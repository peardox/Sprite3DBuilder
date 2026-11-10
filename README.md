# Sprite3DBuilder

Sprite3DBuilder is a Delphi FireMonkey application that will become a level builder for 3D model kits, such as KayKit's dungeon pack. It is built on [Gorilla3D](https://www.gorilla3d.de/) and grew out of [Sprite3D](https://github.com/peardox/Sprite3D): it keeps Sprite3D's view, camera, model loading and settings, and leaves out everything Sprite3D has for making sprites (grabs, icons, exports, the Results tab, backgrounds, projects and the debug tools).

It starts with an empty level: a floor grid at the kit's spacing, ready to build on. File, Open Asset Folder... shows a kit's models as thumbnails, in groups; dragging them onto the level comes next.

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

- **An empty level.** The view starts with a floor grid at the spacing kept in `settings.json` (`gridSize`, 2 units by default, a floor tile of KayKit's dungeon pack), framed in the isometric view.
- **File, Open Asset Folder...** chooses a folder of a model kit, starting in the `assets` folder (see *Assets*), or where the last one was chosen, and shows its models on the **Assets** form (see *Thumbnails*). Desktop only: Android and iOS have no folder dialog.
- **View, Camera.** Variable (a dialog with dials for the angles, distance, shift and rise), fixed views (Isometric, Pixel 2:1, 1/4 View, 3/4 View, Sqrt(2), Golden Ratio, Head On, Top Down, Side View), Lock Camera, and Mouse View (left-drag turns, the wheel zooms, a right click puts the normal view back).
- **View, Lights.** The camera's headlight and a second light on the camera, each on or off.
- **View, Projection.** Perspective, orthographic, and the oblique cavalier, cabinet, military and plan oblique projections, drawn by Spritely.
- **View, Show bounding box** will box each piece placed.
- **Debug tab**, always there: what was chosen, what went wrong and what changed.
- **File, Settings...**: theme, the view's frame rate, minified JSON and, on Windows, the graphics processor.
- **File, Licences...**: the third-party licences, from the program's own resources.

On Android and iOS the menu is a drawer opened from a button at the top; on Linux it is an FMX menu bar, as GTK's native one showed only first letters.

## Thumbnails

The Assets form shows every model of the folders chosen (not their sub-folders) as a 256 x 256 thumbnail, under a heading for each group: the first word of the model's name, before the first underscore (`wall_corner` is in *wall*), with a plural group such as *crates* put with *crate* when both are there. Clicking one shows its name, group, size in its own units and file.

Each model is known by a key: the SHA-256 of its file and of every file it names (for glTF, the `uri` of its buffers and images), so a copy of a model in another folder is the same model, and any change to it, its `.bin` or its textures makes a new one. Two files with the same key are shown once, and the Debug tab says so.

Thumbnails are made the first time a model is seen, one at a time, in the form's own view: loaded, turned upright, framed in the isometric view in orthographic projection with the up axis through its centre of rotation, the point it will sit on in the level, in the middle across (so a corner piece is drawn to one side, as it sits in its cell), and grabbed off screen with a transparent background, as Sprite3D's grabs are. They are kept in a `thumbnails` folder beside `settings.json`, as `<key>.png` with `<key>.json` beside it: the model's name, group, the file it was found as, the files it names, its bounding box (in its own units, so kits made at other scales can be told apart and scaled later), and how and when the thumbnail was made. The next time, every model already in the cache is shown at once. A thumbnail of another size than 256 is made again, so changing the size remakes them. Closing the form stops making them; opening the folder again carries on.

The cache can be deleted at any time; nothing is lost but the time to make the thumbnails again.

## Project layout

```
Sprite3DBuilderGroup.groupproj   the project group
src/
  Sprite3DBuilder.dpr/.dproj     the program
  ui/                            the forms, and Sprite3DBuilderHelpers: settings, the assets folder, themes
  lib/                           grid, swept volumes, off-screen grabs, asset cache, settings storage,
                                 folder dialog, styles, title bar
  common/                        OSPaths, JsonText, GpuPreference, DisplayData
  styles/                        the theme styles and buildstyles.cmd, the pre-build step
licences/                        third-party licences linked into the program
assets/                          model kits for the builder, such as assets/kaykit/dungeon (glTF); git ignores it
tools/pasdoc_check.py            checks the PasDoc comments and that sources are ASCII
docs/licences-required.md        what each third-party part asks of a release
```

`src/lib/Sprite3DAnimFrames.pas` is the one unit not in Sprite3D under that name: the two frame-source classes from Sprite3D's `Sprite3DAnimCapture`, which `Sprite3DSweep` needs, without the off-screen capture built on them. `Sprite3DFolderDialog`, `Sprite3DOffscreen`, `Sprite3DBackground` and `Sprite3DResample` are Sprite3D's, unchanged. `Sprite3DAssetCache` is new: the content keys and the cache's metadata files.

## Assets

Model kits live in `assets/`, off the repository root, one folder per kit: so far `assets/kaykit/dungeon`, KayKit's Dungeon Pack as glTF. Git ignores the whole folder, so each working copy brings its own kits. File, Open Asset Folder... starts there: the program looks for an `assets` folder beside itself and up to five folders above, so it finds the repository's when run from `src/Win64/Debug`.

## Settings

Settings are kept in `settings.json`, written by Neon, in a folder of Sprite3DBuilder's own, apart from Sprite3D's:

| Platform | Folder |
|---|---|
| Windows | `%APPDATA%\Sprite3DBuilder` |
| macOS | `~/Library/Application Support/Sprite3DBuilder` |
| Linux | `$XDG_CONFIG_HOME/Sprite3DBuilder`, or `~/.config/Sprite3DBuilder` |
| Android | the application's documents folder |
| iOS | `Library/Application Support/Sprite3DBuilder` |

What is kept: the View menu's ticks (bounding box, lights, projection), the camera view and the Variable view's angles, the shift, rise and distance when Variable asks for them to be kept, Mouse View's tick, the theme, the GPU choice, the view's frame rate, Minify JSON, the grid's spacing (`gridSize`, set by hand for now) and the asset folder last chosen (`assetFolder`).

## Themes

As Sprite3D's: the four FMX styles that come with RAD Studio (Dark, Aqua Graphite, Ruby Graphite, Golden Graphite), linked in as resources by the pre-build step `src/styles/buildstyles.cmd`, which also builds the licences' resource.

## Licences

What each third-party part asks of anyone who builds or distributes Sprite3DBuilder is set out in [docs/licences-required.md](docs/licences-required.md). The licences a release must carry are text files in `licences/`, linked into the program by `licences/Sprite3DLicences.rc` and shown by **File, Licences...**.

## Paths

Every file the application opens or writes goes through `OSFriendlyPath` in `common/OSPaths.pas` first, which gives it the platform's own delimiters.

## Known issues

- Nothing can be placed yet: the level is the grid alone. Dragging a thumbnail onto it is next.
- On macOS and iOS, where Gorilla3D draws through Metal, a thumbnail is a screenshot of the Assets form's view, as Sprite3D's grabs are there.
- The camera is fitted to the middle of the floor, 10 cells across, whatever is placed; it will frame the level once there is one.
- The camera view and View menu ticks are saved when the main form is destroyed, which Android and iOS do not always do before ending an application.
