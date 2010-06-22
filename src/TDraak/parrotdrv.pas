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

constructor TDrvParrot.create;
begin
  //FoutCode := TStringList.Create;
  //FoutData := TStringList.Create;

  setlength(cache, 0);
  
  Parrot_srand(0);
  interp := Parrot_new(nil);
  out_pbc := create_string('');

end;

procedure TDrvParrot.execute(inNode: PParseNode);
var 
  hllcode: Parrot_PMC;
  pmc_result, pmc_tree: Parrot_PMC;
  s: string;
  oldExcpetionMask: TFPUExceptionMask;
begin

  oldExcpetionMask := SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);

  pmc_tree := genTree(inNode);
  hllcode := Parrot_PMC_get_pmc_keyed_str(interp, pmc_tree, create_string('exec'));
  
  Parrot_ext_call(interp, hllcode, 'P->P', pmc_tree, @pmc_result);
  PCT(pmc_result);
  SetExceptionMask(oldExcpetionMask);

end;

procedure TDrvParrot.write(outStream: TFileStream);
var
  pbc: PChar;
  len: cardinal;
begin
  pbc := Parrot_str_to_cstring(interp, out_pbc);
  len := Parrot_str_byte_length(interp, out_pbc);
  writeln(len);
  outStream.write(pbc^, len)
end;

function TDrvparrot.create_string(s: string): Parrot_String;
begin
  result := Parrot_new_string(interp, PChar(s), length(s), nil, 0);
end;

function TDrvparrot.new_pmc(s: string): Parrot_PMC;
var
  typenum: cardinal;
begin
  typenum := Parrot_PMC_typenum(interp, PChar(s));
  result := Parrot_PMC_new(interp, typenum);
  Parrot_register_pmc(interp, result);
end;

function TDrvParrot.genParrot(hllcode: string): Parrot_PMC;
var
  compiler, errstr: Parrot_String;
  code: Parrot_PMC;
  sa: strArr;
  hll: string;
begin

  // This should utilize a cache.

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

end;

function TDrvParrot.genTree(inNode: PParseNode): Parrot_PMC;
var
  data, children, nonTerms, named: Parrot_PMC;
  r: Parrot_PMC;
  child: Parrot_PMC;
  i: cardinal;
begin
  r := new_pmc('Hash');

  // name
  named := new_pmc('String');
  Parrot_PMC_set_string_native(interp, named, create_string(inNode.point.name));
  Parrot_PMC_set_pmc_keyed_str(interp, r, create_string('name'), named);

  // exec
  Parrot_PMC_set_pmc_keyed_str(interp, r, create_string('exec'), genParrot(join(inNode.point.macros)) );

  // data
  data := new_pmc('ResizablePMCArray');
  if length(inNode.data) > 0 then
    for i := 0 to length(inNode.data)-1 do
    begin
      Parrot_PMC_push_string(interp, data, create_string(inNode.data[i]));
    end;
  Parrot_PMC_set_pmc_keyed_str(interp, r, create_string('data'), data );

  // children
  children := new_pmc('ResizablePMCArray');

  if length(inNode.children) > 0 then
    for i := 0 to length(inNode.children)-1 do
    begin
      if inNode.children[i] = nil then
        continue;

      child := genTree(inNode.children[i]);
      nonTerms := Parrot_PMC_get_pmc_keyed_int(interp, children, inNode.children[i].nonTermNum);
      if nonTerms = Parrot_PMC_null then
      begin
        Parrot_PMC_set_pmc_keyed_int(interp, children, inNode.children[i].nonTermNum, new_pmc('ResizablePMCArray'));
        nonTerms := Parrot_PMC_get_pmc_keyed_int(interp, children, inNode.children[i].nonTermNum);
      end;
      Parrot_PMC_push_pmc(interp, nonTerms, child);
    end;

  Parrot_PMC_set_pmc_keyed_str(interp, r, create_string('xchildren'), children );

  result := r;
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
  setLength(sa, 16);
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
  sa[12] := '  $S0 = $P3';
  sa[13] := '  say $S0';
  sa[14] := '  .return ($S0)';
  sa[15] := '.end';

  code := Parrot_compile_string( interp, compiler, PChar(join(sa)), errstr);
  if assigned(errstr) then
    raise Exception.create(Parrot_str_to_cstring(interp, errstr));

  Parrot_ext_call(interp, code, 'P->S', inPast, @pbc);
  out_pbc := pbc;
  //writeln(Parrot_str_to_cstring(interp, pbc));

end;

begin
  RegisterClass(TDrvParrot);
end.
 
