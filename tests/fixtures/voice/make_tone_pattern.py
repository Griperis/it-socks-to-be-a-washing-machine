#!/usr/bin/env python3
"""Writes tone_pattern.wav beside this file: the voice bake test's fixture (core/84). 1.6 s of 16-bit mono
PCM at 22050 Hz: silence 0-0.25 s, a 220 Hz tone 0.25-0.6 s, silence, a tone 0.85-1.3 s, silence to the end.

    python3 tests/fixtures/voice/make_tone_pattern.py
"""
import math
import os
import struct
import wave

RATE = 22050
PARTS = [(0.25, 0.0), (0.35, 0.5), (0.25, 0.0), (0.45, 0.5), (0.30, 0.0)]


def main():
    frames = bytearray()
    n = 0
    for seconds, amp in PARTS:
        for _ in range(int(seconds * RATE)):
            frames += struct.pack("<h", int(amp * 32767 * math.sin(2 * math.pi * 220 * n / RATE)))
            n += 1
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tone_pattern.wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(bytes(frames))


if __name__ == "__main__":
    main()
