# Environment tests

These can also be used as configuration examples for the different supported environments.

## Browser

Test runs:
```shell
npm install
npm link proj.js --ignore-scripts
npm run build
# Then loads index in Chrome via karma with COOP/COEP enabled
```

* `browser-webpack-esm` browser, webpack, ES6 modules, `"type": "module"`
* `browser-webpack-ts-esm` browser, webpack, TypeScript transpiled to ES6, `"type": "module"`
* `browser-rollup-esm` browser, rollup, ES6 modules, `"type": "module"`
* `browser-vite-esm` browser, vite, ES6 modules, `"type": "module"`
* `browser-vite-ts` browser, vite, TypeScript transpiled to ES6, `"type": "module"`
* `browser-react-ts` browser, React, create-react-app, TypeScript transpiled to CJS

# Node.js

Test runs:
```shell
npm install
npm link proj.js --ignore-scripts
npm test
```

* `node-esm` Node.js, ES6 modules, `"type": "module"`
* `node-ts-esm` Node.js, TypeScript transpiled to ES6, `"type": "module"`
* `node-native-sync` Node.js, ES6 modules, direct synchronous import of the native module, `"type": "module"`

Also, if using Node.js 20 + TypeScript + ES6 modules, you should be aware of https://github.com/TypeStrong/ts-node/issues/1997. Personally, I recommend switching to `tsx` and using `eslint` or `tsc` to type-check.
