unit StrStackCl;

interface
uses BufferCL;

type
  TBStrArray = packed array[0..255] of TBArray;
{-----------------------------------------------------------------------------}
  TStrStack = object
    FinitCicle: Boolean;
  private
    FBuf: TBStrArray;
    FRi, FWi: byte;
    procedure SetEach(const Value: TBArray);
    function GetEach: TBArray;
  public
    constructor Create(FinitCic: boolean = true);
    procedure Reset;
    property Each: TBArray read GetEach write SetEach;

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
  Reset;
end;
{-----------------------------------------------------------------------------}
function TStrStack.GetEach: TBArray;
begin
   if(ready<>0) then begin
     Result := FBuf[FRi];
     inc(FRi);
   end else begin
     Result := GenBAr(0, 0, 7);
   end;
end;
{-----------------------------------------------------------------------------}
procedure TStrStack.SetEach(const Value: TBArray);
begin
  if(FinitCicle and (FWi + 1 = FRi) ) then exit;
  FBuf[FWi] := Value;
  inc(FWi);
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
end.
