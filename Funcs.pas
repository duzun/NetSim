unit Funcs;

interface
uses
  Classes, SysUtils, BufferCL;

const
  WrongData = $8000;
  b_TgtSrc  = $80;
  b_AddLen  = $40;
  
type
  BFile = File of Byte;
  ByteStr = TBArray;


function GetByte(var f: BFile): byte;
function SetByte(var f: BFile; b: byte): boolean;

function chr2num(c: char):word;
function num2chr(nm: byte):char;
function str2byte(byte_str: string): Word;
function byte2str(bt: word; glow: string = ' '): String;

function toISO(data: String; target: byte = 0; source: byte = 0): ByteStr;
function fromISO(data: ByteStr; var target, source: byte):String;
{-----------------------------------------------------------------------------}
implementation

{-----------------------------------------------------------------------------}
function GetByte(var f: BFile): byte;
var b: byte;
begin
    reset(f);
    read(f, b);
    close(f);
    Result := b;
end;
{-----------------------------------------------------------------------------}
function SetByte(var f: BFile; b: byte): boolean;
begin
    rewrite(f);
    Result:=false;
    try
    write(f, b);
    Result:=true;
    finally
    close(f);
    end;
end;
{-----------------------------------------------------------------------------}
function toISO;
var r: ByteStr;
    l, i0, i1: Integer;
    len, i, ld: word;
    b, chk: byte;
begin
   if(data='') then exit;
   l   := Length(data);

   len := 2 + ld;    // + len and chk bytes
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
function byte2str(bt: word; glow: string = ' '): String;
begin
    Result := num2chr(Byte(bt) shr 4) + num2chr(Byte(bt)) + glow;
end;

{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}


end.
