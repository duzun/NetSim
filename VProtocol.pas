unit VProtocol;
{ II Nivel: transportul de date }
interface
{-----------------------------------------------------------------------------}
uses
  Funcs, IOStreams, CmdByte,
  ExtCtrls, Classes;
{-----------------------------------------------------------------------------}
const
  c_BaudRate    = 500; // frames/sec : Max = 500
  c_Reading     = $1;
  c_Writing     = $2;
{-----------------------------------------------------------------------------}
type
{ Class baza pentru protocoalele de comunicare }
  TVProtocol = class(TIOStr)
    MaxAddr, MyAddr: byte; 
  private
    FBaudRate: word;
    RWState:   byte;
    FID:       ShortString;
    FIDs:      packed array[0..254] of TBArray;
    FOnTimer:  TNotifyEvent;
    function  GetConected: boolean;
    function  GetIDs(i: byte): TBArray;
    function  GetBaud: word;
    function  GetReading: boolean;
    function  GetWriting: boolean;
    procedure SetConected(const Value: boolean);
    procedure SetID(const Value: ShortString);
    procedure SetIDs(i: byte; const Value: TBArray);
    procedure SetBaud(Value: word);
    procedure SetReading(const Value: boolean);
    procedure SetWriting(const Value: boolean);
    procedure SetOnTimer(const Value: TNotifyEvent);
  protected
    FTimer:    TTimer;
    FOwner:    TComponent;

//     p, len, tgt, src:  byte;
    BaudCounter:  word;
    CycleCounter: word;

  public
    property OnTimer: TNotifyEvent read FOnTimer write SetOnTimer;
    property ID:ShortString read FID write SetID;
    property IDs[i: byte]:TBArray read GetIDs write SetIDs;
    property BaudRate: word    read GetBaud     write SetBaud;
    property Conected: boolean read GetConected write SetConected;
    property Reading:  boolean read GetReading  write SetReading;
    property Writing:  boolean read GetWriting  write SetWriting;

    constructor Create(AOwner: TComponent; FileName: ShortString = '');

    function Conect(FileName: ShortString = ''): boolean;
    function Disconect(): boolean;

    function getBaudCount():  longword;
    function getCycleCount(): longword;
    procedure ResetCycleCount();
    
    function SendCmd(Cmd: byte; tgt: byte = ToAll): boolean;
    function SendData(data: TBArray; tgt: byte = ToAll): boolean;
    function Send(cmd: byte; data: TBArray; tgt: byte = ToAll): boolean;
    function ListSendCmd(Cmd: byte; tgt: TBArray): boolean;
    function ListSendData(data: TBArray; tgt: TBArray): boolean;
    function ListSend(cmd: byte; data: TBArray; tgt: TBArray): boolean;

    procedure OnConect();    virtual;
    procedure OnDisconect(); virtual;
    Procedure TimerProc(Sender: TObject);
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
  RWState    := 0;
  OnTimer    := nil;
  BaudRate   := c_BaudRate;
  
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
  else if Open(FileName) then begin
     BaudCounter  := 0;
     CycleCounter := 0;
     Reading      := true;
     Opened       := true;
     OnConect();
     repeat DecodeTime(Time, w, w, w, w); until w<10; // time alignment
     Result       := true;
     Conected     := true;
  end else Result := false;
end;
{-----------------------------------------------------------------------------}
function TVProtocol.Disconect: boolean;
begin
  if Conected then begin
    if WSBuf.ready<>0 then Result:=false
    else begin
      Conected  := false;
      Opened    := false;
      MyAddr    := 0;
      RWState   := 0;
      Result    := true;
      OnDisconect();
    end;
  end else Result:=true;
end;
{-----------------------------------------------------------------------------}
function  TVProtocol.GetConected: boolean;  begin Result := Opened and FTimer.Enabled; end;
procedure TVProtocol.SetConected(const Value: boolean);
begin  
   if (not Value)or(Value and(Opened or Conect()))then
      FTimer.Enabled := Value;
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
      r:= GenBAr(ord('<'),0,4); // r[0]:=ord('<');
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
procedure TVProtocol.OnDisconect;begin end;
procedure TVProtocol.OnConect;begin end;
{-----------------------------------------------------------------------------}
function TVProtocol.GetReading: boolean;begin Result := RWState and c_Reading <> 0; end;
function TVProtocol.GetWriting: boolean;begin Result := RWState and c_Writing <> 0; end;
{-----------------------------------------------------------------------------}
procedure TVProtocol.SetReading(const Value: boolean);
begin
   if (Value) then RWState := c_Reading
   else RWState := RWState and c_Writing;  
end;
{-----------------------------------------------------------------------------}
procedure TVProtocol.SetWriting(const Value: boolean);
begin
   if (Value) then RWState := c_Writing
   else RWState := RWState and c_Reading;  
end;
{-----------------------------------------------------------------------------}
function  TVProtocol.GetBaud: word;        begin Result    := 1000 div FBaudRate; end;
procedure TVProtocol.SetBaud(Value: word); begin FBaudRate := 1000 div Value;     end;
{-----------------------------------------------------------------------------}
function TVProtocol.getBaudCount;  begin Result := BaudCounter;  end;
function TVProtocol.getCycleCount; begin Result := CycleCounter; end;
procedure TVProtocol.ResetCycleCount;begin CycleCounter := CycleCounter and $3; end;
{-----------------------------------------------------------------------------}
procedure TVProtocol.TimerProc(Sender: TObject);
begin
   if(BaudCounter = 0)then begin
     if(Reading) then ReadSBuf  else    // --- Data reading  ---
     if(Writing) then WriteSBuf else    // --- Data writing  ---
                                ; 
     BaudCounter := FBaudRate;  // renew counter
     OnTimer(Self);            // --- Data parsing ---
     inc(CycleCounter);        // Cycles from connection
   end else begin
     dec(BaudCounter);
   end;
end;
{-----------------------------------------------------------------------------}
procedure TVProtocol.SetOnTimer(const Value: TNotifyEvent); begin FOnTimer := Value; end;
{-----------------------------------------------------------------------------}
end.
