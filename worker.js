const QWEN_PREFIX = '/hf/onnx-community/Qwen3-0.6B-ONNX/';
const HF_ORIGIN = 'https://huggingface.co/';
const ORT_PREFIX = '/ort/';
const ORT_ORIGIN =
  'https://cdn.jsdelivr.net/npm/onnxruntime-web@1.31.0-dev.20260914-8d85527a0/dist/';

function upstreamRequest(request, targetUrl) {
  const headers = new Headers();

  for (const name of [
    'accept',
    'accept-encoding',
    'if-none-match',
    'if-modified-since',
    'range',
  ]) {
    const value = request.headers.get(name);
    if (value) headers.set(name, value);
  }

  return new Request(targetUrl, {
    method: request.method === 'HEAD' ? 'HEAD' : 'GET',
    headers,
    redirect: 'follow',
  });
}

async function streamProxy(request, targetUrl) {
  const upstream = await fetch(upstreamRequest(request, targetUrl), {
    // Do not try to store very large model responses in Cloudflare cache.
    cf: {
      cacheEverything: false,
      cacheTtl: 0,
    },
  });

  // Stream the body directly. Do not buffer hundreds of MB in Worker memory.
  const headers = new Headers(upstream.headers);
  headers.set('Cross-Origin-Resource-Policy', 'same-origin');
  headers.set('X-Budget-Local-Proxy', '1');
  headers.delete('set-cookie');

  return new Response(request.method === 'HEAD' ? null : upstream.body, {
    status: upstream.status,
    statusText: upstream.statusText,
    headers,
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return new Response('Method Not Allowed', { status: 405 });
    }

    if (url.pathname.startsWith(QWEN_PREFIX)) {
      // Whitelist only the public Qwen repository used by Budget Local.
      const relative = url.pathname.slice('/hf/'.length);
      const target = new URL(relative, HF_ORIGIN);
      target.search = url.search;
      return streamProxy(request, target.toString());
    }

    if (url.pathname.startsWith(ORT_PREFIX)) {
      const filename = url.pathname.slice(ORT_PREFIX.length);
      const allowed = new Set([
        'ort-wasm-simd-threaded.jsep.mjs',
        'ort-wasm-simd-threaded.jsep.wasm',
      ]);

      if (!allowed.has(filename)) {
        return new Response('Not Found', { status: 404 });
      }

      const target = new URL(filename, ORT_ORIGIN);
      return streamProxy(request, target.toString());
    }

    return env.ASSETS.fetch(request);
  },
};
