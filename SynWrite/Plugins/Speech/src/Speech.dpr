library Speech;

uses
  Windows,
  SpeechApi,
  Classes,
  IniFiles,
  ATSynPlugins,
  unOpt in 'unOpt.pas' {fmOpt};

var
  _ActionProc: TSynAction = nil;
  _DefaultIni: string = '';
  OpVoice: string;
  OpSpeed,
  OpPitch,
  OpVol: Integer;

const
  cCaption = 'Speech';
  cSec = 'Speech';

procedure LoadOpt;
begin
  with TIniFile.Create(_DefaultIni) do
  try
    OpVoice:= ReadString(cSec, 'Voice', '');
    OpSpeed:= ReadInteger(cSec, 'Speed', 10);
    OpPitch:= ReadInteger(cSec, 'Pitch', 0);
    OpVol:= ReadInteger(cSec, 'Vol', 80);
  finally
    Free
  end;
end;

procedure SaveOpt;
begin
  with TIniFile.Create(_DefaultIni) do
  try
    WriteString(cSec, 'Voice', OpVoice);
    WriteInteger(cSec, 'Speed', OpSpeed);
    WriteInteger(cSec, 'Pitch', OpPitch);
    WriteInteger(cSec, 'Vol', OpVol);
  finally
    Free
  end;
end;

procedure DoSay(const S: Widestring);
const
  cMinLen = 2;
  cMaxShow = 1500;
var
  L: TStrings;
begin
  if Length(S)<cMinLen then
  begin
    MessageBoxW(0, 'Text not selected', cCaption, mb_taskmodal or mb_ok or mb_iconwarning);
    Exit
  end;

  SpeechInit;
  L:= GetVoices;
  if (L=nil) or (L.Count=0) then Exit;
  if OpVoice='' then
    OpVoice:= L[0];
  SetVoice(OpVoice);

  SetSpeed(OpSpeed);
  SetPitch(OpPitch);
  SetVolume(OpVol);

  SpeechSpeak(S, false);
  //MessageBoxW(0, 'Playing', cCaption, mb_taskmodal or mb_ok {or mb_iconinformation});
  SpeechStop;
end;

function EdText: Widestring;
const
  cSize = 100*1024;
var
  buf: array[0..cSize-1] of WideChar;
  bufSize: Integer;
  res: Integer;
begin
  Result:= '';

  FillChar(buf, SizeOf(buf), 0);
  bufSize:= cSize;
  res:= _ActionProc(nil, cActionGetText, Pointer(cSynIdSelectedText), @buf, @bufSize, nil);
  if res=cSynOk then
    Result:= buf;
end;

function SynAction(AHandle: Pointer; AName: PWideChar; A1, A2, A3, A4: Pointer): Integer; stdcall;
var
  SCmd, SId: Widestring;
begin
  Result:= cSynBadCmd;
  SCmd:= PWideChar(AName);

  if SCmd=cActionMenuCommand then
  begin
    SId:= PWideChar(A1);

    if SId='say' then
    begin
      LoadOpt;
      DoSay(EdText);
    end;

    if SId='options' then
    begin
      LoadOpt;
      if DoOpt(OpVoice, OpSpeed, OpPitch, OpVol) then
        SaveOpt;
    end;

    Result:= cSynOK;
    Exit
  end;
end;

procedure SynInit(ADefaultIni: PWideChar; AActionProc: Pointer); stdcall;
begin
  _ActionProc:= AActionProc;
  _DefaultIni:= Widestring(PWChar(ADefaultIni));
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
