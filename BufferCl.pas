unit BufferCl;

interface
const
  BufSize = 1024;  {Trebuie sa fie 2 la o putere}
  BufMask = BufSize-1;
  
type
  IndexType = Word;
  TBArray = packed array of byte;
  PBArray = ^TBArray;
{-----------------------------------------------------------------------------}
  TBuffer = object
    FinitCicle: Boolean;
  private
    FBuf: TBArray;
    FSize:  IndexType;
    FRi, FWi: IndexType;
    procedure SetEach(const Value: byte);
    function  GetEach: byte;
    procedure SetBuf(const Value: TBArray);
    function  GetBuf: TBArray;
    procedure SetSize(const Value: IndexType);
  public
    constructor Create(BSize: IndexType = BufSize);
    property Each: byte read GetEach write SetEach;
    property Size: IndexType read FSize write SetSize;
    property Buf: TBArray read GetBuf write SetBuf;

    function ready: IndexType;
    function ReadReady(): TBArray;
    function OnlyRead(var r: TBArray): IndexType;
    function sReadReady(): ShortString;
    procedure Reset;
    procedure Skip(nr: IndexType = 1);
  end;
  PBuffer = ^TBuffer;
{-----------------------------------------------------------------------------}
Procedure FillBAr(var BAr: TBArray; Mask: byte; Index: IndexType = 0;Len: IndexType = BufMask);
Function GenBAr(Mask: byte = 0; Index: IndexType = 0;Len: IndexType = BufMask): TBArray;
{-----------------------------------------------------------------------------}

implementation
{-----------------------------------------------------------------------------}
Procedure FillBAr;
begin
  if Length(BAr)<Index+Len then SetLength(BAr, Index+Len);
  while(Len <> 0) do begin
    BAr[Index] := Mask;
    inc(Index);  dec(Len);
  end;
end;
{-----------------------------------------------------------------------------}
Function GenBAr; var r: TBArray;  begin FillBAr(r, Mask, Index, Len); Result := r;end;
{-----------------------------------------------------------------------------}
{ TBuffer }
{-----------------------------------------------------------------------------}
function  TBuffer.ready;
begin
  if FWi < FRi then Result := FSize + FWi - FRi
               else Result := FWi - FRi;
end;
{-----------------------------------------------------------------------------}
procedure TBuffer.Reset; begin  FWi:=0; FRi:=0; end;
{-----------------------------------------------------------------------------}
constructor TBuffer.Create;
begin
  Reset;
  Size := BSize;
  FBuf[FRi] := 0;
end;
{-----------------------------------------------------------------------------}
procedure TBuffer.Skip(nr: IndexType);
begin
     inc(FRi, nr);
     if FRi>=FSize then FRi := FRi - FSize;
end;
{-----------------------------------------------------------------------------}
function TBuffer.GetEach: byte;
begin
   if(ready<>0)then begin
     Result := FBuf[FRi];
     inc(FRi);
     if FRi=FSize then FRi := 0;
   end else begin
     Result := 0;
   end;
end;
{-----------------------------------------------------------------------------}
procedure TBuffer.SetEach(const Value: byte);
begin
  FBuf[FWi] := Value;
  inc(FWi);
  if FWi=FSize then FWi := 0;
end;
{-----------------------------------------------------------------------------}
function TBuffer.GetBuf: TBArray;
var r: TBArray;
    i, j: IndexType;
begin
    j:= FWi;
    SetLength(r, BufSize);
    for i:=0 to BufMask do begin
      inc(j);
      r[i+1]:=(FBuf[j]);
    end;
      r[0] := $FF;
    Result := r;
end;
{-----------------------------------------------------------------------------}
procedure TBuffer.SetBuf(const Value: TBArray);
var i, j: byte;
begin
    j:= FWi;
    for i:=0 to Length(Value)-1 do begin
      Each := Value[i];
{      inc(j);
      FBuf[j] := Value[i];}
    end;
end;
{-----------------------------------------------------------------------------}
function TBuffer.ReadReady(): TBArray;
var i, l: byte;
    r: TBArray;
begin
  i := 0;
  l := ready;
  SetLength(r, l);
  while(i<l)do begin
    r[i] := Each;
    inc(i);
  end;
  Result := r;
end;
{-----------------------------------------------------------------------------}
function TBuffer.sReadReady: ShortString;
var i, l: byte;
    r: ShortString;
begin
  i := 0;
  l := ready;
  Length(r) := l;
  while(i<l)do begin
    r[i+1] := chr(Each);
    inc(i);
  end;
  Result := r;
end;
{-----------------------------------------------------------------------------}
procedure TBuffer.SetSize(const Value: IndexType);
begin
  FSize := Value;
  SetLength(FBuf, FSize);
  FRi := FRi mod FSize;
  FWi := FWi mod FSize;
end;
{-----------------------------------------------------------------------------}
function TBuffer.OnlyRead;
var i, l: byte;
    ibak: IndexType;
begin
  i := 0;
  l := ready;
  SetLength(r, l);
  ibak := FRi;
  while(i<l)do begin
     r[i] := Each;
     inc(i);
  end;
  FRi := ibak;
  Result := l;
end;
{-----------------------------------------------------------------------------}
end.
