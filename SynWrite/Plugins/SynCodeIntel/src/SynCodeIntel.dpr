{$I-}
library SynCodeIntel;

uses
  Windows,
  SysUtils,
  StrUtils,
  ATxSomeProc,
  ATSynPlugins;

var
  _ActionProc: TSynAction;
  _DataDir: string; //folder with "libs", "arch", "python"
  _BaseName: string; //filename without extension
  _EnableHints: boolean = true; //enable "Parameter hints" feature

procedure Msg(const S: Widestring);
begin
  _ActionProc(nil, cActionShowHint, PWChar('['+_BaseName+'] '+S), nil, nil, nil);
  Sleep(1800);
end;

procedure SynInit(ADefaultIni: PWideChar; AActionProc: Pointer); stdcall;
var
  fn, AExeDir, AIniFN: string;
begin
  _ActionProc:= AActionProc;
  //_DefaultIni:= Widestring(PWChar(ADefaultIni));

  fn:= GetModuleName(HInstance);
  _BaseName:= ChangeFileExt(ExtractFileName(fn), '');
  AExeDir:= ExtractFileDir(fn);
  AIniFN:= ChangeFileExt(fn, '.ini');

  _DataDir:= SReadIniKey('ini', 'datadir', AExeDir, AIniFN);
  _EnableHints:= SReadIniKey('ini', 'hints', '1', AIniFN) = '1';
end;

function SGetFileProp(var fn_editor, fn_src: string; var AMsg: string): boolean;
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

  fn_src:= ChangeFileExt(fn_editor, '_tempSynCI' + ExtractFileExt(fn_editor));
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

    //get all lines before current line
    for i:= 0 to NLine-1 do
    begin
      NSize:= SizeOf(buf) div 2;
      if _ActionProc(nil, cActionGetText, Pointer(i), Pointer(@buf), Pointer(@NSize), nil)<>cSynOK then Break;
      Str:= buf;
      Writeln(F, Str);
    end;

    //get current line (truncated by caret pos)
    NSize:= SizeOf(buf) div 2;
    if _ActionProc(nil, cActionGetText, Pointer(NLine), Pointer(@buf), Pointer(@NSize), nil)<>cSynOK then
    begin
      AMsg:= 'Cannot get editor text';
      Exit
    end;  
    Str:= buf;

    //cut line after caret
    Delete(Str, NCol+1, MaxInt);

    //cut last id from line (it confuses CodeIntel)
    i:= Length(Str);
    while (i>0) and IsWordChar(Str[i]) do Dec(i);
    Delete(Str, i+1, MaxInt);

    Write(F, Str); //not Writeln
    Result:= true;
  finally
    CloseFile(F);
  end;
end;


function SynAction(AHandle: Pointer; AName: PWideChar; A1, A2, A3, A4: Pointer): Integer; stdcall;
var
  SAction: Widestring;
  AResultText: Widestring;
  S: string;
  fn_editor, fn_src, fn_out, fn_pythonexe, fn_runpy: string;
  AErrorMsg: string;
  F: TextFile;
  N: Integer;
  AHintMode: boolean;
begin
  Result:= cSynError;
  SAction:= PWideChar(AName);

  //auto-completion
  if (SAction=cActionGetAutoComplete) or
    (_EnableHints and (SAction=cActionGetFunctionHint)) then
  begin
    AHintMode:= (SAction=cActionGetFunctionHint);

    if not SGetFileProp(fn_editor, fn_src, AErrorMsg) then
    begin
      if AErrorMsg<>'' then
        Msg(AErrorMsg)
      else
        Msg('Cannot get editor properties');
      Exit
    end;

    N:= 0;
    repeat
      fn_out:= Format(SExpandVars('%temp%\SynCodeIntel_%d.txt'), [N]);
      DeleteFile(fn_out);
      Inc(N);
    until not FileExists(fn_out);

    fn_pythonexe:= _DataDir+'\python\python.exe';
    fn_runpy:= _DataDir+'\run.py';
    if not FileExists(fn_pythonexe) then
    begin
      Msg('File not found: python.exe');
      Exit
    end;
    if not FileExists(fn_runpy) then
    begin
      Msg('File not found: run.py');
      Exit
    end;

    FExecProcess(
      Format('cmd.exe /c""%s" "%s" "%s" "%s" >"%s""', [
        fn_pythonexe,
        fn_runpy,
        fn_src,
        IfThen(AHintMode, 'hint', ''),
        fn_out
        ]),
      ExtractFileDir(fn_src),
      sw_hide,
      true{Wait});

    DeleteFile(fn_src);
    if not FileExists(fn_out) then
    begin
      Msg('Script didn''t return output');
      Exit;
    end;

    AssignFile(F, fn_out);
    try
      Reset(F);
      if IOResult<>0 then
      begin
        Msg('Cannot open script output file');
        Exit;
      end;

      Readln(F, S); //[Msg] or [Res]
      if S='[Msg]' then
      begin
        Readln(F, S);
        Msg(S);
        Exit
      end;
      if S<>'[Res]' then
      begin
        Msg('Unexpected script output: '+S);
        Exit
      end;
      //get resulting text, #13-separated string list for both actions
      while not Eof(F) do
      begin
        Readln(F, S);
        AResultText:= AResultText + S + #13;
      end;
    finally
      CloseFile(F);
      DeleteFile(fn_out);
    end;

    lstrcpynw(A1, PWChar(AResultText), Integer(A2));
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
