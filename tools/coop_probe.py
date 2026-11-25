#!/usr/bin/env python3
"""Compares a coop_probe Host log and Guest log (coop/13): the Guest's drawn Throw against the Host's
body at the same moment of the flight, the drawn drop, moving bodies under the floor, and every
Sock's final record on both machines."""
import math
import sys


def flight(host_log, guest_log):
    """coop/14: each Sock's flight as drawn each frame on both machines (S lines) against the Host's
    true body (T lines), at the delay that fits best: snaps (frames whose step differs from the true
    body's step at the same moment by more than 2 cm), the largest such jump, the delay, and how far
    off it is drawn (mean and worst)."""
    seen = {"host": {}, "guest": {}}
    true = {}
    marks = []
    for path, role in ((host_log, "host"), (guest_log, "guest")):
        for line in open(path, errors="replace"):
            p = line.split()
            if len(p) == 8 and p[0] in ("S", "T"):
                row = (float(p[2]), (float(p[4]), float(p[5]), float(p[6])), p[7])
                (seen[role] if p[0] == "S" else true).setdefault(int(p[3]), []).append(row)
            elif len(p) == 4 and p[0] == "MARK":
                marks.append((float(p[2]), p[1] + ":" + p[3]))
    if not seen["host"] and not seen["guest"]:
        return
    marks.sort()

    def runs(rows):
        out, cur = [], []
        for r in rows:
            if cur and r[0] - cur[-1][0] > 0.5:
                out.append(cur)
                cur = []
            cur.append(r)
        if cur:
            out.append(cur)
        return [r for r in out if len(r) > 5]

    def at(rows, t):
        if t <= rows[0][0]:
            return rows[0][1]
        if t >= rows[-1][0]:
            return rows[-1][1]
        lo, hi = 0, len(rows) - 1
        while hi - lo > 1:
            m = (lo + hi) // 2
            if rows[m][0] <= t:
                lo = m
            else:
                hi = m
        a, b = rows[lo], rows[hi]
        w = (t - a[0]) / max(b[0] - a[0], 1e-9)
        return tuple(x + (y - x) * w for x, y in zip(a[1], b[1]))

    def sub(a, b):
        return tuple(x - y for x, y in zip(a, b))

    def norm(a):
        return math.sqrt(sum(x * x for x in a))

    def judge(g, h, fixed=None):
        # Only the frames while the true body flies (the lying tail after it is the rest's).
        g = [r for r in g if r[2] != "lying"] or g
        fit = None
        for dms in ([fixed] if fixed is not None else range(-300, 400, 2)):
            d = dms / 1000.0
            err = sum(norm(sub(r[1], at(h, r[0] - d))) for r in g) / len(g)
            if fit is None or err < fit[1]:
                fit = (d, err)
        d = fit[0]
        # A snap: a frame whose change of step (what it moved this frame less what it moved the frame
        # before) differs from the true body's at the same moments by more than 1 cm. A smooth ease
        # (the lead from an avatar's hand) changes its step by millimetres a frame; a skipped tick or a
        # pop by centimetres.
        snaps, largest, worst = 0, 0.0, 0.0
        for a, b, c in zip(g, g[1:], g[2:]):
            dg = sub(sub(c[1], b[1]), sub(b[1], a[1]))
            ha, hb, hc = at(h, a[0] - d), at(h, b[0] - d), at(h, c[0] - d)
            j = norm(sub(dg, sub(sub(hc, hb), sub(hb, ha))))
            largest = max(largest, j)
            if j > 0.01:
                snaps += 1
        for r in g:
            worst = max(worst, norm(sub(r[1], at(h, r[0] - d))))
        return d, snaps, largest, fit[1], worst

    print("FLIGHT  sock what            seen on  frames  delay ms  snaps  jump cm  off mean/worst cm  kinds")
    for sock in sorted(set(seen["guest"]) | set(seen["host"])):
        tr = runs(true.get(sock, []))
        for role in ("host", "guest"):
            for g in runs(seen[role].get(sock, [])):
                label = "?"
                for t, m in marks:
                    if t <= g[0][0] + 0.05:
                        label = m
                h = None
                for cand in tr:
                    if cand[0][0] - 0.4 <= g[-1][0] and g[0][0] <= cand[-1][0] + 0.6:
                        h = cand
                        break
                kinds = "/".join(sorted({r[2] for r in g}))
                if h is None:
                    print("FLIGHT  %4d %-15s %-6s %6d  no true run  kinds %s" % (sock, label, role, len(g), kinds))
                    continue
                d, snaps, largest, mean, worst = judge(g, h, 0 if role == "host" else None)
                print("FLIGHT  %4d %-15s %-6s %6d  %7.0f  %5d  %7.1f  %6.1f/%-6.1f  %s" % (
                    sock, label, role, len(g), d * 1000, snaps, largest * 100, mean * 100, worst * 100, kinds))


def vec(s):
    return tuple(float(x) for x in s.split(","))


def dist(a, b):
    return math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b)))


def main(host_log, guest_log):
    flight(host_log, guest_log)
    host = {}
    finals = {"host": {}, "guest": {}}
    drawn = {"host": {}, "guest": {}}
    snaps = {"host": [], "guest": []}
    lows = {"host": [], "guest": []}
    guest = []
    for path, role in ((host_log, "host"), (guest_log, "guest")):
        for line in open(path, errors="replace"):
            p = line.split()
            if not p:
                continue
            if p[0] == "P" and p[1] == "host" and len(p) > 6 and p[3] == "ft":
                host[round(float(p[4]), 4)] = vec(p[6])
            elif p[0] == "P" and p[1] == "guest":
                d = {"tick": int(p[2]), "what": p[3]}
                for k in ("age", "gbody", "drawn", "copy", "ft", "drawn_mess"):
                    if k in p:
                        v = p[p.index(k) + 1]
                        d[k] = float(v) if k in ("age", "ft") else vec(v)
                guest.append(d)
            elif p[0] == "FINAL" and len(p) == 11:
                finals[p[1]][int(p[2])] = (int(p[3]), tuple(float(x) for x in p[4:11]))
            elif p[0] == "DRAWN":
                drawn[p[1]][int(p[2])] = tuple(float(x) for x in p[3:]) if p[3] != "none" else None
            elif p[0] == "SNAP":
                snaps[p[1]].append((float(p[3]), float(p[4])))
            elif p[0] == "LOW":
                lows[role].append(line.strip())
            elif p[0] == "PROBE" or "SCRIPT ERROR" in line or line.startswith("ERROR"):
                print(role, line.rstrip()[:200])
    times = sorted(host)

    def host_at(t):
        if not times or t < times[0] or t > times[-1]:
            return None
        for a, b in zip(times, times[1:]):
            if a <= t <= b:
                w = (t - a) / max(b - a, 1e-6)
                return tuple(x + (y - x) * w for x, y in zip(host[a], host[b]))
        return host[times[-1]]

    worst_body = worst_drawn = 0.0
    rows = []
    for d in guest:
        if d["what"] != "throw" or "age" not in d:
            continue
        h = host_at(d["age"])
        if h is None:
            continue
        eb = dist(d["gbody"], h)
        ed = dist(d["drawn"], h)
        rows.append((d["age"], h[1], d["gbody"][1], d["drawn"][1], eb, ed))
        worst_body = max(worst_body, eb)
        if d["age"] >= 0.2:
            worst_drawn = max(worst_drawn, ed)
    print("THROW host body ticks %d, guest ghost ticks %d; worst ghost body %.4f m, drawn after 0.2 s %.4f m"
          % (len(host), len(rows), worst_body, worst_drawn))
    for r in rows[::4][:30]:
        print("  t %.3f host y %.3f ghost body y %.3f drawn y %.3f  |body-host| %.3f |drawn-host| %.3f" % r)
    for what in ("throw", "drop"):
        pts = [d.get("drawn") or d.get("drawn_mess") for d in guest
               if d["what"] == what and (d.get("drawn") or d.get("drawn_mess"))]
        if len(pts) > 2:
            steps = [dist(a, b) for a, b in zip(pts, pts[1:])]
            ch = [dist(tuple(b[i] - a[i] for i in range(3)), tuple(c[i] - b[i] for i in range(3)))
                  for a, b, c in zip(pts, pts[1:], pts[2:])]
            print("%s drawn: %d frames, lowest y %.4f, largest step %.4f, largest change of step %.4f, last %s"
                  % (what, len(pts), min(p[1] for p in pts), max(steps), max(ch), pts[-1]))
    for role in ("host", "guest"):
        sn = sorted(snaps[role])
        if sn:
            big = [x for x in sn if x[0] > 0.05 or x[1] > 20]
            print("SNAP %s: %d rests, median %.4f m, 95th %.4f m, worst %.4f m; turned median %.1f deg, worst %.1f; over 5 cm or 20 deg: %d"
                  % (role, len(sn), sn[len(sn) // 2][0], sn[int(len(sn) * 0.95)][0], sn[-1][0],
                     sorted(x[1] for x in sn)[len(sn) // 2], max(x[1] for x in sn), len(big)))
    for role in ("host", "guest"):
        print("LOW lines %s: %d" % (role, len(lows[role])))
        for line in lows[role][:8]:
            print("  " + line)
    h, g = finals["host"], finals["guest"]
    if h and g:
        worst_p = worst_a = 0.0
        off = []
        for s in h:
            if s not in g:
                off.append((s, "missing"))
                continue
            hs, hp = h[s]
            gs, gp = g[s]
            if hs != gs:
                off.append((s, "state %d vs %d" % (hs, gs)))
            dp = dist(hp[:3], gp[:3])
            dot = min(1.0, abs(sum(a * b for a, b in zip(hp[3:], gp[3:]))))
            da = math.degrees(2 * math.acos(dot))
            worst_p, worst_a = max(worst_p, dp), max(worst_a, da)
            if dp > 0.001 or da > 1.0:
                off.append((s, "%.4f m %.2f deg" % (dp, da)))
        print("FINAL %d Socks host, %d guest; worst %.5f m %.3f deg; %d off" % (len(h), len(g), worst_p, worst_a, len(off)))
        for o in off[:10]:
            print("  ", o)
        dh, dg = drawn["host"], drawn["guest"]
        doff = [(s, dh.get(s), dg.get(s)) for s in dh if (dh.get(s) is None) != (dg.get(s) is None)
                or (dh.get(s) is not None and max(abs(a - b) for a, b in zip(dh[s], dg[s])) > 0.001)]
        print("DRAWN instances differing between the two (> 1 mm or drawn on one only): %d" % len(doff))
        for o in doff[:10]:
            print("  ", o)
        under = [s for s, (st, p) in h.items() if st == 0 and p[1] < -0.02]
        print("FINAL lying under the floor's top by > 2 cm (host): %d" % len(under))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
