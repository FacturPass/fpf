package com.facturpass.fpf;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record Einvoice(String eas, String address, String platform) {}
