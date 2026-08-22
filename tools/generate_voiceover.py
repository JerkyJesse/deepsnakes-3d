"""Generate timed DeepSnakes 3D trailer voiceover clips (edge-tts)."""
from __future__ import annotations

import asyncio
from pathlib import Path

import edge_tts

VOICE = "en-US-GuyNeural"
RATE = "-8%"
PITCH = "-4Hz"

# start_ms matches tools/trailer_director.gd beat sheet
LINES: list[tuple[int, str]] = [
	(600, "Deep Snakes."),
	(2400, "You are the snake."),
	(8500, "Forest floor. First person. Mouse steers. Eat to grow. Do not hit yourself."),
	(28500, "Desert wash. Sidewinder. Boost until the sand blurs."),
	(48500, "Blackwater swamp. Cottonmouth. Strike through the fog."),
	(68500, "Red canyon. Hit another snake, and the longer body wins."),
	(88500, "Host a listen server. Friends join your LAN. Port seventy-seven seventy-seven."),
	(108500, "Four species. Four biomes. Deep Snakes."),
]


async def main() -> None:
	root = Path(__file__).resolve().parent.parent
	out = root / "export" / "trailer" / "vo"
	out.mkdir(parents=True, exist_ok=True)
	manifest = out / "clips.txt"
	lines: list[str] = []
	for i, (start_ms, text) in enumerate(LINES):
		path = out / f"line_{i:02d}.mp3"
		print(f"{start_ms:6d} ms  {text}")
		comm = edge_tts.Communicate(text, VOICE, rate=RATE, pitch=PITCH)
		await comm.save(str(path))
		lines.append(f"{start_ms}\t{path.name}\t{text}")
	manifest.write_text("\n".join(lines) + "\n", encoding="utf-8")
	print(f"wrote {len(LINES)} clips to {out}")


if __name__ == "__main__":
	asyncio.run(main())
