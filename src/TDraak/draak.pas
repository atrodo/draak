(* **************************************************************** *)
(*     Copyright (C) 1999-2010, Jon Gentle, All right reserved.     *)
(* **************************************************************** *)
(* This program is free software; you can redistribute it under the *)
(* terms of the Artistic License, as specified in the LICENSE file. *)
(* **************************************************************** *)

unit draak;

interface

uses
  SysUtils, Classes,
  StrUtils,
  Contnrs,
  filedrv,
  gmrdrv,
  Macro,
  parser,
  hashs,
  error;

type
  TDraakNotify = procedure(sender: TObject; s: string) of object;

  TDraakFlags = set of (TimeStat, HashTime);

  TDraak = class(TComponent)
  private
    error: TError;
    Grammar: TGmr;
    root: PParseNode;
    FonError: TDraakNotify;
    FonStatus: TDraakNotify;
    FonStream: TdraakNotify;
    FonNodeCreate: TDraakNotify;
    FonNodeChild: TDraakNotify;
    FonNodePop: TDraakNotify;
    FonCompile: TDraakNotify;
    FonAssemble: TDraakNotify;
    FonLink: TDraakNotify;
    Flag: TDraakFlags;
    FSearchPath: string;
    FMacroClass: TMacroClass;
    finalSuccess: boolean;
  public
    property rootNode: PParseNode read root;
    property success: boolean read finalSuccess;
  published
    property Flags: TDraakFlags read Flag write Flag;
    property SearchPath: string read FSearchPath write FSearchPath;
    property MacroClass: TMacroClass read FMacroClass write FMacroClass;
    property onError: TDraakNotify read FonError write FonError;
    property onStatus: TDraakNotify read FonStatus write FonStatus;
    property onStream: TDraakNotify read FonStream write FonStream;
    property onNodeCreate: TDraakNotify read FonNodeCreate write FonNodeCreate;
    property onNodeChild: TDraakNotify read FonNodeChild write FonNodeChild;
    property onNodePop: TDraakNotify read FonNodePop write FonNodePop;
    property onCompile: TDraakNotify read FonCompile write FonCompile;
    property onAssemble: TDraakNotify read FonAssemble write FonAssemble;
    property onLink: TDraakNotify read FonLink write FonLink;
    constructor create(AOwner: TComponent); override;
    procedure compile(outStream: TFileStream; inFile: string);
    procedure parse(inFile: string);
    procedure clearGrammer;
    procedure clear;
    procedure produceCopyright;
    { Published declarations }
  end;

  EDraakNoCompile = class(Exception)

  end;

procedure Register;

implementation

//uses cmddrv{$ifdef MSWindows}, windows {$endif} ;

function timeCount(var t: int64): double;
var i, f: int64;
begin
  {$ifdef MSWindows}
  if t = 0 then
  begin
    QueryPerformanceCounter(t);
    result := 0;
  end else
  begin
    QueryPerformanceCounter(i);
    QueryPerformanceFrequency(f);
    result := (i-t) / f;
  end; {$endif}
  {$ifdef Linux}
  result := 0;{$Endif}
end;

constructor TDraak.create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  //FMacroClass := TMacro;
  error := TError.create(self);
end;

procedure TDraak.parse(inFile: string);
var loadedFile: string;
    ext, gmrfile: string;
    name: string;
    noext: string;
    lPath: PChar;
    t: int64; tim: double;
    parse: TParser;
begin
  loadedFile := inFile;
  ext := AnsiStrRScan(PChar(loadedFile), '.')+1;
  lPath := AnsiStrRScan(PChar(loadedFile), PathDelim);
  if lPath <> nil then
    name := lPath+1
  else
    name := loadedFile;
  noext := Leftstr(name, AnsiPos('.', name)-1);
  gmrFile := FileSearch({ext+PathDelim+}ext+'.gmr', FSearchPath);

  t := 0; timeCount(t);
  if Grammar = nil then
    Grammar := TGmr.init(TFile.init(gmrFile));
  tim := timeCount(t);
  if HashTime in Flag then error.status(FloatToStrF(tim,ffFixed, 0, 2)+' seconds to hash.');
  t := 0; timeCount(t);
  parse := TParser.Create;
  parse.err := error;
  parse.parse(TFile.init(inFile), Grammar);
  if (parse.rootNode <> nil) AND (root = nil) then
    root := parse.rootNode;
  tim := timeCount(t);
  if TimeStat in Flag then error.status(FloatToStrF(tim, ffFixed, 0, 2)+' seconds.');
end;

procedure TDraak.compile(outStream: TFileStream; inFile: string);
var loadedFile: string;
    ext, gmrFile: string;
    name: string;
    noext: string;
    lPath: PChar;
    t: int64; tim: double;
    macro: TMacroDrv;
    parse: TParser;
begin
  loadedFile := inFile;
  ext := AnsiStrRScan(PChar(loadedFile), '.')+1;
  lPath := AnsiStrRScan(PChar(loadedFile), PathDelim);
  if lPath <> nil then
    name := lPath+1
  else
    name := loadedFile;
  noext := Leftstr(name, AnsiPos('.', name)-1);
  gmrFile := FileSearch({ext+PathDelim+}ext+'.gmr', FSearchPath);
  if gmrFile='' then
  begin
    error.err('Couldn''t find grammar file for extention: '+ext);
    exit;
  end;


  t := 0; timeCount(t);
  if Grammar = nil then
    Grammar := TGmr.init(TFile.init(gmrFile));
  tim := timeCount(t);
  if HashTime in Flag then error.status(FloatToStrF(tim, ffFixed, 0, 2)+' seconds to hash.');
  t := 0; timeCount(t);
  parse := TParser.Create;
  parse.err := error;
  parse.parse(TFile.init(inFile), Grammar);
  if parse.rootNode <> nil then
  begin
    finalSuccess := true;
    {
    if root = nil then
      root := parse.rootNode;
    macro := FMacroClass.create;
    macro.err := error;
    macro.gmr := Grammar;
    macro.searchDirs := FSearchPath;
    macro.execute(parse.rootNode);
    if macro.giantError = false then
    begin
      macro.outCode.SaveToStream(outStream);
      macro.outData.SaveToStream(outStream);
      error.status(noext+'.pas: Compiled! ('+intToStr(parse.lines)+' lines)' );
      finalSuccess := true;
    end else begin finalSuccess := false; error.err('Error compiling file.'); end;
    macro.free;
    }
  end; 
  parse.Free;
  tim := timeCount(t);
  if TimeStat in Flag then error.status(FloatToStrF(tim, ffFixed, 0, 2)+' seconds.');
end;

procedure TDraak.clearGrammer;
begin
  Grammar := nil; root := nil;
end;

{Clear: destroys all internal data.  Wipes it out.  Frees all the mem Draak uses}
{ without destroying the DraakComp.  Grammar and Root are destroyed and set to  }
{ nil.}
procedure TDraak.clear;
begin
  if assigned(Grammar) then Grammar.Free;
  if assigned(root)    then rootDestroy(root);
  Grammar := nil; root := nil;
end;

procedure TDraak.produceCopyright;
begin
  error.status('(* ************************************************************ *)');
  error.status('(* Copyright (c) 1999-2010 Jon Gentle, All right reserved.      *)');
  error.status('(* ************************************************************ *)');
end;

procedure Register;
begin
  RegisterComponents('TOASC', [TDraak]);
end;

begin
end.
