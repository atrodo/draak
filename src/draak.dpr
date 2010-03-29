(* **************************************************************** *)
(*     Copyright (C) 1999-2010, Jon Gentle, All right reserved.     *)
(* **************************************************************** *)
(* This program is free software; you can redistribute it under the *)
(* terms of the Artistic License, as specified in the LICENSE file. *)
(* **************************************************************** *)

program cmddraak;

{$ifdef WIN32}
{$APPTYPE CONSOLE}
{$endif}

{ DEFINE TREETRACE}

uses
  SysUtils,
  Classes,
  StrUtils,
//  memTracker in '..\dbg\memTracker.pas',
  draak {in 'TDraak\Draak.pas' - Nope, doesn't work in fpc.  Not really needed.}
  {$ifdef MSWindows}, Windows{$endif};

var draak1: TDraak;
  outFile: TFileStream;
  delay: array of string;
type
  errors = class
    procedure Draak1Error(sender: TObject; s: String);
    procedure Draak1Assemble(sender: TObject; s: String);
    procedure Draak1Compile(sender: TObject; s: String);
    procedure Draak1NodeCreate(sender: TObject; s: String);
    procedure Draak1NodeChild(sender: TObject; s: String);
    procedure Draak1NodePop(sender: TObject; s: String);
    private t: cardinal;
  end;

procedure errors.Draak1Error(sender: TObject; s: String);
begin
  writeln(s);
end;

procedure errors.Draak1Assemble(sender: TObject; s: String);
begin
  setLength(delay, length(delay)+1);
  delay[length(delay)-1] := s;
end;

procedure errors.Draak1Compile(sender: TObject; s: String);
var outStream: TFileStream;
  noext: string;
  filen:  string;
begin
  filen := Rightstr(s, Length(s)-LastDelimiter(PathDelim, s));
  noext := Leftstr(filen, AnsiPos('.', filen)-1);
  outStream := TFileStream.Create(noext+'.asm', fmCreate);
  try
    Draak1.compile(outStream, trim(s));
  finally
    outStream.Destroy;
  end;
end;

procedure errors.Draak1NodeCreate(sender: TObject; s: String);
begin
  t := t+1;
  writeln(dupestring('--+', t)+'> '+s);
  //nodes.push(Form1.TreeView1.Items.AddChild(TTreeNode(nodes.peek), s));
end;

procedure errors.Draak1NodeChild(sender: TObject; s: String);
begin
  //t := t+1;
  writeln(dupestring('--+', t)+'  '+s);
  //TreeView1.Items.AddChild(TTreeNode(nodes.peek), s);
end;

procedure errors.Draak1NodePop(sender: TObject; s: String);
begin
  t := t-1;
  writeln(dupestring('--+', t)+'< '+s);
  //TTreeNode(nodes.Peek).Text := TTreeNode(nodes.Peek).Text+s; nodes.Pop;
end;


procedure go;
var loadedFile: string;
    ext: string;
    name: string;
    noext: string;
    cdir: string;
    lPath: PChar;
    e: errors;
    i: word;
begin
  writeln('Draak Compiler');

  cdir := ParamStr(0);
  writeln(ParamStr(1));
  for i:=length(cdir) downto 1 do
    if IsPathDelimiter(cdir, i) then
      break;
  if i=0 then cdir:='.'
    else SetLength(cdir, i-1);
  if paramcount > 0 then
    loadedFile := paramstr(1);
  if loadedFile = '' then
  begin
    draak1 := TDraak.create(nil);
    e := Errors.Create;
    draak1.onStatus := e.Draak1Error;
    draak1.produceCopyright;
    writeln('Usage: '+ParamStr(0)+' file.ext');
    exit;
  end;
  ext := AnsiStrRScan(PChar(loadedFile), '.')+1;
  lPath := AnsiStrRScan(PChar(loadedFile), PathDelim);
  if lPath <> nil then
    name := lPath+1
  else
    name := loadedFile;
  {$ifdef MemCheck}
  writeln('AllocMem: '+intToStr(AllocMemSize));
  for i := 0 to 4 do
  begin
  {$endif}
  noext := Leftstr(name, AnsiPos('.', name)-1);
  draak1 := TDraak.create(nil);
  draak1.Flags := [timeStat];
  e := Errors.Create;
  outFile := TFileStream.Create(noext+'.asm', fmCreate);
  try
    {$ifdef WIN32}
    draak1.SearchPath := '.;'+cdir+';'+cdir+PathDelim+ext;
    {$else}
    //draak1.SearchPath := '.:'+cdir+':'+cdir+PathDelim+ext+':'+cdir+PathDelim+'gmr'+PathDelim+ext;
    draak1.SearchPath := cdir+PathDelim+'gmr'+PathDelim;
    {$endif}
    draak1.onError := e.Draak1Error;
    draak1.onStatus := e.Draak1Error;
//    draak1.onStream := e.Draak1Error;
    draak1.onAssemble := e.Draak1Assemble;
    draak1.onLink := e.Draak1Assemble;
    draak1.onCompile := e.Draak1Compile;
    {$ifdef TREETRACE}
    draak1.onNodeCreate := e.Draak1NodeCreate;
    draak1.onNodeChild := e.Draak1NodeChild;
    draak1.onNodePop := e.Draak1NodePop;
    {$endif}
//    draak1.parse(Paramstr(1));
    draak1.compile(outFile, Paramstr(1));
  except on Ex: Exception do
  //except
    begin
    outFile.Destroy;
    e.Free; draak1.clear;
    draak1.Free;
    writeln(Ex.message);
    end;
  end;
  {$ifdef MemCheck}
  writeln('AllocMem: '+intToStr(AllocMemSize));
  end;
  {$endif}
  
  writeln(draak1.success);
  if draak1.success = true then
    ExitCode := 0
  else
    ExitCode := -1;
  {$define NOCOMPILE}
  {$ifndef NOCOMPILE}
    if draak1.success = true then
    begin
      writeln('Compiled!');
      if length(delay) <> 0 then
        for i := 0 to length(delay)-1 do
          {$ifdef MSWindows}
          WinExec(PChar(delay[i]), Windows.SW_NORMAL)
          {$endif}
        ;
    end;
  {$endif}
end;

begin
  go;
//  readln;
end .
