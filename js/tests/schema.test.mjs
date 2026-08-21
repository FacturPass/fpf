import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import Ajv2020 from 'ajv/dist/2020.js';

async function loadJson(path) {
  return JSON.parse(await readFile(new URL(path, import.meta.url), 'utf8'));
}

const ajv = new Ajv2020.default({ allErrors: true, strict: false });
const schema = await loadJson('../../fpf-1.0.schema.json');
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
  assert.equal(check({ fpf: '1.0', kind: 'buyer', legal: { country: 'FR', name: 'X' }, einvoice: { eas: '0225', address: '1' }, extra: true }), false);
});

// --- FPF 1.1 schema ---

const schema11 = await loadJson('../../fpf-1.1.schema.json');
const check11 = ajv.compile(schema11);

test('1.1 examples are valid against the 1.1 schema', async () => {
  assert.ok(check11(await loadJson('../../examples/minimal-1.1.json')), JSON.stringify(check11.errors));
  assert.ok(check11(await loadJson('../../examples/complete-1.1.json')), JSON.stringify(check11.errors));
});

test('1.1 schema rejects the old contact.ref key', () => {
  assert.equal(check11({ fpf: '1.1', kind: 'buyer', legal: { country: 'FR', name: 'X' }, einvoice: { eas: '0225', address: '1' }, contact: { ref: 'A' } }), false);
});

test('1.0 schema rejects the new contact.buyerReference key', () => {
  assert.equal(check({ fpf: '1.0', kind: 'buyer', legal: { country: 'FR', name: 'X' }, einvoice: { eas: '0225', address: '1' }, contact: { buyerReference: 'A' } }), false);
});
