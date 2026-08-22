package com.facturpass.fpf;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Base64;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.zip.DataFormatException;
import java.util.zip.Deflater;
import java.util.zip.Inflater;

/**
 * FPF 1.1 reference implementation — encode/decode of the transport payload.
 * Mirrors the Rust reference implementation at ../rust/src/lib.rs.
 */
public final class Fpf {

    private static final String PREFIX_RAW = "1.";
    private static final String PREFIX_DEFLATE = "2.";

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private Fpf() {}

    /**
     * Serializes and encodes a document into a transport payload. Infallible:
     * serializing an already-built record and compressing in memory cannot
     * reasonably fail, mirroring the other reference implementations, which
     * document no error path for encoding.
     */
    public static String encode(FpfDocument doc, boolean compress) {
        byte[] json;
        try {
            json = MAPPER.writeValueAsBytes(doc);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("FPF: a document always serializes", e);
        }
        if (!compress) {
            return PREFIX_RAW + toBase64Url(json);
        }
        return PREFIX_DEFLATE + toBase64Url(rawDeflate(json));
    }

    /** Encodes with the nominal compressed transport. */
    public static String encode(FpfDocument doc) {
        return encode(doc, true);
    }

    private static String toBase64Url(byte[] bytes) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    // nowrap = true skips the zlib header: FPF carries deflate-raw, the same
    // thing the browsers' CompressionStream('deflate-raw') emits.
    private static byte[] rawDeflate(byte[] input) {
        Deflater deflater = new Deflater(Deflater.DEFAULT_COMPRESSION, true);
        try {
            deflater.setInput(input);
            deflater.finish();
            ByteArrayOutputStream out = new ByteArrayOutputStream(input.length);
            byte[] buffer = new byte[4096];
            while (!deflater.finished()) {
                out.write(buffer, 0, deflater.deflate(buffer));
            }
            return out.toByteArray();
        } finally {
            deflater.end();
        }
    }

    private static byte[] rawInflate(byte[] input) throws DataFormatException {
        Inflater inflater = new Inflater(true);
        try {
            inflater.setInput(input);
            ByteArrayOutputStream out = new ByteArrayOutputStream(input.length * 3);
            byte[] buffer = new byte[4096];
            while (!inflater.finished()) {
                int read = inflater.inflate(buffer);
                if (read == 0 && (inflater.needsInput() || inflater.needsDictionary())) {
                    // Truncated: the stream ended before the deflate block did.
                    throw new DataFormatException("truncated deflate stream");
                }
                out.write(buffer, 0, read);
            }
            return out.toByteArray();
        } finally {
            inflater.end();
        }
    }

    /**
     * Decodes a transport payload back into a document.
     *
     * @throws FpfException with a {@link FpfException.Kind} saying how it failed
     */
    public static FpfDocument decode(String payload) throws FpfException {
        byte[] bytes;
        if (payload.startsWith(PREFIX_DEFLATE)) {
            byte[] compressed = fromBase64Url(payload.substring(PREFIX_DEFLATE.length()));
            try {
                bytes = rawInflate(compressed);
            } catch (DataFormatException e) {
                throw new FpfException(FpfException.Kind.INFLATE, "FPF: inflate error: " + e.getMessage(), e);
            }
        } else if (payload.startsWith(PREFIX_RAW)) {
            bytes = fromBase64Url(payload.substring(PREFIX_RAW.length()));
        } else {
            throw new FpfException(FpfException.Kind.UNKNOWN_PREFIX, "FPF: unknown payload prefix");
        }

        FpfDocument doc;
        try {
            doc = MAPPER.readValue(bytes, FpfDocument.class);
        } catch (Exception e) {
            throw new FpfException(FpfException.Kind.JSON, "FPF: JSON error: " + e.getMessage(), e);
        }
        return required(doc);
    }

    private static byte[] fromBase64Url(String body) {
        try {
            return Base64.getUrlDecoder().decode(body);
        } catch (IllegalArgumentException e) {
            throw new FpfException(FpfException.Kind.BASE64, "FPF: base64 decode error: " + e.getMessage(), e);
        }
    }

    // Jackson leaves a missing record component null. Rust's serde refuses the
    // document outright, and this mirrors it: a truncated document is an error
    // at decode, never a half-filled record handed to the caller.
    private static FpfDocument required(FpfDocument doc) {
        if (doc == null) {
            throw missing("document");
        }
        requireText(doc.fpf(), "fpf");
        requireText(doc.kind(), "kind");
        if (doc.legal() == null) {
            throw missing("legal");
        }
        requireText(doc.legal().country(), "legal.country");
        requireText(doc.legal().name(), "legal.name");
        if (doc.legal().ids() != null) {
            List<LegalId> ids = doc.legal().ids();
            for (int i = 0; i < ids.size(); i++) {
                if (ids.get(i) == null) {
                    throw missing("legal.ids[" + i + "]");
                }
                requireText(ids.get(i).scheme(), "legal.ids[" + i + "].scheme");
                requireText(ids.get(i).value(), "legal.ids[" + i + "].value");
            }
        }
        if (doc.einvoice() == null) {
            throw missing("einvoice");
        }
        requireText(doc.einvoice().eas(), "einvoice.eas");
        requireText(doc.einvoice().address(), "einvoice.address");
        return doc;
    }

    private static void requireText(String value, String field) {
        if (value == null) {
            throw missing(field);
        }
    }

    private static FpfException missing(String field) {
        return new FpfException(FpfException.Kind.JSON, "FPF: JSON error: missing field `" + field + "`");
    }

    private static boolean isAsciiDigits(String s, int length) {
        if (s == null || s.length() != length) {
            return false;
        }
        for (int i = 0; i < length; i++) {
            if (s.charAt(i) < '0' || s.charAt(i) > '9') {
                return false;
            }
        }
        return true;
    }

    private static boolean isCountryCode(String s) {
        if (s == null || s.length() != 2) {
            return false;
        }
        return s.charAt(0) >= 'A' && s.charAt(0) <= 'Z' && s.charAt(1) >= 'A' && s.charAt(1) <= 'Z';
    }

    private static boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }

    /**
     * Structural and semantic validation, mirroring the Rust and JS references'
     * {@code validate()}.
     *
     * <p>Must tolerate a hand-built document whose {@code legal} or
     * {@code einvoice} is null: Java, like C# and unlike Rust, cannot stop a
     * record component from being null. A payload missing those keys never gets
     * this far — {@link #decode} refuses it.
     */
    public static List<String> validate(FpfDocument doc) {
        List<String> errors = new ArrayList<>();

        if (!"1.1".equals(doc.fpf())) {
            errors.add("fpf: must be \"1.1\"");
        }
        if (!"buyer".equals(doc.kind())) {
            errors.add("kind: must be \"buyer\"");
        }

        if (doc.legal() == null) {
            errors.add("legal: required object");
        } else {
            if (!isCountryCode(doc.legal().country())) {
                errors.add("legal.country: ISO 3166-1 alpha-2 code required");
            }
            if (isBlank(doc.legal().name())) {
                errors.add("legal.name: non-empty string required");
            }
            validateIds(doc.legal().ids(), errors);
        }

        if (doc.einvoice() == null) {
            errors.add("einvoice: required object");
        } else {
            if (!isAsciiDigits(doc.einvoice().eas(), 4)) {
                errors.add("einvoice.eas: 4-digit EAS scheme code required");
            }
            if (isBlank(doc.einvoice().address())) {
                errors.add("einvoice.address: non-empty string required");
            }
        }

        return errors;
    }

    private static void validateIds(List<LegalId> ids, List<String> errors) {
        if (ids == null) {
            return;
        }
        if (ids.isEmpty()) {
            errors.add("legal.ids: non-empty array required when present");
        }
        Set<String> seen = new HashSet<>();
        for (int i = 0; i < ids.size(); i++) {
            LegalId id = ids.get(i);
            String scheme = id == null ? null : id.scheme();
            if (!isAsciiDigits(scheme, 4)) {
                errors.add("legal.ids[" + i + "].scheme: 4-digit ICD scheme code required");
            } else if (!seen.add(scheme)) {
                errors.add("legal.ids[" + i + "].scheme: duplicate scheme " + scheme);
            }
            // A number here is the classic hand-rolled-encoder bug: a SIRET
            // emitted as 73282932000074 loses any leading zero and breaks
            // string comparison.
            if (id == null || isBlank(id.value())) {
                errors.add("legal.ids[" + i + "].value: non-empty string required");
            }
        }
    }
}
