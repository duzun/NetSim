object Form1: TForm1
  Left = 696
  Top = 330
  Width = 465
  Height = 373
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
  PixelsPerInch = 96
  TextHeight = 13
  object StatusBar1: TStatusBar
    Left = 0
    Top = 302
    Width = 457
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
        Width = 40
      end
      item
        Width = 50
      end>
    OnDblClick = StatusBar1DblClick
    OnMouseMove = StatusBar1MouseMove
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 457
    Height = 302
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 1
    object TabSheet1: TTabSheet
      Caption = 'Chat'
      DesignSize = (
        449
        274)
      object Memo2: TMemo
        Left = 0
        Top = 0
        Width = 300
        Height = 192
        Hint = 'Aici vin mesajele primite de la altii'
        Anchors = [akLeft, akTop, akRight, akBottom]
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 0
        OnDblClick = AClearTextExecute
      end
      object Memo1: TMemo
        Left = 0
        Top = 191
        Width = 298
        Height = 81
        Hint = 'Aici scrie mesajul pe care doresti sa-l trimiti!'
        Anchors = [akLeft, akRight, akBottom]
        ScrollBars = ssVertical
        TabOrder = 1
        WantReturns = False
        WantTabs = True
        OnDblClick = AClearTextExecute
      end
      object Panel1: TPanel
        Left = 304
        Top = 0
        Width = 145
        Height = 272
        Anchors = [akTop, akRight, akBottom]
        TabOrder = 2
        DesignSize = (
          145
          272)
        object Label1: TLabel
          Left = 88
          Top = 224
          Width = 3
          Height = 13
        end
        object AddrList: TCheckListBox
          Left = 0
          Top = 23
          Width = 145
          Height = 169
          Hint = 'Cui se refera comanda'
          Anchors = [akLeft, akTop, akBottom]
          Color = clScrollBar
          ItemHeight = 13
          Items.Strings = (
            '')
          TabOrder = 0
        end
        object Button4: TButton
          Left = 6
          Top = 219
          Width = 50
          Height = 25
          Anchors = [akRight, akBottom]
          Caption = 'Write'
          Default = True
          TabOrder = 1
          OnClick = Button4Click
        end
        object Button1: TButton
          Left = 6
          Top = 193
          Width = 50
          Height = 25
          Hint = 'Inchide adresa selectata'
          Anchors = [akRight, akBottom]
          Caption = 'Close'
          TabOrder = 2
          OnClick = Button1Click
        end
        object MyAddrEdit: TEdit
          Left = 0
          Top = 0
          Width = 145
          Height = 21
          Hint = 'Numele meu'
          TabOrder = 3
          OnExit = MyAddrEditExit
        end
        object Button2: TButton
          Left = 70
          Top = 192
          Width = 50
          Height = 25
          Caption = 'Test'
          TabOrder = 4
          OnClick = Button2Click
        end
        object Button3: TButton
          Left = 70
          Top = 218
          Width = 50
          Height = 25
          Anchors = [akRight, akBottom]
          Caption = 'Clear'
          TabOrder = 5
          OnClick = Button3Click
        end
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Info'
      ImageIndex = 2
      object LInfo: TLabel
        Left = 0
        Top = 0
        Width = 23
        Height = 13
        Align = alClient
        Caption = 'Info'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Verdana'
        Font.Style = []
        ParentFont = False
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'Log'
      ImageIndex = 1
      DesignSize = (
        449
        274)
      object Memo3: TMemo
        Left = 0
        Top = 0
        Width = 449
        Height = 273
        Anchors = [akLeft, akTop, akRight, akBottom]
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier'
        Font.Style = []
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 0
        OnDblClick = AClearTextExecute
      end
    end
  end
  object MainMenu1: TMainMenu
    Left = 416
    Top = 65520
    object Action1: TMenuItem
      Caption = 'Action'
      OnAdvancedDrawItem = Action1AdvancedDrawItem
      object CloseAll1M: TMenuItem
        Action = AClose
        Caption = 'Close All'
        ShortCut = 16499
      end
      object Connect1M: TMenuItem
        Caption = 'Connect/Decon'
        ShortCut = 8259
        OnClick = AConDeconExecute
      end
      object Timer1M: TMenuItem
        Caption = 'Timer'
        ShortCut = 8276
        OnClick = ATimmerOnOffExecute
      end
      object RunClone1: TMenuItem
        Caption = 'Run Clone'
        ShortCut = 16466
        OnClick = ARunCloneExecute
      end
    end
    object Streamstr1: TMenuItem
      Action = ABrowse
      Caption = 'File'
    end
  end
  object ActionList1: TActionList
    Left = 352
    Top = 65520
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
    object ARunClone: TAction
      Caption = 'ARunClone'
      OnExecute = ARunCloneExecute
    end
    object AOnStateChange: TAction
      Caption = 'AOnStateChange'
    end
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 100
    OnTimer = Timer1Timer
    Left = 384
    Top = 65520
  end
end
