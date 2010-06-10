
Unit embed;

Interface


{
  Automatically converted by H2Pas 1.0.0 from embed.hh
  The following command line parameters were used:
    -Dlibparrot.so
    embed.hh
}

Const 
  External_library = 'libparrot.so'; {Setup as you need}

Type 
  PParrot_Opcode  = Pointer;
  PParrot_String  = Pointer;

  Parrot_PMC = Pointer;
  Parrot_String = pointer;
  Parrot_Interp = pointer;
  (*
  parrot_string_t = Record
         {undefined structure}
  End;


  Parrot_String = parrot_string_t;
  parrot_interp_t = Record
         {undefined structure}
  End;


  Parrot_Interp = parrot_interp_t;
  *)

  Parrot_Int = longint;

  Parrot_UInt = cardinal;

  Parrot_Float = double;

  Parrot_Opcode = longint;

  Parrot_Pointer = pointer;

  Parrot_Int1 = char;

  Parrot_UInt1 = byte;

  Parrot_Int2 = smallint;

  Parrot_UInt2 = word;

  Parrot_Int4 = longint;

  Parrot_UInt4 = cardinal;

  Parrot_Float4 = single;

  Parrot_Float8 = double;
  PackFile = Record
         {undefined structure}
  End;


  Parrot_PackFile = PackFile;

  Parrot_Interp_flag = (PARROT_NO_FLAGS = $00,PARROT_BOUNDS_FLAG = $04,
                        PARROT_PROFILE_FLAG = $08,PARROT_GC_DEBUG_FLAG = $10,
                        PARROT_EXTERN_CODE_FLAG = $100,PARROT_DESTROY_FLAG = $200,
                        PARROT_IS_THREAD = $1000,PARROT_THR_COPY_INTERP = $2000,
                        PARROT_THR_THREAD_POOL = $4000,PARROT_THR_TYPE_1 = PARROT_IS_THREAD,
                        PARROT_THR_TYPE_2 = PARROT_IS_THREAD Or PARROT_THR_COPY_INTERP,
                        PARROT_THR_TYPE_3 = (PARROT_IS_THREAD Or PARROT_THR_COPY_INTERP) or
                       PARROT_THR_THREAD_POOL
                       );

  Parrot_debug_flags = (PARROT_NO_DEBUG = $00,PARROT_MEM_STAT_DEBUG_FLAG = $01,
                        PARROT_BACKTRACE_DEBUG_FLAG = $02,PARROT_JIT_DEBUG_FLAG = $04,
                        PARROT_START_DEBUG_FLAG = $08,PARROT_THREAD_DEBUG_FLAG = $10,
                        PARROT_EVAL_DEBUG_FLAG = $20,PARROT_REG_DEBUG_FLAG = $40,
                        PARROT_CTX_DESTROY_DEBUG_FLAG = $80,
                        PARROT_ALL_DEBUG_FLAGS = $ffff);

  Parrot_trace_flags = (PARROT_NO_TRACE = $00,PARROT_TRACE_OPS_FLAG = $01,
                        PARROT_TRACE_FIND_METH_FLAG = $02,PARROT_TRACE_SUB_CALL_FLAG = $04,
                        PARROT_ALL_TRACE_FLAGS = $ffff);

  Parrot_Run_core_t = (PARROT_SLOW_CORE,PARROT_FUNCTION_CORE = PARROT_SLOW_CORE,
                       PARROT_FAST_CORE = $01,PARROT_SWITCH_CORE = $02,
                       PARROT_CGP_CORE = $06,PARROT_CGOTO_CORE = $04,
                       PARROT_EXEC_CORE = $20,PARROT_GC_DEBUG_CORE = $40,
                       PARROT_DEBUGGER_CORE = $80,PARROT_PROFILING_CORE = $160
                      );

  Parrot_clone_flags = (PARROT_CLONE_CODE = $1,PARROT_CLONE_GLOBALS = $2,
                        PARROT_CLONE_RUNOPS = $4,PARROT_CLONE_INTERP_FLAGS = $8,
                        PARROT_CLONE_HLL = $10,PARROT_CLONE_CLASSES = $20,
                        PARROT_CLONE_LIBRARIES = $40,PARROT_CLONE_CC = $80,
                        PARROT_CLONE_DEFAULT = $7f);


  native_func_t = pointer;

  Warnings_classes = (PARROT_WARNINGS_ALL_FLAG = $FF,PARROT_WARNINGS_NONE_FLAG = $00,
                      PARROT_WARNINGS_UNDEF_FLAG = $01,PARROT_WARNINGS_IO_FLAG = $02,
                      PARROT_WARNINGS_PLATFORM_FLAG = $04,
                      PARROT_WARNINGS_DYNEXT_FLAG = $08,PARROT_WARNINGS_DEPRECATED_FLAG = $10
                     );

  Errors_classes = (PARROT_ERRORS_NONE_FLAG = $00,PARROT_ERRORS_GLOBALS_FLAG = $01,
                    PARROT_ERRORS_OVERFLOW_FLAG = $02,PARROT_ERRORS_PARAM_COUNT_FLAG = $04,
                    PARROT_ERRORS_RESULT_COUNT_FLAG = $08,
                    PARROT_ERRORS_ALL_FLAG = $FF);

  Parrot_warnclass = longint;

  Parrot_disassemble_options = (enum_DIS_BARE = 1,enum_DIS_HEADER = 2
                               );

Function Parrot_new(parent:Parrot_Interp): Parrot_Interp;
cdecl;
external External_library name 'Parrot_new';

Procedure Parrot_init_stacktop(_para1:Parrot_Interp; _para2:pointer);
cdecl;
external External_library name 'Parrot_init_stacktop';

Procedure Parrot_set_flag(_para1:Parrot_Interp; _para2:Parrot_Int);
cdecl;
external External_library name 'Parrot_set_flag';

Procedure Parrot_clear_flag(_para1:Parrot_Interp; _para2:Parrot_Int);
cdecl;
external External_library name 'Parrot_clear_flag';

Function Parrot_test_flag(_para1:Parrot_Interp; _para2:Parrot_Int): Parrot_Int;
cdecl;
external External_library name 'Parrot_test_flag';

Procedure Parrot_set_trace(_para1:Parrot_Interp; _para2:Parrot_UInt);
cdecl;
external External_library name 'Parrot_set_trace';

Procedure Parrot_clear_trace(_para1:Parrot_Interp; _para2:Parrot_UInt);
cdecl;
external External_library name 'Parrot_clear_trace';

Function Parrot_test_trace(_para1:Parrot_Interp; _para2:Parrot_UInt): Parrot_UInt;
cdecl;
external External_library name 'Parrot_test_trace';

Procedure Parrot_set_debug(_para1:Parrot_Interp; _para2:Parrot_UInt);
cdecl;
external External_library name 'Parrot_set_debug';

Procedure Parrot_clear_debug(_para1:Parrot_Interp; _para2:Parrot_UInt);
cdecl;
external External_library name 'Parrot_clear_debug';

Function Parrot_test_debug(_para1:Parrot_Interp; _para2:Parrot_UInt): Parrot_UInt;
cdecl;
external External_library name 'Parrot_test_debug';

Procedure Parrot_set_executable_name(_para1:Parrot_Interp; _para2:Parrot_String);
cdecl;
external External_library name 'Parrot_set_executable_name';

Procedure Parrot_set_run_core(_para1:Parrot_Interp; core:Parrot_Run_core_t);
cdecl;
external External_library name 'Parrot_set_run_core';

Procedure Parrot_setwarnings(_para1:Parrot_Interp; _para2:Parrot_warnclass);
cdecl;
external External_library name 'Parrot_setwarnings';

(* Const before type ignored *)
(* Const before type ignored *)
Function Parrot_pbc_read(_para1:Parrot_Interp; _para2:Pchar; _para3:longint): Parrot_PackFile;
cdecl;
external External_library name 'Parrot_pbc_read';

Procedure Parrot_pbc_load(_para1:Parrot_Interp; _para2:Parrot_PackFile);
cdecl;
external External_library name 'Parrot_pbc_load';

Procedure Parrot_pbc_fixup_loaded(_para1:Parrot_Interp);
cdecl;
external External_library name 'Parrot_pbc_fixup_loaded';

(* Const before type ignored *)
Procedure Parrot_runcode(_para1:Parrot_Interp; argc:longint; argv:Ppchar);
cdecl;
external External_library name 'Parrot_runcode';

(* Const before type ignored *)
Function Parrot_compile_string(_para1:Parrot_Interp; _type:Parrot_String; code:pchar; out error:Parrot_String): Parrot_PMC;
cdecl;
external External_library name 'Parrot_compile_string';

Procedure Parrot_destroy(_para1:Parrot_Interp);
cdecl;
external External_library name 'Parrot_destroy';

Function Parrot_debug(_para1:Parrot_Interp; _para2:Parrot_Interp; pc:pParrot_Opcode): PParrot_Opcode
;
cdecl;
external External_library name 'Parrot_debug';

(* Const before type ignored *)
Procedure Parrot_disassemble(_para1:Parrot_Interp; outfile:pchar; options:Parrot_disassemble_options
);
cdecl;
external External_library name 'Parrot_disassemble';

Procedure Parrot_exit(_para1:Parrot_Interp; status:longint);
cdecl;
external External_library name 'Parrot_exit';

Procedure Parrot_run_native(interp:Parrot_Interp; func:native_func_t);
cdecl;
external External_library name 'Parrot_run_native';

Procedure Parrot_set_config_hash;
cdecl;
external 'libparrot_config.so' name 'Parrot_set_config_hash';


Implementation

//procedure Parrot_set_config_hash_internal; cdecl; external External_library  name 'Parrot_set_config_hash';

{ $L parrot_config.o}
{ $G-}
{ $L libparrot.a}

uses SysUtils;

begin
  //LoadLibrary('libparrot_config.so');
  writeln('u');
  Parrot_set_config_hash;
  writeln('i');
End.
