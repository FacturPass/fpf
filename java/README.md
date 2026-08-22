# FPF — Java reference implementation

`encode` / `decode` / `validate` for the [FPF format](../SPEC.md), targeting
Java 17.

```xml
<dependency>
  <groupId>com.facturpass</groupId>
  <artifactId>fpf</artifactId>
  <version>0.1.0</version>
</dependency>
```

```java
FpfDocument doc = Fpf.decode(payload);   // throws FpfException
List<String> errors = Fpf.validate(doc);
String link = Fpf.encode(doc);           // compressed "2." transport
```

One runtime dependency, [Jackson](https://github.com/FasterXML/jackson-databind):
a payload comes from a scanned QR code, so the JSON parser reads untrusted input
and that is not a good place for a hand-rolled one. Base64url and raw deflate
come from the JDK (`java.util.Base64`, `java.util.zip`).

## Development

```bash
mvn -B test -f java/pom.xml
```

Tests include the shared [`test-vectors.json`](../test-vectors.json) also used by
the JS, Rust, C# and Pascal implementations — keep it in sync via
[`js/scripts/generate-test-vectors.mjs`](../js/README.md) if you change
`examples/*.json`.

Being a typed implementation, it departs from the untyped JS reference on a few
checks that a type makes impossible to represent — see
[Where the typed implementations legitimately differ](../CONTRIBUTING.md#where-the-typed-implementations-legitimately-differ).
