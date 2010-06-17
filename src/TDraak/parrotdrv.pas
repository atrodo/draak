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
    procedure write(outStream: TFileStream); override;
   private
    interp: Parrot_Interp;
    cache: array of Parrot_PMC;
    out_pbc: Parrot_String;
    function create_string(s: string): Parrot_String;
    function new_pmc(s: string): Parrot_PMC;
    function genParrot(hllcode: string): Parrot_PMC;
    function genTree(inNode: PParseNode): Parrot_PMC;
    procedure PCT(inPast: Parrot_PMC);
  end;

implementation

uses Math, Sysutils;

function TDrvparrot.create_string(s: string): Parrot_String;
begin
  //writeln('a');
  result := Parrot_new_string(interp, PChar(s), length(s), nil, 0);
  //writeln('b');
end;

function TDrvparrot.new_pmc(s: string): Parrot_PMC;
var
  typenum: cardinal;
begin
  typenum := Parrot_PMC_typenum(interp, PChar(s));
  result := Parrot_PMC_new(interp, typenum);
  Parrot_register_pmc(interp, result);
end;

constructor TDrvParrot.create;
begin
  //FoutCode := TStringList.Create;
  //FoutData := TStringList.Create;

  setlength(cache, 0);
  
  //writeln('e');
  //Parrot_set_config_hash();
  Parrot_srand(0);
  interp := Parrot_new(nil);
  out_pbc := create_string('');

  //writeln('f');

end;

function TDrvParrot.genParrot(hllcode: string): Parrot_PMC;
var
  compiler, errstr: Parrot_String;
  code: Parrot_PMC;
  sa: strArr;
  hll: string;
begin

  // This should utilize a cache.

  //writeln('g');

  hll := Fgmr.settings.last('ParrotHLL');
  compiler := create_string('PIR');

  setLength(sa, 14);
  sa[ 0] := '.sub "" :anon';
  sa[ 1] := '  .param string hll';
  sa[ 2] := '  .param string code';
  sa[ 3] := '  $P0 = compreg hll';
  sa[ 4] := '  unless_null $P0, compile';
  sa[ 5] := '  load_language "nqprx"';
  sa[ 6] := '  $P0 = compreg "NQP-rx"';
  sa[ 7] := ' compile:';
  sa[ 8] := '  $P1 = $P0."compile"(code)';
  sa[ 9] := '  $P1 = $P1()';
  sa[10] := '  typeof $S2, $P1';
  sa[11] := '  say $S2 #say $P1 #trace 1';
  sa[12] := '  .return ($P1)';
  sa[13] := '.end';
  code := Parrot_compile_string( interp, compiler, PChar(join(sa)), errstr);
  if assigned(errstr) then
    raise Exception.create(Parrot_str_to_cstring(interp, errstr));

  Parrot_ext_call(interp, code, 'SS->P', create_string(hll), create_string(hllcode), @result);

  //writeln('h');

end;

function TDrvParrot.genTree(inNode: PParseNode): Parrot_PMC;
var
  data, children: Parrot_PMC;
  r: Parrot_PMC;
  i: cardinal;
begin
  r := new_pmc('Hash');

  //writeln('-');
  // exec
  //writeln(assigned(r));
  writeln('Before Parrot_PMC_set_pmc_keyed_str');
  Parrot_PMC_set_pmc_keyed_str(interp, r, create_string('exec'), genParrot(join(inNode.point.macros)) );
  writeln('After Parrot_PMC_set_pmc_keyed_str');

  // data
  data := new_pmc('ResizablePMCArray');
  writeln('5');
  if length(inNode.data) > 0 then
    for i := 0 to length(inNode.data)-1 do
    begin
      writeln(i);
      Parrot_PMC_push_string(interp, data, create_string(inNode.data[i]));
    end;
  writeln('6');
  Parrot_PMC_set_pmc_keyed_str(interp, r, create_string('data'), data );
  writeln('6');

  // children

  result := r;
end;

procedure TDrvParrot.execute(inNode: PParseNode);
var 
  hllcode: Parrot_PMC;
  pmc_result, pmc_tree: Parrot_PMC;
  s: string;
  oldExcpetionMask: TFPUExceptionMask;
begin

  //writeln('1');
  oldExcpetionMask := SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);

  //writeln('5');
  //writeln(assigned(hllcode));
  pmc_tree := genTree(inNode);
  hllcode := Parrot_PMC_get_pmc_keyed_str(interp, pmc_tree, create_string('exec'));
  
  writeln('7');
  Parrot_ext_call(interp, hllcode, 'P->P', pmc_tree, @pmc_result);
  writeln('8');
  PCT(pmc_result);
  writeln('7');
  SetExceptionMask(oldExcpetionMask);

end;

procedure TDrvParrot.write(outStream: TFileStream);
var
  pbc: String;
begin
  pbc := Parrot_str_to_cstring(interp, out_pbc);
  //outStream.write(pbc, length(pbc))
end;

procedure TDrvParrot.PCT(inPast: Parrot_PMC);
var
  s: string;
  compiler, errstr: Parrot_String;
  pbc: Parrot_String;
  code: Parrot_PMC;
  sa: strArr;
  hll: string;
begin
  // Let's do this in PCT for now

  compiler := create_string('PIR');
  setLength(sa, 15);
  sa[ 0] := '.sub "" :anon';
  sa[ 1] := '  .param pmc inPast';
  sa[ 2] := '  $P0 = compreg "PAST"';
  sa[ 3] := '  unless_null $P0, compile';
  sa[ 4] := '  load_bytecode "HLL.pbc"';
  sa[ 5] := '  $P0 = compreg "PAST"';
  sa[ 6] := ' compile:';
  sa[ 7] := '  $P1 = $P0."to_post"(inPast)';
  sa[ 8] := '  $P0 = compreg "POST"';
  sa[ 9] := '  $P2 = $P0."to_pir"($P1)';
  sa[10] := '  $P0 = compreg "PIR"';
  sa[11] := '  $P3 = $P0($P2)';
  //sa[11] := '  $S0 = typeof $P0';
  sa[12] := '  say $S0';
  sa[13] := '  .return ($P3)';
  sa[14] := '.end';

  writeln('1');
  code := Parrot_compile_string( interp, compiler, PChar(join(sa)), errstr);
  writeln('1');
  if assigned(errstr) then
    raise Exception.create(Parrot_str_to_cstring(interp, errstr));
  writeln('1');

  Parrot_ext_call(interp, code, 'P->S', inPast, @pbc);
  out_pbc := pbc;
  writeln(Parrot_str_to_cstring(interp, pbc));
  writeln('1');

end;

begin
  RegisterClass(TDrvParrot);
end.
 
