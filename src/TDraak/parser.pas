(* **************************************************************** *)
(*     Copyright (C) 1999-2010, Jon Gentle, All right reserved.     *)
(* **************************************************************** *)
(* This program is free software; you can redistribute it under the *)
(* terms of the Artistic License, as specified in the LICENSE file. *)
(* **************************************************************** *)

unit parser;

interface

uses filedrv, hashs, classes, error, gmrdrv, RegExp;

type
  PParseNode = ^RParseNode;
  RParseNode = record
    point: PGmrNode;
    nonTermNum: cardinal;
    line: cardinal;
    data: array of string;
    children: array of PParseNode;
  end;

  PCardinal = ^cardinal;
  TString = class
   public
    f: TFile;
    buff: string;
    start: cardinal;
    FMax: PCardinal;
    parent: boolean;
    lineNums: array of record line, char: cardinal; end;
    function getChar(i: Cardinal): char;
    function getMax: cardinal;
   public
    property b[Index: Cardinal]: char read getChar; default;
    property st: string read buff;
    property max: Cardinal read getMax;
    property char: Cardinal read start;
    constructor create(inF: TFile; startChar: cardinal; inB: string; inMax: PCardinal; settings: TStringHash = nil);
    destructor destroy; override;
    function getNew(startChar: cardinal): TString;
    function len: cardinal;
    function lineFind(charNum: cardinal): cardinal;
    function copy(s, len: cardinal): string;
    function match(regex: TRegExp; var offset: cardinal): boolean;
  end;

  memostatus = (unknown, inprogress, success, failure);
  RMemopad = array of record
    charno: cardinal;
    nodes: array of record
      inNode: PGmrNode;
      mustFollow: string;
      status: memostatus;
    end;
  end;

  TParser = class
    rootNode: PParseNode;
    err: TError;
    lines: cardinal;
    memopad: RMemopad;
    function checkpad(charno: cardinal; inNode: PGmrNode; mustFollow: AGmrAtom): memostatus;
    procedure addmemo(charno: cardinal; inNode: PGmrNode; mustFollow: AGmrAtom; status: memostatus);
    //alphanum, numbers, hexs, bins, octs: set of char;
    procedure parse(inF: TFile; inG: TGmr);
    function parseDecent(inS: TString; inG: TGmr; inNode: PGmrNode; out child: PParseNode; mustFollow: AGmrAtom): word;
  end;

  procedure rootDestroy(inP: PParseNode);

implementation

uses sysutils, draak, libc;

const buffStep = 2000;

function TString.getChar(i: cardinal): Char;
begin
  if i+start > cardinal(length(buff)) then result := #0
  else result := buff[i+start];
  if FMax^ < i+start then
    FMax^ := i+start;
end;

function TString.getMax: Cardinal;
begin
  result := FMax^;
end;

constructor TString.create(inF: TFile; startChar: cardinal; inB: string; inMax: PCardinal; settings: TStringHash = nil);
var a: string; i, o, buffLen: cardinal;
  preprocess: hashs.strArr;
  preprocess_re: TRegExp;
  s_re: TRegExp;

  preprocessor: hashs.strArr;
  preprocessor_io: array[0..2] of PIOFile;
  preprocessor_in: array[0..2] of Integer;
  preprocessor_out: array[0..2] of Integer;
  returncode, childpid: integer;
  inbuff: String;
begin
  f := inF; start := startChar;
  if inB = '' then
  begin
    FMax := new(pcardinal);
    FMax^ := 0;
    parent := true;

    setLength(lineNums, 1);
    lineNums[0].line := 0;
    lineNums[0].char := 0;
    
    while inF.eof <> true do
    begin
      buff := buff+f.getLine+#10;
      o := length(lineNums);
      setLength(lineNums, o+1);
      lineNums[o].char := length(buff);
      lineNums[o].line := f.lineCount;
    end;

    if assigned(settings) then
    begin

      preprocessor := settings.lookup('Preprocessor');
      if length(preprocessor) > 0 then
        for i := 0 to length(preprocessor)-1 do
        begin

          returncode := pipe(@preprocessor_in);
          if returncode <> 0 then
            Raise Exception.create('Could not create a pipe');
          returncode := pipe(@preprocessor_out);
          if returncode <> 0 then
            Raise Exception.create('Could not create a pipe');

          childpid := fork;
          if childpid < 0 then
            Raise Exception.create('Could not fork a child: '+strerror(childpid));
          if childpid = 0 then
          begin
            __close(0);
            dup2(preprocessor_in [0], 0); // Make stdin the pipe input
            __close(1);
            dup2(preprocessor_out[1], 1); // Make stdout the pipe output
            // We don't need these, they're already dupped
            __close(preprocessor_in [0]);
            __close(preprocessor_in [1]);
            __close(preprocessor_out[0]);
            __close(preprocessor_out[1]);

            execlp(PChar(preprocessor[i]), nil);
            raise Exception.create('Bad execlp!');
          end;
          __close(preprocessor_in[0]);
          __close(preprocessor_out[1]);
          preprocessor_io[0] := fdopen(preprocessor_out[0], 'r');
          preprocessor_io[1] := fdopen(preprocessor_in [1], 'w');
          o := 0;
          while length(buff) > 0 do
          begin
            o := fwrite(PChar(buff), 1, length(buff), preprocessor_io[1]);
            buff := system.copy(buff, o+1, length(buff));
          end;
          fflush(preprocessor_io[1]);
          fclose(preprocessor_io[1]);
          setlength(inbuff, 1024);
          while feof(preprocessor_io[0]) = 0 do
          begin
            setlength(inbuff, 1024);
            o := fread(PChar(inbuff), 1, length(inbuff), preprocessor_io[0]);
            buff := buff + system.copy(inbuff, 0, o);
          end;
          fclose(preprocessor_io[0]);
          waitpid(childpid, nil, 0);

          {
          preprocessor_io := popen(PChar(preprocessor[i]), 'w');
          if assigned(preprocessor_io) then
          begin
            fwrite(PChar(buff), sizeof(char), length(buff), preprocessor_io);
            pclose(preprocessor_io);
          end;
          }
        end;

      preprocess := settings.lookup('Preprocess');
      preprocess_re := TRegExp.create;
      preprocess_re.bind(buff);
      s_re := TRegExp.create('s/(.*)/(.*)/[\s\w]*$');
      if length(preprocess) > 0 then
        for i := 0 to length(preprocess)-1 do
        begin
          if s_re.match(preprocess[i]) then
          begin
            preprocess_re.compile(s_re.capture[1].captured, [IgnoreCase, MultiLine, SingleLine, Extended, Global]);
            buff := preprocess_re.substitute(buff, s_re.capture[2].captured);
          end;
        end;
      //raise Exception.create('bah');
      //writeln(buff);
    end;
    {
    FMax := new(pcardinal);
    FMax^ := 0;
    setLength(lineNums, 1);
    lineNums[0].line := 0; lineNums[0].char := 0;
    o := 0; buffLen := 0;
    while inF.eof <> true do
    begin
      a := f.getLine;
      for i := 1 to length(a) do
      begin
        if i+o > buffLen then
        begin
          buffLen := buffLen+buffStep;
          setLength(buff, buffLen);
        end;
        buff[i+o] := a[i];
      end;
      o := o+cardinal(length(a));
//      buff := buff+f.getLine;
      setLength(lineNums, length(lineNums)+1);
      lineNums[length(lineNums)-1].char := {length(buff)}{o;
      lineNums[length(lineNums)-2].line := f.lineCount;
    end;
    lineNums[length(lineNums)-1].line := f.lineCount;
    setLength(buff, o);
    }
  end else
  begin
    buff := inB;
    FMax := inMax;
    parent := false;
  end;
end;

function TString.getNew(startChar: cardinal): TString;
begin
  result := TString.create(f, start+startChar-1, buff, FMax);
  result.lineNums := lineNums;
end;

function TString.lineFind(charNum: cardinal): cardinal;
var s, i: cardinal;
  old: array of boolean;
begin
  if charNum >= cardinal(length(buff)) then begin result := length(lineNums); exit; end;
  s := length(lineNums)-2;
  i := 0;
  setLength(old, length(lineNums));
  while not((lineNums[s].char <= charNum) AND (lineNums[s+1].char >= charNum)) do
  begin
    old[s] := true;
    s := trunc((charNum / lineNums[s+1].char) * (s+1));
    while (s > 0) and (old[s] = true) do dec(s);
    while (s < cardinal(length(lineNums))) and (old[s] = true) do inc(s);
    inc(i); if i > cardinal(length(lineNums)) then raise EDraakNoCompile.Create('Can''t find error line');
  end;
  result := lineNums[s].line;
  Finalize(old);
//  setLength(old, 0);
end;

function TString.len: cardinal;
begin
  result := cardinal(length(buff))-start;
end;

function TString.copy(s, len: cardinal): string;
begin
  result := system.Copy(buff, start+s, len);
end;

function TString.match(regex: TRegExp; var offset: cardinal): boolean;
begin
  regex.bind(buff);
  regex.offset := start + offset - 1;
  result := regex.match;
  if result = true then
    offset := regex.capture[0].pos + regex.capture[0].len - start;
  {
  writeln('***'+regex.matched+'***');
  writeln(regex.capture[0].pos);
  writeln(regex.capture[0].len);
  writeln(start);
  writeln('***'+regex.matched+'***');
  }
end;

destructor TString.destroy;
begin
  if parent = true then
    dispose(FMax);
  setLength(lineNums, 0);
end;

function TParser.checkpad(charno: cardinal; inNode: PGmrNode; mustFollow: AGmrAtom): memostatus;
var
  i, o: cardinal;
  mustFollowStr: string;
begin;
  result := unknown;

  mustFollowStr := '';
  if length(mustFollow) > 0 then
    for i := 0 to length(mustFollow)-1 do
      mustFollowStr := mustFollowStr + mustFollow[i].data;

  if length(memopad) > 0 then
    for i := 0 to length(memopad)-1 do
    begin
      if memopad[i].charno = charno then
      begin
        with memopad[i] do
        begin
          if length(nodes) > 0 then
            for o := 0 to length(nodes)-1 do
            begin
              if (nodes[o].inNode = inNode) and (nodes[o].mustFollow = mustFollowStr) then
              begin
                result := nodes[o].status;
                exit;
              end;
            end;
        end;
      end;
    end
end;

procedure TParser.addmemo(charno: cardinal; inNode: PGmrNode; mustFollow: AGmrAtom; status: memostatus);
var
  i, o: cardinal;
  mustFollowStr: string;
begin;
  mustFollowStr := '';
  if length(mustFollow) > 0 then
    for i := 0 to length(mustFollow)-1 do
      mustFollowStr := mustFollowStr + mustFollow[i].data;

  if length(memopad) > 0 then
    for i := 0 to length(memopad)-1 do
    begin
      if memopad[i].charno = charno then
      begin
        with memopad[i] do
        begin
          if length(nodes) > 0 then
            for o := 0 to length(nodes)-1 do
            begin
              if (nodes[o].inNode = inNode) and (nodes[o].mustFollow = mustFollowStr)then
              begin
                nodes[o].status := status;
                exit;
              end;
            end;

          // No matching memopad
          o := length(nodes);
          setlength(nodes, o+1);
          nodes[o].inNode := inNode;
          nodes[o].status := status;
          nodes[o].mustFollow := mustFollowStr;
          exit;
        end;
      end;
    end;

  // Nothing found
  i := length(memopad);
  setlength(memopad, i+1);
  memopad[i].charno := charno;
  with memopad[i] do
  begin
    o := length(nodes);
    setlength(nodes, o+1);
    nodes[o].inNode := inNode;
    nodes[o].status := status;
    nodes[o].mustFollow := mustFollowStr;
    exit;
  end;

end;

procedure TParser.parse(inF: TFile; inG: TGmr);
var s: TString;
  i: word; Node: PParseNode;
  dumbHash: PGmrNode;
begin
  lines := 0;
  s := TString.create(inF, 0, '', nil, inG.settings);
  i := parseDecent(s, inG, inG.getGoal, Node, nil);
  lines := inF.lineCount;
  if i < s.len-1 then i := 0;
  if i = 0 then err.err('Did not Parse. Error around "'+s.copy(s.max-20, 40)+'" Line '+intToStr(s.lineFind(s.max)));
  if i <> 0 then rootNode := Node else Node := nil;
  s.Free;
  writeln(length(memopad));
end;

function TParser.parseDecent(inS: TString; inG: TGmr; inNode: PGmrNode; out child: PParseNode; mustFollow: AGmrAtom): word;
var dumbAtom, tempAtom: PGmrAtom;
  tempNode: AGmrNode;
  s: string; i: cardinal;
  parsedLen: cardinal;
  returnedLen: cardinal;
  atomI: word;
  atomO: word;
  nodeI: word;
  nonTermI: word;
  Node: PParseNode;
  partial: boolean;
  matched: boolean;
  done:    boolean;
  tempS: TString;
  appends: AGmrAtom;
  allAtoms: AGmrAtom;
begin
  //write(inNode.id); write(' : '); write(inS.char); writeln(' : '+inNode.name);
  result := 0;

  {$DEFINE MEMOPAD}
  {$ifdef MEMOPAD}
  case checkPad(inS.char, inNode, mustFollow) of
    unknown: ;
    success: ;
    failure: exit;
    inprogress:
      begin
        raise EDraakNoCompile.Create('Infinate recursion on '+inNode.name);
      end;
  end;

  addmemo(inS.char, inNode, mustFollow, inprogress);
  {$endif}

  err.newNode(inNode.name); // + '"' + inS.copy(0, 10) + '"');

  partial := false;
  child := new(PParseNode);
  Node := nil;
  nonTermI := 0;
  setlength(child.children, 0);
  child.point := inNode;
  child.nonTermNum := 0;
  //dumbAtom := innode.RHS;
  parsedLen := 1;
  dumbAtom := innode.RHS[0];
  if (dumbAtom.typed = nonTerminal) AND (dumbAtom.data = inNode.name) then
    raise EDraakNoCompile.Create('Infinate recursion on '+inNode.name);

  try
    allAtoms := innode.RHS;
    atomO := length(allAtoms);
    if length(mustFollow) > 0 then
    begin
      setlength(allAtoms, length(allAtoms)+length(mustFollow));
      for i := 0 to length(mustFollow) - 1 do
        allAtoms[i+atomO] := mustFollow[i];
    end;

    for atomI := 0 to length(allAtoms)-1 do
    begin
      if inS[1] = #0 then exit;
      dumbAtom := allAtoms[atomI];

      done    := false;

      if dumbAtom.typed = nonterminal then
        inc(nonTermI);

      while done = false do
      begin
        matched := false;
        err.addNode('"' + inS.copy(parsedLen, 20) + '"');
        err.addNode(dumbAtom.data);
        case dumbAtom.typed of
         terminal:
          begin
            matched := inS.match(dumbAtom.re, parsedLen);
            if matched then
            begin
              err.addNode('-> '+dumbAtom.data);
              partial := true;
            end;
          end;
         Matching:
          begin
            matched := inS.match(dumbAtom.re, parsedLen);
            if matched then
            begin
              err.addNode('~> '+dumbAtom.data);
              partial := true;
              Node := new(PParseNode);
              Node.point := inNode;
              Node.nonTermNum := 0;
              if dumbAtom.re.captureLength > 1 then
              begin
                setLength(Node.data, dumbAtom.re.captureLength-1);
                for i := 0 to length(Node.data)-1 do
                  Node.data[i] := dumbAtom.re.capture[i+1].captured;
              end;
              setLength(Node.children, 0);
            end;
          end;
         nonterminal:
          begin
            // This is an optional match, normally just for taking care
            // of spaces in stars
            if dumbAtom.re <> nil then
              inS.match(dumbAtom.re, parsedLen);

            setLength(appends, 0);
            if (atomI < length(innode.RHS)-1) and (innode.RHS[atomI+1].appended = true) then
            begin
              for atomO := atomI+1 to length(innode.RHS)-1 do
              begin
                if innode.RHS[atomO].appended = false then break;
                setLength(appends, length(appends)+1);
                appends[length(appends)-1] := innode.RHS[atomO];
              end;
            end;

            // If we are at the end of the node (including if all of the
            // nodes after us are append nodes), append the mustFollow array
            // onto the appends array.
            // This will ONLY happen on non-star nodes
            atomO := length(appends);
            if (dumbAtom.star = false) and (atomI + atomO = length(innode.RHS)-1) and (length(mustFollow) > 0) then
            begin
              setlength(appends, atomO+length(mustFollow));
              for i := 0 to length(mustFollow)-1 do
                appends[i+atomO] := mustFollow[i];
            end;

            tempNode := inG.getHashNode(dumbAtom.data);
            if length(tempNode) = 0 then
            begin
              err.err('No such Non-terminal: ' + dumbAtom.data);
              done := true;
              continue;
            end;
            nodeI := 0;
            while nodeI < length(tempNode) do
            begin
              tempS := inS.getNew(parsedLen);
              i := parseDecent(tempS, inG, tempNode[nodeI], Node, appends);
              tempS.Free;
              if i > 0 then
              begin {That option was a winner}
                matched := true;
                parsedLen := parsedLen + i;
                Node.nonTermNum := nonTermI;
                break;

                {
                if dumbAtom.star = true then
                begin
                  setLength(child^.children, length(child^.children)+1);
                  child^.children[length(child^.children)-1] := Node;
                  count := 0;
                  matched := true;
                  nodeI := 0;
                  //tempNode := inG.getHashNode(dumbAtom.data);
                  continue;
                end;
                }
              end;
              nodeI := nodeI+1;
            end;
          end;
        end;

        done := true;
        if matched = true then with child^ do
        begin
          setLength(children, length(children)+1);
          children[length(children)-1] := Node;
          Node := nil;
          child.line := inS.lineFind(inS.char+parsedLen);
        end;

        //writeln(dumbAtom.star);
        if dumbAtom.optional = true then
          matched := true;
        if dumbAtom.star = true then
        begin
          if matched = true then
            done := false
          else
            done := true;
          matched := true;
        end;

        if matched = false then exit;
      end;

      if atomI < length(innode.RHS) then
        returnedLen := parsedLen;

    end;
    //if atomI < length(innode.RHS) then
      result := returnedLen-1;
  finally begin
    if result = 0 then
    begin
      {$ifdef MEMOPAD}
      addmemo(inS.char, inNode, mustFollow, failure);
      {$endif}
      //err.popNode('!!!');
      err.popNode('!!! '+inNode.name);
      rootdestroy(child); child := nil;
      if assigned(Node) then
        rootDestroy(Node);
      Node := nil;
    end else
    begin
      {$ifdef MEMOPAD}
      addmemo(inS.char, inNode, mustFollow, success);
      {$endif}
      err.popNode('');
    end;
    if (partial = true) AND (result = 0) then {err('Danger Will Robinson, Danger ' + inNode.name)}; { $ENDIF}
  end; end;
end;

procedure rootDestroy(inP: PParseNode);
var i: cardinal;
begin
  if not(assigned(inP)) then
    exit;
  if length(inP.children) <> 0 then
  for i := 0 to length(inP.children)-1 do
    rootDestroy(inP.children[i]);
  //if inP.point.special = true then
  //  DestroyHash(inP.point.next);
  setLength(inP.children, 0);
  dispose(inP);
end;

{* So what does parser do exactly?  Easy, it is in charge of taking a source  *}
{* file, a grammer and building a parse tree of rules.                        *}

end.

