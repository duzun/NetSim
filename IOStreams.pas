unit IOStreams;

interface
uses
  BufferCl, StrStackCl, Funcs,
  ExtCtrls, Classes;
{-----------------------------------------------------------------------------}
const
  ToAll     = $FF;
  PingByte  = $3E;
  AnswerAdd = $40;
  c_BaudRate= 100; // bytes/sec

  OK      = $01;
  Already = $02;
  Failed  = $04;

type
{-----------------------------------------------------------------------------}
  TIOStr = object
    StrBuf:     TStrStack;   // Stack for writing
    WBuf, RBuf: TBuffer;     // Write and Read buffers
    BBuf:       TBArray;
  private
    FTimer:    TTimer;

    FBaudRate, BaudCounter: word;
    FDestAddr, FMyAddr: byte;
    CHC:       byte;
    RB:        byte;
    TMPB:      byte;
    FCounter:  IndexType;
    F:         BFile;
    FN:        ShortString; // Conection FileName
    FOwner:    TComponent;

    function  Add2WBuf: IndexType;
    procedure SetReading(const Value: boolean);
    function  GetReading: boolean;
    procedure SetConected(const Value: boolean);
    function  GetConected: boolean;
    procedure SetBaud(Value: word);
    function  GetBaud: word;
  public
    property BaudRate: word    read GetBaud     write SetBaud;
    property Reading:  boolean read GetReading  write SetReading;
    property Conected: boolean read GetConected write SetConected;
    function CreateConection(FileName: ShortString): byte;

    Procedure TimerProc(Sender: TObject);
    constructor Create(AOwner: TComponent; FileName: ShortString = '');
    function Conect(FileName: ShortString): boolean;
    function Disconect(): boolean;

    function WriteByte(b: byte): word;
    function ReadByte(var b: byte): word;
    function WriteFrame(fr: TBArray): boolean;
    procedure OnRead;
    procedure OnWrite;
    function SendMsg(s: String; Addr: byte): boolean;
  end;
{-----------------------------------------------------------------------------}
var
   IO: TIOStr;
   Buf: TBuffer;
{-----------------------------------------------------------------------------}
procedure TProc(var IOs: TIOStr);
{-----------------------------------------------------------------------------}
implementation
uses SysUtils,
      Unit1;
{-----------------------------------------------------------------------------}
{ TIOStr }
constructor TIOStr.Create;
begin
  FOwner     := AOwner;
  FDestAddr  := 0; // Reading
  FMyAddr    := 0;
  FCounter   := 0;
  BaudCounter:= 0;
  CHC        := 0; 
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
  else if (CreateConection(FileName) and OK <> 0) then begin
     AssignFile(f, FileName);
     Reset(f);
     Reading   := true;

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
  FMyAddr   := 0;
  Result    := true;
end;
{-----------------------------------------------------------------------------}
function TIOStr.CreateConection(FileName: ShortString): byte;
begin                                 
  if FileName = '' then FileName := FN;
  if FileName = '' then Result := Failed
  else if FileExists(FileName)then begin
    Result := Already or OK;
  end else try
    AssignFile(f, FileName);
    Result := OK;
    try    ReWrite(f);
    except Result := Failed;
    end;
  finally  CloseFile(f);
  end;
end;
{-----------------------------------------------------------------------------}
function  TIOStr.GetBaud: word;        begin Result := 1000 div FBaudRate; end;
procedure TIOStr.SetBaud(Value: word); begin FBaudRate := 1000 div Value;  end;
{-----------------------------------------------------------------------------}
function  TIOStr.GetReading; begin  Result:= FDestAddr = 0; end;
procedure TIOStr.SetReading; begin  if (Value) then FDestAddr := 0; end;
{-----------------------------------------------------------------------------}
function TIOStr.GetConected: boolean; begin  Result := FTimer.Enabled; end;
{-----------------------------------------------------------------------------}
procedure TIOStr.SetConected(const Value: boolean);
begin
  FTimer.Enabled := Value;
  if not Value then begin

  end;
end;
{-----------------------------------------------------------------------------}
function TIOStr.WriteByte(b: byte): word;
begin
  Result:=0;
  {$I-}
  repeat
      Seek(f, 0);
      write(f, b);
  until IOResult = 0;
  {$I+}
  Result:=1;
end;
{-----------------------------------------------------------------------------}
function TIOStr.ReadByte(var b: byte): word;
begin
    Result := 0;
    {$I-}
    if FileSize(f)=0 then b:=0
    else begin
      repeat
        Seek(f, 0);
        read(f, b);
      until IOResult = 0;
      Result:=1;
    end;
    {$I+}
end;
{-----------------------------------------------------------------------------}
function TIOStr.WriteFrame;
begin
  if StrBuf.Write(fr) then begin
  //  WBuf.Buf := fr;
    FDestAddr := 48;
    Result   := true;
  end else Reading  := false;
end;
{-----------------------------------------------------------------------------}
procedure TIOStr.OnRead;
var i, len, p:  byte;
    rez: word;
begin
    RBuf.Each  := RB;
    i := RBuf.OnlyRead(BBuf);
    p := 0;
    repeat
      rez := ISOSplit(@BBuf, p, len);
      if rez and WrongLen <> 0 then exit;
      if rez = WrongData then inc(p);
    until rez = 0;

end;
{-----------------------------------------------------------------------------}
procedure TIOStr.OnWrite;
begin

end;
{-----------------------------------------------------------------------------}
procedure TIOStr.TimerProc(Sender: TObject);
var T: LongWord;
begin
    if (BaudCounter = 0) then begin
//    BeginThread(nil, 0, @TProc, @Self, 0, T); //   TProc(Self);

  if Reading then begin
    if ReadByte(RB)<>0 then OnRead;
  end else begin
    if WriteByte(WBuf.Each) = 0 then Reading := true;
    if FCounter = 0 then FCounter:=Add2WBuf
    else dec(FCounter);
  end;

      BaudCounter := FBaudRate;
    end else begin
       dec(BaudCounter);
    end;

end;
{-----------------------------------------------------------------------------}
function TIOStr.Add2WBuf: IndexType;
var t: TBArray;
begin
  if StrBuf.Read(t) then begin
    Result := Length(t);
    WBuf.Buf := t;
  end else begin
    Result := 0;
  end;
end;
{-----------------------------------------------------------------------------}
function TIOStr.SendMsg;
begin
  
end;
{-----------------------------------------------------------------------------}
procedure TProc(var IOs: TIOStr);
var b: byte;
begin
  with IOs do
  if Reading then begin
    if ReadByte(b)<>0 then
    RBuf.Each  := b;
  end else begin
    if WriteByte(WBuf.Each) = 0 then Reading := true;
    if FCounter = 0 then FCounter:=Add2WBuf
    else dec(FCounter);
  end;
end;
{-----------------------------------------------------------------------------}
end.
