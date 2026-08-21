unit fpfjson;

{$MODE OBJFPC}{$H+}

// TFpfDocument <-> JSON text. The only unit that knows about fpjson; a Delphi
// port rewrites it against System.JSON.

interface

uses
  fpf;

function DocToJson(const Doc: TFpfDocument): RawByteString;

implementation

uses
  SysUtils, fpjson;

// Adds Key only when Value is non-empty. An empty optional must be omitted
// from the document entirely — never emitted as "" or null.
procedure AddIfSet(Obj: TJSONObject; const Key, Value: string);
begin
  if Value <> '' then
    Obj.Add(Key, Value);
end;

function LegalToJson(const Legal: TFpfLegal): TJSONObject;
var
  Ids: TJSONArray;
  Id: TJSONObject;
  I: Integer;
begin
  Result := TJSONObject.Create;
  Result.Add('country', Legal.Country);
  Result.Add('name', Legal.Name);
  AddIfSet(Result, 'form', Legal.Form);
  if (Length(Legal.Ids) > 0) or Legal.IdsPresent then
  begin
    Ids := TJSONArray.Create;
    for I := 0 to High(Legal.Ids) do
    begin
      Id := TJSONObject.Create;
      Id.Add('scheme', Legal.Ids[I].Scheme);
      Id.Add('value', Legal.Ids[I].Value);
      Ids.Add(Id);
    end;
    Result.Add('ids', Ids);
  end;
  AddIfSet(Result, 'vat', Legal.Vat);
end;

function EinvoiceToJson(const Einvoice: TFpfEinvoice): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('eas', Einvoice.Eas);
  Result.Add('address', Einvoice.Address);
  AddIfSet(Result, 'platform', Einvoice.PlatformName);
end;

// Returns nil when every field is empty: an object with nothing in it must not
// reach the wire as "billing":{}.
function BillingToJson(const Billing: TFpfBilling): TJSONObject;
begin
  Result := nil;
  if (Billing.Street = '') and (Billing.Zip = '') and (Billing.City = '') and (Billing.Country = '') then
    Exit;
  Result := TJSONObject.Create;
  AddIfSet(Result, 'street', Billing.Street);
  AddIfSet(Result, 'zip', Billing.Zip);
  AddIfSet(Result, 'city', Billing.City);
  AddIfSet(Result, 'country', Billing.Country);
end;

function ContactToJson(const Contact: TFpfContact): TJSONObject;
begin
  Result := nil;
  if (Contact.Email = '') and (Contact.Phone = '') and (Contact.Ref = '') and (Contact.BuyerReference = '') then
    Exit;
  Result := TJSONObject.Create;
  AddIfSet(Result, 'email', Contact.Email);
  AddIfSet(Result, 'phone', Contact.Phone);
  // Declaration order matters: fpjson emits keys in insertion order, and the
  // two spellings are mutually exclusive, so the canonical order holds.
  AddIfSet(Result, 'ref', Contact.Ref);
  AddIfSet(Result, 'buyerReference', Contact.BuyerReference);
end;

function DocToJson(const Doc: TFpfDocument): RawByteString;
var
  Root, Child: TJSONObject;
  WasCompressed, WasStrict: Boolean;
begin
  Root := TJSONObject.Create;
  try
    Root.Add('fpf', Doc.Fpf);
    Root.Add('kind', Doc.Kind);
    Root.Add('legal', LegalToJson(Doc.Legal));
    Root.Add('einvoice', EinvoiceToJson(Doc.Einvoice));
    Child := BillingToJson(Doc.Billing);
    if Child <> nil then
      Root.Add('billing', Child);
    Child := ContactToJson(Doc.Contact);
    if Child <> nil then
      Root.Add('contact', Child);

    // Both of these are CLASS variables, global to the whole process. Setting
    // them once at unit initialization would change the JSON produced by the
    // host application — a cash register that uses fpjson for its own
    // exchanges would silently see its format move. Save and restore instead.
    //
    // CompressedJSON defaults to False, which pads the output with spaces and
    // would break the byte-exact "1." transport. StrictEscaping defaults to
    // False, which is already what JSON.stringify and serde_json do (no
    // escaped solidus), but a host is free to have turned it on.
    WasCompressed := TJSONData.CompressedJSON;
    WasStrict := TJSONString.StrictEscaping;
    try
      TJSONData.CompressedJSON := True;
      TJSONString.StrictEscaping := False;
      Result := Root.AsJSON;
    finally
      TJSONData.CompressedJSON := WasCompressed;
      TJSONString.StrictEscaping := WasStrict;
    end;
  finally
    Root.Free;
  end;
end;

end.
