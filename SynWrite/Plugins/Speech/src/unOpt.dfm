object fmOpt: TfmOpt
  Left = 430
  Top = 381
  ActiveControl = edVoice
  BorderStyle = bsDialog
  Caption = 'Speech'
  ClientHeight = 176
  ClientWidth = 412
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 29
    Height = 13
    Caption = 'Voice:'
  end
  object Label2: TLabel
    Left = 8
    Top = 72
    Width = 34
    Height = 13
    Caption = 'Speed:'
  end
  object Label3: TLabel
    Left = 8
    Top = 40
    Width = 38
    Height = 13
    Caption = 'Volume:'
  end
  object Label4: TLabel
    Left = 8
    Top = 104
    Width = 27
    Height = 13
    Caption = 'Pitch:'
  end
  object edVoice: TComboBox
    Left = 88
    Top = 8
    Width = 313
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 0
  end
  object bOk: TButton
    Left = 200
    Top = 144
    Width = 97
    Height = 23
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 4
  end
  object bCan: TButton
    Left = 304
    Top = 144
    Width = 97
    Height = 23
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 5
  end
  object edVol: TTrackBar
    Left = 80
    Top = 40
    Width = 329
    Height = 25
    Max = 100
    Frequency = 10
    TabOrder = 1
    ThumbLength = 18
  end
  object edSpeed: TTrackBar
    Left = 80
    Top = 72
    Width = 329
    Height = 25
    Max = 20
    Frequency = 5
    TabOrder = 2
    ThumbLength = 18
  end
  object edPitch: TTrackBar
    Left = 80
    Top = 104
    Width = 329
    Height = 25
    Max = 20
    Frequency = 5
    TabOrder = 3
    ThumbLength = 18
  end
end
