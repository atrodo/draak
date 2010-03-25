(* **************************************************************** *)
(*     Copyright (C) 1999-2010, Jon Gentle, All right reserved.     *)
(* **************************************************************** *)
(* This program is free software; you can redistribute it under the *)
(* terms of the Artistic License, as specified in the LICENSE file. *)
(* **************************************************************** *)

unit cmddrv;

interface

uses parser, hashs, classes, strutils, sysutils, contnrs, error, gmrdrv, macro;

type
  PLocal = ^RLocal;
  RLocal = record
    returns: strArr;
    lvar: TStringHash;
    //lvar: varArr;
    truth: (equal, Exists, notequal, Nonexists, greater, less, sElse, SEndif);
  end;

  TMacro = class(TMacroDrv)
    constructor create; override;
    procedure execute(inNode: PParseNode); override;
    destructor destroy; override;
   private
    vars, remember: TVars;
    local: TStack;
    varHash: TStringHash;
    cmdExec: boolean;
    return: string;
    skipAhead: PHashAtom;
    whilePlace: PHashAtom;
    currentNum: cardinal;
    squelsh: boolean;
    logging: boolean;
    hasBeenTrue: boolean;
    procedure execNode(inMacro: PHashAtom; inNode: PParseNode);
    procedure cmd(inMacro: PHashAtom; inNode: PParseNode);
    procedure varcmd(inMacro: PHashAtom; inNode: PParseNode);
    procedure hashcmd(inMacro: PHashAtom; inNode: PParseNode);
    procedure ifcmd(inMacro: PHashAtom; inNode: PParseNode);
    procedure extention(inMacro: PHashAtom; inNode: PParseNode);
    procedure results(inMacro: PHashAtom; inNode: PParseNode);
    function line(inMacro: PHashAtom; inNode: PParseNode): string;
    procedure forloop(inMacro: PHashAtom; inNode: PParseNode);
    procedure varAdd(s: string; inNode: PParseNode);
    procedure varAltAdd(s: string; inNode: PParseNode);
    procedure lhs(inMacro: PHashAtom; inNode: PParseNode);
    procedure rhs(inMacro: PHashAtom; inNode: PParseNode);
    procedure alt(inMacro: PHashAtom; inNode: PParseNode);
    procedure extractType(inMacro: PHashAtom; inNode: PParseNode);
    procedure contextComplete(inMacro: PHashAtom; inNode: PParseNode);
    procedure decontextComplete(inMacro: PHashAtom; inNode: PParseNode);
    procedure whileLoop(inMacro: PHashAtom; inNode: PParseNode);
    procedure compare(inMacro: PHashAtom; inNode: PParseNode);
    procedure compareEquiv(inMacro: PHashAtom; inNode: PParseNode);
    procedure partialCompare(inMacro: PHashAtom; inNode: PParseNode);
    procedure use(inMacro: PHashAtom; inNode: PParseNode);
    procedure basedTypeAdd(s: string; inNode: PParseNode);
    procedure typeAdd(s: string; inNode: PParseNode);
    procedure pushContext(s: string; inNode: PParseNode);
    procedure popContext;
    procedure rememberContext;
    procedure saveContext(context: TVars);
    procedure loadContext(const s, harden: string);
    procedure hardenContext;
    procedure softenContext;
    function varLookup(const s: string): string;
    procedure saveReturn(s: string; varSave: string = '');
    function localed(var s: string): TStringHash;
    procedure getNumber(const s: string);
    function expand(s: string): string;
    procedure split(s: string; out data: strArr; minSize: word = 0);
    function join(data: strArr; doExpand: boolean = false; lower: word = 0; upper: word = 65535): string;
  end;

implementation

uses filedrv, draak;

var numbers: string;

constructor TMacro.create;
begin
  FoutCode := TStringList.Create;
  FoutData := TStringList.Create;
  local := TStack.create;
  varHash := TStringHash.Create;
  cmdExec := true;
  vars := TVars.Create('sysBase', nil, FErr);
end;

destructor TMacro.destroy;
begin
  vars.debugPrintAllHashes;
  local.Free;
  varHash.Free;
  vars[0].Free;
  FoutCode.Free;
  FoutData.Free;
end;

procedure TMacro.execute(inNode: PParseNode);
begin
  local.Push(new(PLocal));
  PLocal(local.Peek).lvar := TStringHash.Create; 
  if inNode = nil then
  begin
    local.Pop;
    PLocal(local.Peek).truth := Nonexists;
    exit;
  end;
  PLocal(local.Peek).truth := Exists;
  if inNode.point.special = true then
  begin
    return := inNode.point.name;
    local.Pop;
    saveReturn(return);
    return := '';
    exit;
  end;

  if inNode.point.Macros = nil then
  begin
    err.err('No macro defined for '+inNode.point.name);
    local.Pop;
    PLocal(local.Peek).truth := Exists;
    exit;
  end;
  try
    execNode(inNode.point.Macros, inNode);
  except on E: EDraakNoCompile do
  begin
    Err.err(E.Message+' on node '+inNode.point.name+', Line '+intToStr(inNode.line));
    giantError := true;
    exit;
  end; end;
  local.Pop;
  if local.Count > 0 then
    PLocal(local.Peek).truth := Exists;
  if return <> '' then
  begin
    saveReturn(return); return := '';
  end;
end;

procedure TMacro.execNode(inMacro: PHashAtom; inNode: PParseNode);
var dumbNode: PHashAtom;
  originalMacro: PChar;
  d: strArr;
begin
  dumbNode := inMacro;
  while dumbNode <> nil do
  begin
    if giantError = true then exit;
    if (cmdExec = true) AND (logging = true) then
      err.stream(inNode.point.name+' '+dumbNode.Macro);
    originalMacro := nil;
    if dumbNode.Macro[0] = '?' then
    begin
      originalMacro := dumbNode.Macro;
      //delete(dumbNode.Macro, 1, 1);
      split(dumbNode.Macro, d);
      delete(d[0], 1, 1);
      if assigned(localed(d[0]).lookup(d[0])) then
      begin
        dumbNode.Macro := PChar(join(d, false, 1));
      end else
      begin
        dumbNode.Macro := originalMacro;
        dumbNode := dumbNode.next;
        continue;
      end;
    end;
    case dumbNode.Macro[0] of
     '!': cmd(dumbNode, inNode);
     '@': if cmdExec = true then varcmd(dumbNode, inNode);
     '+': if (cmdExec = true) AND (squelsh = false) then outCode.Append(line(dumbNode, inNode));
     '*': if (cmdExec = true) AND (squelsh = false) then outData.Append(line(dumbNode, inNode));
     else
      err.err('Bad macro! ' + dumbNode.macro);
    end;
    if (originalMacro <> '') then
      dumbNode.Macro := originalMacro;
    if skipAhead <> nil then
    begin
      dumbNode := skipAhead.next;
      skipAhead := nil;
    end else
      dumbNode := dumbNode.next;
  end;
end;

procedure TMacro.cmd(inMacro: PHashAtom; inNode: PParseNode);
var s: string; d: strArr;
begin
  split(inMacro.Macro, d, 2);
  if (cmdExec = false) AND (inMacro.Macro[1] <> 'I') then exit;
  case inMacro.macro[1] of
   'E': execute(inNode.children[strToInt(copy(d[1], 2, 5))-1]);
   'R': results(inMacro, inNode);
   'v': hashcmd(inMacro, inNode);
   'l': lhs(inMacro, inNode);
   'r': rhs(inMacro, inNode);
   'a': alt(inMacro, inNode);
   't': extractType(inMacro, inNode);
   'T': contextComplete(inMacro, inNode);
   'D': decontextComplete(inMacro, inNode);
   'W': whileLoop(inMacro, inNode);
   'C': compare(inMacro, inNode);
   'I': ifcmd(inMacro, inNode);
   'F': forloop(inMacro, inNode);
   'g': getNumber(expand(d[1]));
   'Q': squelsh := not squelsh;
   'X': extention(inMacro, inNode);
   'b':
     begin
       skipAhead := inMacro;
       while skipAhead.next <> nil do
         skipAhead := skipAhead.next;
     end;
   'Z':
     begin
       s := expand(PChar(inMacro.Macro)+AnsiPos(' ', inMacro.Macro));
       err.err(s); giantError := true;
     end;
   'z':
     begin
       s := expand(PChar(inMacro.Macro)+AnsiPos(' ', inMacro.Macro));
       err.err(s);
     end;
   else err.err('Unknown command: ' + inMacro.macro);
  end;
end;

procedure TMacro.varcmd(inMacro: PHashAtom; inNode: PParseNode);
var s: string;
  dumbContext: TVars;
  i, o: word;
  d: strArr;
begin
  s := inMacro.Macro; split(s, d, 3);
  i := AnsiPos(' ', s);
  if i = 0 then
    i := length(s)+1;
  i := ansiPos(s[i-1], numbers);
  dumbContext := vars[vars.len-i];
  case s[2] of
   'v': varAdd(PChar(s)+AnsiPos(' ', s), inNode);
   'V': varAltAdd(PChar(s)+AnsiPos(' ', s), inNode);
   't': typeAdd(PChar(s)+AnsiPos(' ', s), inNode);
   'T': basedTypeAdd(PChar(s)+AnsiPos(' ', s), inNode);
   'E': dumbContext.attachType(expand(PChar(s)+AnsiPos(' ', s)));
   'd': dumbContext.addDecl(PChar(s)+AnsiPos(' ', s));
   'D': dumbContext.addAltDecl(PChar(s)+AnsiPos(' ', s));
   'l': dumbContext.addLHS(PChar(s)+AnsiPos(' ', s));
   'r': dumbContext.addRHS(PChar(s)+AnsiPos(' ', s));
   'a': dumbContext.addALT(PChar(s)+AnsiPos(' ', s));
   'N': pushContext(PChar(s)+AnsiPos(' ', s), inNode);
   'n': popContext;
   'e': for o := 2 to length(d)-1 do dumbContext.addEquiv(expand(d[1]), expand(d[o]));
   's': dumbContext.saveLocal(PLocal(local.Peek).lvar);
   'S': PLocal(local.Peek).lvar := dumbContext.getLocal(expand(PChar(s)+AnsiPos(' ', s))).copy;
   'c': saveContext(dumbContext);
   'C': loadContext(expand(d[1]), expand(d[2]));
   'M': remember := vars;
   'm': rememberContext;
   'U': dumbContext.dump;
   'o': vars := dumbContext.loadContextBlock(expand(d[1]));
   'X': dumbContext.rmVar(expand(d[1]));
   else err.err('Bad macro: '+s);
  end;
end;

procedure TMacro.hashcmd(inMacro: PHashAtom; inNode: PParseNode);
var d: strArr; dumbHash: TStringHash; // i: byte;
begin
  split(inMacro.Macro, d, 4);
  dumbHash := localed(d[2]);
  case d[1][1] of
    's': dumbHash.add(expand(d[2]), join(d, true, 3)); //expand(d[3]));
    'u': dumbHash.remove(expand(d[2]));
    'i': dumbHash.inc(expand(d[2]), expand(d[3]));
    'a': dumbHash.append(expand(d[2]), join(d, true, 3));
    'r': dumbHash.removeStr(expand(d[2]), expand(d[3]));
    'R': dumbHash.removeStrEnd(expand(d[2]), expand(d[3]));
    'A': dumbHash.strictAppend(expand(d[2]), expand(d[3]));
    'n': dumbHash.insert(expand(d[2]), expand(d[3]));
    'p': dumbHash.insert(expand(d[2]), expand(d[3]));
    'P': dumbHash.removeStr(expand(d[2]), dumbHash.first(expand(d[2])));
    'e': Self.saveReturn(dumbHash.len(expand(d[2])), d[3]);
    'f': Self.saveReturn(dumbHash.first(expand(d[2])), d[3]);
    'l': Self.saveReturn(dumbHash.last(expand(d[2])), d[3]);
    'G': Self.saveReturn(varLookup(expand(d[2])), d[3]);
    'V': Self.saveReturn(vars.name, d[2]);
    'L': Self.saveReturn(intToStr(Length(expand(d[2]))), d[3]);
    'g': varHash.add(expand(d[4]), dumbHash.getSubStr(expand(d[2]), StrToInt(expand(d[3]))-1));
    'C': PLocal(local.Peek).lvar.empty;
   else err.err('Bad variable usage: '+d[1]);
  end;
end;

procedure TMacro.ifcmd(inMacro: PHashAtom; inNode: PParseNode);
var d: strArr;
begin
  split(inMacro.Macro, d, 1);
  case d[1][1] of
   'e': if PLocal(local.Peek).truth <> exists       then cmdExec := false else cmdExec := true;
   'n': if PLocal(local.Peek).truth <> nonexists    then cmdExec := false else cmdExec := true;
   'E': if PLocal(local.Peek).truth <> Equal        then cmdExec := false else cmdExec := true;
   'N': if PLocal(local.Peek).truth <> Notequal     then cmdExec := false else cmdExec := true;
   'g': if PLocal(local.Peek).truth <> greater      then cmdExec := false else cmdExec := true;
   'G': if (PLocal(local.Peek).truth <> greater) AND (PLocal(local.Peek).truth <> Equal)
                                                    then cmdExec := false else cmdExec := true;
   'l': if PLocal(local.Peek).truth <> less         then cmdExec := false else cmdExec := true;
   'L': if (PLocal(local.Peek).truth <> less)    AND (PLocal(local.Peek).truth <> Equal)
                                                    then cmdExec := false else cmdExec := true;
   'S': begin cmdExec := true; hasBeenTrue := false; end;
   's':
    begin
      if length(d) >= 3 then
      begin
        setLength(d, 4); d[2] := expand(d[2]); d[3] := expand(d[3]);
        hasBeenTrue := (cmdExec AND true) or hasBeenTrue;
        if hasBeenTrue = false then
        begin
          if d[2] = d[3] then
            PLocal(local.Peek).truth := Equal
          else
            PLocal(local.Peek).truth := notEqual;
          if PLocal(local.Peek).truth <> Equal then
            cmdExec := false
          else cmdExec := true;
        end else
          cmdExec := false;
      end else
      begin
        if hasBeenTrue = false then
          cmdExec := not(cmdExec)
        else
          cmdExec := false;
      end;
    end;
  end;
end;

procedure TMacro.extention(inMacro: PHashAtom; inNode: PParseNode);
var d: strArr; s: string;
  i: word;
begin
  split(inMacro.Macro, d, 2);
  s := '';
  for i:= 2 to length(d)-1 do s := s + d[i] + ' ';
  s := expand(s); 
  case d[1][1] of
    'a': err.assemble(s);
    'l': err.link(s);
    'c': err.compile(s);
    'U': use(inMacro, inNode);
    'e': logging := true;
    'd': logging := false;
    else err.err('Unknown Extension: ' + d[1]);
  end;
end;

procedure TMacro.results(inMacro: PHashAtom; inNode: PParseNode);
var s: string;
begin
  s := copy(inMacro.Macro, AnsiPos(' ', inMacro.Macro)+1, length(inMacro.Macro)-2);
  return := expand(s);
end;

function TMacro.line(inMacro: PHashAtom; inNode: PParseNode): string;
var s: string;
begin
  s := inMacro.Macro+1; result := expand(s);
end;

procedure TMacro.forloop(inMacro: PHashAtom; inNode: PParseNode);
var dumbNode: PHashAtom;
  dumbParse: PParseNode;
  tempPoint: RHashNode;
  i, o, p: word;
  d: string;
begin
  dumbParse := inNode.children[strToInt(inMacro.Macro[AnsiPos('%', inMacro.Macro)])-1];
  if dumbParse = nil then
  begin
    dumbNode := inMacro.next;
    while not((dumbNode.Macro[0] = '!') AND (dumbNode.Macro[1] = 'F')) do
      dumbNode := dumbNode.next;
    skipAhead := dumbNode;
    PLocal(local.Peek).truth := Nonexists;
    exit;
  end;
  tempPoint := dumbParse.point;
  dumbNode := new(PHashAtom);
  dumbNode.next := inMacro.next;
  dumbNode.Macro := PChar(Copy(inMacro.Macro, 0, length(inMacro.macro)));
  p := strToInt(inMacro.Macro[AnsiPos('%', inMacro.Macro)])-1-length(PLocal(local.Peek).returns);
  for i := strToInt(inMacro.Macro[AnsiPos('%', inMacro.Macro)])-1 to length(inNode.children)-1 do
  begin
    dumbParse := inNode.children[i];
    if dumbParse = nil then break;
    if dumbParse.point.name <> tempPoint.name then break;
    dumbNode.next := inMacro.next.next;
    dumbNode.Macro := inMacro.next.Macro;
    while dumbNode <> nil do
    begin
      if giantError = true then exit;
      if (dumbNode.Macro[0] = '!') AND (dumbNode.Macro[1] = 'F') then
        break;
      d := dumbNode.Macro;
      o := AnsiPos('%n', d);
      if o <> 0 then
      begin
        delete(d, o+1, 1);
        insert(intToStr(i+1), d, o+1);
      end;
      o := AnsiPos('$n', d);
      while o <> 0 do
      begin
        delete(d, o+1, 1);
        insert(intToStr(i+1+p), d, o+1);
        o := AnsiPos('$n', d);
      end;
      dumbNode.Macro := PChar(d);
      case dumbNode.Macro[0] of
       '!': cmd(dumbNode, inNode);
       '@': if cmdExec = true then varcmd(dumbNode, inNode);
       '+': if cmdExec = true then outCode.Append(line(dumbNode, inNode));
       '*': if cmdExec = true then outData.Append(line(dumbNode, inNode));
       else
        err.err('Bad macro! ' + dumbNode.macro);
      end;
      dumbNode.Macro := dumbNode.next.Macro;
      dumbNode.next := dumbNode.next.next;
    end;
  end;
  skipAhead := dumbNode;
end;

procedure TMacro.varAdd(s: string; inNode: PParseNode);
var name, typ, context, temp: string;
 dumbNode: PHashAtom; dumbHash: PVarNode;
 current: PLocal;
 dumbContext: TVars;
 i: word; a: strArr;
begin
  temp := expand(s);
  split(temp, a); name := a[0]; typ := a[1];
  if length(a) > 2 then context := a[2] else context := 'a';
  if vars.hashLookup(name, 1) <> nil then
    Raise EDraakNoCompile.Create('Variable '+name+' already defined in current context');
  i := AnsiPos(context[1], numbers);
  dumbContext := vars[vars.len-i];
  dumbContext.addVar(name, typ);
  dumbHash := vars.hashLookup(name);
  if (dumbHash = nil) OR (dumbHash.typePtr = nil) then exit;
  dumbNode := dumbHash.typePtr.Decl;
  current := local.Push(new(PLocal));
  current.lvar := dumbHash.typePtr.local.copy;
  setLength(current.returns, 2);
  current.returns[0] := name;
  current.returns[1] := typ;
  execNode(dumbNode, inNode);
  dumbHash.local := current.lvar;
  local.Pop;
end;


procedure TMacro.varAltAdd(s: string; inNode: PParseNode);
var name, typ, context, temp: string;
 dumbNode: PHashAtom; dumbHash: PVarNode;
 current: PLocal;
 dumbContext: TVars;
 i: word; a: strArr;
begin
  temp := expand(s);
  split(temp, a); name := a[0]; typ := a[1];
  if length(a) > 2 then context := a[2] else context := 'a';
  if vars.hashLookup(name, 1) <> nil then
    Raise EDraakNoCompile.Create('Variable '+name+' already defined in current context');
  i := AnsiPos(context[1], numbers);
  dumbContext := vars[vars.len-i];
  dumbContext.addVar(name, typ);
  dumbHash := vars.hashLookup(name);
  if (dumbHash = nil) OR (dumbHash.typePtr = nil) then exit;
  dumbNode := dumbHash.typePtr.altDecl;
  current := local.Push(new(PLocal));
  current.lvar := dumbHash.typePtr.local.copy;
  setLength(current.returns, 2);
  current.returns[0] := name;
  current.returns[1] := typ;
  execNode(dumbNode, inNode);
  dumbHash.local := current.lvar;
  local.Pop;
end;

procedure TMacro.lhs(inMacro: PHashAtom; inNode: PParseNode);
var s, name: string;
  d: strArr;
  dumbNode, varNode: PVarNode;
  current: PLocal; i: word;
begin
  s := inMacro.Macro+1; s := expand(s);
  split(s, d, 2);
  name := d[1];
  if name = '' then
    Raise EDraakNoCompile.Create('No type/var passed to LHS');
  dumbNode := vars.hashLookup(name);
  if dumbNode = nil then
    Raise EDraakNoCompile.Create('No such type/var: '+name+' (LHS)');
  varNode := dumbNode;
  if dumbNode.isvar = true then
    dumbNode := dumbNode.typePtr;
  current := local.Push(new(PLocal));
  PLocal(local.Peek).lvar := TStringHash.Create;
  setLength(current.returns, 2);
  current.lvar := varNode.local;
  current.returns[0] := name;
  if length(d) > 2 then current.returns[1] := join(d, false, 2);
  for i := 3 to length(d)-1 do
    current.returns[1] := current.returns[1]+' '+d[i];
  execNode(dumbNode.LHS, inNode);
  local.Pop;
end;

procedure TMacro.rhs(inMacro: PHashAtom; inNode: PParseNode);
var s, name: string;
  d: strArr;
  dumbNode, varNode: PVarNode;
  current: PLocal; i: word;
begin
  s := inMacro.Macro+1; s := expand(s);
  split(s, d, 2);
  name := d[1];
  if name = '' then
    Raise EDraakNoCompile.Create('No type/var passed to RHS');
  dumbNode := vars.hashLookup(name);
  if dumbNode = nil then
    Raise EDraakNoCompile.Create('No such type/var: '+name+' (RHS)');
  varNode := dumbNode;
  if dumbNode.isvar = true then
    dumbNode := dumbNode.typePtr;
  current := local.Push(new(PLocal));
  PLocal(local.Peek).lvar := TStringHash.Create;
  setLength(current.returns, 2);
  current.lvar := varNode.local;
  current.returns[0] := name;
  if length(d) > 2 then current.returns[1] := join(d, false, 2);
  for i := 3 to length(d)-1 do
    current.returns[1] := current.returns[1]+' '+d[i];  
  execNode(dumbNode.RHS, inNode);
  varNode.local := current.lvar;
  local.Pop;
end;

procedure TMacro.alt(inMacro: PHashAtom; inNode: PParseNode);
var s, name: string;
  d: strArr;
  dumbNode, varNode: PVarNode;
  current: PLocal; i: word;
begin
  s := inMacro.Macro+1;
  s := expand(s);
  split(s, d);
  name := d[1];
  if name = '' then
    Raise EDraakNoCompile.Create('No type/var passed to ALT');
  dumbNode := vars.hashLookup(name);
  if dumbNode = nil then
    Raise EDraakNoCompile.Create('No such type/var: '+name+' (ALT)');
  varNode := dumbNode;
  if dumbNode.isvar = true then
    dumbNode := dumbNode.typePtr;
  current := local.Push(new(PLocal));
  PLocal(local.Peek).lvar := TStringHash.Create;  
  setLength(current.returns, 2);
  current.lvar := varNode.local;
  current.returns[0] := name;
  if length(d) > 2 then s := d[2] else s := '';
  current.returns[1] := s;
  for i := 3 to length(d)-1 do
    current.returns[1] := current.returns[1]+' '+d[i];
  if length(dumbNode.ALT)>0 then   {fpc needs this, and is a good idea anyways.}
    for i := 0 to length(dumbNode.ALT)-1 do
    begin
      if i = length(dumbNode.ALT)-1 then
        execNode(dumbNode.ALT[i].next, inNode)
      else if s = dumbNode.ALT[i].Macro then
        begin execNode(dumbNode.ALT[i].next, inNode); break; end;
    end;
//  execNode(dumbNode.ALT, inNode);
  varNode.local := current.lvar;
  local.Pop;
end;

procedure TMacro.extractType(inMacro: PHashAtom; inNode: PParseNode);
var s: string; d: strArr;
  dumbNode: PVarNode;
  ret: string; i: int64;
  r: extended; sn: single; db: double;
  dumbHash: TStringHash;
begin
  s := expand(inMacro.Macro); split(s, d);
  dumbHash := localed(d[2]);
  dumbNode := vars.hashLookup(d[1]); i := 0;
  if dumbNode = nil then
  begin
    {Basic Types}
    if (d[1][1] = '$') or (d[1][1] = '.') then ret := d[1]
    else
    begin
    {Strings}
      try
        i := StrToInt64(d[1]);
      except
        on EConvertError do
        begin
          try
            r := StrToFloat(d[1]);
            sn := StrToFloat(d[1]); db := StrToFloat(d[1]);
            if r = sn then ret := '$r4'
            else if db = r then ret := '$r8'
            else ret := '$r10';
            saveReturn(ret);
            exit;
          except
            on EConvertError do
              Raise EDraakNoCompile.Create('Incorrect type assertion.');
          end;
        end;
      end;
      case i of
        0..255:              ret := '$u1';
        256..65535:          ret := '$u2';
        65536..2147483647:   ret := '$u4';
        -128..-1:            ret := '$s1';
        -32768..-129:        ret := '$s2';
        -2147483648..-32769: ret := '$s4';
        else ret := '$s8';
      end;
    end;
  end else
    if dumbNode.isvar = false then
      ret := dumbNode.baseType
    else
      ret := dumbNode.typePtr.name;
  if length(d) > 2 then
    dumbHash.add(d[2], ret)
  else
    saveReturn(ret);
end;

procedure TMacro.contextComplete(inMacro: PHashAtom; inNode: PParseNode);
var s: string; d: strArr;
  dumbHash: TStringHash;
  c: cardinal; named: string;
begin
  s := expand(inMacro.Macro); split(s, d, 2);
  dumbHash := localed(d[2]);
  if vars.isContextComplete(d[1], c, named) then
  begin
    s := d[1];
  end else
  begin
    s := vars.lookupContext(d[1]);
    s := '.'+s+'$'+d[1];
  end;
  if length(d) > 2 then
    dumbHash.add(d[2], s)
  else
    saveReturn(s);
end;

procedure TMacro.decontextComplete(inMacro: PHashAtom; inNode: PParseNode);
var s: string; d: strArr;
  dumbHash: TStringHash;
  c: cardinal; named: string;
begin
  s := expand(inMacro.Macro); split(s, d, 2);
  dumbHash := localed(d[2]);
  vars.isContextComplete(d[1], c, named);
  if length(d) > 2 then
    dumbHash.add(d[2], named)
  else
    saveReturn(named);
end;

procedure TMacro.whileLoop(inMacro: PHashAtom; inNode: PParseNode);
begin
  if whilePlace = nil then
    whilePlace := inMacro
  else
  begin
    compare(inMacro, inNode);
    if PLocal(local.Peek).truth = Equal then
      whilePlace := nil
    else
      skipAhead := whilePlace;
  end;
end;

procedure TMacro.compare(inMacro: PHashAtom; inNode: PParseNode);
var d: strArr;

  procedure n;
  begin
    d[2] := expand(d[2]); d[3] := expand(d[3]);
    if d[2] = d[3] then
      PLocal(local.Peek).truth := Equal
    else
      PLocal(local.Peek).truth := notEqual;
  end;

  procedure v;
  var dumbVar: PVarNode;
  begin
    d[2] := expand(d[2]);
    dumbVar := vars.hashLookup(d[2]);
    if dumbVar = nil then
      PLocal(local.Peek).truth := Nonexists
    else if dumbVar.isvar = true then
      PLocal(local.Peek).truth := Exists
    else
      PLocal(local.Peek).truth := Nonexists
  end;

  procedure typeCheck;
  var dumbVar: PVarNode;
  begin
    d[2] := expand(d[2]);
    dumbVar := vars.hashLookup(d[2]);
    if dumbVar = nil then
      PLocal(local.Peek).truth := Nonexists
    else if dumbVar.isvar = false then
      PLocal(local.Peek).truth := Exists
    else
      PLocal(local.Peek).truth := Nonexists
  end;

  procedure bigN;
  var i, o: int64;
  begin
    d[2] := expand(d[2]); 
    d[3] := expand(d[3]);
    try
      i := StrToInt64(d[2]);
      o := StrToInt64(d[3]);
    except
      on EConvertError do
      begin
        PLocal(local.Peek).truth := Nonexists;
	      exit;
      end;
    end;
    if i > o then PLocal(local.Peek).truth := greater;
    if i < o then PLocal(local.Peek).truth := less;
    if i = o then PLocal(local.Peek).truth := equal;
  end;

  procedure t;
  var i: cardinal;
  begin
    d[2] := expand(d[2]);
    PLocal(local.Peek).truth := Nonexists;
    for i := vars.len downto 0 do
      if vars[i].name = d[2] then
      begin
        PLocal(local.Peek).truth := Exists;
        exit;
      end;
  end;

begin
  split(inMacro.Macro, d, 4);
  case d[1][1] of
    'e': partialCompare(inMacro, inNode);
    'E': compareEquiv(inMacro, inNode);
    'n': n;
    'N': bigN;
    'v': v;
    't': t;
    'T': typeCheck;
   else err.err('Bad compare usage: '+d[1]);
  end;
end;

procedure TMacro.compareEquiv(inMacro: PHashAtom; inNode: PParseNode);
var s1, s2, d: strArr;
 i: word;
begin
  split(inMacro.Macro, d);
  split(expand(d[2]), s1);
  split(expand(d[3]), s2);
  if length(s1) <> length(s2) then
  begin
    PLocal(local.Peek).truth := notEqual;
    exit;
  end;
  if length(s1) = 0 then
  begin
    PLocal(local.Peek).truth := Equal;
    exit;
  end;
  for i := 0 to length(s1)-1 do
  begin
    if vars.isEquiv(s1[i], s2[i]) = false then
    begin
      PLocal(local.Peek).truth := notEqual;
      exit;
    end;
  end;
  PLocal(local.Peek).truth := Equal;
end;

procedure TMacro.partialCompare(inMacro: PHashAtom; inNode: PParseNode);
var s1, s2, d: strArr;
  current: PLocal; i: word;
begin
  split(inMacro.Macro, d);
  split(expand(d[2]), s1);
  split(expand(d[3]), s2);
  current := local.peek;
  setLength(current.returns, length(current.returns)+1);
  if length(s1) = 0 then
  begin
    PLocal(local.Peek).truth := notEqual;
    exit;
  end;
  for i := 0 to length(s1)-1 do
  begin
    if i >= length(s2) then break;
    if vars.isEquiv(s1[i], s2[i]) = false then
    begin
      PLocal(local.Peek).truth := notEqual;
      exit;
    end;
  end;
  PLocal(local.Peek).truth := Equal;
  current.returns[length(current.returns)-1] := s1[i-1];
end;

procedure TMacro.use(inMacro: PHashAtom; inNode: PParseNode);
var d: strArr; s, found, foundPas: string;
  dumbGmr: TGmr; search: TSearchRec;
  tim: integer;
begin
  split(inMacro.Macro, d);
  s := expand(d[2]);
  if searchDirs = '' then searchDirs := '.';
  found := FileSearch(s+'.dgu', searchDirs);
  foundPas := FileSearch(s+'.pas', searchDirs);
  if found = '' then
  begin
    if foundPas = '' then
      Raise EDraakNoCompile.Create('Cannot find unit "'+s+'"');
    err.compile(foundPas);
  end;
  found := FileSearch(s+'.dgu', searchDirs);
  if found = '' then
    Raise EDraakNoCompile.Create('Problems using unit "'+s+'"');
  begin
    findFirst(found, faAnyFile, search);
    tim := search.Time;
    if foundPas <> '' then
      findFirst(foundPas, faAnyFile, search)
    else
      search.Time := tim-1;
    if tim > search.Time then
    begin
      dumbGmr := TGmr.init(TFile.init((found)));
      pushContext(s, inNode);
      hardenContext;
      varHash.add('uses', 'True');
      execNode(dumbGmr.getGoal.Macros, inNode);
      varHash.remove('uses');
//      err.status(s+'.pas: Compiled! ' );
      softenContext;
      exit;
    end;
  end;
  softenContext;
end;

procedure TMacro.typeAdd(s: string; inNode: PParseNode);
var name, base, temp, context: string;
 dumbContext: TVars;
 i: word; a: strArr;
begin
  temp := expand(s); split(temp, a);
  name := a[0]; base := a[1];
  if length(a) > 2 then context := a[2] else context := 'a';
  if vars.hashLookup(name, 1) <> nil then
  begin
    err.err('Type '+name+' already defined in current context');
    exit;
  end;
//  dumbContext := vars;
  i := AnsiPos(context[1], numbers);
//  for o := 1 to i do
//    dumbContext := dumbContext.pop;
  dumbContext := vars[vars.len-i];
  dumbContext.addType(name, base);
end;

procedure TMacro.basedTypeAdd(s: string; inNode: PParseNode);
var name, base, temp, context: string;
 dumbContext: TVars;
 i: word; a: strArr;
begin
  temp := expand(s); split(temp, a);
  name := a[0]; base := a[1];
  if length(a) > 2 then context := a[2] else context := 'a';
  if vars.hashLookup(s, 1) <> nil then
  begin
    err.err('Type '+s+' already defined in current context');
    exit;
  end;
//  dumbContext := vars;
  i := AnsiPos(context[1], numbers);
//  for o := 1 to i do
//    dumbContext := dumbContext.pop;
  dumbContext := vars[vars.len-i];
  dumbContext.addBasedType(name, base);
end;

procedure TMacro.pushContext(s: string; inNode: PParseNode);
var temp: string;
  tempVars: TVars;
begin
  temp := copy(s, 1, length(s));
  temp := expand(temp);
  if AnsiPos(' ', temp) <> 0 then
    temp := copy(temp, 1, AnsiPos(' ', temp)-1);
  tempVars := vars;
  vars := TVars.Create(temp, tempVars, err);
  vars.clearCurrent;
//  tempVars.clearCurrent;
end;

procedure TMacro.popContext;
begin
  vars := vars.pop;
end;

procedure TMacro.rememberContext;
begin
  vars := vars.loadContext(remember);
  vars.harden := false;
end;

procedure TMacro.saveContext(context: TVars);
begin
  context.saveContext(vars);
end;

procedure TMacro.loadContext(const s, harden: string);
var temp: TVars;
begin
  temp := vars.loadContext(s);
  if not(assigned(temp)) then
  begin
    PLocal(local.Peek).truth := Nonexists;
    err.err('Could not load context: '+s);
  end else begin
    vars := temp;
    PLocal(local.Peek).truth := Exists;
    if harden = '' then
      vars.harden := true
    else if harden[1] = 's' then
      vars.harden := false
    else
      vars.harden := true;
  end;
end;

procedure TMacro.hardenContext;
begin
  vars.harden := true;
end;
procedure TMacro.softenContext;
begin
  vars.harden := false;
end;



function TMacro.varLookup(const s: string): string;
var dumbVar: TVars;
begin
  result := '';
  if s[1] = '$' then exit;
  dumbVar := vars.lookupVar(s);
  if not(assigned(dumbVar)) then
    raise EDraakNoCompile.Create('Variable does not exist in any context: '+s);
  result := dumbVar.name;
end;

procedure TMacro.saveReturn(s: string; varSave: string = '');
var current: PLocal;
  dumbHash: TStringHash;
begin
  if (varSave = '') OR (varSave[1] = '$') then
  begin
    current := local.Peek;
    setLength(current.returns, length(current.returns)+1);
    current.returns[length(current.returns)-1] := s;
  end else
  begin
    dumbHash := localed(varSave);
    dumbHash.add(varSave, s);
  end;
end;

function TMacro.localed(var s: string): TStringHash;
{Deals with the local variables}
begin
  result := varHash;
  if s = '' then exit;
  if s[1] = '.' then
  begin
    result := PLocal(local.Peek).lvar;
    delete(s, 1, 1);
  end;
end;

procedure TMacro.getNumber(const s: string);
begin
  saveReturn(intToStr(currentNum), s);
  inc(currentNum);
end;

function TMacro.expand(s: string): string;
var i, o, p, leftBracket, rightBracket: word;
  temp: string; tempStrs: strArr;
  dumbHash: TStringHash;
begin
  result := ''; tempStrs := nil;
  while s <> '' do
  begin
    i := ansipos('$', s); o := 0;
    if i = 0 then i := length(s)
    else o := AnsiPos(s[i+1], numbers);
    if o <> 0 then
    begin                                             
      result := result+copy(s, 1, i-1);
      if length(PLocal(local.peek).returns) < o then
      begin
        Raise EDraakNoCompile.Create('Error with lenth of returns and attempted usage there of');
      end;
      result := result+PLocal(local.peek).returns[o-1];
      delete(s, 1, 1);
    end
    else result := result+copy(s, 1, i);
    delete(s, 1, i);
  end;
  s := result;
  result := '';
  while s <> '' do
  begin
    i := ansipos('&', s);
    if i = 0 then
    begin
      result := result + copy(s, 1, length(s));
      delete(s, 1, length(s));
      continue;
    end;
    temp := copy(s, i+2, length(s));
    delete(temp, AnsiPos('''', temp), length(temp));
    delete(s, i, length(temp)+3);
    dumbHash := localed(temp);

    tempStrs := dumbHash.lookup(temp);
    p := i;
    if tempStrs <> nil then
    begin
      if (i <= length(s)) AND (s[i] = '^') then
      begin
        delete(s, i, 1);
        insert('&'''+tempStrs[0]+'''', s, p);
        continue;
      end;
      if (i+2 <= length(s)) AND (s[i] = '[') then
      begin
        temp := copy(s, i+1, length(s));
        rightBracket := AnsiPos(']', temp);
        leftBracket := AnsiPos('[', temp);
        while (leftBracket > 0) AND (rightBracket > leftBracket) do
        begin
          rightBracket := AnsiPos(']', PChar(temp)+rightBracket)+rightBracket;
          leftBracket := AnsiPos('[', PChar(temp)+rightBracket)+rightBracket;
        end;
        delete(temp, rightBracket, length(temp));
        o := StrToInt(expand(temp))-1;
        delete(s, i, length(temp)+2);
        if (p <= length(s)) AND (s[p] = '^') then
        begin
          delete(s, p, 1);
          insert('&''''', s, p);
          if o < length(tempStrs) then
            insert(tempStrs[o], s, p+2);
          continue;
        end;
        if o < length(tempStrs) then
        begin
          insert(tempStrs[o]+' ', s, p);
          i := i+length(tempStrs[o]);
          delete(s, i, 1);
        end;
      end else
      begin
        for o := length(tempStrs)-1 downto 0 do
        begin
          insert(tempStrs[o]+' ', s, p);
          i := i+length(tempStrs[o]);
        end;
        delete(s, i+length(tempStrs)-1, 1);
      end;
    end;
    result := result + copy(s, 1, i-1);
    delete(s, 1, i-1);
    {Replace the var}
  end;
end;

procedure TMacro.split(s: string; out data: strArr; minSize: word = 0);
var ss: string;
 i, o: word;
begin
  ss := s; i := 0;
  while ss <> '' do
  begin
    while (ss <> '') AND (ss[1] = ' ') do
      delete(ss, 1, 1);
    if ss = '' then continue;
    setlength(data, i+1);
    o := AnsiPos(' ', ss);
    if o = 0 then o := length(ss)+1;
    data[i] := Copy(ss, 0, o-1);
    delete(ss, 1, o); i := i + 1;
  end;
//  if minSize > 0 then
    if length(data) < minSize then
      setLength(data, minSize);
end;

function TMacro.join(data: strArr; doExpand: boolean = false; lower: word = 0; upper: word = 65535): string;
var i: word;
begin
  result := '';
  for i := lower to length(data)-1 do
  begin
    if i > upper then break;
    if doExpand = false then
      result := result + data[i]+' '
    else
      result := result + expand(data[i])+' ';
  end;
  if (length(result) > 0) then
    delete(result, length(result), 1);
end;

begin
  numbers := '1234567890';
end.
