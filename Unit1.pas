unit Unit1;

interface

uses
  Funcs, BufferCL, IOStreams,
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
    Button6: TButton;
    AConect: TAction;
    ADisconect: TAction;
    ABrowse: TAction;
    Button2: TButton;
    AClearText: TAction;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure AConectExecute(Sender: TObject);
    procedure ADisconectExecute(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ABrowseExecute(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure AClearTextExecute(Sender: TObject);
  private
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
    IO.Create(Self, Edit2.Text);
    Button1Click(Sender);
    Timer1.Enabled := false;
    if ParamStr(1) <> 'DUzun' then
    begin
//       ShellExecute(0,'open', pchar(ParamStr(0)),'DUzun',nil,SW_SHOWNORMAL);
       Button3Click(Sender);
    end;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.Button4Click(Sender: TObject);
var ba: TBArray;
begin
//  ba := toISO(Memo1.Text, 1, 2);
  ba:= Str2BAr(Memo1.Text);
  IO.WriteFrame(ba);
end;
{-----------------------------------------------------------------------------}
procedure TForm1.Timer1Timer(Sender: TObject);
begin
  if IO.RBuf.ready  > 0 then Memo2.Text := Memo2.Text + IO.RBuf.SReadReady;
  if IO.Reading then Label1.Caption := 'Reading...'
                else Label1.Caption := 'Writeing';
end;
{-----------------------------------------------------------------------------}
procedure TForm1.Button3Click(Sender: TObject);
begin
  Timer1.Enabled := not Timer1.Enabled;
  if Timer1.Enabled then Button3.Caption := Button3.Caption + ' On'
                    else Button3.Caption := 'Timmer';
end;

{-----------------------------------------------------------------------------}
procedure TForm1.Button6Click(Sender: TObject);
begin
  IO.Reading := true;
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
//    w, ms: word;
//    D1, D2 : TDateTime;
    a, c: TBArray;
    r: string;
begin
setlength(a, 100);
for i:=0 to 99 do a[i]:=i;
a[0]:=0 or b_TgtSrc;
a[1]:=97;
a[3]:=95;
a[99]:=0;
p:=1;
for i:=0 to 98 do inc(a[99],a[i]);
if ISOSplit(@a, c, s, t)=0 then begin
  Memo2.Text:=inttostr(ISOSplit(@a, p, len));
  for i:=0 to length(c)-1 do r:=r+byte2str(c[i]);
  Memo1.Lines.Append(byte2str(s)+byte2str(t));
  Memo1.Lines.Append(r);
end;

{  for i:= 1 to Memo1.Lines.Count do IO.WriteFrame(Str2BAr(Memo1.Lines[i-1]));
  while(IO.StrBuf.ready<>0)do Memo2.Lines.Append(BAr2Str(IO.StrBuf.Each));

{
D1 := Time;
for i:=1 to 100000 do begin
  w:=IO.ReadByte(b);
  w:=IO.WriteByte(b);
  IO.RBuf.Each := b;
end;
D2 := Time;
Memo2.Text := TimeToStr(D2 - D1);
}
end;
{-----------------------------------------------------------------------------}

end.

