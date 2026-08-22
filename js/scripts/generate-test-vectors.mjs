// Regenerates test-vectors.json from examples/*.json using the JS reference
// implementation. Run manually after changing examples/ or lib/fpf.js;
// the ci-js workflow verifies the committed file hasn't drifted from this
// script's output.

import { readFile, writeFile } from 'node:fs/promises';
import { encode } from '../lib/fpf.js';

const EXAMPLES_DIR = new URL('../../examples/', import.meta.url);
const OUTPUT_PATH = new URL('../../test-vectors.json', import.meta.url);

async function loadExample(name) {
  return JSON.parse(await readFile(new URL(name, EXAMPLES_DIR), 'utf8'));
}

// One version, one set of vectors. They pin the canonical key order that every
// implementation must reproduce byte for byte.
const VECTOR_SOURCES = [
  ['minimal', 'minimal.json'],
  ['complete', 'complete.json'],
];

const vectors = [];
for (const [name, file] of VECTOR_SOURCES) {
  const document = await loadExample(file);
  const payload_raw = await encode(document, { compress: false });
  const payload_deflate = await encode(document, { compress: true });
  vectors.push({ name, example: file, payload_raw, payload_deflate });
}

const output = {
  fpf_versions: ['1.1'],
  vectors,
  decode_failures: [
    { name: 'unknown-prefix', payload: '9.abcdef' },
    { name: 'truncated-deflate', payload: '2.YWJj' },
  ],
  validate_failures: [
    { name: 'missing-einvoice', example: 'invalid-missing-einvoice.json' },
    { name: 'version-1.0-withdrawn', example: 'invalid-version-1.0.json' },
  ],
};

await writeFile(OUTPUT_PATH, JSON.stringify(output, null, 2) + '\n');
console.log(`Wrote ${vectors.length} vectors to test-vectors.json`);
