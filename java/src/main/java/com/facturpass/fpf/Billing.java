package com.facturpass.fpf;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record Billing(String street, String zip, String city, String country) {}
