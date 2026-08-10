using Xunit;

namespace Fpf.Tests;

public class FpfCodecTests
{
    private static FpfDocument SampleDoc() => new()
    {
        Fpf = "1.0",
        Kind = "buyer",
        Legal = new Legal { Country = "FR", Name = "ACME SAS" },
        Einvoice = new Einvoice { Eas = "0225", Address = "542051180" },
    };

    [Fact]
    public void RoundTripRaw()
    {
        var doc = SampleDoc();
        var payload = FpfCodec.Encode(doc, compress: false);
        Assert.StartsWith("1.", payload);
        Assert.Equal(doc, FpfCodec.Decode(payload));
    }

    [Fact]
    public void RoundTripDeflate()
    {
        var doc = SampleDoc();
        var payload = FpfCodec.Encode(doc, compress: true);
        Assert.StartsWith("2.", payload);
        Assert.Equal(doc, FpfCodec.Decode(payload));
    }

    [Fact]
    public void OptionalFieldsAreOmittedWhenNull()
    {
        var doc = SampleDoc();
        var payload = FpfCodec.Encode(doc, compress: false);
        var json = DecodeRawBody(payload);
        Assert.DoesNotContain("billing", json);
        Assert.DoesNotContain("contact", json);
        Assert.DoesNotContain("\"form\"", json);
    }

    [Fact]
    public void UnknownPrefixRejected()
    {
        var ex = Assert.Throws<FpfException>(() => FpfCodec.Decode("9.abcdef"));
        Assert.Contains("unknown payload prefix", ex.Message);
    }

    [Fact]
    public void CanonicalKeyOrderForRawPrefix()
    {
        var doc = SampleDoc();
        var payload = FpfCodec.Encode(doc, compress: false);
        var json = DecodeRawBody(payload);
        Assert.Equal(
            "{\"fpf\":\"1.0\",\"kind\":\"buyer\",\"legal\":{\"country\":\"FR\",\"name\":\"ACME SAS\"},\"einvoice\":{\"eas\":\"0225\",\"address\":\"542051180\"}}",
            json);
    }

    private static string DecodeRawBody(string payload)
    {
        var bytes = FpfCodec.FromBase64Url(payload.Substring("1.".Length));
        return System.Text.Encoding.UTF8.GetString(bytes);
    }
}
