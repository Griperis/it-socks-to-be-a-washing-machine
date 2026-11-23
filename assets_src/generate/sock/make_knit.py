"""The Sock's knit texture (assets/05, Q2500): one seamless tile of stockinette knit, its normal and
roughness, drawn by the sock shader (game/sock/sock_pattern.gdshader) over every Sock shape.

Headless, from the repository (Blender's own numpy; no scene is touched):

    blender -b -P assets_src/generate/sock/make_knit.py -- [--out assets/sock/knit.png] [--size 256]

The tile is WALES columns of stitches across (around the Sock) by COURSES rows down (along it,
cuff -> toe), so it repeats seamlessly in both directions. Each stitch is a V of two yarn legs, its
point toward the toe (the V reads upright with the cuff at the top of the picture, row 0).
The yarn has a round profile, a twist of plies along each leg and a little fuzz.

Channels (8-bit, linear, no colour space):
  R, G  the surface normal's x and y, * 0.5 + 0.5: x along the picture's columns (around the Sock),
        y along its rows (along the Sock, toward the toe)
  B     roughness: the yarn's crowns a little smoother than the gaps between them
  A     cavity: 1 on the yarn's crowns, darker down in the gaps (the shader darkens the colour by it)
"""

import argparse
import os
import sys

import numpy as np

WALES = 8
COURSES = 8
# The yarn leg: its half thickness, in stitch widths, and how far it reaches past its own row so
# a leg tucks under the stitch above (the interlock).
YARN_RADIUS = 0.24
LEG_OVERLAP = 0.18
# Plies twisted along each leg, and the twist's depth.
PLY_TURNS = 3.0
PLY_DEPTH = 0.12
FUZZ_DEPTH = 0.05
# The normal's strength: the height's slope is multiplied by it before normalising.
BUMP = 2.2
ROUGH_CROWN = 0.82
ROUGH_GAP = 1.0
CAVITY_GAP = 0.45


def tile_noise(size, cells, seed):
	"""Value noise that wraps at the tile's edges: `cells` lattice cells across the tile."""
	rng = np.random.default_rng(seed)
	lattice = rng.random((cells, cells))
	coord = np.arange(size) * cells / size
	i0 = np.floor(coord).astype(int)
	f = coord - i0
	f = f * f * (3.0 - 2.0 * f)
	i1 = (i0 + 1) % cells
	a = lattice[np.ix_(i0, i0)]
	b = lattice[np.ix_(i0, i1)]
	c = lattice[np.ix_(i1, i0)]
	d = lattice[np.ix_(i1, i1)]
	fx = f[np.newaxis, :]
	fy = f[:, np.newaxis]
	return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def knit_height(size):
	"""The knit's height (0 gap .. about 1 crown), one tile of WALES x COURSES stitches."""
	# Stitch space: x in wales, y in courses, both growing with the picture's columns and rows.
	px = (np.arange(size) + 0.5) / size
	x = px[np.newaxis, :] * WALES
	y = px[:, np.newaxis] * COURSES
	x = np.broadcast_to(x, (size, size))
	y = np.broadcast_to(y, (size, size))
	height = np.zeros((size, size))
	# Every leg of the stitch in this cell and its neighbours: a seam never cuts a leg off.
	for dj in (-1, 0, 1):
		for di in (-1, 0, 1):
			cx = np.floor(x) + di + 0.5
			cy = np.floor(y) + dj
			for side in (-1.0, 1.0):
				# A leg from the stitch's outer top down to its point at the bottom centre.
				ax, ay = cx + side * 0.46, cy - LEG_OVERLAP
				bx, by = cx + side * 0.06, cy + 1.0 + LEG_OVERLAP * 0.5
				vx, vy = bx - ax, by - ay
				length2 = vx * vx + vy * vy
				t = np.clip(((x - ax) * vx + (y - ay) * vy) / length2, 0.0, 1.0)
				qx, qy = ax + t * vx - x, ay + t * vy - y
				# The distance is measured with y squeezed: a course is shorter than a wale is wide.
				d = np.sqrt(qx * qx + (qy * 0.8) ** 2) / YARN_RADIUS
				profile = np.sqrt(np.clip(1.0 - d * d, 0.0, 1.0))
				# Plies: stripes slanting across the leg, turning PLY_TURNS times along it.
				across = (qx * vy - qy * vx) / np.sqrt(length2)
				ply = 1.0 - PLY_DEPTH * (0.5 + 0.5 * np.cos(2.0 * np.pi * (t * PLY_TURNS + across * 2.0)))
				# The leg over the interlock lies higher in its middle than at its tucked ends.
				lift = 0.75 + 0.25 * np.sin(np.pi * t)
				height = np.maximum(height, profile * ply * lift)
	fuzz = tile_noise(size, 64, 7) * 0.6 + tile_noise(size, 128, 11) * 0.4
	return np.clip(height + FUZZ_DEPTH * (fuzz - 0.5), 0.0, 1.0)


def knit_pixels(size):
	"""The tile as an RGBA float array (rows top to bottom), each channel 0..1."""
	h = knit_height(size)
	# Slopes per stitch, wrapped at the edges: the tile stays seamless.
	dx = (np.roll(h, -1, axis=1) - np.roll(h, 1, axis=1)) * 0.5 * size / WALES
	dy = (np.roll(h, -1, axis=0) - np.roll(h, 1, axis=0)) * 0.5 * size / COURSES
	nx, ny, nz = -dx * BUMP * YARN_RADIUS, -dy * BUMP * YARN_RADIUS, np.ones_like(h)
	inv = 1.0 / np.sqrt(nx * nx + ny * ny + nz * nz)
	crown = np.clip(h / 0.8, 0.0, 1.0)
	rgba = np.empty((size, size, 4))
	rgba[..., 0] = nx * inv * 0.5 + 0.5
	rgba[..., 1] = ny * inv * 0.5 + 0.5
	rgba[..., 2] = ROUGH_GAP + (ROUGH_CROWN - ROUGH_GAP) * crown
	rgba[..., 3] = CAVITY_GAP + (1.0 - CAVITY_GAP) * np.sqrt(crown)
	return rgba


def save_png(rgba, path):
	import bpy

	size = rgba.shape[0]
	image = bpy.data.images.new("sock_knit", size, size, alpha=True)
	image.colorspace_settings.name = "Non-Color"
	image.alpha_mode = "STRAIGHT"
	# Blender's pixels start at the bottom row.
	image.pixels.foreach_set(np.ascontiguousarray(rgba[::-1]).astype(np.float32).ravel())
	image.filepath_raw = path
	image.file_format = "PNG"
	image.save()
	bpy.data.images.remove(image)


def main():
	argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	parser = argparse.ArgumentParser(prog="make_knit.py")
	parser.add_argument("--out", default="assets/sock/knit.png")
	parser.add_argument("--size", type=int, default=256)
	args = parser.parse_args(argv)
	out = os.path.abspath(args.out)
	save_png(knit_pixels(args.size), out)
	print("PASS make_knit: %s (%d px, %d x %d stitches)" % (out, args.size, WALES, COURSES))


if __name__ == "__main__":
	main()
