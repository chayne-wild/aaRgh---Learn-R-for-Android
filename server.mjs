import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.PORT || 3000);
const HOST = '0.0.0.0';
const BUNDLE_ROOT = path.join(__dirname, 'app', 'src', 'main', 'assets', 'aargh_bundle');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.metadata': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.tar': 'application/x-tar',
  '.rds': 'application/octet-stream',
  '.gz': 'application/octet-stream',
  '.so': 'application/octet-stream',
  '.r': 'text/plain; charset=utf-8',
  '.txt': 'text/plain; charset=utf-8',
  '.csv': 'text/csv; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf'
};

function resolveAssetPath(urlPath) {
  const cleanPath = decodeURIComponent(urlPath.split('?')[0]);
  const relPath = cleanPath === '/' ? 'index.html' : cleanPath.replace(/^\/+/, '');
  const candidateBundle = path.join(BUNDLE_ROOT, relPath);
  if (candidateBundle.startsWith(BUNDLE_ROOT) && fs.existsSync(candidateBundle) && fs.statSync(candidateBundle).isFile()) {
    return candidateBundle;
  }
  const candidateRoot = path.join(__dirname, relPath);
  if (candidateRoot.startsWith(__dirname) && fs.existsSync(candidateRoot) && fs.statSync(candidateRoot).isFile()) {
    return candidateRoot;
  }
  return null;
}

const server = http.createServer((req, res) => {
  // Attach COOP/COEP headers on every response to enable SharedArrayBuffer (Atomics.wait)
  res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
  res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
  res.setHeader('Cross-Origin-Resource-Policy', 'same-origin');

  const filePath = resolveAssetPath(req.url || '/');
  if (!filePath) {
    res.statusCode = 404;
    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    res.end('Not found');
    return;
  }

  const ext = path.extname(filePath).toLowerCase();
  res.statusCode = 200;
  res.setHeader('Content-Type', MIME_TYPES[ext] || 'application/octet-stream');
  fs.createReadStream(filePath).pipe(res);
});

server.listen(PORT, HOST, () => {
  console.log(`aaRgh offline R asset server listening on http://${HOST}:${PORT}`);
});
