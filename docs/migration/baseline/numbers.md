# Numbers at v0.1 that can be measured without a GPU

Tag `v0.1` = commit 10db4d049779641153ba731ab6bc92b0c1e620e2. Measured in the sandbox (Linux, no GPU) on a worktree of that commit with the LFS files checked out.

## Suite verdict (known, not re-run)

`PASS 33038 checks, 1054 cases`, from the merge run of progression/98. The full suite was NOT run for this baseline.

## Code and data

| what | files | lines |
|---|---|---|
| GDScript under `game/` | 321 | 79,036 |
| GDScript under `tests/` | 102 | 45,864 |
| GDScript under `tools/` | 32 | 4,734 |
| `.tscn` scenes (game/, assets/) | 7 | |
| `.gdshader` shaders (assets/, game/, data/) | 13 | |
| `.ogg` sounds (488 in assets/audio) | 506 | |
| `.png` textures under `assets/` | 25 | |
| `.svg` (assets/ui icons) | 111 | |
| `.ttf` fonts | 1 | |

## Assets per folder (size = apparent bytes of everything in the folder, `.import` files included)

| folder | size (MB) | glb files | glb MB |
|---|---|---|---|
| assets/audio/ | 18.6 | 0 | 0.00 |
| assets/avatar/ | 6.1 | 122 | 6.05 |
| assets/blender_assets/ | 0.0 | 0 | 0.00 |
| assets/cabinet/ | 2.4 | 17 | 2.17 |
| assets/cat/ | 0.2 | 1 | 0.24 |
| assets/clock/ | 0.1 | 1 | 0.06 |
| assets/encyclopedia_book/ | 0.1 | 1 | 0.09 |
| assets/flat/ | 2.4 | 1 | 2.10 |
| assets/fonts/ | 0.2 | 0 | 0.00 |
| assets/grotto_lantern/ | 0.0 | 1 | 0.02 |
| assets/guide/ | 0.5 | 0 | 0.00 |
| assets/hamper/ | 0.0 | 1 | 0.05 |
| assets/house/ | 17.3 | 71 | 15.64 |
| assets/laundry_bin/ | 0.1 | 1 | 0.05 |
| assets/pairing_machine/ | 0.3 | 1 | 0.33 |
| assets/parts/ | 0.2 | 5 | 0.20 |
| assets/radio/ | 17.1 | 1 | 0.06 |
| assets/sample_crate/ | 0.0 | 0 | 0.00 |
| assets/sky/ | 19.7 | 0 | 0.00 |
| assets/sock/ | 3.4 | 13 | 0.26 |
| assets/sock_detector/ | 0.0 | 1 | 0.04 |
| assets/sock_vacuum/ | 0.3 | 1 | 0.28 |
| assets/tv/ | 0.1 | 1 | 0.07 |
| assets/ui/ | 0.2 | 0 | 0.00 |
| assets/vacuum_devices/ | 3.3 | 3 | 0.64 |
| assets/wardrobe_station/ | 0.3 | 1 | 0.28 |
| assets/washing_machine/ | 0.5 | 1 | 0.50 |
| **total** | 93.5 | 245 | 29.12 |

## The Windows build in the main checkout

`builds/windows/ItSocks.exe` is 216,980,408 bytes (206.9 MB). There is NO separate `.pck` (the pack is embedded). `ItSocks.console.exe` is 188,928 bytes. Both are dated 2026-11-19 20:47; I could not verify that this build is of tag v0.1.

## Frame times: not measured

Frame-time numbers need the designer's machine (a real GPU); the sandbox draws on the CPU (lavapipe), so its times mean nothing for the game. Command from `docs/perf/tools.md`, with a debug build or from the repo:

    "ItSocks.exe" -- --bench
    godot --path . -- --bench --bench-presets=low,medium

It writes `bench.json` (`%APPDATA%\Godot\app_userdata\It Socks\bench.json`). A double-click version for a low-end machine is `bench_lowend.cmd` next to the exe (five runs, zipped as `bench_lowend_results.zip`); `tools/bench_mirrors.cmd` compares mirror modes. Run plugged in, at the resolution you play at, other programs closed.
