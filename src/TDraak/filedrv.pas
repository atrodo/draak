(* **************************************************************** *)
(*     Copyright (C) 1999-2010, Jon Gentle, All right reserved.     *)
(* **************************************************************** *)
(* This program is free software; you can redistribute it under the *)
(* terms of the Artistic License, as specified in the LICENSE file. *)
(* **************************************************************** *)

unit filedrv;

interface

uses Sysutils, classes, regexp;

type
  PFile = ^TFile;
  TFile = class
    private
      inF: TFileStream;
      Feof: boolean;
      FlineCount: cardinal;
      Feol: TRegExp;
    public
      property lineCount: cardinal read FlineCount;
      property eof: boolean read Feof;
    public
      constructor init(f: string);
      function getLine: string;
      destructor Destroy; override;
  end;

implementation

constructor TFile.init(f: string);
begin
  inF := TFileStream.Create(f, fmOpenRead);
  Feol := TRegExp.create('\R+', [MultiLine, SingleLine, Extended]);
end;

{ We need to be more effective and use a buffer to get the data}
function TFile.getLine: string;
var c: char;
  status: cardinal;
begin
  if eof then exit;
  c := #0; result := '';
  while Feol.match(result) = false do
  begin
    status := inF.Read(c, 1);
    if status = 0 then
    begin
      Feof := true;
      exit;
    end;
    result := result + c;
  end;
  result := Feol.substitute(result, '');
  inc(FlineCount);
end;

destructor TFile.Destroy;
begin
end;

end.
