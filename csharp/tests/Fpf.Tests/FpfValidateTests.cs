using Xunit;

namespace Fpf.Tests;

public class FpfValidateTests
{
    private static FpfDocument ValidDoc() => new()
    {
        Fpf = "1.1",
        Kind = "buyer",
        Legal = new Legal { Country = "FR", Name = "ACME SAS" },
        Einvoice = new Einvoice { Eas = "0225", Address = "542051180" },
    };

    [Fact]
    public void MinimalValidDocHasNoErrors()
    {
        Assert.Empty(FpfCodec.Validate(ValidDoc()));
    }

    [Fact]
    public void WrongFpfVersion()
    {
        var doc = ValidDoc() with { Fpf = "2.0" };
        Assert.Contains(FpfCodec.Validate(doc), e => e.StartsWith("fpf:"));
    }

    [Fact]
    public void WrongKind()
    {
        var doc = ValidDoc() with { Kind = "seller" };
        Assert.Contains(FpfCodec.Validate(doc), e => e.StartsWith("kind:"));
    }

    [Fact]
    public void BadCountryAndEmptyName()
    {
        var doc = ValidDoc() with { Legal = new Legal { Country = "France", Name = "  " } };
        var errors = FpfCodec.Validate(doc);
        Assert.Contains(errors, e => e.StartsWith("legal.country:"));
        Assert.Contains(errors, e => e.StartsWith("legal.name:"));
    }

    private static FpfDocument WithIds(params LegalId[] ids)
    {
        var baseDoc = ValidDoc();
        return baseDoc with { Legal = baseDoc.Legal with { Ids = ids } };
    }

    [Fact]
    public void WellFormedLegalIdsPass()
    {
        var doc = WithIds(
            new LegalId { Scheme = "0002", Value = "542051180" },
            new LegalId { Scheme = "0009", Value = "73282932000074" });
        Assert.Empty(FpfCodec.Validate(doc));
    }

    [Fact]
    public void LegalIdSchemeMustBeFourDigits()
    {
        var doc = WithIds(new LegalId { Scheme = "2", Value = "542051180" });
        Assert.Contains(FpfCodec.Validate(doc), e => e.StartsWith("legal.ids[0].scheme:"));
    }

    [Fact]
    public void DuplicateLegalIdSchemeIsRejected()
    {
        var doc = WithIds(
            new LegalId { Scheme = "0002", Value = "542051180" },
            new LegalId { Scheme = "0002", Value = "999999999" });
        Assert.Contains(FpfCodec.Validate(doc), e => e.Contains("duplicate scheme 0002"));
    }

    [Fact]
    public void TheCoreKnowsNothingAboutSirenLengths()
    {
        // "12345" is not a SIREN, but that is PROFILE-FR's business, not the core's.
        Assert.Empty(FpfCodec.Validate(WithIds(new LegalId { Scheme = "0002", Value = "12345" })));
    }

    [Fact]
    public void BadEasAndEmptyAddress()
    {
        var doc = ValidDoc() with { Einvoice = new Einvoice { Eas = "22", Address = "" } };
        var errors = FpfCodec.Validate(doc);
        Assert.Contains(errors, e => e.StartsWith("einvoice.eas:"));
        Assert.Contains(errors, e => e.StartsWith("einvoice.address:"));
    }

    [Fact]
    public void NullLegalAndEinvoiceProduceErrorsInsteadOfThrowing()
    {
        var doc = ValidDoc() with { Legal = null!, Einvoice = null! };
        var errors = FpfCodec.Validate(doc);
        Assert.Contains(errors, e => e.StartsWith("legal:"));
        Assert.Contains(errors, e => e.StartsWith("einvoice:"));
    }

    [Fact]
    public void WithdrawnVersion1_0IsRejected()
    {
        var doc = ValidDoc() with { Fpf = "1.0" };
        Assert.Contains(FpfCodec.Validate(doc), e => e == "fpf: must be \"1.1\"");
    }

    [Fact]
    public void LegacyContactRefIsNamedAsARename()
    {
        var doc = ValidDoc() with { Contact = new Contact { Ref = "EMP-042" } };
        Assert.Contains(FpfCodec.Validate(doc), e => e == "contact.ref: renamed to contact.buyerReference in FPF 1.1");
    }
}
