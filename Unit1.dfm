object Form1: TForm1
  Left = 188
  Top = 104
  Width = 600
  Height = 427
  Caption = 'Mini LAN Simulatore'
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
  object Label1: TLabel
    Left = 376
    Top = 16
    Width = 39
    Height = 13
    Caption = 'Writeing'
  end
  object Edit2: TEdit
    Left = 68
    Top = 10
    Width = 293
    Height = 21
    TabOrder = 0
    Text = 'Stream.str'
    OnDblClick = ABrowseExecute
  end
  object Memo1: TMemo
    Left = 0
    Top = 64
    Width = 585
    Height = 169
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssVertical
    TabOrder = 1
    OnDblClick = AClearTextExecute
  end
  object Edit3: TEdit
    Left = 67
    Top = 37
    Width = 57
    Height = 21
    TabOrder = 2
  end
  object Button3: TButton
    Left = 374
    Top = 29
    Width = 67
    Height = 25
    Caption = 'Timmer'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 212
    Top = 31
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Write'
    Default = True
    TabOrder = 4
    OnClick = Button4Click
  end
  object Memo2: TMemo
    Left = 0
    Top = 232
    Width = 585
    Height = 169
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssVertical
    TabOrder = 5
    OnDblClick = AClearTextExecute
  end
  object Button1: TButton
    Left = 125
    Top = 34
    Width = 75
    Height = 25
    Caption = 'Conect'
    TabOrder = 6
    OnClick = Button1Click
  end
  object Button6: TButton
    Left = 292
    Top = 31
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Read'
    Default = True
    TabOrder = 7
    OnClick = Button6Click
  end
  object Button2: TButton
    Left = 456
    Top = 32
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 8
    OnClick = Button2Click
  end
  object ActionList1: TActionList
    Left = 40
    Top = 72
    object AConect: TAction
      Caption = 'AConect'
      OnExecute = AConectExecute
    end
    object ADisconect: TAction
      Caption = 'ADisconect'
      OnExecute = ADisconectExecute
    end
    object ABrowse: TAction
      Caption = 'ABrowse'
      OnExecute = ABrowseExecute
    end
    object AClearText: TAction
      Caption = 'AClearText'
      OnExecute = AClearTextExecute
    end
  end
  object Timer1: TTimer
    Interval = 200
    OnTimer = Timer1Timer
    Left = 72
    Top = 72
  end
end
