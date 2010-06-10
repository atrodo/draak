(* **************************************************************** *)
(*     Copyright (C) 1999-2010, Jon Gentle, All right reserved.     *)
(* **************************************************************** *)
(* This program is free software; you can redistribute it under the *)
(* terms of the Artistic License, as specified in the LICENSE file. *)
(* **************************************************************** *)

unit Macro;

interface

uses hashs, error, gmrdrv, parser, classes; 

type

  TMacroDrv = class(TPersistent)
    constructor create; virtual; abstract;
    procedure execute(inNode: PParseNode); virtual; abstract;
   protected
    Ferr: TError;
    Fgmr: TGmr;
    FoutCode: TStringList;
    FoutData: TStringList;
    FsearchDirs: string;
    FgiantError: boolean;
   public
    property err: TError read Ferr write Ferr;
    property gmr: TGmr read Fgmr write Fgmr;
    property outCode: TStringList read FoutCode write FoutCode;
    property outData: TStringList read FoutData write FoutData;
    property searchDirs: string read FsearchDirs write FSearchDirs;
    property giantError: boolean read FgiantError write FgiantError;
  end;

  TMacroClass = class of TMacroDrv;

implementation

end.
 
