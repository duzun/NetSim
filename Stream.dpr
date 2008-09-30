program Stream;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Funcs in 'Funcs.pas',
  BufferCl in 'BufferCl.pas',
  IOStream in 'IOStream.pas',
  StrStackCl in 'StrStackCl.pas',
  PrHost in 'PrHost.pas',
  CmdByte in 'CmdByte.pas',
  VProtocol in 'VProtocol.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
