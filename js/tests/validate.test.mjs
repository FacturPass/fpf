import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validate } from '../lib/fpf.js';

const VALID = {
  fpf: '1.0',
  kind: 'buyer',
  legal: { country: 'FR', name: 'ACME SAS' },
  einvoice: { eas: '0225', address: '542051180' },
};

test('minimal valid doc -> no errors', () => {
  assert.deepEqual(validate(VALID), []);
});

test('non-object -> single error', () => {
  assert.equal(validate(null).length, 1);
  assert.equal(validate('x').length, 1);
});

test('wrong fpf version', () => {
  assert.ok(validate({ ...VALID, fpf: '2.0' }).some((e) => e.startsWith('fpf:')));
});

test('wrong kind', () => {
  assert.ok(validate({ ...VALID, kind: 'seller' }).some((e) => e.startsWith('kind:')));
});

test('missing legal / einvoice blocks', () => {
  const { legal, ...noLegal } = VALID;
  const { einvoice, ...noEinvoice } = VALID;
  assert.ok(validate(noLegal).some((e) => e.startsWith('legal:')));
  assert.ok(validate(noEinvoice).some((e) => e.startsWith('einvoice:')));
});

test('bad country, empty name', () => {
  const errs = validate({ ...VALID, legal: { country: 'France', name: '  ' } });
  assert.ok(errs.some((e) => e.startsWith('legal.country:')));
  assert.ok(errs.some((e) => e.startsWith('legal.name:')));
});

test('bad optional siren/siret formats', () => {
  const errs = validate({
    ...VALID,
    legal: { ...VALID.legal, siren: '12345', siret: 'ABC' },
  });
  assert.ok(errs.some((e) => e.startsWith('legal.siren:')));
  assert.ok(errs.some((e) => e.startsWith('legal.siret:')));
});

test('bad eas / empty address', () => {
  const errs = validate({ ...VALID, einvoice: { eas: '22', address: '' } });
  assert.ok(errs.some((e) => e.startsWith('einvoice.eas:')));
  assert.ok(errs.some((e) => e.startsWith('einvoice.address:')));
});

// --- FPF 1.1: contact.ref renamed to contact.buyerReference (BT-10) ---

const VALID_11 = {
  fpf: '1.1',
  kind: 'buyer',
  legal: { country: 'FR', name: 'ACME SAS' },
  einvoice: { eas: '0225', address: '542051180' },
};

test('1.1 minimal doc -> no errors', () => {
  assert.deepEqual(validate(VALID_11), []);
});

test('1.0 documents stay valid (links already issued must keep decoding)', () => {
  assert.deepEqual(validate(VALID), []);
});

test('unknown versions are still rejected', () => {
  assert.ok(validate({ ...VALID, fpf: '2.0' }).some((e) => e.startsWith('fpf:')));
  assert.ok(validate({ ...VALID, fpf: '1.2' }).some((e) => e.startsWith('fpf:')));
});

test('contact.buyerReference is accepted in 1.1, contact.ref is not', () => {
  assert.deepEqual(validate({ ...VALID_11, contact: { buyerReference: 'EMP-042' } }), []);
  const errs = validate({ ...VALID_11, contact: { ref: 'EMP-042' } });
  assert.ok(errs.some((e) => e.startsWith('contact.ref:')), errs.join(' | '));
});

test('contact.ref is accepted in 1.0, contact.buyerReference is not', () => {
  assert.deepEqual(validate({ ...VALID, contact: { ref: 'EMP-042' } }), []);
  const errs = validate({ ...VALID, contact: { buyerReference: 'EMP-042' } });
  assert.ok(errs.some((e) => e.startsWith('contact.buyerReference:')), errs.join(' | '));
});
