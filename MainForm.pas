unit MainForm;

interface

uses
  ProtocolBase, GovProtocol, Funcs, BufferCL,  CmdByte,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ActnList, ExtCtrls, ShellAPI, ToolWin, ComCtrls,
  Buttons, Menus, CheckLst;

const
  Retries = 100;

type

  TForm1 = class(TForm)
    StatusBar1: TStatusBar;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet3: TTabSheet;
    Memo2: TMemo;
    Memo1: TMemo;
    Panel1: TPanel;
    AddrList: TCheckListBox;
    Button4: TButton;
    Button1: TButton;
    MyAddrEdit: TEdit;
    MainMenu1: TMainMenu;
    Action1: TMenuItem;
    CloseAll1M: TMenuItem;
    Connect1M: TMenuItem;
    Timer1M: TMenuItem;
    RunClone1: TMenuItem;
    Streamstr1: TMenuItem;
    ActionList1: TActionList;
    AConect: TAction;
    ADisconect: TAction;
    ABrowse: TAction;
    AClearText: TAction;
    AConDecon: TAction;
    ATimmerOnOff: TAction;
    AWriteInfo: TAction;
    AClose: TAction;
    ACloseAll: TAction;
    ARunClone: TAction;
    Timer1: TTimer;
    Label1: TLabel;
    Memo3: TMemo;
    TabSheet2: TTabSheet;
    LInfo: TLabel;
    Button2: TButton;
    Button3: TButton;
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
    procedure ARunCloneExecute(Sender: TObject);

    procedure Action1AdvancedDrawItem(Sender: TObject; ACanvas: TCanvas;      ARect: TRect; State: TOwnerDrawState);
    procedure MyAddrEditExit(Sender: TObject);
    procedure StatusBar1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure StatusBar1DblClick(Sender: TObject);

    procedure OnStateChange(Sender: TObject);
    procedure OnDataReceived(Sender: TObject);

    procedure SendFormSizeCmd(Sender: TObject);
    procedure SendTestCmd (Sender: TObject);
    procedure SendWriteCmd(Sender: TObject);
    procedure SendCloseCmd(Sender: TObject);
    procedure SendClearCmd(Sender: TObject);
    procedure AddrListClick(Sender: TObject);
  private
    { Private declarations }
    ToClose:boolean;
    Cnter: integer;
    Condition: boolean;
    FX, FY: integer;
  public
    { Public declarations }
    IO: TProtocolBase;
    tgt: TBArray;
    b_tgt: byte;
    procedure ShowMsg(s: TBArray);
    procedure FormResize(bf: TBArray);
    procedure FormMove(bf: TBArray);
    procedure FormMoveTo(bf: TBArray);

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
  if(Sender is TButton)then TButton(Sender).Caption := s
                       else Result:=false;
  s := Sender.ClassName;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.FormCreate(Sender: TObject);
begin
    IO := TGovProtocol.Create(Self, 'Chanels\Stream.str');
    IO.IDs[0]  := ToBAr('<To All>');
    IO.OnStateChange := OnStateChange;
    setLength(tgt, 0);
    b_tgt      := ToAll;
    ToClose    := false;
    Condition  := false;
    Top        := (Screen.Height-Height)div 2;
    Left       := (Screen.Width-Width)  div 2;
    AConectExecute(MainMenu1.Items[0].Items[1]);
    ATimmerOnOffExecute(Sender);
end;
{-----------------------------------------------------------------------------}
procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Label1.Caption := IntToStr((IO as TGovProtocol).getState);
  OnDataReceived(Sender);  
  AWriteInfoExecute(Sender);
  if ToClose then ACloseExecute(Sender);
end;
{-----------------------------------------------------------------------------}
procedure TForm1.AConectExecute(Sender: TObject);
begin
   if not IO.Conect then
      ShowMessage('Nu ma pot conecta la ' + IO.FileName + '!')
   else
      PutText(Sender, 'Conected');
end;
{-----------------------------------------------------------------------------}
procedure TForm1.ADisconectExecute(Sender: TObject);
begin 
  Cnter := Retries * IO.MaxAddr; 
  while not IO.Disconect(Cnter=0) do dec(Cnter); 
  PutText(Sender, 'Disconected');
end;
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
  with IO do begin
    PutText(LInfo, '' +
    #13#10#9'~ TIOStream ~' + #13#10 +
    'Opened: '#9 + Bool2Str(Opened) + #13#10 +
    'Chanel: '#9 + FileName + #13#10 +
    'CycleCount:'#9 + IntToStr(CycleCount) + #13#10 +
    'NoReadCount:'#9 + IntToStr(NoReadCount) + #13#10 +
    'NoWriteCount:'#9 + IntToStr(NoWriteCount) + #13#10 +
    'Received:'#9 + IntToStr(ReadPackets) + #13#10 +
    'Sent:'#9#9 + IntToStr(WrittenPackets) + #13#10 +

    #13#10#9'~ TConnection ~' + #13#10 +
    'My Name: '#9 + ID + #13#10 +
    'My Address: '#9 + '$' + byte2str(MyAddr) + #13#10 +
    'Max Addr: '#9 + '$' + byte2str(MaxAddr) + #13#10 +
    'Connected:'#9 + TimeToStr(Time-ConectionTime) + #13#10 +
    'Reading: '#9 + Bool2Str(Reading) + #13#10 +
    'Writing: '#9 + Bool2Str(Writing) + #13#10 +
    'BaudRate:'#9 + IntToStr(BaudRate) + #13#10 +
    '');
  end;

  with StatusBar1 do begin
    if IO.Conected then begin
       Panels[0].Text   := 'Connected';
    end else begin
       Panels[0].Text := 'Disconnected';
    end;
    if Timer1.Enabled then Panels[1].Text := 'Timer On'
                      else Panels[1].Text := 'Timer Off';
    Panels[2].Text := 'Addr: '+byte2str(IO.MyAddr);
    Panels[3].Text := IntToStr(IO.CycleCount);
    if IO.Writing then
       Panels[4].Text := 'Writing'
    else if IO.Reading then
       Panels[4].Text := 'Reading'
    else
       Panels[4].Text := '...';

    AddrListClick(Sender);
    if MyAddrEdit.Text <> IO.ID then IO.ID := MyAddrEdit.Text;
  end;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.ACloseExecute(Sender: TObject);
begin
  if not ToClose then begin
    ToClose := true;
    Cnter   := 1000 div Timer1.Interval * 5 * IO.MaxAddr;
    if IO.Conected then IO.Send(cmd_stop, 1, ToAll);
  end;
  if not IO.Disconect then Application.Minimize;
  if IO.Disconect(Cnter=0) then Application.Terminate;
  dec(Cnter);
end;
{-----------------------------------------------------------------------------}
procedure TForm1.ACloseAllExecute(Sender: TObject);
begin
  if IO.Conected then
      if length(tgt)=0 then IO.Send(cmd_write, cmd_close, ToAll);
  ToClose := true;
  ACloseExecute(Sender);
end;
{-----------------------------------------------------------------------------}
procedure TForm1.StatusBar1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer); begin FX := X;  FY := y; end;
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
{-----------------------------------------------------------------------------}
procedure TForm1.ARunCloneExecute(Sender: TObject); begin ShellExecute(0, 0, PChar(ParamStr(0)), 0, 0, 0); end;
{-----------------------------------------------------------------------------}
procedure TForm1.OnStateChange(Sender: TObject);
begin
  if Timer1.Enabled then with Sender as TProtocolBase do Memo3.Lines.Append(StateMsg);
end;
{-----------------------------------------------------------------------------}
procedure TForm1.OnDataReceived(Sender: TObject);
var i:  word;
    bf: TBArray;
    cmd, src: byte;
begin
  with IO.RSBuf do while ready <> 0 do begin
     bf  := Each;
     i   := length(bf)-1;
     cmd := ShiftBAr(bf, 1);
     src := bf[i];
//      setlength(bf, i); // sometimes its' required
     case cmd of
        cmd_close        : Close;
        cmd_write        : ShowMsg(bf);
        cmd_clear        : AClearTextExecute(Memo2);
        cmd_set_form_size: FormResize(bf);
        cmd_get_on_top   : ;
        else PutText(Memo2, 'Unknown cmd: $'+byte2str(cmd));
     end;
  end;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.SendTestCmd;
var t: byte;
begin
  if Length(tgt) = 1 then t := tgt[0] else t := ToAll;
  with IO do begin
    SendType(cmd_write, 'Testare codif/decodif:', t); // String
    SendTime(cmd_write, Time, t);              // TDateTime
    SendType(cmd_write, MyAddr, t);            // byte
    SendType(cmd_write, 'Q', t);               // char
    SendType(cmd_write, word($FFFF), t);       // word
    SendType(cmd_write, -1, t);                // integer
    SendType(cmd_write, $FFFFFFFF, t);         // longword
    SendType(cmd_write, 123.456789, t);        // double / real
  end;                                  
end;                                    
{-----------------------------------------------------------------------------}
procedure TForm1.SendWriteCmd;          
begin                                   
  if Length(tgt)=0 then IO.SendType(cmd_write, Memo1.Text)
                   else IO.ListSendType(cmd_write, Memo1.Text, tgt);
  Memo1.Clear;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.SendCloseCmd;
begin
  if length(tgt)=0 then IO.Send(cmd_Data, cmd_close)
                   else IO.ListSend(cmd_Data, cmd_close, tgt);
end;
{-----------------------------------------------------------------------------}
procedure TForm1.SendClearCmd;
begin
  if Length(tgt)=0 then IO.Send(cmd_Data, cmd_clear)
                   else IO.ListSend(cmd_Data, cmd_clear, tgt);
end;
{-----------------------------------------------------------------------------}
procedure TForm1.SendFormSizeCmd;
begin
  if Length(tgt)=0 then IO.Send(cmd_set_form_size, Join(ToBar(word(Width)), ToBar(word(Height))) )
                   else IO.ListSend(cmd_set_form_size, Join(ToBar(word(Width)), ToBar(word(Height))), tgt);
end;
{-----------------------------------------------------------------------------}
procedure TForm1.ShowMsg;
var src, t: byte;
    msg: string;
    BAr: TBArray;
begin
  src := PopBAr(s);
  t   := ShiftBAr(s, 1);
  Memo2.Lines.Append(BAr2Str(IO.IDs[src])+':');
  case t of
  cmd_Byte    : msg := byte2str(BAr2Word(s)and $FF);
  cmd_Word    : msg := IntToStr(BAr2Word(s));
  cmd_Int     : msg := IntToStr(BAr2Int(s));
  cmd_LongWord: msg := IntToStr(BAr2LongWord(s));
  cmd_Char    : msg := chr(BAr2Word(s)and $FF);
  cmd_String  : msg := BAr2Str(s);
  cmd_Time    : msg := TimeToStr(BAr2Double(s));
  cmd_Double  : msg := FloatToStr(BAr2Double(s));
  else          msg := 'Unknown #'+byte2str(t);
  end;
  Memo2.Lines.Append(msg);
  Memo2.Lines.Append('~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
end;
{-----------------------------------------------------------------------------}
procedure TForm1.FormResize;
var w, h: integer;
begin
  w := ShiftBAr(bf, 2);
  h := ShiftBAr(bf, 2); 
  if w > 0 then Width  := w;
  if h > 0 then Height := h;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.FormMove;
var dx, dy: integer;
begin
  dx := integer(BAr2Word(bf, 0, 2));
  dy := integer(BAr2Word(bf, 2, 2));
  Left := Left+dx;
  Top  := Top+dy;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.FormMoveTo;
var x, y: integer;
begin
  x := integer(BAr2Word(bf, 0, 2));
  y := integer(BAr2Word(bf, 2, 2));
  Left := x - Width  div 2;
  Top  := y - Height div 2;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.AddrListClick(Sender: TObject);
var i: integer;
    s: string;
begin
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
end;

end.
