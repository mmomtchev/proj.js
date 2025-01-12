import type * as PROJ from '../swig/proj.d.ts';
export type * from '../swig/proj.d.ts';

/*
 * Embedded file system access, available only in WASM
 */
declare type FSMode = 'r' | 'r+' | 'w' | 'wx' | 'w+' | 'wx+' | 'a' | 'ax' | 'a+' | 'ax+';

declare module '../swig/proj.d.ts' {
  namespace FS {
    function open(path: string, mode?: FSMode): unknown;
    function close(file: unknown): void;
    function read(file: unknown, buffer: ArrayBufferView, offset: number, length: number, position?: number): void;
    function write(file: unknown, buffer: ArrayBufferView, offset: number, length: number, position?: number): void;
    function readFile(path: string, opts: { encoding?: 'binary', flags?: string; }): Uint8Array;
    function readFile(path: string, opts: { encoding: 'utf8', flags?: string; }): string;
    function writeFile(path: string, data: ArrayBufferView, opts: { encoding?: 'binary', flags?: FSMode; }): void;
    function writeFile(path: string, data: string, opts: { encoding: 'utf8', flags?: FSMode; }): void;
    function readdir(path: string): string[];
  }

  function loadDatabase(db: Uint8Array): void;
}

declare const bindings: Promise<typeof PROJ>;
export default bindings;
