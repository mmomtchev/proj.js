import * as fs from 'node:fs';
import * as path from 'node:path';
import { fileURLToPath } from 'node:url';

// This loads proj.db into the environment (in globalThis)
// to be used in case proj.db hasn't been inlined

const proj_db_path = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', 'lib', 'binding', 'proj', 'proj.db');
const proj_db_data = fs.promises.readFile(proj_db_path);
// @ts-ignore
globalThis.proj_db = proj_db_data;
