unit VProtocol;
{ II Nivel: transportul de date }
interface
{-----------------------------------------------------------------------------}
uses
  Funcs, IOStreams, BufferCL, CmdByte,
  ExtCtrls, Classes;
{-----------------------------------------------------------------------------}
const
  c_BaudRate    = 200; // frames/sec : Max = 250
{-----------------------------------------------------------------------------}
type
{ Class baza pentru protocoalele de comunicare }
  TVProtocol = class(TIOStr)
    MaxAddr, MyAddr: byte; 
  private
    FID:       ShortString;
    FIDs:      packed array[0..254] of TBArray;
    procedure SetBaud(Value: word);
    function  GetBaud: word;
    procedure SetID(const Value: ShortString);
    function  GetIDs(i: byte): TBArray;
    procedure SetIDs(i: byte; const Value: TBArray);
  protected
    FTimer:    TTimer;
    FOwner:    TComponent;
    FBaudRate: word;
    SWriting:  boolean;

    procedure SetConected(const Value: boolean);
    function  GetConected: boolean;
  public
    property ID:ShortString read FID write SetID;
    property IDs[i: byte]:TBArray read GetIDs write SetIDs;
    property BaudRate: word    read GetBaud     write SetBaud;
    property Conected: boolean read GetConected write SetConected;
    
    constructor Create(AOwner: TComponent; FileName: ShortString = '');

    function Conect(FileName: ShortString = ''): boolean;
    function Disconect(): boolean;

    function SendCmd(Cmd: byte; tgt: byte = ToAll): boolean;
    function SendData(data: TBArray; tgt: byte = ToAll): boolean;
    function Send(cmd: byte; data: TBArray; tgt: byte = ToAll): boolean;
    function ListSendCmd(Cmd: byte; tgt: TBArray): boolean;
    function ListSendData(data: TBArray; tgt: TBArray): boolean;
    function ListSend(cmd: byte; data: TBArray; tgt: TBArray): boolean;
                 
    procedure OnConect();    virtual;
    procedure OnDisconect(); virtual;
    Procedure TimerProc(Sender: TObject); virtual;
   end;
{-----------------------------------------------------------------------------}
implementation
uses
   SysUtils;
{-----------------------------------------------------------------------------}
{ TVProtocol }
{-----------------------------------------------------------------------------}
constructor TVProtocol.Create;
begin
  inherited Create(FileName);
  FOwner     := AOwner;
  MaxAddr    := $0;
  MyAddr     := $0;
  SWriting   := false;

  FTimer          := TTimer.Create(FOwner);
  FTimer.Interval := 1;
  FTimer.Enabled  := false;
  FTimer.OnTimer  := TimerProc;

  Conected := false;
end;
{-----------------------------------------------------------------------------}
function TVProtocol.Conect(FileName: ShortString=''): boolean;
var w: Word;
begin
  if FileName = '' then FileName := FN;
  if Conected and (FileName = FN) then Result:=true
  else if (MkFile(FileName) and IO_OK <> 0) then begin
     Opened    := true;
     repeat DecodeTime(Time, w, w, w, w); until w<10;
     Result    := true;
     Conected  := true;
     OnConect();
  end else Result := false;
end;
{-----------------------------------------------------------------------------}
function TVProtocol.Disconect: boolean;
begin
  if Conected then begin
    if WSBuf.ready<>0 then Result:=false
    else begin
      Opened    := false;
      Conected  := false;
      MyAddr    := 0;
      Result    := true;
      OnDisconect();
    end;
  end else Result:=true;
end;
{-----------------------------------------------------------------------------}
procedure TVProtocol.SetID(const Value: ShortString);
begin
  if Value = FID then exit;
  FID := Value;
  Send(cmd_readID or cmd_OK, Str2BAr(FID));
  if MyAddr <> 0 then FIDs[MyAddr] := Str2BAr(FID);
end;
{-----------------------------------------------------------------------------}
function  TVProtocol.GetBaud: word;        begin Result := 500 div FBaudRate; end;
procedure TVProtocol.SetBaud(Value: word); begin FBaudRate := 500 div Value;  end;
{-----------------------------------------------------------------------------}
function TVProtocol.GetConected: boolean;
  begin  Result := Opened and FTimer.Enabled; end;
{-----------------------------------------------------------------------------}
procedure TVProtocol.SetConected(const Value: boolean);
  begin  if (not Value)or(Value and(Opened or Conect))then FTimer.Enabled := Value; end;
{-----------------------------------------------------------------------------}
function TVProtocol.SendData;
var p, l: word;
begin
  Result := false;
  p:=0;
  l:=Length( data );
  while(p<l)do begin
    WSBuf.Each := ISOForm(data, p, MyAddr, tgt);
    // Overflow chk !!!
  end;
  Result := true;
end;
{-----------------------------------------------------------------------------}
function TVProtocol.SendCmd; begin  Result:=SendData(GenBAr(Cmd,0,1), tgt); end;
{-----------------------------------------------------------------------------}
function TVProtocol.Send;
var p,l: word;
begin
  l:=length(data);
  setlength(data, l+1);
  while l>0 do begin
    data[l]:=data[l-1];
    dec(l);
  end;
  data[0]:=cmd;
  Result := SendData(data, tgt);
end;
{-----------------------------------------------------------------------------}
function TVProtocol.ListSendCmd(Cmd: byte; tgt: TBArray): boolean;
var i:word;
    r: boolean;
begin
  i:=length(tgt);
  r:=true;
  while i>0 do begin
    dec(i);
    if not SendCmd(cmd, tgt[i]) then r:=false;;
  end;
  Result:=r;
end;
{-----------------------------------------------------------------------------}
function TVProtocol.ListSendData(data, tgt: TBArray): boolean;
var i:word;
    r: boolean;
begin
  i:=length(tgt);
  r:=true;
  while i>0 do begin
    dec(i);
    if not SendData(data, tgt[i]) then r:=false;;
  end;
  Result:=r;
end;
{-----------------------------------------------------------------------------}
function TVProtocol.ListSend(cmd: byte; data, tgt: TBArray): boolean;
var i:word;
    r: boolean;
begin
  i:=length(tgt);
  r:=true;
  while i>0 do begin
    dec(i);
    if not Send(cmd, data, tgt[i]) then r:=false;;
  end;
  Result:=r;
end;
{-----------------------------------------------------------------------------}
function TVProtocol.GetIDs(i: byte): TBArray;
var r: TBArray;
begin
  if (i=ToAll) then result:=GenBAr(0,0,0)
  else begin
    if length(FIDs[i])=0 then begin
      r:= GenBAr(ord('<'),0,4);
//      r[0]:=ord('<');
      r[1]:=ord(num2chr(i shr 4));
      r[2]:=ord(num2chr(i));
      r[3]:=ord('>');
      Result:=r;
    end else result:=FIDs[i];
  end;
end;
{-----------------------------------------------------------------------------}
procedure TVProtocol.SetIDs(i: byte; const Value: TBArray);
begin
  if (i=ToAll) then exit;
  if (i = MyAddr)and(i<>0) then ID := BAr2Str(Value)
  else FIDs[i]:= Value;
end;
{-----------------------------------------------------------------------------}
procedure TVProtocol.TimerProc(Sender: TObject);
begin  end;
{-----------------------------------------------------------------------------}
procedure TVProtocol.OnDisconect();begin end;
procedure TVProtocol.OnConect();begin end;
{-----------------------------------------------------------------------------}
end.
