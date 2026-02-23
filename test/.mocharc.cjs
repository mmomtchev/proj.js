module.exports = {
  'spec': [
    'node/*.test.[tj]s',
    'shared/*.test.[tj]s'
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
    'node/wasm.node_js.proj_db.ts'
  ]
};
