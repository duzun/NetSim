unit Funcs;

interface
uses
  Classes, SysUtils, BufferCL;

const
  WrongData = $8000;
  WrongLen  = $4000;
  b_TgtSrc  = $80;
  b_AddLen  = $40;
  
type
  BFile = File of Byte;

function chr2num(c: char):word;
function num2chr(nm: byte):char;
function str2byte(byte_str: string): Word;
function byte2str(bt: word; glow: string = ' '): String;

function Copy(var data:TBArray; Index: word = 0; Len: word = 0): TBArray;
function Str2BAr(s: string):TBArray;
function BAr2Str(s: TBArray):string;
function toISO(data: String; target: byte = 0; source: byte = 0): TBArray;
function fromISO(data: TBArray; var target, source: byte):String;

function ISOLen(data: PBArray; var p: byte): boolean;

function ISOSplit(frame: PBarray;var p, len, tgt, src: byte): word;            overload;
function ISOSplit(frame: PBarray;var p, len: byte): word;                      overload;
function ISOSplit(frame: PBarray;var data: TBarray; var p, len, tgt, src: byte): word;overload;
function ISOSplit(frame: PBarray;var data: TBarray; var tgt, src: byte): word; overload;
{-----------------------------------------------------------------------------}
implementation
{-----------------------------------------------------------------------------}
function Copy(var data:TBArray; Index: word = 0; Len: word = 0): TBArray;
var r: TBArray;
begin
   If (Len = 0)or(Len > length(data)) then Len := Length(data);
   if Index >= Len then Len:=0;
   SetLength(r, Len);
   while(Len>0)do begin
     dec(Len);
     r[Len]:=data[Index+Len];
   end;
   Result := r;
end;
{-----------------------------------------------------------------------------}
function ISOSplit(frame: PBarray;var p, len, tgt, src: byte): word;  overload;
var chc: byte;
    i: word;
begin
  Result := WrongLen;
  if(frame=nil)or(Length(frame^)<3)then exit;
  len := frame^[p] and $3F;
  inc(p);
  if frame^[0] and b_TgtSrc <> 0 then begin
    src := frame^[p];
    tgt := frame^[p+1];
    inc(p, 2);
  end else begin
    tgt:=0; src:=0;
  end;
  if len = 0 then begin
    if (Length(frame^)<p) then exit;
    len := frame^[p];
    inc(p);
  end;
  i := len + p;
  if (i + 1 > Length(frame^)) then begin
    Result := WrongLen or (i + 1 - Length(frame^));
    exit;
  end;
  chc := frame^[i];
  while(i>0)do begin
    dec(i);
    dec(chc, frame^[i]);
  end;
  if chc <> 0 then Result := WrongData
              else Result := 0;
end;
{-----------------------------------------------------------------------------}
function ISOSplit(frame: PBarray;var data: TBarray; var p, len, tgt, src: byte): word;            overload;
var i: word;
begin
  i := ISOSplit(frame, p, len, tgt, src);
  if i=0 then begin
    data := Copy(frame^, p, len);
    Result := 0;
  end else Result := i;
end;
{-----------------------------------------------------------------------------}
function ISOSplit(frame: PBarray;var data: TBarray; var tgt, src: byte): word; overload;
var p, len: byte;
begin p:=0; Result := ISOSplit(frame, data, p, len, tgt, src); end;
{-----------------------------------------------------------------------------}
function ISOSplit(frame: PBarray;var p, len: byte): word;  overload;
var i: byte;
begin  Result := ISOSplit(frame, p, len, i, i); end;
{-----------------------------------------------------------------------------}
function ISOLen(data: PBArray; var p: byte): boolean;
begin
  Result := false;
  if(data=nil)or(Length(data^)=0)then exit;
  p := data^[0] and $3F;
  if p=0 then begin
     if (data^[0] and b_TgtSrc) <> 0 then p:=3 else p:=1;
     if Length(data^) <= p then exit;
     p := data^[p];
  end;
  Result := true;
end;
{-----------------------------------------------------------------------------}
function Str2BAr(s: string):TBArray;
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
function BAr2Str(s: TBArray):string;
var w: LongWord;
    r: string;
begin
  w := length(s);
  setLength(r, w);
  while w<>0 do begin
    r[w] := chr(s[w-1]);
    dec(w);
  end;
  Result := r;
end;
{-----------------------------------------------------------------------------}
function toISO;
var r: TBArray;
    l, i0, i1: Integer;
    i, ld: word;
    b, chk: byte;
begin
   if(data='') then exit;
   l   := Length(data);

   SetLength(r, l + 2 + 3*(l div $ff + 1)); // rezervarea spatiului de memorie suficient

   i:=1;
   b:=0;
   chk:=0;
   i0 := 0;

   if(target or source<>0) then begin
      inc(b, b_TgtSrc);
      r[i]:=target; inc(i);
      r[i]:=source; inc(i);
      inc(chk, target + source);
   end;
 repeat
   ld:=$FF;
   if l > ld then inc(b, b_AddLen)
   else ld := l and ld;
   dec(l, ld);
   if(ld >= (1 shl 6)) then begin
     r[i]:=ld; inc(i);
     inc(chk, ld);
   end else begin
     inc(b, ld);
   end;
   r[i0]:=b;  // Baitul de setari
   inc(chk, b);
   inc(i0, i);
   i := ld;
   while(i<>0)do begin
      r[i0+i-1]:=ord(data[i]);
      inc(chk, r[i0+i-1]);
      dec(i);
   end;
   Delete(data, 1, ld);
   inc(i0, ld+1);
   r[i0-1]:=chk;

   chk:=0;
   b:=0;
   i:=1;
 until l=0;
 SetLength(r, i0);
 Result := r;
end;
{-----------------------------------------------------------------------------}
function fromISO;
var r: string;
begin

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
function str2byte(byte_str: string): Word;
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
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}


end.
