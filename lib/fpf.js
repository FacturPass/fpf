// FPF 1.0 reference implementation — encode/decode of the transport payload.
// Works unchanged in browsers (>= 2023) and Node >= 22.

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
