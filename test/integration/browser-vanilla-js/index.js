window.proj_js.then(async (PROJ) => {
  if (!PROJ.proj_js_inline_projdb) {
    const proj_db = await fetch('build/assets/proj.db');
    const proj_db_data = new Uint8Array(await proj_db.arrayBuffer());
    PROJ.loadDatabase(proj_db_data);
  }

  const dbContext = PROJ.DatabaseContext.create();
  const authFactory = PROJ.AuthorityFactory.create(dbContext, 'string');
  const coord_op_ctxt = PROJ.CoordinateOperationContext.create(authFactory, null, 0);
  const authFactoryEPSG = PROJ.AuthorityFactory.create(dbContext, 'EPSG');
  const sourceCRS = authFactoryEPSG.createCoordinateReferenceSystem('4326');
  const targetCRS = PROJ.createFromUserInput('+proj=utm +zone=31 +datum=WGS84 +type=crs', dbContext);
  const list = PROJ.CoordinateOperationFactory.create().createOperations(sourceCRS, targetCRS, coord_op_ctxt);

  const transformer = list[0].coordinateTransformer();
  const c0 = new PROJ.PJ_COORD;
  c0.v = [49, 2, 0, 0];
  const c1 = transformer.transform(c0);

  const div = document.createElement('div');
  const text = document.createTextNode(`Translated ${c1.v[0]}:${c1.v[1]}`);
  div.appendChild(text);
  document.getElementsByTagName('body')[0].appendChild(div);
});

if (window.it) {
  it('PROJ is there', () => {
    if (!(window.proj_js instanceof Promise))
      throw new Error('window.proj_js is not registered');
  });
}

