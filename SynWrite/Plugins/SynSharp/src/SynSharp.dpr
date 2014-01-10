{$I-}
library SynSharp;

uses
  Windows,
  SysUtils,
  Classes,
  IniFiles,
  ATSynPlugins,
  ATxSomeProc,
  ATxTcp;

var
  _ActionProc: TSynAction;
  opDataDir: string; //folder with server
  opDllName: string; //dll filename without extension
  opEnableHints: boolean = true; //enable "Parameter hints" feature
  opPortNum: integer = 2000; //server port number
  opHintDelay: integer = 2500; //delay (msec) after error message in editor statusbar
  opHideServer: boolean = false;
  opStartDelay: integer = 4000; //delay (msec) after server start
  opSolutionFN: string;

procedure Msg(const S: Widestring; APause: boolean = true);
begin
  _ActionProc(nil, cActionShowHint, PWChar('['+opDllName+'] '+S), nil, nil, nil);
  if APause then
    Sleep(opHintDelay);
end;

procedure SynInit(ADefaultIni: PWideChar; AActionProc: Pointer); stdcall;
var
  fn, AExeDir, AIniFN: string;
begin
  _ActionProc:= AActionProc;
  //_DefaultIni:= Widestring(PWChar(ADefaultIni));

  fn:= GetModuleName(HInstance);
  opDllName:= ChangeFileExt(ExtractFileName(fn), '');
  AExeDir:= ExtractFileDir(fn);
  AIniFN:= ChangeFileExt(fn, '.ini');

  opDataDir:= SReadIniKey('ini', 'datadir', AExeDir, AIniFN);
  opEnableHints:= SReadIniKey('ini', 'hints', '1', AIniFN) = '1';
  opHideServer:= SReadIniKey('ini', 'server_hide', '0', AIniFN) = '1';
  opPortNum:= StrToInt(SReadIniKey('ini', 'server_port', IntToStr(opPortNum), AIniFN));
end;


function GetEditorProps(
  var fn_editor: string;
  var file_text: string;
  var caret_line, caret_col: integer;
  var AMsg: string): boolean;
const
  cMaxLen = 260;
var
  bufName: array[0..cMaxLen] of WideChar;
  bufText: Pointer;
  NLine, NCol, NOffset, NSize, NSizeBuf: Integer;
begin
  Result:= false;
  fn_editor:= '';
  file_text:= '';
  caret_line:= 1;
  caret_col:= 1;
  AMsg:= '';

  //get filename
  FillChar(bufName, SizeOf(bufName), 0);
  if _ActionProc(nil, cActionGetOpenedFileName, PWChar(@bufName), Pointer(cSynIdCurrentFile), nil, nil)<>cSynOK then Exit;
  fn_editor:= bufName;
  if fn_editor='' then
  begin
    AMsg:= 'Cannot handle unnamed file tab';
    Exit
  end;

  //get caret pos
  if _ActionProc(nil, cActionGetCaretPos, Pointer(@NCol), Pointer(@NLine), Pointer(@NOffset), nil)<>cSynOK then
  begin
    AMsg:= 'Cannot get caret pos';
    Exit;
  end;
  caret_line:= NLine+1;
  caret_col:= NCol+1;

  //get text
  {
  //old method, line by line
  for i:= 0 to MaxInt div 2 do
  begin
    NSize:= cMaxLen;
    if _ActionProc(nil, cActionGetText, Pointer(i), Pointer(@buf), Pointer(@NSize), nil)<>cSynOK then Break;
    file_text:= file_text + WideString(buf) + #13#10;
  end;
  }

  NSize:= 1; //1 char initially
  NSizeBuf:= (NSize+1)*2;
  GetMem(bufText, NSizeBuf);
  try
    if _ActionProc(nil, cActionGetText, Pointer(cSynIdAllText), bufText, Pointer(@NSize), nil)<>cSynSmallBuffer then
    begin
      AMsg:= 'Cannot get text (unexpected GetText result)';
      Exit;
    end;
  finally
    FreeMem(bufText);
    bufText:= nil;
  end;

  NSizeBuf:= (NSize+1)*2;
  GetMem(bufText, NSizeBuf);
  try
    FillChar(bufText^, NSizeBuf, 0);
    if _ActionProc(nil, cActionGetText, Pointer(cSynIdAllText), bufText, Pointer(@NSize), nil)<>cSynOK then
    begin
      AMsg:= 'Cannot get text (small buffer)';
      Exit;
    end;
    file_text:= WideString(PWideChar(bufText));
    //ShowMessage(file_text);//
  finally
    FreeMem(bufText);
    bufText:= nil;
  end;

  Result:= true;
end;

function DoServerClose: boolean;
begin
  Result:= true;
  try
    /////UrlRequest('/stopserver', '', opPortNum);
  except
    Result:= false;
  end;
end;

function IsServerRun: boolean;
begin
  Result:= true;
  try
    UrlRequest('/', '', opPortNum);
  except
    Result:= false;
  end;
end;

function SIniFN: string;
begin
  Result:= opDataDir + '\history.ini';
end;

function GetProjectSolution: string;
const
  bufLen = 4*1024;
var
  buf: array[0..bufLen] of WideChar;
  size: integer;
  s, s1: string;
begin
  Result:= '';
  FillChar(buf, SizeOf(buf), 0);
  size:= bufLen;
  if _ActionProc(nil, cActionGetText, Pointer(cSynIdSearchPaths), Pointer(@buf), Pointer(@size), nil)=cSynOK then
  begin
    //get 1st item from ";" separated list, which ends with ".sln"
    s:= buf;
    repeat
      s1:= SGetItem(s, ';');
      if s1='' then Break;
      if ExtractFileExt(s1)='.sln' then
        begin Result:= s1; Exit end;
    until false;
  end;
end;

function GetLastSolution: string;
begin
  with TIniFile.Create(SIniFN) do
  try
    Result:= ReadString('ini', 'sol', '');
  finally
    Free
  end;
end;

procedure SetLastSolution(const fn: string);
begin
  with TIniFile.Create(SIniFN) do
  try
    WriteString('ini', 'sol', fn);
  finally
    Free
  end;
end;


function DoServerRun: boolean;
const
  cShowMode: array[boolean] of Integer = (SW_MINIMIZE, SW_HIDE);
var
  sServerDir, sCmd, sParams: string;
begin
  sServerDir:= opDataDir + '\server';
  with TIniFile.Create(sServerDir + '\server.ini') do
  try
    sCmd:= ReadString('ini', 'cmd', '');
    sParams:= ReadString('ini', 'params', '');
  finally
    Free
  end;

  if sCmd='' then
  begin
    Msg('Cannot read params from server.ini');
    Result:= false;
    Exit
  end;

  SReplaceAll(sCmd, '{dir}', sServerDir);
  SReplaceAll(sParams, '{dir}', sServerDir);
  SReplaceAll(sParams, '{sln}', opSolutionFN);
  SReplaceAll(sParams, '{port}', IntToStr(opPortNum));
  //ShowMessage(sCmd+#13+sParams);////

  Result:= FExecAsAdmin(sCmd, sParams, sServerDir, cShowMode[opHideServer], true);
  if Result then
    Sleep(opStartDelay);
end;

function SynAction(AHandle: Pointer; AName: PWideChar; A1, A2, A3, A4: Pointer): Integer; stdcall;
var
  fn_editor: string;
  file_text: string;
  num_line, num_col: integer;
  //
  function DoRequest(const cmd: string): string;
  begin
    try
      Result:= HttpRequest(
          Format('/' + cmd + '?buffer=%s&filename=%s&line=%d&column=%d',
            [UrlEncode(file_text), UrlEncode(fn_editor), num_line, num_col]),
          opPortNum);
    except
      Result:= '';
    end;
  end;
  //
var
  SAction: Widestring;
  AResultText: Widestring;
  S, AErrorMsg: string;
  res_fn: string;
  res_line, res_col: integer;
  i: integer;
begin
  Result:= cSynError;
  SAction:= PWideChar(AName);

  opSolutionFN:= GetProjectSolution;
  if opSolutionFN='' then
  begin
    Msg('Solution-file not set');
    Result:= cSynError;
    Exit
  end;
  if not FileExists(opSolutionFN) then
  begin
    Msg('Solution-file not found: '+opSolutionFN);
    Result:= cSynError;
    Exit
  end;

  if not IsServerRun then
  begin
    SetLastSolution(opSolutionFN);
    if not DoServerRun then
    begin
      Msg('Cannot run server');
      Result:= cSynError;
      Exit
    end;
    //wait for server reply
    for i:= 1 to 10 do
    begin
      Sleep(1000);
      if IsServerRun then Break;
    end;
  end
  else
  begin
    if opSolutionFN<>GetLastSolution then
    begin
      Msg('Please close server window - it''s opened for another solution');
      Sleep(2000);
      Result:= cSynError;
      Exit
    end;
  end;

  //auto-completion
  if (SAction=cActionGetAutoComplete) then
  begin
    if not GetEditorProps(fn_editor, file_text, num_line, num_col, AErrorMsg) then
    begin
      if AErrorMsg<>'' then
        Msg(AErrorMsg)
      else
        Msg('Cannot get editor properties');
      Exit
    end;

    s:= DoRequest('autocomplete');
    if s='' then
    begin
      Msg('Cannot connect to server');
      Result:= cSynError;
      Exit;
    end;

    AResultText:= SParseOmniSharp(S);
    lstrcpynw(A1, PWChar(AResultText), Integer(A2));
    Result:= cSynOK;
    Exit
  end;

  //------------------------------
  if SAction=cActionFindID then
  begin
    if not GetEditorProps(fn_editor, file_text, num_line, num_col, AErrorMsg) then
    begin
      if AErrorMsg<>'' then
        Msg(AErrorMsg)
      else
        Msg('Cannot get editor properties');
      Exit
    end;

    s:= DoRequest('gotodefinition');
    if s='' then
    begin
      Msg('Cannot connect to server');
      Result:= cSynError;
      Exit;
    end;

    SParseOmniSharp_Findid(s, res_fn, res_line, res_col);
    if (res_fn='') or (res_fn='null') then
    begin
      Msg('Cannot find id');
      Result:= cSynError;
      Exit;
    end;

    {
    //we can get result in our temp file-> redirect to editor file
    if UpperCase(res_fn) = UpperCase(fn_editor) then
      res_fn:= fn_editor;
      }

    //we found filename, open the editor now
    if (res_fn='') or not FileExists(res_fn) then
    begin
      Msg('Cannot find file: '+res_fn);
      Exit
    end;

    if _ActionProc(nil, cActionOpenFile, PWChar(Widestring(res_fn)), nil, nil, nil)<>cSynOK then
    begin
      Msg('Cannot open file: '+res_fn);
      Exit
    end;

    if _ActionProc(nil, cActionSetCaretPos, Pointer(res_col-1), Pointer(res_line-1), nil, nil)<>cSynOK then
    begin
      Msg('Cannot position caret');
      Exit
    end;

    Msg(Format('Found: %s : %d', [ExtractFileName(res_fn), res_line]), false);
    Result:= cSynOK;
    Exit
  end;

  Result:= cSynBadCmd;
end;

exports
  SynAction,
  SynInit;

//following is to check types
var
  _Action: TSynAction;
  _Init: TSynInit;
begin
  _Action:= SynAction;
  _Init:= SynInit;
  if @_Action<>nil then begin end;
  if @_Init<>nil then begin end;

end.
