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
     MaxAddr, MyAddr: byte;
     RCnter: word;
  private
    FTimer:    TTimer;
    SOnRead:   byte;
    SRSend:    byte;
    SWriting:  boolean;

    FBaudRate, BaudCounter: word;
    SCicle:    byte;

    FOwner:    TComponent;
    
    procedure SetConected(const Value: boolean);
    function  GetConected: boolean;
    procedure SetBaud(Value: word);
    function  GetBaud: word;
  public
    property BaudRate: word    read GetBaud     write SetBaud;
    property Conected: boolean read GetConected write SetConected;
    function CreateConection(FileName: ShortString): byte;
    constructor Create(AOwner: TComponent; FileName: ShortString = '');
    
    function Conect(FileName: ShortString): boolean;
    function Disconect(): boolean;

    procedure RSend(var State: byte);
    procedure OnRead(var State: byte);

    function SendCmd(Cmd: byte; tgt: byte = ToAll): boolean;
    function SendData(data: TBArray; tgt: byte = ToAll): boolean;
    function Send(cmd: byte; data: TBArray; tgt: byte = ToAll): boolean;

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
  MaxAddr    := 0; // Reading
  MyAddr     := 0;
  BaudCounter:= 0;
  SWriting   := false;
  SCicle     := 0;
  BaudRate   := c_BaudRate;

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
function TuNET.Conect(FileName: ShortString): boolean;
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
  if (tgt<>ToAll) and (tgt>MaxAddr) then exit;

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
procedure TuNET.RSend(var State: byte);
begin
 if SRSend <> State then begin
   SRSend:=State;
   case State of
     4:SendCmd(testPresent, ToAll);
     5:;
     else
   end;
 end;
end;
{-----------------------------------------------------------------------------}
procedure TuNET.OnRead;
var i, len, p, tgt, src:  byte;
    rez: word;
begin
  p:=0;
  case State of
  0:begin    // Initiere
    RCnter:=4;
    case LastRStat of
     IO_Failed: exit; // Mai citeste o data
     IO_NoData: State:=2;
     IO_OK:     State:=1;
    end;
    State := 1;
  end;
  1:begin  // Conect
    dec(RCnter);
    if(LastRStat=IO_OK)then State:=3
    else if(RCnter=0)then State:=2
    else exit;
    OnRead(State);
  end;
  2:begin  // Nobody is online
    MaxAddr := $FF;
    MyAddr  := $01;
    State   := 4;
  end;
  3:begin  // Wait for chanel to be free
    if(LastRStat=IO_NoData)then begin
       State:=4;
       RSend(State);
       SWriting := true;
    end else if(LastRStat=IO_OK)then begin
       ISOSplit(RBAr, p, len, src, tgt);

    end;;
  end;
  4:begin  // GetAddr
    ISOSplit(RBAr, p, len, src, tgt);
    if(tgt=0)and(len>0)and(RBAr[p]=testPresent or AnswerAdd) then begin
       MyAddr:=src+1;
    end;
           State := 5;
  end;
  5:begin  // Start comunication
    State:=10;
  end;
  10:begin  // Read all
   if LastRStat = IO_OK then begin
    ISOSplit(RBAr, p, len, src, tgt);
    if(src<>MyAddr)and((tgt=ToAll)or(tgt=MyAddr))and(len>0)then begin
      case RBAr[p] of
        testPresent: SendCmd(testPresent or AnswerAdd, src);
        writeData:   begin
            lBAr := Copy(RBAr,p,len);
            setLength(lBAr, len+1);
            lBAr[len]:=src;
            RSBuf.Each := lBAr;
        end;
      end;
    end;
   end else SWriting:=true;
  end;
  11:begin  // Have to tell

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
    if(BaudCounter = 0)then begin
    // --- Data reding ---
      ReadSBuf;
      OnRead(SOnRead);
      RSend(SOnRead);
      inc(SCicle);
    // --- //
      BaudCounter := FBaudRate shl 1;
    end else begin
      if(BaudCounter = FBaudRate)then
      if(SWriting)then begin
//      if(SCicle and 1 = 0)then begin
    // --- Data writing ---
       WriteSBuf;
       SWriting:=false;
    // --- //
//      end else begin      end;
      end;
      dec(BaudCounter);
    end;
end;
{-----------------------------------------------------------------------------}
end.
