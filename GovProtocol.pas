unit GovProtocol;
{ Nivelul sesiune }
{ Aici este encapsulat protocolul de comunicare cu moderator (Governator) }
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
  ProtocolBase, IOStream, Funcs, CmdByte, 
  ExtCtrls, Classes, SysUtils;
{-----------------------------------------------------------------------------}
const Max_01_silent = 100;
{-----------------------------------------------------------------------------}
type
  TGovProtocol = class(TProtocolBase)
     LastAddr: byte;
     RetryCounter: word;
  private
    ToWrite: boolean;
    StateOnRead: word;

  public
    constructor Create(AOwner: TComponent; FileName: ShortString = '');

    function  getState():word;
    
    function  CanWrite: boolean;
    function  CanRead:  boolean;
    procedure OnConect(); override;
    procedure OnRead(var State: word); 
    procedure TimerProc(Sender: TObject); 
   end;
{-----------------------------------------------------------------------------}
implementation
{-----------------------------------------------------------------------------}
{ TGovProtocol }
{-----------------------------------------------------------------------------}
constructor TGovProtocol.Create;
begin  
  inherited Create(AOwner, FileName);
  LastAddr := $0;
  Writing  := false;
  ToWrite  := false;
  OnTimer  := TimerProc;
end;                                             
{-----------------------------------------------------------------------------}
function TGovProtocol.getState: word; begin Result := StateOnRead; end;
{-----------------------------------------------------------------------------}
procedure TGovProtocol.OnConect();
begin                                                                          
  StateOnRead := 0; // begining 
//  MyAddr := 0;  
//   MaxAddr := 0;  
  LastAddr := 0;  
end;
{-----------------------------------------------------------------------------}
procedure TGovProtocol.OnRead;
begin
    case ReadResult of
     IO_Failed: State := 0; // Reinitializare la eroare
     IO_NoData: ;
     IO_OK:
        if src = MyAddr then     
           SendLog(byte2str(tgt)+'<-| '+BAr2ByteStr(RBAr, len+4))
        else    
           SendLog(byte2str(src)+'->| '+BAr2ByteStr(RBAr, len+4));
    end;
  case State of
  0:begin  // Initializare
     SendLog('OnRead: State='+inttostr(State));
     RetryCounter := 4; // Nr de incercari
     if MyAddr <> 0 then State := 2 else State := 3;
    end;
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
      MaxAddr  := $00;
      if MyAddr = 0 then MyAddr := $01;
      State    := 5;
  end;
  3:begin  // Asteapta adresa
    if(ReadResult=IO_OK)then begin
      if(tgt=$00)and(len>0)then
        {/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/}
        case Data[0] of
        cmd_tellMe:
             if (src=$01) then begin
               SendCmdNow(cmd_giveAddr, ToAll);
               ToWrite := true;
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
      if(src<>MyAddr)and((tgt=$00)or(tgt=MyAddr))and(len>0)then
        {/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/}
        case Data[0] of
        cmd_tellMe:
            if(src=$01) then begin
              SendCmdNow(cmd_start, ToAll);
              ToWrite := true;
              State   := 5;
            end;
        cmd_isPresent:
            SendCmdNow(cmd_OK or cmd_isPresent, src);
        end;
        {/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/}
    end
  end;
  5:begin  // Citire date
    if(ReadResult=IO_OK)then begin
      if (src<>ToAll)and(src > MaxAddr) then MaxAddr := src;
      if((src<>MyAddr)and(tgt=MyAddr)or(tgt=ToAll))and(len>0)then
      {/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/}
      case Data[0] of   // parsing commands

      cmd_isPresent: 
         SendCmdNow(Data[0] or cmd_OK, src);
         
      cmd_start: 
           if MaxAddr+1=src then inc(MaxAddr);
         
      cmd_stop: 
         begin
           if MyAddr=MaxAddr then begin
              MyAddr := src;
              SendCmdNow(cmd_readID);
              dec(MaxAddr);
           end else if MyAddr=$01 then begin
              SendNow(cmd_giveAddr or cmd_OK, src, MaxAddr);
           end;
         end;
         
      cmd_giveAddr:
         begin
            SendNow(cmd_giveAddr or cmd_OK, MaxAddr+1, src);
         end;
         
      cmd_readID: 
         begin
//            SendCmdNow(cmd_readID or cmd_Ok); 
         end;

      cmd_tellMe:
            ToWrite := true;
      
      cmd_OK or cmd_giveAddr:
         begin
            if MyAddr = MaxAddr then dec(MaxAddr);
            MyAddr := Data[1];
            SendCmdNow(cmd_readID);
         end;
         
      cmd_OK or cmd_readID: 
         IDs[src] := Copy(Data,1,len-1);
         
      cmd_Data:            
         begin
            LastBAr := Copy(Data, 1);
            IncBAr(LastBAr, 1, src);
            RSBuf.Each := LastBAr;
         end;
         
      else 
         begin
            LastBAr := Data;
            IncBAr(LastBAr, 1, src);
            RSBuf.Each := LastBAr;
         end;
      end else begin  // Cand mesajul nu este adresat mie
        case Data[0] of

        cmd_OK or cmd_giveAddr:
           if tgt = MaxAddr then dec(MaxAddr);

        cmd_start: 
           if MaxAddr+1=src then inc(MaxAddr);

        cmd_stop: 
           if src = MaxAddr then dec(MaxAddr);
             
        end;       
      end;
      {/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/*\*/}
    end;
      if (NoReadCount >= Max_01_silent) then begin
      if (Max_01_silent - NoReadCount = (MaxAddr - MyAddr)*Max_01_silent) then begin
         MaxAddr := MyAddr - 1;
         MyAddr := $01;                 
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
procedure TGovProtocol.TimerProc;
begin
   // --- After read ---
   if Reading then begin
      p:=0;
      if ReadResult = IO_OK then begin
        SplitRBAr;
//         if (tgt<>ToAll)and(tgt > MaxAddr) then MaxAddr := tgt;
      end else begin
        len:=0;
        src:=0;
      end;
      OnRead(StateOnRead);  // --- Data parsing ---
   // --- After write  ---
   end else if Writing then
      { $01 is DJ, Boss }
      if(MyAddr=$01)then begin
          inc(LastAddr);     // Who can write?
          if LastAddr > MaxAddr then LastAddr:=0;
          if LastAddr <> MyAddr then SendCmd(cmd_tellMe, LastAddr);
      end else begin
      
	  end;

   Reading := CanRead;  // --- Read in the next Cycle
   Writing := CanWrite; // --- Write only one frame in the next Cycle ---
end;
{-----------------------------------------------------------------------------}
function TGovProtocol.CanRead: boolean;
begin
  Result := CycleCount and 1 = 1;
end;
{-----------------------------------------------------------------------------}
function TGovProtocol.CanWrite: boolean;
begin
   Result := (MyAddr<>$01) and (CycleCount and 3 = 2) and ToWrite or (MyAddr=$01) and (CycleCount and 3 = 0);
end;
{-----------------------------------------------------------------------------}
end.
