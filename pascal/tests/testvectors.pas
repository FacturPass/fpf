unit testvectors;

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry, fpjson, jsonparser, fpf, fpfjson, testsupport;

type
  TVectorTest = class(TTestCase)
  private
    function VectorFile: TJSONObject;
  published
    procedure VectorsDecodeToTheExpectedDocument;
    procedure EncodeRawMatchesTheVectorExactly;
    procedure EncodeDeflateRoundTrips;
    procedure DecodeFailuresAreRejected;
    procedure ValidateFailuresProduceErrors;
  end;

implementation

function TVectorTest.VectorFile: TJSONObject;
begin
  Result := TJSONObject(GetJSON(ReadFixture('test-vectors.json')));
end;

procedure TVectorTest.VectorsDecodeToTheExpectedDocument;
var
  Vectors: TJSONArray;
  Vector, VecFile: TJSONObject;
  Expected: TFpfDocument;
  I: Integer;
begin
  VecFile := VectorFile;
  try
    Vectors := VecFile.Arrays['vectors'];
    // A loop over an empty array would pass without testing anything.
    AssertTrue('test-vectors.json carries vectors', Vectors.Count > 0);
    for I := 0 to Vectors.Count - 1 do
    begin
      Vector := TJSONObject(Vectors.Items[I]);
      Expected := JsonToDoc(ReadFixture('examples/' + Vector.Get('example', '')));
      AssertDocumentsEqual(Self, Expected, FpfDecode(Vector.Get('payload_raw', '')),
        'raw payload for ' + Vector.Get('name', ''));
      AssertDocumentsEqual(Self, Expected, FpfDecode(Vector.Get('payload_deflate', '')),
        'deflate payload for ' + Vector.Get('name', ''));
    end;
  finally
    VecFile.Free;
  end;
end;

procedure TVectorTest.EncodeRawMatchesTheVectorExactly;
var
  Vectors: TJSONArray;
  Vector, VecFile: TJSONObject;
  Doc: TFpfDocument;
  I: Integer;
begin
  VecFile := VectorFile;
  try
    Vectors := VecFile.Arrays['vectors'];
    // A loop over an empty array would pass without testing anything.
    AssertTrue('test-vectors.json carries vectors', Vectors.Count > 0);
    for I := 0 to Vectors.Count - 1 do
    begin
      Vector := TJSONObject(Vectors.Items[I]);
      Doc := JsonToDoc(ReadFixture('examples/' + Vector.Get('example', '')));
      AssertEquals('raw encode for ' + Vector.Get('name', ''),
        Vector.Get('payload_raw', ''), FpfEncode(Doc, False));
    end;
  finally
    VecFile.Free;
  end;
end;

procedure TVectorTest.EncodeDeflateRoundTrips;
var
  Vectors: TJSONArray;
  Vector, VecFile: TJSONObject;
  Doc: TFpfDocument;
  I: Integer;
begin
  // The 2. transport is only ever checked by round-trip: two deflate
  // implementations have no reason to emit the same bytes.
  VecFile := VectorFile;
  try
    Vectors := VecFile.Arrays['vectors'];
    // A loop over an empty array would pass without testing anything.
    AssertTrue('test-vectors.json carries vectors', Vectors.Count > 0);
    for I := 0 to Vectors.Count - 1 do
    begin
      Vector := TJSONObject(Vectors.Items[I]);
      Doc := JsonToDoc(ReadFixture('examples/' + Vector.Get('example', '')));
      AssertDocumentsEqual(Self, Doc, FpfDecode(FpfEncode(Doc, True)),
        'deflate round-trip for ' + Vector.Get('name', ''));
    end;
  finally
    VecFile.Free;
  end;
end;

procedure TVectorTest.DecodeFailuresAreRejected;
var
  Failures: TJSONArray;
  Failure, VecFile: TJSONObject;
  I: Integer;
begin
  VecFile := VectorFile;
  try
    Failures := VecFile.Arrays['decode_failures'];
    AssertTrue('test-vectors.json carries decode failures', Failures.Count > 0);
    for I := 0 to Failures.Count - 1 do
    begin
      Failure := TJSONObject(Failures.Items[I]);
      try
        FpfDecode(Failure.Get('payload', ''));
        Fail('expected failure: ' + Failure.Get('name', ''));
      except
        on E: EFpfError do ; // expected
      end;
    end;
  finally
    VecFile.Free;
  end;
end;

procedure TVectorTest.ValidateFailuresProduceErrors;
var
  Failures: TJSONArray;
  Failure, VecFile: TJSONObject;
  Doc: TFpfDocument;
  I: Integer;
  Mapped: Boolean;
begin
  VecFile := VectorFile;
  try
    Failures := VecFile.Arrays['validate_failures'];
    AssertTrue('test-vectors.json carries validate failures', Failures.Count > 0);
    for I := 0 to Failures.Count - 1 do
    begin
      Failure := TJSONObject(Failures.Items[I]);
      // A document that will not even map into a TFpfDocument — a missing
      // required key — is a fortiori invalid: decoding enforces the same
      // shape the untyped JS reference checks inside validate(). Either
      // outcome satisfies this vector, exactly as in the Rust reference.
      Mapped := True;
      try
        Doc := JsonToDoc(ReadFixture('examples/' + Failure.Get('example', '')));
      except
        on E: EFpfError do
          Mapped := False;
      end;
      if Mapped then
        AssertTrue('expected validate errors: ' + Failure.Get('name', ''),
          Length(FpfValidate(Doc)) > 0);
    end;
  finally
    VecFile.Free;
  end;
end;

initialization
  RegisterTest(TVectorTest);

end.
