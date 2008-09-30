unit IOStream;
{ Nivelul fizic - scrierea si citirea datelor }
interface
uses
  StrStackCl, Funcs, CmdByte;

{-----------------------------------------------------------------------------}
const
  c_MaxReadBuf  = 512;

  IO_OK        = $01;
  IO_Failed    = $02;
  IO_NoData    = $04;
  IO_WrongData = $08;
  IO_Already   = $10;
  IO_NotReady  = $20;

{-----------------------------------------------------------------------------}
type 
  TIOStream = class(TObject)
  {=========================}
    WSBuf, RSBuf: TStrStack;      // Write and Read string buffers
  {=========================}
  private
    FOpened:  Boolean;
    procedure SetOpened(const Value: Boolean);
    procedure SetFileName(const Value: ShortString);
    procedure SetCycleCounter(const Value: integer);
    function  GetCycleCounter: integer;
  {=========================}
  protected
    F                             : BFile;       // File Pointer
    FN                            : ShortString; // Conection FileName
    RBAr, WBAr, LastBAr           : TBArray;     // Byte Buffers
    ReadResult,    WriteResult    : byte;        //
    LastReadCycle, LastWriteCycle : integer;
    ReadCycle,     WriteCycle     : word;
    OffSetCycle                   : integer;
  {=========================}
  public
    property Opened    : Boolean     read FOpened write SetOpened;   // Connect tu FileName
    property FileName  : ShortString read FN      write SetFileName; // Open on assign 
    property CycleCount: integer     read GetCycleCounter write SetCycleCounter;

    function Open(NameOfFile: ShortString)  : Boolean;
    function MkFile(NameOfFile: ShortString): word;
    function DelFile(): word;

	function NoReadCount   : word;
	function NoWriteCount  : word;
	function ReadPackets   : word;
	function WrittenPackets: word;

    function WriteSBuf: word;
    function ReadSBuf : word;

    function WriteByte(b: byte; poz: byte = 0)   : word;
    function ReadByte(var b: byte; poz: byte = 0): word;
    
    procedure Reset_IO;
    procedure Reset_IO_Buffers;
    
    constructor Create(NameOfFile: ShortString = '');
    destructor  Destroy; override;
  {=========================}
  end;
{-----------------------------------------------------------------------------}

implementation
uses
   ExtCtrls, SysUtils;
{-----------------------------------------------------------------------------}
{ TIOStream }
constructor TIOStream.Create;
begin
  inherited Create;
  WSBuf         := TStrStack.Create;
  RSBuf         := TStrStack.Create;
  FN            := NameOfFile;
  FOpened       := false;
  Reset_IO;
end;
{-----------------------------------------------------------------------------}
procedure TIOStream.Reset_IO_Buffers;
begin
  WSBuf.Reset;
  RSBuf.Reset;
  RBAr:=0; WBAr:=0; LastBAr:=0;
end;
{-----------------------------------------------------------------------------}
procedure TIOStream.Reset_IO;
begin
  LastReadCycle := 0;
  LastWriteCycle:= 0;
  OffSetCycle   := 0;
  WriteCycle    := 0;
  ReadCycle     := 0;

  RBAr:=0; WBAr:=0; LastBAr:=0;
end;
{-----------------------------------------------------------------------------}
{ Cicluri de inactivitate... }
function TIOStream.NoReadCount: word;  begin Result := CycleCount - LastReadCycle; end;
function TIOStream.NoWriteCount: word; begin Result := CycleCount - LastWriteCycle; end;
{-----------------------------------------------------------------------------}
{ Cantitatea de pakete citite / scrise }
function TIOStream.ReadPackets; begin Result := ReadCycle; end;
function TIOStream.WrittenPackets; begin Result := WriteCycle; end;
{-----------------------------------------------------------------------------}
{ Citeste continutul fisierului in RBAr }
function TIOStream.ReadSBuf;
var l: integer;
begin
{$I-}
    Seek(f, 0);
    l := FileSize(f);
    if l > c_MaxReadBuf then l := c_MaxReadBuf;
    if (IOResult <> 0)or(l = -1)or(ReadBAr(f, LastBAr, l) < l) then begin
       ReadResult := IO_Failed;
       Exit;
    end;
{$I+}
    if (l=0) or BArCmp(@RBAr, @LastBAr{, 7}) then begin
      ReadResult := IO_NoData;
      inc(OffSetCycle);
    end else begin
      RBAr          := LastBAr;
      ReadResult    := IO_OK;
      LastReadCycle := CycleCount;
      inc(ReadCycle);
    end;
    Result := ReadResult;
end;
{-----------------------------------------------------------------------------}
{ Scrie datele in fisier }
function TIOStream.WriteSBuf;
var l: word;
begin
  if(Length(WBAr)>0)then begin
     LastBAr       := WBAr; // Urgent packet
     WSBuf.Success := true;
  end else
     LastBAr := WSBuf.Arrays[0];
  if(WSBuf.Success) then begin
{$I-}
    Seek(f, 0);
    l := Length(LastBAr);
    if(IOResult <> 0) or (l>WriteBAr(f, LastBAr, l)) then begin
	   WriteResult := IO_Failed;
       Result      := WriteResult;
       Exit;
    end;
    WriteBAr(f, ToBAr(CycleCount)); // Numaratorul ciclului
{$I+}
    WriteResult    := IO_OK;
    LastWriteCycle := CycleCount;
    if(Length(WBAr)>0)then SetLength(WBAr,0)
                      else WSBuf.IncR;
    inc(WriteCycle); 
  end else begin
    WriteResult := IO_NoData;
    inc(OffSetCycle);
  end;
  Result := WriteResult;
end;
{-----------------------------------------------------------------------------}
{ Functii rudimentare }
function TIOStream.WriteByte;begin Result:=0; {$I-} repeat Seek(f, poz); write(f, b); until IOResult=0; {$I+} Result:=1;end;
function TIOStream.ReadByte; begin Result := 0; {$I-} if FileSize(f)=0 then b:=0 else begin repeat Seek(f, poz); read(f, b); until IOResult=0; Result:=1; end; {$I+} end;
{-----------------------------------------------------------------------------}
{ Incearca sa creeze fisierul de legatura, daca nu exista.  }
function TIOStream.MkFile;
var dir: ShortString;
begin
  if NameOfFile = '' then NameOfFile := FN;
  if NameOfFile = '' then Result := IO_Failed
  else if FileExists(NameOfFile)then begin
    Result := IO_Already or IO_OK;
    FN := NameOfFile;
  end else try
    dir := ExtractFileDir(NameOfFile);
    if(not DirectoryExists(dir)) then MkDir(dir);
    AssignFile(f, NameOfFile);
    Result := IO_OK;
    FN     := NameOfFile;
    try    ReWrite(f);
    except Result := IO_Failed;
    end;
  finally
   begin
     CloseFile(f);
     FOpened := false;
   end;
  end;
end;
{-----------------------------------------------------------------------------}
function TIOStream.DelFile;
begin
   Opened := false;
   if not FileExists(FN) then
     Result := IO_Already or IO_OK
   else try
     if DeleteFile(FN) then Result := IO_OK
                       else Result := IO_Failed;
   except Result := IO_Failed;
   end;
end;
{-----------------------------------------------------------------------------}
{ Deschide fisierul NameOfFile }
function TIOStream.Open(NameOfFile: ShortString): Boolean;
begin
  FileName := NameOfFile;
  Result   := Opened;
end;
{-----------------------------------------------------------------------------}
{ Functi private }
procedure TIOStream.SetOpened(const Value: Boolean);
begin
   {$I-}
   if Value and not FOpened and (MkFile(FN) and IO_OK <> 0)then
     try
       AssignFile(f, FN);
       Reset(f);
       FOpened := true;
       ReadSBuf;
       Opened := (IOResult = 0);
     except Opened := false;
     end else
   if not Value and FOpened then
   try     CloseFile(f);
   finally FOpened := false;
   end;
   {$I+}
end;
{-----------------------------------------------------------------------------}
procedure TIOStream.SetFileName(const Value: ShortString);
begin
  if Value <> FN then begin
    Opened := false;
    FN     := Value;
  end;
  if Value <> '' then Opened := true
                 else DelFile;
end;
{-----------------------------------------------------------------------------}
destructor TIOStream.Destroy; begin Opened := false; inherited Destroy; end;
{-----------------------------------------------------------------------------}
procedure TIOStream.SetCycleCounter; begin OffSetCycle := Value - (ReadCycle + WriteCycle); end;
function  TIOStream.GetCycleCounter; begin Result := ReadCycle + WriteCycle + OffSetCycle; end;
{-----------------------------------------------------------------------------}

end.
