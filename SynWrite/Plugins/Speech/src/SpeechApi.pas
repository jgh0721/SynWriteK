{$J+}
// Original code from https://sourceforge.net/projects/sapidll/
// Modified by Alexey (SynWrite)

unit SpeechApi;

interface

uses Windows, SysUtils, Classes, SpeechMulti, ActiveX;

type
  TSpeechEvent = procedure;
  TPositionEvent = procedure(Position: dword);
  TEngineEvent = procedure(Number: integer; const Name: string);
  TErrorEvent = procedure(const Text: string);

  TSpeechEvents = class(TComponent)
    procedure DoStart(Sender: TObject);
    procedure DoPause(Sender: TObject);
    procedure DoResume(Sender: TObject);
    procedure DoStop(Sender: TObject);
    procedure DoUserStart(Sender: TObject);
    procedure DoUserStop(Sender: TObject);
    procedure DoPosition(Sender: TObject; Position: dword);
    procedure DoSpeed(Sender: TObject; Position: dword);
    procedure DoVolume(Sender: TObject; Position: dword);
    procedure DoPitch(Sender: TObject; Position: dword);
    procedure DoSelectEngine(Sender: TObject; Number: integer; const Name: string);
    procedure DoStatusChange(Sender: TObject);
    procedure DoError(Sender: TObject; const Text: Widestring);
  end;


// Speech functions
function SpeechInit: HResult; stdcall;
procedure SpeechDone; stdcall;
procedure SpeechSpeak(const Text: Widestring; Async: boolean); stdcall;
procedure SetVoice(const Name: string); stdcall;
procedure GetEngineInfo(const EngineName: string; var Info: TEngineInfo); stdcall;
function GetVoices: TStrings; stdcall;
function GetPitch: Word; stdcall;
function GetSpeed: dword; stdcall;
function GetVolume: dword; stdcall;
procedure SetPitch(const Value: Word); stdcall;
procedure SetSpeed(const Value: dword); stdcall;
procedure SetVolume(const Value: dword); stdcall;

{
function GetEnginesCount: word; stdcall;
function GetMaxPitch: Word; stdcall;
function GetMaxSpeed: dword; stdcall;
function GetMaxVolume: dword; stdcall;
function GetMinPitch: Word; stdcall;
function GetMinSpeed: dword; stdcall;
function GetMinVolume: dword; stdcall;
}
procedure SpeechPause; stdcall;
procedure SpeechResume; stdcall;
procedure SpeechStop; stdcall;

{
// For non Delphi languages
procedure PSpeak(Text: LPCTSTR); stdcall;
procedure PSelectEngine(EngineName: LPCTSTR); stdcall;
procedure PSelectEngineNumber(EngineNumber: word); stdcall;
function PGetEngines(number: word): LPCTSTR; stdcall;
}

// version 2.0 events
procedure RegistOnStart(CallbackAddr: TSpeechEvent);
procedure RegistOnPause(CallbackAddr: TSpeechEvent);
procedure RegistOnResume(CallbackAddr: TSpeechEvent);
procedure RegistOnStop(CallbackAddr: TSpeechEvent);
procedure RegistOnUserStart(CallbackAddr: TSpeechEvent);
procedure RegistOnUserStop(CallbackAddr: TSpeechEvent);
procedure RegistOnPosition(CallbackAddr: TPositionEvent);
procedure RegistOnSpeed(CallbackAddr: TPositionEvent);
procedure RegistOnVolume(CallbackAddr: TPositionEvent);
procedure RegistOnPitch(CallbackAddr: TPositionEvent);
procedure RegistOnSelectEngine(CallbackAddr: TEngineEvent);
procedure RegistOnStatusChange(CallbackAddr: TSpeechEvent);
procedure RegistOnError(CallbackAddr: TErrorEvent);

var
  Speech: TMultiSpeech = nil;
  SpeechCallbackEvents: TSpeechEvents = nil;
  
implementation

const
  _pause: boolean = false;
var
  OnStartAddr: TSpeechEvent;
  OnPauseAddr: TSpeechEvent;
  OnResumeAddr: TSpeechEvent;
  OnStopAddr: TSpeechEvent;
  OnUserStartAddr: TSpeechEvent;
  OnUserStopAddr: TSpeechEvent;
  OnPositionAddr: TPositionEvent;
  OnSpeedAddr: TPositionEvent;
  OnVolumeAddr: TPositionEvent;
  OnPitchAddr: TPositionEvent;
  OnSelectEngineAddr: TEngineEvent;
  OnStatusChangeAddr: TSpeechEvent;
  OnErrorAddr: TErrorEvent;


function SpeechInit: HResult;
begin
  if not Assigned(Speech) then
  begin
    CoInitialize(nil);
    Result := 1;
    Speech := TMultiSpeech.Create(nil);
    if Speech <> nil then SpeechInit := 0;
    SpeechCallbackEvents := TSpeechEvents.Create(nil);
    Speech.OnStart := SpeechCallbackEvents.DoStart;
    Speech.OnPause := SpeechCallbackEvents.DoPause;
    Speech.OnResume := SpeechCallbackEvents.DoResume;
    Speech.OnStop := SpeechCallbackEvents.DoStop;
    Speech.OnUserStart := SpeechCallbackEvents.DoUserStart;
    Speech.OnUserStop := SpeechCallbackEvents.DoUserStop;
    Speech.OnPosition := SpeechCallbackEvents.DoPosition;
    Speech.OnSpeed := SpeechCallbackEvents.DoSpeed;
    Speech.OnVolume := SpeechCallbackEvents.DoVolume;
    Speech.OnPitch := SpeechCallbackEvents.DoPitch;
    Speech.OnSelectEngine := SpeechCallbackEvents.DoSelectEngine;
    Speech.OnStatusChange := SpeechCallbackEvents.DoStatusChange;
    Speech.OnError := SpeechCallbackEvents.DoError;
  end
  else
    Result := 0;
end;

procedure SpeechDone;
begin
  if Speech = nil then Exit;
  FreeAndNil(Speech);
end;


procedure SpeechSpeak(const Text: Widestring; Async: boolean);
begin
  if Speech = nil then Exit;
  Speech.Speak(Text, Async);
end;

procedure SetVoice(const Name: string);
begin
  if Speech = nil then Exit;
  Speech.SetVoice(Name);
end;

function GetVoices: TStrings;
begin
  if Speech = nil then
    Result:= nil
  else
    Result:= Speech.FVoices;
end;

procedure GetEngineInfo(const EngineName: string; var Info: TEngineInfo); stdcall;
begin
  Info.Name:= '';
  Info.Gender:= '';
  Info.Language:= '';

  if Speech <> nil then
    Info := Speech.EngineInfo;
end;

function GetPitch: Word; stdcall;
begin
  if Speech = nil then
    Result:= 0
  else
    Result := Speech.Pitch;
end;

function GetSpeed: dword; stdcall;
begin
  if Speech = nil then
    Result:= 0
  else
    Result := Speech.Speed;
end;

function GetVolume: dword; stdcall;
begin
  if Speech = nil then
    Result:= 0
  else
    Result := Speech.Volume;
end;

procedure SetPitch(const Value: Word); stdcall;
begin
  if Speech = nil then Exit;
  Speech.Pitch := Value;
end;

procedure SetSpeed(const Value: dword); stdcall;
begin
  if Speech = nil then Exit;
  Speech.Speed := Value;
end;

procedure SetVolume(const Value: dword); stdcall;
begin
  if Speech = nil then Exit;
  Speech.Volume := Value;
end;

function GetMaxPitch: Word; stdcall;
begin
  Result := MaxPitch;
end;

function GetMaxSpeed: dword; stdcall;
begin
  Result := MaxSpeed;
end;

function GetMaxVolume: dword; stdcall;
begin
  Result := MaxVolume;
end;

function GetMinPitch: Word; stdcall;
begin
  Result := MinPitch;
end;

function GetMinSpeed: dword; stdcall;
begin
  Result := MinSpeed;
end;

function GetMinVolume: dword; stdcall;
begin
  Result := MinVolume;
end;


procedure SpeechPause;
begin
  if Speech = nil then Exit;
  _Pause := true;
  Speech.Pause;
end;

procedure SpeechResume;
begin
  if Speech = nil then Exit;
  _Pause := false;
  Speech.Resume;
end;

procedure SpeechStop;
begin
  if Speech = nil then Exit;
  Speech.Stop;
end;

(*
//for non Delphi compilers

procedure PSpeak(Text: LPCTSTR); stdcall;
begin
  if Speech = nil then Exit;
  SpeechSpeak(string(Text));
end;

procedure PSelectEngine(EngineName: LPCTSTR); stdcall;
begin
  if Speech = nil then Exit;
  SpeechSelectEngine(string(EngineName));
end;

function GetEnginesCount: word; stdcall;
begin
  if Speech = nil then Result:= 0 else
    Result := Speech.Engines.Count;
end;

function PGetEngines(number: word): LPCTSTR; stdcall;
begin
  if Speech = nil then Exit;
  PGetEngines := LPCTSTR(Speech.Engines[number - 1]);
end;

procedure PSelectEngineNumber(EngineNumber: word); stdcall;
begin
  if Speech = nil then Exit;
  SpeechSelectEngine(Speech.Engines[EngineNumber]);
end;
*)

//version 2.0 events

procedure RegistOnStart(CallbackAddr: TSpeechEvent);
begin
  OnStartAddr := CallbackAddr;
end;

procedure RegistOnPause(CallbackAddr: TSpeechEvent);
begin
  OnPauseAddr := CallbackAddr;
end;

procedure RegistOnResume(CallbackAddr: TSpeechEvent);
begin
  OnResumeAddr := CallbackAddr;
end;


procedure RegistOnStop(CallbackAddr: TSpeechEvent);
begin
  OnStopAddr := CallbackAddr;
end;

procedure RegistOnUserStart(CallbackAddr: TSpeechEvent);
begin
  OnUserStartAddr := CallbackAddr;
end;

procedure RegistOnUserStop(CallbackAddr: TSpeechEvent);
begin
  OnUserStopAddr := CallbackAddr;
end;

procedure RegistOnPosition(CallbackAddr: TPositionEvent);
begin
  OnPositionAddr := CallbackAddr;
end;

procedure RegistOnSpeed(CallbackAddr: TPositionEvent);
begin
  OnSpeedAddr := CallbackAddr;
end;

procedure RegistOnVolume(CallbackAddr: TPositionEvent);
begin
  OnVolumeAddr := CallbackAddr;
end;

procedure RegistOnPitch(CallbackAddr: TPositionEvent);
begin
  OnPitchAddr := CallbackAddr;
end;

procedure RegistOnSelectEngine(CallbackAddr: TEngineEvent);
begin
  OnSelectEngineAddr := CallbackAddr;
end;

procedure RegistOnStatusChange(CallbackAddr: TSpeechEvent);
begin
  OnStatusChangeAddr := CallbackAddr;
end;

procedure RegistOnError(CallbackAddr: TErrorEvent);
begin
  OnErrorAddr := CallbackAddr;
end;
// Events wraper

procedure TSpeechEvents.DoStart(Sender: TObject);
begin
  if assigned(OnStartAddr) then OnStartAddr;
end;

procedure TSpeechEvents.DoPause(Sender: TObject);
begin
  if assigned(OnPauseAddr) then OnResumeAddr;
end;

procedure TSpeechEvents.DoResume(Sender: TObject);
begin
  if assigned(OnResumeAddr) then OnResumeAddr;
end;


procedure TSpeechEvents.DoStop(Sender: TObject);
begin
  if assigned(OnStopAddr) then OnStopAddr;
end;

procedure TSpeechEvents.DoUserStart(Sender: TObject);
begin
  if assigned(OnUserStartAddr) then OnUserStartAddr;
end;

procedure TSpeechEvents.DoUserStop(Sender: TObject);
begin
  if assigned(OnUserStopAddr) then OnUserStopAddr;
end;

procedure TSpeechEvents.DoPosition(Sender: TObject; Position: dword);
begin
  if assigned(OnPositionAddr) then OnPositionAddr(Position);
end;

procedure TSpeechEvents.DoSpeed(Sender: TObject; Position: dword);
begin
  if assigned(OnSpeedAddr) then OnSpeedAddr(Position);
end;

procedure TSpeechEvents.DoVolume(Sender: TObject; Position: dword);
begin
  if assigned(OnVolumeAddr) then OnVolumeAddr(Position);
end;

procedure TSpeechEvents.DoPitch(Sender: TObject; Position: dword);
begin
  if assigned(OnPitchAddr) then OnPitchAddr(Position);
end;

procedure TSpeechEvents.DoSelectEngine(Sender: TObject; Number: integer; const Name: string);
begin
  if assigned(OnSelectEngineAddr) then OnSelectEngineAddr(Number, Name);
end;

procedure TSpeechEvents.DoStatusChange(Sender: TObject);
begin
  if assigned(OnStatusChangeAddr) then OnStatusChangeAddr;
end;

procedure TSpeechEvents.DoError(Sender: TObject; const Text: Widestring);
begin
  if assigned(OnErrorAddr) then OnErrorAddr(Text);
end;


end.

