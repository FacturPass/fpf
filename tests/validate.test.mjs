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
