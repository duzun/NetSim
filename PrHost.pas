unit PrHost;
{ Aici este encapsulat protocolul de comunicare cu moderator }
{-----------------------------------------------------------------------------
  Descriere: 
  Inainte de a trimite informatii, fiecare participant cere "voie" 
  de la moderator. 
  Moderatorul la fel atribuie adrese calculatoarelor nou incluse in comunicare. 
  Moderatorul totdeauna are adresa $01.
  Cand moderatorul "pleaca", locul lui il ocupa ultimul calculator (cu adresa maxima).
  Timpul este impartit in 2 cicluri, unul pentru moderator si altul pentru ceilalti.
  Un ciclu este impartit in 2 perioade: de scriere si de citire. 
  La perioada de citire participa toti, indiferent de ciclu. 
 -----------------------------------------------------------------------------}
interface
{-----------------------------------------------------------------------------}
uses
  VProtocol, Funcs, IOStreams, CmdByte, 
  ExtCtrls, Classes, SysUtils;
{-----------------------------------------------------------------------------}
type
  TPrHost = class(TVProtocol)
     LastAddr: byte;
     RetryCounter: word;
  private
    StateOnRead: word;

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
  LastAddr    := $0;
  OnTimer     := TimerProc;
end;
{-----------------------------------------------------------------------------}
function TPrHost.getState: word; begin Result := StateOnRead; end;
{-----------------------------------------------------------------------------}
procedure TPrHost.OnConect();
begin
  StateOnRead := 0; // begining 
//  MyAddr := 0;  
//   MaxAddr := 0;  
  LastAddr := 0;  
end;
{-----------------------------------------------------------------------------}
procedure TPrHost.OnRead;
begin
    case ReadResult of
     IO_Failed: State := 0; // Reinitializare la eroare
     IO_NoData: ;
     IO_OK:
        if src = MyAddr then     
           SendLog('> '+byte2str(tgt)+'| '+BAr2ByteStr(RBAr, len+3))
        else    
           SendLog('< '+byte2str(src)+'| '+BAr2ByteStr(RBAr, len+3));
    end;
  case State of
  0:begin  // Initializare
    SendLog('OnRead: State='+inttostr(State));
    RetryCounter := 4; // Nr de incercari
    if MyAddr <> 0 then State := 2 else State := 3;
{    case ReadResult of
     IO_OK:     State := 1; // Ma conectez...
     IO_NoData: State := 2; // Nimeni conectat
     IO_Failed: exit;       // Mai citeste o data
    end;
}  end;
  1:begin  // Conectare
    dec(RetryCounter);
    SendLog('OnRead: State='+inttostr(State)+', '+inttostr(RetryCounter));
    case ReadResult of
     IO_OK:     State := 3;
     IO_NoData: if(RetryCounter=0)then State:=2 else exit;
     IO_Failed: {???};
    end;
    OnRead(State);
  end;
  2:begin  // Nimeni online
    SendLog('OnRead: State='+inttostr(State)+', MyAddr='+inttostr(MyAddr));
    MaxAddr := $00;
    if MyAddr = 0 then MyAddr  := $01;
    State   := 5;
  end;
  3:begin  // Asteapta adresa
    if(ReadResult=IO_OK)then begin
//       SendLog('OnRead: St:'+inttostr(State));
      if(tgt=$00)and(len>0)then
        {/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/}
        case Data[0] of
        cmd_tellMe:
             if (src=$01) then begin
               SendCmdNow(cmd_giveAddr, ToAll);
               Writing := true;
             end;
        cmd_OK or cmd_giveAddr:
             begin
               State  := 4;
               MyAddr := Data[1];
             end;
        end
        {/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/}
    end;    
  end;
  4:begin    // Spune tuturor ca sunt prezent
    if(ReadResult=IO_OK)then begin
//       SendLog('OnRead: St='+inttostr(State)+', cmd='+byte2str(RBAr[p]));
      if(src<>MyAddr)and((tgt=$00)or(tgt=MyAddr))and(len>0)then
        {/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/}
        case Data[0] of
        cmd_tellMe:
            if(src=$01) then begin
              SendCmd(cmd_start, ToAll);
              Writing := true;
              State   := 5;
            end;
        cmd_isPresent:
            SendCmd(cmd_OK or cmd_isPresent, src);
        end;
        {/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/}
    end
  end;
  5:begin  // Citire date
    if(ReadResult=IO_OK)then begin
      if(src>MaxAddr) then MaxAddr := src;
      if((src<>MyAddr)and(tgt=MyAddr)or(tgt=ToAll))and(len>0)then
      {/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/}
      case Data[0] of   // parsing commands

      cmd_isPresent: 
         SendCmdNow(Data[0] or cmd_OK, src);
         
      cmd_start: 
         begin
           if MaxAddr+1=src then inc(MaxAddr);
         end;  
         
      cmd_stop: 
         begin
           if MyAddr=MaxAddr then begin
              MyAddr := src;
              SendCmdNow(cmd_readID);
           end else if MyAddr=$01 then begin
              Send(cmd_giveAddr or cmd_OK, src, MaxAddr);
           end;
           dec(MaxAddr);
         end;
         
      cmd_giveAddr:
         begin
            SendNow(cmd_giveAddr or cmd_OK, MaxAddr+1, src);
         end;
         
      cmd_write:   
         begin
            LastBAr := Data;
            IncBAr(LastBAr, 1, src);
            RSBuf.Each := LastBAr;
         end;
         
      cmd_tellMe:
         begin
            Writing := true;
//             dec(CycleCounter, CycleCounter and 1);
         end;
         
      cmd_OK or cmd_giveAddr:
         MyAddr := Data[1];
         
      cmd_OK or cmd_readID: 
         IDs[src] := Copy(Data,1,len-1);
         
      else
      end;
      {/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/}
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
      p:=0;
      if ReadResult = IO_OK then begin
        SplitRBAr;
        if (src<>ToAll)and(src > MaxAddr) then MaxAddr := src;
        if (tgt<>ToAll)and(tgt > MaxAddr) then MaxAddr := tgt;
      end else begin
        len:=0;
        src:=0;
      end;
      OnRead(StateOnRead); // --- Data parsing ---

     { $01 is DJ, Boss }
     if(MyAddr=$01) then begin
       if(CycleCounter and 2 = 0)then begin
          inc(LastAddr);     // Who can write?
          if LastAddr > MaxAddr then LastAddr:=0;
          if LastAddr <> MyAddr then begin
//             SetLength(LastBAr,3);
//             LastBAr[0]:=cmd_tellMe;
//             LastBAr[1]:=$FF and CycleCounter;
//             LastBAr[2]:=$FF and (CycleCounter shr 8);
            SendCmd(cmd_tellMe, LastAddr);
          end;
          Writing := true; // write in the next Cycle
       end
     end else begin
{       if (src=$01) then begin
         if(tgt=$00)and(LastAddr<MyAddr)and(StateOnRead=5) then begin
            StateOnRead := 3;
            MyAddr := 0;
         end else LastAddr := tgt;
       end;
}     end;
     
   end else begin
  { Writing }
     if(Writing)then begin // --- Have right to write  ---
       Reading := true;   // --- Can write only one frame ---
     end else          
   end;
end;
{-----------------------------------------------------------------------------}
end.
