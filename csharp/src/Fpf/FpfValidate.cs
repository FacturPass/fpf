namespace Fpf;

public static partial class FpfCodec
{
    private static bool IsAsciiDigits(string? s, int len) =>
        s is not null && s.Length == len && s.All(c => c is >= '0' and <= '9');

    private static bool IsCountryCode(string? s) =>
        s is not null && s.Length == 2 && s.All(c => c is >= 'A' and <= 'Z');

    /// <summary>
    /// Structural + semantic validation mirroring the JS/Rust references'
    /// <c>validate()</c>. Must tolerate a hand-constructed
    /// <see cref="FpfDocument"/> whose <c>Legal</c>/<c>Einvoice</c> are null
    /// despite being declared non-nullable — C#, unlike Rust, does not
    /// enforce non-nullability at runtime.
    /// </summary>
    public static IReadOnlyList<string> Validate(FpfDocument doc)
    {
        var errors = new List<string>();

        if (doc.Fpf != "1.0") errors.Add("fpf: must be \"1.0\"");
        if (doc.Kind != "buyer") errors.Add("kind: must be \"buyer\"");

        if (doc.Legal is null)
        {
            errors.Add("legal: required object");
        }
        else
        {
            if (!IsCountryCode(doc.Legal.Country)) errors.Add("legal.country: ISO 3166-1 alpha-2 code required");
            if (string.IsNullOrWhiteSpace(doc.Legal.Name)) errors.Add("legal.name: non-empty string required");
            if (doc.Legal.Siren is { } siren && !IsAsciiDigits(siren, 9)) errors.Add("legal.siren: must be 9 digits");
            if (doc.Legal.Siret is { } siret && !IsAsciiDigits(siret, 14)) errors.Add("legal.siret: must be 14 digits");
        }

        if (doc.Einvoice is null)
        {
            errors.Add("einvoice: required object");
        }
        else
        {
            if (!IsAsciiDigits(doc.Einvoice.Eas, 4)) errors.Add("einvoice.eas: 4-digit EAS scheme code required");
            if (string.IsNullOrWhiteSpace(doc.Einvoice.Address)) errors.Add("einvoice.address: non-empty string required");
        }

        return errors;
    }
}
