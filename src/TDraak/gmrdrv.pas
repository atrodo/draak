(* **************************************************************** *)
(*     Copyright (C) 1999-2010, Jon Gentle, All right reserved.     *)
(* **************************************************************** *)
(* This program is free software; you can redistribute it under the *)
(* terms of the Artistic License, as specified in the LICENSE file. *)
(* **************************************************************** *)

unit gmrdrv;

interface

uses filedrv, sysutils, StrUtils, hashs, RegExp;

type
  AtomType = (Terminal, NonTerminal, Matching);

  strArr = array of string;

  PGmrAtom = ^RGmrAtom;
  RGmrAtom = record
    optional, star: boolean;
    typed: AtomType;
    data: String;
    re: TRegExp;
  end;

  PGmrNode = ^RGmrNode;
  AGmrNode = array of PGmrNode;
  RGmrNode = record
    name: string;
    next: PGmrNode;
    rhs : array of PGmrAtom;
    macros: array of string;
  end;


  PGmrHash = ^TGmrHash;
  TGmrHash = class
    private
      table: array[0..HashSize] of PGmrNode;
      Fcurrent: PGmrNode;
      settings: TStringHash;
    public
      constructor create(in_settings: TStringHash);
      destructor destroy; override;
      procedure add(const lhs, rhs: string); overload;
      procedure add(const lhs, rhs: string; re: TRegExp); overload;
      //procedure addRHS(const inS: string);
      procedure addMacro(const macro: string);
      procedure clearCurrent;
      function hashLookup(const key: string): PGmrNode; overload;
      function get(const key: string): AGmrNode; overload;
    public
      property current: PGmrNode read Fcurrent;
      //function hashLookup(const S: string; hint: word; count: word = 0): PGmrNode; overload;
  end;

  PGmr = ^TGmr;
  TGmr = class
    private
      ghash: TGmrHash;
      goal: PGmrNode;
      Fsettings: TStringHash;
    public
      constructor init(inF: TFile);
      destructor destroy; override;
      function getHash: TGmrHash;
      function getGoal: PGmrNode;
      function getHashNode(s: string): AGmrNode;
    public
      property settings: TStringHash read Fsettings;
  end;

implementation

var
  gmr_re: TRegExp;
  terminalSpaces: TRegExp;

constructor TGmrHash.create(in_settings: TStringHash);
begin
  settings := in_settings;
end;

destructor TGmrHash.destroy;
begin
end;

procedure TGmrHash.add(const lhs, rhs: string);
var dumbNode: PGmrNode;
  hashCode: word;
  done: boolean;
  term: string;
  nonterm: string;
  whitespace: string;
  dumbAtom: PGmrAtom;
  hasNonTerm: boolean;
  i: cardinal;
begin
  new(dumbNode);
  dumbNode.name := lhs;
  hashCode := hash(lhs);
  dumbNode.next := table[hashCode];
  setLength(dumbNode.rhs, 0);
  setLength(dumbNode.macros, 0);
  table[hashCode] := dumbNode;
  Fcurrent := dumbNode;

  done := false;
  gmr_re.bind(rhs);

  whiteSpace := settings.last('Whitespace');
  if whiteSpace = '' then
    whiteSpace := '\s*';

  //writeln('***'+rhs);
  //writeln(0);
  while gmr_re.match = true do
  begin
    term := gmr_re.capture[1].captured;

    hasNonTerm := false;

    for i := 3 to 5 do
      if gmr_re.capture[i].captured <> '' then
        hasNonTerm := true;

    if hasNonTerm = false then
      term := term + gmr_re.capture[2].captured;

    if term <> '' then
    begin
      new(dumbAtom);
      dumbAtom.typed := terminal;
      dumbAtom.data := term;
      // TODO: this is less than optimal if someone has a \Q as a part of their grammer.
      dumbAtom.data := term;
      term := '\G\Q'+terminalSpaces.substitute(term, '\E'+whiteSpace+'\Q')+'\E';
      //writeln('  '+term);
      dumbAtom.re   := TRegExp.create(term, []);
      setLength(dumbNode.rhs, length(dumbNode.rhs)+1);
      dumbNode.rhs[length(dumbNode.rhs)-1] := dumbAtom;
    end;

    if hasNonTerm = true then
    begin
      new(dumbAtom);
      dumbAtom.typed := nonterminal;
      dumbAtom.re := nil;

      // If we have optional space, let's record it as such
      if gmr_re.capture[2].captured <> '' then
      begin
        dumbAtom.re := TRegExp.create(whiteSpace, []);
      end;

      // Optional
      if gmr_re.capture[3].captured <> '' then
      begin
        dumbAtom.optional := true;
        dumbAtom.data := gmr_re.capture[3].captured;
        //writeln('opt');
      end
      else
      // Zero or more
      if gmr_re.capture[4].captured <> '' then
      begin
        dumbAtom.star := true;
        dumbAtom.data := gmr_re.capture[4].captured;
        //writeln('star');
      end
      else
      // One
      if gmr_re.capture[5].captured <> '' then
      begin
        dumbAtom.data := gmr_re.capture[5].captured;
        //writeln('one');
      end;
      setLength(dumbNode.rhs, length(dumbNode.rhs)+1);
      dumbNode.rhs[length(dumbNode.rhs)-1] := dumbAtom;
    end;
    {
    if (term = '') and (dumbAtom.data = '') then
    begin
      dispose(dumbAtom);
      break;
    end;
    }
    {
    if dumbAtom.data <> '' then
    begin
      setLength(dumbNode.rhs, length(dumbNode.rhs)+1);
      dumbNode.rhs[length(dumbNode.rhs)-1] := dumbAtom;
    end else
    begin
      dispose(dumbAtom);
    end;
    }
  end;

  //add(lhs, rhs, TRegExp.create('^'+rhs, [MultiLine, SingleLine, Extended]));
end;

procedure TGmrHash.add(const lhs, rhs: string; re: TRegExp);
var
  dumbNode: PGmrNode;
  dumbAtom: PGmrAtom;
  hashCode: word;
begin
  new(dumbNode);
  dumbNode.name := lhs;
  hashCode := hash(lhs);
  dumbNode.next := table[hashCode];
  setLength(dumbNode.rhs, 1);
  setLength(dumbNode.macros, 0);
  table[hashCode] := dumbNode;

  Fcurrent := dumbNode;

  new(dumbAtom);
  dumbAtom.typed := Matching;
  dumbAtom.data  := rhs;
  dumbAtom.re    := re;
  dumbNode.rhs[0] := dumbAtom;
end;

procedure TGmrHash.addMacro(const macro: string);
begin
end;

procedure TGmrHash.clearCurrent;
begin
  Fcurrent := nil;
end;

function TGmrHash.hashLookup(const key: string): PGmrNode;
begin
  result := get(key)[0];
end;

function TGmrHash.get(const key: string): AGmrNode;
var
  dumbNode: PGmrNode;
  len: cardinal;
begin
  len := 0;
  setLength(result, len);
  dumbNode := table[hash(key)];
  while (dumbNode <> nil) do
  begin
    if dumbNode.name = key then
    begin
      len := len + 1;
      setLength(result, len);
      result[len-1] := dumbNode;
    end;
    dumbNode := dumbNode.next;
  end;
    {
    if dumbNode = nil then
      result := nil
    else
      result := dumbNode.value;
      }
end;


constructor TGmr.init(inF: TFile);
var s: string;
  posStr: word;
  cleanup: TRegExp;
  gmrMatchN, gmrMatchM, settingMatch: TRegExp;
  success: boolean;
begin
  Fsettings := TStringHash.Create;
  ghash := TGmrHash.Create(Fsettings);
  goal := nil;
  cleanup := TRegExp.create('\s+', [MultiLine, SingleLine, Extended]);
  settingMatch := TRegExp.create('^\s*(\w+)\s*=>\s*(.*)$', [Extended]);
  gmrMatchN := TRegExp.create('^\s*(<\w+>)\s*->\s*(.*)$', [Extended]);
  gmrMatchM := TRegExp.create('^\s*(<\w+>)\s*~>\s*m/(.*)/\s*$', [Extended]);
  try
    while inF.eof <> true do
    begin
      s := inF.getLine;
      s := cleanup.substitute(s, ' ');
      if s = '' then continue;
      if s[1] = '#' then continue;
      {Macros}
      if s[1] <> '<' then
      begin
        if (ghash.current = nil) and settingMatch.match(s) = true then
        begin
          Fsettings.append(settingMatch.capture[1].captured, settingMatch.capture[2].captured);
          //writeln(settingMatch.capture[1].captured);
        end
        else
          ghash.addMacro(s);
        continue;
      end;

      {
      success := gmrMatch.match(s);
      if success = false then
        raise Exception.create('Could not figure out grammer line: '+s);
      }

      if gmrMatchN.match(s) = true then
        ghash.add(gmrMatchN.capture[1].captured, gmrMatchN.capture[2].captured)
      else
      if gmrMatchM.match(s) = true then
      begin
        ghash.add(gmrMatchM.capture[1].captured, gmrMatchM.capture[2].captured, TRegExp.create('\G'+gmrMatchM.capture[2].captured, [SingleLine, MultiLine, Extended]));
      end;
      {
      writeln('---'+gmrMatchN.matched);
      writeln(gmrMatchN.capture[0].captured);
      writeln(gmrMatchN.capture[1].captured);
      writeln(gmrMatchN.capture[2].captured);
      writeln(gmrMatchN.capture[3].captured);
      writeln(gmrMatchN.capture[4].captured);
      writeln('---'+gmrMatchN.matched);
      }
    end;
    goal := ghash.get(Fsettings.first('Root'))[0];
    if goal = nil then
      raise Exception.create('No root found');
  finally
    inF.Destroy;
  end;
end;

function TGmr.getHash: TGmrHash;
begin
  result := ghash;
end;

function TGmr.getGoal: PGmrNode;
begin
  result := goal;
end;

function TGmr.getHashNode(s: string): AGmrNode;
begin
  result := ghash.get(s);
end;

destructor TGmr.destroy;
begin
  ghash.Free;
  inherited destroy;
end;

{* So, what does gmrdrv do?  Well, it will handle opening a grammer file,     *}
{* parsing it into memory, and giving the apporiate rule to those that ask.   *}

begin
  gmr_re := TRegExp.create('(.*?)(\s*)(?:{(<\w+>)} | (<\w+>)\* | (<\w+>) | $)', [Extended]);
  terminalSpaces := TRegExp.create('\s+', [Global]);
end.
