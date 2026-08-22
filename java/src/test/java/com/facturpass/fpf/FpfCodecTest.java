package com.facturpass.fpf;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.zip.Inflater;
import org.junit.jupiter.api.Test;

class FpfCodecTest {

    /** payload_raw of the "minimal" vector, produced by the JS reference. */
    static final String MINIMAL_RAW =
            "1.eyJmcGYiOiIxLjEiLCJraW5kIjoiYnV5ZXIiLCJsZWdhbCI6eyJjb3VudHJ5IjoiRlIiLCJuYW1l"
            + "IjoiQUNNRSBTQVMifSwiZWludm9pY2UiOnsiZWFzIjoiMDIyNSIsImFkZHJlc3MiOiI1NDIwNTExOD"
            + "AifX0";

    static final String MINIMAL_JSON =
            "{\"fpf\":\"1.1\",\"kind\":\"buyer\",\"legal\":{\"country\":\"FR\",\"name\":\"ACME SAS\"},"
            + "\"einvoice\":{\"eas\":\"0225\",\"address\":\"542051180\"}}";

    static FpfDocument minimalDoc() {
        return new FpfDocument(
                "1.1", "buyer",
                new Legal("FR", "ACME SAS", null, null, null),
                new Einvoice("0225", "542051180", null),
                null, null);
    }

    private static String bodyOf(String payload) {
        return payload.substring(2);
    }

    @Test
    void encodeRawMatchesTheVectorByteForByte() {
        assertEquals(MINIMAL_RAW, Fpf.encode(minimalDoc(), false));
    }

    @Test
    void encodeProducesTheCanonicalKeyOrder() {
        byte[] json = Base64.getUrlDecoder().decode(bodyOf(Fpf.encode(minimalDoc(), false)));
        assertEquals(MINIMAL_JSON, new String(json, StandardCharsets.UTF_8));
    }

    @Test
    void encodeOmitsEmptyOptionalKeys() {
        byte[] json = Base64.getUrlDecoder().decode(bodyOf(Fpf.encode(minimalDoc(), false)));
        String text = new String(json, StandardCharsets.UTF_8);
        assertFalse(text.contains("billing"), text);
        assertFalse(text.contains("contact"), text);
        assertFalse(text.contains("\"form\""), text);
        assertFalse(text.contains("\"ids\""), text);
    }

    @Test
    void encodeCompressedUsesThe2PrefixAndIsRawDeflate() throws Exception {
        String payload = Fpf.encode(minimalDoc(), true);
        assertTrue(payload.startsWith("2."), payload);

        // Inflated here with a bare java.util.zip.Inflater in nowrap mode: if the
        // encoder ever emitted a zlib header, this would throw.
        Inflater inflater = new Inflater(true);
        inflater.setInput(Base64.getUrlDecoder().decode(bodyOf(payload)));
        byte[] out = new byte[4096];
        int n = inflater.inflate(out);
        inflater.end();
        assertEquals(MINIMAL_JSON, new String(out, 0, n, StandardCharsets.UTF_8));
    }

    @Test
    void accentsSurviveTheRoundTrip() {
        FpfDocument doc = new FpfDocument(
                "1.1", "buyer",
                new Legal("FR", "Boulangerie Orléans & Fils", null, null, null),
                new Einvoice("0225", "542051180", null),
                null, null);
        assertEquals(doc, Fpf.decode(Fpf.encode(doc, true)));
    }
}
