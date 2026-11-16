"""Fit the selected ElevenLabs recording to the sanctuary's 48.4-second film."""

import argparse
from pathlib import Path
import shutil
import subprocess


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs/reference/music/ritual-of-the-forgotten.mp3"
OUTPUT = ROOT / "assets/game/music/ritual-of-the-forgotten.ogg"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=SOURCE)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    parser.add_argument("--ffmpeg", default=shutil.which("ffmpeg"))
    args = parser.parse_args()
    executable = args.ffmpeg
    if not executable:
        import imageio_ffmpeg

        executable = imageio_ffmpeg.get_ffmpeg_exe()

    # Keep the procession. Replace the repeated middle bars with the final
    # crescendo. Its accents land near 13.12, 14.87, 16.63, 18.38 and 20.25 s.
    opening_end = 13.32
    rise_start = 24.42
    rise_end = 32.8
    rise_overlap = 0.4
    rise_at = opening_end - rise_overlap
    rise_tempo = (31.1 - rise_start) / (20.25 - rise_at)
    rise_length = (rise_end - rise_start) / rise_tempo

    # Sustain the existing post-impact resonance under the dialogue and descent.
    # Pitch stays fixed. A gentle gain ramp offsets the recorded decay before
    # the final fade, so the extended tail remains audible on a phone.
    tail_overlap = 0.6
    tail_at = rise_at + rise_length - tail_overlap
    tail_length = 48.4 - tail_at
    tail_tempo = 6.0 / tail_length
    filters = (
        "[0:a]asplit=3[opening][rise][tail];"
        f"[opening]atrim=0:{opening_end},asetpts=PTS-STARTPTS[a];"
        f"[rise]atrim={rise_start}:{rise_end},asetpts=PTS-STARTPTS,"
        f"rubberband=tempo={rise_tempo}:pitch=1:channels=together,"
        f"apad=whole_dur={rise_length},atrim=duration={rise_length}[b];"
        "[tail]atrim=32.4:38.4,asetpts=PTS-STARTPTS,"
        f"rubberband=tempo={tail_tempo}:pitch=1:transients=smooth:"
        "detector=soft:channels=together,"
        f"apad=whole_dur={tail_length},atrim=duration={tail_length},"
        "volume='pow(10,min(t*0.5,12)/20)':eval=frame,"
        f"afade=t=out:st={tail_length - 1.2}:d=1.2[c];"
        f"[a][b]acrossfade=d={rise_overlap}:c1=tri:c2=tri[ab];"
        f"[ab][c]acrossfade=d={tail_overlap}:c1=tri:c2=tri,"
        "apad=whole_dur=48.4,atrim=duration=48.4[out]"
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.output.with_suffix(".new.ogg")
    subprocess.run(
        [
            executable, "-y", "-v", "error", "-i", str(args.source),
            "-filter_complex", filters, "-map", "[out]", "-map_metadata", "-1",
            "-ar", "44100", "-c:a", "libvorbis", "-q:a", "4", str(temporary),
        ],
        check=True,
    )
    temporary.replace(args.output)
    print(f"Wrote {args.output} ({args.output.stat().st_size:,} bytes)")
    print("Main accent 20.25 s; ending 48.4 s")


if __name__ == "__main__":
    main()
