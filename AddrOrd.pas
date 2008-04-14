unit AddrOrd;

interface
uses Funcs;
type
  TAddrOrd = class
  private
     Buf: TBArray;
     i:   word;
  public
    constructor Create;
    function Add(addr: byte = 0): boolean;

  end;
implementation

{ TAddrOrd }

function TAddrOrd.Add(addr: byte): boolean;
var j: word;
    r: boolean;
begin
  r:=true;
  if addr=0 then begin         // Adresa nu are nimic de comunicat
     Buf[i]:=0;
     Result:=true;
  end else
  if addr = Buf[i] then begin  // Aceeasi adresa
    Result:=true;
  end else
  if (i = length(Buf)-1)and(Buf[i]=0) then begin  // Octetul liber, pentru initierea comunicarii
     Buf[i]:=addr;
     Result:=true;
  end else begin                  // Violare adresa
     Result:=false;
  end;
    inc(i);
    if i = length(Buf) then begin
      i:=0;

    end;

    j:=0;
  r:=false;
  while not r and(j<length(Buf))do begin
    if Buf[j]=addr then begin
      r := true;
      i:=j;
    end;
    inc(j);
  end;
  if not r then begin
    SetLength(Buf, j+1);
    Buf[j]:=addr;
  end;
  Result := r;
end;

constructor TAddrOrd.Create;
begin
  setlength(Buf, 1);
  i:=0;
  Buf[i]:=0;
end;

end.
