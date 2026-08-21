import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import Ajv2020 from 'ajv/dist/2020.js';

async function loadJson(path) {
  return JSON.parse(await readFile(new URL(path, import.meta.url), 'utf8'));
}

const ajv = new Ajv2020.default({ allErrors: true, strict: false });
const schema = await loadJson('../../fpf-1.1.schema.json');
const check = ajv.compile(schema);

test('minimal example is valid', async () => {
  assert.ok(check(await loadJson('../../examples/minimal.json')), JSON.stringify(check.errors));
});

test('complete example is valid', async () => {
  assert.ok(check(await loadJson('../../examples/complete.json')), JSON.stringify(check.errors));
});

test('invalid example is rejected', async () => {
  assert.equal(check(await loadJson('../../examples/invalid-missing-einvoice.json')), false);
});

test('additional top-level properties are rejected', () => {
  assert.equal(check({ fpf: '1.1', kind: 'buyer', legal: { country: 'FR', name: 'X' }, einvoice: { eas: '0225', address: '1' }, extra: true }), false);
});

test('the withdrawn contact.ref key is rejected', async () => {
  assert.equal(check(await loadJson('../../examples/invalid-legacy-ref.json')), false);
});

test('a 1.0 document is rejected by the schema too', async () => {
  assert.equal(check(await loadJson('../../examples/invalid-version-1.0.json')), false);
});
