//This is light version of SynWrite's ATxFProc.pas,
//to not use Classes/Forms.
unit ATxFProc;

interface

uses Windows, SysUtils;

function IsFileExist(const FileName: WideString): Boolean; overload;
function FReadString(const fn: string): string;

type
  TExecCode = (exOk, exCannotRun, exExcept);
type
  PInt64Rec = ^TInt64Rec;
  TInt64Rec = packed record
    Lo, Hi: DWORD;
  end;

function FExecProcess(const CmdLine, CurrentDir: Widestring; ShowCmd: integer; DoWait: boolean): TExecCode;
function FDelete(const FileName: WideString): Boolean;
function FGetFileSize(const FileName: WideString): Int64; overload;

implementation

function IsFileExist(const FileName: WideString; var IsDir: Boolean): Boolean; overload;
var
  h: THandle;
  fdW: TWin32FindDataW;
begin
  IsDir := False;
  begin
    h := FindFirstFileW(PWideChar(FileName), fdW);
    Result := h <> INVALID_HANDLE_VALUE;
    if Result then
    begin
      IsDir := (fdW.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) <> 0;
      Windows.FindClose(h);
    end;
  end
end;

function IsFileExist(const FileName: WideString): Boolean; overload;
var
  IsDir: Boolean;
begin
  Result := IsFileExist(FileName, IsDir) and (not IsDir);
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

function FDelete(const FileName: WideString): Boolean;
begin
  Result := DeleteFileW(PWideChar(FileName))
end;

function FGetFileSize(const FileName: WideString): Int64; overload;
var
  h: THandle;
  fdW: TWin32FindDataW;
  SizeRec: TInt64Rec absolute Result;
begin
  Result := -1;
  begin
    h := FindFirstFileW(PWideChar(FileName), fdW);
    if h <> INVALID_HANDLE_VALUE then
    begin
      SizeRec.Hi := fdW.nFileSizeHigh;
      SizeRec.Lo := fdW.nFileSizeLow;
      Windows.FindClose(h);
    end;
  end
end;

function FReadString(const fn: string): string;
var
  f: TextFile;
begin
  Result:= '';
  AssignFile(f, fn);
  {$I-}
  Reset(f);
  {$I+}
  if IOResult<>0 then Exit;
  Readln(f, Result);
  CloseFile(f);
end;


end.

