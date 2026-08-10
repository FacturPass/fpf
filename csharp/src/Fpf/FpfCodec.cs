using System.IO.Compression;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Fpf;

public sealed class FpfException : Exception
{
    public FpfException(string message, Exception? inner = null) : base(message, inner) { }
}

public static partial class FpfCodec
{
    private const string PrefixRaw = "1.";
    private const string PrefixDeflate = "2.";

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
    };

    internal static string ToBase64Url(byte[] bytes) =>
        Convert.ToBase64String(bytes).Replace('+', '-').Replace('/', '_').TrimEnd('=');

    internal static byte[] FromBase64Url(string s)
    {
        var padded = s.Replace('-', '+').Replace('_', '/');
        padded += new string('=', (4 - padded.Length % 4) % 4);
        return Convert.FromBase64String(padded);
    }

    /// <summary>
    /// Serializes and encodes a document into a transport payload. Infallible:
    /// serializing an already-built <see cref="FpfDocument"/> and compressing
    /// in memory cannot reasonably fail, mirroring the JS/Rust references
    /// which document no error path for encoding.
    /// </summary>
    public static string Encode(FpfDocument doc, bool compress = true)
    {
        var bytes = JsonSerializer.SerializeToUtf8Bytes(doc, JsonOptions);
        if (!compress)
        {
            return PrefixRaw + ToBase64Url(bytes);
        }

        using var output = new MemoryStream();
        using (var deflate = new DeflateStream(output, CompressionLevel.Optimal, leaveOpen: true))
        {
            deflate.Write(bytes, 0, bytes.Length);
        }
        return PrefixDeflate + ToBase64Url(output.ToArray());
    }

    /// <summary>Decodes a transport payload back into a document.</summary>
    public static FpfDocument Decode(string payload)
    {
        byte[] bytes;
        if (payload.StartsWith(PrefixDeflate, StringComparison.Ordinal))
        {
            try
            {
                var compressed = FromBase64Url(payload.Substring(PrefixDeflate.Length));
                using var input = new MemoryStream(compressed);
                using var deflate = new DeflateStream(input, CompressionMode.Decompress);
                using var output = new MemoryStream();
                deflate.CopyTo(output);
                bytes = output.ToArray();
            }
            catch (Exception ex)
            {
                throw new FpfException($"FPF: failed to decode payload: {ex.Message}", ex);
            }
        }
        else if (payload.StartsWith(PrefixRaw, StringComparison.Ordinal))
        {
            try
            {
                bytes = FromBase64Url(payload.Substring(PrefixRaw.Length));
            }
            catch (Exception ex)
            {
                throw new FpfException($"FPF: failed to decode payload: {ex.Message}", ex);
            }
        }
        else
        {
            throw new FpfException("FPF: unknown payload prefix");
        }

        FpfDocument? doc;
        try
        {
            doc = JsonSerializer.Deserialize<FpfDocument>(bytes, JsonOptions);
        }
        catch (Exception ex)
        {
            throw new FpfException($"FPF: invalid JSON: {ex.Message}", ex);
        }

        if (doc is null || doc.Fpf is null || doc.Kind is null || doc.Legal is null || doc.Einvoice is null)
        {
            throw new FpfException("FPF: missing required field");
        }

        return doc;
    }
}
