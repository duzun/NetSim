program Stream;

uses
  Forms,
  MainForm in 'MainForm.pas' {Form1},
  Funcs in 'Funcs.pas',
  BufferCl in 'BufferCl.pas',
  IOStream in 'IOStream.pas',
  StrStackCl in 'StrStackCl.pas',
  GovProtocol in 'GovProtocol.pas',
  CmdByte in 'CmdByte.pas',
  ProtocolBase in 'ProtocolBase.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
