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

    [Fact]
    public void BadOptionalSirenSiretFormats()
    {
        var baseDoc = ValidDoc();
        var doc = baseDoc with { Legal = baseDoc.Legal with { Siren = "12345", Siret = "ABC" } };
        var errors = FpfCodec.Validate(doc);
        Assert.Contains(errors, e => e.StartsWith("legal.siren:"));
        Assert.Contains(errors, e => e.StartsWith("legal.siret:"));
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
