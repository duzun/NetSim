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
  c_BaudRate  = 30; // bytes/sec

  OK      = $01;
  Already = $02;
  Failed  = $04;

type
{-----------------------------------------------------------------------------}
  TIOStr = object
   StrBuf: TStrStack;   // Stack for writing
   WBuf, RBuf: TBuffer; // Write and Read buffers
  private
    FTimer:    TTimer;

    FBaudRate, BaudCounter: word;
    FDestAddr, FMyAddr: byte;
    FCounter:  IndexType;
    F:         BFile;
    FN: ShortString; // Conection FileName
    FOwner: TComponent;

    function Add2WBuf: IndexType;
    Procedure TimerProc(Sender: TObject);
    procedure SetReading(const Value: boolean);
    function GetReading: boolean;
    procedure SetConected(const Value: boolean);
    function GetConected: boolean;
    function GetBaud: word;
    procedure SetBaud(Value: word);
  public
    constructor Create(AOwner: TComponent; FileName: ShortString = '');
    property BaudRate: word read GetBaud write SetBaud;
    property Reading: boolean read GetReading write SetReading;
    property Conected: boolean read GetConected write SetConected;     
    function CreateConection(FileName: ShortString): byte;
    function Conect(FileName: ShortString): boolean;
    function Disconect(): boolean;

    function WriteByte(b: byte): word;
    function ReadByte(var b: byte): word;
    function WriteFrame(fr: TBArray): boolean;

    function SendMsg(s: String; Addr: byte): boolean;
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
  FDestAddr  := 0; // Reading
  FMyAddr    := 0;
  FCounter   := 0;
  BaudCounter:= 0;
  BaudRate   := c_BaudRate;
  
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
begin
  if FileName = '' then FileName := FN;
  if Conected and (FileName = FN) then begin
     Result:=true; exit;
  end else if (CreateConection(FileName) and OK <> 0) then begin
     AssignFile(f, FileName);
     Reset(f);
     Reading   := true;
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
function  TIOStr.GetBaud: word;        begin    Result := 1000 div FBaudRate; end;
procedure TIOStr.SetBaud(Value: word); begin    FBaudRate := 1000 div Value;  end;
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
  {$I+}
//  repeat
      Seek(f, 0);
      write(f, b);
//  until IOResult = 0;
  {$I+}
  Result:=1;
end;
{-----------------------------------------------------------------------------}
function TIOStr.ReadByte(var b: byte): word;
begin
    Result := 0;
    {$I+}
    if FileSize(f)=0 then b:=0
    else begin
//      repeat
        Seek(f, 0);
        read(f, b);
//      until IOResult = 0;
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
 // EndThread(1);
end;
{-----------------------------------------------------------------------------}
procedure TIOStr.TimerProc(Sender: TObject);
var T: LongWord;
begin
    if (BaudCounter = 0) then begin
 //     TProc(Self);
      BeginThread(nil, 0, @TProc, @Self, 0, T);
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

end.
