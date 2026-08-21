unit testsupport;

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, fpf;

function RepoRoot: string;
function ReadFixture(const RelativePath: string): RawByteString;
procedure AssertDocumentsEqual(Test: TTestCase; const Expected, Actual: TFpfDocument; const Context: string);

implementation

function RepoRoot: string;
var
  Dir, Parent: string;
begin
  Dir := GetCurrentDir;
  repeat
    if FileExists(IncludeTrailingPathDelimiter(Dir) + 'test-vectors.json') then
      Exit(IncludeTrailingPathDelimiter(Dir));
    Parent := ExtractFileDir(ExcludeTrailingPathDelimiter(Dir));
    if Parent = Dir then
      raise Exception.Create('test-vectors.json not found above ' + GetCurrentDir);
    Dir := Parent;
  until False;
end;

function ReadFixture(const RelativePath: string): RawByteString;
var
  Stream: TStringStream;
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(RepoRoot + RelativePath, fmOpenRead or fmShareDenyNone);
  try
    Stream := TStringStream.Create('');
    try
      Stream.CopyFrom(FileStream, 0);
      Result := Stream.DataString;
    finally
      Stream.Free;
    end;
  finally
    FileStream.Free;
  end;
end;

// Field by field rather than by comparing two encodings: when this fails it
// must name the field that differs.
procedure AssertDocumentsEqual(Test: TTestCase; const Expected, Actual: TFpfDocument; const Context: string);
var
  I: Integer;
begin
  Test.AssertEquals(Context + ' fpf', Expected.Fpf, Actual.Fpf);
  Test.AssertEquals(Context + ' kind', Expected.Kind, Actual.Kind);
  Test.AssertEquals(Context + ' legal.country', Expected.Legal.Country, Actual.Legal.Country);
  Test.AssertEquals(Context + ' legal.name', Expected.Legal.Name, Actual.Legal.Name);
  Test.AssertEquals(Context + ' legal.form', Expected.Legal.Form, Actual.Legal.Form);
  Test.AssertEquals(Context + ' legal.vat', Expected.Legal.Vat, Actual.Legal.Vat);
  Test.AssertEquals(Context + ' legal.ids count', Length(Expected.Legal.Ids), Length(Actual.Legal.Ids));
  for I := 0 to High(Expected.Legal.Ids) do
  begin
    Test.AssertEquals(Format('%s legal.ids[%d].scheme', [Context, I]), Expected.Legal.Ids[I].Scheme, Actual.Legal.Ids[I].Scheme);
    Test.AssertEquals(Format('%s legal.ids[%d].value', [Context, I]), Expected.Legal.Ids[I].Value, Actual.Legal.Ids[I].Value);
  end;
  Test.AssertEquals(Context + ' einvoice.eas', Expected.Einvoice.Eas, Actual.Einvoice.Eas);
  Test.AssertEquals(Context + ' einvoice.address', Expected.Einvoice.Address, Actual.Einvoice.Address);
  Test.AssertEquals(Context + ' einvoice.platform', Expected.Einvoice.PlatformName, Actual.Einvoice.PlatformName);
  Test.AssertEquals(Context + ' billing.street', Expected.Billing.Street, Actual.Billing.Street);
  Test.AssertEquals(Context + ' billing.zip', Expected.Billing.Zip, Actual.Billing.Zip);
  Test.AssertEquals(Context + ' billing.city', Expected.Billing.City, Actual.Billing.City);
  Test.AssertEquals(Context + ' billing.country', Expected.Billing.Country, Actual.Billing.Country);
  Test.AssertEquals(Context + ' contact.email', Expected.Contact.Email, Actual.Contact.Email);
  Test.AssertEquals(Context + ' contact.phone', Expected.Contact.Phone, Actual.Contact.Phone);
  Test.AssertEquals(Context + ' contact.ref', Expected.Contact.Ref, Actual.Contact.Ref);
  Test.AssertEquals(Context + ' contact.buyerReference', Expected.Contact.BuyerReference, Actual.Contact.BuyerReference);
end;

end.
