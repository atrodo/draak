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
      current: PGmrNode;
    public
      destructor destroy; override;
      procedure add(const lhs, rhs: string); overload;
      procedure add(const lhs, rhs: string; re: TRegExp); overload;
      //procedure addRHS(const inS: string);
      procedure addMacro(const macro: string);
      procedure clearCurrent;
      function hashLookup(const key: string): PGmrNode; overload;
      //function hashLookup(const S: string; hint: word; count: word = 0): PGmrNode; overload;
  end;

  PGmr = ^TGmr;
  TGmr = class
    private
      ghash: TGmrHash;
      goal: PGmrNode;
      settings: TStringHash;
    public
      constructor init(inF: TFile);
      destructor destroy; override;
      function getHash: TGmrHash;
      function getGoal: PGmrNode;
      function getHashNode(s: string): PGmrNode;
  end;

implementation

var
  gmr_re: TRegExp;
  terminalClean: TRegExp;

destructor TGmrHash.destroy;
begin
end;

procedure TGmrHash.add(const lhs, rhs: string);
var dumbNode: PGmrNode;
  hashCode: word;
  done: boolean;
  term: string;
  nonterm: string;
  dumbAtom: PGmrAtom;
begin
  new(dumbNode);
  dumbNode.name := lhs;
  hashCode := hash(lhs);
  dumbNode.next := table[hashCode];
  setLength(dumbNode.rhs, 0);
  setLength(dumbNode.macros, 0);
  table[hashCode] := dumbNode;
  current := dumbNode;

  done := false;
  gmr_re.bind(rhs);

  writeln('***'+rhs);
  writeln(0);
  while gmr_re.match = true do
  begin
    term := gmr_re.capture[1].captured;
    if term <> '' then
    begin
      new(dumbAtom);
      dumbAtom.typed := terminal;
      dumbAtom.data := term;
      // TODO: this is less than optimal if someone has a \Q as a part of their grammer.
      term := '\Q'+terminalClean.substitute(term, '\E\s*\Q')+'\E';
      //writeln('  '+term);
      dumbAtom.re   := TRegExp.create(term);
      setLength(dumbNode.rhs, length(dumbNode.rhs)+1);
      dumbNode.rhs[length(dumbNode.rhs)-1] := dumbAtom;
    end;

    new(dumbAtom);
    dumbAtom.typed := nonterminal;

    // Optional
    if gmr_re.capture[2].captured <> '' then
    begin
      dumbAtom.optional := true;
      dumbAtom.data := gmr_re.capture[2].captured;
      writeln('opt');
    end
    else
    // Zero or more
    if gmr_re.capture[3].captured <> '' then
    begin
      dumbAtom.star := true;
      dumbAtom.data := gmr_re.capture[3].captured;
      writeln('star');
    end
    else
    // One
    if gmr_re.capture[4].captured <> '' then
    begin
      dumbAtom.data := gmr_re.capture[4].captured;
      writeln('one');
    end;
    {
    if (term = '') and (dumbAtom.data = '') then
    begin
      dispose(dumbAtom);
      break;
    end;
    }
    setLength(dumbNode.rhs, length(dumbNode.rhs)+1);
    dumbNode.rhs[length(dumbNode.rhs)-1] := dumbAtom;
  end;

  //add(lhs, rhs, TRegExp.create('^'+rhs, [MultiLine, SingleLine, Extended]));
end;

procedure TGmrHash.add(const lhs, rhs: string; re: TRegExp);
begin
end;

procedure TGmrHash.addMacro(const macro: string);
begin
end;

procedure TGmrHash.clearCurrent;
begin
  current := nil;
end;

function TGmrHash.hashLookup(const key: string): PGmrNode;
begin
  result := table[hash(key)];
  while (result <> nil) AND (result.name <> key) do
    result := result.next;
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
  gmrMatchN, gmrMatchM: TRegExp;
  success: boolean;
begin
  ghash := TGmrHash.Create;
  goal := nil;
  cleanup := TRegExp.create('\s+', [MultiLine, SingleLine, Extended]);
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
        ghash.add(gmrMatchM.capture[1].captured, gmrMatchM.capture[2].captured, TRegExp.create(gmrMatchM.capture[2].captured, [MultiLine, SingleLine, Extended]));
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

function TGmr.getHashNode(s: string): PGmrNode;
begin
  result := ghash.hashLookup(s);
end;

destructor TGmr.destroy;
begin
  ghash.Free;
  inherited destroy;
end;

{* So, what does gmrdrv do?  Well, it will handle opening a grammer file,     *}
{* parsing it into memory, and giving the apporiate rule to those that ask.   *}

begin
  gmr_re := TRegExp.create('(.*?)(?:{(<\w+>)} | (<\w+>)\* | (<\w+>) | $)', [Extended]);
  terminalClean := TRegExp.create('\s+', [Global]);
end.
