"""Render and verify Pigeon Tower's deterministic one-shot audio bank."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import platform
import struct
import subprocess
from concurrent.futures import ThreadPoolExecutor
import sys
import wave

import numpy as np
import scipy

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools" / "procedural_sfx"))
import recipes
import sfxkit as kit


def fit(signal, frames):
    return np.pad(signal[:frames], (0, max(0, frames - len(signal))))


def synthesize(spec):
    kit.reseed(spec["seed"])
    frames = kit.n_(spec["seconds"])
    out = np.zeros(frames)
    for layer in spec["layers"]:
        at = kit.n_(layer.get("at", 0))
        render = getattr(recipes, layer["recipe"])
        signal = render(**layer.get("args", {}))
        pitch = layer.get("pitch", 1.0)
        if pitch != 1.0:
            samples = np.arange(0, len(signal), pitch)
            signal = np.interp(samples, np.arange(len(signal)), signal)
        seconds = layer.get("seconds")
        if seconds is not None:
            signal = fit(signal, kit.n_(seconds))
        if "band" in layer:
            signal = kit.bp(signal, *layer["band"])
        if "decay" in layer:
            signal *= np.exp(-np.arange(len(signal)) / kit.SR / layer["decay"])
        signal = kit.norm(signal)
        length = min(len(signal), frames - at)
        signal = signal[:length].copy()
        if length < 2:
            raise ValueError(f"Layer has no room in {spec['id']}: {layer}")
        edge = min(kit.n_(.002), length // 2)
        signal[:edge] *= np.linspace(0, 1, edge) ** 2
        tail = min(kit.n_(.012), length // 2)
        signal[-tail:] *= np.linspace(1, 0, tail) ** 2
        out[at:at + length] += signal * layer.get("gain", 1.0)
    out = kit.hp(out, 28)
    edge = min(kit.n_(.018), frames // 4)
    out[-edge:] *= np.cos(np.linspace(0, np.pi / 2, edge)) ** 2
    if not np.isfinite(out).all() or not np.any(out):
        raise ValueError(f"Invalid signal: {spec['id']}")
    return kit.norm(out, 10 ** (spec["peak_dbtp"] / 20) * np.max(np.abs(out)) / np.max(kit.true_peak(out)))


def measure(path, expected_frames, ceiling):
    with wave.open(str(path), "rb") as file:
        signature = file.getnchannels(), file.getsampwidth(), file.getframerate(), file.getnframes()
        if signature != (1, 2, kit.SR, expected_frames):
            raise ValueError(f"Unexpected WAV format or duration: {path}: {signature}")
        pcm = np.frombuffer(file.readframes(expected_frames), dtype="<i2")
    if np.any((pcm == 32767) | (pcm == -32768)) or pcm[0] or pcm[-1]:
        raise ValueError(f"Clipping or nonzero endpoints: {path}")
    signal = pcm.astype(float) / 32768
    peak = np.max(np.abs(signal))
    true_peak = float(kit.true_peak_db(signal))
    if not np.isfinite(true_peak) or true_peak > ceiling + .04:
        raise ValueError(f"True peak {true_peak:.2f} exceeds {ceiling}: {path}")
    spectrum = np.abs(np.fft.rfft(signal)) ** 2
    active = np.flatnonzero(np.abs(signal) >= peak * .10)
    return {
        "frames": len(signal),
        "seconds": len(signal) / kit.SR,
        "sample_peak_dbfs": round(20 * math.log10(peak), 2),
        "true_peak_dbtp": round(true_peak, 2),
        "pcm_rail_samples": 0,
        "rms_dbfs": round(10 * math.log10(np.mean(signal ** 2)), 2),
        "centroid_hz": round(float(np.average(np.fft.rfftfreq(len(signal), 1 / kit.SR), weights=spectrum))),
        "attack_ms": round(1000 * int(np.argmax(np.abs(signal))) / kit.SR, 2),
        "last_above_minus20_ms": round(1000 * int(active[-1]) / kit.SR, 2),
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }


def render_bank(manifest, output, verify_only=False):
    output.mkdir(parents=True, exist_ok=True)
    measurements = {}
    for spec in manifest["sounds"]:
        path = output / (spec["id"] + ".wav")
        if not verify_only:
            pcm = np.rint(synthesize(spec) * 32767).astype("<i2")
            with wave.open(str(path), "wb") as file:
                file.setparams((1, 2, kit.SR, len(pcm), "NONE", "not compressed"))
                file.writeframes(pcm.tobytes())
        measurements[spec["id"]] = measure(path, kit.n_(spec["seconds"]), spec["peak_dbtp"])
    return measurements


def pack_bank(output, specs, bank_path, metrics):
    """Pack small Vorbis streams together, with a byte index for lazy playback."""
    def encode(spec):
        wav = output / (spec["id"] + ".wav")
        encoded = subprocess.run(
            ["ffmpeg", "-v", "error", "-i", str(wav), "-c:a", "libvorbis",
             "-q:a", "4", "-fflags", "+bitexact", "-flags:a", "+bitexact", "-f", "ogg", "-"],
            capture_output=True, check=True,
        ).stdout
        decoded = subprocess.run(
            ["ffmpeg", "-v", "error", "-f", "ogg", "-i", "-", "-f", "f32le", "-"],
            input=encoded, capture_output=True, check=True,
        ).stdout
        audio = np.frombuffer(decoded, dtype="<f4")
        # The last Ogg page granule is the exact PCM length. Pipe decoders can
        # return the entire final Vorbis block, including encoder padding.
        last_page = encoded.rfind(b"OggS")
        if last_page < 0:
            raise ValueError(f"Invalid Vorbis stream: {spec['id']}")
        granule = struct.unpack_from("<Q", encoded, last_page + 6)[0]
        if granule != kit.n_(spec["seconds"]) or not np.isfinite(audio).all() or not len(audio):
            raise ValueError(f"Invalid decoded stream duration: {spec['id']}")
        peak = float(kit.true_peak_db(audio))
        if not -40 < peak < -1 or np.abs(audio).max() >= 1:
            raise ValueError(f"Invalid decoded true peak ({peak:.2f}): {spec['id']}")
        return encoded, round(peak, 2)

    index = {}
    payload = bytearray()
    with ThreadPoolExecutor(max_workers=6) as pool:
        for spec, (data, peak) in zip(specs, pool.map(encode, specs), strict=True):
            index[spec["id"]] = [len(payload), len(data)]
            payload.extend(data)
            metrics[spec["id"]]["vorbis_true_peak_dbtp"] = peak
    encoded_index = json.dumps(index, separators=(",", ":")).encode()
    bank_path.write_bytes(struct.pack("<I", len(encoded_index)) + encoded_index + payload)
    return hashlib.sha256(bank_path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--report", type=Path, default=Path("short-sfx-verification.json"))
    parser.add_argument("--verify-only", action="store_true")
    parser.add_argument("--bank", type=Path, help="Also encode and verify the Godot Vorbis bank")
    args = parser.parse_args()
    manifest = json.loads((ROOT / "tools" / "short_sfx.json").read_text())
    metrics = render_bank(manifest, args.output, args.verify_only)
    report = {
        "python": platform.python_version(),
        "numpy": np.__version__,
        "scipy": scipy.__version__,
        "sample_rate": kit.SR,
        "pcm_bits": 16,
        "channels": 1,
        "sounds": metrics,
    }
    if args.bank:
        report["bank_sha256"] = pack_bank(args.output, manifest["sounds"], args.bank, metrics)
    args.report.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Verified {len(metrics)} WAV files, zero clipped samples, maximum {max(s['true_peak_dbtp'] for s in metrics.values()):.2f} dBTP")


if __name__ == "__main__":
    main()
