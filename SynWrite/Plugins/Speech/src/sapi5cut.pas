{
  Get Access to Speech API from DLL methods [SAPI4, SAPI5 support]
  (c) Kirin Denis 2002-2006.  version 2.0 GNU GPL
  http://wtwsoft.narod.ru
  mailto:wtwsoft@narod.ru
}

unit sapi5cut;
interface
uses
 OleServer, ActiveX, Classes, Variants;
const
  IID_ISpeechObjectToken: TGUID = '{C74A3ADC-B727-4500-A84A-B526721C8B8C}';
  SVSFlagsAsync = $00000001;
type
  ISpeechObjectToken = interface;
  ISpeechDataKey = interface;
  ISpeechObjectTokenCategory = interface;
  ISpeechObjectTokens = interface;
  ISpeechVoice = interface;
  ISpeechVoiceStatus = interface;
  ISpeechBaseStream = interface;
  ISpeechAudioFormat = interface;
  ISpeechWaveFormatEx = interface;


  SpeechVisemeFeature = TOleEnum;
  SpeechVisemeType = TOleEnum;
  SpeechVoiceEvents = TOleEnum;
  SpeechVoicePriority = TOleEnum;
  SpeechVoiceSpeakFlags = TOleEnum;
  SpeechTokenContext = TOleEnum;
  SpeechTokenShellFolder  = TOleEnum;
  SpeechDataKeyLocation  = TOleEnum;
  SpeechRunState   = TOleEnum;
  SpeechStreamSeekPositionType = TOleEnum;
  SpeechAudioFormatType = TOleEnum;

  ISpeechObjectToken = interface(IDispatch)
    ['{C74A3ADC-B727-4500-A84A-B526721C8B8C}']
    function Get_Id: WideString; safecall;
    function Get_DataKey: ISpeechDataKey; safecall;
    function Get_Category: ISpeechObjectTokenCategory; safecall;
    function GetDescription(Locale: Integer): WideString; safecall;
    procedure SetId(const Id: WideString; const CategoryID: WideString; CreateIfNotExist: WordBool); safecall;
    function GetAttribute(const AttributeName: WideString): WideString; safecall;
    function CreateInstance(const pUnkOuter: IUnknown; ClsContext: SpeechTokenContext): IUnknown; safecall;
    procedure Remove(const ObjectStorageCLSID: WideString); safecall;
    function GetStorageFileName(const ObjectStorageCLSID: WideString; const KeyName: WideString;
                                const FileName: WideString; Folder: SpeechTokenShellFolder): WideString; safecall;
    procedure RemoveStorageFileName(const ObjectStorageCLSID: WideString;
                                    const KeyName: WideString; DeleteFile: WordBool); safecall;
    function IsUISupported(const TypeOfUI: WideString; var ExtraData: OleVariant;
                           const Object_: IUnknown): WordBool; safecall;
    procedure DisplayUI(hWnd: Integer; const Title: WideString; const TypeOfUI: WideString;
                        var ExtraData: OleVariant; const Object_: IUnknown); safecall;
    function MatchesAttributes(const Attributes: WideString): WordBool; safecall;
    property Id: WideString read Get_Id;
    property DataKey: ISpeechDataKey read Get_DataKey;
    property Category: ISpeechObjectTokenCategory read Get_Category;
  end;


  ISpeechDataKey = interface(IDispatch)
    ['{CE17C09B-4EFA-44D5-A4C9-59D9585AB0CD}']
    procedure SetBinaryValue(const ValueName: WideString; Value: OleVariant); safecall;
    function GetBinaryValue(const ValueName: WideString): OleVariant; safecall;
    procedure SetStringValue(const ValueName: WideString; const Value: WideString); safecall;
    function GetStringValue(const ValueName: WideString): WideString; safecall;
    procedure SetLongValue(const ValueName: WideString; Value: Integer); safecall;
    function GetLongValue(const ValueName: WideString): Integer; safecall;
    function OpenKey(const SubKeyName: WideString): ISpeechDataKey; safecall;
    function CreateKey(const SubKeyName: WideString): ISpeechDataKey; safecall;
    procedure DeleteKey(const SubKeyName: WideString); safecall;
    procedure DeleteValue(const ValueName: WideString); safecall;
    function EnumKeys(Index: Integer): WideString; safecall;
    function EnumValues(Index: Integer): WideString; safecall;
  end;


  ISpeechObjectTokenCategory = interface(IDispatch)
    ['{CA7EAC50-2D01-4145-86D4-5AE7D70F4469}']
    function Get_Id: WideString; safecall;
    procedure Set_Default(const TokenId: WideString); safecall;
    function Get_Default: WideString; safecall;
    procedure SetId(const Id: WideString; CreateIfNotExist: WordBool); safecall;
    function GetDataKey(Location: SpeechDataKeyLocation): ISpeechDataKey; safecall;
    function EnumerateTokens(const RequiredAttributes: WideString; 
                             const OptionalAttributes: WideString): ISpeechObjectTokens; safecall;
    property Id: WideString read Get_Id;
    property Default: WideString read Get_Default write Set_Default;
  end;

  ISpeechObjectTokens = interface(IDispatch)
    ['{9285B776-2E7B-4BC0-B53E-580EB6FA967F}']
    function Get_Count: Integer; safecall;
    function Item(Index: Integer): ISpeechObjectToken; safecall;
    function Get__NewEnum: IUnknown; safecall;
    property Count: Integer read Get_Count;
    property _NewEnum: IUnknown read Get__NewEnum;
  end;

  ISpeechVoice = interface(IDispatch)
    ['{269316D8-57BD-11D2-9EEE-00C04F797396}']
    function Get_Status: ISpeechVoiceStatus; safecall;
    function Get_Voice: ISpeechObjectToken; safecall;
    procedure _Set_Voice(const Voice: ISpeechObjectToken); safecall;
    function Get_AudioOutput: ISpeechObjectToken; safecall;
    procedure _Set_AudioOutput(const AudioOutput: ISpeechObjectToken); safecall;
    function Get_AudioOutputStream: ISpeechBaseStream; safecall;
    procedure _Set_AudioOutputStream(const AudioOutputStream: ISpeechBaseStream); safecall;
    function Get_Rate: Integer; safecall;
    procedure Set_Rate(Rate: Integer); safecall;
    function Get_Volume: Integer; safecall;
    procedure Set_Volume(Volume: Integer); safecall;
    procedure Set_AllowAudioOutputFormatChangesOnNextSet(Allow: WordBool); safecall;
    function Get_AllowAudioOutputFormatChangesOnNextSet: WordBool; safecall;
    function Get_EventInterests: SpeechVoiceEvents; safecall;
    procedure Set_EventInterests(EventInterestFlags: SpeechVoiceEvents); safecall;
    procedure Set_Priority(Priority: SpeechVoicePriority); safecall;
    function Get_Priority: SpeechVoicePriority; safecall;
    procedure Set_AlertBoundary(Boundary: SpeechVoiceEvents); safecall;
    function Get_AlertBoundary: SpeechVoiceEvents; safecall;
    procedure Set_SynchronousSpeakTimeout(msTimeout: Integer); safecall;
    function Get_SynchronousSpeakTimeout: Integer; safecall;
    function Speak(const Text: WideString; Flags: SpeechVoiceSpeakFlags): Integer; safecall;
    function SpeakStream(const Stream: ISpeechBaseStream; Flags: SpeechVoiceSpeakFlags): Integer; safecall;
    procedure Pause; safecall;
    procedure Resume; safecall;
    function Skip(const Type_: WideString; NumItems: Integer): Integer; safecall;
    function GetVoices(const RequiredAttributes: WideString; const OptionalAttributes: WideString): ISpeechObjectTokens; safecall;
    function GetAudioOutputs(const RequiredAttributes: WideString; 
                             const OptionalAttributes: WideString): ISpeechObjectTokens; safecall;
    function WaitUntilDone(msTimeout: Integer): WordBool; safecall;
    function SpeakCompleteEvent: Integer; safecall;
    function IsUISupported(const TypeOfUI: WideString; var ExtraData: OleVariant): WordBool; safecall;
    procedure DisplayUI(hWndParent: Integer; const Title: WideString; const TypeOfUI: WideString; 
                        var ExtraData: OleVariant); safecall;
    property Status: ISpeechVoiceStatus read Get_Status;
    property Voice: ISpeechObjectToken read Get_Voice write _Set_Voice;
    property AudioOutput: ISpeechObjectToken read Get_AudioOutput write _Set_AudioOutput;
    property AudioOutputStream: ISpeechBaseStream read Get_AudioOutputStream write _Set_AudioOutputStream;
    property Rate: Integer read Get_Rate write Set_Rate;
    property Volume: Integer read Get_Volume write Set_Volume;
    property AllowAudioOutputFormatChangesOnNextSet: WordBool read Get_AllowAudioOutputFormatChangesOnNextSet write Set_AllowAudioOutputFormatChangesOnNextSet;
    property EventInterests: SpeechVoiceEvents read Get_EventInterests write Set_EventInterests;
    property Priority: SpeechVoicePriority read Get_Priority write Set_Priority;
    property AlertBoundary: SpeechVoiceEvents read Get_AlertBoundary write Set_AlertBoundary;
    property SynchronousSpeakTimeout: Integer read Get_SynchronousSpeakTimeout write Set_SynchronousSpeakTimeout;
  end;


    ISpeechVoiceStatus = interface(IDispatch)
    ['{8BE47B07-57F6-11D2-9EEE-00C04F797396}']
    function Get_CurrentStreamNumber: Integer; safecall;
    function Get_LastStreamNumberQueued: Integer; safecall;
    function Get_LastHResult: Integer; safecall;
    function Get_RunningState: SpeechRunState; safecall;
    function Get_InputWordPosition: Integer; safecall;
    function Get_InputWordLength: Integer; safecall;
    function Get_InputSentencePosition: Integer; safecall;
    function Get_InputSentenceLength: Integer; safecall;
    function Get_LastBookmark: WideString; safecall;
    function Get_LastBookmarkId: Integer; safecall;
    function Get_PhonemeId: Smallint; safecall;
    function Get_VisemeId: Smallint; safecall;
    property CurrentStreamNumber: Integer read Get_CurrentStreamNumber;
    property LastStreamNumberQueued: Integer read Get_LastStreamNumberQueued;
    property LastHResult: Integer read Get_LastHResult;
    property RunningState: SpeechRunState read Get_RunningState;
    property InputWordPosition: Integer read Get_InputWordPosition;
    property InputWordLength: Integer read Get_InputWordLength;
    property InputSentencePosition: Integer read Get_InputSentencePosition;
    property InputSentenceLength: Integer read Get_InputSentenceLength;
    property LastBookmark: WideString read Get_LastBookmark;
    property LastBookmarkId: Integer read Get_LastBookmarkId;
    property PhonemeId: Smallint read Get_PhonemeId;
    property VisemeId: Smallint read Get_VisemeId;
  end;

  ISpeechBaseStream = interface(IDispatch)
    ['{6450336F-7D49-4CED-8097-49D6DEE37294}']
    function Get_Format: ISpeechAudioFormat; safecall;
    procedure _Set_Format(const AudioFormat: ISpeechAudioFormat); safecall;
    function Read(out Buffer: OleVariant; NumberOfBytes: Integer): Integer; safecall;
    function Write(Buffer: OleVariant): Integer; safecall;
    function Seek(Position: OleVariant; Origin: SpeechStreamSeekPositionType): OleVariant; safecall;
    property Format: ISpeechAudioFormat read Get_Format write _Set_Format;
  end;
  

  ISpeechAudioFormat = interface(IDispatch)
    ['{E6E9C590-3E18-40E3-8299-061F98BDE7C7}']
    function Get_type_: SpeechAudioFormatType; safecall;
    procedure Set_type_(AudioFormat: SpeechAudioFormatType); safecall;
    function Get_Guid: WideString; safecall;
    procedure Set_Guid(const Guid: WideString); safecall;
    function GetWaveFormatEx: ISpeechWaveFormatEx; safecall;
    procedure SetWaveFormatEx(const WaveFormatEx: ISpeechWaveFormatEx); safecall;
    property type_: SpeechAudioFormatType read Get_type_ write Set_type_;
    property Guid: WideString read Get_Guid write Set_Guid;
  end;


  ISpeechWaveFormatEx = interface(IDispatch)
    ['{7A1EF0D5-1581-4741-88E4-209A49F11A10}']
    function Get_FormatTag: Smallint; safecall;
    procedure Set_FormatTag(FormatTag: Smallint); safecall;
    function Get_Channels: Smallint; safecall;
    procedure Set_Channels(Channels: Smallint); safecall;
    function Get_SamplesPerSec: Integer; safecall;
    procedure Set_SamplesPerSec(SamplesPerSec: Integer); safecall;
    function Get_AvgBytesPerSec: Integer; safecall;
    procedure Set_AvgBytesPerSec(AvgBytesPerSec: Integer); safecall;
    function Get_BlockAlign: Smallint; safecall;
    procedure Set_BlockAlign(BlockAlign: Smallint); safecall;
    function Get_BitsPerSample: Smallint; safecall;
    procedure Set_BitsPerSample(BitsPerSample: Smallint); safecall;
    function Get_ExtraData: OleVariant; safecall;
    procedure Set_ExtraData(ExtraData: OleVariant); safecall;
    property FormatTag: Smallint read Get_FormatTag write Set_FormatTag;
    property Channels: Smallint read Get_Channels write Set_Channels;
    property SamplesPerSec: Integer read Get_SamplesPerSec write Set_SamplesPerSec;
    property AvgBytesPerSec: Integer read Get_AvgBytesPerSec write Set_AvgBytesPerSec;
    property BlockAlign: Smallint read Get_BlockAlign write Set_BlockAlign;
    property BitsPerSample: Smallint read Get_BitsPerSample write Set_BitsPerSample;
    property ExtraData: OleVariant read Get_ExtraData write Set_ExtraData;
  end;
  

  TSpVoiceStartStream = procedure(ASender: TObject; StreamNumber: Integer;
                                                    StreamPosition: OleVariant) of object;
  TSpVoiceEndStream = procedure(ASender: TObject; StreamNumber: Integer; StreamPosition: OleVariant) of object;
  TSpVoiceVoiceChange = procedure(ASender: TObject; StreamNumber: Integer;
                                                    StreamPosition: OleVariant;
                                                    const VoiceObjectToken: ISpeechObjectToken) of object;
  TSpVoiceBookmark = procedure(ASender: TObject; StreamNumber: Integer; StreamPosition: OleVariant;
                                                 const Bookmark: WideString; BookmarkId: Integer) of object;
  TSpVoiceWord = procedure(ASender: TObject; StreamNumber: Integer; StreamPosition: OleVariant;
                                             CharacterPosition: Integer; Length: Integer) of object;
  TSpVoiceSentence = procedure(ASender: TObject; StreamNumber: Integer; StreamPosition: OleVariant;
                                                 CharacterPosition: Integer; Length: Integer) of object;
  TSpVoicePhoneme = procedure(ASender: TObject; StreamNumber: Integer; StreamPosition: OleVariant;
                                                Duration: Integer; NextPhoneId: Smallint;
                                                Feature: SpeechVisemeFeature;
                                                CurrentPhoneId: Smallint) of object;
  TSpVoiceViseme = procedure(ASender: TObject; StreamNumber: Integer; StreamPosition: OleVariant;
                                               Duration: Integer; NextVisemeId: SpeechVisemeType;
                                               Feature: SpeechVisemeFeature;
                                               CurrentVisemeId: SpeechVisemeType) of object;
  TSpVoiceAudioLevel = procedure(ASender: TObject; StreamNumber: Integer;
                                                   StreamPosition: OleVariant; AudioLevel: Integer) of object;
  TSpVoiceEnginePrivate = procedure(ASender: TObject; StreamNumber: Integer;
                                                      StreamPosition: Integer; 
                                                      EngineData: OleVariant) of object;

  TSpVoice = class(TOleServer)
  private
    FOnStartStream: TSpVoiceStartStream;
    FOnEndStream: TSpVoiceEndStream;
    FOnVoiceChange: TSpVoiceVoiceChange;
    FOnBookmark: TSpVoiceBookmark;
    FOnWord: TSpVoiceWord;
    FOnSentence: TSpVoiceSentence;
    FOnPhoneme: TSpVoicePhoneme;
    FOnViseme: TSpVoiceViseme;
    FOnAudioLevel: TSpVoiceAudioLevel;
    FOnEnginePrivate: TSpVoiceEnginePrivate;
    FIntf:        ISpeechVoice;
{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
    FProps:       TSpVoiceProperties;
    function      GetServerProperties: TSpVoiceProperties;
{$ENDIF}
    function      GetDefaultInterface: ISpeechVoice;
  protected
    procedure InitServerData; override;
    procedure InvokeEvent(DispID: TDispID; var Params: TVariantArray); override;
    function Get_Status: ISpeechVoiceStatus;
    function Get_Voice: ISpeechObjectToken;
    procedure _Set_Voice(const Voice: ISpeechObjectToken);
    function Get_AudioOutput: ISpeechObjectToken;
    procedure _Set_AudioOutput(const AudioOutput: ISpeechObjectToken);
    function Get_AudioOutputStream: ISpeechBaseStream;
    procedure _Set_AudioOutputStream(const AudioOutputStream: ISpeechBaseStream);
    function Get_Rate: Integer;
    procedure Set_Rate(Rate: Integer);
    function Get_Volume: Integer;
    procedure Set_Volume(Volume: Integer);
    procedure Set_AllowAudioOutputFormatChangesOnNextSet(Allow: WordBool);
    function Get_AllowAudioOutputFormatChangesOnNextSet: WordBool;
    function Get_EventInterests: SpeechVoiceEvents;
    procedure Set_EventInterests(EventInterestFlags: SpeechVoiceEvents);
    procedure Set_Priority(Priority: SpeechVoicePriority);
    function Get_Priority: SpeechVoicePriority;
    procedure Set_AlertBoundary(Boundary: SpeechVoiceEvents);
    function Get_AlertBoundary: SpeechVoiceEvents;
    procedure Set_SynchronousSpeakTimeout(msTimeout: Integer);
    function Get_SynchronousSpeakTimeout: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure Connect; override;
    procedure ConnectTo(svrIntf: ISpeechVoice);
    procedure Disconnect; override;
    function Speak(const Text: WideString; Flags: SpeechVoiceSpeakFlags): Integer;
    function SpeakStream(const Stream: ISpeechBaseStream; Flags: SpeechVoiceSpeakFlags): Integer;
    procedure Pause;
    procedure Resume;
    function Skip(const Type_: WideString; NumItems: Integer): Integer;
    function GetVoices(const RequiredAttributes: WideString; const OptionalAttributes: WideString): ISpeechObjectTokens;
    function GetAudioOutputs(const RequiredAttributes: WideString; 
                             const OptionalAttributes: WideString): ISpeechObjectTokens;
    function WaitUntilDone(msTimeout: Integer): WordBool;
    function SpeakCompleteEvent: Integer;
    function IsUISupported(const TypeOfUI: WideString): WordBool; overload;
    function IsUISupported(const TypeOfUI: WideString; var ExtraData: OleVariant): WordBool; overload;
    procedure DisplayUI(hWndParent: Integer; const Title: WideString; const TypeOfUI: WideString); overload;
    procedure DisplayUI(hWndParent: Integer; const Title: WideString; const TypeOfUI: WideString; 
                        var ExtraData: OleVariant); overload;
    property DefaultInterface: ISpeechVoice read GetDefaultInterface;
    property Status: ISpeechVoiceStatus read Get_Status;
    property Voice: ISpeechObjectToken read Get_Voice write _Set_Voice;
    property AudioOutput: ISpeechObjectToken read Get_AudioOutput write _Set_AudioOutput;
    property AudioOutputStream: ISpeechBaseStream read Get_AudioOutputStream write _Set_AudioOutputStream;
    property AllowAudioOutputFormatChangesOnNextSet: WordBool read Get_AllowAudioOutputFormatChangesOnNextSet write Set_AllowAudioOutputFormatChangesOnNextSet;
    property Rate: Integer read Get_Rate write Set_Rate;
    property Volume: Integer read Get_Volume write Set_Volume;
    property EventInterests: SpeechVoiceEvents read Get_EventInterests write Set_EventInterests;
    property Priority: SpeechVoicePriority read Get_Priority write Set_Priority;
    property AlertBoundary: SpeechVoiceEvents read Get_AlertBoundary write Set_AlertBoundary;
    property SynchronousSpeakTimeout: Integer read Get_SynchronousSpeakTimeout write Set_SynchronousSpeakTimeout;
  published
{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
    property Server: TSpVoiceProperties read GetServerProperties;
{$ENDIF}
    property OnStartStream: TSpVoiceStartStream read FOnStartStream write FOnStartStream;
    property OnEndStream: TSpVoiceEndStream read FOnEndStream write FOnEndStream;
    property OnVoiceChange: TSpVoiceVoiceChange read FOnVoiceChange write FOnVoiceChange;
    property OnBookmark: TSpVoiceBookmark read FOnBookmark write FOnBookmark;
    property OnWord: TSpVoiceWord read FOnWord write FOnWord;
    property OnSentence: TSpVoiceSentence read FOnSentence write FOnSentence;
    property OnPhoneme: TSpVoicePhoneme read FOnPhoneme write FOnPhoneme;
    property OnViseme: TSpVoiceViseme read FOnViseme write FOnViseme;
    property OnAudioLevel: TSpVoiceAudioLevel read FOnAudioLevel write FOnAudioLevel;
    property OnEnginePrivate: TSpVoiceEnginePrivate read FOnEnginePrivate write FOnEnginePrivate;
  end;


implementation

procedure TSpVoice.InitServerData;
const
  CServerData: TServerData = (
    ClassID:   '{96749377-3391-11D2-9EE3-00C04F797396}';
    IntfIID:   '{269316D8-57BD-11D2-9EEE-00C04F797396}';
    EventIID:  '{A372ACD1-3BEF-4BBD-8FFB-CB3E2B416AF8}';
    LicenseKey: nil;
    Version: 500);
begin
  ServerData := @CServerData;
end;

procedure TSpVoice.Connect;
var
  punk: IUnknown;
begin
  if FIntf = nil then
  begin
    punk := GetServer;
    ConnectEvents(punk);
    Fintf:= punk as ISpeechVoice;
  end;
end;

procedure TSpVoice.ConnectTo(svrIntf: ISpeechVoice);
begin
  Disconnect;
  FIntf := svrIntf;
  ConnectEvents(FIntf);
end;

procedure TSpVoice.DisConnect;
begin
  if Fintf <> nil then
  begin
    DisconnectEvents(FIntf);
    FIntf := nil;
  end;
end;

function TSpVoice.GetDefaultInterface: ISpeechVoice;
begin
  if FIntf = nil then
    Connect;
  Assert(FIntf <> nil, 'DefaultInterface is NULL. Component is not connected to Server. You must call ''Connect'' or ''ConnectTo'' before this operation');
  Result := FIntf;
end;

constructor TSpVoice.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
  FProps := TSpVoiceProperties.Create(Self);
{$ENDIF}
end;

destructor TSpVoice.Destroy;
begin
{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
  FProps.Free;
{$ENDIF}
  inherited Destroy;
end;

{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
function TSpVoice.GetServerProperties: TSpVoiceProperties;
begin
  Result := FProps;
end;
{$ENDIF}

procedure TSpVoice.InvokeEvent(DispID: TDispID; var Params: TVariantArray);
begin
  case DispID of
    -1: Exit;  // DISPID_UNKNOWN
    1: if Assigned(FOnStartStream) then
         FOnStartStream(Self,
                        Params[0] {Integer},
                        Params[1] {OleVariant});
    2: if Assigned(FOnEndStream) then
         FOnEndStream(Self,
                      Params[0] {Integer},
                      Params[1] {OleVariant});
    3: if Assigned(FOnVoiceChange) then
         FOnVoiceChange(Self,
                        Params[0] {Integer},
                        Params[1] {OleVariant},
                        IUnknown(TVarData(Params[2]).VPointer) as ISpeechObjectToken {const ISpeechObjectToken});
    4: if Assigned(FOnBookmark) then
         FOnBookmark(Self,
                     Params[0] {Integer},
                     Params[1] {OleVariant},
                     Params[2] {const WideString},
                     Params[3] {Integer});
    5: if Assigned(FOnWord) then
         FOnWord(Self,
                 Params[0] {Integer},
                 Params[1] {OleVariant},
                 Params[2] {Integer},
                 Params[3] {Integer});
    7: if Assigned(FOnSentence) then
         FOnSentence(Self,
                     Params[0] {Integer},
                     Params[1] {OleVariant},
                     Params[2] {Integer},
                     Params[3] {Integer});
    6: if Assigned(FOnPhoneme) then
         FOnPhoneme(Self,
                    Params[0] {Integer},
                    Params[1] {OleVariant},
                    Params[2] {Integer},
                    Params[3] {Smallint},
                    Params[4] {SpeechVisemeFeature},
                    Params[5] {Smallint});
    8: if Assigned(FOnViseme) then
         FOnViseme(Self,
                   Params[0] {Integer},
                   Params[1] {OleVariant},
                   Params[2] {Integer},
                   Params[3] {SpeechVisemeType},
                   Params[4] {SpeechVisemeFeature},
                   Params[5] {SpeechVisemeType});
    9: if Assigned(FOnAudioLevel) then
         FOnAudioLevel(Self,
                       Params[0] {Integer},
                       Params[1] {OleVariant},
                       Params[2] {Integer});
    10: if Assigned(FOnEnginePrivate) then
         FOnEnginePrivate(Self,
                          Params[0] {Integer},
                          Params[1] {Integer},
                          Params[2] {OleVariant});
  end; {case DispID}
end;

function TSpVoice.Get_Status: ISpeechVoiceStatus;
begin
    Result := DefaultInterface.Status;
end;

function TSpVoice.Get_Voice: ISpeechObjectToken;
begin
    Result := DefaultInterface.Voice;
end;

procedure TSpVoice._Set_Voice(const Voice: ISpeechObjectToken);
  { Warning: The property Voice has a setter and a getter whose
    types do not match. Delphi was unable to generate a property of
    this sort and so is using a Variant as a passthrough. }
var
  InterfaceVariant: OleVariant;
begin
  InterfaceVariant := DefaultInterface;
  InterfaceVariant.Voice := Voice;
end;

function TSpVoice.Get_AudioOutput: ISpeechObjectToken;
begin
    Result := DefaultInterface.AudioOutput;
end;

procedure TSpVoice._Set_AudioOutput(const AudioOutput: ISpeechObjectToken);
  { Warning: The property AudioOutput has a setter and a getter whose
    types do not match. Delphi was unable to generate a property of
    this sort and so is using a Variant as a passthrough. }
var
  InterfaceVariant: OleVariant;
begin
  InterfaceVariant := DefaultInterface;
  InterfaceVariant.AudioOutput := AudioOutput;
end;

function TSpVoice.Get_AudioOutputStream: ISpeechBaseStream;
begin
    Result := DefaultInterface.AudioOutputStream;
end;

procedure TSpVoice._Set_AudioOutputStream(const AudioOutputStream: ISpeechBaseStream);
  { Warning: The property AudioOutputStream has a setter and a getter whose
    types do not match. Delphi was unable to generate a property of
    this sort and so is using a Variant as a passthrough. }
var
  InterfaceVariant: OleVariant;
begin
  InterfaceVariant := DefaultInterface;
  InterfaceVariant.AudioOutputStream := AudioOutputStream;
end;

function TSpVoice.Get_Rate: Integer;
begin
    Result := DefaultInterface.Rate;
end;

procedure TSpVoice.Set_Rate(Rate: Integer);
begin
  DefaultInterface.Set_Rate(Rate);
end;

function TSpVoice.Get_Volume: Integer;
begin
    Result := DefaultInterface.Volume;
end;

procedure TSpVoice.Set_Volume(Volume: Integer);
begin
  DefaultInterface.Set_Volume(Volume);
end;

procedure TSpVoice.Set_AllowAudioOutputFormatChangesOnNextSet(Allow: WordBool);
begin
  DefaultInterface.Set_AllowAudioOutputFormatChangesOnNextSet(Allow);
end;

function TSpVoice.Get_AllowAudioOutputFormatChangesOnNextSet: WordBool;
begin
    Result := DefaultInterface.AllowAudioOutputFormatChangesOnNextSet;
end;

function TSpVoice.Get_EventInterests: SpeechVoiceEvents;
begin
    Result := DefaultInterface.EventInterests;
end;

procedure TSpVoice.Set_EventInterests(EventInterestFlags: SpeechVoiceEvents);
begin
  DefaultInterface.Set_EventInterests(EventInterestFlags);
end;

procedure TSpVoice.Set_Priority(Priority: SpeechVoicePriority);
begin
  DefaultInterface.Set_Priority(Priority);
end;

function TSpVoice.Get_Priority: SpeechVoicePriority;
begin
    Result := DefaultInterface.Priority;
end;

procedure TSpVoice.Set_AlertBoundary(Boundary: SpeechVoiceEvents);
begin
  DefaultInterface.Set_AlertBoundary(Boundary);
end;

function TSpVoice.Get_AlertBoundary: SpeechVoiceEvents;
begin
    Result := DefaultInterface.AlertBoundary;
end;

procedure TSpVoice.Set_SynchronousSpeakTimeout(msTimeout: Integer);
begin
  DefaultInterface.Set_SynchronousSpeakTimeout(msTimeout);
end;

function TSpVoice.Get_SynchronousSpeakTimeout: Integer;
begin
    Result := DefaultInterface.SynchronousSpeakTimeout;
end;

function TSpVoice.Speak(const Text: WideString; Flags: SpeechVoiceSpeakFlags): Integer;
begin
  Result := DefaultInterface.Speak(Text, Flags);
end;

function TSpVoice.SpeakStream(const Stream: ISpeechBaseStream; Flags: SpeechVoiceSpeakFlags): Integer;
begin
  Result := DefaultInterface.SpeakStream(Stream, Flags);
end;

procedure TSpVoice.Pause;
begin
  DefaultInterface.Pause;
end;

procedure TSpVoice.Resume;
begin
  DefaultInterface.Resume;
end;

function TSpVoice.Skip(const Type_: WideString; NumItems: Integer): Integer;
begin
  Result := DefaultInterface.Skip(Type_, NumItems);
end;

function TSpVoice.GetVoices(const RequiredAttributes: WideString; 
                            const OptionalAttributes: WideString): ISpeechObjectTokens;
begin
  Result := DefaultInterface.GetVoices(RequiredAttributes, OptionalAttributes);
end;

function TSpVoice.GetAudioOutputs(const RequiredAttributes: WideString; 
                                  const OptionalAttributes: WideString): ISpeechObjectTokens;
begin
  Result := DefaultInterface.GetAudioOutputs(RequiredAttributes, OptionalAttributes);
end;

function TSpVoice.WaitUntilDone(msTimeout: Integer): WordBool;
begin
  Result := DefaultInterface.WaitUntilDone(msTimeout);
end;

function TSpVoice.SpeakCompleteEvent: Integer;
begin
  Result := DefaultInterface.SpeakCompleteEvent;
end;

function TSpVoice.IsUISupported(const TypeOfUI: WideString): WordBool;
begin
  Result := DefaultInterface.IsUISupported(TypeOfUI, EmptyParam);
end;

function TSpVoice.IsUISupported(const TypeOfUI: WideString; var ExtraData: OleVariant): WordBool;
begin
  Result := DefaultInterface.IsUISupported(TypeOfUI, ExtraData);
end;

procedure TSpVoice.DisplayUI(hWndParent: Integer; const Title: WideString; 
                             const TypeOfUI: WideString);
begin
  DefaultInterface.DisplayUI(hWndParent, Title, TypeOfUI, EmptyParam);
end;

procedure TSpVoice.DisplayUI(hWndParent: Integer; const Title: WideString; 
                             const TypeOfUI: WideString; var ExtraData: OleVariant);
begin
  DefaultInterface.DisplayUI(hWndParent, Title, TypeOfUI, ExtraData);
end;



end.
