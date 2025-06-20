// https://github.com/DefinitelyTyped/DefinitelyTyped/discussions/72133
// This is a flaw in the chai typings

import { assert } from 'chai';

export function assertInstanceOf<T = unknown>(
  value: T,
  constructor: Function & { prototype: T; },
  message?: string
): asserts value is T {
  return assert.instanceOf(value, constructor as Chai.Constructor<T>, message);
}
