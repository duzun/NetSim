unit PrHost;
{ Aici este encapsulat protocolul de comunicare fara moderator }
{-----------------------------------------------------------------------------
  Descriere: 
  Concurenta libera...
 -----------------------------------------------------------------------------}
interface
{-----------------------------------------------------------------------------}
uses
  VProtocol, Funcs, IOStreams, CmdByte, 
  ExtCtrls, Classes;
{-----------------------------------------------------------------------------}
type
  TPrHost = class(TVProtocol)     
     RetryCounter: word;
  private
    StateOnRead: word;
    p, len, tgt, src:  byte;

  public
    constructor Create(AOwner: TComponent; FileName: ShortString = '');

    function getState():word;
    
    procedure OnConect(); override;
    procedure OnRead(var State: word); 
    procedure TimerProc(Sender: TObject); 
   end;
{-----------------------------------------------------------------------------}
implementation
{-----------------------------------------------------------------------------}
{ TPrHost }
{-----------------------------------------------------------------------------}
constructor TPrHost.Create;
begin
  inherited Create(AOwner, FileName);
  OnTimer     := TimerProc;
end;
{-----------------------------------------------------------------------------}
function TPrHost.getState: word; begin Result := StateOnRead; end;
{-----------------------------------------------------------------------------}
procedure TPrHost.OnConect();
begin
  StateOnRead := 0; // begining 
  MyAddr := 0;  
  MaxAddr := 0;  
end;
{-----------------------------------------------------------------------------}
procedure TPrHost.OnRead;
begin
    case ReadResult of
     IO_Failed: State := 0; // Reinitializare la eroare
     IO_NoData: ;
     IO_OK:     ;
    end;
  case State of
  0:begin  // Initializare
    RetryCounter := 4; // Nr de incercari
    case ReadResult of
     IO_OK:     State := 1; // Ma conectez...
     IO_NoData: State := 2; // Nimeni conectat
     IO_Failed: exit;       // Mai citeste o data
    end;
  end;
  1:begin  // Conectare
    dec(RetryCounter);
    case ReadResult of
     IO_OK:     State := 3;
     IO_NoData: if(RetryCounter=0)then State:=2 else exit;
     IO_Failed: {???};
    end;
    OnRead(State);
  end;
  2:begin  // Nimeni online
    MaxAddr := $01;
    MyAddr  := $01;
    State   := 5;
  end;
  3:begin  // Asteapta adresa
    if(ReadResult=IO_OK)then
      if(src=$01)and(tgt=$00)and(len>0)then
        case RBAr[p] of
          cmd_tellMe: begin
             SendCmd(cmd_giveAddr, src);
             Writing:=true;
          end;
          cmd_OK or cmd_giveAddr:begin MyAddr:=RBAr[p+1]; State:=4;end;
        end
  end;
  4:begin    // Spune tuturor ca sunt prezent
    if(ReadResult=IO_OK)then
      if(src<>MyAddr)and({(tgt=$00)or}(tgt=MyAddr))and(len>0)then
        case RBAr[p] of
          cmd_tellMe: begin
            SendCmd(cmd_start, ToAll);
            Writing:=true;
            State:=5;
          end;
          cmd_isPresent:begin SendCmd(cmd_OK or cmd_isPresent,src);end;
        end
  end;
  5:begin  // Citire date
    if(ReadResult=IO_OK)then begin
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
            Writing:=true;
            dec(CycleCounter, CycleCounter and 1);
        end;

        cmd_OK or cmd_giveAddr:MyAddr:=RBAr[p+1];
        cmd_OK or cmd_readID: IDs[src]:=Copy(RBAr,p+1,len-1);
        else
      end;
    end;
  end;
  else
     if ReadResult = IO_OK then begin
        RSBuf.Each := RBAr;
     end;
  end;
end;
{-----------------------------------------------------------------------------}
procedure TPrHost.TimerProc;
begin
   { Reading }
   if(CycleCounter and 1 = 0)then begin 
      p := 0;
      if ReadResult = IO_OK then begin
        ISOSplit(RBAr, p, len, src, tgt);
        if (src<>ToAll)and(src > MaxAddr) then MaxAddr := src;
        if (tgt<>ToAll)and(tgt > MaxAddr) then MaxAddr := tgt;
      end else begin
        len:=0;
        src:=0;
      end;
      OnRead(StateOnRead); // --- Data parsing ---

     { $01 is DJ, Boss }
     if(MyAddr=$01)and(CycleCounter and 2 = 0)then begin
        inc(LastAddr);     // Who can write?
        if LastAddr > MaxAddr then LastAddr:=0;
        if LastAddr <> MyAddr then begin
          SetLength(lBAr,3);
          lBAr[0]:=cmd_tellMe;
          lBAr[1]:=$FF and CycleCounter;
          lBAr[2]:=$FF and (CycleCounter shr 8);
          SendData(lBAr, LastAddr);
        end;
        Writing := true; // write in the next Cycle
     end;
   end else begin
  { Writing }
     if(Writing)then begin // --- Have right to write  ---
       Reading := true;   // --- Can write only one frame ---
     end else          
   end;
end;
{-----------------------------------------------------------------------------}
end.
