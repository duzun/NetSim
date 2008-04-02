unit Funcs;

interface
uses
  Classes, SysUtils;

const
  WrongData = $8000;
  b_TgtSrc  = $80;
  
type
  MyStr = TFileStream;
  PMyStr = ^MyStr;
  ByteStr = packed array of byte;

function OpenStr(var PStr: PMyStr; FN: String; Create: Boolean):boolean;

function chr2num(c: char):word;
function num2chr(nm: byte):char;
function str2byte(byte_str: string): Word;
function byte2str(bt: word; glow: string = ' '): String;

function toISO(data: String; target: byte = 0; source: byte = 0): ByteStr;
{-----------------------------------------------------------------------------}
implementation
{-----------------------------------------------------------------------------}
function toISO(data: String; target: byte = 0; source: byte = 0): ByteStr;
var r: ByteStr;
    len, i, ld: word;
    b, chk: byte;
begin
   if(data='') then exit;
   ld  := Length(data);
   len := 2 + ld; // len and chk bytes
   SetLength(r, len + 5); // + tgt, src, len1 and len2 bytes
   i:=1; b:=0; chk:=0;
   if(target or source<>0) then begin
      inc(b, b_TgtSrc);
      r[i]:=target; inc(i);
      r[i]:=source; inc(i);
      inc(len,2);
   end;
   if(ld >= (1 shl 6)) then begin
     r[i]:=0; inc(i);
     if(ld >= (1 shl 8)) then begin
        r[i]:=0; inc(i);
        r[i]:=ld and $FF; inc(i);
        r[i]:=(ld shr 8) and $FF; inc(i);
     end else begin
        r[i]:=ld; inc(i);
        dec(len, 2);
     end;
   end else begin
     inc(b, ld);
     dec(len, 3);
   end;
   r[0]:=b;
   while(ld<>0)do begin
      r[i+ld-1]:=ord(data[ld]);
      dec(ld);
   end;
   for i:=0 to len-2 do inc(chk, r[i]);
   r[len-1]:=chk;
end;
{-----------------------------------------------------------------------------}
function OpenStr;
var Mode: word;
begin
  Result := false;
  if(FileExists(FN))then Mode:= fmOpenReadWrite
     else if(Create)then Mode:= fmCreate
     else exit;
  if(PStr = Nil) then new(PStr);
  PStr^     := MyStr.Create(FN, Mode);
  Result := true;
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
function byte2str(bt: word; glow: string = ' '): String;
begin
    Result := num2chr(Byte(bt) shr 4) + num2chr(Byte(bt)) + glow;
end;

{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
end.
