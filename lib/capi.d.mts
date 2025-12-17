import type * as PROJ from '../swig/proj_capi.d.ts';
export type * from '../swig/proj_capi.d.ts';

/*
 * Embedded file system access, available only in WASM
 */
declare type FSMode = 'r' | 'r+' | 'w' | 'wx' | 'w+' | 'wx+' | 'a' | 'ax' | 'a+' | 'ax+';

declare module '../swig/proj_capi.d.ts' {
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

  interface PROJ_UNIT_INFO_CONTAINER {
    [Symbol.iterator](): Iterator<PROJ_UNIT_INFO & { readonly parent: PROJ_UNIT_INFO_CONTAINER }>;
  }
  interface PROJ_CELESTIAL_BODY_INFO_CONTAINER {
    [Symbol.iterator](): Iterator<PROJ_CELESTIAL_BODY_INFO & { readonly parent: PROJ_CELESTIAL_BODY_INFO_CONTAINER; }>;
  }
  interface PROJ_CRS_INFO_CONTAINER {
    [Symbol.iterator](): Iterator<PROJ_CRS_INFO & { readonly parent: PROJ_CRS_INFO_CONTAINER; }>;
  }

  interface PJ_OBJ_LIST {
    [Symbol.iterator](): Iterator<PJ & { readonly parent: PJ; }>;
    get(i: number): PJ & { readonly parent: PJ; };
  }
}

declare const bindings: Promise<typeof PROJ>;
export default bindings;
