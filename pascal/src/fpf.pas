unit fpf;

{$MODE OBJFPC}{$H+}

// FPF 1.1 reference implementation — encode/decode of the transport payload.
// Mirrors the Rust reference implementation at ../rust/src/lib.rs.
//
// This unit is portable Object Pascal: everything specific to Free Pascal is
// in fpfjson and fpfbytes, which a Delphi port replaces.

interface

uses
  SysUtils;

type
  // A registration identifier (EN 16931 BT-47) qualified by its ICD scheme
  // code (BT-47-1), drawn from the same registry as einvoice.eas. What a
  // scheme means — 0002 is a French SIREN, 0009 a SIRET — belongs to the
  // country profiles, not here.
  TFpfLegalId = record
    Scheme: string;
    Value: string;
  end;

  TFpfLegalIds = array of TFpfLegalId;

  TFpfLegal = record
    Country: string;
    Name: string;
    Form: string;
    Ids: TFpfLegalIds;
    Vat: string;
    // A dynamic array of length zero IS nil in Pascal, so "present but empty"
    // and "absent" would otherwise be the same thing and the error
    // "legal.ids: non-empty array required when present" could never fire.
    // This flag restores what Option<Vec<LegalId>> carries in Rust. It is only
    // consulted when Ids is empty: a non-empty Ids is present regardless, so
    // an emitter who fills Ids without knowing about the flag never loses it.
    IdsPresent: Boolean;
  end;

  TFpfEinvoice = record
    Eas: string;
    Address: string;
    // Named PlatformName, not Platform: `platform` is a hint directive in
    // Object Pascal. The JSON key is still "platform".
    PlatformName: string;
  end;

  TFpfBilling = record
    Street: string;
    Zip: string;
    City: string;
    Country: string;
  end;

  TFpfContact = record
    Email: string;
    Phone: string;
    // "buyerReference" (EN 16931 BT-10) is the only spelling. Ref exists so the
    // validator can name the rename for anyone who read stale documentation —
    // the withdrawn 1.0 used it.
    Ref: string;
    BuyerReference: string;
  end;

  TFpfDocument = record
    Fpf: string;
    Kind: string;
    Legal: TFpfLegal;
    Einvoice: TFpfEinvoice;
    Billing: TFpfBilling;
    Contact: TFpfContact;
  end;

  TFpfErrors = array of string;

  // The four ways a payload can fail to decode, mirroring Rust's FpfError.
  TFpfErrorKind = (fekUnknownPrefix, fekBase64, fekInflate, fekJson);

  EFpfError = class(Exception)
  public
    Kind: TFpfErrorKind;
    constructor Create(AKind: TFpfErrorKind; const AMessage: string);
  end;

// Serializes and encodes a document into a transport payload. Infallible:
// serializing an already-built record and compressing in memory cannot
// reasonably fail, mirroring the JS and Rust references, which document no
// error path for encoding.
function FpfEncode(const Doc: TFpfDocument; Compress: Boolean = True): string;

// Decodes a transport payload back into a document. Raises EFpfError, whose
// Kind says which of the four ways it failed.
function FpfDecode(const Payload: string): TFpfDocument;

implementation

uses
  fpfjson, fpfbytes;

const
  PREFIX_RAW = '1.';
  PREFIX_DEFLATE = '2.';

constructor EFpfError.Create(AKind: TFpfErrorKind; const AMessage: string);
begin
  inherited Create(AMessage);
  Kind := AKind;
end;

function FpfEncode(const Doc: TFpfDocument; Compress: Boolean): string;
var
  Json: RawByteString;
begin
  Json := DocToJson(Doc);
  if Compress then
    Result := PREFIX_DEFLATE + ToBase64Url(RawDeflate(Json))
  else
    Result := PREFIX_RAW + ToBase64Url(Json);
end;

function FpfDecode(const Payload: string): TFpfDocument;
var
  Body: string;
  Bytes: RawByteString;
begin
  if Copy(Payload, 1, Length(PREFIX_DEFLATE)) = PREFIX_DEFLATE then
  begin
    Body := Copy(Payload, Length(PREFIX_DEFLATE) + 1, MaxInt);
    try
      Bytes := FromBase64Url(Body);
    except
      on E: Exception do
        raise EFpfError.Create(fekBase64, 'FPF: base64 decode error: ' + E.Message);
    end;
    try
      Bytes := RawInflate(Bytes);
    except
      on E: Exception do
        raise EFpfError.Create(fekInflate, 'FPF: inflate error: ' + E.Message);
    end;
  end
  else if Copy(Payload, 1, Length(PREFIX_RAW)) = PREFIX_RAW then
  begin
    Body := Copy(Payload, Length(PREFIX_RAW) + 1, MaxInt);
    try
      Bytes := FromBase64Url(Body);
    except
      on E: Exception do
        raise EFpfError.Create(fekBase64, 'FPF: base64 decode error: ' + E.Message);
    end;
  end
  else
    raise EFpfError.Create(fekUnknownPrefix, 'FPF: unknown payload prefix');

  Result := JsonToDoc(Bytes);
end;

end.
