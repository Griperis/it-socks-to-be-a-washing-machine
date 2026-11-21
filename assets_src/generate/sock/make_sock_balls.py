"""The static sock balls for Pairs with their LOD chain (pipeline/03, Q809, Q810), built into
the open Blender scene. Ported from the old game's tools/blender/make_sock_balls.py unchanged but
for this header (assets/08).

Headless, from the repository (assets_src/generate/README.md):

    blender -b -P assets_src/generate/build.py -- sock [--only ball_crew_plain] [--out <dir>] [--save]

--save writes assets_src/blender/sock/sock_balls.blend; each ball is exported to its glb
(assets/blender_assets.json sends ball_<cuff> to assets/sock/ball_<cuff>.glb). In an open Blender,
with assets_src/generate/sock on sys.path: `import make_sock_balls; print(make_sock_balls.build_all())`.

A Pair is two Socks rolled from the toe into a bundle, with one cuff turned
back over the outside: the "pocket" fold (docs/llm/flat/spec.md, real
references in docs/research/sock-shapes.md). The bundle is a lumpy oval, not a
sphere: longer along its axis than across, a little flatter than wide, with
soft lumps where the rolled heels and toes bunch up. The turned-back cuff is a
wide ribbed band over the mouth end with a raised edge (the cuff's welt) where
it ends on the shell. The folded cuff keeps its Collection's shape, so each
cuff style has its own ball:

    ankle          Simple      small ball, thin plain lip
    crew_plain     (spare)     plain crew cuff
    crew_scallop   Food        scalloped lip
    crew_rolled    Space       fat rolled lip
    crew_cape      Superhero   a little cape flap over the top
    crew_ears      Animals     two ears standing on the cuff band
    crew_stripe    Patterns    striped cuff band (trim / print / trim ...)
    tube_rib       Sport       wide ribbed cuff band (ribs drawn by the shader)
    chunky_fold    Winter      big ball, thick knit fold-over band

Objects per ball (the asset contract, with its LOD naming): the root Empty `ball_<cuff>`,
under it `<cuff>_ball` (LOD0, the close-up, about 500 triangles) and `<cuff>_ball_lod1` (LOD1,
the far ball, about 60: 8 vertices around and 4 of LOD0's rows, the ears as two pyramids, the
cape as a sheet, the scallops as a zigzag lip of 14). No rig, no spring bones; material `sock`.
The rows are picked from the profile, most deviating first (`pick_rows`), so each ball keeps
its lip bead, cuff band, knit ridges and stripes where they show most.

Frame: the ball's axis lies along X like a flat Sock. The mouth (the cuff
opening, where the rolled toe end shows) faces -X, the gathered back pole is
at +X. Origin at the centre of the footprint, bottom at height 0, stretched
along X (OVAL) and squashed in height (SQUASH). Blender Z-up; glTF converts to
Y-up.

UV contract (same as the rigged Socks, so the pattern shader keeps working):
  UV0 `UVMap`: the folded-back leg is a tube around the ball's axis, so
    U runs cuff -> toe along the ball from the mouth lip (U = 0) over the
    shell to the back pole (U = U_BACK, about mid-sock), and
    V runs around the axis exactly like around a Sock: V = 0 on the +Y side,
    0.25 on top, 0.5 on -Y, 0.75 underneath (seam on the +Y side).
    The mouth shows the rolled foot: U = 0.6 at its rim to 1.0 (toe) at its
    centre. Seen from above, the ball shows V around 0.25, the same face as a
    flat Sock's top, with U increasing toward +X.
  UV1 `TrimMask`: U = 1 on the cuff band (and its lip, cape and ears) and on
    the toe at the mouth's centre, 0 elsewhere. The stripe cuff alternates
    1/0 bands across the cuff band. V = 1 on the ribbed cuff band and lip
    (the sock shader draws ribs there), else 0.

"""

import math
import random

import bpy
import bmesh
from mathutils import Vector

U_BACK = 0.55      # UV0 U at the back pole
SQUASH = 0.84      # height scale of the finished ball
OVAL = (1.16, 0.96)  # length (X) and width (Y) scale: a bundle, not a sphere


def smoothstep(e0, e1, x):
    t = min(max((x - e0) / (e1 - e0), 0.0), 1.0)
    return t * t * (3 - 2 * t)


# --- Cuff styles -----------------------------------------------------------------
#   R           radius of the rolled body (m)
#   mouth       angular radius of the mouth opening (deg, from the -X axis)
#   lip         angle of the lip bead's centre (deg)
#   band        angle where the cuff band ends (deg)
#   rb          lip bead radius (m); lift: bead centre radius = R + rb * lift
#   t_band      cuff band thickness over the body (m); t_shell: leg layer (m)
#   cuff_end    UV0 U at the end of the cuff band
#   extra       "scallop" | "rib" | "knit" | "stripe" | "cape" | "ears" | None
#   lumps       seed of the soft lumps (where the rolled heels and toes bunch)
STYLES = {
    "ankle": dict(R=0.036, mouth=40, lip=44, band=70, rb=0.0028, lift=1.0,
                  t_band=0.0045, t_shell=0.0025, cuff_end=0.07, extra=None, lumps=1),
    "crew_plain": dict(R=0.044, mouth=42, lip=46, band=80, rb=0.0035, lift=1.0,
                       t_band=0.006, t_shell=0.003, cuff_end=0.12, extra=None, lumps=2),
    "crew_scallop": dict(R=0.044, mouth=38, lip=48, band=80, rb=0.0035, lift=1.0,
                         t_band=0.006, t_shell=0.003, cuff_end=0.12,
                         extra="scallop", lumps=3),
    "crew_rolled": dict(R=0.044, mouth=40, lip=48, band=76, rb=0.0085, lift=0.9,
                        t_band=0.0065, t_shell=0.003, cuff_end=0.12, extra=None,
                        lumps=4),
    "crew_cape": dict(R=0.044, mouth=42, lip=46, band=80, rb=0.0035, lift=1.0,
                      t_band=0.006, t_shell=0.003, cuff_end=0.12, extra="cape",
                      lumps=5),
    "crew_ears": dict(R=0.044, mouth=42, lip=46, band=80, rb=0.0035, lift=1.0,
                      t_band=0.006, t_shell=0.003, cuff_end=0.12, extra="ears",
                      lumps=6),
    "crew_stripe": dict(R=0.044, mouth=42, lip=46, band=86, rb=0.0035, lift=1.0,
                        t_band=0.006, t_shell=0.003, cuff_end=0.14,
                        extra="stripe", lumps=7),
    "tube_rib": dict(R=0.044, mouth=40, lip=44, band=90, rb=0.004, lift=1.0,
                     t_band=0.0065, t_shell=0.003, cuff_end=0.18, extra="rib",
                     lumps=8),
    "chunky_fold": dict(R=0.056, mouth=40, lip=46, band=94, rb=0.009, lift=0.75,
                        t_band=0.012, t_shell=0.005, cuff_end=0.16,
                        extra="knit", lumps=9),
}


def sph(alpha, r, th):
    """Point at angle alpha from the -X axis, distance r, angle th around X."""
    rho = r * math.sin(alpha)
    return Vector((-r * math.cos(alpha), rho * math.cos(th), rho * math.sin(th)))


def lip_angle(st, th):
    a = math.radians(st["lip"])
    if st["extra"] == "scallop":
        # Seven rounded scallops reaching into the mouth.
        a -= math.radians(10) * abs(math.sin(3.5 * th))
    return a


def band_trim(st, u):
    if st["extra"] == "stripe":
        # trim / print / trim / print / trim across the band
        k = int(u / st["cuff_end"] * 5)
        return 1.0 if k % 2 == 0 else 0.0
    return 1.0


def band_bump(st, f, th):
    """Extra radius on the cuff band at fraction f (0 lip .. 1 band end)."""
    # Ribs around the band are drawn by the sock shader (UV1 V); only the chunky
    # fold keeps its three soft ridges in the mesh.
    if st["extra"] == "knit":
        return 0.0035 * (0.5 + 0.5 * math.cos(2 * math.pi * 3 * f))
    return 0.0


def rows(st):
    """Profile rows: each is a function th -> (point, u, trim), mouth to back."""
    R = st["R"]
    am = math.radians(st["mouth"])
    ab = math.radians(st["band"])
    rb = st["rb"]
    Rc = R + rb * st["lift"]
    r_top = Rc + rb
    r_band = max(R + st["t_band"], r_top)
    r_shell = R + st["t_shell"]
    out = []

    # A. The rolled foot in the mouth, with a spiral of layers.
    Rd = R * 0.94
    nd = 7
    for k in range(1, nd + 1):
        f = k / nd
        a = am * f

        def row(th, a=a, f=f):
            s = (f * 3.2 - th / (2 * math.pi)) % 1.0
            groove = 0.5 - 0.5 * math.cos(2 * math.pi * s)
            r = Rd * (1 + 0.03 * (1 - f) ** 0.5) - 0.0016 * groove * smoothstep(0.1, 0.3, f)
            u = 1.0 - 0.4 * f
            return sph(a, r, th), u, smoothstep(0.82, 0.88, u), 0.0
        out.append(row)

    # B. Crevice down under the lip, then C. the lip bead.
    nb = 7
    for k in range(nb + 1):
        psi = math.pi * k / nb

        def row(th, psi=psi):
            al = lip_angle(st, th)
            n = sph(al, 1.0, th)
            tau = Vector((math.sin(al), math.cos(al) * math.cos(th), math.cos(al) * math.sin(th)))
            c = n * Rc
            p = c - n * (rb * math.cos(psi)) - tau * (rb * math.sin(psi))
            return p, 0.0, band_trim(st, 0.0), 1.0
        out.append(row)

    # D. The cuff band.
    nband = 12 if st["extra"] in ("knit", "stripe") else 5
    for k in range(1, nband + 1):
        f = k / nband

        def row(th, f=f):
            al = lip_angle(st, th)
            a = al + (ab - al) * f
            # Ease from the bead's top radius onto the band radius.
            r = r_top + (r_band - r_top) * smoothstep(0.0, 0.3, f) + band_bump(st, f, th)
            u = st["cuff_end"] * f
            return sph(a, r, th), u, band_trim(st, min(u, st["cuff_end"] * 0.999)), 1.0
        out.append(row)

    # E. Step from the band down onto the leg layer (still trim, so the wall is
    # the cuff's edge, not a stretched strip of print), F. the shell to the back pole.
    step = math.radians(7)
    a_s = ab + step

    def row(th, a_s=a_s):
        return sph(a_s, r_shell, th), st["cuff_end"], band_trim(st, 0.0), 1.0
    out.append(row)
    a_s += math.radians(1.5)
    ns = 10
    for k in range(ns + 1):
        f = k / ns
        a = a_s + (math.pi - a_s) * f

        def row(th, a=a, f=f):
            r = r_shell
            u = st["cuff_end"] + (U_BACK - st["cuff_end"]) * f
            return sph(a, r, th), u, 0.0, 0.0
        out.append(row)
    return out


def add_patch(bm, uv0, uv1, pts_fn, nu, nv, u_fn, trim, thickness):
    """A thin two-sided slab from a (s, t) -> point surface, s, t in 0..1."""
    top, bot = [], []
    for a in range(nu + 1):
        rt, rbm = [], []
        for b in range(nv + 1):
            p, n = pts_fn(a / nu, b / nv)
            rt.append(bm.verts.new(p + n * thickness * 0.5))
            rbm.append(bm.verts.new(p - n * thickness * 0.5))
        top.append(rt)
        bot.append(rbm)

    def quad(vs, uvs):
        f = bm.faces.new(vs)
        for loop, (u, v) in zip(f.loops, uvs):
            loop[uv0].uv = (u, v)
            loop[uv1].uv = (trim, 0.0)

    for a in range(nu):
        for b in range(nv):
            uv = [u_fn(a / nu, b / nv), u_fn((a + 1) / nu, b / nv),
                  u_fn((a + 1) / nu, (b + 1) / nv), u_fn(a / nu, (b + 1) / nv)]
            quad((top[a][b], top[a + 1][b], top[a + 1][b + 1], top[a][b + 1]), uv)
            quad((bot[a][b + 1], bot[a + 1][b + 1], bot[a + 1][b], bot[a][b]), uv[::-1])
    # Close the rim.
    rim = [(a, 0) for a in range(nu)] + [(nu, b) for b in range(nv)] + \
          [(a, nv) for a in range(nu, 0, -1)] + [(0, b) for b in range(nv, 0, -1)]
    for k in range(len(rim)):
        a0, b0 = rim[k]
        a1, b1 = rim[(k + 1) % len(rim)]
        uv = [u_fn(a0 / nu, b0 / nv), u_fn(a1 / nu, b1 / nv)]
        quad((top[a0][b0], bot[a0][b0], bot[a1][b1], top[a1][b1]), [uv[0], uv[0], uv[1], uv[1]])


def lumpy_oval(bm, st):
    """Stretch the ball into a bundle (OVAL, SQUASH) and push out a few soft lumps."""
    rnd = random.Random(st["lumps"])
    lumps = []
    for _ in range(5):
        # Lumps on the shell behind the cuff band, not on the mouth.
        a = math.radians(rnd.uniform(st["band"] + 10, 170))
        th = rnd.uniform(0, 2 * math.pi)
        lumps.append((sph(a, 1.0, th), rnd.uniform(0.04, 0.08), rnd.uniform(0.45, 0.7)))
    for v in bm.verts:
        p = v.co
        if p.length > 1e-6:
            d = p.normalized()
            k = 0.0
            for c, amp, w in lumps:
                k += amp * math.exp(-((1 - d.dot(c)) / (w * w * 0.5)) ** 2)
            # The mouth and the turned-back cuff band stay smooth (stretched over the lumps).
            alpha = math.degrees(math.acos(max(-1.0, min(1.0, -d.x))))
            k *= smoothstep(st["band"] + 6, st["band"] + 30, alpha)
            p = p * (1 + k)
        v.co = Vector((p.x * OVAL[0], p.y * OVAL[1], p.z * SQUASH))


# --- The LOD chain (pipeline/03, Q809) ----------------------------------------------
TRIM_WEIGHT = 0.008  # m of deviation one unit of TrimMask counts as, when picking rows


def profile(st, segs):
    """Every candidate row sampled at `segs` angles: [(param, points, (u, trim, rib) per angle,
    row function)], between two fixed ends with no row function: the mouth's centre and the back
    pole (the fans close the shell there; the pole's own row is left out). `param` is the
    distance along the profile on top of the ball, the rows' blend parameter."""
    centre = Vector((-st["R"] * 0.94 * 1.03, 0, 0))
    pole = Vector((st["R"] + st["t_shell"], 0, 0))
    out = [(0.0, [centre] * segs, [(1.0, 1.0, 0.0)] * segs, None)]
    acc, prev = 0.0, centre
    for fn in rows(st)[:-1]:
        pts, data = [], []
        for i in range(segs):
            p, u, t, rib = fn(2 * math.pi * i / segs)
            pts.append(p)
            data.append((u, t, rib))
        top = fn(math.pi / 2)[0]
        acc += (top - prev).length + 1e-6
        prev = top
        out.append((acc, pts, data, fn))
    acc += (pole - prev).length + 1e-6
    out.append((acc, [pole] * segs, [(U_BACK, 0.0, 0.0)] * segs, None))
    return out


def pick_rows(prof, count, among=None):
    """`count` rows of the profile between its fixed ends: each next one is the row that deviates
    most from the straight blend of its picked neighbours (position, plus TrimMask and rib mask
    weighted by TRIM_WEIGHT). `among` limits the candidates (indices)."""
    ends = [0, len(prof) - 1]
    cands = sorted(set(among if among is not None else range(len(prof))) | set(ends))
    picked = list(ends)
    while len(picked) < count + 2:
        best, err_best = None, -1.0
        sp = sorted(picked)
        for c in cands:
            if c in picked:
                continue
            k = next(i for i, x in enumerate(sp) if x > c)
            a, b = sp[k - 1], sp[k]
            ta, tb, tc = prof[a][0], prof[b][0], prof[c][0]
            t = (tc - ta) / (tb - ta) if tb > ta else 0.5
            err = 0.0
            for i in range(len(prof[c][1])):
                d = (prof[c][1][i] - prof[a][1][i].lerp(prof[b][1][i], t)).length
                for j in (1, 2):
                    va, vb = prof[a][2][i][j], prof[b][2][i][j]
                    d += TRIM_WEIGHT * abs(prof[c][2][i][j] - (va + (vb - va) * t))
                err = max(err, d)
            if err > err_best:
                best, err_best = c, err
        picked.append(best)
    return sorted(set(picked) - set(ends))


def add_revolved(bm, uv0, uv1, st, fns, segs):
    """The ball's shell: the rows `fns` revolved at `segs` angles, a fan from the mouth's centre
    and a fan to the back pole."""
    centre = bm.verts.new(Vector((-st["R"] * 0.94 * 1.03, 0, 0)))
    grid, data = [], []
    for fn in fns:
        ring, d = [], []
        for i in range(segs):
            p, u, t, rib = fn(2 * math.pi * i / segs)
            ring.append(bm.verts.new(p))
            d.append((u, t, rib))
        grid.append(ring)
        data.append(d)
    back = bm.verts.new(Vector((st["R"] + st["t_shell"], 0, 0)))

    def setuv(f, items):
        for loop, (u, v, t, rib) in zip(f.loops, items):
            loop[uv0].uv = (u, v)
            loop[uv1].uv = (t, rib)

    def at(r, i, v):
        return (data[r][i][0], v, data[r][i][1], data[r][i][2])

    for i in range(segs):
        j = (i + 1) % segs
        v0, v1 = i / segs, (i + 1) / segs
        f = bm.faces.new((centre, grid[0][j], grid[0][i]))
        setuv(f, ((1.0, (v0 + v1) / 2, 1.0, 0.0), at(0, j, v1), at(0, i, v0)))
    for r in range(len(grid) - 1):
        for i in range(segs):
            j = (i + 1) % segs
            v0, v1 = i / segs, (i + 1) / segs
            f = bm.faces.new((grid[r][i], grid[r][j], grid[r + 1][j], grid[r + 1][i]))
            setuv(f, (at(r, i, v0), at(r, j, v1), at(r + 1, j, v1), at(r + 1, i, v0)))
    last = len(grid) - 1
    for i in range(segs):
        j = (i + 1) % segs
        v0, v1 = i / segs, (i + 1) / segs
        f = bm.faces.new((grid[last][i], grid[last][j], back))
        setuv(f, ((data[last][i][0], v0, 0.0, 0.0), (data[last][j][0], v1, 0.0, 0.0),
                  (U_BACK, (v0 + v1) / 2, 0.0, 0.0)))


def _cape_surface(st):
    R = st["R"]
    r = R + st["t_shell"] + 0.0012
    a0 = math.radians(st["band"] - 4)
    a1 = math.radians(140)

    def pts(s, t):
        a = a0 + (a1 - a0) * s
        half = 0.35 + 0.35 * s                            # flares toward the hem
        hem = 0.06 * abs(math.sin(t * math.pi * 3)) * s   # a scalloped hem
        th = math.pi / 2 + (t - 0.5) * 2 * half
        rr = r + 0.0012 * math.sin(t * math.pi * 6) * s ** 2
        a = a - hem * (a1 - a0) * s
        p = sph(a, rr, th)
        return p, p.normalized() if p.length > 0 else Vector((0, 0, 1))

    def u_fn(s, t):
        return (st["cuff_end"] * 0.5, 0.25 + (t - 0.5) * 0.3)

    return pts, u_fn


def add_cape(bm, uv0, uv1, st, lod=0):
    """A little cape fastened along the top of the cuff band, draped back over the ball: a thin
    slab at LOD0 (its hem scallops at the corners of 3 x 6 cells), a single sheet at LOD1."""
    pts, u_fn = _cape_surface(st)
    if lod == 0:
        add_patch(bm, uv0, uv1, pts, 3, 6, u_fn, 1.0, 0.002)
        return
    # The far cape: the top of the slab's cells at s = 0, 1 and t = 0, 0.5, 1 (a tent, 4 tris).
    grid = {}
    for s in (0, 1):
        for t in (0, 0.5, 1):
            p, n = pts(s, t)
            grid[(s, t)] = bm.verts.new(p + n * 0.001)
    for t0, t1 in ((0, 0.5), (0.5, 1)):
        f = bm.faces.new((grid[(0, t0)], grid[(1, t0)], grid[(1, t1)], grid[(0, t1)]))
        for loop, (s, t) in zip(f.loops, ((0, t0), (1, t0), (1, t1), (0, t1))):
            loop[uv0].uv = u_fn(s, t)
            loop[uv1].uv = (1.0, 0.0)


EAR_RINGS, EAR_AROUND = 3, 6


def add_ears(bm, uv0, uv1, st, lod=0):
    """Two rounded ears standing up from the cuff band, faces toward the mouth: 3 rings of 6 at
    LOD0, a three-sided pyramid (every other vertex of the base ring and the tip) at LOD1."""
    R = st["R"]
    a = math.radians(st["lip"] + 12)
    h, w, d = 0.021, 0.026, 0.010
    for side in (-1, 1):
        th = math.pi / 2 + side * 0.5
        base = sph(a, R + st["t_band"] - 0.003, th)
        n = (base.normalized() + Vector((0, 0, 0.8))).normalized()   # lean upward
        along = Vector((1, 0, 0))
        across = n.cross(along).normalized()
        along = across.cross(n).normalized()

        def ring_pt(k, i):
            s = k / EAR_RINGS
            shrink = (1 - s) ** 0.85 * (1 - 0.25 * s)    # rounded triangle
            ph = 2 * math.pi * i / EAR_AROUND
            return base + n * (h * s) + across * (0.5 * w * shrink * math.cos(ph)) + \
                along * (0.5 * d * shrink * (0.6 + 0.4 * (1 - s)) * math.sin(ph))

        tip = bm.verts.new(base + n * h * 0.97)

        def setuv(f, s_vals):
            for loop, sv in zip(f.loops, s_vals):
                loop[uv0].uv = (0.02 + 0.06 * sv, 0.25)
                loop[uv1].uv = (1.0, 0.0)

        if lod:
            ring = [bm.verts.new(ring_pt(0, i)) for i in range(0, EAR_AROUND, 2)]
            for i in range(len(ring)):
                f = bm.faces.new((ring[i], ring[(i + 1) % len(ring)], tip))
                setuv(f, (0.0, 0.0, 1.0))
            continue
        rings = [[bm.verts.new(ring_pt(k, i)) for i in range(EAR_AROUND)] for k in range(EAR_RINGS)]
        for k in range(EAR_RINGS - 1):
            for i in range(EAR_AROUND):
                j = (i + 1) % EAR_AROUND
                f = bm.faces.new((rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]))
                setuv(f, (k / EAR_RINGS, k / EAR_RINGS, (k + 1) / EAR_RINGS, (k + 1) / EAR_RINGS))
        last = rings[-1]
        for i in range(EAR_AROUND):
            j = (i + 1) % EAR_AROUND
            f = bm.faces.new((last[i], last[j], tip))
            setuv(f, (0.9, 0.9, 1.0))
        f = bm.faces.new(list(reversed(rings[0])))      # cap, sunk into the band
        setuv(f, [0.0] * EAR_AROUND)


# Per style: (segments, rows) at LOD0 and at LOD1. The scallop ball needs 4 vertices a scallop
# up close and 2 (a zigzag lip) far; the stripe ball keeps one more row far for its bands.
LOD_SHAPE = {
    "default": ((16, 15), (8, 4)),
    "crew_ears": ((16, 13), (8, 4)),
    "crew_cape": ((16, 13), (8, 4)),
    "crew_scallop": ((28, 8), (14, 2)),
    "crew_stripe": ((16, 15), (8, 5)),
    "chunky_fold": ((16, 15), (8, 4)),
}


def _ball_mesh(name, st, segs, fns, lod, mat):
    bm = bmesh.new()
    uv0 = bm.loops.layers.uv.new("UVMap")
    uv1 = bm.loops.layers.uv.new("TrimMask")
    add_revolved(bm, uv0, uv1, st, fns, segs)
    if st["extra"] == "cape":
        add_cape(bm, uv0, uv1, st, lod)
    if st["extra"] == "ears":
        add_ears(bm, uv0, uv1, st, lod)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-7)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    lumpy_oval(bm, st)
    return bm


def _remove_tree(name):
    root = bpy.data.objects.get(name)
    if root is None:
        return
    for o in list(root.children_recursive) + [root]:
        data = o.data
        bpy.data.objects.remove(o)
        if data is not None and data.users == 0 and isinstance(data, bpy.types.Mesh):
            bpy.data.meshes.remove(data)


def sock_material():
    mat = bpy.data.materials.get("sock") or bpy.data.materials.new("sock")
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (0.8, 0.8, 0.8, 1)
    bsdf.inputs["Roughness"].default_value = 0.8
    return mat


def build(name):
    """Builds ball_<name> (root Empty, `<name>` LOD0 and `<name>_lod1`) in the scene, replacing
    any earlier one."""
    st = STYLES[name]
    (s0, k0), (s1, k1) = LOD_SHAPE.get(name, LOD_SHAPE["default"])
    _remove_tree("ball_" + name)
    prof0 = profile(st, s0)
    rows0 = pick_rows(prof0, k0)
    prof1 = profile(st, s1)
    rows1 = pick_rows(prof1, k1, among=rows0)
    mat = sock_material()
    bms = [_ball_mesh(name, st, s0, [prof0[r][3] for r in rows0], 0, mat),
           _ball_mesh(name + "_lod1", st, s1, [prof1[r][3] for r in rows1], 1, mat)]
    # Centre on LOD0's box (footprint centre on the origin, bottom at z = 0); LOD1 moves with it.
    xs = [v.co.x for v in bms[0].verts]
    ys = [v.co.y for v in bms[0].verts]
    zs = [v.co.z for v in bms[0].verts]
    off = Vector(((max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2, min(zs)))
    coll = bpy.context.scene.collection
    root = bpy.data.objects.new("ball_" + name, None)
    root.empty_display_size = 0.03
    coll.objects.link(root)
    out = []
    for obj_name, bm in zip((name + "_ball", name + "_ball_lod1"), bms):
        for v in bm.verts:
            v.co -= off
        mesh = bpy.data.meshes.new(obj_name)
        bm.to_mesh(mesh)
        bm.free()
        for p in mesh.polygons:
            p.use_smooth = True
        mesh.materials.append(mat)
        obj = bpy.data.objects.new(obj_name, mesh)
        coll.objects.link(obj)
        obj.parent = root
        out.append("%s %d" % (obj_name, sum(len(p.vertices) - 2 for p in mesh.polygons)))
    dims = (max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))
    return "ball_%s: %.3f x %.3f x %.3f m; tris %s" % (name, *dims, ", ".join(out))


def build_all():
    return "\n".join(build(n) for n in STYLES)
