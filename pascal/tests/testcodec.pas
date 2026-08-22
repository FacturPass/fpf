unit testcodec;

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry, base64, zstream, fpf, fpfbytes;

type
  TCodecTest = class(TTestCase)
  private
    procedure AssertDecodeFails(const Payload: string; Expected: TFpfErrorKind; const Why: string);
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
    procedure DecodeRoundTripsBothTransports;
    procedure DecodeReadsTheJsMinimalVector;
    procedure DecodeRejectsAnUnknownPrefix;
    procedure DecodeRejectsCorruptedBase64;
    procedure DecodeRejectsATruncatedDeflatePayload;
    procedure DecodeRejectsInvalidJson;
    procedure DecodeRejectsAMissingRequiredKey;
    procedure DecodeKeepsALeadingZeroInAnIdentifier;
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

procedure TCodecTest.DecodeRoundTripsBothTransports;
var
  Doc: TFpfDocument;
begin
  Doc := FpfDecode(FpfEncode(MinimalDoc, False));
  AssertEquals('ACME SAS', Doc.Legal.Name);
  Doc := FpfDecode(FpfEncode(MinimalDoc, True));
  AssertEquals('542051180', Doc.Einvoice.Address);
end;

procedure TCodecTest.DecodeReadsTheJsMinimalVector;
var
  Doc: TFpfDocument;
begin
  Doc := FpfDecode('2.' + MINIMAL_DEFLATE_BODY);
  AssertEquals('1.1', Doc.Fpf);
  AssertEquals('buyer', Doc.Kind);
  AssertEquals('FR', Doc.Legal.Country);
  AssertEquals('0225', Doc.Einvoice.Eas);
end;

procedure TCodecTest.AssertDecodeFails(const Payload: string; Expected: TFpfErrorKind; const Why: string);
begin
  try
    FpfDecode(Payload);
    Fail(Why);
  except
    on E: EFpfError do
      AssertTrue(Why + ' (wrong error kind: ' + E.Message + ')', E.Kind = Expected);
  end;
end;

procedure TCodecTest.DecodeRejectsAnUnknownPrefix;
begin
  AssertDecodeFails('9.abcdef', fekUnknownPrefix, 'an unknown prefix must be refused, not guessed at');
end;

procedure TCodecTest.DecodeRejectsCorruptedBase64;
begin
  AssertDecodeFails('1.!!!!', fekBase64, 'corrupted base64 must be refused');
end;

procedure TCodecTest.DecodeRejectsATruncatedDeflatePayload;
begin
  AssertDecodeFails('2.YWJj', fekInflate, 'a truncated deflate payload must be refused');
end;

procedure TCodecTest.DecodeRejectsInvalidJson;
begin
  AssertDecodeFails('1.' + ToBase64Url('{not json'), fekJson, 'invalid JSON must be refused');
end;

procedure TCodecTest.DecodeRejectsAMissingRequiredKey;
begin
  AssertDecodeFails('1.' + ToBase64Url('{"fpf":"1.1","kind":"buyer"}'), fekJson,
    'a document without legal and einvoice must not decode into a half-filled record');
end;

procedure TCodecTest.DecodeKeepsALeadingZeroInAnIdentifier;
var
  Doc: TFpfDocument;
begin
  // The classic hand-rolled-decoder bug: an identifier read as a number loses
  // its leading zero and stops comparing equal to the string it came from.
  Doc := FpfDecode('1.' + ToBase64Url(
    '{"fpf":"1.1","kind":"buyer","legal":{"country":"FR","name":"ACME SAS",' +
    '"ids":[{"scheme":"0009","value":"07282932000074"}]},' +
    '"einvoice":{"eas":"0225","address":"542051180"}}'));
  AssertEquals(1, Length(Doc.Legal.Ids));
  AssertEquals('0009', Doc.Legal.Ids[0].Scheme);
  AssertEquals('07282932000074', Doc.Legal.Ids[0].Value);
  AssertTrue('ids present', Doc.Legal.IdsPresent);
end;

initialization
  RegisterTest(TCodecTest);

end.
