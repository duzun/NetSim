unit Connection;
{ Nivelul legãturii de date }
interface
{-----------------------------------------------------------------------------}
uses
  Funcs, IOStream, Pack, CmdByte,
  ExtCtrls, Classes;
{-----------------------------------------------------------------------------}
const
  c_BaudRate    = 250; // frames/sec : Max = 1000
  c_Retries     = 10;
  c_Reading     = $01;
  c_Writing     = $02;
{-----------------------------------------------------------------------------}
type
{ Class baza pentru protocoalele de comunicare }
  TConnection = class(TIOStream)
    MaxAddr, MyAddr: byte; 
    StateMsg: string; 
    OnStateChange: TNotifyEvent;
    procedure SendLog(Msg: string); 
  private
    FConectTime: TDateTime;
    FBaudRate: word;
    RWState:   byte;
    FOnTimer:  TNotifyEvent;

    function  GetConected: boolean;
    function  GetFConected: boolean;
    function  GetBaud: word;
    function  GetReading: boolean;
    function  GetWriting: boolean;
    procedure SetConected(const Value: boolean);
    procedure SetBaud(Value: word);
    procedure SetReading(const Value: boolean);
    procedure SetWriting(const Value: boolean);
    procedure SetOnTimer(const Value: TNotifyEvent);
    procedure SetFConected(const Value: boolean);
    property  FConected: boolean  read GetFConected write SetFConected;
    Procedure TimerProc(Sender: TObject);
  protected
    FTimer:    TTimer;
    FOwner:    TComponent;
    
    RetryCount: word;
    BaudCounter: word;

    {Discompunerea Frame-ului primit}
//     Pack :TPack; 
    p, len, tgt, src:  byte;
    Cycle: integer;
    Data: TBArray;
    function SplitRBAr: boolean;
    
  public
    property OnTimer  : TNotifyEvent read FOnTimer    write SetOnTimer;
    property BaudRate : word         read GetBaud     write SetBaud;
    property Conected : boolean      read GetConected write SetConected;
    property Reading  : boolean      read GetReading  write SetReading;
    property Writing  : boolean      read GetWriting  write SetWriting;

    function  Conect(NameOfFile: ShortString = ''): boolean;
    function  Disconect(force: boolean = false): boolean;
    procedure Synchronize(Sender: TObject);
    procedure ResetCycleCount;

    procedure Reset_All;
    procedure Reset_Connection;

	function  ConectionTime: TDateTime;

    procedure OnConect();    virtual;
    procedure OnDisconect(); virtual;

    constructor Create(AOwner: TComponent; NameOfFile: ShortString = ''; BaudR: word = c_BaudRate);
    destructor  Destroy; override;
   end;
{-----------------------------------------------------------------------------}
implementation
uses
   SysUtils;
{-----------------------------------------------------------------------------}
{ TConnection }
{-----------------------------------------------------------------------------}
procedure TConnection.SendLog(Msg: string);
begin
  StateMsg := Msg;
  OnStateChange(Self);
end; 
{-----------------------------------------------------------------------------}
constructor TConnection.Create;
begin
  inherited Create(NameOfFile);
  FOwner          := AOwner;
  OnTimer         := nil;
  BaudRate        := BaudR;
  Reset_Connection;

//   Pack := TPack.Create(0);
  FTimer          := TTimer.Create(FOwner);
  FTimer.Enabled  := false;
  FTimer.Interval := 1;

  Conected        := false;
end;
{-----------------------------------------------------------------------------}
procedure TConnection.Reset_Connection;
begin
  MaxAddr         := $00;
  MyAddr          := $00;
  RWState         := 0;
  BaudCounter     := 0;
end;
{-----------------------------------------------------------------------------}
procedure TConnection.Reset_All;
begin
   Reset_IO;
   Reset_IO_Buffers;
   Reset_Connection;
end;
{-----------------------------------------------------------------------------}
procedure TConnection.Synchronize;
begin
  if not FConected then begin // first call
     Reset_Connection;
     Opened         := true;
     CycleCount     := 0;
     FTimer.OnTimer := Synchronize;
     FTimer.Enabled := true;
     FConected      := true;
  end;
  if Writing then exit; // its locked by another call to Synchronize
  Writing := true;      // lock Synchronize
  ReadSBuf;
  if (NoReadCount >= 20 * FBaudRate) then
    begin // nobody inline
       MyAddr := 1;
       ReadResult := IO_OK;
    end;   
  case ReadResult of
  IO_OK:
     begin
        BaudCounter := FBaudRate;
        Reading     := true; // Enable Reading
        FTimer.OnTimer := TimerProc;
        FConected := true;
        OnConect();
     end;
  IO_NoData: ;
  IO_Failed:
     begin
        BaudCounter  := 0;
        CycleCount   := 0;
     end;
  end;
  Writing := false; // unlock Synchronize
end;
{-----------------------------------------------------------------------------}
procedure TConnection.TimerProc(Sender: TObject);
begin
   if(BaudCounter = 0)then begin
     if(Reading) then ReadSBuf  else    // --- Data reading  ---
     if(Writing) then WriteSBuf else    // --- Data writing  ---
     inc(OffSetCycle);                  // Cycles from connection
     BaudCounter := FBaudRate;  // renew counter
//      SplitRBAr;  // ReadResult - ?
     OnTimer(Self);             // --- Next level ---
   end else begin
     dec(BaudCounter);
   end;
end;
{-----------------------------------------------------------------------------}
function  TConnection.Conect(NameOfFile: ShortString=''): boolean;
begin
  if NameOfFile = '' then NameOfFile := FileName;
  if Conected and (NameOfFile = FileName) then Result := true
  else if Open(NameOfFile) then begin
     Synchronize(Self);
     Result := true;
  end else Result := false;
end;
{-----------------------------------------------------------------------------}
function  TConnection.Disconect;
begin
  if Conected then begin
    if (WSBuf.ready<>0)and(not force) then Result:=false
    else begin
      Conected  := false;
      Opened    := false;
      Reset_All;
      Result    := true;
      OnDisconect();
    end;
  end else Result:=true;
end;
{-----------------------------------------------------------------------------}
function  TConnection.GetConected: boolean; begin Result := FConected and Opened; end;
procedure TConnection.SetConected(const Value: boolean);
begin  
   if not Value then begin
      FTimer.Enabled := false;
      Opened := false; // release the file
      FConected := false;
   end else 
      Conect();
end;
{-----------------------------------------------------------------------------}
procedure TConnection.OnDisconect;begin end;
procedure TConnection.OnConect;begin end;
{-----------------------------------------------------------------------------}
function  TConnection.GetReading: boolean;begin Result := RWState and c_Reading <> 0; end;
function  TConnection.GetWriting: boolean;begin Result := RWState and c_Writing <> 0; end;
{-----------------------------------------------------------------------------}
procedure TConnection.SetReading(const Value: boolean);
begin
   if (Value) then RWState := c_Reading
   else RWState := RWState and c_Writing;  
end;
{-----------------------------------------------------------------------------}
procedure TConnection.SetWriting(const Value: boolean);
begin
   if (Value) then RWState := c_Writing
   else RWState := RWState and c_Reading;  
end;
{-----------------------------------------------------------------------------}
function  TConnection.GetBaud: word;        begin Result    := 1000 div FBaudRate; end;
procedure TConnection.SetBaud(Value: word); begin FBaudRate := 1000 div Value;     end;
{-----------------------------------------------------------------------------}
procedure TConnection.ResetCycleCount;begin CycleCount := CycleCount and $3; end;
{-----------------------------------------------------------------------------}
procedure TConnection.SetOnTimer(const Value: TNotifyEvent); begin FOnTimer := Value; end;
{-----------------------------------------------------------------------------}
destructor TConnection.Destroy;
begin
  Disconect;
  FTimer.Destroy;
  inherited Destroy;
end;
{-----------------------------------------------------------------------------}
function TConnection.SplitRBAr;
var r: boolean;
begin
   r := SplitFrame(RBAr, p, len, src, tgt)=0;
   if not r then exit;
   Data  := Copy(RBAr, p, len);
   Cycle := BAr2Int(RBAr, p+len+1, 4);
   Result := r;
end;
{-----------------------------------------------------------------------------}
procedure TConnection.SetFConected; begin if Value then FConectTime:=Time else FConectTime:=0; end;
function  TConnection.GetFConected; begin Result := FConectTime <> 0; end;
{-----------------------------------------------------------------------------}
function TConnection.ConectionTime; begin Result := FConectTime; end;
{-----------------------------------------------------------------------------}


end.
