unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ActnList, Funcs;

type

  TForm1 = class(TForm)
    Edit1: TEdit;
    Label1: TLabel;
    Edit2: TEdit;
    Label2: TLabel;
    Button1: TButton;
    Button2: TButton;
    Memo1: TMemo;
    Edit3: TEdit;
    Label3: TLabel;
    Button3: TButton;
    ActionList1: TActionList;
    OpenStream: TAction;
    OpenAddres: TAction;
    Button4: TButton;
    Edit4: TEdit;
    Label4: TLabel;
    procedure OpenStreamExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OpenAddresExecute(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    PFStr: PMyStr;
    PAStr: PMyStr;
    Addr: array of byte;    
  end;

var
  Form1: TForm1;
{-----------------------------------------------------------------------------}

implementation
{$R *.dfm}

{-----------------------------------------------------------------------------}
procedure TForm1.OpenStreamExecute(Sender: TObject);
var i: word;
    b: byte;
    buf: string;
begin
  if(OpenStr(PFStr, Edit2.Text, true)) then begin
      buf:='';
      for i:=1 to PFStr^.Size do begin
        PFStr^.Read(b, 1);
        buf := buf + byte2str(b);
      end;
      Memo1.Text := buf;
  end;
end;
{-----------------------------------------------------------------------------}
procedure TForm1.FormCreate(Sender: TObject);
begin
     OpenStreamExecute(self);
end;
{-----------------------------------------------------------------------------}
procedure TForm1.OpenAddresExecute(Sender: TObject);
begin
  if(OpenStr(PAStr, Edit1.Text, true)) then ;
end;

end.
{-----------------------------------------------------------------------------}
