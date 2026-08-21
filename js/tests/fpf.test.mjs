import { test } from 'node:test';
import assert from 'node:assert/strict';
import { encode, decode, validate } from '../lib/fpf.js';

const DOC = {
  fpf: '1.1',
  kind: 'buyer',
  legal: { country: 'FR', name: 'Société Générale d’Électricité' },
  einvoice: { eas: '0225', address: '542051180' },
};

test('round-trip deflate (prefix 2.)', async () => {
  const payload = await encode(DOC);
  assert.ok(payload.startsWith('2.'));
  assert.deepEqual(await decode(payload), DOC);
});

test('round-trip raw (prefix 1.)', async () => {
  const payload = await encode(DOC, { compress: false });
  assert.ok(payload.startsWith('1.'));
  assert.deepEqual(await decode(payload), DOC);
});

test('payload is URL-safe (no + / = characters)', async () => {
  const payload = await encode(DOC);
  assert.doesNotMatch(payload.slice(2), /[+/=]/);
});

test('UTF-8 accents survive the round-trip', async () => {
  const doc = { ...DOC, legal: { country: 'FR', name: 'Àéîõü & Cie — «test»' } };
  assert.deepEqual(await decode(await encode(doc)), doc);
});

test('unknown prefix rejects', async () => {
  await assert.rejects(() => decode('9.abcdef'), /prefix/i);
});

test('truncated payload rejects', async () => {
  const payload = await encode(DOC);
  await assert.rejects(() => decode(payload.slice(0, 10)));
});

test('compressed payload is smaller than raw for a full doc', async () => {
  const full = {
    ...DOC,
    legal: { ...DOC.legal, form: 'SAS', ids: [{ scheme: '0002', value: '542051180' }, { scheme: '0009', value: '73282932000074' }], vat: 'FR59542051180' },
    billing: { street: '1 rue de la Paix', zip: '75001', city: 'Paris', country: 'FR' },
    contact: { email: 'compta@example.fr', phone: '+33100000000', buyerReference: 'EMP-042' },
  };
  const deflated = await encode(full);
  const raw = await encode(full, { compress: false });
  assert.ok(deflated.length < raw.length);
});

// --- Round-trip against the published examples ---
// test-vectors.json pins the cross-language contract; these keep the JS
// reference honest on its own, without loading the shared file.

import { readFile } from 'node:fs/promises';

for (const name of ['minimal.json', 'complete.json']) {
  test(`round-trip ${name} through both transports`, async () => {
    const doc = JSON.parse(await readFile(new URL(`../../examples/${name}`, import.meta.url), 'utf8'));
    assert.deepEqual(await decode(await encode(doc, { compress: false })), doc);
    assert.deepEqual(await decode(await encode(doc, { compress: true })), doc);
    assert.deepEqual(validate(doc), []);
  });
}
