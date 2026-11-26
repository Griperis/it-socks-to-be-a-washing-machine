#!/usr/bin/env python3
"""Writes the Wardrobe's piece files (core/128) once from the old game's data: one
game/wardrobe/pieces/<id>.tres per piece, from data/tuning/wardrobe.json (the ten basic pieces) and
data/tuning/gifts.json "pieces" (six per Collection), with the old avatar.json swish_rate.

    python3 tools/wardrobe_pieces_from_old.py [--reference <old game checkout>]

A hat, clothes or Socks piece points at its Looks game/wardrobe/looks/<id>.tscn (assets/18, 19) and a Trail at
its scene game/wardrobe/trails/<id>.tscn (core/144). The ten basic pieces are owned from the start (Q2679). Values the editor would not
write (the defaults) are left out; uids are left to the editor (path-only references).
Python 3 standard library only. Kept so the files can be written again; after that they are the designer's.
"""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "game" / "wardrobe" / "pieces"
SLOTS = {"hat": 0, "clothes": 1, "socks": 2, "trail": 3}
RARITY = {"common": 0, "uncommon": 1, "rare": 2}
NAMES = {"beanie": "Beanie", "cap": "Cap", "top_hat": "Top hat", "party_hat": "Party hat",
		"bobble_hat": "Bobble hat", "crown": "Crown", "scarf": "Scarf", "apron": "Apron",
		"bow_tie": "Bow tie", "jumper": "Jumper"}
TRAILS = "res://game/wardrobe/trails/"


def looks_of(pid: str, slot: str) -> str:
	if slot in ("hat", "clothes", "socks"):
		path = ROOT / "game" / "wardrobe" / "looks" / (pid + ".tscn")
		if not path.exists():
			raise SystemExit("no Looks for %s at %s" % (pid, path))
		return "res://game/wardrobe/looks/%s.tscn" % pid
	own = ROOT / "game" / "wardrobe" / "trails" / (pid + ".tscn")
	if not own.exists():
		raise SystemExit("no Trail scene for %s at %s" % (pid, own))
	return TRAILS + pid + ".tscn"


def write(pid: str, piece: dict) -> None:
	lines = ['[gd_resource type="Resource" script_class="WardrobePiece" format=3]', "",
			'[ext_resource type="Script" path="res://game/wardrobe/wardrobe_piece.gd" id="1_piece"]',
			'[ext_resource type="PackedScene" path="%s" id="2_looks"]' % piece["looks"], "",
			"[resource]", 'script = ExtResource("1_piece")', 'name = "%s"' % piece["name"]]
	if piece["slot"]:
		lines.append("slot = %d" % piece["slot"])
	if piece["collection"]:
		lines.append('collection = &"%s"' % piece["collection"])
	if piece["rarity"]:
		lines.append("rarity = %d" % piece["rarity"])
	if piece["order"]:
		lines.append("order = %d" % piece["order"])
	lines.append('looks = ExtResource("2_looks")')
	if piece["swish_rate"] != 1:
		lines.append("swish_rate = %d" % piece["swish_rate"])
	if piece["owned_from_start"]:
		lines.append("owned_from_start = true")
	(OUT / (pid + ".tres")).write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def main() -> None:
	ap = argparse.ArgumentParser()
	ap.add_argument("--reference", default=str(ROOT / "reference" / "it-socks"))
	ref = Path(ap.parse_args().reference) / "data" / "tuning"
	wardrobe = json.loads((ref / "wardrobe.json").read_text(encoding="utf-8"))
	gifts = json.loads((ref / "gifts.json").read_text(encoding="utf-8"))
	rates = json.loads((ref / "avatar.json").read_text(encoding="utf-8")).get("swish_rate", {})
	OUT.mkdir(parents=True, exist_ok=True)
	pieces = {}
	for slot in ("hats", "clothes"):
		for i, pid in enumerate(wardrobe[slot]):
			s = "hat" if slot == "hats" else "clothes"
			pieces[pid] = {"name": NAMES.get(pid, pid.replace("_", " ").capitalize()), "slot": SLOTS[s],
					"collection": "", "rarity": 0, "order": i, "looks": looks_of(pid, s), "owned_from_start": True}
	for collection, row in gifts["pieces"].items():
		for i, p in enumerate(row):
			pieces[p["id"]] = {"name": p.get("name", p["id"].replace("_", " ").capitalize()),
					"slot": SLOTS[p["slot"]], "collection": collection,
					"rarity": RARITY[p.get("rarity", "common")], "order": i,
					"looks": looks_of(p["id"], p["slot"]), "owned_from_start": False}
	for pid, piece in pieces.items():
		piece["swish_rate"] = max(1, int(rates.get(pid, 1)))
		write(pid, piece)
	print("wardrobe_pieces_from_old: %d pieces written to %s" % (len(pieces), OUT.relative_to(ROOT)))


if __name__ == "__main__":
	main()
