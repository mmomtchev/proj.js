import qPROJ from 'proj.js/capi';

const PROJ = await qPROJ;

const P = PROJ.proj_create_crs_to_crs(
  "EPSG:4326", "+proj=utm +zone=32 +datum=WGS84",
  null);
console.log(P.toString());

const norm = PROJ.proj_normalize_for_visualization(P);
console.log(norm.toString());

const a = PROJ.proj_coord(12, 55, 0, 0);
const b = PROJ.proj_trans(P, PROJ.PJ_FWD, a);
console.log(`easting: ${b.enu.e}, northing: ${b.enu.n}`);
const c = PROJ.proj_trans(P, PROJ.PJ_INV, b);
console.log(`longitude: ${c.lp.lam}, latitude: ${c.lp.phi}`);
