// G42.0: what LibreOffice's threads need, measured in the isolated frame and told to the page.
(() => {
  const r = { isolated: self.crossOriginIsolated === true, sab: false, atomics: false, threads: 0 };
  try {
    const sab = new SharedArrayBuffer(16);
    r.sab = true;
    const a = new Int32Array(sab);
    Atomics.add(a, 0, 2);
    r.atomics = Atomics.load(a, 0) === 2;
  } catch {
    // No SharedArrayBuffer here.
  }
  r.threads = navigator.hardwareConcurrency || 0;
  parent.postMessage({ redgiant: "isolation-probe", result: r }, location.origin);
})();
