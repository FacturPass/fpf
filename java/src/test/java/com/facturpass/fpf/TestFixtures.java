package com.facturpass.fpf;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Locates the fixtures shared with the other reference implementations by
 * walking up from the working directory until {@code test-vectors.json} shows
 * up — the equivalent of Rust's {@code CARGO_MANIFEST_DIR}, so the tests do not
 * depend on where the build is run from.
 */
final class TestFixtures {

    private TestFixtures() {}

    static Path repoRoot() {
        Path dir = Paths.get("").toAbsolutePath();
        while (dir != null) {
            if (Files.exists(dir.resolve("test-vectors.json"))) {
                return dir;
            }
            dir = dir.getParent();
        }
        throw new IllegalStateException(
                "test-vectors.json not found above " + Paths.get("").toAbsolutePath());
    }

    /** Always UTF-8: the platform default is Cp1252 on a French Windows. */
    static String read(String relativePath) {
        try {
            return Files.readString(repoRoot().resolve(relativePath), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
