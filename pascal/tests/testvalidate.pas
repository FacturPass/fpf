unit testvalidate;

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry, fpf;

type
  TValidateTest = class(TTestCase)
  private
    function ValidDoc: TFpfDocument;
    procedure AssertHasError(const Errors: TFpfErrors; const Expected: string);
    procedure AssertNoErrors(const Errors: TFpfErrors);
  published
    procedure MinimalDocumentHasNoErrors;
    procedure WrongVersionIsRejected;
    procedure WithdrawnVersion10IsRejected;
    procedure WrongKindIsRejected;
    procedure BadCountryAndEmptyName;
    procedure WellFormedIdsPass;
    procedure PresentButEmptyIdsAreRejected;
    procedure IdSchemeMustBeFourDigits;
    procedure DuplicateIdSchemeIsRejected;
    procedure TheCoreKnowsNothingAboutSirenLengths;
    procedure EmptyIdValueIsRejected;
    procedure BadEasAndEmptyAddress;
  end;

implementation

function TValidateTest.ValidDoc: TFpfDocument;
begin
  Result := Default(TFpfDocument);
  Result.Fpf := '1.1';
  Result.Kind := 'buyer';
  Result.Legal.Country := 'FR';
  Result.Legal.Name := 'ACME SAS';
  Result.Einvoice.Eas := '0225';
  Result.Einvoice.Address := '542051180';
end;

procedure TValidateTest.AssertHasError(const Errors: TFpfErrors; const Expected: string);
var
  I: Integer;
begin
  for I := 0 to High(Errors) do
    if Errors[I] = Expected then
      Exit;
  Fail('expected error not produced: ' + Expected);
end;

procedure TValidateTest.AssertNoErrors(const Errors: TFpfErrors);
begin
  if Length(Errors) > 0 then
    Fail('unexpected error: ' + Errors[0]);
end;

procedure TValidateTest.MinimalDocumentHasNoErrors;
begin
  AssertNoErrors(FpfValidate(ValidDoc));
end;

procedure TValidateTest.WrongVersionIsRejected;
var
  Doc: TFpfDocument;
begin
  Doc := ValidDoc;
  Doc.Fpf := '2.0';
  AssertHasError(FpfValidate(Doc), 'fpf: must be "1.1"');
end;

procedure TValidateTest.WithdrawnVersion10IsRejected;
var
  Doc: TFpfDocument;
begin
  // 1.0 was published briefly and withdrawn before a single document was
  // handed out. It is refused, never read.
  Doc := ValidDoc;
  Doc.Fpf := '1.0';
  AssertHasError(FpfValidate(Doc), 'fpf: must be "1.1"');
end;

procedure TValidateTest.WrongKindIsRejected;
var
  Doc: TFpfDocument;
begin
  Doc := ValidDoc;
  Doc.Kind := 'seller';
  AssertHasError(FpfValidate(Doc), 'kind: must be "buyer"');
end;

procedure TValidateTest.BadCountryAndEmptyName;
var
  Doc: TFpfDocument;
  Errors: TFpfErrors;
begin
  Doc := ValidDoc;
  Doc.Legal.Country := 'France';
  Doc.Legal.Name := '  ';
  Errors := FpfValidate(Doc);
  AssertHasError(Errors, 'legal.country: ISO 3166-1 alpha-2 code required');
  AssertHasError(Errors, 'legal.name: non-empty string required');
end;

procedure TValidateTest.WellFormedIdsPass;
var
  Doc: TFpfDocument;
begin
  Doc := ValidDoc;
  SetLength(Doc.Legal.Ids, 2);
  Doc.Legal.Ids[0].Scheme := '0002';
  Doc.Legal.Ids[0].Value := '542051180';
  Doc.Legal.Ids[1].Scheme := '0009';
  Doc.Legal.Ids[1].Value := '73282932000074';
  AssertNoErrors(FpfValidate(Doc));
end;

procedure TValidateTest.PresentButEmptyIdsAreRejected;
var
  Doc: TFpfDocument;
begin
  Doc := ValidDoc;
  Doc.Legal.IdsPresent := True;
  AssertHasError(FpfValidate(Doc), 'legal.ids: non-empty array required when present');
end;

procedure TValidateTest.IdSchemeMustBeFourDigits;
var
  Doc: TFpfDocument;
begin
  Doc := ValidDoc;
  SetLength(Doc.Legal.Ids, 1);
  Doc.Legal.Ids[0].Scheme := '2';
  Doc.Legal.Ids[0].Value := '542051180';
  AssertHasError(FpfValidate(Doc), 'legal.ids[0].scheme: 4-digit ICD scheme code required');
end;

procedure TValidateTest.DuplicateIdSchemeIsRejected;
var
  Doc: TFpfDocument;
begin
  Doc := ValidDoc;
  SetLength(Doc.Legal.Ids, 2);
  Doc.Legal.Ids[0].Scheme := '0002';
  Doc.Legal.Ids[0].Value := '542051180';
  Doc.Legal.Ids[1].Scheme := '0002';
  Doc.Legal.Ids[1].Value := '999999999';
  AssertHasError(FpfValidate(Doc), 'legal.ids[1].scheme: duplicate scheme 0002');
end;

procedure TValidateTest.TheCoreKnowsNothingAboutSirenLengths;
var
  Doc: TFpfDocument;
begin
  // "12345" is not a SIREN, but that is PROFILE-FR's business, not the core's.
  Doc := ValidDoc;
  SetLength(Doc.Legal.Ids, 1);
  Doc.Legal.Ids[0].Scheme := '0002';
  Doc.Legal.Ids[0].Value := '12345';
  AssertNoErrors(FpfValidate(Doc));
end;

procedure TValidateTest.EmptyIdValueIsRejected;
var
  Doc: TFpfDocument;
begin
  Doc := ValidDoc;
  SetLength(Doc.Legal.Ids, 1);
  Doc.Legal.Ids[0].Scheme := '0002';
  Doc.Legal.Ids[0].Value := '   ';
  AssertHasError(FpfValidate(Doc), 'legal.ids[0].value: non-empty string required');
end;

procedure TValidateTest.BadEasAndEmptyAddress;
var
  Doc: TFpfDocument;
  Errors: TFpfErrors;
begin
  Doc := ValidDoc;
  Doc.Einvoice.Eas := '22';
  Doc.Einvoice.Address := '';
  Errors := FpfValidate(Doc);
  AssertHasError(Errors, 'einvoice.eas: 4-digit EAS scheme code required');
  AssertHasError(Errors, 'einvoice.address: non-empty string required');
end;

initialization
  RegisterTest(TValidateTest);

end.
