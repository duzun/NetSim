unit ProtocolBase;
{ Nivelul transport }
interface
{-----------------------------------------------------------------------------}
uses
  Funcs, IOStream, Connection, CmdByte,
  ExtCtrls, Classes;
{-----------------------------------------------------------------------------}
type
{ Class baza pentru protocoalele de comunicare }
  TProtocolBase = class(TConnection)
  private
    FID:      ShortString;
    FIDs:     packed array of TBArray;
    function  GetIDs(i: byte): TBArray;
    procedure SetID(const Value: ShortString);
    procedure SetIDs(i: byte; const Value: TBArray);
  public
    property ID         : ShortString  read FID         write SetID;
    property IDs[i:byte]: TBArray      read GetIDs      write SetIDs;

    function  SendData(data: TBArray; tgt: byte = ToAll): boolean; {The basic Send function}
    function  SendCmd(Cmd: byte; tgt: byte = ToAll): boolean;

    function  SendCmdNow(cmd: byte; tgt: byte = ToAll): boolean;
    function  SendDataNow(data: TBArray; tgt: byte = ToAll): word;

    { Send without data type specificator }
    function  Send(cmd: byte; data: TBArray; tgt: byte = ToAll): boolean; overload;
    function  Send(cmd: byte; data: String;  tgt: byte = ToAll): boolean; overload;
    function  Send(cmd: byte; data: byte;    tgt: byte = ToAll): boolean; overload;
    function  Send(cmd: byte; data: word;    tgt: byte = ToAll): boolean; overload;
    function  Send(cmd: byte; data: longword;tgt: byte = ToAll): boolean; overload;
    function  Send(cmd: byte; data: Double;  tgt: byte = ToAll): boolean; overload;

    { Send with data type specificator }
    function  SendType(cmd: byte; data: Byte     ; tgt: byte = ToAll): boolean; overload;
    function  SendType(cmd: byte; data: Word     ; tgt: byte = ToAll): boolean; overload;
    function  SendType(cmd: byte; data: Integer  ; tgt: byte = ToAll): boolean; overload;
    function  SendType(cmd: byte; data: LongWord ; tgt: byte = ToAll): boolean; overload;
    function  SendType(cmd: byte; data: Char     ; tgt: byte = ToAll): boolean; overload;
    function  SendType(cmd: byte; data: String   ; tgt: byte = ToAll): boolean; overload;
    function  SendType(cmd: byte; data: Double   ; tgt: byte = ToAll): boolean; overload;
    function  SendTime(cmd: byte; data: TDateTime; tgt: byte = ToAll): boolean;

    function  SendNow(cmd: byte; data: TBArray; tgt: byte = ToAll): boolean; overload;  
    function  SendNow(cmd: byte; data: String;  tgt: byte = ToAll): boolean; overload;  
    function  SendNow(cmd: byte; data: byte;    tgt: byte = ToAll): boolean; overload;  
    function  SendNow(cmd: byte; data: word;    tgt: byte = ToAll): boolean; overload;  
    function  SendNow(cmd: byte; data: longword;tgt: byte = ToAll): boolean; overload;  
    function  SendNow(cmd: byte; data: Double;  tgt: byte = ToAll): boolean; overload;  
    
    function  ListSendCmd(Cmd: byte; tgt: TBArray): boolean;
    function  ListSendData(data: TBArray; tgt: TBArray): boolean;

    function  ListSend(cmd: byte; data: TBArray; tgt: TBArray): boolean; overload;
    function  ListSend(cmd: byte; data: String;  tgt: TBArray): boolean; overload;
    function  ListSend(cmd: byte; data: byte;    tgt: TBArray): boolean; overload;
    function  ListSend(cmd: byte; data: word;    tgt: TBArray): boolean; overload;
    function  ListSend(cmd: byte; data: longword;tgt: TBArray): boolean; overload;
    function  ListSend(cmd: byte; data: Double;  tgt: TBArray): boolean; overload;
    
    function  ListSendType(cmd: byte; data: Byte     ; tgt: TBArray): boolean; overload;
    function  ListSendType(cmd: byte; data: Word     ; tgt: TBArray): boolean; overload;
    function  ListSendType(cmd: byte; data: Integer  ; tgt: TBArray): boolean; overload;
    function  ListSendType(cmd: byte; data: LongWord ; tgt: TBArray): boolean; overload;
    function  ListSendType(cmd: byte; data: Char     ; tgt: TBArray): boolean; overload;
    function  ListSendType(cmd: byte; data: String   ; tgt: TBArray): boolean; overload;
    function  ListSendType(cmd: byte; data: Double   ; tgt: TBArray): boolean; overload;
    function  ListSendTime(cmd: byte; data: TDateTime; tgt: TBArray): boolean;
    
    constructor Create(AOwner: TComponent; NameOfFile: ShortString = '');
   end;
{-----------------------------------------------------------------------------}
implementation
uses
   SysUtils;
{-----------------------------------------------------------------------------}
{ TProtocolBase }
{-----------------------------------------------------------------------------}
constructor TProtocolBase.Create;
begin
  inherited Create(AOwner, NameOfFile);
  setlength(FIDs, 0);
end;
{-----------------------------------------------------------------------------}
procedure TProtocolBase.SetID(const Value: ShortString);
begin
  if Value = FID then exit;
  FID := Value;
  Send(cmd_readID or cmd_OK, ToBAr(FID));
  if MyAddr <> 0 then IDs[MyAddr] := ToBAr(FID);
end;
{-----------------------------------------------------------------------------}
function  TProtocolBase.GetIDs(i: byte): TBArray;
begin
  if (i=ToAll) then result:=GenBAr(0,0,0)
  else begin
    if (i>=length(FIDs))or(length(FIDs[i])=0) then Result:=ToBAr('<'+byte2str(i,'>'))
    else Result:=FIDs[i];
  end;
end;
{-----------------------------------------------------------------------------}
procedure TProtocolBase.SetIDs(i: byte; const Value: TBArray);
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
function  TProtocolBase.SendData;
var p, l: word;
begin
  Result := false;
  p:=0;
  l:=Length( data );
  while(p<l)do begin
    WSBuf.Each := FormFrame(data, p, MyAddr, tgt);
    // Overflow chk !!!
  end;
  Result := true;
end;
{-----------------------------------------------------------------------------}
function  TProtocolBase.SendDataNow;
var p: word;
begin
  p := 0;
  if Length(WBAr)=0 then // data trebuie sa fie cat mai mic 
     WBAr := FormFrame(data, p, MyAddr, tgt)
  else    
     SendData(data, tgt); // Daca canalul e supraincarcat, se foloseste metoda obisnuita de transmitere
  Result := p;
end;
{-----------------------------------------------------------------------------}
function  TProtocolBase.SendCmd; begin Result:=SendData(ToBAr(Cmd), tgt); end;
{-----------------------------------------------------------------------------}
function  TProtocolBase.Send(cmd:byte; data:TBArray;  tgt:byte=ToAll):boolean;begin Insert(cmd,data); Result:=SendData(data,tgt); end;
function  TProtocolBase.Send(cmd:byte; data:string;   tgt:byte=ToAll):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=SendData(BAr,tgt); end;
function  TProtocolBase.Send(cmd:byte; data:byte;     tgt:byte=ToAll):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=SendData(BAr,tgt); end;
function  TProtocolBase.Send(cmd:byte; data:word;     tgt:byte=ToAll):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=SendData(BAr,tgt); end;
function  TProtocolBase.Send(cmd:byte; data:longword; tgt:byte=ToAll):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=SendData(BAr,tgt); end;
function  TProtocolBase.Send(cmd:byte; data:Double;   tgt:byte=ToAll):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=SendData(BAr,tgt); end;
{-----------------------------------------------------------------------------}
function TProtocolBase.SendType(cmd: byte; data: Integer;  tgt: byte): boolean; begin Result:=Send(cmd, Join(cmd_Int,      ToBar(data)), tgt); end;
function TProtocolBase.SendType(cmd: byte; data: LongWord; tgt: byte): boolean; begin Result:=Send(cmd, Join(cmd_LongWord, ToBar(data)), tgt); end;
function TProtocolBase.SendType(cmd: byte; data: byte;     tgt: byte): boolean; begin Result:=Send(cmd, Join(cmd_Byte,     ToBar(data)), tgt); end;
function TProtocolBase.SendType(cmd: byte; data: Word;     tgt: byte): boolean; begin Result:=Send(cmd, Join(cmd_Word,     ToBar(data)), tgt); end;
function TProtocolBase.SendType(cmd: byte; data: Double;   tgt: byte): boolean; begin Result:=Send(cmd, Join(cmd_Double,   ToBar(data)), tgt); end;
function TProtocolBase.SendType(cmd: byte; data: Char;     tgt: byte): boolean; begin Result:=Send(cmd, Join(cmd_Char,     ToBar(data)), tgt); end;
function TProtocolBase.SendType(cmd: byte; data: String;   tgt: byte): boolean; begin Result:=Send(cmd, Join(cmd_String,   ToBar(data)), tgt); end;
function TProtocolBase.SendTime(cmd: byte; data: TDateTime;tgt: byte): boolean; begin Result:=Send(cmd, Join(cmd_Time,     ToBar(data)), tgt); end;
{-----------------------------------------------------------------------------}
function  TProtocolBase.SendCmdNow; begin Result:=SendDataNow(ToBAr(Cmd), tgt)<>0; end;
{-----------------------------------------------------------------------------}
function  TProtocolBase.SendNow(cmd:byte; data:TBArray;  tgt:byte=ToAll):boolean;begin Insert(cmd,data); Result:=SendDataNow(data,tgt)<>0; end;
function  TProtocolBase.SendNow(cmd:byte; data:String;   tgt:byte=ToAll):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=SendDataNow(BAr,tgt)<>0; end;
function  TProtocolBase.SendNow(cmd:byte; data:byte;     tgt:byte=ToAll):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=SendDataNow(BAr,tgt)<>0; end;
function  TProtocolBase.SendNow(cmd:byte; data:word;     tgt:byte=ToAll):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=SendDataNow(BAr,tgt)<>0; end;
function  TProtocolBase.SendNow(cmd:byte; data:longword; tgt:byte=ToAll):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=SendDataNow(BAr,tgt)<>0; end;
function  TProtocolBase.SendNow(cmd:byte; data:Double;   tgt:byte=ToAll):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=SendDataNow(BAr,tgt)<>0; end;
{-----------------------------------------------------------------------------}
function  TProtocolBase.ListSendCmd(Cmd: byte; tgt: TBArray): boolean;
var BAr: TBArray;
begin
  BAr := ToBAr(Cmd);
  Result:=ListSendData(BAr, tgt);
end;
{-----------------------------------------------------------------------------}
function  TProtocolBase.ListSendData(data, tgt: TBArray): boolean;
var i: word;    r: boolean;
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
function  TProtocolBase.ListSend(cmd:byte; data:TBArray;  tgt:TBArray): boolean;begin Insert(cmd,data); Result:=ListSendData(data,tgt); end;
function  TProtocolBase.ListSend(cmd:byte; data:String;   tgt:TBArray):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=ListSendData(BAr,tgt); end;
function  TProtocolBase.ListSend(cmd:byte; data:byte;     tgt:TBArray):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=ListSendData(BAr,tgt); end;
function  TProtocolBase.ListSend(cmd:byte; data:word;     tgt:TBArray):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=ListSendData(BAr,tgt); end;
function  TProtocolBase.ListSend(cmd:byte; data:longword; tgt:TBArray):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=ListSendData(BAr,tgt); end;
function  TProtocolBase.ListSend(cmd:byte; data:Double;   tgt:TBArray):boolean;var BAr:TBArray;begin BAr:=ToBAr(data,1); BAr[0]:=cmd; Result:=ListSendData(BAr,tgt); end;
{-----------------------------------------------------------------------------}
function TProtocolBase.ListSendType(cmd: byte; data: Integer;  tgt: TBArray): boolean; begin Result:=ListSend(cmd, Join(cmd_Int,      ToBar(data)), tgt); end;
function TProtocolBase.ListSendType(cmd: byte; data: LongWord; tgt: TBArray): boolean; begin Result:=ListSend(cmd, Join(cmd_LongWord, ToBar(data)), tgt); end;
function TProtocolBase.ListSendType(cmd: byte; data: byte;     tgt: TBArray): boolean; begin Result:=ListSend(cmd, Join(cmd_Byte,     ToBar(data)), tgt); end;
function TProtocolBase.ListSendType(cmd: byte; data: Word;     tgt: TBArray): boolean; begin Result:=ListSend(cmd, Join(cmd_Word,     ToBar(data)), tgt); end;
function TProtocolBase.ListSendType(cmd: byte; data: Double;   tgt: TBArray): boolean; begin Result:=ListSend(cmd, Join(cmd_Double,   ToBar(data)), tgt); end;
function TProtocolBase.ListSendType(cmd: byte; data: Char;     tgt: TBArray): boolean; begin Result:=ListSend(cmd, Join(cmd_Char,     ToBar(data)), tgt); end;
function TProtocolBase.ListSendType(cmd: byte; data: String;   tgt: TBArray): boolean; begin Result:=ListSend(cmd, Join(cmd_String,   ToBar(data)), tgt); end;
function TProtocolBase.ListSendTime(cmd: byte; data: TDateTime;tgt: TBArray): boolean; begin Result:=ListSend(cmd, Join(cmd_Time,     ToBar(data)), tgt); end;
{-----------------------------------------------------------------------------}

end.
