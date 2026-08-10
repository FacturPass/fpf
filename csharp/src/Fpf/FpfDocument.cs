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
    [JsonPropertyName("siren")] public string? Siren { get; init; }
    [JsonPropertyName("siret")] public string? Siret { get; init; }
    [JsonPropertyName("vat")] public string? Vat { get; init; }
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
    [JsonPropertyName("ref")] public string? Ref { get; init; }
}
