unit MiniStream;

interface
uses
  Funcs, Classes, SysUtils;
type
  TMiniStream = object
  private
    buf: ByteStr;
    function GetLen: integer;
    procedure SetLen(const Value: integer);
  public
        property Length: integer read GetLen write SetLen;
  end;

implementation
{-----------------------------------------------------------------------------}
{ TMiniStream }

function TMiniStream.GetLen: integer;
begin

end;
{-----------------------------------------------------------------------------}
procedure TMiniStream.SetLen(const Value: integer);
begin

end;
{-----------------------------------------------------------------------------}
end.
