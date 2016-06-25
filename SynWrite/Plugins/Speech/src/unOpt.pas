unit unOpt;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Spin, ComCtrls;

type
  TfmOpt = class(TForm)
    edVoice: TComboBox;
    Label1: TLabel;
    bOk: TButton;
    bCan: TButton;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    edVol: TTrackBar;
    edSpeed: TTrackBar;
    edPitch: TTrackBar;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function DoOpt(var OpVoice: string; var OpSpeed, OpPitch, OpVol: Integer): boolean;

implementation

uses
  SpeechApi, SpeechMulti;

{$R *.dfm}

function DoOpt(var OpVoice: string; var OpSpeed, OpPitch, OpVol: Integer): boolean;
var
  Eng: TStrings;
begin
  SpeechInit;
  Eng:= GetVoices;

  with TfmOpt.Create(nil) do
  try
    if Eng<>nil then
      edVoice.Items.AddStrings(Eng);
    if OpVoice<>'' then
      edVoice.ItemIndex:= edVoice.Items.IndexOf(OpVoice)
    else
      if edVoice.Items.Count>0 then
        edVoice.ItemIndex:= 0;

    edSpeed.Position:= OpSpeed;
    edPitch.Position:= OpPitch;
    edVol.Position:= OpVol;

    Result:= ShowModal=mrOk;
    if Result then
    begin
      OpVoice:= edVoice.Text;
      OpSpeed:= edSpeed.Position;
      OpPitch:= edPitch.Position;
      OpVol:= edVol.Position;
    end;
  finally
    Free
  end;
end;

end.
