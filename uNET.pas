unit uNET;

interface
{-----------------------------------------------------------------------------}
uses
  Funcs, IOStreams, BufferCL,
  ExtCtrls, Classes;
{-----------------------------------------------------------------------------}
const
  ToAll     = $FF;
  AnswerAdd = $40;

  c_BaudRate    = 250; // frames/sec    - Max = 250
{-----------------------------------------------------------------------------}
type
  TuNET = class(TIOStr)
     MaxAddr, MyAddr, LastAddr: byte;
     RCnter: word;
  private
    FTimer:    TTimer;
    SOnRead:   byte;
    SRSend:    byte;
    SWriting:  boolean;

    FBaudRate, BaudCounter: word;
    SCicle:    word;

    FOwner:    TComponent;
    FID:       ShortString;
    FIDs:      packed array[1..254] of TBArray;
    
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
    function CreateConection(FileName: ShortString): byte;
    constructor Create(AOwner: TComponent; FileName: ShortString = '');

    function Conect(FileName: ShortString = ''): boolean;
    function Disconect(): boolean;

    procedure ReadISO;
    procedure OnRead(var State: byte);

    function SendCmd(Cmd: byte; tgt: byte = ToAll): boolean;
    function SendData(data: TBArray; tgt: byte = ToAll): boolean;
    function Send(cmd: byte; data: TBArray; tgt: byte = ToAll): boolean;
    function ListSend(cmd: byte; data: TBArray; tgt: TBArray): boolean;

    Procedure TimerProc(Sender: TObject);
   end;
{-----------------------------------------------------------------------------}
var
   IO: TuNET;
implementation
uses
   CmdByte, SysUtils;
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
function TuNET.CreateConection(FileName: ShortString): byte;
begin
  if FileName = '' then FileName := FN;
  if FileName = '' then Result := IO_Failed
  else if FileExists(FileName)then begin
    Result := IO_Already or IO_OK;
  end else try
    AssignFile(f, FileName);
    Result := IO_OK;
    try    ReWrite(f);
    except Result := IO_Failed;
    end;
  finally  CloseFile(f);
  end;
end;
{-----------------------------------------------------------------------------}
function TuNET.Conect(FileName: ShortString=''): boolean;
var w: Word;
begin
  if FileName = '' then FileName := FN;
  if Conected and (FileName = FN) then Result:=true
  else if (CreateConection(FileName) and IO_OK <> 0) then begin
     AssignFile(f, FileName);
     Reset(f);
//     Reading   := true;
     SOnRead := 0;
     SRSend  := 0;

     repeat DecodeTime(Time, w, w, w, w); until w<10;
     Result    := true;
     Conected  := true;

  end else Result := false;
end;
{-----------------------------------------------------------------------------}
function TuNET.Disconect: boolean;
begin
//bufering...
  if Conected then CloseFile(f);
  Conected  := false;
  MyAddr    := 0;
  Result    := true;
end;
{-----------------------------------------------------------------------------}
procedure TuNET.SetID(const Value: ShortString);
begin
  if Value = FID then exit;
  Send(cmd_readID or AnswerAdd, Str2BAr(Value));
  FID := Value;
end;
{-----------------------------------------------------------------------------}
function  TuNET.GetBaud: word;        begin Result := 250 div FBaudRate; end;
procedure TuNET.SetBaud(Value: word); begin FBaudRate := 500 div Value;  end;
{-----------------------------------------------------------------------------}
function TuNET.GetConected: boolean; begin  Result := FTimer.Enabled; end;
procedure TuNET.SetConected(const Value: boolean);begin FTimer.Enabled := Value; end;
{-----------------------------------------------------------------------------}
function TuNET.SendData;
var p, l: word;
begin
  Result := false;
//  if (tgt<>ToAll) then exit;

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
//    if (src<>ToAll)and(src > MaxAddr) then MaxAddr := src;
    if (tgt<>ToAll)and(tgt > MaxAddr) then
     MaxAddr := tgt;
     rez:=rez;
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
          AnswerAdd or cmd_giveAddr:begin MyAddr:=RBAr[p+1]; State:=4;end;
        end
  end;
  4:begin    // Tell that I'm present
    if(LastRStat=IO_OK)then
      if(src=$01)and((tgt=$00)or(tgt=MyAddr))and(len>0)then
        case RBAr[p] of
          cmd_tellMe: begin
            SendCmd(startCommunication, $01);
            SWriting:=true;
            State:=5;
          end;
          testPresent:begin SendCmd(AnswerAdd or testPresent,src);end;
        end
  end;
  5:begin  // Reading data
    if(LastRStat=IO_OK)then begin
      if(src<>MyAddr)and((tgt=ToAll)or(tgt=MyAddr))and(len>0)then
      case RBAr[p] of   // parsing commands
        testPresent: SendCmd(RBAr[p] or AnswerAdd, src);
        startCommunication: if MaxAddr+1=src then inc(MaxAddr);
        stopCommunication:  if src=MaxAddr then dec(MaxAddr)
                            else begin
                              if MyAddr=$01 then begin
                                Send(AnswerAdd or cmd_giveAddr, GenBAr(src,0,1), MaxAddr);
                                SendCmd(cmd_readID,src);
                                dec(MaxAddr);
                              end;
                            end;
        cmd_giveAddr:begin
            inc(MaxAddr);
            Send(RBAr[p] or AnswerAdd, GenBAr(MaxAddr,0,1), src);
        end;
        writeData:   begin
            lBAr := Copy(RBAr,p,len);
            setLength(lBAr, len+1);
            lBAr[len]:=src;
            RSBuf.Each := lBAr;
        end;
        cmd_tellMe:SWriting:=true;

        AnswerAdd or cmd_giveAddr:MyAddr:=RBAr[p+1];
        AnswerAdd or cmd_readID: IDs[src]:=Copy(RBAr,p+1,len-1);
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
begin
  if (i=0) or (i=ToAll) then result:=GenBAr(0,0,0)
  else result:=FIDs[i];
end;
{-----------------------------------------------------------------------------}
procedure TuNET.SetIDs(i: byte; const Value: TBArray);
begin
  if (i=0) or (i=ToAll) then exit
  else FIDs[i]:= Value;
end;
{-----------------------------------------------------------------------------}

end.
