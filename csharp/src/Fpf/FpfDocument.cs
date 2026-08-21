using System.Text.Json.Serialization;

namespace Fpf;

public sealed record FpfDocument
{
    [JsonPropertyName("fpf")] public string Fpf { get; init; } = null!;
    [JsonPropertyName("kind")] public string Kind { get; init; } = null!;
    [JsonPropertyName("legal")] public Legal Legal { get; init; } = null!;
    [JsonPropertyName("einvoice")] public Einvoice Einvoice { get; init; } = null!;
    [JsonPropertyName("billing")] public Billing? Billing { get; init; }
    [JsonPropertyName("contact")] public Contact? Contact { get; init; }
}

public sealed record Legal
{
    [JsonPropertyName("country")] public string Country { get; init; } = null!;
    [JsonPropertyName("name")] public string Name { get; init; } = null!;
    [JsonPropertyName("form")] public string? Form { get; init; }
    [JsonPropertyName("ids")] public IReadOnlyList<LegalId>? Ids { get; init; }
    [JsonPropertyName("vat")] public string? Vat { get; init; }

    // A record compares its members with EqualityComparer<T>.Default, which for a
    // list means reference equality: two documents decoded from the same payload
    // would compare unequal. The identifier list has to compare by content.
    public bool Equals(Legal? other) =>
        other is not null
        && Country == other.Country
        && Name == other.Name
        && Form == other.Form
        && Vat == other.Vat
        && (Ids is null ? other.Ids is null : other.Ids is not null && Ids.SequenceEqual(other.Ids));

    public override int GetHashCode()
    {
        unchecked
        {
            var hash = 17;
            hash = hash * 31 + (Country?.GetHashCode() ?? 0);
            hash = hash * 31 + (Name?.GetHashCode() ?? 0);
            hash = hash * 31 + (Form?.GetHashCode() ?? 0);
            hash = hash * 31 + (Vat?.GetHashCode() ?? 0);
            if (Ids is not null)
            {
                foreach (var id in Ids) hash = hash * 31 + id.GetHashCode();
            }
            return hash;
        }
    }
}

// A registration identifier (EN 16931 BT-47) qualified by its ICD scheme code
// (BT-47-1), drawn from the same registry as einvoice.eas. What a scheme means —
// 0002 is a French SIREN, 0009 a SIRET — belongs to the country profiles.
public sealed record LegalId
{
    [JsonPropertyName("scheme")] public string Scheme { get; init; } = null!;
    [JsonPropertyName("value")] public string Value { get; init; } = null!;
}

public sealed record Einvoice
{
    [JsonPropertyName("eas")] public string Eas { get; init; } = null!;
    [JsonPropertyName("address")] public string Address { get; init; } = null!;
    [JsonPropertyName("platform")] public string? Platform { get; init; }
}

public sealed record Billing
{
    [JsonPropertyName("street")] public string? Street { get; init; }
    [JsonPropertyName("zip")] public string? Zip { get; init; }
    [JsonPropertyName("city")] public string? City { get; init; }
    [JsonPropertyName("country")] public string? Country { get; init; }
}

public sealed record Contact
{
    [JsonPropertyName("email")] public string? Email { get; init; }
    [JsonPropertyName("phone")] public string? Phone { get; init; }
    // "buyerReference" (EN 16931 BT-10) is the only spelling. "ref" is kept so the
    // validator can name the rename for anyone who read stale documentation — the
    // withdrawn 1.0 used it. Declaration order matters: System.Text.Json emits
    // properties in this order, and the two are mutually exclusive, so the
    // canonical key order holds.
    [JsonPropertyName("ref")] public string? Ref { get; init; }
    [JsonPropertyName("buyerReference")] public string? BuyerReference { get; init; }
}
