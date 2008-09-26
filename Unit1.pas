unit Unit1;

interface

uses
  VProtocol, uNET, Funcs, BufferCL, IOStreams, CmdByte,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ActnList, ExtCtrls, ShellAPI, ToolWin, ComCtrls,
  Buttons, Menus, CheckLst;

const
  Retries = 10;

type

  TForm1 = class(TForm)
    Memo1: TMemo;
    ActionList1: TActionList;
    Timer1: TTimer;
    Memo2: TMemo;
    AConect: TAction;
    ADisconect: TAction;
    ABrowse: TAction;
    AClearText: TAction;
    StatusBar1: TStatusBar;
    MainMenu1: TMainMenu;
    Action1: TMenuItem;
    Connect1M: TMenuItem;
    Panel1: TPanel;
    Button4: TButton;
    Streamstr1: TMenuItem;
    AConDecon: TAction;
    ATimmerOnOff: TAction;
    Timer1M: TMenuItem;
    AWriteInfo: TAction;
    Button1: TButton;
    AddrList: TCheckListBox;
    MyAddrEdit: TEdit;
    AClose: TAction;
    CloseAll1M: TMenuItem;
    ACloseAll: TAction;
    ARunClone: TAction;
    RunClone1: TMenuItem;
    CheckBox1: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

    procedure Timer1Timer(Sender: TObject);

    procedure AConectExecute(Sender: TObject);
    procedure ADisconectExecute(Sender: TObject);
    procedure ABrowseExecute(Sender: TObject);
    procedure AClearTextExecute(Sender: TObject);
    procedure AConDeconExecute(Sender: TObject);
    procedure ACloseExecute(Sender: TObject);
    procedure ACloseAllExecute(Sender: TObject);
    procedure ATimmerOnOffExecute(Sender: TObject);
    procedure AWriteInfoExecute(Sender: TObject);

    procedure Action1AdvancedDrawItem(Sender: TObject; ACanvas: TCanvas;      ARect: TRect; State: TOwnerDrawState);
    procedure MyAddrEditExit(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure StatusBar1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure StatusBar1DblClick(Sender: TObject);
    procedure ARunCloneExecute(Sender: TObject);
  private
    { Private declarations }
    ToClose:boolean;
    Cnter: integer;
    Condition: boolean;
    FX, FY: integer;
  public
    { Public declarations }
    IO: TVProtocol;
    tgt: TBArray;
    procedure ShowMsg(s: TBArray);
    procedure FormResize(s: TBArray);

  end;

var
  Form1: TForm1;

{-----------------------------------------------------------------------------}
function PutText(Sender: TObject; s: String): Boolean;
{-----------------------------------------------------------------------------}
implementation
{$R *.dfm}
{-----------------------------------------------------------------------------}
function PutText(Sender: TObject; s: String): Boolean;
begin
  if Sender = nil then exit;
  Result:=true;
  if Sender is TCustomEdit then TCustomEdit(Sender).Text := s else
  if(Sender is TMenuItem)then TMenuItem(Sender).Caption := s else
  if(Sender is TLabel)then TLabel(Sender).Caption := s else
  if(Sender is TButton)then TButton(Sender).Caption := s else
     Result:=false;
  s := Sender.ClassName;
  s := s;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.FormCreate(Sender: TObject);
begin
    IO := TuNET.Create(Self, 'Stream.str');
    IO.IDs[0]  := Str2BAr('<To All>');
    setLength(tgt, 0);
    ToClose    := false;
    Condition  := false;
    Top        := (Screen.Height-Height)div 2;
    Left       := (Screen.Width-Width)  div 2;
    AConectExecute(MainMenu1.Items[0].Items[1]);
    ATimmerOnOffExecute(Sender);
end;
{-----------------------------------------------------------------------------}
procedure TForm1.Button4Click(Sender: TObject);
var ba: TBArray;
    i: word;
begin
  ba :=  Str2BAr(#2+Memo1.Text);
  if Length(tgt)=0 then IO.Send(cmd_write, ba)
                   else IO.ListSend(cmd_write, ba, tgt);
  Memo1.Clear;                 
end;
{-----------------------------------------------------------------------------}
procedure TForm1.Timer1Timer(Sender: TObject);
var i:  word;
    bf: TBArray;
    cmd, src: byte;
begin

  if IO.RSBuf.ready <> 0 then with IO.RSBuf do begin
   repeat
     bf  := Each;
     i   := length(bf)-1;
     cmd := bf[1];
     src := bf[i];
//     setlength(bf, i);
     if CheckBox1.Checked then begin
        Memo2.Lines.Append(BAr2Str(bf));
     end;
     case cmd of
        1: Close;
        2: ShowMsg(bf);
        3: FormResize(bf);
     end;
   until ready = 0;
  end;
  AWriteInfoExecute(Sender);
  if ToClose then ACloseExecute(Sender);
end;
{-----------------------------------------------------------------------------}
procedure TForm1.AConectExecute(Sender: TObject);
begin  Cnter := Retries;  while not IO.Conect and (Cnter<>0) do dec(Cnter); PutText(Sender, 'Conected');end;
{-----------------------------------------------------------------------------}
procedure TForm1.ADisconectExecute(Sender: TObject);
begin  Cnter := Retries;  while not IO.Disconect and (Cnter<>0) do dec(Cnter); PutText(Sender, 'Disconected');end;
{-----------------------------------------------------------------------------}
procedure TForm1.AConDeconExecute(Sender: TObject);
begin
  if IO.Conected then begin
    ADisconectExecute(Sender);
    PutText(Sender, '&Conect');
  end else begin
    AConectExecute(Sender);
    PutText(Sender, 'Dis&conect');
  end;
  AWriteInfoExecute(Sender);  
end;
{-----------------------------------------------------------------------------}
procedure TForm1.ATimmerOnOffExecute(Sender: TObject);
begin
  Timer1.Enabled := not Timer1.Enabled;
  if Timer1.Enabled then PutText(Sender, 'Timer On')
                    else PutText(Sender, 'Timer Off');
  AWriteInfoExecute(Sender);
end;
{-----------------------------------------------------------------------------}
procedure TForm1.ABrowseExecute(Sender: TObject); var FN: String;
begin
  FN := IO.FileName;
  if PromptForFileName(FN,
                       '(str)|*.str|(txt)|*.txt', '*.str',
                       'Chose a streaming file',
                       '', True)
  then begin
     IO.Conect(FN);
     PutText(Sender, FN);
     AWriteInfoExecute(Sender);
  end;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.AClearTextExecute(Sender: TObject); begin (Sender as TCustomEdit).Clear; end;
{-----------------------------------------------------------------------------}
procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ACloseExecute(Sender);
  Action := caNone;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.Action1AdvancedDrawItem(Sender: TObject; ACanvas: TCanvas;
  ARect: TRect; State: TOwnerDrawState);
begin
  if IO.Conected then PutText(Connect1M, 'Dis&connect')
                 else PutText(Connect1M, '&Connect');

  if Timer1.Enabled then PutText(Timer1M, 'Timer On')
                    else PutText(Timer1M, 'Timer Off');
  
end;
{-----------------------------------------------------------------------------}
procedure TForm1.MyAddrEditExit; begin  IO.ID := MyAddrEdit.Text; end;
{-----------------------------------------------------------------------------}
procedure TForm1.AWriteInfoExecute(Sender: TObject);
var i:word;
    s:string;
begin
  with StatusBar1 do begin
    if IO.Conected then begin
       Panels[0].Text   := 'Connected';
    end else begin
       Panels[0].Text := 'Disconnected';
    end;
    if Timer1.Enabled then Panels[1].Text := 'Timer On'
                      else Panels[1].Text := 'Timer Off';
    Panels[2].Text := 'Addr: '+byte2str(IO.MyAddr);
    Panels[3].Text := IntToStr(IO.getCycleCount())+':'+IntToStr(IO.getBaudCount());
    Panels[4].Text := ExtractFileName(IO.FileName);

    with AddrList do begin
      setLength(tgt,0);
      while Count <= IO.MaxAddr do Items.Append('');
      while Count-1 > IO.MaxAddr do Items.Delete(AddrList.Count-1);
      i := Count;
      while i > 0 do begin
        Dec(i);
        if Checked[i] then IncBAr(tgt, 1, i);
        s := BAr2Str(IO.IDs[i]);
        if s='' then s := byte2str(i);
        if Items.Strings[i] <> s then Items.Strings[i] := s;
      end;
      if Checked[0] then SetLength(tgt,0);
    end;
    if MyAddrEdit.Text <> IO.ID
    then
    IO.ID := MyAddrEdit.Text;
  end;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.ACloseExecute(Sender: TObject);
begin
  if not ToClose then begin
    ToClose := true;
    Cnter := 1000 div Timer1.Interval * 5;
    if IO.Conected then IO.Send(cmd_stop, GenBAr(1,0,1), ToAll);
  end;
  if not IO.Disconect then Application.Minimize;
  if IO.Disconect or (Cnter=0) then Application.Terminate;
  dec(Cnter);
end;
{-----------------------------------------------------------------------------}
procedure TForm1.ACloseAllExecute(Sender: TObject);
begin
  if IO.Conected then
      if length(tgt)=0 then IO.Send(cmd_write, GenBAr(1,0,1), ToAll);
  ToClose := true;    
  ACloseExecute(Sender);
end;
{-----------------------------------------------------------------------------}
procedure TForm1.ShowMsg(s: TBArray);
var src: byte;
begin
  src := PopBAr(s);
  Memo2.Lines.Append(BAr2Str(IO.IDs[src])+':');
  Memo2.Lines.Append(BAr2Str(Copy(s,2)));
  Memo2.Lines.Append('~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
end;
{-----------------------------------------------------------------------------}
procedure TForm1.FormResize(s: TBArray);
begin
  PopBAr(s);
  Width  := PopBAr(s,2);
  Height := PopBAr(s,2);
end;
{-----------------------------------------------------------------------------}
procedure TForm1.Button1Click(Sender: TObject);
begin
  if length(tgt)=0 then IO.Send(cmd_write, GenBAr(1,0,1), ToAll)
                   else IO.ListSend(cmd_write, GenBAr(1,0,1), tgt);
end;
{-----------------------------------------------------------------------------}

procedure TForm1.StatusBar1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  FX := X;
  FY := y;
end;

procedure TForm1.StatusBar1DblClick(Sender: TObject);
var PanelNr: byte;
    X: integer;
    P: Pointer;
begin
    PanelNr := 0;
    X := 0;
    repeat
      inc(X, StatusBar1.Panels.Items[PanelNr].Width);
      inc(PanelNr);
    until (FX < X) or (StatusBar1.Panels.Count = PanelNr);
    P:= StatusBar1.Panels.Items[PanelNr-1];
    case PanelNr of
    1:AConDeconExecute(P);
    2:ATimmerOnOffExecute(P);
    3:;
    4:IO.ResetCycleCount;
    5:ABrowseExecute(P);
    end;
end;

procedure TForm1.ARunCloneExecute(Sender: TObject);
begin
  ShellExecute(0, 0, PChar(ParamStr(0)), 0, 0, 0);
end;

end.

