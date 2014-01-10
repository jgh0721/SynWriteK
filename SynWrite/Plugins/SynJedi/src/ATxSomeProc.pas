unit ATxSomeProc;

interface

function FExecAsAdmin(const Cmd, Params, Dir: string; ShowMode: Integer; AsAdmin: boolean): boolean;
function FGetFileSize(const FileName: WideString): Int64; overload;
procedure FWriteString(const fn, str: string);

function IsWordChar(C: Widechar): boolean;
function SExpandVars(const S: WideString): WideString;
function SReadIniKey(const section, key, default: string; const fnIni: string): string;
function SDeleteBegin(var s: string; const subs: string): boolean;
function SGetItem(var S: string; const sep: Char = ','): string;
procedure SReplaceAll(var S: string; const SFrom, STo: string);

implementation

uses
  SysUtils,
  Windows,
  Classes,
  ShellApi;

function IsWordChar(C: Widechar): boolean;
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


procedure FWriteString(const fn, str: string);
var
  L: TStringList;
begin
  L:= TStringList.Create;
  try
    L.Add(str);
    L.SaveToFile(fn);
  finally
    FreeAndNil(L)
  end;
end;

end.
