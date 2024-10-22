import * as cp from 'node:child_process';
import * as process from 'node:process';
import * as path from 'node:path';
import * as fs from 'node:fs';
import * as zlib from 'node:zlib';
import { fileURLToPath } from 'node:url';

const dirname = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const orig = path.resolve(dirname, 'lib', 'binding', 'emscripten-wasm32', 'proj.wasm.orig');
const main = path.resolve(dirname, 'lib', 'binding', 'emscripten-wasm32', 'proj.wasm');
const secondary = path.resolve(dirname, 'lib', 'binding', 'emscripten-wasm32', 'proj.deferred.wasm');
const backup = path.resolve(dirname, 'lib', 'binding', 'emscripten-wasm32', 'proj.wasm.backup');

if (!fs.existsSync(orig)) {
  console.log(`orig file ${orig} not found`);
  process.exit(1);
}
if (!fs.existsSync(backup)) {
  fs.copyFileSync(main, backup);
  console.log(`creating a backup copy ${backup} from ${main}`);
} else {
  fs.copyFileSync(backup, main);
  console.log(`restoring backup copy ${main} from ${backup}`);
}

import qPROJ from '../wasm/index.mjs';

const PROJ = await qPROJ;

const proj_db_path = path.resolve(dirname, 'lib', 'binding', 'proj', 'proj.db');
const proj_db = fs.readFileSync(proj_db_path);
if (!PROJ.proj_js_inline_projdb)
  PROJ.loadDatabase(proj_db);

fs.rmSync('profile.data', { force: true });
const program = process.argv[2] ?? path.resolve(path.dirname(fileURLToPath(import.meta.url)), 'split-quickstart.js');
console.log(`Splitting WASM using ${program}`);
await import(program);
PROJ.swig_em_write_profile();

const split = process.env['EMSDK'] ? path.resolve(process.env['EMSDK'], 'upstream', 'bin', 'wasm-split') : 'wasm-split';
const splitCommand = `${split} --enable-threads --enable-bulk-memory --enable-mutable-globals --export-prefix=% ${orig} -o1 ${main} -o2 ${secondary} --profile=profile.data`;
console.log('running', splitCommand);
try {
  cp.execSync(splitCommand);
} catch {
  process.exit(1);
}

const origRaw = fs.readFileSync(orig);
const origCompressed = zlib.brotliCompressSync(origRaw, { level: 9 });
const mainRaw = fs.readFileSync(main);
const mainCompressed = zlib.brotliCompressSync(mainRaw, { level: 9 });
const secondaryRaw = fs.readFileSync(secondary);
const secondaryCompressed = zlib.brotliCompressSync(secondaryRaw, { level: 9 });

console.log(`::notice::Original module before splitting: ${Math.ceil(origRaw.length / 1024)} KiBytes, compressed: ${Math.ceil(origCompressed.length / 1024) } KiBytes`);
console.log(`::notice::Main module after splitting: ${Math.ceil(mainRaw.length / 1024)} KiBytes, compressed: ${Math.ceil(mainCompressed.length / 1024)} KiBytes`);
console.log(`::notice::Deferred module after splitting: ${Math.ceil(secondaryRaw.length / 1024)} KiBytes, compressed: ${Math.ceil(secondaryCompressed.length / 1024)} KiBytes`);
