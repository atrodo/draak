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
    constructor create(inF: TFile; startChar: cardinal; inB: string; inMax: PCardinal);
    destructor destroy; override;
    function getNew(startChar: cardinal): TString;
    function len: cardinal;
    function lineFind(charNum: cardinal): cardinal;
    function copy(s, len: cardinal): string;
    function match(regex: TRegExp; var offset: cardinal): boolean;
  end;

  TParser = class
    rootNode: PParseNode;
    err: TError;
    lines: cardinal;
    alphanum, numbers, hexs, bins, octs: set of char;
    procedure parse(inF: TFile; inG: TGmr);
    function parseDecent(inS: TString; inG: TGmr; inNode: PGmrNode; out child: PParseNode): word;
  end;

  procedure rootDestroy(inP: PParseNode);

implementation

uses sysutils, draak;

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

constructor TString.create(inF: TFile; startChar: cardinal; inB: string; inMax: PCardinal);
var a: string; i, o, buffLen: cardinal;
begin
  f := inF; start := startChar;
  if inB = '' then
  begin
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
      lineNums[length(lineNums)-1].char := {length(buff)}o;
      lineNums[length(lineNums)-2].line := f.lineCount;
    end;
    lineNums[length(lineNums)-1].line := f.lineCount;
    setLength(buff, o);
    parent := true;
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
  regex.offset := start + offset;
  result := regex.match;
  if result = true then
    offset := offset + length(regex.matched);
end;

destructor TString.destroy;
begin
  if parent = true then
    dispose(FMax);
  setLength(lineNums, 0);
end;

procedure TParser.parse(inF: TFile; inG: TGmr);
var s: TString;
  i: word; Node: PParseNode;
  dumbHash: PGmrNode;
begin
  lines := 0;
  s := TString.create(inF, 0, '', nil);
  i := parseDecent(s, inG, inG.getGoal, Node);
  lines := inF.lineCount;
  if i < s.len-1 then i := 0;
  if i = 0 then err.err('Did not Parse. Error around "'+s.copy(s.max-10, 20)+'" Line '+intToStr(s.lineFind(s.max)));
  if i <> 0 then rootNode := Node else Node := nil;
  s.Free;
end;

function TParser.parseDecent(inS: TString; inG: TGmr; inNode: PGmrNode; out child: PParseNode): word;
var dumbAtom, tempAtom: PGmrAtom;
  tempNode: AGmrNode;
  s: string; i, o, count: cardinal;
  atomI: word;
  nodeI: word;
  Node: PParseNode;
  partial: boolean;
  matched: boolean;
  tempS: TString;
begin
  err.newNode(inNode.name + '"' + inS.copy(0, 10) + '"');
  partial := false;
  child := new(PParseNode);
  Node := nil;
  setlength(child.children, 0);
  child.point := inNode;
  //dumbAtom := innode.RHS;
  o := 1;
  result := 0;
  dumbAtom := innode.RHS[0];
  if (dumbAtom.typed = nonTerminal) AND (dumbAtom.data = inNode.name) then
    raise EDraakNoCompile.Create('Infinate recursion on '+inNode.name);

  writeln('aaa');
  try
  //while dumbAtom <> nil do
  for atomI := 0 to length(innode.RHS)-1 do
  begin
    if inS[1] = #0 then exit;
    if inS[o] = ' ' then inc(o);
    dumbAtom := innode.RHS[atomI];

    matched := false;

    case dumbAtom.typed of
     terminal:
      begin
        matched := inS.match(dumbAtom.re, o);
        if matched then
        begin
          err.addNode('-> '+dumbAtom.data);
          partial := true;
        end;
        {
        s := dumbAtom.data;         
        for i := 1 to length(s) do
        begin
          if (inS[o] = ' ') AND (s[i] = ' ') then inc(o);
          if upcase(s[i]) <> upcase(inS[o]) then
            if s[i] = ' ' then continue
            else exit;
          inc(o);
        end;
        err.addNode(dumbAtom.data);
        partial := true;
        }
      end;
     Matching:
      begin
        matched := inS.match(dumbAtom.re, o);
        if matched then
        begin
          err.addNode('~> '+dumbAtom.data);
          partial := true;
          Node := new(PParseNode);
          Node.point := inNode;
          setLength(Node.data, dumbAtom.re.captureLength);
          for i := 0 to length(Node.data)-1 do
            Node.data[i] := dumbAtom.re.capture[i].captured;
          setLength(Node.children, 0);
        end;
      end;
     nonterminal:
      begin
        count := 0;
        tempNode := inG.getHashNode(dumbAtom.data);
        if length(tempNode) = 0 then
        begin
          err.err('No such Non-terminal: ' + dumbAtom.data);
          exit;
        end;
        //while tempNode <> nil do
        //for nodeI := 0 to length(tempNode)-1 do
        nodeI := 0;
        while nodeI < length(tempNode) do
        begin
          tempS := inS.getNew(o);
          i := parseDecent(tempS, inG, tempNode[nodeI], Node);
          tempS.Free;
          if i = 0 then {Try next option}
          begin
            //inc(count);
            //tempNode := inG.getHashNode(dumbAtom.data);
            //TODO
            //if (tempNode = nil) AND (dumbAtom.optional = false) then exit;
            //if tempNode = nil then node := nil;
            //continue;
          end else
          begin {That option was a winner}
            o := o + i;
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
            break;
          end;
          nodeI := nodeI+1;
        end;
      end;
    end;
    if (dumbAtom.typed <> terminal) {AND (Node <> nil)} then with child^ do
    begin
      setLength(children, length(children)+1);
      children[length(children)-1] := Node;
      Node := nil;
      child.line := inS.lineFind(inS.char+o);
    end;
    //dumbAtom := dumbAtom.next;
  end;
  result := o-1;
  finally begin
    if result = 0 then begin
      err.popNode('!!!');
      rootdestroy(child); child := nil;
      if assigned(Node) then
        rootDestroy(Node);
      Node := nil;
    end else err.popNode('');
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

