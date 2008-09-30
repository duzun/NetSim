Unit Pack;
interface
Uses Funcs;

Type
  TPack = class
   private
    procedure SetBAr(Value: TBArray);
    function GetBAr: TBArray;
   public
     cmd, len, tgt, src, p:  byte;
     l:  word;
     SID: integer;
     Data: TBArray;

     Property Frame: TBArray  read GetBAr write SetBAr;

     constructor Create(BAr: TBArray);
   end; 

implementation


{ TPack }

constructor TPack.Create(BAr: TBArray);
begin
  inherited Create;
  Frame := BAr;
end;

function TPack.GetBAr: TBArray;
var d: TBArray;
begin
  if(l=0)then begin
    d := Data;
    Insert(cmd, d);
    Result := FormFrame(d, l, src, tgt);
  end else begin
    Result := FormFrame(Data, l, src, tgt);
  end;
end;

procedure TPack.SetBAr(Value: TBArray);
var r: boolean;
begin
   p   := 0;
   r   := SplitFrame(Value, p, len, src, tgt)=0;
   SID := BAr2Int(Value, p+len+1, 4);
   if not r then begin
     cmd   := 0;
     Data  := 0;
     SID   := 0;
   end else begin
     Data  := Copy(Value, p+1, len);
     cmd   := Value[p];
   end;
   l := 0;
end;

end.
