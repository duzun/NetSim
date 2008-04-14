unit Unit1;

interface

uses
  Funcs, BufferCL, IOStreams, CmdByte,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ActnList, ExtCtrls, ShellAPI;

type

  TForm1 = class(TForm)
    Edit2: TEdit;
    Label2: TLabel;
    Memo1: TMemo;
    Edit3: TEdit;
    Label3: TLabel;
    Button3: TButton;
    ActionList1: TActionList;
    Button4: TButton;
    Timer1: TTimer;
    Memo2: TMemo;
    Button1: TButton;
    AConect: TAction;
    ADisconect: TAction;
    ABrowse: TAction;
    Button2: TButton;
    AClearText: TAction;
    Label4: TLabel;
    Edit4: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure AConectExecute(Sender: TObject);
    procedure ADisconectExecute(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ABrowseExecute(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure AClearTextExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Edit4Change(Sender: TObject);
  private
    ToClose:boolean;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

{-----------------------------------------------------------------------------}

implementation
{$R *.dfm}

{-----------------------------------------------------------------------------}
procedure TForm1.FormCreate(Sender: TObject);
begin
    ToClose:=false;
    IO.Create(Self, Edit2.Text);
    Button1Click(Sender);
    Timer1.Enabled := true;
    if ParamStr(1) <> 'DUzun' then
    begin
//       ShellExecute(0,'open', pchar(ParamStr(0)),'DUzun',nil,SW_SHOWNORMAL);
//       Button3Click(Sender);
    end;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.Button4Click(Sender: TObject);
var ba: TBArray;
    tgt: byte;
begin
  if Edit3.Text='' then tgt:=ToAll
  else tgt:=strtoint(Edit3.Text);
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
//  if IO.RBuf.ready > 0 then Memo2.Text := Memo2.Text + IO.RBuf.SReadReady;
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
  if ToClose then Close;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.Button3Click(Sender: TObject);
begin
  Timer1.Enabled := not Timer1.Enabled;
  if Timer1.Enabled then Button3.Caption := Button3.Caption + ' On'
                    else Button3.Caption := 'Timmer';
end;

{-----------------------------------------------------------------------------}
procedure TForm1.AConectExecute(Sender: TObject);var i: integer;
begin  i := 100;  while not IO.Conect(Edit2.Text) and (i<>0) do dec(i);end;
{-----------------------------------------------------------------------------}
procedure TForm1.ADisconectExecute(Sender: TObject);var i: integer;
begin  i := 100;  while not IO.Disconect and (i<>0) do dec(i);end;
{-----------------------------------------------------------------------------}
procedure TForm1.ABrowseExecute(Sender: TObject); var FN: String;
begin
  FN := (Sender as TCustomEdit).Text;
  if PromptForFileName(FN,
                       '(str)|*.str|(txt)|*.txt', '*.str',
                       'Chose a streaming file',
                       '', True)
  then (Sender as TCustomEdit).Text := FN;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.AClearTextExecute(Sender: TObject); begin (Sender as TCustomEdit).Clear; end;
{-----------------------------------------------------------------------------}
procedure TForm1.Button1Click(Sender: TObject);
begin
   if IO.Conected then begin
      ADisconectExecute(nil);
      Button1.Caption := 'Conect';
   end else begin
      AConectExecute(nil);
      Button1.Caption := 'Disconect';
   end;
end;
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
      Action:=caNone;
    end;
    ToClose:=true;
  end else begin
    if IO.WSBuf.ready<>0 then Action:=caNone;
    ToClose:=true;
  end;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.Edit4Change(Sender: TObject);
begin
  IO.MyAddr:=StrToInt(Edit4.Text);
end;
{-----------------------------------------------------------------------------}
end.

