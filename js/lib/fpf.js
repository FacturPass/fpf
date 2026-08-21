// FPF 1.0/1.1 reference implementation — encode/decode of the transport payload.
// Works unchanged in browsers (>= 2023) and Node >= 22.

// Every version ever published stays readable: a QR code printed years ago
// must still decode. New documents are written in the latest version.
const VERSIONS = ['1.0', '1.1'];

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

export function validate(doc) {
  if (doc === null || typeof doc !== 'object' || Array.isArray(doc)) {
    return ['document: must be a JSON object'];
  }
  const errors = [];
  if (!VERSIONS.includes(doc.fpf)) errors.push('fpf: must be "1.0" or "1.1"');
  if (doc.kind !== 'buyer') errors.push('kind: must be "buyer"');

  const legal = doc.legal;
  if (legal === null || typeof legal !== 'object') {
    errors.push('legal: required object');
  } else {
    if (!/^[A-Z]{2}$/.test(legal.country ?? '')) errors.push('legal.country: ISO 3166-1 alpha-2 code required');
    if (typeof legal.name !== 'string' || legal.name.trim() === '') errors.push('legal.name: non-empty string required');
    if (legal.siren !== undefined && !/^\d{9}$/.test(legal.siren)) errors.push('legal.siren: must be 9 digits');
    if (legal.siret !== undefined && !/^\d{14}$/.test(legal.siret)) errors.push('legal.siret: must be 14 digits');
  }

  const einvoice = doc.einvoice;
  if (einvoice === null || typeof einvoice !== 'object') {
    errors.push('einvoice: required object');
  } else {
    if (!/^\d{4}$/.test(einvoice.eas ?? '')) errors.push('einvoice.eas: 4-digit EAS scheme code required');
    if (typeof einvoice.address !== 'string' || einvoice.address.trim() === '') errors.push('einvoice.address: non-empty string required');
  }

  // contact.ref became contact.buyerReference (EN 16931 BT-10) in 1.1. Each
  // version accepts only its own key, so a reader keys off doc.fpf and never
  // has to guess which of the two a document meant.
  const contact = doc.contact;
  if (contact !== null && typeof contact === 'object') {
    if (doc.fpf === '1.1' && contact.ref !== undefined) {
      errors.push('contact.ref: renamed to contact.buyerReference in FPF 1.1');
    }
    if (doc.fpf === '1.0' && contact.buyerReference !== undefined) {
      errors.push('contact.buyerReference: not in FPF 1.0, use contact.ref');
    }
  }
  return errors;
}
