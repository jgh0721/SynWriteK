{$I-}
library SynJediFind;

uses
  Windows,
  SysUtils,
  ATSynPlugins,
  ATxSomeProc;

var
  _ActionProc: TSynAction = nil;
  _DataDir: string;

procedure SynInit(ADefaultIni: PWideChar; AActionProc: Pointer); stdcall;
begin
  @_ActionProc:= AActionProc;
  _DataDir:= ExtractFileDir(GetModuleName(HInstance));
  _DataDir:= SReadIniKey('ini', 'datadir', _DataDir, _DataDir+'\SynJedi.ini');
end;

procedure Msg(const S: Widestring; Beep: boolean = true);
begin
  if Beep then
    MessageBeep(mb_iconwarning);
  _ActionProc(nil, cActionShowHint, PWChar('[SynJedi] '+s), nil, nil, nil);
end;


function DoGetFileProp(var fn_editor, fn_src: string; var AMsg: string): boolean;
const
  cMaxLineSize = 512;
var
  buf: array[0..Pred(cMaxLineSize)] of Widechar;
  Str: Widestring;
  NLine, NCol, NOffset, NSize, i: Integer;
  F: TextFile;
begin
  Result:= false;
  fn_editor:= '';
  fn_src:= '';
  AMsg:= '';
  Str:= '';

  //get filename
  FillChar(buf, SizeOf(buf), 0);
  if _ActionProc(nil, cActionGetOpenedFileName, PWChar(@buf), Pointer(cSynIdCurrentFile), nil, nil)<>cSynOK then Exit;
  fn_editor:= buf;
  if fn_editor='' then
  begin
    AMsg:= 'Cannot handle unnamed file tab';
    Exit
  end;

  fn_src:= ChangeFileExt(fn_editor, '_tempSynJedi' + ExtractFileExt(fn_editor));
  AssignFile(F, fn_src);
  try
    Rewrite(F);
    if IOResult<>0 then
    begin
      AMsg:= 'Cannot create temp file (in source code folder)';
      Exit
    end;

    //get caret pos
    if _ActionProc(nil, cActionGetCaretPos, Pointer(@NCol), Pointer(@NLine), Pointer(@NOffset), nil)<>cSynOK then
    begin
      AMsg:= 'Cannot get caret pos';
      Exit;
    end;  

    //get all lines up to current line
    for i:= 0 to NLine do
    begin
      NSize:= SizeOf(buf) div 2;
      if _ActionProc(nil, cActionGetText, Pointer(i), Pointer(@buf), Pointer(@NSize), nil)<>cSynOK then Break;
      Str:= buf;
      Writeln(F, Str);
    end;

    Result:= true;
  finally
    CloseFile(F);
  end;
end;


function SynAction(AHandle: Pointer;
    AName: PWideChar; A1, A2, A3, A4: Pointer): Integer; stdcall;
const
  cBufSize = 2*1024;
var
  ff: TextFile;
  act, s: string;
  fn_editor, fn_src, fn_findpy, fn_pythonexe, fn_dir, fn_out, s_cmd: string;
  caret_X, caret_Y: Integer;
  res_fn: Widestring;
  res_ln, res_col: Integer;
  buf: array[0..cBufSize-1] of WideChar;
  bufSize: Integer;
begin
  act:= WideString(AName);
  {
  if act=cActionMenuCommand then
  begin
    MessageBoxW(0, PWChar(Widestring('Command: ')+ PWChar(A1)), 'Command', mb_taskmodal);
    Result:= cSynError;
  end
  else
  }
  if act<>cActionFindID then
  begin
    Result:= cSynBadCmd;
    Exit
  end;

  try
    Result:= cSynError;

    //read filename
    if not DoGetFileProp(fn_editor, fn_src, s) then
    begin
      if s='' then
        s:= 'Cannot read file props';
      Msg(s);
      Exit
    end;

    //read caret pos
    if _ActionProc(nil, cActionGetCaretPos, @caret_X, @caret_Y, nil, nil)<>cSynOK then
    begin
      Msg('Cannot read caret pos');
      Exit
    end;

    //read search paths
    FillChar(buf, SizeOf(buf), 0);
    bufSize:= SizeOf(buf);
    if _ActionProc(nil, cActionGetText, Pointer(cSynIdSearchPaths), @buf, @bufSize, nil) <> cSynOK then
    begin
      Msg('Cannot read search paths');
      Exit
    end;

    //run
    fn_pythonexe:= _DataDir+'\python\python.exe';
    fn_findpy:= _DataDir+'\find.py';
    if not FileExists(fn_pythonexe) then
    begin
      Msg('File not found: python.exe');
      Exit
    end;
    if not FileExists(fn_findpy) then
    begin
      Msg('File not found: find.py');
      Exit
    end;

    fn_out:= SExpandVars('%Temp%\SynJediFind.txt');
    fn_dir:= ExtractFileDir(fn_src);
    s_cmd:= Format('cmd.exe /c""%s" "%s" "%s" %d %d >"%s""', [
      fn_pythonexe,
      fn_findpy,
      fn_src,
      caret_Y + 1,
      caret_X + 1,
      fn_out
      ]);

    DeleteFile(fn_out);
    if FileExists(fn_out) then
    begin
      Msg('Cannot delete temp file');
      Exit
    end;

    Msg('Processing...', false);
    if FExecProcess(s_cmd, fn_dir, sw_hide, true{Wait})=exCannotRun then
    begin
      Msg('Cannot run script');
      Exit
    end;

    if (not FileExists(fn_out)) or (FGetFileSize(fn_out)=0) then
    begin
      Msg('Script didn''t return output');
      Exit
    end;
  finally
    if fn_src<>'' then
      DeleteFile(fn_src);
  end;

    AssignFile(ff, fn_out);
    try
      Reset(ff);
      if IOResult<>0 then
      begin
        Msg('Cannot read script output');
        Exit
      end;

      Readln(ff, s);
      if s='[Msg]' then
      begin
        Readln(ff, s);
        Msg(s);
        Exit
      end;
      if s<>'[Findid]' then
      begin
        Msg('Unexpected script output: '+s);
        Exit
      end;

      Readln(ff, s);
      if Pos('File=', s)<>1 then
      begin
        Msg('Unexpected script output: '+s);
        Exit
      end;
      res_fn:= Copy(s, Pos('=', s)+1, MaxInt);

      //we can get result in our temp file-> redirect to editor file
      if UpperCase(res_fn)=UpperCase(fn_src) then
        res_fn:= fn_editor;

      Readln(ff, s);
      if Pos('Line=', s)<>1 then
      begin
        Msg('Unexpected script output: '+s);
        Exit
      end;
      res_ln:= StrToIntDef(Copy(s, Pos('=', s)+1, MaxInt), -1); //line is 1-based
      if res_ln<=0 then
      begin
        Msg('Unexpected line number: '+Inttostr(res_ln));
        Exit
      end;

      Readln(ff, s);
      if Pos('Col=', s)<>1 then
      begin
        Msg('Unexpected script output: '+s);
        Exit
      end;
      res_col:= StrToIntDef(Copy(s, Pos('=', s)+1, MaxInt), -1) + 1; //column is 0-based
      if res_col<=0 then
      begin
        Msg('Unexpected column number: '+Inttostr(res_col));
        Exit
      end;
    finally
      CloseFile(ff);
      DeleteFile(fn_out);
    end;

    //we found filename, line:col,
    //open the editor now
    if (res_fn='') or not FileExists(res_fn) then
    begin
      Msg('Cannot find file: '+res_fn);
      Exit
    end;

    if _ActionProc(nil, cActionOpenFile, PWChar(res_fn), nil, nil, nil)<>cSynOK then
    begin
      Msg('Cannot open file: '+res_fn);
      Exit
    end;

    if _ActionProc(nil, cActionSetCaretPos, Pointer(res_col-1), Pointer(res_ln-1), nil, nil)<>cSynOK then
    begin
      Msg('Cannot position caret');
      Exit
    end;

    Msg(Format('Found: %s : %d', [ExtractFileName(res_fn), res_ln]), false);
    Result:= cSynOK;
end;

exports
  SynInit,
  SynAction;

end.
