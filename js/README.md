# FPF — JavaScript reference implementation

`encode` / `decode` / `validate` for the [FPF format](../SPEC.md). Zero runtime
dependencies; Node ≥ 22 (uses native `CompressionStream`/`DecompressionStream`).

```js
import { encode, decode, validate } from './lib/fpf.js';
```

## Development

```bash
npm install
npm test
```

After changing `examples/*.json` or `lib/fpf.js`, regenerate the shared
[`test-vectors.json`](../test-vectors.json) used by every language implementation:

```bash
node scripts/generate-test-vectors.mjs
```

CI ([`ci-js.yml`](../.github/workflows/ci-js.yml)) fails if the committed
`test-vectors.json` doesn't match this script's output, so run it and commit the
result whenever those files change.
