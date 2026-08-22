package com.facturpass.fpf;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record Legal(
        String country,
        String name,
        String form,
        List<LegalId> ids,
        String vat) {}
