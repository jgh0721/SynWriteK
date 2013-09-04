unit ATxSomeProc;

interface

type
  TExecCode = (exOk, exCannotRun, exExcept);

function FExecProcess(const CmdLine, CurrentDir: Widestring; ShowCmd: integer; DoWait: boolean): TExecCode;
function FGetFileSize(const FileName: WideString): Int64; overload;

function IsWordChar(C: Widechar): boolean;
function SExpandVars(const S: WideString): WideString;
function SReadIniKey(const section, key, default: string; const fnIni: string): string;

implementation

uses
  SysUtils, Windows;

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


function FExecProcess(const CmdLine, CurrentDir: Widestring; ShowCmd: integer; DoWait: boolean): TExecCode;
var
  pi: TProcessInformation;
  si: TStartupInfo;
  code: DWord;
begin
  FillChar(pi, SizeOf(pi), 0);
  FillChar(si, SizeOf(si), 0);
  si.cb:= SizeOf(si);
  si.dwFlags:= STARTF_USESHOWWINDOW;
  si.wShowWindow:= ShowCmd;

  if not CreateProcessW(nil, PWChar(CmdLine), nil, nil, false, 0,
    nil, PWChar(CurrentDir), si, pi) then
    Result:= exCannotRun
  else
    begin
    if DoWait then WaitForSingleObject(pi.hProcess, INFINITE);
    if GetExitCodeProcess(pi.hProcess, code) and
      (code >= $C0000000) and (code <= $C000010E) then
      Result:= exExcept
    else
      Result:= exOk;
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    end;
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


end.
