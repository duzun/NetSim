unit IOStreams;

interface
uses
  BufferCl, StrStackCl, Funcs, CmdByte;

{-----------------------------------------------------------------------------}
const

  c_MaxReadBuf  = 512;

  IO_OK       = $01;
  IO_NotReady = $02;
  IO_Already  = $04;
  IO_Failed   = $08;
  IO_NoData   = $10;
  IO_WrongData= $20;

type
{-----------------------------------------------------------------------------}
  TIOStr = class
  {=========================}
    WSBuf, RSBuf: TStrStack;      // Write and Read string buffers
    WBuf, RBuf:   TBuffer;        // Write and Read buffers
  {=========================}
  private
    RB:        byte;
    TMPB:      byte;
  {=========================}
  protected
    F:         BFile;
    FN:        ShortString;       // Conection FileName
    RBAr, WBAr, lBAr: TBArray;    // Byte Buffers
    LastRStat, LastWStat: word;
  {=========================}
  public
    constructor Create(FileName: ShortString = '');
    function GetFileName: ShortString;

    procedure WriteSBuf;
    procedure ReadSBuf;

    function WriteByte(b: byte; poz: byte = 0): word;
    function ReadByte(var b: byte; poz: byte = 0): word;
  {=========================}
  end;
{-----------------------------------------------------------------------------}

implementation
uses
   ExtCtrls;
{-----------------------------------------------------------------------------}
{ TIOStr }
constructor TIOStr.Create;
begin
  WBuf.Create;
  RBuf.Create(4096);
  WSBuf.Create;
  RSBuf.Create;
  FN := FileName;
end;
{-----------------------------------------------------------------------------}
procedure TIOStr.ReadSBuf;
var i: IndexType;
    l: Integer;
begin
{$I-}
    Seek(f, 0);
    l := FileSize(f);
    if l > c_MaxReadBuf then l := c_MaxReadBuf;
    i := 0;
    SetLength(lBAr, l);
    while(i<l)do begin
      read(f, lBAr[i]);
      if(IOResult <> 0) then begin LastRStat := IO_Failed; Exit; end;
      inc(i);
    end;
{$I+}
    if (l=0)or BArCmp(@RBAr, @lBAr{, 7}) then begin
      LastRStat := IO_NoData;
    end else begin
      RBAr := lBAr;
      LastRStat := IO_OK;
    end;
end;
{-----------------------------------------------------------------------------}
procedure TIOStr.WriteSBuf;
var i, l: IndexType;
begin
  WBAr := WSBuf.Arrays[0];
  if (WSBuf.Success) then begin
{$I-}
    Seek(f, 0);
    l := Length(WBAr);
    i := 0;
    while(i<l)do begin
      write(f, WBAr[i]);
      if(IOResult <> 0) then begin LastWStat := IO_Failed; Exit; end;
      inc(i);
    end;
{$I+}
    LastWStat := IO_OK;
    WSBuf.IncR;
  end else begin
    LastWStat := IO_NoData;
  end;
end;
{-----------------------------------------------------------------------------}
function TIOStr.WriteByte;
begin
  Result:=0;
  {$I-}
  repeat
      Seek(f, poz);
      write(f, b);
  until IOResult = 0;
  {$I+}
  Result:=1;
end;
{-----------------------------------------------------------------------------}
function TIOStr.ReadByte;
begin
    Result := 0;
    {$I-}
    if FileSize(f)=0 then b:=0
    else begin
      repeat
        Seek(f, poz);
        read(f, b);
      until IOResult = 0;
      Result:=1;
    end;
    {$I+}
end;
{-----------------------------------------------------------------------------}
function TIOStr.GetFileName: ShortString; begin Result:=FN; end;
{-----------------------------------------------------------------------------}
end.
