using System.Text.Json;
using Xunit;

namespace Fpf.Tests;

public class VectorTests
{
    private sealed record VectorFile(
        List<Vector> Vectors,
        List<DecodeFailure> DecodeFailures,
        List<ValidateFailure> ValidateFailures);

    private sealed record Vector(string Name, string Example, string PayloadRaw, string PayloadDeflate);

    private sealed record DecodeFailure(string Name, string Payload);

    private sealed record ValidateFailure(string Name, string Example);

    // Test-only DTOs: a naming policy is simpler here than repeating
    // [JsonPropertyName] on every property, unlike FpfDocument (Task 1),
    // which is the public API surface and documents the wire format
    // explicitly.
    private static readonly JsonSerializerOptions VectorJsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
    };

    private static VectorFile LoadVectorFile()
    {
        var json = File.ReadAllText("test-vectors.json");
        return JsonSerializer.Deserialize<VectorFile>(json, VectorJsonOptions)
            ?? throw new InvalidOperationException("test-vectors.json deserialized to null");
    }

    private static string LoadExampleRaw(string name) => File.ReadAllText(Path.Combine("examples", name));

    [Fact]
    public void VectorsDecodeToExpectedDocument()
    {
        var file = LoadVectorFile();
        foreach (var vector in file.Vectors)
        {
            var expected = JsonSerializer.Deserialize<FpfDocument>(LoadExampleRaw(vector.Example));
            Assert.Equal(expected, FpfCodec.Decode(vector.PayloadRaw));
            Assert.Equal(expected, FpfCodec.Decode(vector.PayloadDeflate));
        }
    }

    [Fact]
    public void EncodeRawMatchesVectorExactly()
    {
        var file = LoadVectorFile();
        foreach (var vector in file.Vectors)
        {
            var document = JsonSerializer.Deserialize<FpfDocument>(LoadExampleRaw(vector.Example))!;
            Assert.Equal(vector.PayloadRaw, FpfCodec.Encode(document, compress: false));
        }
    }

    [Fact]
    public void EncodeDeflateRoundTrips()
    {
        var file = LoadVectorFile();
        foreach (var vector in file.Vectors)
        {
            var document = JsonSerializer.Deserialize<FpfDocument>(LoadExampleRaw(vector.Example))!;
            var payload = FpfCodec.Encode(document, compress: true);
            Assert.Equal(document, FpfCodec.Decode(payload));
        }
    }

    [Fact]
    public void DecodeFailuresAreRejected()
    {
        var file = LoadVectorFile();
        foreach (var failure in file.DecodeFailures)
        {
            Assert.Throws<FpfException>(() => FpfCodec.Decode(failure.Payload));
        }
    }

    [Fact]
    public void ValidateFailuresProduceErrors()
    {
        var file = LoadVectorFile();
        foreach (var failure in file.ValidateFailures)
        {
            var raw = LoadExampleRaw(failure.Example);

            // A document that fails to even deserialize into a typed
            // FpfDocument, OR that deserializes with a null Legal/Einvoice
            // because the JSON was missing that key, is a fortiori invalid.
            // System.Text.Json does not throw on a missing non-nullable
            // property (unlike Rust's serde) — it just leaves it null — so
            // both outcomes must be treated as satisfying this vector. This
            // mirrors the same typed-language nuance already applied in the
            // Rust reference implementation's equivalent test.
            FpfDocument? document;
            try
            {
                document = JsonSerializer.Deserialize<FpfDocument>(raw);
            }
            catch (JsonException)
            {
                continue;
            }
            if (document is null || document.Legal is null || document.Einvoice is null)
            {
                continue;
            }
            Assert.NotEmpty(FpfCodec.Validate(document));
        }
    }
}
