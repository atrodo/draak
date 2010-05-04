unit regexp;

interface

uses pcre;

type
  RCapture = record
      captured: string;
      pos:      cardinal;
      len:      cardinal;
    end;

  RCaptureArr = array of RCapture;
  
  RegExpFlags = set of (IgnoreCase, MultiLine, SingleLine, Extended, Global, Anch);
  TRegExp = class
   private
    FboundString: string;
    Foffset: integer;
    Fpcre: Ppcre;
    Fcompiled: string;
    Fflags: RegExpFlags;
    FpcreFlags: optionSet;
    Fmatched: string;
    Fcapture: RCaptureArr;
    function getCapture(i: integer): RCapture;
    
    function do_match: boolean;
    function do_match_global: boolean;
    function do_substitute(replacement: string): string;
    function do_substitute_global(replacement: string): string;

    function boundmatch(regex: string): string;
    function boundsubstitute(regex: string; replace: string): string; overload;
   public
    constructor create(regex: string = ''; flags: RegExpFlags = []; boundString: string = '');

    procedure compile(regex: string; flags: RegExpFlags = []);
    procedure bind(boundString: string);

    function captureLength: cardinal;

    function match: boolean; overload;
    function match(boundString: string): boolean; overload;
    function substitute(replace: string): string; overload;
    function substitute(boundString: string; replace: string): string; overload;

    class function match(regex: string; bound: string; Flags: RegExpFlags = []): string; overload;
    class function substitute(regex: string; bound: string; replace: string; Flags: RegExpFlags = []): string; overload;

    destructor destroy; override;

   public
    property matched: string read Fmatched;
    property capture[i: integer]: RCapture read getCapture;
    property offset: integer read Foffset write Foffset;
    property m[regex: string]: string read boundmatch;
    property s[regex: string; replace: string]: string read boundsubstitute;
  end;

  function generateFlags(flags: string): RegExpFlags;

implementation

uses SysUtils;
//uses oslib, util, SysUtils;

function TRegExp.getCapture(i: integer): RCapture;
begin
  result.captured := '';
  if i < length(Fcapture) then
    result := Fcapture[i];
end;

function TRegExp.do_match: boolean;
var
  i: integer;
  ovector: outputVector;
begin;
  result := false;
  setLength(Fcapture, 0);
  Fmatched := '';
  //writeln('do '+Fcompiled);
  if Foffset = length(FboundString) then
    exit;
  //writeln('exec '+Fcompiled);
  //writeln('on '+copy(FboundString, Foffset, 20));
  i := pcre_exec(Fpcre, nil, PChar(FboundString), length(FboundString), Foffset, [], ovector, 96);
  if i < -1 then
    raise Exception.create('Match error: '+intToStr(i));
  if i = -1 then exit;
  if i = 0 then
    raise Exception.create('Match error: too many capture strings (>32)');
  result := true;
  setLength(Fcapture, i);
  for i := 0 to i-1 do
  begin
    Fcapture[i].pos := ovector[i*2]+1;
    Fcapture[i].len := ovector[i*2+1]-ovector[i*2];
    Fcapture[i].captured := copy(FboundString, Fcapture[i].pos, Fcapture[i].len);
  end;
  Fmatched := Fcapture[0].captured;
  Foffset  := ovector[1];

  {
  writeln('===');
  writeln(Fmatched);
  for i := 0 to i*2 do
  begin
    //writeln(i);
    //writeln(ovector[i]);
    writeln(i);
    writeln(Fcapture[i].pos);
    writeln(Fcapture[i].len);
    writeln(Fcapture[i].captured);
  end;
    writeln('===');
  }
end;

function TRegExp.do_match_global: boolean;
var 
  allCapture: RCaptureArr;
  oldLen: cardinal;
  i: cardinal;
begin
  result := false;
  setLength(allCapture, 1);
  allCapture[0].pos := Foffset;
  allCapture[0].len := 0;
  allCapture[0].captured := '';

  while result = false do
  begin
    result := do_match;
    if result = false then break;
    oldLen := length(allCapture);
    setLength(allCapture, oldLen+length(Fcapture));
    for i := 1 to length(Fcapture)-1 do
      allCapture[i+oldLen] := Fcapture[i];
  end;
  
  allCapture[0].len := Foffset+Fcapture[length(Fcapture)-1].len;
  allCapture[0].captured := copy(FboundString, allCapture[0].pos, allCapture[0].len);
  Fcapture := allCapture;
  Fmatched := Fcapture[0].captured;

end;

function TRegExp.do_substitute(replacement: string): string;
var
  status: boolean;
  i: cardinal;
  origOffset: cardinal;
begin
  result := '';
  origOffset := Foffset;
  status := do_match;
  if status = false then exit;

  for i := 1 to length(Fcapture)-1 do
    replacement := StringReplace(replacement, '$'+intToStr(i), Fcapture[i].captured, [rfReplaceAll]);
  replacement := StringReplace(replacement, '\n', #10, [rfReplaceAll]);
  Fmatched := replacement;
  result := FboundString;
  delete(result, Fcapture[0].pos, Fcapture[0].len);
  insert(replacement, result, Fcapture[0].pos);
  result := copy(result, origOffset+1, length(result));
  //Foffset := Foffset - Fcapture[0].len + length(replacement);
end;

function TRegExp.do_substitute_global(replacement: string): string;
var 
  done: boolean;
  allCapture: RCaptureArr;
  oldLen: cardinal;
  i: cardinal;
  singleSub: string;
begin
  result := '';
  done := false;
  setLength(allCapture, 1);
  allCapture[0].pos := Foffset;
  allCapture[0].len := 0;
  allCapture[0].captured := '';

  while done = false do
  begin
    singleSub := do_substitute(replacement);
    if singleSub = '' then break;
    delete(singleSub, length(singleSub) - (length(FboundString)-Foffset) + 1, length(singleSub));
    //result := result + copy(singleSub, oldLen, Foffset-oldLen+length(Fmatched));
    result := result + singleSub;
    oldLen := length(allCapture);
    setLength(allCapture, oldLen+length(Fcapture));
    for i := 1 to length(Fcapture)-1 do
      allCapture[i+oldLen] := Fcapture[i];
    //result := result + Fmatched;
  end;
  result := result + copy(FboundString, Foffset+1, length(FboundString));
  
  if length(Fcapture) > 0 then
    allCapture[0].len := Foffset+Fcapture[length(Fcapture)-1].len;
  allCapture[0].captured := copy(FboundString, allCapture[0].pos, allCapture[0].len);
  Fcapture := allCapture;
  Fmatched := Fcapture[0].captured;
  //result := Fmatched;
  
end;

constructor TRegExp.create(regex: string = ''; flags: RegExpFlags = []; boundString: string = '');
begin
  compile(regex, flags);
  bind(boundString);
  setlength(Fcapture, 0);
  Foffset := 0;
end;

procedure TRegExp.compile(regex: string; flags: RegExpFlags = []);
var error: PChar;
  offset: integer;
begin
  Fflags := flags;
  FpcreFlags := [];
  if IgnoreCase in flags then Include(FpcreFlags, PCRE_CASELESS);
  if MultiLine  in flags then Include(FpcreFlags, PCRE_MULTILINE);
  if SingleLine in flags then Include(FpcreFlags, PCRE_DOTALL);
  if Extended   in flags then Include(FpcreFlags, PCRE_EXTENDED);

  if Anch       in flags then Include(FpcreFlags, PCRE_ANCHORED);

  Fpcre := pcre_compile(PChar(regex), FpcreFlags,  error, offset, nil);
  if not assigned(Fpcre) then
  begin
    raise Exception.create('Compile error: '+error+' at offset '+intToStr(offset)+' : '+regex);
  end;
  Fcompiled := regex;
end;

procedure TRegExp.bind(boundString: string);
begin
  FboundString := boundString;
  Foffset := 0;
end;

function TRegExp.captureLength: cardinal;
begin
  result := length(Fcapture);
end;

function TRegExp.boundmatch(regex: string): string;
var success: boolean;
begin
  compile(regex);
  success := do_match;
  if success = false then exit;
  result := Fmatched;
end;

function TRegExp.match: boolean;
begin
  if Global in Fflags then
    result := do_match_global
  else
    result := do_match;
end;

function TRegExp.match(boundString: string): boolean;
begin
  bind(boundString);
  result := match;
end;

class function TRegExp.match(regex: string; bound: string; Flags: RegExpFlags = []): string;
var 
  compiled: TRegExp;
begin
  compiled := TRegExp.create(regex, Flags);
  compiled.bind(bound);
  compiled.match;
  result := compiled.matched;
end;

function TRegExp.boundsubstitute(regex: string; replace: string): string;
begin

  result := substitute(regex, replace, FboundString, Fflags);
  FboundString := result;
end;

function TRegExp.substitute(replace: string): string;
begin
  if Global in Fflags then
    result := do_substitute_global(replace)
  else
    result := do_substitute(replace);
end;

function TRegExp.substitute(boundString: string; replace: string): string;
begin
  bind(boundString);
  result := substitute(replace);
end;

class function TRegExp.substitute(regex: string; bound: string; replace: string; Flags: RegExpFlags = []): string;
var 
  compiled: TRegExp;
begin
  compiled := TRegExp.create(regex, Flags);
  compiled.bind(bound);
  result := compiled.substitute(replace);
end;

destructor TRegExp.destroy;
begin
  setLength(Fcapture, 0);
  if assigned(Fpcre) then
    pcre_free(Fpcre);
end;

function generateFlags(flags: string): RegExpFlags;
var
  i: cardinal;
begin
  result := [];

  if length(flags) > 0 then
    for i := 0 to length(flags)-1 do
    begin
      case flags[i] of
        // IgnoreCase, MultiLine, SingleLine, Extended, Global
        'i': Include(result, IgnoreCase);
        'm': Include(result, MultiLine);
        's': Include(result, SingleLine);
        'x': Include(result, Extended);
        'g': Include(result, Global);
      end;
    end;

end;

end.
