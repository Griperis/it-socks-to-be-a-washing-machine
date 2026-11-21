# It Socks: pages for the designer

These pages are for you, working in the Godot editor and Blender. Each says what a job is for, the steps, how to see that it worked, and what bites.

| Page | One line |
|---|---|
| `models-update-a-model.md` | Change or replace a model that is already in the game: Socks and balls, Cabinets, furniture, house kit pieces. |
| `models-pipeline.md` | Bring a new model in from Blender to a Looks scene on an entity, and show it in a zoo station. |
| `sounds-pipeline.md` | Add or swap a sound: the catalogue, buses, flat or 3D, minimum gap, strength, footsteps, the Sounds station. |
| `house-kit.md` | Build or change rooms from the house kit in the editor, and rebuild the pieces from their sizes. |

## Two things that hold for every page

- The test command is `kit/tools/run.sh --only=<suite>`. Run it from the project folder. A good run ends with a line starting `PASS`.
- Some work is only on a branch and not in `main` yet. Each page says so in one line where it matters. Today that is the furniture and the shared material library (branch `assets/04-furniture-and-materials`, waiting for your go).
