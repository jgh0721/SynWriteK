//------------------------------------
// FindIDPas plugin for SynWrite
// Author: A.Torgashin, uvviewsoft.com
// License: MPL 1.1
//------------------------------------
library FindIDPas;

uses
  Windows, SysUtils,
  ATSynPlugins,
  ATxFProc,
  ATxSProc;

var
  FActionProc: TSynAction = nil;

procedure SynInit(ADefaultIni: PWideChar; AActionProc: Pointer); stdcall;
begin
  @FActionProc:= AActionProc;
end;

procedure Msg(const S: Widestring; Beep: boolean = true);
begin
  if Beep then
    MessageBeep(mb_iconwarning);
  FActionProc(nil, cActionShowHint, PWChar('[Find ID] '+s), nil, nil, nil);
end;

procedure SParseOut(const Str: Widestring; var res_fn: Widestring; var res_ln, res_col: Integer);
const
  cRegex: Widestring = 'ID found: "(.+)" (\d+):(\d+)';
var
  S1, S2, S3, S4, S5, S6, S7, S8: TSynRegexStr;
  SRegex: TSynRegexArray;
begin
  SRegex[0]:= @S1;
  SRegex[1]:= @S2;
  SRegex[2]:= @S3;
  SRegex[3]:= @S4;
  SRegex[4]:= @S5;
  SRegex[5]:= @S6;
  SRegex[6]:= @S7;
  SRegex[7]:= @S8;

  res_fn:= '';
  res_ln:= -1;
  res_col:= -1;

  if FActionProc(nil, cActionParseRegex, PWChar(cRegex), PWChar(Str), @SRegex, nil)<>cSynOK then Exit;
  res_fn:= S1;
  res_ln:= StrToIntDef(S2, -1);
  res_col:= StrToIntDef(S3, -1);
end;

function SynAction(AHandle: Pointer;
    AName: PWideChar; A1, A2, A3, A4: Pointer): Integer; stdcall;
var
  act, s: Widestring;
  FFileName, FPaths: Widestring;
  FPosX, FPosY: Integer;
  ffindid, ftemp, fdir, fpar, fcmd: Widestring;
  res_fn: Widestring;
  res_ln, res_col: Integer;
  buf: array[0..2048-1] of WideChar;
  bufSize: Integer;
begin
  act:= WideString(AName);
  if act=cActionMenuCommand then
  begin
    MessageBoxW(0, PWChar(Widestring('Command: ')+ PWChar(A1)), 'Command', mb_taskmodal);
    Result:= cSynError;
  end
  else
  if act=cActionFindID then
  begin
    Result:= cSynError;

    //read filename
    FillChar(buf, SizeOf(buf), 0);
    if FActionProc(nil, cActionGetOpenedFileName, @buf, Pointer(cSynIdCurrentFile), nil, nil) <> cSynOK then
      begin Msg('Cannot read file name'); Exit end;
    FFileName:= buf;

    //read caret pos
    FActionProc(nil, cActionGetCaretPos, @FPosX, @FPosY, nil, nil);

    //read search paths
    FillChar(buf, SizeOf(buf), 0);
    bufSize:= SizeOf(buf);
    if FActionProc(nil, cActionGetText, Pointer(cSynIdSearchPaths), @buf, @bufSize, nil) <> cSynOK then
      begin Msg('Cannot read search paths'); Exit end;
    FPaths:= buf;

    //run FindID tool
    ffindid:= ExtractFilePath(GetModuleName(HInstance))+'FindID.exe';
    if not IsFileExist(ffindid) then
    begin
      Msg('FindID.exe not found');
      Exit
    end;

    ftemp:= SExpandVars('%Temp%\SynFindID.txt');
    fpar:= WideFormat('"%s" %d %d "/paths=%s"',
      [FFileName,
       FPosY + 1,
       FPosX + 1,
       FPaths]);
    fdir:= ExtractFileDir(FFileName);
    fcmd:= WideFormat('cmd.exe /c""%s" %s >"%s""', [ffindid, fpar, ftemp]);

    FDelete(ftemp);
    if FExecProcess(fcmd, fdir, sw_hide, true{Wait})=exCannotRun then
    begin
      Msg('Cannot run tool FindID.exe');
      Exit
    end;

    if (not IsFileExist(ftemp)) or (FGetFileSize(ftemp)=0) then
    begin
      Msg('Tool didn''t return output');
      Exit
    end;

    s:= FReadString(ftemp);
    FDelete(ftemp);
    if s='' then
    begin
      Msg('Cannot read tool output');
      Exit
    end;

    //parse
    SParseOut(s, res_fn, res_ln, res_col);
    if res_fn='' then
    begin
      Msg(s);
      Exit
    end;
    if not IsFileExist(res_fn) then
    begin
      Msg(WideFormat('Cannot find file "%s"', [res_fn]));
      Exit
    end;

    if FActionProc(nil, cActionOpenFile, PWChar(res_fn), nil, nil, nil)<>cSynOK then
      Exit;
    if FActionProc(nil, cActionSetCaretPos, Pointer(res_col-1), Pointer(res_ln-1), nil, nil)<>cSynOK then
      Exit;

    Msg('ID found: "'+ExtractFileName(res_fn)+'", '+ Inttostr(res_ln)+':'+Inttostr(res_col), false);
    Result:= cSynOK;

    //messageboxW(0, pwchar(A4), 'cc', 0);//// 
  end
  else
    Result:= cSynBadCmd;
end;

exports
  SynInit,
  SynAction;

end.
