object Form1: TForm1
  Left = 190
  Top = 108
  Width = 688
  Height = 578
  Caption = 'Mini LAN Simulatore'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  ShowHint = True
  OnActivate = AWriteInfoExecute
  OnClose = FormClose
  OnCreate = FormCreate
  DesignSize = (
    680
    531)
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 0
    Top = 450
    Width = 535
    Height = 61
    Anchors = [akLeft, akRight, akBottom]
    Lines.Strings = (
      '1 2 3 4 5 6 7 8 9 0')
    ScrollBars = ssVertical
    TabOrder = 0
    WantReturns = False
    WantTabs = True
    OnDblClick = AClearTextExecute
  end
  object Memo2: TMemo
    Left = 0
    Top = 0
    Width = 535
    Height = 455
    Anchors = [akLeft, akTop, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
    OnDblClick = AClearTextExecute
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 512
    Width = 680
    Height = 19
    Panels = <
      item
        Width = 75
      end
      item
        Width = 70
      end
      item
        Width = 50
      end
      item
        Width = 50
      end>
  end
  object Panel1: TPanel
    Left = 533
    Top = 0
    Width = 145
    Height = 514
    Anchors = [akTop, akRight, akBottom]
    TabOrder = 3
    DesignSize = (
      145
      514)
    object Button4: TButton
      Left = 6
      Top = 279
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Write'
      Default = True
      TabOrder = 0
      OnClick = Button4Click
    end
    object Button2: TButton
      Left = 6
      Top = 208
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Experiment'
      TabOrder = 1
      OnClick = Button2Click
    end
    object Button1: TButton
      Left = 8
      Top = 248
      Width = 75
      Height = 25
      Caption = 'Close'
      TabOrder = 2
    end
    object AddrList: TCheckListBox
      Left = 0
      Top = 23
      Width = 145
      Height = 137
      Hint = 'Cui se refera actiunea'
      Color = clScrollBar
      ItemHeight = 13
      Items.Strings = (
        '')
      TabOrder = 3
    end
    object MyAddrEdit: TEdit
      Left = 0
      Top = 1
      Width = 145
      Height = 21
      TabOrder = 4
      OnExit = MyAddrEditExit
    end
  end
  object ActionList1: TActionList
    Left = 656
    Top = 16
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
      Hint = 'Fisierul de comunicare'
      OnExecute = ABrowseExecute
    end
    object AClearText: TAction
      Caption = 'AClearText'
      OnExecute = AClearTextExecute
    end
    object AConDecon: TAction
      Caption = 'AConDecon'
      OnExecute = AConDeconExecute
    end
    object ATimmerOnOff: TAction
      Caption = 'ATimmerOnOff'
      OnExecute = ATimmerOnOffExecute
    end
    object AWriteInfo: TAction
      Caption = 'AWriteInfo'
      OnExecute = AWriteInfoExecute
    end
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 300
    OnTimer = Timer1Timer
    Left = 632
    Top = 16
  end
  object MainMenu1: TMainMenu
    Left = 688
    Top = 16
    object Action1: TMenuItem
      Caption = 'Action'
      OnAdvancedDrawItem = Action1AdvancedDrawItem
      object Connect1: TMenuItem
        Caption = 'Connect/Decon'
        OnClick = AConDeconExecute
      end
      object imer1: TMenuItem
        Caption = 'Timer'
        OnClick = ATimmerOnOffExecute
      end
    end
    object Conection1: TMenuItem
      Caption = 'Conection'
      object Streamstr1: TMenuItem
        Action = ABrowse
        Caption = 'File'
      end
    end
  end
end
