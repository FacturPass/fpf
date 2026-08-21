program fpftests;

{$MODE OBJFPC}{$H+}

uses
  consoletestrunner,
  testcodec;

var
  App: TTestRunner;

begin
  App := TTestRunner.Create(nil);
  try
    App.Title := 'FPF Pascal reference implementation';
    App.Initialize;
    App.Run;
  finally
    App.Free;
  end;
end.
