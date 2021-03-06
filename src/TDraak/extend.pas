
Unit extend;
interface

{   Automatically converted by H2Pas 0.99.15 from extend.hh
  The following command line parameters were used:
    -D
    extend.hh
}

  Const 
    External_library = 'libparrot.so'; {Setup as you need}


  Type 

     Parrot_PMC = Pointer;

     Parrot_String = Pointer;

     Parrot_Interp = Pointer;

     Parrot_Int = longint;

     Parrot_UInt = cardinal;

     Parrot_Float = double;

     PParrot_Opcode = ^Parrot_Opcode;
     Parrot_Opcode = longint;

     Parrot_Pointer = pointer;

     Parrot_Int1 = char;

     Parrot_UInt1 = byte;

     Parrot_Int2 = smallint;

     Parrot_UInt2 = word;

     Parrot_Int4 = longint;

     Parrot_UInt4 = cardinal;

     Parrot_Float4 = double;

     Parrot_Float8 = double;
     PackFile = Record
         {undefined structure}
       End;


     Parrot_PackFile = PackFile;

     Parrot_Interp_flag = (PARROT_NO_FLAGS = $00,PARROT_BOUNDS_FLAG = $04,
                           PARROT_PROFILE_FLAG = $08,PARROT_GC_DEBUG_FLAG = $10,
                           PARROT_EXTERN_CODE_FLAG = $100,PARROT_DESTROY_FLAG = $200,
                           PARROT_IS_THREAD = $1000,PARROT_THR_COPY_INTERP = $2000,
                           PARROT_THR_THREAD_POOL = $4000,PARROT_THR_TYPE_1 =
                           PARROT_IS_THREAD,
                           PARROT_THR_TYPE_2 = PARROT_IS_THREAD Or PARROT_THR_COPY_INTERP
                           ,PARROT_THR_TYPE_3 = (PARROT_IS_THREAD Or
                           PARROT_THR_COPY_INTERP) or PARROT_THR_THREAD_POOL
                          );

     Parrot_debug_flags = (PARROT_NO_DEBUG = $00,PARROT_MEM_STAT_DEBUG_FLAG = $01,
                           PARROT_BACKTRACE_DEBUG_FLAG = $02,PARROT_JIT_DEBUG_FLAG = $04
                           ,
                           PARROT_START_DEBUG_FLAG = $08,PARROT_THREAD_DEBUG_FLAG = $10,
                           PARROT_EVAL_DEBUG_FLAG = $20,PARROT_REG_DEBUG_FLAG = $40,
                           PARROT_CTX_DESTROY_DEBUG_FLAG = $80,
                           PARROT_ALL_DEBUG_FLAGS = $ffff);

     Parrot_trace_flags = (PARROT_NO_TRACE = $00,PARROT_TRACE_OPS_FLAG = $01,
                           PARROT_TRACE_FIND_METH_FLAG = $02,PARROT_TRACE_SUB_CALL_FLAG
                           = $04,
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

     Warnings_classes = (PARROT_WARNINGS_ALL_FLAG = $FF,PARROT_WARNINGS_NONE_FLAG = $00,
                         PARROT_WARNINGS_UNDEF_FLAG = $01,PARROT_WARNINGS_IO_FLAG = $02,
                         PARROT_WARNINGS_PLATFORM_FLAG = $04,
                         PARROT_WARNINGS_DYNEXT_FLAG = $08,
                         PARROT_WARNINGS_DEPRECATED_FLAG = $10
                        );

     Errors_classes = (PARROT_ERRORS_NONE_FLAG = $00,PARROT_ERRORS_GLOBALS_FLAG = $01,
                       PARROT_ERRORS_OVERFLOW_FLAG = $02,PARROT_ERRORS_PARAM_COUNT_FLAG
                       = $04,
                       PARROT_ERRORS_RESULT_COUNT_FLAG = $08,
                       PARROT_ERRORS_ALL_FLAG = $FF);

     Parrot_Language = Parrot_Int;

     Parrot_Encoding = Pointer;

     Parrot_CharType = Pointer;
(* Const before type ignored *)

     Parrot_Const_Encoding = Pointer;
(* Const before type ignored *)

     Parrot_Const_CharType = Pointer;
(* Const before type ignored *)

     Parrot_VTABLE = Pointer;

     ptrdiff_t = longint;

     size_t = cardinal;

     wchar_t = longint;

  Function Parrot_PMC_absolute(interp:Parrot_Interp; pmc:Parrot_PMC; dest:Parrot_PMC):
                                                                                Parrot_PMC
;
cdecl;
external External_library name 'Parrot_PMC_absolute';

  Function Parrot_PMC_add(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC; dest:
                          Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_add';

  Procedure Parrot_PMC_add_attribute(interp:Parrot_Interp; pmc:Parrot_PMC; name:
                                     Parrot_String; _type:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_add_attribute';

  Function Parrot_PMC_add_float(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_Float;
                                dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_add_float';

  Function Parrot_PMC_add_int(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_Int; dest
                              :Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_add_int';

  Procedure Parrot_PMC_add_method(interp:Parrot_Interp; pmc:Parrot_PMC; method_name:
                                  Parrot_String; sub_pmc:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_add_method';

  Procedure Parrot_PMC_add_parent(interp:Parrot_Interp; pmc:Parrot_PMC; parent:Parrot_PMC)
;
cdecl;
external External_library name 'Parrot_PMC_add_parent';

  Procedure Parrot_PMC_add_role(interp:Parrot_Interp; pmc:Parrot_PMC; role:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_add_role';

  Procedure Parrot_PMC_add_vtable_override(interp:Parrot_Interp; pmc:Parrot_PMC;
                                           vtable_name:Parrot_String; sub_pmc:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_add_vtable_override';

  Procedure Parrot_PMC_assign_pmc(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_assign_pmc';

  Procedure Parrot_PMC_assign_string_native(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                            Parrot_String);
cdecl;
external External_library name 'Parrot_PMC_assign_string_native';

  Function Parrot_PMC_can(interp:Parrot_Interp; pmc:Parrot_PMC; method:Parrot_String):
                                                                                Parrot_Int
;
cdecl;
external External_library name 'Parrot_PMC_can';

  Function Parrot_PMC_clone(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_clone';

  Function Parrot_PMC_clone_pmc(interp:Parrot_Interp; pmc:Parrot_PMC; args:Parrot_PMC):
                                                                                Parrot_PMC
;
cdecl;
external External_library name 'Parrot_PMC_clone_pmc';

  Function Parrot_PMC_cmp(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC):
                                                                                Parrot_Int
;
cdecl;
external External_library name 'Parrot_PMC_cmp';

  Function Parrot_PMC_cmp_num(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC):
                                                                                Parrot_Int
;
cdecl;
external External_library name 'Parrot_PMC_cmp_num';

  Function Parrot_PMC_cmp_pmc(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC):
                                                                                Parrot_PMC
;
cdecl;
external External_library name 'Parrot_PMC_cmp_pmc';

  Function Parrot_PMC_cmp_string(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC):
                                                                                Parrot_Int
;
cdecl;
external External_library name 'Parrot_PMC_cmp_string';

  Function Parrot_PMC_concatenate(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC;
                                  dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_concatenate';

  Function Parrot_PMC_concatenate_str(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                      Parrot_String; dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_concatenate_str';

  Procedure Parrot_PMC_decrement(interp:Parrot_Interp; pmc:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_decrement';

  Function Parrot_PMC_defined(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_Int;
cdecl;
external External_library name 'Parrot_PMC_defined';

  Function Parrot_PMC_defined_keyed(interp:Parrot_Interp; pmc:Parrot_PMC; key:Parrot_PMC):
                                                                                Parrot_Int
;
cdecl;
external External_library name 'Parrot_PMC_defined_keyed';

  Function Parrot_PMC_defined_keyed_int(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                        Parrot_Int): Parrot_Int;
cdecl;
external External_library name 'Parrot_PMC_defined_keyed_int';

  Function Parrot_PMC_defined_keyed_str(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                        Parrot_String): Parrot_Int;
cdecl;
external External_library name 'Parrot_PMC_defined_keyed_str';

  Procedure Parrot_PMC_delete_keyed(interp:Parrot_Interp; pmc:Parrot_PMC; key:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_delete_keyed';

  Procedure Parrot_PMC_delete_keyed_int(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                        Parrot_Int);
cdecl;
external External_library name 'Parrot_PMC_delete_keyed_int';

  Procedure Parrot_PMC_delete_keyed_str(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                        Parrot_String);
cdecl;
external External_library name 'Parrot_PMC_delete_keyed_str';

  Procedure Parrot_PMC_delprop(interp:Parrot_Interp; pmc:Parrot_PMC; key:Parrot_String);
cdecl;
external External_library name 'Parrot_PMC_delprop';

  Procedure Parrot_PMC_destroy(interp:Parrot_Interp; pmc:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_destroy';

  Function Parrot_PMC_divide(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC; dest:
                             Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_divide';

  Function Parrot_PMC_divide_float(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                   Parrot_Float; dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_divide_float';

  Function Parrot_PMC_divide_int(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_Int;
                                 dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_divide_int';

  Function Parrot_PMC_does(interp:Parrot_Interp; pmc:Parrot_PMC; role:Parrot_String):
                                                                                Parrot_Int
;
cdecl;
external External_library name 'Parrot_PMC_does';

  Function Parrot_PMC_does_pmc(interp:Parrot_Interp; pmc:Parrot_PMC; role:Parrot_PMC):
                                                                                Parrot_Int
;
cdecl;
external External_library name 'Parrot_PMC_does_pmc';

  Function Parrot_PMC_elements(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_Int;
cdecl;
external External_library name 'Parrot_PMC_elements';

  Function Parrot_PMC_exists_keyed(interp:Parrot_Interp; pmc:Parrot_PMC; key:Parrot_PMC):
                                                                                Parrot_Int
;
cdecl;
external External_library name 'Parrot_PMC_exists_keyed';

  Function Parrot_PMC_exists_keyed_int(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                       Parrot_Int): Parrot_Int;
cdecl;
external External_library name 'Parrot_PMC_exists_keyed_int';

  Function Parrot_PMC_exists_keyed_str(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                       Parrot_String): Parrot_Int;
cdecl;
external External_library name 'Parrot_PMC_exists_keyed_str';

  Function Parrot_PMC_find_method(interp:Parrot_Interp; pmc:Parrot_PMC; method_name:
                                  Parrot_String): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_find_method';

  Function Parrot_PMC_floor_divide(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC;
                                   dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_floor_divide';

  Function Parrot_PMC_floor_divide_float(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                         Parrot_Float; dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_floor_divide_float';

  Function Parrot_PMC_floor_divide_int(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                       Parrot_Int; dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_floor_divide_int';

  Procedure Parrot_PMC_freeze(interp:Parrot_Interp; pmc:Parrot_PMC; info:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_freeze';

  Function Parrot_PMC_get_attr_keyed(interp:Parrot_Interp; pmc:Parrot_PMC; key:Parrot_PMC;
                                     idx:Parrot_String): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_get_attr_keyed';

  Function Parrot_PMC_get_attr_str(interp:Parrot_Interp; pmc:Parrot_PMC; idx:Parrot_String
): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_get_attr_str';

  Function Parrot_PMC_get_bool(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_Int;
cdecl;
external External_library name 'Parrot_PMC_get_bool';

  Function Parrot_PMC_get_class(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_get_class';

  Function Parrot_PMC_get_integer(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_Int;
cdecl;
external External_library name 'Parrot_PMC_get_integer';

  Function Parrot_PMC_get_integer_keyed(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                        Parrot_PMC): Parrot_Int;
cdecl;
external External_library name 'Parrot_PMC_get_integer_keyed';

  Function Parrot_PMC_get_integer_keyed_int(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                            Parrot_Int): Parrot_Int;
cdecl;
external External_library name 'Parrot_PMC_get_integer_keyed_int';

  Function Parrot_PMC_get_integer_keyed_str(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                            Parrot_String): Parrot_Int;
cdecl;
external External_library name 'Parrot_PMC_get_integer_keyed_str';

  Function Parrot_PMC_get_iter(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_get_iter';

  Function Parrot_PMC_get_namespace(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_get_namespace';

  Function Parrot_PMC_get_number(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_Float;
cdecl;
external External_library name 'Parrot_PMC_get_number';

  Function Parrot_PMC_get_number_keyed(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                       Parrot_PMC): Parrot_Float;
cdecl;
external External_library name 'Parrot_PMC_get_number_keyed';

  Function Parrot_PMC_get_number_keyed_int(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                           Parrot_Int): Parrot_Float;
cdecl;
external External_library name 'Parrot_PMC_get_number_keyed_int';

  Function Parrot_PMC_get_number_keyed_str(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                           Parrot_String): Parrot_Float;
cdecl;
external External_library name 'Parrot_PMC_get_number_keyed_str';

  Function Parrot_PMC_get_pmc(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_get_pmc';

  Function Parrot_PMC_get_pmc_keyed(interp:Parrot_Interp; pmc:Parrot_PMC; key:Parrot_PMC):
                                                                                Parrot_PMC
;
cdecl;
external External_library name 'Parrot_PMC_get_pmc_keyed';

  Function Parrot_PMC_get_pmc_keyed_int(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                        Parrot_Int): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_get_pmc_keyed_int';

  Function Parrot_PMC_get_pmc_keyed_str(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                        Parrot_String): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_get_pmc_keyed_str';

  Function Parrot_PMC_get_pointer(interp:Parrot_Interp; pmc:Parrot_PMC): pointer;
cdecl;
external External_library name 'Parrot_PMC_get_pointer';

  Function Parrot_PMC_get_pointer_keyed(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                        Parrot_PMC): pointer;
cdecl;
external External_library name 'Parrot_PMC_get_pointer_keyed';

  Function Parrot_PMC_get_pointer_keyed_int(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                            Parrot_Int): pointer;
cdecl;
external External_library name 'Parrot_PMC_get_pointer_keyed_int';

  Function Parrot_PMC_get_pointer_keyed_str(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                            Parrot_String): pointer;
cdecl;
external External_library name 'Parrot_PMC_get_pointer_keyed_str';

  Function Parrot_PMC_get_repr(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_String;
cdecl;
external External_library name 'Parrot_PMC_get_repr';

  Function Parrot_PMC_get_string(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_String;
cdecl;
external External_library name 'Parrot_PMC_get_string';

  Function Parrot_PMC_get_string_keyed(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                       Parrot_PMC): Parrot_String;
cdecl;
external External_library name 'Parrot_PMC_get_string_keyed';

  Function Parrot_PMC_get_string_keyed_int(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                           Parrot_Int): Parrot_String;
cdecl;
external External_library name 'Parrot_PMC_get_string_keyed_int';

  Function Parrot_PMC_get_string_keyed_str(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                           Parrot_String): Parrot_String;
cdecl;
external External_library name 'Parrot_PMC_get_string_keyed_str';

  Function Parrot_PMC_getprop(interp:Parrot_Interp; pmc:Parrot_PMC; key:Parrot_String):
                                                                                Parrot_PMC
;
cdecl;
external External_library name 'Parrot_PMC_getprop';

  Function Parrot_PMC_getprops(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_getprops';

  Function Parrot_PMC_hashvalue(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_Int;
cdecl;
external External_library name 'Parrot_PMC_hashvalue';

  Procedure Parrot_PMC_i_absolute(interp:Parrot_Interp; pmc:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_i_absolute';

  Procedure Parrot_PMC_i_add(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_i_add';

  Procedure Parrot_PMC_i_add_float(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                   Parrot_Float);
cdecl;
external External_library name 'Parrot_PMC_i_add_float';

  Procedure Parrot_PMC_i_add_int(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_Int);
cdecl;
external External_library name 'Parrot_PMC_i_add_int';

  Procedure Parrot_PMC_i_concatenate(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                     Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_i_concatenate';

  Procedure Parrot_PMC_i_concatenate_str(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                         Parrot_String);
cdecl;
external External_library name 'Parrot_PMC_i_concatenate_str';

  Procedure Parrot_PMC_i_divide(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_i_divide';

  Procedure Parrot_PMC_i_divide_float(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                      Parrot_Float);
cdecl;
external External_library name 'Parrot_PMC_i_divide_float';

  Procedure Parrot_PMC_i_divide_int(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_Int
);
cdecl;
external External_library name 'Parrot_PMC_i_divide_int';

  Procedure Parrot_PMC_i_floor_divide(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                      Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_i_floor_divide';

  Procedure Parrot_PMC_i_floor_divide_float(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                            Parrot_Float);
cdecl;
external External_library name 'Parrot_PMC_i_floor_divide_float';

  Procedure Parrot_PMC_i_floor_divide_int(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                          Parrot_Int);
cdecl;
external External_library name 'Parrot_PMC_i_floor_divide_int';

  Procedure Parrot_PMC_i_logical_not(interp:Parrot_Interp; pmc:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_i_logical_not';

  Procedure Parrot_PMC_i_modulus(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_i_modulus';

  Procedure Parrot_PMC_i_modulus_float(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                       Parrot_Float);
cdecl;
external External_library name 'Parrot_PMC_i_modulus_float';

  Procedure Parrot_PMC_i_modulus_int(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                     Parrot_Int);
cdecl;
external External_library name 'Parrot_PMC_i_modulus_int';

  Procedure Parrot_PMC_i_multiply(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_i_multiply';

  Procedure Parrot_PMC_i_multiply_float(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                        Parrot_Float);
cdecl;
external External_library name 'Parrot_PMC_i_multiply_float';

  Procedure Parrot_PMC_i_multiply_int(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                      Parrot_Int);
cdecl;
external External_library name 'Parrot_PMC_i_multiply_int';

  Procedure Parrot_PMC_i_neg(interp:Parrot_Interp; pmc:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_i_neg';

  Procedure Parrot_PMC_i_repeat(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_i_repeat';

  Procedure Parrot_PMC_i_repeat_int(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_Int
);
cdecl;
external External_library name 'Parrot_PMC_i_repeat_int';

  Procedure Parrot_PMC_i_subtract(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_i_subtract';

  Procedure Parrot_PMC_i_subtract_float(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                        Parrot_Float);
cdecl;
external External_library name 'Parrot_PMC_i_subtract_float';

  Procedure Parrot_PMC_i_subtract_int(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                      Parrot_Int);
cdecl;
external External_library name 'Parrot_PMC_i_subtract_int';

  Procedure Parrot_PMC_increment(interp:Parrot_Interp; pmc:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_increment';

  Procedure Parrot_PMC_init(interp:Parrot_Interp; pmc:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_init';

  Procedure Parrot_PMC_init_int(interp:Parrot_Interp; pmc:Parrot_PMC; initializer:
                                Parrot_Int);
cdecl;
external External_library name 'Parrot_PMC_init_int';

  Procedure Parrot_PMC_init_pmc(interp:Parrot_Interp; pmc:Parrot_PMC; initializer:
                                Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_init_pmc';

  Function Parrot_PMC_inspect(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_inspect';

  Function Parrot_PMC_inspect_str(interp:Parrot_Interp; pmc:Parrot_PMC; what:Parrot_String
): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_inspect_str';

  Function Parrot_PMC_instantiate(interp:Parrot_Interp; pmc:Parrot_PMC; sig:Parrot_PMC):
                                                                                Parrot_PMC
;
cdecl;
external External_library name 'Parrot_PMC_instantiate';

  Function Parrot_PMC_invoke(interp:Parrot_Interp; pmc:Parrot_PMC; next:pointer): PParrot_Opcode
;
cdecl;
external External_library name 'Parrot_PMC_invoke';

  Function Parrot_PMC_is_equal(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC):
                                                                                Parrot_Int
;
cdecl;
external External_library name 'Parrot_PMC_is_equal';

  Function Parrot_PMC_is_equal_num(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC)
: Parrot_Int;
cdecl;
external External_library name 'Parrot_PMC_is_equal_num';

  Function Parrot_PMC_is_equal_string(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                      Parrot_PMC): Parrot_Int;
cdecl;
external External_library name 'Parrot_PMC_is_equal_string';

  Function Parrot_PMC_is_same(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC):
                                                                                Parrot_Int
;
cdecl;
external External_library name 'Parrot_PMC_is_same';

  Function Parrot_PMC_isa(interp:Parrot_Interp; pmc:Parrot_PMC; _class:Parrot_String):
                                                                                Parrot_Int
;
cdecl;
external External_library name 'Parrot_PMC_isa';

  Function Parrot_PMC_isa_pmc(interp:Parrot_Interp; pmc:Parrot_PMC; _class:Parrot_PMC):
                                                                                Parrot_Int
;
cdecl;
external External_library name 'Parrot_PMC_isa_pmc';

  Function Parrot_PMC_logical_and(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC;
                                  dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_logical_and';

  Function Parrot_PMC_logical_not(interp:Parrot_Interp; pmc:Parrot_PMC; dest:Parrot_PMC):
                                                                                Parrot_PMC
;
cdecl;
external External_library name 'Parrot_PMC_logical_not';

  Function Parrot_PMC_logical_or(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC;
                                 dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_logical_or';

  Function Parrot_PMC_logical_xor(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC;
                                  dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_logical_xor';

  Procedure Parrot_PMC_mark(interp:Parrot_Interp; pmc:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_mark';

  Function Parrot_PMC_modulus(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC; dest
                              :Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_modulus';

  Function Parrot_PMC_modulus_float(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                    Parrot_Float; dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_modulus_float';

  Function Parrot_PMC_modulus_int(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_Int;
                                  dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_modulus_int';

  Procedure Parrot_PMC_morph(interp:Parrot_Interp; pmc:Parrot_PMC; _type:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_morph';

  Function Parrot_PMC_multiply(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC;
                               dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_multiply';

  Function Parrot_PMC_multiply_float(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                     Parrot_Float; dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_multiply_float';

  Function Parrot_PMC_multiply_int(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_Int;
                                   dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_multiply_int';

  Function Parrot_PMC_name(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_String;
cdecl;
external External_library name 'Parrot_PMC_name';

  Function Parrot_PMC_neg(interp:Parrot_Interp; pmc:Parrot_PMC; dest:Parrot_PMC):
                                                                                Parrot_PMC
;
cdecl;
external External_library name 'Parrot_PMC_neg';

  Function Parrot_PMC_pop_float(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_Float;
cdecl;
external External_library name 'Parrot_PMC_pop_float';

  Function Parrot_PMC_pop_integer(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_Int;
cdecl;
external External_library name 'Parrot_PMC_pop_integer';

  Function Parrot_PMC_pop_pmc(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_pop_pmc';

  Function Parrot_PMC_pop_string(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_String;
cdecl;
external External_library name 'Parrot_PMC_pop_string';

  Procedure Parrot_PMC_push_float(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_Float
);
cdecl;
external External_library name 'Parrot_PMC_push_float';

  Procedure Parrot_PMC_push_integer(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_Int
);
cdecl;
external External_library name 'Parrot_PMC_push_integer';

  Procedure Parrot_PMC_push_pmc(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_push_pmc';

  Procedure Parrot_PMC_push_string(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                   Parrot_String);
cdecl;
external External_library name 'Parrot_PMC_push_string';

  Procedure Parrot_PMC_remove_attribute(interp:Parrot_Interp; pmc:Parrot_PMC; name:
                                        Parrot_String);
cdecl;
external External_library name 'Parrot_PMC_remove_attribute';

  Procedure Parrot_PMC_remove_method(interp:Parrot_Interp; pmc:Parrot_PMC; method_name:
                                     Parrot_String);
cdecl;
external External_library name 'Parrot_PMC_remove_method';

  Procedure Parrot_PMC_remove_parent(interp:Parrot_Interp; pmc:Parrot_PMC; parent:
                                     Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_remove_parent';

  Procedure Parrot_PMC_remove_role(interp:Parrot_Interp; pmc:Parrot_PMC; role:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_remove_role';

  Procedure Parrot_PMC_remove_vtable_override(interp:Parrot_Interp; pmc:Parrot_PMC;
                                              vtable_name:Parrot_String);
cdecl;
external External_library name 'Parrot_PMC_remove_vtable_override';

  Function Parrot_PMC_repeat(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC; dest:
                             Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_repeat';

  Function Parrot_PMC_repeat_int(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_Int;
                                 dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_repeat_int';

  Procedure Parrot_PMC_set_attr_keyed(interp:Parrot_Interp; pmc:Parrot_PMC; key:Parrot_PMC
                                      ; idx:Parrot_String; value:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_set_attr_keyed';

  Procedure Parrot_PMC_set_attr_str(interp:Parrot_Interp; pmc:Parrot_PMC; idx:
                                    Parrot_String; value:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_set_attr_str';

  Procedure Parrot_PMC_set_bool(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_Int);
cdecl;
external External_library name 'Parrot_PMC_set_bool';

  Procedure Parrot_PMC_set_integer_keyed(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                         Parrot_PMC; value:Parrot_Int);
cdecl;
external External_library name 'Parrot_PMC_set_integer_keyed';

  Procedure Parrot_PMC_set_integer_keyed_int(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                             Parrot_Int; value:Parrot_Int);
cdecl;
external External_library name 'Parrot_PMC_set_integer_keyed_int';

  Procedure Parrot_PMC_set_integer_keyed_str(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                             Parrot_String; value:Parrot_Int);
cdecl;
external External_library name 'Parrot_PMC_set_integer_keyed_str';

  Procedure Parrot_PMC_set_integer_native(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                          Parrot_Int);
cdecl;
external External_library name 'Parrot_PMC_set_integer_native';

  Procedure Parrot_PMC_set_number_keyed(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                        Parrot_PMC; value:Parrot_Float);
cdecl;
external External_library name 'Parrot_PMC_set_number_keyed';

  Procedure Parrot_PMC_set_number_keyed_int(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                            Parrot_Int; value:Parrot_Float);
cdecl;
external External_library name 'Parrot_PMC_set_number_keyed_int';

  Procedure Parrot_PMC_set_number_keyed_str(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                            Parrot_String; value:Parrot_Float);
cdecl;
external External_library name 'Parrot_PMC_set_number_keyed_str';

  Procedure Parrot_PMC_set_number_native(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                         Parrot_Float);
cdecl;
external External_library name 'Parrot_PMC_set_number_native';

  Procedure Parrot_PMC_set_pmc(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_set_pmc';

  Procedure Parrot_PMC_set_pmc_keyed(interp:Parrot_Interp; pmc:Parrot_PMC; key:Parrot_PMC;
                                     value:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_set_pmc_keyed';

  Procedure Parrot_PMC_set_pmc_keyed_int(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                         Parrot_Int; value:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_set_pmc_keyed_int';

  Procedure Parrot_PMC_set_pmc_keyed_str(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                         Parrot_String; value:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_set_pmc_keyed_str';

  Procedure Parrot_PMC_set_pointer(interp:Parrot_Interp; pmc:Parrot_PMC; value:pointer);
cdecl;
external External_library name 'Parrot_PMC_set_pointer';

  Procedure Parrot_PMC_set_pointer_keyed(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                         Parrot_PMC; value:pointer);
cdecl;
external External_library name 'Parrot_PMC_set_pointer_keyed';

  Procedure Parrot_PMC_set_pointer_keyed_int(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                             Parrot_Int; value:pointer);
cdecl;
external External_library name 'Parrot_PMC_set_pointer_keyed_int';

  Procedure Parrot_PMC_set_pointer_keyed_str(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                             Parrot_String; value:pointer);
cdecl;
external External_library name 'Parrot_PMC_set_pointer_keyed_str';

  Procedure Parrot_PMC_set_string_keyed(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                        Parrot_PMC; value:Parrot_String);
cdecl;
external External_library name 'Parrot_PMC_set_string_keyed';

  Procedure Parrot_PMC_set_string_keyed_int(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                            Parrot_Int; value:Parrot_String);
cdecl;
external External_library name 'Parrot_PMC_set_string_keyed_int';

  Procedure Parrot_PMC_set_string_keyed_str(interp:Parrot_Interp; pmc:Parrot_PMC; key:
                                            Parrot_String; value:Parrot_String);
cdecl;
external External_library name 'Parrot_PMC_set_string_keyed_str';

  Procedure Parrot_PMC_set_string_native(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                         Parrot_String);
cdecl;
external External_library name 'Parrot_PMC_set_string_native';

  Procedure Parrot_PMC_setprop(interp:Parrot_Interp; pmc:Parrot_PMC; key:Parrot_String;
                               value:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_setprop';

  Procedure Parrot_PMC_share(interp:Parrot_Interp; pmc:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_share';

  Function Parrot_PMC_share_ro(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_share_ro';

  Function Parrot_PMC_shift_float(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_Float;
cdecl;
external External_library name 'Parrot_PMC_shift_float';

  Function Parrot_PMC_shift_integer(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_Int;
cdecl;
external External_library name 'Parrot_PMC_shift_integer';

  Function Parrot_PMC_shift_pmc(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_shift_pmc';

  Function Parrot_PMC_shift_string(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_String;
cdecl;
external External_library name 'Parrot_PMC_shift_string';

  Procedure Parrot_PMC_splice(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC;
                              offset:Parrot_Int; count:Parrot_Int);
cdecl;
external External_library name 'Parrot_PMC_splice';

  Procedure Parrot_PMC_substr(interp:Parrot_Interp; pmc:Parrot_PMC; offset:Parrot_Int;
                              length:Parrot_Int; dest:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_substr';

  Function Parrot_PMC_substr_str(interp:Parrot_Interp; pmc:Parrot_PMC; offset:Parrot_Int;
                                 length:Parrot_Int): Parrot_String;
cdecl;
external External_library name 'Parrot_PMC_substr_str';

  Function Parrot_PMC_subtract(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC;
                               dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_subtract';

  Function Parrot_PMC_subtract_float(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                     Parrot_Float; dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_subtract_float';

  Function Parrot_PMC_subtract_int(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_Int;
                                   dest:Parrot_PMC): Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_subtract_int';

  Procedure Parrot_PMC_thaw(interp:Parrot_Interp; pmc:Parrot_PMC; info:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_thaw';

  Procedure Parrot_PMC_thawfinish(interp:Parrot_Interp; pmc:Parrot_PMC; info:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_thawfinish';

  Function Parrot_PMC_type(interp:Parrot_Interp; pmc:Parrot_PMC): Parrot_Int;
cdecl;
external External_library name 'Parrot_PMC_type';

  Procedure Parrot_PMC_unshift_float(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                     Parrot_Float);
cdecl;
external External_library name 'Parrot_PMC_unshift_float';

  Procedure Parrot_PMC_unshift_integer(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                       Parrot_Int);
cdecl;
external External_library name 'Parrot_PMC_unshift_integer';

  Procedure Parrot_PMC_unshift_pmc(interp:Parrot_Interp; pmc:Parrot_PMC; value:Parrot_PMC)
;
cdecl;
external External_library name 'Parrot_PMC_unshift_pmc';

  Procedure Parrot_PMC_unshift_string(interp:Parrot_Interp; pmc:Parrot_PMC; value:
                                      Parrot_String);
cdecl;
external External_library name 'Parrot_PMC_unshift_string';

  Procedure Parrot_PMC_visit(interp:Parrot_Interp; pmc:Parrot_PMC; info:Parrot_PMC);
cdecl;
external External_library name 'Parrot_PMC_visit';


  Function Parrot_PMC_null: Parrot_PMC;
cdecl;
external External_library name 'Parrot_PMC_null';

  Procedure Parrot_ext_call(interp: Parrot_Interp; sub_pmc:Parrot_PMC; const signature:PChar);
cdecl; varargs;
external External_library name 'Parrot_ext_call';

  Function Parrot_new_string(interp: Parrot_Interp; buffer:PChar; len:Parrot_UInt; encoding_name:PChar; flags:Parrot_UInt): Parrot_String;
cdecl;
external External_library name 'Parrot_new_string';

(*  Extra *)

  Function Parrot_str_to_cstring(interp: Parrot_Interp; s:Parrot_String): PChar;
cdecl;
external External_library name 'Parrot_str_to_cstring';

implementation


End.
