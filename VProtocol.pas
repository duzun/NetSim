unit VProtocol;
{ II Nivel: transportul de date }
interface
{-----------------------------------------------------------------------------}
uses
  Funcs, IOStreams, Pack, CmdByte,
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
    StateMsg: string; 
    OnStateChange: TNotifyEvent;
    procedure SendLog(Msg: string); 
  private
    FBaudRate: word;
    RWState:   byte;
    FID:       ShortString;
    FIDs:      packed array of TBArray;
    FOnTimer:  TNotifyEvent;
    FConected: boolean;
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

    BaudCounter:  word;

    {Discompunerea Frame-ului primit}
    Pack :TPack; 
    p, len, tgt, src:  byte;
    Cycle: integer;
    Data: TBArray;
    function SplitRBAr: boolean;
    
  public
    property OnTimer    : TNotifyEvent read FOnTimer    write SetOnTimer;
    property ID         : ShortString  read FID         write SetID;
    property IDs[i:byte]: TBArray      read GetIDs      write SetIDs;
    property BaudRate   : word         read GetBaud     write SetBaud;
    property Conected   : boolean      read GetConected write SetConected;
    property Reading    : boolean      read GetReading  write SetReading;
    property Writing    : boolean      read GetWriting  write SetWriting;

    function  Conect(NameOfFile: ShortString = ''): boolean;
    function  Disconect(force: boolean = false): boolean;
    procedure Synchronize(Sender: TObject);

    function  getBaudCount():  longword;
    function  getCycleCount(): longword;
    procedure ResetCycleCount();
    
    function  SendCmd(Cmd: byte; tgt: byte = ToAll): boolean;
    function  SendData(data: TBArray; tgt: byte = ToAll): boolean;
    function  Send(cmd: byte; data: TBArray; tgt: byte = ToAll): boolean; overload;
    function  Send(cmd: byte; data: byte;    tgt: byte = ToAll): boolean; overload;
    function  Send(cmd: byte; data: word;    tgt: byte = ToAll): boolean; overload;
    function  Send(cmd: byte; data: longword;tgt: byte = ToAll): boolean; overload;

    function  SendCmdNow(cmd: byte; tgt: byte = ToAll): boolean;
    function  SendDataNow(data: TBArray; tgt: byte = ToAll): word;
    function  SendNow(cmd: byte; data: TBArray; tgt: byte = ToAll): boolean; overload;  
    function  SendNow(cmd: byte; data: byte;    tgt: byte = ToAll): boolean; overload;  
    function  SendNow(cmd: byte; data: word;    tgt: byte = ToAll): boolean; overload;  
    function  SendNow(cmd: byte; data: longword;tgt: byte = ToAll): boolean; overload;  
    
    function  ListSendCmd(Cmd: byte; tgt: TBArray): boolean;
    function  ListSendData(data: TBArray; tgt: TBArray): boolean;
    function  ListSend(cmd: byte; data: TBArray; tgt: TBArray): boolean;

    procedure OnConect();    virtual;
    procedure OnDisconect(); virtual;
    Procedure TimerProc(Sender: TObject);

    constructor Create(AOwner: TComponent; NameOfFile: ShortString = '');
    destructor  Destroy; override;
   end;
{-----------------------------------------------------------------------------}
implementation
uses
   SysUtils;
{-----------------------------------------------------------------------------}
{ TVProtocol }
{-----------------------------------------------------------------------------}
procedure TVProtocol.SendLog(Msg: string);
begin
  StateMsg := Msg;
  OnStateChange(Self);
end; 
{-----------------------------------------------------------------------------}
constructor TVProtocol.Create;
begin
  inherited Create(NameOfFile);
  FOwner          := AOwner;
  MaxAddr         := $0;
  MyAddr          := $0;
  RWState         := 0;
  OnTimer         := nil;
  BaudRate        := c_BaudRate;

//   Pack := TPack.Create(0);
  FTimer          := TTimer.Create(FOwner);
  FTimer.Enabled  := false;
  FTimer.Interval := 1;

  setlength(FIDs, 0);
  Conected        := false;
end;
{-----------------------------------------------------------------------------}
procedure TVProtocol.Synchronize;
begin
  if not FConected then begin // first call
     MyAddr         := 0;
     Opened         := true;
     BaudCounter    := 0;
     CycleCounter   := 0;
     FTimer.OnTimer := Synchronize;
     FTimer.Enabled := true;
     FConected      := true;
  end;
  if Writing then exit; // its locked by another call to Synchronize
  Writing := true;      // lock Synchronize
  ReadSBuf;
  if (BaudCounter >= 20 * FBaudRate)and(ReadResult=IO_NoData) then 
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
  IO_NoData: inc(BaudCounter);
  IO_Failed:
     begin
        BaudCounter    := 0;      
        CycleCounter   := 0;
     end;
  end;
  Writing := false; // unlock Synchronize
end;
{-----------------------------------------------------------------------------}
function  TVProtocol.Conect(NameOfFile: ShortString=''): boolean;
begin
  if NameOfFile = '' then NameOfFile := FileName;
  if Conected and (NameOfFile = FileName) then Result := true
  else if Open(NameOfFile) then begin
     Synchronize(Self);
     Result := true;
  end else Result := false;
end;
{-----------------------------------------------------------------------------}
function  TVProtocol.Disconect;
begin
  if Conected then begin
    if (WSBuf.ready<>0)and(not force) then Result:=false
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
function  TVProtocol.GetConected: boolean; begin Result := FConected and Opened; end;
procedure TVProtocol.SetConected(const Value: boolean);
begin  
   if not Value then begin
      FTimer.Enabled := false;
      Opened := false; // release the file
      FConected := false;
   end else 
      Conect();
end;
{-----------------------------------------------------------------------------}
procedure TVProtocol.SetID(const Value: ShortString);
begin
  if Value = FID then exit;
  FID := Value;
  Send(cmd_readID or cmd_OK, ToBAr(FID));
  if MyAddr <> 0 then FIDs[MyAddr] := ToBAr(FID);
end;
{-----------------------------------------------------------------------------}
function  TVProtocol.GetIDs(i: byte): TBArray;
begin
  if (i=ToAll) then result:=GenBAr(0,0,0)
  else begin
    if (i>=length(FIDs))or(length(FIDs[i])=0) then Result:=ToBAr('<'+byte2str(i,'>'))
    else Result:=FIDs[i];
  end;
end;
{-----------------------------------------------------------------------------}
procedure TVProtocol.SetIDs(i: byte; const Value: TBArray);
begin
  if (i=ToAll) then exit;
  if (i = MyAddr)and(i<>0) then ID := BAr2Str(Value)
  else begin
     if i>=length(FIDs) then setlength(FIDs, i+1);
     FIDs[i]:= Value;
     i := length(FIDs)-1;
     while(length(FIDs[i])=0)and(i>0)do dec(i);
     setlength(FIDs, i+1) 
  end;
end;
{-----------------------------------------------------------------------------}
procedure TVProtocol.OnDisconect;begin end;
procedure TVProtocol.OnConect;begin end;
{-----------------------------------------------------------------------------}
function  TVProtocol.GetReading: boolean;begin Result := RWState and c_Reading <> 0; end;
function  TVProtocol.GetWriting: boolean;begin Result := RWState and c_Writing <> 0; end;
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
function  TVProtocol.getBaudCount;  begin Result := BaudCounter;  end;
function  TVProtocol.getCycleCount; begin Result := CycleCounter; end;
procedure TVProtocol.ResetCycleCount;begin CycleCounter := CycleCounter and $3; end;
{-----------------------------------------------------------------------------}
procedure TVProtocol.TimerProc(Sender: TObject);
begin
   if(BaudCounter = 0)then begin
     if(Reading) then ReadSBuf  else    // --- Data reading  ---
     if(Writing) then WriteSBuf else    // --- Data writing  ---
     inc(OffSetCycle);                  // Cycles from connection
     BaudCounter := FBaudRate;  // renew counter
//      SplitRBAr;  // ReadResult - ?
     OnTimer(Self);            // --- Data parsing ---

   end else begin
     dec(BaudCounter);
   end;
end;
{-----------------------------------------------------------------------------}
procedure TVProtocol.SetOnTimer(const Value: TNotifyEvent); begin FOnTimer := Value; end;
{-----------------------------------------------------------------------------}
destructor TVProtocol.Destroy;
begin
  Disconect;
  FTimer.Destroy;
  setlength(FIDs, 0);
  inherited Destroy;
end;
{-----------------------------------------------------------------------------}
function  TVProtocol.SendData;
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
function  TVProtocol.SendDataNow;
var p: word;
begin
  p := 0;
  if Length(WBAr)=0 then // data trebuie sa fie cat mai mic 
     WBAr := ISOForm(data, p, MyAddr, tgt)
  else    
     SendData(data, tgt); // Daca canalul e supraincarcat, se foloseste metoda obisnuita de transmitere
  Result := p;
end;
{-----------------------------------------------------------------------------}
function  TVProtocol.SendCmd; begin Result:=SendData(ToBAr(Cmd), tgt); end;
{-----------------------------------------------------------------------------}
function  TVProtocol.Send(cmd:byte; data:TBArray;  tgt:byte=ToAll):boolean;begin Insert(cmd,data); Result:=SendData(data,tgt); end;
function  TVProtocol.Send(cmd:byte; data:byte;     tgt:byte=ToAll):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=SendData(BAr,tgt); end;
function  TVProtocol.Send(cmd:byte; data:word;     tgt:byte=ToAll):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=SendData(BAr,tgt); end;
function  TVProtocol.Send(cmd:byte; data:longword; tgt:byte=ToAll):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=SendData(BAr,tgt); end;
{-----------------------------------------------------------------------------}
function  TVProtocol.SendCmdNow; begin Result:=SendDataNow(ToBAr(Cmd), tgt)<>0; end;
{-----------------------------------------------------------------------------}
function  TVProtocol.SendNow(cmd:byte; data:TBArray;  tgt:byte=ToAll):boolean;begin Insert(cmd,data); Result:=SendDataNow(data,tgt)<>0; end;
function  TVProtocol.SendNow(cmd:byte; data:byte;     tgt:byte=ToAll):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=SendDataNow(BAr,tgt)<>0; end;
function  TVProtocol.SendNow(cmd:byte; data:word;     tgt:byte=ToAll):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=SendDataNow(BAr,tgt)<>0; end;
function  TVProtocol.SendNow(cmd:byte; data:longword; tgt:byte=ToAll):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=SendDataNow(BAr,tgt)<>0; end;
{-----------------------------------------------------------------------------}
function  TVProtocol.ListSendCmd(Cmd: byte; tgt: TBArray): boolean;
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
function  TVProtocol.ListSendData(data, tgt: TBArray): boolean;
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
function  TVProtocol.ListSend(cmd: byte; data, tgt: TBArray): boolean;
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
function TVProtocol.SplitRBAr;
var r: boolean;
begin
   r := ISOSplit(RBAr, p, len, src, tgt)=0;
   if not r then exit;
   Data  := Copy(RBAr, p, len);
   Cycle := BAr2Int(RBAr, p+len+1, 4);
end;

end.
