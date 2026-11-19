# Writes the test jobs (montatore's fcpxml input) for RedGiant G41.6b's reference XML.
import json, os
J = os.path.join(os.path.dirname(os.path.abspath(__file__)), "jobs")
A2 = {"channels": 2, "sample_rate": 48000}
def clip(m, s, i, d, e=True): return {"media": m, "start": s, "in": i, "dur": d, "enabled": e}
def tr(id, ty, clips, e=True): return {"id": id, "type": ty, "enabled": e, "clips": clips}
def put(name, job): json.dump(job, open(os.path.join(J, name + ".json"), "w"), indent=1, ensure_ascii=False)

put("matrimonio", {"name": "Sposi & amici <2026>", "fps_num": 25, "fps_den": 1, "width": 1920, "height": 1080,
 "media": {
  "10": {"url": "E:\\Montaggi\\Sposi & amici\\Città 01.MOV", "name": "Città 01.MOV", "frames": 1500, "timecode": "10:00:00:00", "width": 1920, "height": 1080, "audio": A2},
  "11": {"url": "E:\\Montaggi\\Sposi & amici\\chiesa (2).mp4", "name": "chiesa (2).mp4", "frames": 750, "timecode": "09:30:15:12", "width": 3840, "height": 2160, "audio": {"channels": 1, "sample_rate": 44100}},
  "12": {"url": "E:\\Montaggi\\Sposi & amici\\Torta è.jpg", "name": "Torta è.jpg", "frames": None, "timecode": None, "width": 4000, "height": 3000, "audio": None}},
 "tracks": [
  tr("V1", "video", [clip(10, 50, 100, 200), clip(11, 250, 0, 125, False), clip(10, 375, 700, 300)]),
  tr("V2", "video", [clip(12, 100, 33, 75)]),
  tr("V3", "video", []),
  tr("A1", "audio", [clip(10, 50, 100, 200), clip(11, 250, 0, 125), clip(10, 375, 700, 300)]),
  tr("A2", "audio", [clip(11, 0, 10, 40)], False)]})

put("ntsc59", {"name": "Prova \"59,94\" è", "fps_num": 60000, "fps_den": 1001, "width": 3840, "height": 2160,
 "media": {
  "a": {"url": "/srv/riprese/scena #1 50%?.mp4", "name": "scena #1 50%?.mp4", "frames": 3000, "timecode": "00:59:59;28", "width": 3840, "height": 2160, "audio": {"channels": 1, "sample_rate": 44100}},
  "b": {"url": "\\\\nas\\video\\Ripresa é ü.mov", "name": "Ripresa é ü.mov", "frames": 900, "timecode": "12:12:33.23", "width": 1280, "height": 720, "audio": A2},
  "c": {"url": "file:///già/così.mp4", "name": "così.mp4", "frames": 600, "timecode": "1:02:03:04", "width": 0, "height": 0, "audio": A2}},
 "tracks": [
  tr("V1", "video", [clip("a", 0, 0, 600), clip("b", 600, 120, 300), clip("c", 900, 5, 10)]),
  tr("V2", "video", [clip("a", 100, 0, 600)]),
  tr("A1", "audio", [clip("a", 0, 0, 600), clip("b", 600, 120, 300), clip("c", 900, 5, 10)]),
  tr("A2", "audio", [clip("a", 100, 0, 600, False)])]})

put("film24", {"name": "Film", "fps_num": 24000, "fps_den": 1001, "width": 4096, "height": 1716,
 "media": {
  "1": {"url": "D:/Film/rulli/R01.mov", "name": "R01.mov", "frames": 20000, "timecode": "01:00:00:00", "width": 4096, "height": 1716, "audio": A2},
  "2": {"url": "D:/Film/rulli/R02.mov", "name": "R02.mov", "frames": 20000, "timecode": "00:00:00:29", "width": 4096, "height": 1716, "audio": A2},
  "3": {"url": "D:/Film/rulli/R03.mov", "name": "R03.mov", "frames": 20000, "timecode": "12:12:33;23", "width": 4096, "height": 1716, "audio": None}},
 "tracks": [
  tr("V1", "video", [clip("1", 0, 1000, 2400), clip("2", 2400, 0, 100), clip("3", 2600, 19000, 999)]),
  tr("A1", "audio", [clip("1", 0, 1000, 2400), clip("2", 2400, 0, 100)])]})

put("vuota", {"name": "Vuota", "fps_num": 30, "fps_den": 1, "width": 1280, "height": 720, "media": {},
 "tracks": [tr("V1", "video", []), tr("A1", "audio", [])]})

put("audio-lunga", {"name": "Solo suono", "fps_num": 50, "fps_den": 1, "width": 1080, "height": 1920,
 "media": {"v": {"url": "/data/v.mp4", "name": "v.mp4", "frames": 500, "timecode": None, "width": 1080, "height": 1920, "audio": A2}},
 "tracks": [tr("V1", "video", [clip("v", 0, 0, 100)]), tr("A1", "audio", [clip("v", 0, 0, 100)]),
            tr("A2", "audio", [clip("v", 200, 0, 500)], False)]})

put("rate12", {"name": "Dodici", "fps_num": 12, "fps_den": 1, "width": 640, "height": 480,
 "media": {"v": {"url": "/data/stop motion.mp4", "name": "stop motion.mp4", "frames": 240, "timecode": "00:00:10:00", "width": 640, "height": 480, "audio": None}},
 "tracks": [tr("V1", "video", [clip("v", 12, 24, 48)]), tr("A1", "audio", [])]})

put("ripetute", {"name": "Ripetute", "fps_num": 30000, "fps_den": 1001, "width": 1920, "height": 1080,
 "media": {"x": {"url": "C:\\Users\\Pixel\\Videos\\x.mp4", "name": "x.mp4", "frames": 900, "timecode": "00:10:00;00", "width": 1920, "height": 1080, "audio": A2},
           "f": {"url": "C:\\Users\\Pixel\\Pictures\\f.png", "name": "f.png", "frames": None, "timecode": None, "width": 800, "height": 800, "audio": None}},
 "tracks": [tr("V1", "video", [clip("x", 0, 0, 30), clip("x", 30, 0, 30), clip("x", 60, 0, 30), clip("f", 90, 500, 30), clip("f", 120, 0, 30)]),
            tr("V2", "video", [clip("x", 0, 0, 30)]),
            tr("A1", "audio", [clip("x", 0, 0, 30), clip("x", 30, 0, 30), clip("x", 60, 0, 30)]),
            tr("A2", "audio", [clip("x", 0, 0, 30)]), tr("A3", "audio", [clip("x", 0, 0, 30, False)])]})
