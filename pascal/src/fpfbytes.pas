unit fpfbytes;

{$MODE OBJFPC}{$H+}

// The transport layer's two platform-specific chores: base64url and raw
// deflate. Together with fpfjson, this is what a Delphi port rewrites —
// fpf.pas itself stays untouched.
//
// Everything here is RawByteString, never string: these are bytes, and a
// plain string invites an implicit code page conversion that would corrupt a
// UTF-8 payload.

interface

function ToBase64Url(const Data: RawByteString): string;
function FromBase64Url(const S: string): RawByteString;
function RawDeflate(const Data: RawByteString): RawByteString;
function RawInflate(const Data: RawByteString): RawByteString;

implementation

uses
  SysUtils, Classes, base64, zstream;

function ToBase64Url(const Data: RawByteString): string;
begin
  Result := EncodeStringBase64(Data);
  Result := StringReplace(Result, '+', '-', [rfReplaceAll]);
  Result := StringReplace(Result, '/', '_', [rfReplaceAll]);
  while (Result <> '') and (Result[Length(Result)] = '=') do
    SetLength(Result, Length(Result) - 1);
end;

function FromBase64Url(const S: string): RawByteString;
var
  Padded: string;
begin
  Padded := StringReplace(S, '-', '+', [rfReplaceAll]);
  Padded := StringReplace(Padded, '_', '/', [rfReplaceAll]);
  while (Length(Padded) mod 4) <> 0 do
    Padded := Padded + '=';
  // Strict: a corrupted payload must raise rather than decode to garbage.
  Result := DecodeStringBase64(Padded, True);
end;

function RawDeflate(const Data: RawByteString): RawByteString;
var
  Dest: TStringStream;
  Z: TCompressionStream;
begin
  Dest := TStringStream.Create('');
  try
    // The third argument skips the zlib header: FPF carries deflate-raw,
    // the same thing the browsers' CompressionStream('deflate-raw') emits.
    Z := TCompressionStream.Create(clDefault, Dest, True);
    try
      if Length(Data) > 0 then
        Z.WriteBuffer(Data[1], Length(Data));
    finally
      Z.Free; // destroying the stream flushes the remaining deflate output
    end;
    Result := Dest.DataString;
  finally
    Dest.Free;
  end;
end;

function RawInflate(const Data: RawByteString): RawByteString;
var
  Src: TStringStream;
  Z: TDecompressionStream;
  Buf: array[0..4095] of Byte;
  Read: Integer;
begin
  Result := '';
  Src := TStringStream.Create(Data);
  try
    Z := TDecompressionStream.Create(Src, True);
    try
      repeat
        Read := Z.Read(Buf, SizeOf(Buf));
        if Read > 0 then
        begin
          SetLength(Result, Length(Result) + Read);
          Move(Buf, Result[Length(Result) - Read + 1], Read);
        end;
      until Read <= 0;
    finally
      Z.Free;
    end;
  finally
    Src.Free;
  end;
end;

end.
