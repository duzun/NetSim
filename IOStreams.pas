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
  BaudRate  = 100; // bytes/sec

  OK      = $01;
  Already = $02;
  Failed  = $04;

type
{-----------------------------------------------------------------------------}
  TIOStr = object
   StrBuf: TStrStack;
   WBuf, RBuf: TBuffer;
  private
    FTimer:     TTimer;


    FDestAddr: byte;
    FMyAddr:   byte;
    F:         BFile;
    FN: ShortString; // Conection FileName
    FPingActive: Boolean;
    FConected: Boolean;

    FOwner: TComponent;

    Procedure TimerProc(Sender: TObject);
    procedure SetReading(const Value: boolean);
    function GetReading: boolean;
  public
    property Reading: boolean read GetReading write SetReading;
    constructor Create(AOwner: TComponent; FileName: ShortString = '');
    function Conect(FileName: ShortString):boolean;
    function Disconect():boolean;
    function CreateConection(FileName: ShortString): byte;

    function WriteByte(b: byte): word;
    function ReadByte(var b: byte): word;
    function WriteFrame(fr: TBArray):boolean;

  end;
{-----------------------------------------------------------------------------}
var
   IO: TIOStr;
   Buf: TBuffer;
{-----------------------------------------------------------------------------}
implementation
uses SysUtils;
{-----------------------------------------------------------------------------}
{ TIOStr }
constructor TIOStr.Create;
begin
  FOwner := AOwner;
  FDestAddr  := 0; // Reading
  FMyAddr    := 0;
  FPingActive:= false;
  FConected  := false;

  WBuf.Create;
  RBuf.Create;

  FTimer := TTimer.Create(AOwner);
  FTimer.Interval := 1000 div BaudRate;
  FTimer.OnTimer  := TimerProc;
  FTimer.Enabled  := true;

  FN := FileName;
end;
{-----------------------------------------------------------------------------}
function TIOStr.Conect(FileName: ShortString): boolean;
begin
  if FileName = '' then FileName := FN;
  if FConected and (FileName = FN) then begin
     Result:=true; exit;
  end else if (CreateConection(FileName) and OK <> 0) then begin
     AssignFile(f, FileName);
     FConected := true;
     Reading   := true;
     Result    := true;
  end else Result := false;
end;
{-----------------------------------------------------------------------------}
function TIOStr.Disconect: boolean;
begin
//bufering...
  FConected := false;
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
function  TIOStr.GetReading; begin  Result:= FDestAddr = 0; end;
procedure TIOStr.SetReading; begin  if (Value) then FDestAddr := 0; end;
{-----------------------------------------------------------------------------}
procedure TIOStr.TimerProc(Sender: TObject);
var b: byte;
begin
  if FConected then
  if Reading then begin
    ReadByte(b);
    RBuf.Each := b;
  end else begin
    WriteByte(WBuf.Each);
  end;
end;
{-----------------------------------------------------------------------------}
function TIOStr.WriteByte(b: byte): word;
begin
    Result:=0;
    try
      rewrite(F);
      write(f, b);
      Result:=1;
    finally
      CloseFile(F);
    end;
end;
{-----------------------------------------------------------------------------}
function TIOStr.ReadByte(var b: byte): word;
begin
    reset(f);
    if FileSize(f)=0 then begin
      b:=0;
      Result := 0;
    end else begin
      read(f, b);
      Result:=1;
    end;
    CloseFile(f);  
end;
{-----------------------------------------------------------------------------}
function TIOStr.WriteFrame;
begin
  WBuf.Buf := fr;
  FDestAddr := 10;//  Reading  := false;
  Result   := true;
end;

end.
