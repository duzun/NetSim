object Form1: TForm1
  Left = 192
  Top = 113
  Width = 870
  Height = 640
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
    862
    613)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 16
    Width = 52
    Height = 13
    Caption = 'Addres file:'
  end
  object Label2: TLabel
    Left = 16
    Top = 48
    Width = 52
    Height = 13
    Caption = 'Stream file:'
  end
  object Label3: TLabel
    Left = 555
    Top = 16
    Width = 37
    Height = 13
    Caption = 'Source:'
  end
  object Label4: TLabel
    Left = 557
    Top = 45
    Width = 34
    Height = 13
    Caption = 'Target:'
  end
  object Edit1: TEdit
    Left = 72
    Top = 16
    Width = 361
    Height = 21
    TabOrder = 0
    Text = 'Addres.sta'
  end
  object Edit2: TEdit
    Left = 72
    Top = 48
    Width = 361
    Height = 21
    TabOrder = 1
    Text = 'Stream.str'
  end
  object Button1: TButton
    Left = 440
    Top = 16
    Width = 75
    Height = 25
    Caption = 'Browse'
    TabOrder = 2
  end
  object Button2: TButton
    Left = 440
    Top = 48
    Width = 75
    Height = 25
    Caption = 'Browse'
    TabOrder = 3
  end
  object Memo1: TMemo
    Left = 0
    Top = 80
    Width = 865
    Height = 529
    Anchors = [akLeft, akTop, akRight, akBottom]
    Lines.Strings = (
      '')
    ScrollBars = ssVertical
    TabOrder = 4
  end
  object Edit3: TEdit
    Left = 592
    Top = 16
    Width = 57
    Height = 21
    TabOrder = 5
  end
  object Button3: TButton
    Left = 648
    Top = 16
    Width = 33
    Height = 25
    Caption = 'Set'
    TabOrder = 6
  end
  object Button4: TButton
    Left = 784
    Top = 5
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Write to Str'
    Default = True
    TabOrder = 7
  end
  object Edit4: TEdit
    Left = 592
    Top = 45
    Width = 57
    Height = 21
    TabOrder = 8
  end
  object ActionList1: TActionList
    Left = 696
    Top = 8
    object OpenStream: TAction
      Caption = 'OpenStream'
      OnExecute = OpenStreamExecute
    end
    object OpenAddres: TAction
      Caption = 'OpenAddres'
      OnExecute = OpenAddresExecute
    end
  end
end
