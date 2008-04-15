unit Unit1;

interface

uses
  uNET, Funcs, BufferCL, IOStreams, CmdByte,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ActnList, ExtCtrls, ShellAPI, ToolWin, ComCtrls,
  Buttons, Menus, CheckLst;

const
  Retries = 100;

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
    Conection1: TMenuItem;
    Connect1: TMenuItem;
    Panel1: TPanel;
    Button4: TButton;
    Button2: TButton;
    Streamstr1: TMenuItem;
    AConDecon: TAction;
    ATimmerOnOff: TAction;
    imer1: TMenuItem;
    AWriteInfo: TAction;
    Button1: TButton;
    AddrList: TCheckListBox;
    MyAddrEdit: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure AConectExecute(Sender: TObject);
    procedure ADisconectExecute(Sender: TObject);
    procedure ABrowseExecute(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure AClearTextExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure AConDeconExecute(Sender: TObject);
    procedure Action1AdvancedDrawItem(Sender: TObject; ACanvas: TCanvas;
      ARect: TRect; State: TOwnerDrawState);
    procedure ATimmerOnOffExecute(Sender: TObject);
    procedure AWriteInfoExecute(Sender: TObject);
    procedure MyAddrEditExit(Sender: TObject);
  private
    ToClose:boolean;
    { Private declarations }
  public
    { Public declarations }
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
  s:=Sender.ClassName;
  s:=s;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.FormCreate(Sender: TObject);
begin
    ToClose:=false;
    IO := TuNET.Create(Self, 'Stream.str');
    AConectExecute(Sender);
    ATimmerOnOffExecute(Sender);
end;
{-----------------------------------------------------------------------------}
procedure TForm1.Button4Click(Sender: TObject);
var ba: TBArray;
    tgtL: TBArray;
    tgt:byte;
    i: word;
begin

  if tgt = 0 then tgt := ToAll;

  ba:= Str2BAr(#2+Memo1.Text);
  IO.Send(writeData, ba, tgt);
end;
{-----------------------------------------------------------------------------}
procedure TForm1.Timer1Timer(Sender: TObject);
var i: word;
    bf: TBArray;
    cmd, src:byte;
begin
  if IO.RSBuf.ready > 0 then with IO.RSBuf do begin
   repeat
     bf:=Each;
     i:=length(bf)-1;
     cmd:=bf[1];
     src:=bf[i];
     setlength(bf, i);
     case cmd of
        1: Close;
        2: Memo2.Lines.Append(BAr2Str(Copy(bf,2)));
        3: ;
     end;
   until ready = 0;
  end;
  AWriteInfoExecute(Sender);
  if ToClose then Close;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.AConectExecute(Sender: TObject);var i: integer;
begin  i := Retries;  while not IO.Conect() and (i<>0) do dec(i); PutText(Sender, 'Conected');end;
{-----------------------------------------------------------------------------}
procedure TForm1.ADisconectExecute(Sender: TObject);var i: integer;
begin  i := Retries;  while not IO.Disconect and (i<>0) do dec(i); PutText(Sender, 'Disconected');end;
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
end;
{-----------------------------------------------------------------------------}
procedure TForm1.ATimmerOnOffExecute(Sender: TObject);
begin
  Timer1.Enabled := not Timer1.Enabled;
  if Timer1.Enabled then PutText(Sender, 'Timer On')
                    else PutText(Sender, 'Timer Off');
end;
{-----------------------------------------------------------------------------}
procedure TForm1.ABrowseExecute(Sender: TObject); var FN: String;
begin
  FN := IO.GetFileName;
  if PromptForFileName(FN,
                       '(str)|*.str|(txt)|*.txt', '*.str',
                       'Chose a streaming file',
                       '', True)
  then PutText(Sender, FN);
end;
{-----------------------------------------------------------------------------}
procedure TForm1.AClearTextExecute(Sender: TObject); begin (Sender as TCustomEdit).Clear; end;
{-----------------------------------------------------------------------------}
procedure TForm1.Button2Click(Sender: TObject);
var i: integer;
    t, s, p, len: byte;
    w, ms: word;
    D1, D2 : TDateTime;
    a, c: TBArray;
    bb: TBArArray;
    r: string;
begin

exit;
setlength(a, 1000);
for i:=0 to 1000 do a[i]:=i;
w:=0;

bb:=ArISOForm(a, 1, 2);

p:=0;
if ISOSplit(a, c, s, t)=0 then begin
  Memo2.Text:=inttostr(ISOSplit(a, p, len));
  for i:=0 to length(c)-1 do r:=r+byte2str(c[i]);
  Memo1.Lines.Append(byte2str(s)+byte2str(t));
  Memo1.Lines.Append(r);
end;

{  for i:= 1 to Memo1.Lines.Count do IO.WriteFrame(Str2BAr(Memo1.Lines[i-1]));
  while(IO.StrBuf.ready<>0)do Memo2.Lines.Append(BAr2Str(IO.StrBuf.Each));
}
{
D1 := Time;
a:=GenBAr($3f, 0, c_MaxReadBuf);
for i:=1 to 10000 do begin
  IO.WSBuf.Each := a;
  IO.WriteSBuf;
  IO.ReadSBuf;
end;
D2 := Time;
Memo2.Text := TimeToStr(D2 - D1);
}
end;
{-----------------------------------------------------------------------------}

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not ToClose then begin
    if IO.Conected then begin
      IO.Send(writeData, GenBAr(1,0,1), ToAll);
      Action:=caMinimize;
    end;
    ToClose:=true;
  end else begin
    if IO.WSBuf.ready<>0 then Action:=caNone;
    ToClose:=true;
  end;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.Action1AdvancedDrawItem(Sender: TObject; ACanvas: TCanvas;
  ARect: TRect; State: TOwnerDrawState);
begin
  if IO.Conected then PutText(Connect1, 'Dis&connect')
  else PutText(Connect1, '&Connect');
end;
{-----------------------------------------------------------------------------}
procedure TForm1.MyAddrEditExit; begin  IO.ID := MyAddrEdit.Text; end;
{-----------------------------------------------------------------------------}
procedure TForm1.AWriteInfoExecute(Sender: TObject);
var i:word;
    s:string;
begin
  with StatusBar1 do begin
    if IO.Conected then Panels[0].Text:='Connected'
                   else Panels[0].Text:='Disconnected';
    if Timer1.Enabled then Panels[1].Text:='Timer On'
                       else Panels[1].Text:='Timer Off';
    Panels[2].Text := 'Addr: '+byte2str(IO.MyAddr);
    Panels[3].Text := IO.GetFileName;
    with AddrList do begin
      while Count < IO.MaxAddr do Items.Append('');
      while Count > IO.MaxAddr do Items.Delete(AddrList.Count-1);
      i:=Count;
      while i >0 do begin
        Dec(i);
        s:=BAr2Str(IO.IDs[i]);
        if s='' then s:=byte2str(i+1);
        Items.Strings[i] := s;
      end;
    end;
//    MyAddrEdit.Text := IO.ID;
  end;
end;
{-----------------------------------------------------------------------------}
end.

