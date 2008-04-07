program Stream;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Funcs in 'Funcs.pas',
  BufferCl in 'BufferCl.pas',
  IOStreams in 'IOStreams.pas',
  StrStackCl in 'StrStackCl.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
