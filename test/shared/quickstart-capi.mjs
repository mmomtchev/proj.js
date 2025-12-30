import { assert } from 'chai';

export default async function (PROJ) {
  const P = PROJ.proj_create_crs_to_crs(
    'EPSG:4326', '+proj=utm +zone=32 +datum=WGS84');
  assert.instanceOf(P, PROJ.PJ);

  const norm = PROJ.proj_normalize_for_visualization(P);
  assert.instanceOf(norm, PROJ.PJ);

  const a = PROJ.proj_coord(12, 55, 0, 0);
  assert.instanceOf(a, PROJ.PJ_COORD);

  const b = PROJ.proj_trans(P, PROJ.PJ_FWD, a);
  assert.instanceOf(b, PROJ.PJ_COORD);

  const c = PROJ.proj_trans(P, PROJ.PJ_INV, b);
  assert.instanceOf(c, PROJ.PJ_COORD);

  assert.closeTo(c.lp.lam, 12, 1e-5);
  assert.closeTo(c.lp.phi, 55, 1e-5);
}
