unit CmdByte;
interface

const
{-----------------------------------------------------------------------------}
{ - uNET: Protocol specific Command Bytes - }
 { General }
 ToAll         = $FF;
 cmd_OK        = $40;
 cmd_No        = $7F;

 { Net management }
 cmd_start     = $81;
 cmd_stop      = $82;

 cmd_isPresent = $3E;
 cmd_tellMe    = $30;
 cmd_giveAddr  = $31;
 cmd_readID    = $32;
 cmd_Data      = $3F;
 
 { Data Types }
 cmd_Byte      = $01;
 cmd_Word      = $02;
 cmd_Int       = $03;
 cmd_LongWord  = $04;
 cmd_Char      = $05;
 cmd_String    = $06;
 cmd_Time      = $07;
 cmd_Double    = $08;
 
 { Application level (imperative) }
 cmd_close         = $20;
 cmd_write         = $21;
 cmd_clear         = $22;
 cmd_set_form_size = $23;
 cmd_get_on_top    = $24;
  

{-----------------------------------------------------------------------------}
implementation

end.
