unit pcre;

interface

const outvecSize = 96;
type
  Ppcre = pointer;
  optionSet = set of (PCRE_CASELESS, PCRE_MULTILINE, PCRE_DOTALL, PCRE_EXTENDED, PCRE_ANCHORED, PCRE_DOLLAR_ENDONLY, PCRE_EXTRA, PCRE_NOTBOL, PCRE_NOTEOL, PCRE_UNGREEDY, PCRE_NOTEMPTY, PCRE_UTF8, PCRE_NO_AUTO_CAPTURE, PCRE_NO_UTF8_CHECK, PCRE_AUTO_CALLOUT, PCRE_PARTIAL, PCRE_DFA_SHORTEST, PCRE_DFA_RESTART, PCRE_FIRSTLINE);
  outputVector = array[0..outvecSize] of integer;
  function pcre_compile(pattern: PChar; options: optionSet; var error: PChar; var offset: integer; table: PChar): Ppcre; cdecl; external 'libpcre.so';
  function pcre_exec(code: Ppcre; pcre_extra: pointer; subject: PChar; length, startoffset: integer; options: optionSet; ovector: outputVector; ovecsize: integer=outvecSize): integer; cdecl; external 'libpcre.so';
  procedure pcre_free(code: Ppcre); cdecl; external 'libpcre.so';

implementation

end.
