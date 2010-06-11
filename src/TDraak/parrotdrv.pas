(* **************************************************************** *)
(*     Copyright (C) 1999-2010, Jon Gentle, All right reserved.     *)
(* **************************************************************** *)
(* This program is free software; you can redistribute it under the *)
(* terms of the Artistic License, as specified in the LICENSE file. *)
(* **************************************************************** *)

unit parrotdrv;

interface

uses hashs, error, gmrdrv, parser, classes, Macro, parrot;

type

  TDrvParrotClass = class of TDrvParrot;

  TDrvParrot= class(TMacroDrv)
    constructor create; override;
    procedure execute(inNode: PParseNode); override;
   private
    interp: Parrot_Interp;
    function create_string(s: string): Parrot_String;
  end;

implementation

uses Math;

function TDrvparrot.create_string(s: string): Parrot_String;
begin
  writeln('a');
  result := Parrot_new_string(interp, PChar(s), length(s), nil, 0);
  writeln('b');
end;

constructor TDrvParrot.create;
begin
  FoutCode := TStringList.Create;
  FoutData := TStringList.Create;
  
  writeln('a');
  Parrot_set_config_hash();
  interp := Parrot_new(nil);
  writeln('b');

end;

procedure TDrvParrot.execute(inNode: PParseNode);
var 
  compiler, errstr: Parrot_String;
  code, hllcode: Parrot_PMC;
  hll: string;
  s: string;
  sa: strArr;
  oldExcpetionMask: TFPUExceptionMask;
begin

  writeln('1');
  hll := Fgmr.settings.last('ParrotHLL');
  compiler := create_string('PIR');
  {
  writeln('2');
  writeln(inNode.point.name);
  writeln(length(inNode.point.macros));
  writeln(join(inNode.point.macros));
  code := Parrot_compile_string( interp, compiler, PChar(join(inNode.point.macros)), errstr);
  writeln('3');
  writeln(assigned(errstr));
  writeln(assigned(code));
  //writeln(Parrot_str_to_cstring(interp, errstr));
  Parrot_ext_call(interp, code, '->');
  writeln('4');
  }

  oldExcpetionMask := SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  setLength(sa, 14);
  sa[ 0] := '.sub "" :anon';
  sa[ 1] := '  .param string hll';
  sa[ 2] := '  .param string code';
  sa[ 3] := '  ';
  sa[ 4] := '  $P0 = compreg hll';
  sa[ 5] := '  unless_null $P0, compile';
  sa[ 6] := '  load_language "nqprx"';
  sa[ 7] := '  $P0 = compreg "NQP-rx"';
  sa[ 8] := ' compile:';
  sa[ 9] := '  $P1 = $P0."compile"(code)';
  sa[10] := '  typeof $S2, $P1';
  sa[11] := '  say $S2 #say $P1 #trace 1';
  sa[12] := '  .return ($P1)';
  sa[13] := '.end';
  //sa := [ '.sub m :anon', ' $P0 = compreg "'+hll+'"' ];
  //s := '.sub m :anon'+#10+' $P0 = compreg "'+hll+'"'+#10+'.return ($P0)'+#10+'.end';
  code := Parrot_compile_string( interp, compiler, PChar(join(sa)), errstr);
  writeln(assigned(errstr));
  if assigned(errstr) then
    writeln(Parrot_str_to_cstring(interp, errstr));
  writeln(Get8087CW);
  writeln(assigned(code));
  Parrot_ext_call(interp, code, 'SS->P', create_string(hll), create_string(join(inNode.point.macros)), @hllcode);

  writeln('5');
  writeln(assigned(hllcode));
  Parrot_ext_call(interp, hllcode, 'S->', create_string('Hello World!'));
  writeln('6');

  // $P0 = compreg 'Tcl'; $P1 = $P0.'compile'("puts hi"); $P1()

  SetExceptionMask(oldExcpetionMask);

end;

begin
  RegisterClass(TDrvParrot);
end.
 
