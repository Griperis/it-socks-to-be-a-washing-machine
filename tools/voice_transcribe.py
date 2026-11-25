#!/usr/bin/env python3
"""The voice bake's transcription step (core/84): one wav in, its segments out as one JSON line on stdout,
{"segments": [{"start": s, "end": s, "text": "..."}]}.

    python3 tools/voice_transcribe.py assets/voice/washer/my_line.wav

faster-whisper with the `small.en` model, on the CPU, as the old game's tools/voiceover/voiceover.py: offline
once the model is downloaded (into extras/models/; faster-whisper may live in extras/pylib/). Without it the
script prints why on stderr and exits 3; the bake then gives a new line the text TODO.
"""
import array
import json
import os
import sys
import wave

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
MODEL_NAME = "small.en"


def read_mono(path):
    """(samples as floats -1..1, rate) of a PCM wav."""
    with wave.open(path, "rb") as w:
        ch, width, rate, n = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
        raw = w.readframes(n)
    if width == 2:
        a = array.array("h")
        a.frombytes(raw)
        if sys.byteorder == "big":
            a.byteswap()
        vals = [x / 32768.0 for x in a]
    elif width == 1:
        vals = [(x - 128) / 128.0 for x in raw]
    elif width == 3:
        vals = [int.from_bytes(raw[i:i + 3], "little", signed=True) / 8388608.0 for i in range(0, len(raw) - 2, 3)]
    elif width == 4:
        a = array.array("i")
        a.frombytes(raw)
        vals = [x / 2147483648.0 for x in a]
    else:
        raise ValueError("unsupported sample width %d" % width)
    if ch > 1:
        vals = [sum(vals[i:i + ch]) / ch for i in range(0, len(vals) - ch + 1, ch)]
    return vals, rate


def main(argv):
    if len(argv) != 1:
        print(__doc__, file=sys.stderr)
        return 2
    pylib = os.path.join(ROOT, "extras", "pylib")
    if os.path.isdir(pylib):
        sys.path.insert(0, pylib)
    try:
        import numpy as np
        from faster_whisper import WhisperModel
    except Exception as e:  # noqa: BLE001
        print("no faster-whisper (%s: %s)" % (type(e).__name__, str(e).splitlines()[0][:200] if str(e) else ""),
              file=sys.stderr)
        return 3
    try:
        cache = os.path.join(ROOT, "extras", "models")
        os.makedirs(cache, exist_ok=True)
        model = WhisperModel(MODEL_NAME, device="cpu", compute_type="int8", download_root=cache)
        # Our own wav reader: faster-whisper's PyAV decoder breaks on new av versions (the old game's note).
        vals, rate = read_mono(argv[0])
        audio = np.asarray(vals, dtype=np.float32)
        if rate != 16000:
            n = int(len(audio) * 16000 / rate)
            audio = np.interp(np.linspace(0, len(audio) - 1, n), np.arange(len(audio)), audio).astype(np.float32)
        segs, _ = model.transcribe(audio, language="en")
        out = [{"start": round(s.start, 2), "end": round(s.end, 2), "text": s.text.strip()} for s in segs]
    except Exception as e:  # noqa: BLE001
        msg = str(e).strip().splitlines()
        print("transcription failed (%s: %s)" % (type(e).__name__, msg[0][:200] if msg else ""), file=sys.stderr)
        return 3
    print(json.dumps({"segments": out}))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
