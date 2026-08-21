unit testcodec;

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry;

type
  TCodecTest = class(TTestCase)
  published
    procedure HarnessRunsTests;
  end;

implementation

procedure TCodecTest.HarnessRunsTests;
begin
  AssertEquals('1.1', '1.1');
end;

initialization
  RegisterTest(TCodecTest);

end.
