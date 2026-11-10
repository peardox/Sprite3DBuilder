# Sprite3DBuilder

Sprite3DBuilder is a Delphi FireMonkey application that will become a level builder for 3D model kits, such as KayKit's dungeon pack. It is built on [Gorilla3D](https://www.gorilla3d.de/) and grew out of [Sprite3D](https://github.com/peardox/Sprite3D): it keeps Sprite3D's view, camera, model loading and settings, and leaves out everything Sprite3D has for making sprites (grabs, icons, exports, the Results tab, backgrounds, projects and the debug tools).

This first version is the cut-down base: open models, look at them on the floor grid, and choose which are listed. Placing pieces to build a level comes next.

The code is split as Sprite3D's is: everything in `src/lib` and `src/common` is independent of the application, and `src/ui` holds the forms and the application's own rules. The units in `src/lib` and `src/common` are copies of Sprite3D's, under the same names, so a fix in one can be carried to the other.

## Requirements

- RAD Studio (Delphi) with FireMonkey.
- [Gorilla3D](https://www.gorilla3d.de/) 1.5.4 or later, installed in the IDE.
- Spritely, the camera components that live in the [Sprite3D](https://github.com/peardox/Sprite3D) repository's `Spritely/` folder: its runtime package built for each platform you compile for, and its design package installed in the IDE. Sprite3DBuilder uses its orbital camera, `TSpritelyOrbitalCamera`, and its projections, `TSpritelyProjection`. Build them from Sprite3D's `Sprite3DGroup.groupproj` (see its README); Sprite3DBuilder needs no search path for them, as the package puts its compiled units in Delphi's Dcp folder.
- [Neon](https://github.com/paolo-rossi/delphi-neon), the JSON serialisation library, and [FastMM5](https://github.com/pleriche/FastMM5), both as Git submodules.

Target platforms: Windows (64-bit and ARM64EC), macOS (Intel and Apple silicon), Linux 64-bit, Android (32 and 64-bit) and iOS.

## Getting started

Clone with the submodules:

```
git clone --recurse-submodules https://github.com/peardox/Sprite3DBuilder.git
```

or, in an existing clone:

```
git submodule update --init
```

1. Build and install Spritely from Sprite3D first, as above.
2. Open `Sprite3DBuilderGroup.groupproj` in RAD Studio, choose a platform for **Sprite3DBuilder** and run.

A build failing with *F2613 Unit 'Spritely.OrbitalCamera' not found* has not got Spritely built for the platform it is compiling for.

## Features

- **Models list.** File, Open Model, dropping model files on the window, or a file the system asks the program to open, adds a model to the Models list beside the view and shows it. Opening the same file again reloads it in its place. A model whose name is listed already, from another file, is asked about: replace, ignore, or list it under a new name. Every model stays loaded, hidden while another is shown. **Clear**, below the list, empties it.
- **Static models only.** Every model is shown, and measured, in its rest pose; animations are not listed or played yet.
- **Floor grid.** The view always shows a grid on the model's floor; there is no other background.
- **Models, Models Used...** chooses which of the models opened are listed, each with its swept volume as a share of them all.
- **View, Camera.** Variable (a dialog with dials for the angles, distance, shift and rise), fixed views (Isometric, Pixel 2:1, 1/4 View, 3/4 View, Sqrt(2), Golden Ratio, Head On, Top Down, Side View), Lock Camera, and Mouse View (left-drag turns, the wheel zooms, a right click puts the normal view back).
- **View, Lights.** The camera's headlight and a second light on the camera, each on or off.
- **View, Projection.** Perspective, orthographic, and the oblique cavalier, cabinet, military and plan oblique projections, drawn by Spritely.
- **View, Show bounding box / Show axes / Show Model Volume / Show Combined Volume.** The combined volume joins every listed model's, and shows while two or more are listed.
- **Debug tab**, always there: what was loaded, what went wrong and what changed.
- **File, Settings...**: start-up action (none, the default model, the last model), theme, the view's frame rate, minified JSON and, on Windows, the graphics processor.
- **File, Licences...**: the third-party licences, from the program's own resources.

On Android and iOS the menu is a drawer opened from a button at the top; on Linux it is an FMX menu bar, as GTK's native one showed only first letters.

## Project layout

```
Sprite3DBuilderGroup.groupproj   the project group
src/
  Sprite3DBuilder.dpr/.dproj     the program
  ui/                            the forms, and Sprite3DBuilderHelpers: settings, model slots, themes
  lib/                           grid, axes, swept volumes, settings storage, styles, title bar, open requests
  common/                        OSPaths, JsonText, GpuPreference, DisplayData
  styles/                        the theme styles and buildstyles.cmd, the pre-build step
licences/                        third-party licences linked into the program
assets/                          model kits for the builder, such as assets/kaykit/dungeon (glTF); git ignores it
tools/pasdoc_check.py            checks the PasDoc comments and that sources are ASCII
docs/licences-required.md        what each third-party part asks of a release
```

`src/lib/Sprite3DAnimFrames.pas` is the one unit not in Sprite3D under that name: the two frame-source classes from Sprite3D's `Sprite3DAnimCapture`, which `Sprite3DSweep` needs, without the off-screen capture built on them.

## Assets

Model kits live in `assets/`, off the repository root, one folder per kit: so far `assets/kaykit/dungeon`, KayKit's Dungeon Pack as glTF. Git ignores the whole folder, so each working copy brings its own kits; the program does not look there by itself yet, so open the models with File, Open Model or drop them on the window.

## Settings

Settings are kept in `settings.json`, written by Neon, in a folder of Sprite3DBuilder's own, apart from Sprite3D's:

| Platform | Folder |
|---|---|
| Windows | `%APPDATA%\Sprite3DBuilder` |
| macOS | `~/Library/Application Support/Sprite3DBuilder` |
| Linux | `$XDG_CONFIG_HOME/Sprite3DBuilder`, or `~/.config/Sprite3DBuilder` |
| Android | the application's documents folder |
| iOS | `Library/Application Support/Sprite3DBuilder` |

What is kept: the View menu's ticks (bounding box, axes, Model Volume, Combined Volume, lights, projection), the camera view and the Variable view's angles, the shift, rise and distance when Variable asks for them to be kept, Mouse View's tick, the start-up action and the last model, the theme, the GPU choice, the view's frame rate and Minify JSON.

The start-up action is None at first, as no sample model comes with the program; Load default model looks for `models/uvcube.glb` in the program's assets folder.

## Themes

As Sprite3D's: the four FMX styles that come with RAD Studio (Dark, Aqua Graphite, Ruby Graphite, Golden Graphite), linked in as resources by the pre-build step `src/styles/buildstyles.cmd`, which also builds the licences' resource.

## Licences

What each third-party part asks of anyone who builds or distributes Sprite3DBuilder is set out in [docs/licences-required.md](docs/licences-required.md). The licences a release must carry are text files in `licences/`, linked into the program by `licences/Sprite3DLicences.rc` and shown by **File, Licences...**.

## Paths

Every file the application opens or writes goes through `OSFriendlyPath` in `common/OSPaths.pas` first, which gives it the platform's own delimiters.

## Known issues

- The grid belongs to the model shown and is drawn at Sprite3D's spacing of 1 unit; with no model shown there is no grid. A level builder needs a scene grid of its own, at the kit's spacing (2 units for KayKit's dungeon pack).
- Each model is centred on its bounding box as it loads (`PlaceModel`), as Sprite3D does; kit pieces will need to keep their own origins to snap to the grid.
- The camera view and View menu ticks are saved when the main form is destroyed, which Android and iOS do not always do before ending an application.
