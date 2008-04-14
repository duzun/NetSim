unit StrStackCl;

interface
uses BufferCL, Funcs;

type
  TBStrArray = packed array[0..1024] of TBArray;
{-----------------------------------------------------------------------------}
  TStrStack = object
    FinitCicle: Boolean;
    Success:    Boolean; // Spune daca ultima operatie a avut loc cu succes
  private
    FBuf: TBStrArray;
    FRi, FWi: byte;
    procedure SetEach(const Value: TBArray);
    function GetEach: TBArray;
    function GetArrays(Index: byte): TBArray;
    procedure SetArrays(Index: byte; const Value: TBArray);
  public
    constructor Create(FinitCic: boolean = true);
    procedure Reset;
    property Each: TBArray read GetEach write SetEach;
    property Arrays[Index: byte]: TBArray read GetArrays write SetArrays;

    function IncR(b: byte = 1): byte;
    function DecW(b: Byte = 1): Byte;
    function Read(var BAr: TBArray):  boolean;  {Use Read and Write instead of Each if you}
    function Write(var BAr: TBArray): boolean;  {need to know if the opperation is done   }

    function ready: byte;
  end;
  PStrStack = ^TStrStack;
{-----------------------------------------------------------------------------}
implementation

{ TStrStack }
{-----------------------------------------------------------------------------}
function  TStrStack.ready; begin Result := FWi - FRi; end;
{-----------------------------------------------------------------------------}
procedure TStrStack.Reset; begin FWi:=0; FRi:=0; end;
{-----------------------------------------------------------------------------}
constructor TStrStack.Create(FinitCic: boolean = true);
begin
  FinitCicle := FinitCic;
  Success := true;
  Reset;
end;
{-----------------------------------------------------------------------------}
function TStrStack.GetEach: TBArray;
begin
   if(ready<>0) then begin
     Result := FBuf[FRi];
     inc(FRi);
     Success := true;
   end else begin
     Result := GenBAr(0, 0, 7);
     Success := false;
   end;
end;
{-----------------------------------------------------------------------------}
procedure TStrStack.SetEach(const Value: TBArray);
begin
  if(FinitCicle and (FWi + 1 = FRi) ) then exit;
  FBuf[FWi] := Value;
  inc(FWi);
  Success := true;
end;
{-----------------------------------------------------------------------------}
function TStrStack.GetArrays(Index: byte): TBArray;
begin
   if(Index<ready) then begin
     Result := FBuf[FRi+Index];
     Success := true;
   end else begin
     Result := GenBAr(0, 0, 0);
     Success := false;
   end;
end;
{-----------------------------------------------------------------------------}
procedure TStrStack.SetArrays(Index: byte; const Value: TBArray);
begin
  if(Index<ready) then begin
    FBuf[FRi+Index] := Value;
    Success := true;
  end else
    if (Index=ready) then begin
      Each := Value;
      Success := true;
    end else
      Success := false;
end;
{-----------------------------------------------------------------------------}
function TStrStack.Read(var BAr: TBArray): boolean;
begin
  Result := false;
  if ready = 0 then exit;
  BAr := Each;
  Result := true;
end;
{-----------------------------------------------------------------------------}
function TStrStack.Write(var BAr: TBArray): boolean;
begin
  Result := false;
  if(FinitCicle and (FWi + 1 = FRi) ) then exit;
  Each := BAr;
  Result := true;
end;
{-----------------------------------------------------------------------------}
function TStrStack.IncR(b: byte): byte;
begin
  if(b > FWi - FRi)then b:= FWi - FRi;
  inc(FRi, b);
  Result := b;
end;
{-----------------------------------------------------------------------------}
function TStrStack.DecW(b: Byte): Byte;
begin
  if(b > FWi - FRi)then b:= FWi - FRi;
  dec(FWi, b);
  Result := b;
end;
{-----------------------------------------------------------------------------}
end.
