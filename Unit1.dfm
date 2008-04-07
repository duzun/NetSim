object Form1: TForm1
  Left = 188
  Top = 104
  Width = 600
  Height = 427
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    592
    400)
  PixelsPerInch = 96
  TextHeight = 13
  object Label2: TLabel
    Left = 12
    Top = 10
    Width = 52
    Height = 13
    Caption = 'Stream file:'
  end
  object Label3: TLabel
    Left = 23
    Top = 37
    Width = 36
    Height = 13
    Caption = 'Addres:'
  end
  object Edit2: TEdit
    Left = 68
    Top = 10
    Width = 361
    Height = 21
    TabOrder = 0
    Text = 'Stream.str'
  end
  object Button2: TButton
    Left = 436
    Top = 10
    Width = 75
    Height = 25
    Caption = 'Browse'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Memo1: TMemo
    Left = 0
    Top = 64
    Width = 297
    Height = 329
    Anchors = [akLeft, akTop, akRight, akBottom]
    Lines.Strings = (
      '')
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object Edit3: TEdit
    Left = 67
    Top = 37
    Width = 57
    Height = 21
    TabOrder = 3
  end
  object Button3: TButton
    Left = 124
    Top = 37
    Width = 33
    Height = 25
    Caption = 'Set'
    TabOrder = 4
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 436
    Top = 37
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Write to Str'
    Default = True
    TabOrder = 5
    OnClick = Button4Click
  end
  object Memo2: TMemo
    Left = 301
    Top = 184
    Width = 284
    Height = 217
    Anchors = [akLeft, akTop, akRight, akBottom]
    Lines.Strings = (
      '')
    ScrollBars = ssVertical
    TabOrder = 6
  end
  object Button1: TButton
    Left = 437
    Top = 64
    Width = 75
    Height = 25
    Caption = 'Conect'
    TabOrder = 7
    OnClick = Button1Click
  end
  object ActionList1: TActionList
    Left = 64
    Top = 144
  end
  object Timer1: TTimer
    Interval = 100
    OnTimer = Timer1Timer
    Left = 96
    Top = 144
  end
end
