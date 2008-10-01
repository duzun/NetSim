unit StrStackCl;

interface
uses Funcs;

type
{-----------------------------------------------------------------------------}
  TStrStack = class(TObject)
    FinitCicle: Boolean; // True pentru a se opri cand s-a ajuns la unltimul element din bufer
    Success:    Boolean; // Spune daca ultima operatie a avut loc cu succes
  private
    FBuf: TBArArray;
    FRi, FWi: word;
    procedure SetEach(const Value: TBArray);
    function  GetEach: TBArray;
    function  GetArrays(Index: word): TBArray;
    procedure SetArrays(Index: word; const Value: TBArray);
    function  GetSize: word;
    procedure SetSize(const Value: word);
  public
    constructor Create(FinitCic: boolean = true; BufSize: word = 1024);
    procedure Reset; // Reseteaza indicii de citire/scriere
    
    property Size: word read GetSize write SetSize;
    property Each: TBArray read GetEach write SetEach;
    property Arrays[Index: word]: TBArray read GetArrays write SetArrays;

    function IncR(b: word = 1): word;
    function DecW(b: word = 1): word;
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
constructor TStrStack.Create;
begin
  inherited Create;
  FinitCicle := FinitCic;
  Success    := true;
  Size       := BufSize;
  Reset;
end;
{-----------------------------------------------------------------------------}
function TStrStack.GetEach: TBArray;
begin
   if(ready<>0) then begin
     Result  := FBuf[FRi];
     inc(FRi);
     Success := true;
   end else begin
     Result  := GenBAr(0, 0, 7);
     Success := false;
   end;
end;
{-----------------------------------------------------------------------------}
procedure TStrStack.SetEach(const Value: TBArray);
begin
  if(FinitCicle and (FWi + 1 = FRi) ) then exit;
  FBuf[FWi] := Value;
  inc(FWi);
  Success   := true;
end;
{-----------------------------------------------------------------------------}
function TStrStack.GetArrays;
begin
   Success := Index<ready;
   if Success then Result := FBuf[FRi+Index]
              else Result := GenBAr(0, 0, 0);
end;
{-----------------------------------------------------------------------------}
procedure TStrStack.SetArrays;
begin
  if(Index<ready) then      // atribuie
  begin
    FBuf[FRi+Index] := Value;
    Success := true;
  end else
  if (Index=ready) then    // adauga
  begin
    Each    := Value;
    Success := true;
  end else                 // :-(
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
  if(FinitCicle and (FWi + 1 = FRi) ) then begin
     Result := false;
  end else begin   
     Each   := BAr;
     Result := true;
  end;   
end;
{-----------------------------------------------------------------------------}
function TStrStack.IncR;
begin
  if(b > FWi - FRi)then b := FWi - FRi;
  inc(FRi, b);
  Result := b;
end;
{-----------------------------------------------------------------------------}
function TStrStack.DecW;
begin
  if(b > FWi - FRi)then b := FWi - FRi;
  dec(FWi, b);
  Result := b;
end;
{-----------------------------------------------------------------------------}
function TStrStack.GetSize: word; begin Result := Length(FBuf); end;
{-----------------------------------------------------------------------------}
procedure TStrStack.SetSize(const Value: word);
begin
   SetLength(FBuf, Value);
end;
{-----------------------------------------------------------------------------}
end.
