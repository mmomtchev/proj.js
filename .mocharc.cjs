module.exports = {
  'spec': process.env.NO_ASYNC ? 'test/*.sync.test.*s' : 'test/*.test.*s',
  'node-option': [
    'no-warnings',
    'loader=ts-node/esm'
  ],
  'require': [
    'test/wasm.node_js.proj_db.ts'
  ]
};
