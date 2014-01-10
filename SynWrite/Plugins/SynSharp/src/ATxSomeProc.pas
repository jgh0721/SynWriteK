unit ATxSomeProc;

interface

type
  TExecCode = (exOk, exCannotRun, exExcept);

function FExecAsAdmin(const Cmd, Params, Dir: string; ShowMode: Integer; AsAdmin: boolean): boolean;
function FGetFileSize(const FileName: WideString): Int64; overload;

function IsWordChar(C: Widechar): boolean;
function IsWordCharA(C: Ansichar): boolean;

function SExpandVars(const S: WideString): WideString;
function SReadIniKey(const section, key, default: string; const fnIni: string): string;
function SDeleteBegin(var s: string; const subs: string): boolean;
function SGetItem(var S: string; const sep: Char = ','): string;
procedure SReplaceAll(var S: string; const SFrom, STo: string);

function SParseOmniSharp(const Str: string): string;
procedure SParseOmniSharp_Findid(const Str: string; var fn: string; var line, col: Integer);

implementation

uses
  SysUtils,
  Windows,
  ShellApi,
  Classes,
  StrUtils;

function IsWordChar(C: Widechar): boolean;
begin
  Result:= Char(C) in ['a'..'z', 'A'..'Z', '0'..'9', '_'];
end;

function IsWordCharA(C: Ansichar): boolean;
begin
  Result:= Char(C) in ['a'..'z', 'A'..'Z', '0'..'9', '_'];
end;

function SExpandVars(const S: WideString): WideString;
const
  BufSize = 4 * 1024;
var
  BufferW: array[0 .. BufSize - 1] of WideChar;
begin
  FillChar(BufferW, SizeOf(BufferW), 0);
  ExpandEnvironmentStringsW(PWChar(S), BufferW, BufSize);
  Result := WideString(BufferW);
end;


function SReadIniKey(const section, key, default: string; const fnIni: string): string;
var
  buf: array[0..2*1024-1] of char;
begin
  Result:= '';
  if (section='') or (key='') then Exit;

  FillChar(buf, SizeOf(buf), 0);
  GetPrivateProfileString(PChar(section), PChar(key), PChar(default),
    buf, SizeOf(buf), PChar(fnIni));
  Result:= buf;
end;

type
  PInt64Rec = ^TInt64Rec;
  TInt64Rec = packed record
    Lo, Hi: DWORD;
  end;

function FGetFileSize(const FileName: WideString): Int64; overload;
var
  h: THandle;
  fdW: TWin32FindDataW;
  SizeRec: TInt64Rec absolute Result;
begin
  Result := -1;
  h := FindFirstFileW(PWideChar(FileName), fdW);
  if h <> INVALID_HANDLE_VALUE then
  begin
    SizeRec.Hi := fdW.nFileSizeHigh;
    SizeRec.Lo := fdW.nFileSizeLow;
    Windows.FindClose(h);
  end;
end;

function SDeleteBegin(var s: string; const subs: string): boolean;
begin
  Result:=
    (s<>'') and (subs<>'') and
    (Copy(s, 1, Length(subs))=subs);
  if Result then
    Delete(s, 1, Length(subs));
end;


function SGetItem(var S: string; const sep: Char = ','): string;
var
  i: integer;
begin
  i:= Pos(sep, s);
  if i = 0 then i:= MaxInt;
  Result:= Copy(s, 1, i-1);
  Delete(s, 1, i);
end;


(*
function SRegexReplace(var S: Widestring; const SRegex, SReplace: Widestring): boolean;
var
  R: TecRegExpr;
  n, nRes: integer;
begin
  Result:= false;
  R:= TecRegExpr.Create;
  try
    R.Expression:= SRegex;
    R.ModifierX:= false; //to handle ' ' in RE
    for n:= 1 to Length(S) do
    begin
      nRes:= n;
      if R.Match(S, nRes) then
      begin
        Delete(S, R.MatchPos[0], R.MatchLen[0]);
        Insert(SReplace, S, R.MatchPos[0]);
        Result:= true;
        Exit;
      end;
    end;
  finally
    R.Free;
  end;
end;
*)

procedure SReplaceAll(var S: string; const SFrom, STo: string);
var
  i: Integer;
begin
  repeat
    i := Pos(SFrom, S);
    if i = 0 then Break;
    Delete(S, i, Length(SFrom));
    Insert(STo, S, i);
  until False;
end;

function SParseJsonValue(const Str: string; const Id: string): string;
var
  n1, n2: Integer;
  sStart: string;
begin
  Result:= '';
  sStart:= '"'+Id+'":';

  n1:= PosEx(sStart, Str, 1);
  if n1=0 then Exit;
  n1:= n1+Length(sStart);
  n2:= PosEx(',', Str, n1+1);
  if n2=0 then
    n2:= PosEx('}', Str, n1+1);
  if n2=0 then Exit;

  Result:= Copy(Str, n1, n2-n1);
  Result:= AnsiDequotedStr(Result, '"');
  SReplaceAll(Result, '\\', '\');
end;

(*
{"FileName":"g:\\_OmniSharpServer\\server\\OmniSharp.Tests\\AutoComplete\\CompletionTestBase.cs","Line":8,"Column":9}
*)
procedure SParseOmniSharp_Findid(const Str: string; var fn: string; var line, col: Integer);
begin
  fn:= SParseJsonValue(Str, 'FileName');
  line:= StrToIntDef(SParseJsonValue(Str, 'Line'), 1);
  col:= StrToIntDef(SParseJsonValue(Str, 'Column'), 1);
end;

function SParseOmniSharp(const Str: string): string;
var
  L: TStringList;
  n1, n2: integer;
  SName, SType, SPar: string;
const
  sStart = '"CompletionText":';
begin
  Result:= '';
  L:= TStringList.Create;
  try
    n2:= 1;
    repeat
      n1:= PosEx(sStart, Str, n2);
      if n1=0 then Break;
      n1:= n1+Length(sStart)+1;
      n2:= PosEx('"', Str, n1);
      if n2=0 then Break;

      SName:= Copy(Str, n1, n2-n1);
      if Pos('(', SName)>0 then
        SType:= 'func'
      else
        SType:= 'id';
      SPar:= '';

      //move brackets from SName to SPar
      n1:= Pos('(', SName);
      if n1>0 then
      begin
        Delete(SName, n1, MaxInt);
        SPar:= '( )';
      end;

      L.Add(SName+'|'+SType+'|'+SPar);
    until false;
  finally
    Result:= L.Text;
    FreeAndNil(L);
  end;
end;

function FExecAsAdmin(const Cmd, Params, Dir: string; ShowMode: Integer; AsAdmin: boolean): boolean;
var
  Verb: string;
begin
  if AsAdmin then
  begin
    //Vista? then "runas"
    if Win32MajorVersion >= 6 then
      Verb:= 'runas'
    else
      Verb:= 'open';
  end
  else
    Verb:= 'open';
  Result:= ShellExecute(0, PChar(Verb), PChar(Cmd), PChar(Params), PChar(Dir), ShowMode) > 32;
end;


end.
