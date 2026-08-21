unit testcodec;

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry, base64, zstream, fpf, fpfbytes;

type
  TCodecTest = class(TTestCase)
  published
    procedure Base64UrlHasNoPaddingOrUnsafeCharacters;
    procedure Base64UrlRoundTripsBinary;
    procedure Base64UrlRejectsCorruptedInput;
    procedure DeflateRoundTripsUtf8;
    procedure InflateReadsAPayloadProducedByTheJsImplementation;
    procedure InflateRejectsATruncatedStream;
    procedure EncodeProducesTheCanonicalKeyOrder;
    procedure EncodeOmitsEmptyOptionalKeys;
    procedure EncodeMatchesTheMinimalVectorByteForByte;
    procedure EncodeCompressedUsesThe2Prefix;
  end;

const
  // The "minimal" vector's payload_deflate, produced by the JS reference.
  // Inflating it here is the cheapest possible proof that FPC's raw deflate
  // agrees with the browsers' CompressionStream('deflate-raw').
  MINIMAL_DEFLATE_BODY =
    'FcoxCsIwGIDRq8g3B0mCAclWRDcXe4LY_JVgTUtqhVJyd-n6eBv91OMxR4PinXLE81xWKSgGe' +
    'YUBv9GNS_6WFc_tgSKHj-BpLvfroW1aqkJS_o2pk31LmPFoax2KEGOReQd3stoZc9bU-gc';
  MINIMAL_JSON =
    '{"fpf":"1.1","kind":"buyer","legal":{"country":"FR","name":"ACME SAS"},' +
    '"einvoice":{"eas":"0225","address":"542051180"}}';

implementation

function MinimalDoc: TFpfDocument;
begin
  Result := Default(TFpfDocument);
  Result.Fpf := '1.1';
  Result.Kind := 'buyer';
  Result.Legal.Country := 'FR';
  Result.Legal.Name := 'ACME SAS';
  Result.Einvoice.Eas := '0225';
  Result.Einvoice.Address := '542051180';
end;

procedure TCodecTest.Base64UrlHasNoPaddingOrUnsafeCharacters;
var
  Encoded: string;
begin
  // "hello?>~" is chosen because its standard base64 contains both + and /.
  Encoded := ToBase64Url('hello?>~');
  AssertEquals('aGVsbG8_Pn4', Encoded);
end;

procedure TCodecTest.Base64UrlRoundTripsBinary;
var
  Data: RawByteString;
begin
  Data := #$00#$FF#$C3#$A9'{}';
  AssertEquals(Data, FromBase64Url(ToBase64Url(Data)));
end;

procedure TCodecTest.Base64UrlRejectsCorruptedInput;
begin
  try
    FromBase64Url('!!!!');
    Fail('a corrupted payload must raise, not decode to garbage');
  except
    on E: EBase64DecodingException do ; // expected
  end;
end;

procedure TCodecTest.DeflateRoundTripsUtf8;
var
  Source: RawByteString;
begin
  Source := '{"city":"Orl' + #$C3 + #$A9 + 'ans"}';
  AssertEquals(Source, RawInflate(RawDeflate(Source)));
end;

procedure TCodecTest.InflateReadsAPayloadProducedByTheJsImplementation;
begin
  AssertEquals(MINIMAL_JSON, RawInflate(FromBase64Url(MINIMAL_DEFLATE_BODY)));
end;

procedure TCodecTest.InflateRejectsATruncatedStream;
begin
  try
    RawInflate('abc');
    Fail('a truncated deflate stream must raise');
  except
    on E: Edecompressionerror do ; // expected
  end;
end;

procedure TCodecTest.EncodeProducesTheCanonicalKeyOrder;
begin
  AssertEquals(MINIMAL_JSON, RawInflate(FromBase64Url(Copy(FpfEncode(MinimalDoc, True), 3, MaxInt))));
end;

procedure TCodecTest.EncodeOmitsEmptyOptionalKeys;
var
  Json: RawByteString;
begin
  Json := FromBase64Url(Copy(FpfEncode(MinimalDoc, False), 3, MaxInt));
  AssertEquals('no billing key', 0, Pos('billing', Json));
  AssertEquals('no contact key', 0, Pos('contact', Json));
  AssertEquals('no form key', 0, Pos('"form"', Json));
  AssertEquals('no ids key', 0, Pos('"ids"', Json));
end;

procedure TCodecTest.EncodeMatchesTheMinimalVectorByteForByte;
begin
  // payload_raw of the "minimal" vector, produced by the JS reference.
  AssertEquals(
    '1.eyJmcGYiOiIxLjEiLCJraW5kIjoiYnV5ZXIiLCJsZWdhbCI6eyJjb3VudHJ5IjoiRlIiLCJuYW1l' +
    'IjoiQUNNRSBTQVMifSwiZWludm9pY2UiOnsiZWFzIjoiMDIyNSIsImFkZHJlc3MiOiI1NDIwNTExOD' +
    'AifX0',
    FpfEncode(MinimalDoc, False));
end;

procedure TCodecTest.EncodeCompressedUsesThe2Prefix;
begin
  AssertEquals('2.', Copy(FpfEncode(MinimalDoc, True), 1, 2));
end;

initialization
  RegisterTest(TCodecTest);

end.
