import { assert } from 'chai';
import qPROJ from 'proj.js/capi';

qPROJ.then((PROJ) => {
  console.time('proj_create_crs_to_crs');
  const P = PROJ.proj_create_crs_to_crs(
    'EPSG:4326', '+proj=utm +zone=32 +datum=WGS84');
  console.timeEnd('proj_create_crs_to_crs');
  console.trace(P.toString());
  assert.instanceOf(P, PROJ.PJ);

  console.time('proj_normalize_for_visualization');
  const norm = PROJ.proj_normalize_for_visualization(P);
  console.timeEnd('proj_normalize_for_visualization');
  console.trace(norm.toString());
  assert.instanceOf(norm, PROJ.PJ);

  console.time('proj_coord');
  const a = PROJ.proj_coord(12, 55, 0, 0);
  console.timeEnd('proj_coord');
  assert.instanceOf(a, PROJ.PJ_COORD);

  console.time('proj_trans');
  const b = PROJ.proj_trans(P, PROJ.PJ_FWD, a);
  console.timeEnd('proj_trans');
  console.trace(`easting: ${b.enu.e}, northing: ${b.enu.n}`);
  assert.instanceOf(b, PROJ.PJ_COORD);

  console.time('proj_trans');
  const c = PROJ.proj_trans(P, PROJ.PJ_INV, b);
  console.timeEnd('proj_trans');
  console.trace(`longitude: ${c.lp.lam}, latitude: ${c.lp.phi}`);
  assert.instanceOf(c, PROJ.PJ_COORD);

  assert.closeTo(c.lp.lam, 12, 1e-5);
  assert.closeTo(c.lp.phi, 55, 1e-5);
});
