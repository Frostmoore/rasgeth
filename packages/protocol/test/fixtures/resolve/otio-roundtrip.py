# Reads every .otio RedGiant wrote (ours/) with OpenTimelineIO and writes it again (ours-rt/).
import glob, os, opentimelineio as otio
for f in sorted(glob.glob("/ref/ours/*.otio")):
    if f.endswith(".rewritten.otio"): continue
    tl = otio.adapters.read_from_file(f)
    out = otio.adapters.write_to_string(tl, "otio_json")
    open("/ref/ours-rt/" + os.path.basename(f), "w").write(out)
    print(os.path.basename(f), "same" if out == open(f).read() else "DIFFERENT", len(tl.tracks), sum(1 for _ in tl.find_clips()))
