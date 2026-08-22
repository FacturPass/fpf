package com.facturpass.fpf;

import com.fasterxml.jackson.annotation.JsonInclude;

/**
 * A registration identifier (EN 16931 BT-47) qualified by its ICD scheme code
 * (BT-47-1), drawn from the same registry as {@code einvoice.eas}. What a scheme
 * means — 0002 is a French SIREN, 0009 a SIRET — belongs to the country
 * profiles, not here.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record LegalId(String scheme, String value) {}
