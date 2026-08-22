// FPF 1.1 reference implementation — encode/decode of the transport payload.
// Works unchanged in browsers (>= 2023) and Node >= 22.

// 1.1 is the only version. 1.0 was published briefly and withdrawn before any
// document was ever handed out, so it is refused rather than read.
const VERSIONS = ['1.1'];

const PREFIX_RAW = '1.';
const PREFIX_DEFLATE = '2.';

function toBase64Url(bytes) {
  let bin = '';
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '');
}

function fromBase64Url(str) {
  const b64 = str.replaceAll('-', '+').replaceAll('_', '/');
  const padded = b64 + '='.repeat((4 - (b64.length % 4)) % 4);
  const bin = atob(padded);
  return Uint8Array.from(bin, (c) => c.charCodeAt(0));
}

async function pipeThrough(bytes, transform) {
  const stream = new Blob([bytes]).stream().pipeThrough(transform);
  return new Uint8Array(await new Response(stream).arrayBuffer());
}

export async function encode(doc, { compress = true } = {}) {
  const bytes = new TextEncoder().encode(JSON.stringify(doc));
  if (!compress) return PREFIX_RAW + toBase64Url(bytes);
  const deflated = await pipeThrough(bytes, new CompressionStream('deflate-raw'));
  return PREFIX_DEFLATE + toBase64Url(deflated);
}

export async function decode(payload) {
  let bytes;
  if (payload.startsWith(PREFIX_DEFLATE)) {
    bytes = await pipeThrough(
      fromBase64Url(payload.slice(PREFIX_DEFLATE.length)),
      new DecompressionStream('deflate-raw'),
    );
  } else if (payload.startsWith(PREFIX_RAW)) {
    bytes = fromBase64Url(payload.slice(PREFIX_RAW.length));
  } else {
    throw new Error('FPF: unknown payload prefix');
  }
  return JSON.parse(new TextDecoder().decode(bytes));
}

// legal.ids carries the buyer's registration identifiers (EN 16931 BT-47), each
// qualified by an ICD scheme code (BT-47-1) drawn from the same registry as
// einvoice.eas. What a scheme means — 0002 is a French SIREN, 0009 a SIRET — and
// the check digits it implies belong to the country profiles, not here: the core
// format has no business knowing that a SIREN is nine digits.
function idErrors(ids) {
  if (ids === undefined) return [];
  if (!Array.isArray(ids) || ids.length === 0) return ['legal.ids: non-empty array required when present'];
  const errors = [];
  const seen = new Set();
  ids.forEach((id, i) => {
    if (id === null || typeof id !== 'object' || Array.isArray(id)) {
      errors.push(`legal.ids[${i}]: must be an object`);
      return;
    }
    if (!/^\d{4}$/.test(id.scheme ?? '')) errors.push(`legal.ids[${i}].scheme: 4-digit ICD scheme code required`);
    else if (seen.has(id.scheme)) errors.push(`legal.ids[${i}].scheme: duplicate scheme ${id.scheme}`);
    else seen.add(id.scheme);
    // A number here is the classic hand-rolled-encoder bug: a SIRET emitted as
    // 73282932000074 loses any leading zero and breaks string comparison.
    if (typeof id.value !== 'string' || id.value.trim() === '') errors.push(`legal.ids[${i}].value: non-empty string required`);
  });
  return errors;
}

export function validate(doc) {
  if (doc === null || typeof doc !== 'object' || Array.isArray(doc)) {
    return ['document: must be a JSON object'];
  }
  const errors = [];
  if (!VERSIONS.includes(doc.fpf)) errors.push('fpf: must be "1.1"');
  if (doc.kind !== 'buyer') errors.push('kind: must be "buyer"');

  const legal = doc.legal;
  if (legal === null || typeof legal !== 'object') {
    errors.push('legal: required object');
  } else {
    if (!/^[A-Z]{2}$/.test(legal.country ?? '')) errors.push('legal.country: ISO 3166-1 alpha-2 code required');
    if (typeof legal.name !== 'string' || legal.name.trim() === '') errors.push('legal.name: non-empty string required');
    errors.push(...idErrors(legal.ids));
  }

  const einvoice = doc.einvoice;
  if (einvoice === null || typeof einvoice !== 'object') {
    errors.push('einvoice: required object');
  } else {
    if (!/^\d{4}$/.test(einvoice.eas ?? '')) errors.push('einvoice.eas: 4-digit EAS scheme code required');
    if (typeof einvoice.address !== 'string' || einvoice.address.trim() === '') errors.push('einvoice.address: non-empty string required');
  }

  return errors;
}
