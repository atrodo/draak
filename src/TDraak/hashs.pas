(* **************************************************************** *)
(*     Copyright (C) 1999-2010, Jon Gentle, All right reserved.     *)
(* **************************************************************** *)
(* This program is free software; you can redistribute it under the *)
(* terms of the Artistic License, as specified in the LICENSE file. *)
(* **************************************************************** *)

unit hashs;

interface
uses error;

Const HashSize = 50;
type
  AtomType = (Macro, Terminal, NonTerminal, id, str, num, hex, oct, bin);

  strArr = array of string;
  varArr = array[0..9] of string;

  PHashAtom = ^RHashAtom;
  RHashAtom = record
    next: PHashAtom;
    optional, star: boolean;
    case term: AtomType of
      Terminal: (terminal: PChar);
      NonTerminal: (nonTerminal: PChar; hashCode: word);
      Macro: (Macro: PChar;)
  end;

  PHashNode = ^RHashNode;
  RHashNode = record
    name: string;
    next: PHashNode;
    special: boolean;
    RHS, lastRHS: PHashAtom;
    Macros, lastMacro: PHashAtom;
  end;


  PHash = ^THash;
  THash = class
    private
      optin, star: boolean;
      table: array[0..HashSize] of PHashNode;
      current: PHashNode;
    public
      destructor destroy; override;
      procedure add(const named: string);
      procedure addRHS(const inS: string);
      procedure addToRHS(const s: string);
      procedure addMacro(const s: string);
      procedure clearCurrent;
      function hashLookup(const S: string): PHashNode; overload;
      function hashLookup(const S: string; hint: word; count: word = 0): PHashNode; overload;
  end;

  PStringHash = ^RStringHash;
  RStringHash = record
    name: string;
    data: strArr;
    next: PStringHash;
  end;

  TStringHash = class
    private
      table: array[0..HashSize] of PStringHash;
    public
      destructor destroy; override;
      procedure add(s: string; data: string);
      procedure remove(s: string);
      procedure removeStr(s: string; data: string);
      procedure removeStrEnd(s: string; data: string);
      procedure empty;
      procedure inc(s, num: string);
      procedure append(s, data: string);
      procedure strictAppend(s, data: string);
      procedure insert(s, data: string);
      function first(s: string): string;
      function last(s: string): string;
      function len(s: string): string;
      function pos(s, data: string): string;
      function getSubStr(s: string; n: word): string;
      function lookup(s: string): strArr;
      function copy: TStringHash;
  end;

  PVars = ^TVars;

  PVarNode = ^RVarNode;
  RVarNode = record
    name: string;
    next: PVarNode;
    isvar: boolean;
    baseType, nameType: string;
    equiv: strArr;
    local: TStringHash;
    typePtr: PVarNode;
    attachPtr: PVarNode;
    size: word;
    context: PVars;
    RHS, lastRHS: PHashAtom;
    LHS, lastLHS: PHashAtom;
//    ALT,
    lastALT: PHashAtom;
    ALT: array of PHashAtom;
    Decl, lastDecl: PHashAtom;
    altDecl, lastAltDecl: PHashAtom;
  end;

  TVars = class;
  varsArr = array of TVars;
  TVars = class
    private
      FName: string;
      table: array[0..HashSize] of PVarNode;
      current: PVarNode;
      hard: boolean;
      next: varsArr;
      all: varsArr;
      first: TVars;
      err: TError;
      procedure setItem(index: integer; value: TVars);
      function getItem(index: integer): TVars;
      function getLen: integer;
    public
      property harden: boolean write hard;
      property name: string read FName; 
      property items[index: integer]: TVars read getItem write setItem; default;
      property len: integer read getLen;
      constructor Create(const named: string; nextHash: TVars; error: TError);
      destructor destroy; override;
      procedure addVar(const named: string; const typed: string);
      procedure addType(const named: string; const base: string);
      procedure addBasedType(const named: string; const base: string);
      procedure attachType(const s: string);
      procedure addLHS(const s: string);
      procedure addRHS(const s: string);
      procedure addALT(const s: string);
      procedure addDecl(const s: string);
      procedure addAltDecl(const s: string);
      procedure clearCurrent;
      function pop: TVars;
      function isEquiv(const s, base: string): boolean;
      function isContextComplete(const s: string; out context: cardinal; out named: string): boolean;
      procedure addEquiv(const s, base: string);
      procedure saveLocal(const s: TStringHash);
      function getLocal(const s: string): TStringHash;
      procedure saveContext(context: TVars);
      function loadContext(value: TVars): TVars; overload;
      function loadContext(const s: string): TVars; overload;
      function lookupVar(const s: string): TVars;
      function lookupContext(const s: string): string;
      function hashLookup(const S: string; deep: integer = -1; count: integer = -1): PVarNode;
      procedure dump;
      procedure debugPrintHashes;   {Used for debugging}
      procedure debugPrintAllHashes;{Used for debugging}
      procedure rmVar(const named: string);
      function loadContextBlock(const S: string): TVars;
  end;


  function hash(s: string): word;
  procedure DestroyHash(inHash: PHashNode);

implementation

uses SysUtils, StrUtils, classes, draak;

function hash(s: string): word;
const hashCode = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
var i: word; tempHash: integer;
begin
  tempHash := 0; s := AnsiUpperCase(s);
  for i := 1 to length(s) do
  begin
    tempHash := tempHash + AnsiPos(s[i], hashCode);
  end;
  result := tempHash MOD HashSize;
end;

procedure DestroyHash(inHash: PHashNode);
var
  dumbNode, nextNode: PHashNode;
  dumbAtom, nextAtom: PHashAtom;
begin
    dumbNode := inHash;
    while assigned(dumbNode) do
    begin
      nextNode := dumbNode.next;
      dumbAtom := dumbNode.RHS;
      while assigned(dumbAtom) do
      begin
        nextAtom := dumbAtom.next;
        dispose(dumbAtom.terminal);
        dispose(dumbAtom);
        dumbAtom := nextAtom;
      end;
      dumbAtom := dumbNode.Macros;
      while assigned(dumbAtom) do
      begin
        nextAtom := dumbAtom.next;
        dispose(dumbAtom.Macro);
        dispose(dumbAtom);
        dumbAtom := nextAtom;
      end;
      dispose(dumbNode);
      dumbNode := nextNode;
    end;
end;

destructor THash.destroy;
var i: cardinal;
begin
  for i := 0 to hashSize do
  begin
    DestroyHash(table[i]);
  end;
  current := nil;
  inherited destroy;
end;

procedure THash.add(const named: string);
var dumbNode: PHashNode;
  hashCode: word;
begin
  new(dumbNode);
  dumbNode.special := false;
  dumbNode.name := named;
  hashCode := hash(named);
  dumbNode.next := table[hashCode];
  dumbNode.RHS := nil; dumbNode.lastRHS := nil;
  dumbNode.Macros := nil; dumbNode.lastMacro := nil;
  table[hashCode] := dumbNode;
  current := dumbNode;
end;

procedure THash.addRHS(const inS: string);
var s, tempS: string;
  posStr: word;
begin
  optin := false;
  s := inS;
  while s <> '' do
  begin
    case s[1] of
     ' ':
      begin
        delete(s, 1, 1);
        continue;
      end;
     '{':
      begin
        delete(s, 1, 1);
        optin := true;
      end;
     '}':
      begin
        delete(s, 1, 1);
        optin := false;
      end;
     '*':
      begin
       star := false;
       optin := false;
       delete(s, 1, 1);
      end;
     '<':
      begin
        posStr := AnsiPos('>', s);
        if s[posStr+1] = '*' then star := true else star := false;
        addToRHS(leftStr(s, posStr));
        delete(s, 1, posStr);
        tempS := '';
      end;
     else
      begin
        posStr := AnsiPos('<', s);
        if (s[1] = '\') AND (s[2] = '*') then
          delete(s, 1, 1);
        if (s[1] = '\') AND (s[2] = '}') then
          delete(s, 1, 1);
        if posStr <> 0 then
        begin
          if s[posStr-1] = '\' then
          begin
            delete(s, posStr-1, 1);
            tempS := tempS + leftStr(s, posStr-1);
            delete(s, 1, posStr-1);
            continue;
          end else
          if s[posStr-1] = '{' then
            dec(posStr);
        end else posStr := length(s)+1;
        if tempS <> '' then if tempS[1] = '<' then insert(' ', tempS, 1);
        addToRHS(tempS + leftStr(s, posStr-1));
        delete(s, 1, posStr-1);
      end;
    end;
  end;
  if tempS = '<' then
    addToRHS(' <');
end;

procedure THash.addToRHS(const s: string);
var dumbAtom: PHashAtom;
begin
  if current = nil then exit;
  new(dumbAtom);
  dumbAtom.next := nil;
  dumbAtom.optional := optin;
  dumbAtom.star := star;
  if star = true then dumbAtom.optional := true;
//  dumbAtom.plus := plus;
  if AnsiSameText(s, '<id>') = true then
  begin
    dumbAtom.term := id;
    dumbAtom.nonTerminal := nil;
  end else
  if AnsiSameText(s, '<str>') = true then
  begin
    dumbAtom.term := str;
    dumbAtom.nonTerminal := nil;
  end else
  if AnsiSameText(s, '<num>') = true then
  begin
    dumbAtom.term := num;
    dumbAtom.nonTerminal := nil;
  end else
  if AnsiSameText(s, '<hex>') = true then
  begin
    dumbAtom.term := hex;
    dumbAtom.nonTerminal := nil;
  end else
  if AnsiSameText(s, '<oct>') = true then
  begin
    dumbAtom.term := oct;
    dumbAtom.nonTerminal := nil;
  end else
  if AnsiSameText(s, '<bin>') = true then
  begin
    dumbAtom.term := bin;
    dumbAtom.nonTerminal := nil;
  end else
  if s[1] = '<' then
  begin
    dumbAtom.term := nonTerminal;
    getMem(dumbAtom.nonTerminal, length(s)+1);
    strcopy(dumbAtom.nonTerminal, PChar(trim(s)));
    dumbAtom.hashCode := hash(s);
  end else
  begin
    dumbAtom.term := terminal;
    getMem(dumbAtom.terminal, length(s)+1);
    strcopy(dumbAtom.terminal, PChar(trim(s)));
  end;
  if current.lastRHS = nil then
  begin
    current.RHS := dumbAtom;
    current.lastRHS := dumbAtom;
  end else
  begin
    current.lastRHS.next := dumbAtom;
    current.lastRHS := dumbAtom;
  end;
end;

procedure THash.addMacro(const s: string);
var dumbAtom: PHashAtom;
begin
  trim(s);
  if current = nil then exit;
  new(dumbAtom);
  dumbAtom.next := nil;
  dumbAtom.term := macro;
  getMem(dumbAtom.macro, length(s)+1);
  strcopy(dumbAtom.macro, PChar(trim(s)));
  if current.lastMacro = nil then
  begin
    current.Macros := dumbAtom;
    current.lastMacro := dumbAtom;
  end else
  begin
    current.lastMacro.next := dumbAtom;
    current.lastMacro := dumbAtom;
  end;
end;

procedure THash.clearCurrent;
begin
  current := nil;
end;

function THash.hashLookup(const s: string): PHashNode;
begin
  result := hashLookup(s, hash(s));
end;

function THash.hashLookup(const s: string; hint: word; count: word): PHashNode;
var i: word;
begin
  result := table[hint];
  for i := 0 to count do
  begin
    while (result <> nil) and (AnsiCompareText(result.name, s) <> 0) do
    begin
      result := result.next;
    end;
    if result = nil then exit;
    if i <> count then
      result := result.next;
  end;
end;

constructor TVars.Create(const named: string; nextHash: TVars; error: TError);
begin
  if nextHash = nil then
  begin
    first := self; setLength(next, 0);
    setLength(all, 1); all[0] := self;
  end else
  begin
    next := nextHash.next;
    first := nextHash.first;
    setLength(first.all, length(first.all)+1);
    first.all[length(first.all)-1] := self;
  end;
  self[length(next)] := self;
  FName := named;
  err := error;
end;

destructor TVars.Destroy;
var i: cardinal;
  dumbNode, nextNode: PVarNode;
begin
  if length(all) <> 0 then
  begin
    for i := 1 to length(all)-1 do
      all[i].Free;
  end;
  for i := 0 to hashSize do
  begin
    dumbNode := table[i];
    while assigned(dumbNode) do
    begin
      nextNode := dumbNode.next;
      dispose(dumbNode);
      dumbNode := nextNode;
    end;
  end;
end;

procedure TVars.setItem(index: integer; value: TVars);
begin
  if index >= length(next) then
  begin
    setLength(next, length(next)+1);
    next[length(next)-1] := value;
  end;
end;

function TVars.getItem(index: integer): TVars;
begin
  if index > length(next) then
    raise Exception.Create('Range is out of bounds ('+intToStr(index)+')');
  result := next[index] as TVars;
end;

function TVars.getLen: integer;
begin
  result := length(next)-1;
end;

procedure TVars.addVar(const named: string; const typed: string);
var dumbNode: PVarNode;
  hashCode: word;
begin
  if assigned(self.hashLookup(named, 1)) then
    Raise EDraakNoCompile.Create('Variable already exists: '+named);
  new(dumbNode);
  dumbNode.isvar := true;
  dumbNode.name := named;
  dumbNode.attachPtr := nil;  
  dumbNode.typePtr := hashLookup(typed);
  if dumbNode.typePtr = nil then
  begin
    err.err('No such type: ' + typed);
    exit;
  end;
  dumbNode.nameType := dumbNode.typePtr.name;
  dumbNode.baseType := dumbNode.typePtr.baseType;
  hashCode := hash(named);
  dumbNode.next := table[hashCode];
  dumbNode.context := nil;
  dumbNode.RHS := nil; dumbNode.lastRHS := nil;
  dumbNode.LHS := nil; dumbNode.lastLHS := nil;
  dumbNode.ALT := nil; dumbNode.lastALT := nil;
  dumbNode.Decl := nil; dumbNode.lastDecl := nil;
  dumbNode.altDecl := nil; dumbNode.lastAltDecl := nil;
  setLength(dumbNode.equiv, 0);
  dumbNode.local := TStringHash.Create;
  table[hashCode] := dumbNode;
  current := dumbNode;
end;

procedure TVars.addBasedType(const named: string; const base: string);
var dumbNode, basePtr: PVarNode;
  hashCode: word;
begin
  new(dumbNode);
  dumbNode.name := named;
  dumbNode.isVar := false;
  dumbNode.attachPtr := nil;  
  hashCode := hash(named);
  dumbNode.next := table[hashCode];
  setLength(dumbNode.equiv, 0);
  if base[1] = '$' then
  begin
    err.err('Can not @T a basic type ('+base+').');
  end;
  basePtr := hashLookup(base);
  if basePtr = nil then
  begin
    err.err('No such type: '+base);
    exit;
  end;
  dumbNode.baseType := basePtr.baseType;
  dumbNode.equiv := copy(basePtr.equiv, 0, length(basePtr.equiv));

  dumbNode.nameType := base;
  dumbNode.typePtr := nil;
  dumbNode.context := basePtr.context;
  dumbNode.attachPtr := basePtr;
  dumbNode.RHS := basePtr.RHS; dumbNode.lastRHS := basePtr.lastRHS;
  dumbNode.LHS := basePtr.LHS; dumbNode.lastLHS := basePtr.lastLHS;
  dumbNode.ALT := basePtr.ALT; dumbNode.lastALT := basePtr.lastALT;
  dumbNode.Decl := basePtr.Decl; dumbNode.lastDecl := basePtr.lastDecl;
  dumbNode.altDecl := basePtr.altDecl; dumbNode.lastAltDecl := basePtr.lastAltDecl;
  setLength(dumbNode.equiv, length(dumbNode.equiv)+1);
  dumbNode.equiv[length(dumbNode.equiv)-1] := base;
  dumbNode.local := basePtr.local;
  table[hashCode] := dumbNode;
  current := dumbNode;
end;

procedure TVars.addType(const named: string; const base: string);
var dumbNode, basePtr: PVarNode;
  hashCode: word;
begin
  new(dumbNode);
  dumbNode.name := named;
  dumbNode.isVar := false;
  dumbNode.attachPtr := nil;
  hashCode := hash(named);
  dumbNode.next := table[hashCode];
  setLength(dumbNode.equiv, 0);
  if base[1] <> '$' then
  begin
    basePtr := hashLookup(base);
    if basePtr = nil then
    begin
      err.err('No such type: '+base);
      exit;
    end;
    dumbNode.baseType := basePtr.baseType;
    dumbNode.equiv := copy(basePtr.equiv, 0, length(basePtr.equiv));
  end else
    dumbNode.baseType := named;
  dumbNode.nameType := base;
  dumbNode.typePtr := nil;
  dumbNode.context := nil;
  dumbNode.RHS := nil; dumbNode.lastRHS := nil;
  dumbNode.LHS := nil; dumbNode.lastLHS := nil;
  dumbNode.ALT := nil; //dumbNode.lastALT := nil;
  dumbNode.Decl := nil; dumbNode.lastDecl := nil;
  dumbNode.altDecl := nil; dumbNode.lastAltDecl := nil;
  setLength(dumbNode.equiv, length(dumbNode.equiv)+1);
  dumbNode.equiv[length(dumbNode.equiv)-1] := base;
  dumbNode.local := TStringHash.Create;
  table[hashCode] := dumbNode;
  current := dumbNode;
end;

procedure TVars.attachType(const s: string);
var dumbNode, basePtr: PVarNode;
begin
  basePtr := hashLookup(s);
  if basePtr = nil then
  begin
    err.err('No such type: '+s);
    exit;
  end;
  dumbNode := Self.current;
  dumbNode.attachPtr := basePtr;
  if dumbNode.RHS = nil then
  begin
    dumbNode.RHS := basePtr.RHS; dumbNode.lastRHS := basePtr.lastRHS;
  end;
  if dumbNode.LHS = nil then
  begin
    dumbNode.LHS := basePtr.LHS; dumbNode.lastLHS := basePtr.lastLHS;
  end;
  if dumbNode.ALT = nil then
  begin
    dumbNode.ALT := basePtr.ALT; dumbNode.lastALT := basePtr.lastALT;
  end;
  if dumbNode.Decl = nil then
  begin
    dumbNode.Decl := basePtr.Decl; dumbNode.lastDecl := basePtr.lastDecl;
  end;
  if dumbNode.altDecl = nil then
  begin
    dumbNode.altDecl := basePtr.altDecl; dumbNode.lastAltDecl := basePtr.lastAltDecl;
  end;
end;

procedure TVars.addLHS(const s: string);
var dumbAtom: PHashAtom;
begin
  trim(s);
  if current = nil then exit;
  new(dumbAtom);
  dumbAtom.next := nil;
  getMem(dumbAtom.Macro, length(s)+1);
  strcopy(dumbAtom.Macro, PChar(trim(s)));
  if current.lastLHS = nil then
    current.LHS := dumbAtom
  else
    current.lastLHS.next := dumbAtom;
  current.lastLHS := dumbAtom;
end;

procedure TVars.addRHS(const s: string);
var dumbAtom: PHashAtom;
begin
  trim(s);
  if current = nil then exit;
  new(dumbAtom);
  dumbAtom.next := nil;
  getMem(dumbAtom.Macro, length(s)+1);
  strcopy(dumbAtom.Macro, PChar(trim(s)));
  if current.lastRHS = nil then
    current.RHS := dumbAtom
  else
    current.lastRHS.next := dumbAtom;
  current.lastRHS := dumbAtom;
end;

procedure TVars.addALT(const s: string);
var dumbAtom: PHashAtom;
begin
//  trim(s);
  if current = nil then exit;
{  if s  = '' then
  begin
     setLength(current.ALT, length(current.ALT)+1);
     current.lastALT := nil;
  end else}
  case s[1] of
    '!', '@', '+', '*', '?':
      if length(current.ALT) = 0 then
      begin
        setLength(current.ALT, 1);
  new(dumbAtom);
  dumbAtom.next := nil;
  dumbAtom.Macro := '';
        current.lastALT := dumbAtom;
        current.ALT[0] := dumbAtom;
      end;
   else
   begin
     setLength(current.ALT, length(current.ALT)+1);
     current.lastALT := nil;
   end;
  end;
  new(dumbAtom);
  dumbAtom.next := nil;
  getMem(dumbAtom.Macro, length(s)+1);
  strcopy(dumbAtom.Macro, PChar(trim(s)));
  if current.lastALT = nil then
  begin
    current.ALT[length(current.ALT)-1] := dumbAtom;
  end
//    current.ALT := dumbAtom
  else
    current.lastALT.next := dumbAtom;
  current.lastALT := dumbAtom;
end;

procedure TVars.addDecl(const s: string);
var dumbAtom: PHashAtom;
begin
  trim(s);
  if current = nil then exit;
  new(dumbAtom);
  dumbAtom.next := nil;
  getMem(dumbAtom.Macro, length(s)+1);
  strcopy(dumbAtom.Macro, PChar(trim(s)));
  if current.lastDecl = nil then
    current.Decl := dumbAtom
  else
    current.lastDecl.next := dumbAtom;
  current.lastDecl := dumbAtom;
end;

procedure TVars.addAltDecl(const s: string);
var dumbAtom: PHashAtom;
begin
  trim(s);
  if current = nil then exit;
  new(dumbAtom);
  dumbAtom.next := nil;
  getMem(dumbAtom.Macro, length(s)+1);
  strcopy(dumbAtom.Macro, PChar(trim(s)));
  if current.lastAltDecl = nil then
    current.altDecl := dumbAtom
  else
    current.lastAltDecl.next := dumbAtom;
  current.lastAltDecl := dumbAtom;
end;

procedure TVars.clearCurrent;
begin
  current := nil;
end;

function TVars.pop: TVars;
var i: cardinal;
begin
  result := next[length(next)-2] as TVars;
  for i := length(next)-2 downto 1 do
    if next[i] = self then break;
  setLength(next, i+1);
end;

function TVars.isEquiv(const s, base: string): boolean;
var baseTemp, sTemp: PVarNode;
 i: word;
begin
  result := false;
  if s = base then result := true;
  if base[1] = '$' then
  begin
    baseTemp := hashlookup(s);
    if baseTemp = nil then
        Raise EDraakNoCompile.Create('Error: Could not find type/var: '+s);
    for i := 0 to length(baseTemp.equiv)-1 do
      if base = baseTemp.equiv[i] then result := true
  end else
  begin
    baseTemp := hashlookup(base);
    if baseTemp = nil then
        Raise EDraakNoCompile.Create('Error: Could not find type/var: '+ base+' '+s);
    if baseTemp.isvar = true then
    begin
      baseTemp := baseTemp.typePtr;
      if baseTemp.name = s then result := true;
    end;
    for i := 0 to length(baseTemp.equiv)-1 do
      if s = baseTemp.equiv[i] then result := true;
    if (result = false){ and (baseTemp.baseType <> base)} then
    begin
      sTemp := hashLookup(s);
      if sTemp = nil then exit;
      if sTemp.isvar = true then
        sTemp := sTemp.typePtr;
      if (sTemp.baseType = s) AND (baseTemp.baseType = base) then exit;
      result := isEquiv(sTemp.baseType, baseTemp.baseType);
    end;
  end;
end;

function TVars.isContextComplete(const s: string; out context: cardinal; out named: string): boolean;
var i, o, n: cardinal;
const num = '0123456789';
begin
  context := 0;
  named := '';
  result := false;
  o := length(s);
  if s[1] <> '.' then exit;
  for i := 2 to length(s)-1 do
  begin
    o := i;
    n := pos(s[i], num);
    if (n = 0) and (s[i] <> '$') then exit;
    if (n = 0) and (s[i] = '$') then break;
    context := context * 10 + (n - 1);
  end;
  if o = cardinal(length(s)) then exit;
  named := copy(s, o+1, length(s));
  result := true;
end;

procedure TVars.addEquiv(const s, base: string);
var temp, baseTemp: PVarNode;
 i: word;
begin
  temp := hashLookup(s); baseTemp := hashlookup(base);
  if temp = nil then begin err.err('No such type for equivalance: ' + s); exit; end;
  if baseTemp = nil then
    begin err.err('No such base type for equivalance: ' + base); exit; end;
  for i := 0 to length(baseTemp.equiv)-1 do
  begin
    if isEquiv(baseTemp.equiv[i], s) = true then continue;
    setLength(temp.equiv, length(temp.equiv)+1);
    temp.equiv[length(temp.equiv)-1] := baseTemp.equiv[i];
  end;
  setLength(temp.equiv, length(temp.equiv)+1);
  temp.equiv[length(temp.equiv)-1] := base;
end;

procedure TVars.saveLocal(const s: TStringHash);
begin
  current.local := s.copy;
end;

function TVars.getLocal(const s: string): TStringHash;
var dumbNode: PVarNode;
begin
  result := nil;
  dumbNode := hashLookup(s);
  if dumbNode = nil then exit;
  result := dumbNode.local;
end;

procedure TVars.saveContext(context: TVars);
begin
  current.context := PVars(context);
end;

function TVars.loadContext(value: TVars): TVars;
begin
  result := value;
  result.next := next;
  result.items[length(result.next)] := result;
end;

function TVars.loadContext(const s: string): TVars;
var dumbNode: PVarNode;
begin
  dumbNode := hashLookup(s);
  if dumbNode = nil then result := nil
  else begin
    if dumbNode.isvar = true then
      result := TVars(dumbNode.typePtr.context)
    else
      result := TVars(dumbNode.context);
    if result = nil then exit;
    result.next := next;
    result.items[length(result.next)] := result;
  end;
end;

function TVars.lookupVar(const s: string): TVars;
var i: cardinal;
begin
  result := nil;
  for i := length(next)-1 downto 0 do
    if (next[i] as TVars).hashLookup(s, 1) <> nil then
      begin result := next[i] as TVars; break; end;
end;

function TVars.lookupContext(const s: string): string;
var o, i: cardinal;
begin
  result := ''; o := length(next)+1;
  for i := length(next)-1 downto 0 do
    if next[i].hashLookup(s, 1) <> nil then
      begin o := i; break; end;
  if o > length(next) then exit;
  for i := 0 to length(first.all)-1 do
    if next[o] = first.all[i] then
    begin
      result := intToStr(i);
      break;
    end;
end;

function TVars.hashLookup(const S: string; deep: integer = -1; count: integer = -1): PVarNode;
var c: cardinal; named: string;
begin
  if isContextComplete(s, c, named) = true then
  begin
    result := first.all[c].hashLookup(named, 1, 1);
    exit;
  end;
  if deep = 0 then
  begin
    result := nil;
    exit;
  end;
  if count = -1 then count := length(next)-1;
  result := table[hash(s)];
  while (result <> nil) and (AnsiCompareText(result.name, s) <> 0) do
  begin
    result := result.next;
  end;
  if (hard = true) AND (result = nil) AND (count <> 0) then
    result := (next[0] as TVars).hashLookup(s)
  else
  if (hard = false) AND (result = nil) AND (count >= 1) then
    result := (next[count-1] as TVars).hashLookup(s, deep-1, count-1);
end;

procedure TVars.dump;
var v, t: TStringList;

procedure dumbContext(value: TVars);
var i, o, j: word;
  dumbVars: PVarNode;
  dumbHash: PStringHash;
  dumbAtom: PHashAtom;
  n: string;
  s: ^TStringList;
begin
  with value do
  begin
  for i := 0 to HashSize do
  begin
    dumbVars := table[i];
    while dumbVars <> nil do
    begin
      n := dumbVars.name;
      if dumbVars.isvar = false then
      begin
        t.Append('@t ' + n + ' ' + dumbVars.baseType);
        if dumbVars.context <> nil then
        begin
          t.Append('@N '+TVars(dumbVars.context).name);
          dumbContext(TVars(dumbVars.context));
          t.Append('@c1');
          t.Append('@n');
        end;
        s := @t;
      end else
      begin
        v.Append('@V ' + n + ' ' + dumbVars.typePtr.name);
        s := @v;
      end;
      if length(dumbVars.equiv) > 0 then
        for o := 0 to length(dumbVars.equiv)-1 do
          if dumbVars.equiv[o][1] <> '$' then
            v.append('@e ' + n + ' ' + dumbVars.equiv[o]);
      s.Append('!v C');
      {for o := 0 to 9 do
        if dumbVars.local[o] <> '' then
          s.append('!v s ''' + intToStr((o+1) MOD 10) + ''' ' + dumbVars.local[o]);}
      for o := 0 to hashSize do
      begin
        dumbHash := dumbVars.local.table[o];
        while dumbHash <> nil do
        begin
          n := '';
          if length(dumbHash.data) > 0 then
          for j := 0 to length(dumbHash.data)-1 do
            n := n + dumbHash.data[j];
          s.Append('!v s .'+dumbHash.name+' '+n);
          dumbHash := dumbHash.next;
        end;
      end;
      s.append('@s');
      if dumbVars.attachPtr <> nil then
        s.Append('@E '+dumbVars.attachPtr.name)
      else
      begin
        dumbAtom := dumbVars.RHS;
        while dumbAtom <> nil do
        begin
          s.append('@r ' + dumbAtom.Macro);
          dumbAtom := dumbAtom.next;
        end;
        dumbAtom := dumbVars.LHS;
        while dumbAtom <> nil do
        begin
          s.append('@l ' + dumbAtom.Macro);
          dumbAtom := dumbAtom.next;
        end;
        if length(dumbVars.Alt) > 0 then for o := 0 to length(dumbVars.ALT)-1 do
        begin
	        dumbAtom := dumbVars.ALT[o];
          while dumbAtom <> nil do
          begin
            s.append('@a ' + dumbAtom.Macro);
            dumbAtom := dumbAtom.next;
          end;
        end;
        dumbAtom := dumbVars.Decl;
        while dumbAtom <> nil do
        begin
          s.append('@d ' + dumbAtom.Macro);
          dumbAtom := dumbAtom.next;
        end;
        dumbAtom := dumbVars.altDecl;
        while dumbAtom <> nil do
        begin
          s.append('@D ' + dumbAtom.Macro);
          dumbAtom := dumbAtom.next;
        end;
      end;
      s.append('');
      dumbVars :=dumbVars.next;
    end;
  end;
  end;
end;

begin
  v := TStringList.Create;
  t := TStringList.Create;
  t.append('<Goal> -> . ');
  try
    dumbContext(self);
  finally
    t.AddStrings(v);
    t.SaveToFile(name+'.dgu');
  end;
// err.stream(t.Text);
end;

procedure TVars.rmVar(const named: string);
var dumbNode, prevNode: PVarNode;
begin
  dumbNode := table[hash(named)];
  prevNode := dumbNode;
  if dumbNode.name = named then
  begin
    if dumbNode.isvar = false then exit;
    table[hash(named)] := dumbNode.next;
  end else
  begin
    while assigned(dumbNode) AND (dumbNode.name <> named) do
    begin
      prevNode := dumbNode;
      dumbNode := dumbNode.next;
    end;
    if not assigned(dumbNode) then exit;
    if dumbNode.isvar = false then exit;
    prevNode.next := dumbNode.next;
  end;
  dispose(dumbNode);
end;

procedure TVars.debugPrintAllHashes;
var i: cardinal;
begin
  if self <> self.first then
    first.debugPrintAllHashes;
  if length(all) < 1 then exit;
  for i := 0 to length(all)-1 do
    if assigned(all[i]) then
      all[i].debugPrintHashes;
end;

procedure TVars.debugPrintHashes;
var
  i: cardinal;
  walker: PVarNode;
  s: string;
begin
  if not assigned(err) then exit;
  err.stream('=======================================');
  //err.stream('Level: '+ intToStr(length(next)));
  err.stream('Buckets: '+ intToStr(HashSize+1));
  err.stream('Name: '+name);
  err.stream('');
  for i:=0 to HashSize do
    begin
      //err.stream('B'+ intToStr(i)+ ': ');
      s := 'B'+ intToStr(i)+ ': ';
      walker:=table[i];
      while walker<>nil do
      begin
        s := s + '['+walker.name+'] '+walker.baseType+' ';
        if walker.isVar = true then
          s := s + 'V '
        else
          s := s + 'T ';
        //err.stream('['+walker.name+'] ');
        walker:=walker.next;
      end;
      err.stream(s);
    end;
    
//  if length(next)>=2 then
//    (next[length(next)-2] as TVars).debugPrintHashes;
end;


function TVars.loadContextBlock(const s: string): TVars;
var i: word;
begin
  result := nil;
  for i := len downto 0 do
    if (next[i] as TVars).name = s then
      result := loadContext(next[i] as TVars);
end;

procedure split(s: string; out data: strArr);
var ss: string;
 i, o: word;
begin
  ss := s; i := 0;
  while ss <> '' do
  begin
    while ss[1] = ' ' do
      delete(ss, 1, 1);
    setlength(data, i+1);
    o := AnsiPos(' ', ss);
    if o = 0 then o := length(ss)+1;
    data[i] := Copy(ss, 0, o-1);
    delete(ss, 1, o); i := i + 1;
  end;
end;

destructor TStringHash.destroy;
var i: cardinal;
  dumbNode, nextNode: PStringHash;
begin
  for i := 0 to HashSize do
  begin
    dumbNode := table[i];
    while dumbNode <> nil do
    begin
      nextNode := dumbNode.next;
      dispose(dumbNode);
      dumbNode := nextNode;
    end;
  end;
end;

procedure TStringHash.add(s: string; data: string);
var i: word; dumbNode: PStringHash;
begin
  remove(s);
  i := hash(s);
  new(dumbNode);
  dumbNode.next := table[i];
  table[i] := dumbNode;
  dumbNode.name := s;
  split(data, dumbNode.data);
end;

procedure TStringHash.remove(s: string);
var dumbNode, aNode: PStringHash;
begin
  dumbNode := table[hash(s)];
  if dumbNode = nil then exit;
  if dumbNode.name = s then
  begin
    aNode := dumbNode;
    table[hash(s)] := dumbNode.next;
    setLength(aNode.data, 0);
    dispose(aNode);
    exit;
  end;
  while (dumbNode.next <> nil) AND (dumbNode.next.name <> s) do
    dumbNode := dumbNode.next;
  if (dumbNode.next = nil) AND (dumbNode.name <> s) then
    exit;
  aNode := dumbNode.next;
  dumbNode.next := dumbNode.next.next;
  setLength(aNode.data, 0);
  dispose(aNode);
end;

procedure TStringHash.removeStr(s: string; data: string);
var i, o: word;
  dumbNode: PStringHash;
begin
  dumbNode := table[hash(s)];
  if dumbNode = nil then exit;
  while (dumbNode.next <> nil) AND (dumbNode.name <> s) do
    dumbNode := dumbNode.next;
  if (dumbNode.next = nil) AND (dumbNode.name <> s) then
    exit;
  if length(dumbNode.data) > 0 then
  for i := 0 to length(dumbNode.data)-1 do
  begin
    if dumbNode.data[i] = data then
    begin
      if i <> length(dumbNode.data)-1 then
      for o := i to length(dumbNode.data)-2 do
        dumbNode.data[o] := dumbNode.data[o+1];
      setLength(dumbNode.data, length(dumbNode.data)-1);
      exit;
    end;
  end;
end;

procedure TStringHash.removeStrEnd(s: string; data: string);
var i, o: word;
  dumbNode: PStringHash;
begin
  dumbNode := table[hash(s)];
  if dumbNode = nil then exit;
  while (dumbNode.next <> nil) AND (dumbNode.name <> s) do
    dumbNode := dumbNode.next;
  if (dumbNode.next = nil) AND (dumbNode.name <> s) then
    exit;
  if length(dumbNode.data) > 0 then
  for i := length(dumbNode.data)-1 downto 0 do
  begin
    if dumbNode.data[i] = data then
    begin
      if i <> length(dumbNode.data)-1 then
      for o := i to length(dumbNode.data)-2 do
        dumbNode.data[o] := dumbNode.data[o+1];
      setLength(dumbNode.data, length(dumbNode.data)-1);
      exit;
    end;
  end;
end;

procedure TStringHash.empty;
var i: cardinal;
  dumbNode, nextNode: PStringHash;
begin
  for i := 0 to HashSize do
  begin
    dumbNode := table[i];
    while dumbNode <> nil do
    begin
      nextNode := dumbNode.next;
      dispose(dumbNode);
      dumbNode := nextNode;
    end;
    table[i] := nil;
  end;
end;

procedure TStringHash.inc(s, num: string);
var dumbNode: PStringHash;
 i: integer;
begin
  if num = '' then num := '1';
  i := hash(s);
  dumbNode := table[i];
  while (dumbNode <> nil) AND (dumbNode.name <> s) do
    dumbNode := dumbNode.next;
  if dumbNode = nil then exit;
  i := strToInt(dumbNode.data[0]);
  case num[1] of
   '|':
    begin
      delete(num, 1, 1);
      i := i OR strToInt(num);
    end;
   '^':
    begin
      delete(num, 1, 1);
      i := i XOR strToInt(num);
    end;
   '*':
    begin
      delete(num, 1, 1);
      i := i * strToInt(num);
    end;
   '\':
    begin
      delete(num, 1, 1);
      i := i DIV strToInt(num);
    end;
   '%':
    begin
      delete(num, 1, 1);
      i := i MOD strToInt(num);
    end;
   '&':
    begin
      delete(num, 1, 1);
      i := i AND strToInt(num);
    end;
   '>':
    begin
      delete(num, 1, 1);
      i := i SHR strToInt(num);
    end;
   '<':
    begin
      delete(num, 1, 1);
      i := i SHL strToInt(num);
    end;
   else
    begin
      system.Inc(i, strToInt(num));
    end;
  end;
  dumbNode.data[0] := intToStr(i);
end;

procedure TStringHash.append(s, data: string);
var i: word; dumbNode: PStringHash;
begin
  i := hash(s);
  dumbNode := table[i];
  while (dumbNode <> nil) AND (dumbNode.name <> s) do
    dumbNode := dumbNode.next;
  if dumbNode = nil then
    begin add(s, data); exit; end;
  setLength(dumbNode.data, length(dumbNode.data)+1);
  dumbNode.data[length(dumbNode.data)-1] := data;
end;

procedure TStringHash.strictAppend(s, data: string);
var i: word; dumbNode: PStringHash;
begin
  i := hash(s);
  dumbNode := table[i];
  while (dumbNode <> nil) AND (dumbNode.name <> s) do
    dumbNode := dumbNode.next;
  if dumbNode = nil then
    exit;
  if length(dumbNode.data) <> 0 then
  for i := 0 to length(dumbNode.data)-1 do
    if AnsiLowerCase(trim(dumbNode.data[i])) = AnsiLowerCase(trim(data)) then
      exit;
  setLength(dumbNode.data, length(dumbNode.data)+1);
  dumbNode.data[length(dumbNode.data)-1] := data;
end;

procedure TStringHash.insert(s, data: string);
var i: word; dumbNode: PStringHash;
begin
  i := hash(s);
  dumbNode := table[i];
  while (dumbNode <> nil) AND (dumbNode.name <> s) do
    dumbNode := dumbNode.next;
  if dumbNode = nil then
    begin add(s, data); exit; end;
  setLength(dumbNode.data, length(dumbNode.data)+1);
  for i := length(dumbNode.data)-1 downto 1 do
    dumbNode.data[i] := dumbNode.data[i-1];
  dumbNode.data[0] := data;
end;

function TStringHash.first(s: string): string;
var d: strArr;
begin
  d := lookup(s);
  if d = nil then result := ''
  else result := d[0];
end;

function TStringHash.last(s: string): string;
var d: strArr;
begin
  d := lookup(s);
  result := d[length(d)-1];
end;

function TStringHash.len(s: string): string;
var d: strArr;
begin
  d := lookup(s);
  if d = nil then result := '0'
  else result := intToStr(length(d));
end;

function TStringHash.pos(s, data: string): string;
var i: word; dumbNode: PStringHash;
begin
  i := hash(s);
  dumbNode := table[i];
  while (dumbNode <> nil) AND (dumbNode.name <> s) do
    dumbNode := dumbNode.next;
  if dumbNode = nil then
    exit;
end;

function TStringHash.getSubStr(s: string; n: word): string;
var d: strArr;
begin
  d := lookup(s);
  if n >= length(d) then
    result := ''
  else
    result := d[n];
end;

function TStringHash.copy: TStringHash;
var i: word;
  dumbHashTo, dumbHashFrom: PStringHash;
begin
  result := TStringHash.Create;
  for i := 0 to HashSize do
  begin
    result.table[i] := nil;
    if self.table[i] = nil then continue;
    dumbHashFrom := self.table[i];
    new(result.table[i]);
    dumbHashTo := result.table[i];
    dumbHashTo.name := dumbHashFrom.name;
    dumbHashTo.next := nil;
    dumbHashTo.data := system.copy(dumbHashFrom.data, 0, length(dumbHashFrom.data));
    dumbHashFrom := dumbHashFrom.next;
    while dumbHashFrom <> nil do
    begin
      new(dumbHashTo.next);
      dumbHashTo.name := dumbHashFrom.name;
      dumbHashTo.data := system.copy(dumbHashFrom.data, 0, length(dumbHashFrom.data));
      dumbHashTo.next := nil;
      dumbHashFrom:=dumbHashFrom.next;
    end;
  end;
end;

function TStringHash.lookup(s: string): strArr;
var i: word;
 dumbNode: PStringHash;
begin
  result := nil;
  i := hash(s);
  dumbNode := table[i];
  while (dumbNode <> nil) AND (dumbNode.name <> s) do
    dumbNode := dumbNode.next;
  if dumbNode = nil then
    result := nil
  else
    result := dumbNode.data;
end;

end.
