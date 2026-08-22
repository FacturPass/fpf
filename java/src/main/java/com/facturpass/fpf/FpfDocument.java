package com.facturpass.fpf;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.List;

/**
 * An FPF 1.1 document. Mirrors the Rust reference implementation at
 * ../rust/src/lib.rs.
 *
 * <p>Records serialize their components in declaration order, which is what
 * gives the canonical key order the byte-exact "1." transport depends on — so
 * the order below is contractual, not cosmetic.
 *
 * <p>{@code null} means absent. An empty optional must be omitted from the
 * document entirely, never emitted as {@code ""} or {@code null}, which is what
 * {@link JsonInclude.Include#NON_NULL} enforces.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record FpfDocument(
        String fpf,
        String kind,
        Legal legal,
        Einvoice einvoice,
        Billing billing,
        Contact contact) {}
