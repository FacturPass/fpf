package com.facturpass.fpf;

import com.fasterxml.jackson.annotation.JsonInclude;

/** {@code buyerReference} (EN 16931 BT-10) is the only spelling. */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record Contact(String email, String phone, String buyerReference) {}
