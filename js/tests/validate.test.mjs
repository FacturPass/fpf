import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validate } from '../lib/fpf.js';

const VALID = {
  fpf: '1.1',
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
  assert.ok(validate({ ...VALID, fpf: '1.2' }).some((e) => e.startsWith('fpf:')));
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

const withIds = (ids) => ({ ...VALID, legal: { ...VALID.legal, ids } });

test('legal.ids: a well-formed list passes', () => {
  assert.deepEqual(
    validate(withIds([
      { scheme: '0002', value: '542051180' },
      { scheme: '0009', value: '73282932000074' },
    ])),
    [],
  );
});

test('legal.ids: the scheme is a 4-digit ICD code', () => {
  const errs = validate(withIds([{ scheme: '2', value: '542051180' }]));
  assert.ok(errs.some((e) => e.startsWith('legal.ids[0].scheme:')), errs.join(' | '));
});

test('legal.ids: the same scheme cannot appear twice', () => {
  const errs = validate(withIds([
    { scheme: '0002', value: '542051180' },
    { scheme: '0002', value: '999999999' },
  ]));
  assert.ok(errs.some((e) => e.includes('duplicate scheme 0002')), errs.join(' | '));
});

test('legal.ids: a numeric value is rejected — identifiers are strings', () => {
  const errs = validate(withIds([{ scheme: '0009', value: 73282932000074 }]));
  assert.ok(errs.some((e) => e.startsWith('legal.ids[0].value:')), errs.join(' | '));
});

test('legal.ids: an empty list is rejected, an absent one is fine', () => {
  assert.ok(validate(withIds([])).some((e) => e.startsWith('legal.ids:')));
  assert.deepEqual(validate(VALID), []);
});

test('legal.ids: the core format knows nothing about SIREN lengths', () => {
  // "12345" is not a SIREN, but that is PROFILE-FR's business, not the core's.
  assert.deepEqual(validate(withIds([{ scheme: '0002', value: '12345' }])), []);
});

test('bad eas / empty address', () => {
  const errs = validate({ ...VALID, einvoice: { eas: '22', address: '' } });
  assert.ok(errs.some((e) => e.startsWith('einvoice.eas:')));
  assert.ok(errs.some((e) => e.startsWith('einvoice.address:')));
});

// --- 1.1 is the only version ---

test('a 1.0 document is rejected: the version was withdrawn before anyone used it', () => {
  assert.deepEqual(validate({ ...VALID, fpf: '1.0' }), ['fpf: must be "1.1"']);
});

// --- contact.buyerReference (EN 16931 BT-10) is the only spelling ---

test('contact.buyerReference is accepted', () => {
  assert.deepEqual(validate({ ...VALID, contact: { buyerReference: 'EMP-042' } }), []);
});
