package com.facturpass.fpf;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import org.junit.jupiter.api.Test;

class FpfValidateTest {

    private static FpfDocument validDoc() {
        return new FpfDocument(
                "1.1", "buyer",
                new Legal("FR", "ACME SAS", null, null, null),
                new Einvoice("0225", "542051180", null),
                null, null);
    }

    private static void assertHasError(List<String> errors, String expected) {
        assertTrue(errors.contains(expected), "expected error not produced: " + expected + ", got " + errors);
    }

    @Test
    void minimalDocumentHasNoErrors() {
        assertEquals(List.of(), Fpf.validate(validDoc()));
    }

    @Test
    void wrongVersionIsRejected() {
        FpfDocument doc = new FpfDocument("2.0", "buyer", validDoc().legal(), validDoc().einvoice(), null, null);
        assertHasError(Fpf.validate(doc), "fpf: must be \"1.1\"");
    }

    @Test
    void withdrawnVersion10IsRejected() {
        // 1.0 was published briefly and withdrawn before a single document was
        // handed out. It is refused, never read.
        FpfDocument doc = new FpfDocument("1.0", "buyer", validDoc().legal(), validDoc().einvoice(), null, null);
        assertEquals(List.of("fpf: must be \"1.1\""), Fpf.validate(doc));
    }

    @Test
    void wrongKindIsRejected() {
        FpfDocument doc = new FpfDocument("1.1", "seller", validDoc().legal(), validDoc().einvoice(), null, null);
        assertHasError(Fpf.validate(doc), "kind: must be \"buyer\"");
    }

    @Test
    void nullLegalAndEinvoiceAreNamed() {
        // A hand-built record can hold nulls that decode() would have refused,
        // so validate() has to survive them — same nuance as the C# reference.
        FpfDocument doc = new FpfDocument("1.1", "buyer", null, null, null, null);
        List<String> errors = Fpf.validate(doc);
        assertHasError(errors, "legal: required object");
        assertHasError(errors, "einvoice: required object");
    }

    @Test
    void badCountryAndEmptyName() {
        FpfDocument doc = new FpfDocument("1.1", "buyer",
                new Legal("France", "  ", null, null, null), validDoc().einvoice(), null, null);
        List<String> errors = Fpf.validate(doc);
        assertHasError(errors, "legal.country: ISO 3166-1 alpha-2 code required");
        assertHasError(errors, "legal.name: non-empty string required");
    }

    @Test
    void wellFormedIdsPass() {
        FpfDocument doc = new FpfDocument("1.1", "buyer",
                new Legal("FR", "ACME SAS", null,
                        List.of(new LegalId("0002", "542051180"), new LegalId("0009", "73282932000074")), null),
                validDoc().einvoice(), null, null);
        assertEquals(List.of(), Fpf.validate(doc));
    }

    @Test
    void presentButEmptyIdsAreRejected() {
        FpfDocument doc = new FpfDocument("1.1", "buyer",
                new Legal("FR", "ACME SAS", null, List.of(), null), validDoc().einvoice(), null, null);
        assertHasError(Fpf.validate(doc), "legal.ids: non-empty array required when present");
    }

    @Test
    void idSchemeMustBeFourDigits() {
        FpfDocument doc = new FpfDocument("1.1", "buyer",
                new Legal("FR", "ACME SAS", null, List.of(new LegalId("2", "542051180")), null),
                validDoc().einvoice(), null, null);
        assertHasError(Fpf.validate(doc), "legal.ids[0].scheme: 4-digit ICD scheme code required");
    }

    @Test
    void duplicateIdSchemeIsRejected() {
        FpfDocument doc = new FpfDocument("1.1", "buyer",
                new Legal("FR", "ACME SAS", null,
                        List.of(new LegalId("0002", "542051180"), new LegalId("0002", "999999999")), null),
                validDoc().einvoice(), null, null);
        assertHasError(Fpf.validate(doc), "legal.ids[1].scheme: duplicate scheme 0002");
    }

    @Test
    void theCoreKnowsNothingAboutSirenLengths() {
        // "12345" is not a SIREN, but that is PROFILE-FR's business, not the core's.
        FpfDocument doc = new FpfDocument("1.1", "buyer",
                new Legal("FR", "ACME SAS", null, List.of(new LegalId("0002", "12345")), null),
                validDoc().einvoice(), null, null);
        assertEquals(List.of(), Fpf.validate(doc));
    }

    @Test
    void emptyIdValueIsRejected() {
        FpfDocument doc = new FpfDocument("1.1", "buyer",
                new Legal("FR", "ACME SAS", null, List.of(new LegalId("0002", "   ")), null),
                validDoc().einvoice(), null, null);
        assertHasError(Fpf.validate(doc), "legal.ids[0].value: non-empty string required");
    }

    @Test
    void badEasAndEmptyAddress() {
        FpfDocument doc = new FpfDocument("1.1", "buyer", validDoc().legal(),
                new Einvoice("22", "", null), null, null);
        List<String> errors = Fpf.validate(doc);
        assertHasError(errors, "einvoice.eas: 4-digit EAS scheme code required");
        assertHasError(errors, "einvoice.address: non-empty string required");
    }
}
