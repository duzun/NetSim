unit uNET;
{ Aici este encapsulat protocolul de comunicare }
interface
{-----------------------------------------------------------------------------}
uses
  VProtocol, Funcs, IOStreams, BufferCL, CmdByte,
  ExtCtrls, Classes;
{-----------------------------------------------------------------------------}
const
  c_BaudRate    = 200; // frames/sec : Max = 250
{-----------------------------------------------------------------------------}
type
  TuNET = class(TVProtocol)
     LastAddr: byte;
     RCnter: word;
  private
    StateOnRead: word;

    BaudCounter: word;
    SCicle:    word;

    p, len, tgt, src:  byte;

  public
    constructor Create(AOwner: TComponent; FileName: ShortString = '');

    procedure ReadISO;

    procedure OnConect(); override;
    procedure OnRead(var State: word);
    Procedure TimerProc(Sender: TObject);override;
   end;
{-----------------------------------------------------------------------------}
implementation
{-----------------------------------------------------------------------------}
{ TuNET }
{-----------------------------------------------------------------------------}
constructor TuNET.Create;
begin
  inherited Create(AOwner, FileName);
  LastAddr   := $0;
  BaudCounter:= 0;
  SCicle     := 0;
  BaudRate   := c_BaudRate;
end;
{-----------------------------------------------------------------------------}
procedure TuNET.OnConect();
begin
  StateOnRead := 0; // begining 
end;
{-----------------------------------------------------------------------------}
procedure TuNET.OnRead;
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
procedure TuNET.TimerProc(Sender: TObject);
begin
   { Reading }
   if(BaudCounter = 0)then begin 
      ReadISO;              // --- Data reding  ---
      OnRead(StateOnRead); // --- Data parsing ---
      inc(SCicle);        // --- new Cicle    ---
      BaudCounter := BaudRate shl 1; // renew counter
   end else begin
  { Writing }
     if(BaudCounter = BaudRate)then 
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

//          lBAr[1]:=$FF and SCicle;
//          lBAr[2]:=$FF and (SCicle shr 8);
          SendData(lBAr, LastAddr);
        end;
        WriteSBuf;
     end;
     dec(BaudCounter);
   end;
end;
{-----------------------------------------------------------------------------}
end.
