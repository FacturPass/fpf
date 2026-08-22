package com.facturpass.fpf;

/**
 * A payload that could not be decoded. {@link #kind} says which of the four ways
 * it failed, mirroring Rust's {@code FpfError}.
 *
 * <p>Unchecked on purpose: C# and Pascal raise unchecked exceptions and Rust
 * returns a {@code Result} nothing forces the caller to handle at the call site.
 * Parity decides.
 */
public class FpfException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    public enum Kind {
        UNKNOWN_PREFIX,
        BASE64,
        INFLATE,
        JSON
    }

    public final Kind kind;

    public FpfException(Kind kind, String message) {
        super(message);
        this.kind = kind;
    }

    public FpfException(Kind kind, String message, Throwable cause) {
        super(message, cause);
        this.kind = kind;
    }
}
