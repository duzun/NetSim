unit Unit1;

interface

uses
  Funcs, BufferCL, IOStreams,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ActnList, ExtCtrls;

type

  TForm1 = class(TForm)
    Edit2: TEdit;
    Label2: TLabel;
    Button2: TButton;
    Memo1: TMemo;
    Edit3: TEdit;
    Label3: TLabel;
    Button3: TButton;
    ActionList1: TActionList;
    Button4: TButton;
    Timer1: TTimer;
    Memo2: TMemo;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
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
    Timer1.Enabled := false;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.Timer1Timer(Sender: TObject);
begin
  if IO.RBuf.ready > 0 then Memo2.Text := Memo2.Text + IO.RBuf.SReadReady;

end;
{-----------------------------------------------------------------------------}
procedure TForm1.Button3Click(Sender: TObject);
begin
//    Memo1.Text:= inttostr(BeginThread(nil,0,@thr, @Buf, 0, th));
     Timer1.Enabled := true;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
 IO.Conect(Edit2.Text);
end;

procedure TForm1.Button2Click(Sender: TObject);
var FN: String;
begin
  FN := Edit2.Text;
  if PromptForFileName(FN, '(str)|*.str|(txt)|*.txt','*.str', 'Chose a streaming file', '', True) then
      Edit2.Text := FN;

end;
{-----------------------------------------------------------------------------}
procedure TForm1.Button4Click(Sender: TObject);
var bs: ByteStr;
    ba: TBArray;
    s, s1: String;
    i: integer;
begin
  s:='';
  s1:='';

  ba := toISO(Memo1.Text, 1, 2);
  IO.WriteFrame(ba);
  exit;
  for i:=0 to length(bs)-1 do s:=s+byte2str(bs[i],' ');
  for i:=1 to length(Memo1.Text) do s1:=s1+byte2str(ord(Memo1.Text[i]), ' ');
  Memo2.Text:=s;
  memo1.Lines.Append(s1);
end;

end.

