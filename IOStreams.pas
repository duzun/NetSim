unit IOStreams;

interface
uses
  BufferCl, StrStackCl, Funcs, CmdByte,
  ExtCtrls, Classes;
{-----------------------------------------------------------------------------}
const
  ToAll     = $FF;
  AnswerAdd = $40;
  
  c_BaudRate= 250; // frames/sec    - Max = 250
  c_MaxReadBuf = 512;

  IO_OK      = $01;
  IO_Already = $02;
  IO_Failed  = $04;
  IO_NoData  = $08;
  IO_WrongData = $10;

type
{-----------------------------------------------------------------------------}
  TIOStr = object

    WSBuf, RSBuf: TStrStack;  // Write and Read string buffers
    WBuf, RBuf: TBuffer;     // Write and Read buffers
    RBAr, WBAr, lBAr: TBArray;    // Byte Buffers
    RCnter: word;
    LastRStat, LastWStat: word;
    SChat :  TBArray;
    SChatI: word;

    MaxAddr, MyAddr: byte;
  private
    FTimer:    TTimer;
    SOnRead:   byte;
    SRSend:    byte;
    SWriting:  boolean;

    FBaudRate, BaudCounter: word;

    CHC:       byte;
    RB:        byte;
    TMPB:      byte;
    SCicle:    byte;
    FCounter:  IndexType;
    F:         BFile;
    FN:        ShortString; // Conection FileName
    FOwner:    TComponent;

    function  Add2WBuf: IndexType;
    procedure SetConected(const Value: boolean);
    function  GetConected: boolean;
    procedure SetBaud(Value: word);
    function  GetBaud: word;
  public
    property BaudRate: word    read GetBaud     write SetBaud;
    property Conected: boolean read GetConected write SetConected;
    function CreateConection(FileName: ShortString): byte;

    Procedure TimerProc(Sender: TObject);
    constructor Create(AOwner: TComponent; FileName: ShortString = '');
    function Conect(FileName: ShortString): boolean;
    function Disconect(): boolean;

    procedure WriteSBuf;
    procedure ReadSBuf;

    function WriteByte(b: byte; poz: byte = 0): word;
    function ReadByte(var b: byte; poz: byte = 0): word;

    procedure RSend(var State: byte);
    procedure OnRead(var State: byte);
    procedure OnWrite;

    function DoCmd: boolean;
    function SendCmd(Cmd: byte; tgt: byte = ToAll): boolean;
    function SendData(data: TBArray; tgt: byte = ToAll): boolean;
    function Send(cmd: byte; data: TBArray; tgt: byte = ToAll): boolean;
    function WriteFrame(fr: TBArray): boolean;
  end;
{-----------------------------------------------------------------------------}
var
   IO: TIOStr;
   Buf: TBuffer;
{-----------------------------------------------------------------------------}
implementation
uses SysUtils,
      Unit1;
{-----------------------------------------------------------------------------}
{ TIOStr }
constructor TIOStr.Create;
begin
  FOwner     := AOwner;
  MaxAddr    := 0; // Reading
  MyAddr     := 0;
  FCounter   := 0;
  BaudCounter:= 0;
  CHC        := 0;
  SWriting   := false;
  SCicle     := 0;
  BaudRate        := c_BaudRate;

  WBuf.Create;
  RBuf.Create(4096);

  FTimer          := TTimer.Create(AOwner);
  FTimer.Interval := 1;
  FTimer.Enabled  := false;
  FTimer.OnTimer  := TimerProc;

  Conected := false;
  FN := FileName;
end;
{-----------------------------------------------------------------------------}
function TIOStr.Conect(FileName: ShortString): boolean;
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
     SetLength(SChat, 255);
     SChat[0]:=0;
     SChatI := 0;

     repeat DecodeTime(Time, w, w, w, w); until w=0;
     Conected  := true;
     Result    := true;
  end else Result := false;
end;
{-----------------------------------------------------------------------------}
function TIOStr.Disconect: boolean;
begin
//bufering...
  if Conected then CloseFile(f);
  Conected  := false;
  MyAddr    := 0;
  Result    := true;
end;
{-----------------------------------------------------------------------------}
function TIOStr.CreateConection(FileName: ShortString): byte;
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
function  TIOStr.GetBaud: word;        begin Result := 2000 div FBaudRate; end;
procedure TIOStr.SetBaud(Value: word); begin FBaudRate := 500 div Value;  end;
{-----------------------------------------------------------------------------}
function TIOStr.GetConected: boolean; begin  Result := FTimer.Enabled; end;
{-----------------------------------------------------------------------------}
procedure TIOStr.SetConected(const Value: boolean);begin FTimer.Enabled := Value; end;
{-----------------------------------------------------------------------------}
procedure TIOStr.ReadSBuf;
var i: IndexType;
    l: Integer;
begin
{$I-}
    Seek(f, 0);
    l := FileSize(f);
    if l > c_MaxReadBuf then l := c_MaxReadBuf;
    i := 0;
    SetLength(lBAr, l);
    while(i<l)do begin
      read(f, lBAr[i]);
      if(IOResult <> 0) then begin LastRStat := IO_Failed; Exit; end;
      inc(i);
    end;
{$I+}
    if (l=0)or BArCmp(@RBAr, @lBAr{, 7}) then begin
      LastRStat := IO_NoData;
    end else begin
      RBAr := lBAr;
      LastRStat := IO_OK;
    end;
end;
{-----------------------------------------------------------------------------}
function TIOStr.DoCmd: boolean;
begin

end;
{-----------------------------------------------------------------------------}
procedure TIOStr.RSend(var State: byte);
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
procedure TIOStr.OnRead;
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
       SChat[SChatI]:=src;
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
        DoCmd;
     end;
  end;
end;
{-----------------------------------------------------------------------------}
procedure TIOStr.WriteSBuf;
var i, l: IndexType;
begin
  WBAr := WSBuf.Arrays[0];
  if (WSBuf.Success) then begin
{$I-}
    Seek(f, 0);
    l := Length(WBAr);
    i := 0;
    while(i<l)do begin
      write(f, WBAr[i]);
      if(IOResult <> 0) then begin LastWStat := IO_Failed; Exit; end;
      inc(i);
    end;
{$I+}
    LastWStat := IO_OK;
    WSBuf.IncR;
  end else begin
    LastWStat := IO_NoData;
  end;
end;
{-----------------------------------------------------------------------------}
function TIOStr.WriteByte;
begin
  Result:=0;
  {$I-}
  repeat
      Seek(f, poz);
      write(f, b);
  until IOResult = 0;
  {$I+}
  Result:=1;
end;
{-----------------------------------------------------------------------------}
function TIOStr.ReadByte;
begin
    Result := 0;
    {$I-}
    if FileSize(f)=0 then b:=0
    else begin
      repeat
        Seek(f, poz);
        read(f, b);
      until IOResult = 0;
      Result:=1;
    end;
    {$I+}
end;
{-----------------------------------------------------------------------------}
function TIOStr.WriteFrame;
begin
  WSBuf.Each := fr;
  Result := WSBuf.Success;
end;
{-----------------------------------------------------------------------------}
procedure TIOStr.OnWrite;
begin

end;
{-----------------------------------------------------------------------------}
procedure TIOStr.TimerProc(Sender: TObject);
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
       OnWrite;
       SWriting:=false;
    // --- //
//      end else begin      end;
      end;
      dec(BaudCounter);
    end;
end;
{-----------------------------------------------------------------------------}
function TIOStr.Add2WBuf: IndexType;
var t: TBArray;
begin
  if WSBuf.Read(t) then begin
    Result := Length(t);
    WBuf.Buf := t;
  end else begin
    Result := 0;
  end;
end;
{-----------------------------------------------------------------------------}
function TIOStr.SendData;
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
function TIOStr.SendCmd; begin  Result:=SendData(GenBAr(Cmd,0,1), tgt); end;
{-----------------------------------------------------------------------------}
function TIOStr.Send;
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

end.
