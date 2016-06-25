// Original code from https://sourceforge.net/projects/sapidll/
// Modified by Alexey (SynWrite)
// removed SAPI4 usage

unit SpeechMulti;

interface
uses
  Windows, SysUtils, Classes, sapi5cut, ActiveX;

const
  DefaultVolume = 80;
  DefaultSpeed = 10;
  DefaultPitch = 0;

  MaxSpeed = 20;
  MinSpeed = 0;

  MaxVolume = 100;
  MinVolume = 0;

  MaxPitch = 20;
  MinPitch = 0;

type
  TEngineState = set of (esSpeak, esPause, esStop);
  TEngineInfo = record
    Name: string;
    Gender: string;
    Language: string;
  end;

type
  TSelectEngineEvent = procedure(Sender: TObject; Number: integer; const Name: string) of object;
  TPositionEvent = procedure(Sender: TObject; Position: dword) of object;
  TErrorEvent = procedure(Sender: TObject; const Text: Widestring) of object;

type  
  TMultiSpeech = class(TComponent)
  protected
    FOnStart: TNotifyEvent;
    FOnPause: TNotifyEvent;
    FOnResume: TNotifyEvent;
    FOnStop: TNotifyEvent;
    FOnUserStart: TNotifyEvent;
    FOnUserStop: TNotifyEvent;
    FOnPosition: TPositionEvent;
    FOnSpeed: TPositionEvent;
    FOnVolume: TPositionEvent;
    FOnPitch: TPositionEvent;
    FOnSelectEngine: TSelectEngineEvent;
    FOnStatusChange: TNotifyEvent;
    FOnError: TErrorEvent;
    FSpeed: integer;
    FVolume: integer;
    FPitch: integer;
    FEngineState: TEngineState;
    SAPI5: TSpVoice;
    UserStop: boolean;
    FEngineInfo: TEngineInfo;

    procedure StartStream(ASender: TObject; StreamNumber: Integer; StreamPosition: OleVariant);
    procedure EndStream(ASender: TObject; StreamNumber: Integer; StreamPosition: OleVariant);
    procedure SpWord(ASender: TObject; StreamNumber: Integer; StreamPosition: OleVariant; CharacterPosition, Length: Integer);

    procedure SetSpeed(Value: integer);
    procedure SetVolume(Value: integer);
    procedure SetPitch(Value: integer);
    procedure AddError(const Text: Widestring);

    procedure DoStop;
  public
    BufferText: Widestring;
    BufferPosition: dword;
    FLastPosition: longint;
    FErrorList: TStringList;
    FVoices: TStringList;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Speak(const Text: Widestring; Async: boolean);
    procedure Stop;
    procedure Pause;
    procedure Resume;
    procedure SetVoice(Number: integer); overload;
    procedure SetVoice(const Name: string); overload;

  published
    property Speed: integer read FSpeed write SetSpeed default DefaultSpeed;
    property Volume: integer read FVolume write SetVolume default DefaultVolume;
    property Pitch: integer read FPitch write SetPitch default DefaultPitch;
    property EngineState: TEngineState read FEngineState write FEngineState;
    property EngineInfo: TEngineInfo read FEngineInfo write FEngineInfo;
    property OnStart: TNotifyEvent read FOnStart write FOnStart;
    property OnPause: TNotifyEvent read FOnPause write FOnPause;
    property OnResume: TNotifyEvent read FOnResume write FOnResume;    
    property OnStop: TNotifyEvent read FOnStop write FOnStop;
    property OnUserStart: TNotifyEvent read FOnUserStart write FOnUserStart;
    property OnUserStop: TNotifyEvent read FOnUserStop write FOnUserStop;

    property OnPosition: TPositionEvent read FOnPosition write FOnPosition;
    property OnSpeed: TPositionEvent read FOnSpeed write FOnSpeed;
    property OnVolume: TPositionEvent read FOnVolume write FOnVolume;
    property OnPitch: TPositionEvent read FOnPitch write FOnPitch;
    property OnSelectEngine: TSelectEngineEvent read FOnSelectEngine write FOnSelectEngine;
    property OnStatusChange: TNotifyEvent read FOnStatusChange write FOnStatusChange;    
    property OnError: TErrorEvent read FOnError write FOnError;
  end;

implementation


constructor TMultiSpeech.Create(AOwner: TComponent);
var
  EngineCount: dword;
begin
  inherited Create(AOwner);

  BufferPosition := 0;
  FVolume := DefaultVolume;
  FSpeed := DefaultSpeed;
  FPitch := DefaultPitch;
  FillChar(FEngineInfo, SizeOf(EngineInfo), #0);

  EngineState := [esStop];
  if Assigned(OnStatusChange) then OnStatusChange(Self);
  FErrorList := TStringList.Create;
  FVoices := TStringList.Create;
  try
    SAPI5 := TSpVoice.Create(Self);
    SAPI5.OnStartStream := StartStream;
    SAPI5.OnEndStream := EndStream;
    SAPI5.OnWord := SpWord;
    for EngineCount := 0 to SAPI5.GetVoices('', '').count - 1 do
      FVoices.Add(SAPI5.GetVoices('', '').Item(EngineCount).GetDescription(0));
  except
    AddError('SAPI 5 initialization fault');
  end;
end;

destructor TMultiSpeech.Destroy;
begin
  Stop;

  FreeAndNil(SAPI5);
  FreeAndNil(FVoices);
  FreeAndNil(FErrorList);

  inherited Destroy;
end;

procedure TMultiSpeech.AddError(const Text: Widestring);
begin
  FErrorList.Add(Text);
  if Assigned(OnError) then OnError(Self, Text);
end;

procedure TMultiSpeech.DoStop;
begin
  EngineState := [esStop];
  if Assigned(OnStatusChange) then OnStatusChange(Self);
  SAPI5.Disconnect;
end;

procedure TMultiSpeech.SetVoice(Number: integer);
var
  pLanguageName: array[0..Pred(80)] of Char;
begin
  DoStop;
  ZeroMemory(@EngineInfo, SizeOf(EngineInfo));
  if Number > FVoices.Count - 1 then Exit;
  try
    if Number < SAPI5.GetVoices('', '').Count then
    begin
      SAPI5.Voice := SAPI5.GetVoices('', '').Item(Number);
      FEngineInfo.Gender := AnsiUpperCase(SAPI5.Voice.GetAttribute('GENDER'));

      VerLanguageName(cardinal(SAPI5.Voice.GetAttribute('LANGUAGE')), pLanguageName, 80);
      FEngineInfo.Language := string(PLanguageName);
    end;

    FEngineInfo.Name := FVoices[Number];

    if Assigned(OnSelectEngine) then OnSelectEngine(Self, Number, FEngineInfo.Name);

  except
    AddError('Select ');
  end;
end;

procedure TMultiSpeech.SetVoice(const Name: string);
begin
  SetVoice(FVoices.IndexOf(Name));
end;

procedure TMultiSpeech.Speak(const Text: Widestring; Async: boolean);
var
  Flags: TOleEnum;
begin
  if Text = '' then Exit;
  if Assigned(OnUserStart) then OnUserStart(Self);
  BufferPosition := 0;

  try
    if Async then
      Flags:= SVSFlagsAsync
    else
      Flags:= 0;
    SAPI5.DefaultInterface.Speak(Text, Flags);
  except
    AddError('SAPI 5 Speak fault: ');
  end;
end;

procedure TMultiSpeech.Stop;
begin
  UserStop := true;
  if Assigned(OnUserStop) then OnUserStop(Self);
  DoStop;
end;

procedure TMultiSpeech.Pause;
begin
  EngineState := [esPause];
  if Assigned(OnStatusChange) then OnStatusChange(Self);  
  if Assigned(OnPause) then OnPause(Self);
  SAPI5.Pause;
end;

procedure TMultiSpeech.Resume;
begin
  EngineState := [esSpeak];
  if Assigned(OnStatusChange) then OnStatusChange(Self);  
  if Assigned(OnResume) then OnResume(Self);  
  SAPI5.Resume;
  if Assigned(OnStart) then OnStart(nil);
end;

procedure TMultiSpeech.StartStream(ASender: TObject; StreamNumber: Integer; StreamPosition: OleVariant);
begin
  EngineState := [esSpeak];
  if Assigned(OnStatusChange) then OnStatusChange(Self);  
  if Assigned(OnStart) then OnStart(ASender);
end;

procedure TMultiSpeech.EndStream(ASender: TObject; StreamNumber: Integer; StreamPosition: OleVariant);
begin
  EngineState := [esStop];
  if Assigned(OnStatusChange) then OnStatusChange(Self);  
  if Assigned(OnStop) then OnStop(ASender);
end;

procedure TMultiSpeech.SpWord(ASender: TObject; StreamNumber: Integer; StreamPosition: OleVariant; CharacterPosition, Length: Integer);
begin
  FLastPosition := CharacterPosition + BufferPosition;
  if Assigned(OnPosition) then OnPosition(ASender, FLastPosition);
end;


procedure TMultiSpeech.SetSpeed(Value: integer);
var
  Text: Widestring;
begin
  if Value < MinSpeed then Value := MinSpeed;
  if Value > MaxSpeed then Value := MaxSpeed;
  FSpeed := Value;

  Stop;
  Text := '<RATE ABSSPEED="' + inttostr(Value - 10) + '">';
  Speak(Text, true);

  BufferPosition := length(BufferText) - length(Text);
  if Assigned(OnSpeed) then OnSpeed(Self, value);
end;


procedure TMultiSpeech.SetVolume(Value: integer);
begin
  if Value < MinVolume then Value := MinVolume;
  if Value > MaxVolume then Value := MaxVolume;
  FVolume := Value;
  SAPI5.Volume := Value;
  if Assigned(OnVolume) then OnVolume(Self, value);
end;

procedure TMultiSpeech.SetPitch(Value: integer);
var
  Text: Widestring;
begin
  if Value < MinPitch then Value := MinPitch;
  if Value > MaxPitch then Value := MaxPitch;
  FPitch := Value;

  Stop;
  Text := '<pitch absmiddle="' + inttostr(Value - 10) + '">';
  Speak(Text, true);

  BufferPosition := length(BufferText) - length(Text);
  if Assigned(OnPitch) then OnPitch(Self, value);
end;


end.

