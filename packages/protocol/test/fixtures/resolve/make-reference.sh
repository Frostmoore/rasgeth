#!/bin/sh
# Reference XML for RedGiant G41.6b: runs a COPY of montatore's engine (engine/) in a throwaway
# container of the image montatore-dev (OpenTimelineIO 0.18.1, otio-fcp-adapter 1.0.0, Python 3.13).
# Every jobs/<name>.json becomes out/<name>.xml. Never touches montatore itself.
R=/mnt/archive1/officina-dati/rg-test/montatore-ref
docker run --rm --entrypoint sh -v $R:/ref -w /ref/engine montatore-dev -c '
for j in /ref/jobs/*.json; do
  n=$(basename $j .json)
  /opt/venv/bin/python - "$j" "$n" <<PY
import json, sys
from montatore_engine.fcpxml import fcpxml
job = json.load(open(sys.argv[1]))
job["out"] = "/ref/out/" + sys.argv[2] + ".xml"
print(sys.argv[2], fcpxml(job))
import opentimelineio as otio
from montatore_engine.fcpxml import build
otio.adapters.write_to_file(build(job), "/ref/out/" + sys.argv[2] + ".otio")
PY
done'
