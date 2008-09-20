unit Funcs;

interface
uses
  Classes, SysUtils;

const
  WrongData   = $8000;
  WrongLen    = $4000;
  NotComplete = $0100;
  b_TgtSrc    = $80;
  b_AddLen    = $40;
  
type
  TBArray   = packed array of byte;
  TBArArray = packed array of TBArray;
  PBArray   = ^TBArray;
  PBArArray = ^TBArArray;
  BFile = File of Byte;

function chr2num(c: char):word;
function num2chr(nm: byte):char;
function str2byte(byte_str: String): Word;
function byte2str(bt: word; glow: String = ' '): String;

function Copy(var data:TBArray; Index: word = 0; Len: word = 0): TBArray; {Analogic cu Copy pentru String}
function BArCmp(a1,a2: PBArray; len: word=0): boolean;           {Compara primele len elemmente din a1 si a2}
function DecBAr(var BAr: TBArray; l: word = 1): word;            {Elimina l elemente de la coada BAr. return length}
function IncBAr(var BAr: TBArray; l: word = 1; b: byte=0): word; {Adauga b de l ori la coada BAr. return length}
function PopBAr(var BAr: TBArray; size: byte = 1): LongWord;     {Arunca ultimul element din BAr de lungimea size:(1..4)}
function ShiftBAr(var BAr: TBArray; size: byte = 1): LongWord;   {Arunca primul  element din BAr de lungimea size:(1..4)}
function Str2BAr(s: String):TBArray;
function BAr2Str(s: TBArray):String;

function ISOLen(data: PBArray; var p: byte): boolean;
function ISOCmd(data: PBArray; var src, tgt: byte): byte;

function ISOForm(var data: TBArray; var p:word; src:byte=0; tgt:byte=0): TBArray;

function ISOSplit(var frame: TBArray;var p, len, src, tgt: byte): word;            overload;
function ISOSplit(var frame: TBArray;var p, len: byte): word;                      overload;
function ISOSplit(var frame: TBArray;var data: TBArray; var src, tgt: byte): word; overload;
function ISOSplit(var frame: TBArray;var data: TBArray; var p,len,src,tgt: byte): word; overload;

function ArISOForm(var data: TBArray; src:byte=0; tgt:byte=0): TBArArray;
function ArISOSplit(var frame: TBArArray;var src, tgt: byte): TBArray;
{-----------------------------------------------------------------------------}
implementation
{-----------------------------------------------------------------------------}
function ISOForm(var data: TBArray; var p:word; src:byte=0;tgt:byte=0): TBArray;
var r: TBArray;
    i, l: word;
    len, b, chk: byte;
begin
   l := Length(data);
   if(l<=p) then exit;
   i:=1;
   chk:=0;
   b:=0;
   // Len Limit
   if l > $FF then begin     // Sunt mai multe pakete
      inc(b, b_AddLen);      // Nu se mai utilizeaza lungimea, fiind implicit 255
      len := (l-p) div $FF;  // Contorul descrescator pana la 0
      if(len=0)then begin
        dec(l, p);           // Lungimea specificata
      end else begin
        l := $FF;            // Lungimea implicita
      end;
   end else begin            // Un singur paket
      dec(l, p);
      len:=l;
   end;
   SetLength(r, l + 5); // 5 = b0+tgt+src+len+chk
   // Target / Source
   if(tgt or src<>0) then begin
      inc(b, b_TgtSrc);
      r[i]:=src; inc(i);
      r[i]:=tgt; inc(i);
      inc(chk, tgt + src);
   end;
   // Len Byte
   if(len >= (1 shl 6)) then begin
     r[i]:=len; inc(i);
     inc(chk, len);
   end else begin
     if(len=0)then begin // len e contor, nu lungime
        r[i]:=l; inc(i);
        inc(chk, l);
     end else
        inc(b, len);
   end;
   // Settings Byte
   r[0]:=b;
   inc(chk, b);
   // Coping Data
   inc(l, i);
   while(i<l)do begin
      r[i] := data[p];
      inc(chk, r[i]);
      inc(i); inc(p);
   end;
   r[i]:=chk;
   // Final adjustment
   SetLength(r, i+1);
   Result := r;
end;
{-----------------------------------------------------------------------------}
function ArISOForm(var data: TBArray; src:byte=0;tgt:byte=0): TBArArray;
var p, l: word;
    r: TBArArray;
    i: byte;
begin
  p:=0;
  l:=Length( data );
  SetLength(r, l div $FF + 1);
  for i:=0 to Length(r)-1 do r[i] := ISOForm(data, p, src, tgt);
  Result:=r;
end;
{-----------------------------------------------------------------------------}
function ArISOSplit(var frame: TBArArray;var src, tgt: byte): TBArray;
var p, l: word;
    r, d: TBArray;
    i: byte;
begin
    p:=0;
    l := length(frame);
    for i:=0 to l-1 do ;
end;
{-----------------------------------------------------------------------------}
function ISOSplit(var frame: TBArray;var p, len, src, tgt: byte): word;  overload;
var chc, b: byte;
    i, r: word;
begin
  Result := WrongLen;
  r      := 0;
  if(Length(frame)<3)then exit;
  b   := frame[p];
  len := b and $3F;
  inc(p);

  if frame[0] and b_TgtSrc <> 0 then begin
    src := frame[p];
    tgt := frame[p+1];
    inc(p, 2);
  end else begin
    tgt:=0; src:=0;
  end;

  if len = 0 then begin
    if (Length(frame)<p) then exit;
    len := frame[p];
    inc(p);
  end else if b and b_AddLen <> 0 then begin
    len:=$FF;
    inc(r, NotComplete);
  end;

  i := len + p;
  if (i + 1 > Length(frame)) then begin
    Result := WrongLen or (i + 1 - Length(frame)) or r;
    exit;
  end;
  chc := frame[i];

  while(i>0)do begin
    dec(i);
    dec(chc, frame[i]);
  end;
  if chc <> 0 then r := WrongData or r;
  Result := r;
end;
{-----------------------------------------------------------------------------}
function ISOSplit(var frame: TBArray;var data: TBarray; var p, len, src, tgt: byte): word; overload;
var i: word;
begin
  i := ISOSplit(frame, p, len, src, tgt);
  if i and (WrongData or WrongLen) = 0 then begin
    data := Copy(frame, p, len);
    Result := 0;
  end else Result := i;
end;
{-----------------------------------------------------------------------------}
function ISOSplit(var frame: TBArray;var data: TBarray; var src, tgt: byte): word; overload;
var p, len: byte;
begin p:=0; Result := ISOSplit(frame, data, p, len, src, tgt); end;
{-----------------------------------------------------------------------------}
function ISOSplit(var frame: TBArray;var p, len: byte): word;  overload;
var i: byte;
begin  Result := ISOSplit(frame, p, len, i, i); end;
{-----------------------------------------------------------------------------}
function ISOCmd;
var p, len: byte;
begin
   ISOSplit(data^, p, len, src, tgt);
   Result := data^[p];
end;
{-----------------------------------------------------------------------------}
function ISOLen(data: PBArray; var p: byte): boolean;
begin
  Result := false;                              // in the case if no data :-(
  if (data=nil) or (Length(data^)=0) then exit; // no data -> exit :-(
  p := data^[0];                                // suppose len pos is 0
  if p and $3F = 0 then begin                   // 6 bits not enough for len
     if (data^[0] and b_TgtSrc)<>0 then p:=3 else p:=1; // len pos in data   
     if Length(data^) <= p then exit;           // len out of data
     p := data^[p];                             // get the len byte
  end else
  if (p and b_AddLen <> 0)then p := $FF        // data bigger then one packet
                          else p := p and $3F; // len is stored only in 6 bits
  Result := true;                              // data len determined :-)
end;
{-----------------------------------------------------------------------------}
function Str2BAr(s: String):TBArray;
var w: LongWord;
    r: TBArray;
begin
  w := length(s);
  setLength(r, w);
  while w<>0 do begin
    r[w-1] := ord(s[w]);
    dec(w);
  end;
  Result := r;
end;
{-----------------------------------------------------------------------------}
function BAr2Str(s: TBArray):String;
var w: LongWord;
    r: String;
begin
  w := length(s);
  setLength(r, w);
  while w<>0 do begin
    r[w] := chr(s[w-1]);
    dec(w);
  end;
  Result := r;
end;
{---------------------------------------------------------------------------------------------------------}
{ Converts a hexadecimal digit character into its' numerical value                                        }
{---------------------------------------------------------------------------------------------------------}
function chr2num(c: char):word;
var ch: byte;
begin
  ch := ord(c);
  if(($29<ch) and (ch<$40)) then begin Result:=ch-$30; exit; end; ch:=ch or $20;
  if(($60<ch) and (ch<$67)) then begin Result:=ch-$57; exit; end;
  Result := WrongData;
end;
{---------------------------------------------------------------------------------------------------------}
function num2chr(nm: byte):char;
var r: byte;
begin
	r := nm and $0F or $30;
	if(r > $39) then r :=r + $07;
	Result := chr(r);
end;
{---------------------------------------------------------------------------------------------------------}
{ Converts a textual hexadecimal representation of a byte into its' numerical value.                      }
{ If the $byte_str is longer or shotter than 2 characters, false is returned.                             }
{---------------------------------------------------------------------------------------------------------}
function str2byte(byte_str: String): Word;
var r: word;
begin
  Result := WrongData;
  if(Length(byte_str)<>2) then exit;
  r := chr2num(byte_str[1]);
  if(r and WrongData <> 0) then exit;
  r := (r shl 4) or chr2num(byte_str[2]);
  if(r and WrongData <> 0) then exit;
  Result := r;
end;
{---------------------------------------------------------------------------------------------------------}
function byte2str; begin Result := num2chr(Byte(bt) shr 4) + num2chr(Byte(bt)) + glow; end;
{-----------------------------------------------------------------------------}
function BArCmp;
var m1, m2: word;
begin
  m1 := length(a1^);
  m2 := length(a2^);
  Result:=false;
  if(len=0)then if(m1<>m2)then exit else len:=m1 else if(len>m2)or(len>m1)then exit;

  while(len>0)do begin
    dec(len);
    if a1^[len]<>a2^[len] then exit;
  end;
  Result:=true;
end;
{-----------------------------------------------------------------------------}
function DecBAr(var BAr: TBArray; l: word = 1): word;
var r: word;
begin
  r := length(BAr);
  if r<l then r := 0 else dec(r,l);
  SetLength(BAr, r);
  Result := r;
end;
{-----------------------------------------------------------------------------}
function IncBAr(var BAr: TBArray; l: word = 1; b: byte=0): word;
var r: word;
begin
  r := length(BAr);
  inc(l, r);
  SetLength(BAr, l);
  while r<l do begin
    BAr[r] := b;
    inc(r);
  end;
  Result := r;
end;
{-----------------------------------------------------------------------------}
function PopBAr(var BAr: TBArray; size: byte): LongWord;
var r: LongWord; l: word;
begin
  l := length(BAr);
  r := 0;
  if (size > 4) then size := 1; {1 <= size <= 4}
  while (size>0) and (l>0) do begin
    dec(l);
    dec(size);
    r := (r shl 8) or BAr[l]; {BAr[l]: byte}
  end;
  SetLength(BAr, l);
  Result := r;
end;
{-----------------------------------------------------------------------------}
function ShiftBAr(var BAr: TBArray; size: byte = 1): LongWord;
var r: LongWord; l, i: word;
begin
  Result := 0;
  l := length(BAr);
  if l=0 then exit;
  if (size > 4)  then size := 1  {1 <= size <= 4}
  else if size>l then size := l;
  r := 0;
  i := size;
  while i>0 do begin
    dec(i);
    r := (r shl 8) or BAr[l]; {BAr[l]: byte}
  end;
  dec(l, size);
  while i<l do begin
    BAr[i] := BAr[i+size];
    inc(i);
  end;
  SetLength(BAr, i);
  Result := r;
end;
{-----------------------------------------------------------------------------}
function Copy(var data: TBArray; Index: word = 0; Len: word = 0): TBArray;
var r: TBArray;
begin
   If (Len = 0)or(Len > length(data)) then Len := Length(data)-Index;
   if Index + Len > length(data) then Len:=0;
   SetLength(r, Len);
   while(Len>0)do begin
     dec(Len);
     r[Len]:=data[Index+Len];
   end;
   Result := r;
end;
{-----------------------------------------------------------------------------}
end.
