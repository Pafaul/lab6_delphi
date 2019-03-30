program Simulation5;

uses
  Vcl.Forms,
  Simulation in 'Simulation.pas' {Form2},
  UTargets in 'UTargets.pas',
  UIntegrator in 'UIntegrator.pas',
  Threads in 'Threads.pas',
  USQL in 'USQL.pas',
  TNC in 'TNC.pas',
  USimulator in 'USimulator.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
