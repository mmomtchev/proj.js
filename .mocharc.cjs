module.exports = {
  'spec': [
    'test/node/*.test.[tj]s',
    'test/shared/*.test.[tj]s'
  ],
  'node-option': [
    'no-warnings',
    'loader=ts-node/esm',
    'expose-gc'
  ],
  'timeout': 20000,
  'repeats': 100,
  'v8-expose-gc': true,
  'extensions': [
    'ts'
  ],
  'require': [
    'ts-node/register',
    'test/node/wasm.node_js.proj_db.ts'
  ]
};
