package com.facturpass.fpf;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.io.UncheckedIOException;
import org.junit.jupiter.api.Test;

/** The shared test vectors, run by every reference implementation. */
class VectorTest {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private static JsonNode vectorFile() {
        try {
            return MAPPER.readTree(TestFixtures.read("test-vectors.json"));
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    private static JsonNode block(String name) {
        JsonNode node = vectorFile().get(name);
        // A loop over an empty array would pass without testing anything.
        assertFalse(node == null || node.isEmpty(), "test-vectors.json carries no " + name);
        return node;
    }

    private static FpfDocument example(JsonNode vector) {
        try {
            return MAPPER.readValue(
                    TestFixtures.read("examples/" + vector.get("example").asText()), FpfDocument.class);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    @Test
    void vectorsDecodeToTheExpectedDocument() {
        for (JsonNode vector : block("vectors")) {
            FpfDocument expected = example(vector);
            String name = vector.get("name").asText();
            assertEquals(expected, Fpf.decode(vector.get("payload_raw").asText()), "raw payload for " + name);
            assertEquals(expected, Fpf.decode(vector.get("payload_deflate").asText()), "deflate payload for " + name);
        }
    }

    @Test
    void encodeRawMatchesTheVectorExactly() {
        for (JsonNode vector : block("vectors")) {
            assertEquals(vector.get("payload_raw").asText(), Fpf.encode(example(vector), false),
                    "raw encode for " + vector.get("name").asText());
        }
    }

    @Test
    void encodeDeflateRoundTrips() {
        // The 2. transport is only ever checked by round-trip: two deflate
        // implementations have no reason to emit the same bytes.
        for (JsonNode vector : block("vectors")) {
            FpfDocument doc = example(vector);
            assertEquals(doc, Fpf.decode(Fpf.encode(doc, true)),
                    "deflate round-trip for " + vector.get("name").asText());
        }
    }

    @Test
    void decodeFailuresAreRejected() {
        for (JsonNode failure : block("decode_failures")) {
            assertThrows(FpfException.class, () -> Fpf.decode(failure.get("payload").asText()),
                    "expected failure: " + failure.get("name").asText());
        }
    }

    @Test
    void validateFailuresProduceErrors() {
        for (JsonNode failure : block("validate_failures")) {
            String name = failure.get("name").asText();
            String raw = TestFixtures.read("examples/" + failure.get("example").asText());
            // A document that will not even map into an FpfDocument is a
            // fortiori invalid: decoding enforces the same shape the untyped JS
            // reference checks inside validate(). Either outcome satisfies this
            // vector, exactly as in the Rust reference.
            FpfDocument doc;
            try {
                doc = MAPPER.readValue(raw, FpfDocument.class);
            } catch (IOException e) {
                continue;
            }
            assertTrue(Fpf.validate(doc).size() > 0, "expected validate errors: " + name);
        }
    }
}
