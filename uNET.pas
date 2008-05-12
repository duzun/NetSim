unit uNET;
{ Aici este encapsulat protocolul de comunicare }
interface
{-----------------------------------------------------------------------------}
uses
  Funcs, IOStreams, BufferCL, CmdByte,
  ExtCtrls, Classes;
{-----------------------------------------------------------------------------}
const
  c_BaudRate    = 200; // frames/sec    - Max = 250
{-----------------------------------------------------------------------------}
type
  TuNET = class(TIOStr)
     MaxAddr, MyAddr, LastAddr: byte;
     RCnter: word;
  private
    FTimer:    TTimer;

    SOnRead:   byte;
    SWriting:  boolean;

    FBaudRate, BaudCounter: word;
    SCicle:    word;

    FOwner:    TComponent;
    FID:       ShortString;
    FIDs:      packed array[0..254] of TBArray;

    p, len, tgt, src:  byte;
    cBuf: TBArray;

    procedure SetConected(const Value: boolean);
    function  GetConected: boolean;
    procedure SetBaud(Value: word);
    function  GetBaud: word;
    procedure SetID(const Value: ShortString);
    function getIDs(i: byte): TBArray;
    procedure SetIDs(i: byte; const Value: TBArray);
  public
    property ID:ShortString read FID write SetID;
    property IDs[i: byte]:TBArray read getIDs write SetIDs;
    property BaudRate: word    read GetBaud     write SetBaud;
    property Conected: boolean read GetConected write SetConected;
    constructor Create(AOwner: TComponent; FileName: ShortString = '');

    function Conect(FileName: ShortString = ''): boolean;
    function Disconect(): boolean;

    procedure ReadISO;
    procedure OnRead(var State: byte);

    function SendCmd(Cmd: byte; tgt: byte = ToAll): boolean;
    function SendData(data: TBArray; tgt: byte = ToAll): boolean;
    function Send(cmd: byte; data: TBArray; tgt: byte = ToAll): boolean;
    function ListSendCmd(Cmd: byte; tgt: TBArray): boolean;
    function ListSendData(data: TBArray; tgt: TBArray): boolean;
    function ListSend(cmd: byte; data: TBArray; tgt: TBArray): boolean;

    Procedure TimerProc(Sender: TObject);
   end;
{-----------------------------------------------------------------------------}
var
   IO: TuNET;
implementation
uses
   SysUtils;
{-----------------------------------------------------------------------------}
{ TuNET }
{-----------------------------------------------------------------------------}
constructor TuNET.Create;
begin
  inherited Create(FileName);
  FOwner     := AOwner;
  MaxAddr    := $0;
  MyAddr     := $0;
  LastAddr   := $0;
  BaudCounter:= 0;
  SWriting   := false;
  SCicle     := 0;
  BaudRate   := c_BaudRate;
  SetLength(cBuf, 0);

  FTimer          := TTimer.Create(AOwner);
  FTimer.Interval := 1;
  FTimer.Enabled  := false;
  FTimer.OnTimer  := TimerProc;

  Conected := false;
end;
{-----------------------------------------------------------------------------}
function TuNET.Conect(FileName: ShortString=''): boolean;
var w: Word;
begin
  if FileName = '' then FileName := FN;
  if Conected and (FileName = FN) then Result:=true
  else if (MkFile(FileName) and IO_OK <> 0) then begin
     Opened:=true;
     SOnRead := 0;
     repeat DecodeTime(Time, w, w, w, w); until w<10;
     Result    := true;
     Conected  := true;
  end else Result := false;
end;
{-----------------------------------------------------------------------------}
function TuNET.Disconect: boolean;
begin
  if Conected then begin
    if WSBuf.ready<>0 then Result:=false
    else begin
      Opened    := false;
      Conected  := false;
      MyAddr    := 0;
      Result    := true;
    end;
  end else Result:=true;
end;
{-----------------------------------------------------------------------------}
procedure TuNET.SetID(const Value: ShortString);
begin
  if Value = FID then exit;
  Send(cmd_readID or cmd_OK, Str2BAr(Value));
  FID := Value;
  if MyAddr <> 0 then FIDs[MyAddr]:=  Str2BAr(Value);
end;
{-----------------------------------------------------------------------------}
function  TuNET.GetBaud: word;        begin Result := 500 div FBaudRate; end;
procedure TuNET.SetBaud(Value: word); begin FBaudRate := 500 div Value;  end;
{-----------------------------------------------------------------------------}
function TuNET.GetConected: boolean;
  begin  Result := Opened and FTimer.Enabled; end;
{-----------------------------------------------------------------------------}
procedure TuNET.SetConected(const Value: boolean);
  begin  if (not Value)or(Value and(Opened or Conect))then FTimer.Enabled := Value; end;
{-----------------------------------------------------------------------------}
function TuNET.SendData;
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
function TuNET.SendCmd; begin  Result:=SendData(GenBAr(Cmd,0,1), tgt); end;
{-----------------------------------------------------------------------------}
function TuNET.Send;
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
function TuNET.ListSendCmd(Cmd: byte; tgt: TBArray): boolean;
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
function TuNET.ListSendData(data, tgt: TBArray): boolean;
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
function TuNET.ListSend(cmd: byte; data, tgt: TBArray): boolean;
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
procedure TuNET.ReadISO;
var rez: word;
begin
  ReadSBuf;
  p:=0;
  if LastRStat = IO_OK then begin
    rez := ISOSplit(RBAr, p, len, src, tgt);
    if (src<>ToAll)and(src > MaxAddr) then MaxAddr := src;
    if (tgt<>ToAll)and(tgt > MaxAddr) then MaxAddr := tgt;
  end else begin
    len:=0;
    src:=0;
  end;
end;
{-----------------------------------------------------------------------------}
procedure TuNET.OnRead;
var i:  byte;
    rez: word;
begin
    case LastRStat of
     IO_Failed: State:=0;
     IO_NoData: ;
     IO_OK:     ;
    end;
  case State of
  0:begin    // Initiere
    RCnter:=4;
    case LastRStat of
     IO_OK:     State:=1;
     IO_NoData: State:=2;
     IO_Failed: exit; // Mai citeste o data
    end;
  end;
  1:begin  // Conect
    dec(RCnter);
    case LastRStat of
     IO_OK:     State:=3;
     IO_NoData: if(RCnter=0)then State:=2 else exit;
     IO_Failed: {???};
    end;
    OnRead(State);
  end;
  2:begin  // Nobody is online
    MaxAddr := $01;
    MyAddr  := $01;
    State   := 5;
  end;
  3:begin  // Wait for Addr
    if(LastRStat=IO_OK)then
      if(src=$01)and(tgt=$00)and(len>0)then
        case RBAr[p] of
          cmd_tellMe: begin
             SendCmd(cmd_giveAddr, src);
             SWriting:=true;
          end;
          cmd_OK or cmd_giveAddr:begin MyAddr:=RBAr[p+1]; State:=4;end;
        end
  end;
  4:begin    // Tell that I'm present
    if(LastRStat=IO_OK)then
      if(src<>MyAddr)and((tgt=$00)or(tgt=MyAddr))and(len>0)then
        case RBAr[p] of
          cmd_tellMe: begin
            SendCmd(cmd_start, ToAll);
            SWriting:=true;
            State:=5;
          end;
          cmd_isPresent:begin SendCmd(cmd_OK or cmd_isPresent,src);end;
        end
  end;
  5:begin  // Reading data
    if(LastRStat=IO_OK)then begin
      if((src<>MyAddr)and(tgt=MyAddr)or(tgt=ToAll))and(len>0)then
      case RBAr[p] of   // parsing commands
        cmd_isPresent: SendCmd(RBAr[p] or cmd_OK, src);
        cmd_start: if MaxAddr+1=src then inc(MaxAddr);
        cmd_stop: begin
           if MyAddr=MaxAddr then begin
              MyAddr:=src;
              SendCmd(cmd_readID);
           end else if MyAddr=$01 then begin
              Send(cmd_giveAddr or cmd_OK, GenBAr(src,0,1), MaxAddr);
           end;
           dec(MaxAddr);
        end;
        cmd_giveAddr:begin
            inc(MaxAddr);
            Send(cmd_giveAddr or cmd_OK, GenBAr(MaxAddr,0,1), src);
        end;
        cmd_write:   begin
            lBAr := Copy(RBAr,p,len);
            setLength(lBAr, len+1);
            lBAr[len]:=src;
            RSBuf.Each := lBAr;
        end;
        cmd_tellMe:begin
            SWriting:=true;
            dec(SCicle, SCicle and 1);
        end;

        cmd_OK or cmd_giveAddr:MyAddr:=RBAr[p+1];
        cmd_OK or cmd_readID: IDs[src]:=Copy(RBAr,p+1,len-1);
        else
      end;
    end;
  end;
  else
     if LastRStat = IO_OK then begin
        RSBuf.Each := RBAr;
     end;
  end;
end;
{-----------------------------------------------------------------------------}
procedure TuNET.TimerProc(Sender: TObject);
begin
   if(BaudCounter = 0)then begin { Reading }
      ReadISO;          // --- Data reding  ---
      OnRead(SOnRead); // --- Data parsing ---
      inc(SCicle);    // --- new Cicle    ---
      BaudCounter := FBaudRate shl 1; // renew counter
   end else begin
     if(BaudCounter = FBaudRate)then { Writing }
     if(SWriting)then begin // --- Have right to write  ---
       WriteSBuf;          // --- Data writing           ---
       SWriting:=false;   // --- Can write only one frame ---
     end else           { $01 is DJ, Boss }
     if(MyAddr=$01)and(SCicle and 1 = 0)then begin
        inc(LastAddr);     // Who can write?
        if LastAddr > MaxAddr then LastAddr:=0;
        if LastAddr <> MyAddr then begin
          SetLength(lBAr,3);
          lBAr[0]:=cmd_tellMe;
          lBAr[1]:=lo(SCicle);
          lBAr[2]:=hi(SCicle);
          SendData(lBAr, LastAddr);
        end;
        WriteSBuf;
     end;
     dec(BaudCounter);
   end;
end;
{-----------------------------------------------------------------------------}
function TuNET.getIDs(i: byte): TBArray;
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
procedure TuNET.SetIDs(i: byte; const Value: TBArray);
begin
  if (i=ToAll) then exit;
  if (i = MyAddr)and(i<>0) then ID := BAr2Str(Value)
  else FIDs[i]:= Value;
end;
{-----------------------------------------------------------------------------}
end.
