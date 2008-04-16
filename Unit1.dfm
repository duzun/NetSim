object Form1: TForm1
  Left = 190
  Top = 115
  Width = 413
  Height = 375
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
    405
    328)
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 0
    Top = 247
    Width = 260
    Height = 61
    Hint = 'Aici scrie mesajul pe care doresti sa-l trimiti!'
    Anchors = [akLeft, akRight, akBottom]
    ScrollBars = ssVertical
    TabOrder = 0
    WantReturns = False
    WantTabs = True
    OnDblClick = AClearTextExecute
  end
  object Memo2: TMemo
    Left = 0
    Top = 0
    Width = 260
    Height = 252
    Hint = 'Aici vin mesajele primite de la altii'
    Anchors = [akLeft, akTop, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
    OnDblClick = AClearTextExecute
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 309
    Width = 405
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
    Left = 258
    Top = 0
    Width = 145
    Height = 311
    Anchors = [akTop, akRight, akBottom]
    TabOrder = 3
    DesignSize = (
      145
      311)
    object Button4: TButton
      Left = 6
      Top = 276
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = 'Write'
      Default = True
      TabOrder = 0
      OnClick = Button4Click
    end
    object Button1: TButton
      Left = 8
      Top = 237
      Width = 75
      Height = 25
      Hint = 'Inchide adresa selectata'
      Anchors = [akRight, akBottom]
      Caption = 'Close'
      TabOrder = 1
      OnClick = Button1Click
    end
    object AddrList: TCheckListBox
      Left = 0
      Top = 23
      Width = 145
      Height = 184
      Hint = 'Cui se refera comanda'
      Anchors = [akLeft, akTop, akBottom]
      Color = clScrollBar
      ItemHeight = 13
      Items.Strings = (
        '')
      TabOrder = 2
    end
    object MyAddrEdit: TEdit
      Left = 0
      Top = 1
      Width = 145
      Height = 21
      Hint = 'Numele meu'
      TabOrder = 3
      OnExit = MyAddrEditExit
    end
  end
  object ActionList1: TActionList
    Left = 72
    Top = 8
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
    object AClose: TAction
      Caption = 'AClose'
      OnExecute = ACloseExecute
    end
    object ACloseAll: TAction
      Caption = 'ACloseAll'
      OnExecute = ACloseAllExecute
    end
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 100
    OnTimer = Timer1Timer
    Left = 40
    Top = 8
  end
  object MainMenu1: TMainMenu
    Left = 8
    Top = 8
    object Action1: TMenuItem
      Caption = 'Action'
      OnAdvancedDrawItem = Action1AdvancedDrawItem
      object CloseAll1: TMenuItem
        Action = AClose
        Caption = 'Close All'
      end
      object Connect1: TMenuItem
        Caption = 'Connect/Decon'
        OnClick = AConDeconExecute
      end
      object imer1: TMenuItem
        Caption = 'Timer'
        OnClick = ATimmerOnOffExecute
      end
    end
    object Streamstr1: TMenuItem
      Action = ABrowse
      Caption = 'File'
    end
  end
end
