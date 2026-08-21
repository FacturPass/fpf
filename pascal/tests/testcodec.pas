unit testcodec;

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry, base64, zstream, fpfbytes;

type
  TCodecTest = class(TTestCase)
  published
    procedure Base64UrlHasNoPaddingOrUnsafeCharacters;
    procedure Base64UrlRoundTripsBinary;
    procedure Base64UrlRejectsCorruptedInput;
    procedure DeflateRoundTripsUtf8;
    procedure InflateReadsAPayloadProducedByTheJsImplementation;
    procedure InflateRejectsATruncatedStream;
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

initialization
  RegisterTest(TCodecTest);

end.
