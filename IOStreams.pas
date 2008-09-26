unit IOStreams;
{ I Nivel: fizic }
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

type 
{-----------------------------------------------------------------------------}
  TIOStr = class(TObject)
  {=========================}
    WSBuf, RSBuf: TStrStack;      // Write and Read string buffers
  {=========================}
  private
    FOpened:  Boolean;
    procedure SetOpened(const Value: Boolean);
    procedure SetFileName(const Value: ShortString);
  {=========================}
  protected
    F:  BFile;                    // File Pointer
    FN: ShortString;              // Conection FileName
    RBAr, WBAr, lBAr: TBArray;    // Byte Buffers
    ReadResult, WriteResult: word;
  {=========================}
  public
    property Opened: Boolean read FOpened write SetOpened;
    Property FileName: ShortString read FN write SetFileName;
    
    function Open(NameOfFile: ShortString): Boolean;
    function MkFile(NameOfFile: ShortString): word;

    function WriteSBuf: word;
    function ReadSBuf: word;

    function WriteByte(b: byte; poz: byte = 0): word;
    function ReadByte(var b: byte; poz: byte = 0): word;
    constructor Create(NameOfFile: ShortString = '');
  {=========================}
  end;
{-----------------------------------------------------------------------------}

implementation
uses
   ExtCtrls, SysUtils;
{-----------------------------------------------------------------------------}
{ TIOStr }
constructor TIOStr.Create;
begin
  inherited Create;
  WSBuf   := TStrStack.Create;
  RSBuf   := TStrStack.Create;
  FN      := NameOfFile;
  FOpened := false;
end;
{-----------------------------------------------------------------------------}
function TIOStr.ReadSBuf;
var i: word;
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
      if(IOResult <> 0) then begin
	     ReadResult := IO_Failed;
         Result     := ReadResult;
		 Exit;
	  end;
      inc(i);
    end;
{$I+}
    if (l=0) or BArCmp(@RBAr, @lBAr{, 7}) then begin
      ReadResult := IO_NoData;
    end else begin
      RBAr := lBAr;
      ReadResult := IO_OK;
    end;
    Result := ReadResult;
end;
{-----------------------------------------------------------------------------}
function TIOStr.WriteSBuf;
var i, l: word;
begin
  WBAr := WSBuf.Arrays[0];
  if (WSBuf.Success) then begin
{$I-}
    Seek(f, 0);
    l := Length(WBAr);
    i := 0;
    while(i<l)do begin
      write(f, WBAr[i]);
      if(IOResult <> 0) then begin
	     WriteResult := IO_Failed;
         Result      := WriteResult;
		 Exit;
      end;
      inc(i);
    end;
{$I+}
    WriteResult := IO_OK;
    WSBuf.IncR;
  end else begin
    WriteResult := IO_NoData;
  end;
  Result := WriteResult;
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
function TIOStr.MkFile;
begin
  if NameOfFile = '' then NameOfFile := FN;
  if NameOfFile = '' then Result := IO_Failed
  else if FileExists(NameOfFile)then begin
    Result := IO_Already or IO_OK;
    FN := NameOfFile;
  end else try
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
function TIOStr.Open(NameOfFile: ShortString): Boolean;
begin
  FileName := NameOfFile;
  Result   := Opened;
end;
{-----------------------------------------------------------------------------}
procedure TIOStr.SetOpened(const Value: Boolean);
begin
   if Value and not FOpened and (MkFile(FN) and IO_OK <> 0)then
     begin
       AssignFile(f, FN);
       Reset(f);
       FOpened := true;
     end else
   if not Value and FOpened then begin
     CloseFile(f);
     FOpened := false;
   end;
end;
{-----------------------------------------------------------------------------}
procedure TIOStr.SetFileName(const Value: ShortString);
begin
  if Value <> FN then begin
	 Opened := false;
     FN     := Value;
  end;
  if Value <> '' then Opened := true;
end;
{-----------------------------------------------------------------------------}
end.
