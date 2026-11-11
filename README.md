# Sprite3DBuilder

Sprite3DBuilder is a Delphi FireMonkey application that will become a level builder for 3D model kits, such as KayKit's dungeon pack. It is built on [Gorilla3D](https://www.gorilla3d.de/) and grew out of [Sprite3D](https://github.com/peardox/Sprite3D): it keeps Sprite3D's view, camera, model loading and settings, and leaves out everything Sprite3D has for making sprites (grabs, icons, exports, the Results tab, backgrounds, projects and the debug tools).

It starts with an empty level: a floor grid at the kit's spacing, ready to build on. File, Library... holds your collections of models, each shown as thumbnails in groups; dragging them onto the level comes next.

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
- **File, Library...** opens the **Library** (see *Library*). At start it opens by itself, on the collection open last, if there are any collections. Desktop only: Android and iOS have no folder dialog to add collections with.
- **File, Clear Library...** deletes the whole library, after asking: the database (`library.db`) and the `thumbnails` folder with everything in it, so every collection, its groups and every thumbnail go. The model files themselves are never touched. The Library is then empty, ready to add collections again. Desktop only, as the Library is.
- **View, Camera.** Variable (a dialog with dials for the angles, distance, shift and rise), fixed views (Isometric, Pixel 2:1, 1/4 View, 3/4 View, Sqrt(2), Golden Ratio, Head On, Top Down, Side View), Lock Camera, and Mouse View (left-drag turns, the wheel zooms, a right click puts the normal view back).
- **View, Lights.** The camera's headlight and a second light on the camera, each on or off.
- **View, Projection.** Perspective, orthographic, and the oblique cavalier, cabinet, military and plan oblique projections, drawn by Spritely.
- **View, Show bounding box** will box each piece placed.
- **Debug tab**, always there: what was chosen, what went wrong and what changed.
- **File, Settings...**: theme, the view's frame rate, minified JSON and, on Windows, the graphics processor.
- **File, Licences...**: the third-party licences, from the program's own resources.

On Android and iOS the menu is a drawer opened from a button at the top; on Linux it is an FMX menu bar, as GTK's native one showed only first letters.

## Library

The Library holds artists, and under each artist their collections: sets of models, each from one or more folders (not their sub-folders), arranged in groups, such as *Kaykit Dungeon*. The top bar chooses the artist shown, each listed with how many collections they have and how many models in them all (a collection is listed with its model count, or *not imported yet*); **...** beside it renames or deletes the artist (with their collections, from the library only), and **Add Artist...** adds one. A collection with no artist, such as those of before artists, goes under *Unassigned*; a collection's **...** menu has **Move to Artist** to put it under another.

A new user has none, so the first thing to do is **Add Artist...** then **Add New Asset Collection...**, at the top right of the second bar, which adds a collection to the artist shown: choose its folder, usually the root of the pack, starting in the `assets` folder (see *Assets*) or where the last was chosen, then give it a name. The folder and every folder below it are searched for models. Packs often hold the same models in several formats, each in its own folder (KayKit's Dungeon Pack has `gltf`, `fbx`, `fbx(unity)` and `obj`): if models are found in more than one folder or format, **Choose Folders to Import** lists them, each with its format and count, and ticks those of your *preferred format* (remembered), leaving out a folder that repeats the models of one already ticked; tick what you want. If there is only one, it is just added. A collection remembers each folder with the format taken from it.

The drop-down at the top left chooses the collection shown; **...** beside it renames it or deletes it from the library (its models, folders and thumbnails stay).

**Add Artist Collections...**, on the artist bar, makes many at once: choose a folder holding packs, such as everything one artist has made, and each folder directly inside it becomes a collection, named after it, under the artist shown. So to put a product line (KayKit, say) under its maker, **Add Artist...** the maker first, then choose the product line's folder. With no artist shown, or *Unassigned*, the folder chosen becomes the artist, named after it (or adds to the artist of that name).

The first one asks which format you want, and that becomes the default for the rest; a pack with the default format just gets it, engine copies left out. A pack with none of your formats so far asks again: *Import* takes the format you choose as your next default (so glTF first, then FBX, and so on), *Skip* passes it over and turns down the formats it offered, so a later pack with only those (FBX only, say, when you want glTF) is passed over without asking, and a format skipped is not offered again, *Only My Defaults* passes over it and every later one like it, *Stop* ends there.

Packs with no models, or named as a collection you have already, are passed over. Then every new collection is imported in full, one after another, its folders read and its thumbnails made, the status line saying which of how many; this can take a while for a big folder. At the end the first is shown, with a summary of what was done. Choosing another collection or closing the Library stops it there; the rest are imported as each is opened. (Adding folders to an existing collection will come with drag and drop.)

The Library writes what it does to `library-import.log` in the settings folder, each model's load and thumbnail grab timed, so after a hang the last lines say which model it was on; each artist import starts it afresh. A thumbnail grab that has not come back after 4 seconds is started again, and after three tries the model is passed over, without one, and the import goes on with the next (not while the Library is minimised, when nothing is drawn). If the program is stopped while a model is loading or shown (ended from Task Manager after a hang, say), that model is passed over from then on: it is listed in `library-skipped.txt` beside the log, and taking it out of that file (or deleting the file) tries it again.

**Rescan** reads its folders again for models added, changed or removed. A collection otherwise opens straight from what was saved, without reading its folders.

A collection shows every model as a 128 x 128 thumbnail. The groups are down the left, a button each with its icon above its name and how many models it has; clicking one, or Up and Down, chooses it, and it stays chosen until another is. Its thumbnails fill the right. A model's group is the first word of its name, before the first underscore (`wall_corner` is in *wall*), with a plural group such as *crates* put with *crate* when both are there, unless it has been moved.

Groups nest, as folders do. Drag a group into the grid and it goes inside the group shown; onto a group's tile in the grid or a button on the left, inside that one; below the buttons, back to the top. The left shows the top groups; the groups inside the one shown are tiles at the start of its grid, opened with a double-click, and the bar above the grid shows where you are, with *Up* (or Backspace) to go up. A right-click on the grid adds a group inside the one shown. Group names are unique at every level, and a group's count takes in the groups inside it. *Delete Group* needs it to have no models and no groups inside.

The view at the top left says *Model Preview* while it has no model to show.

Thumbnails are picked as files are: click, Control-click to add or take one away, Shift-click for a run. Dragging a picked thumbnail onto another group moves every picked model there. Groups are in alphabetical order, case ignored, at every level. A drag held at the top or bottom edge of the groups or the grid scrolls it. A right-click on the groups opens a menu: *Add Group...*, *Rename Group...*, *Change Icon...*, and *Delete Group* for a group with no models anywhere. (Placing a model on the level, next, will take one at a time.)

A group's icon is the one chosen for it, or else an icon of the library named after the group (`wall.svg` or `wall.png`), or else its first model's thumbnail. The library is `icons/groups` beside the program or above it (the repository's), then the user's own, `icons/groups` beside `settings.json`, where an icon chosen from anywhere else is copied. Icons are PNG, or SVG drawn as filled shapes, such as those of [game-icons.net](https://game-icons.net); an SVG is drawn in one light colour. The icons in the repository are placeholders drawn by `tools/make_group_icons.py`.

A collection's groups, where each is, their icons and which models are in each are its palette. The library, every collection (its folders and formats, models and palette) and every model's metadata are kept in one SQLite database, `library.db` beside `settings.json`, through FireDAC, so everything comes back next time; collections are written in one transaction. FireDAC's SQLite driver is in every edition of RAD Studio, Community included, with SQLite linked into the program on Windows and macOS and the system's used elsewhere; SQLite is public domain. The JSON files of before the database are moved into it as they are come upon: `library.json` and `collection-<id>.json` the first time the Library opens (renamed `.moved`), each model's `.json` as it is first read (deleted). The one `palette.json` of before the library became the collection *Kaykit Dungeon* and was renamed `palette.json.moved`.

Clicking a thumbnail shows its name, group, size in its own units and file, and, once every thumbnail has been made, the model itself in the view at the top left, in the thumbnails' view, over a checker (which stands for transparency, as in Sprite3D) and with a floor grid at the level's grid spacing at the model's own floor (Y = 0), one line through its centre of rotation: a model that is raised above the floor, sunk into it, or off the grid shows it there, as it will when placed. Neither is ever in a thumbnail. Dragging across the view turns it, dragging up and down tilts it, the wheel zooms, and a right-click (or Control-click) puts the thumbnails' view back. While thumbnails are being made, the view shows each model as it is made.

Each model is known by a key: the SHA-256 of its file and of every file it names (for glTF, the `uri` of its buffers and images), so a copy of a model in another folder is the same model, and any change to it, its `.bin` or its textures makes a new one. Two files with the same key are shown once, and the Debug tab says so.

Thumbnails are made the first time a model is seen, one at a time, in the form's own view: loaded, turned upright, shown in the view for a moment, framed as Sprite3D frames a model, in the isometric view in orthographic projection: the volume its box sweeps turning about the up axis through its centre of rotation is fitted, with the camera's target on that axis, and grabbed off screen with a transparent background, as Sprite3D's grabs are.

They are kept in a `thumbnails` folder beside `settings.json`, as `<key>.png`, in two levels of folders named after the key's first two digits (`3/f/3fa9....png`), so no folder holds more than a share of them. Each model's metadata goes in the database: its name, group, the file it was found as, the files it names, its bounding box (in its own units, so kits made at other scales can be told apart and scaled later), and how and when the thumbnail was made. The next time, every model already in the cache is shown at once. A thumbnail of another size than 128 is made again, so changing the size remakes them.

While they are being made, the status line counts them and, after the first few, says about how long is left. Closing the form stops making them; opening the collection again carries on.

File, Clear Library... starts again from nothing. As each thumbnail is made, the Debug tab gets a line with the model's box and the camera's distance and orthographic height, to check a thumbnail by.

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
icons/groups/                    group icons for the Library (placeholders, made by the script below)
tools/pasdoc_check.py            checks the PasDoc comments and that sources are ASCII
tools/make_group_icons.py        draws the placeholder group icons (needs Pillow)
docs/licences-required.md        what each third-party part asks of a release
```

`src/lib/Sprite3DAnimFrames.pas` is the one unit not in Sprite3D under that name: the two frame-source classes from Sprite3D's `Sprite3DAnimCapture`, which `Sprite3DSweep` needs, without the off-screen capture built on them. `Sprite3DFolderDialog`, `Sprite3DOffscreen`, `Sprite3DBackground` and `Sprite3DResample` are Sprite3D's, unchanged. `Sprite3DAssetCache` is new: the content keys and the cache's metadata files.

## Assets

Model kits live in `assets/`, off the repository root, one folder per kit: so far `assets/kaykit/dungeon`, KayKit's Dungeon Pack as glTF. Git ignores the whole folder, so each working copy brings its own kits. Add New Asset Collection... starts there: the program looks for an `assets` folder beside itself and up to five folders above, so it finds the repository's when run from `src/Win64/Debug`.

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
- On macOS and iOS, where Gorilla3D draws through Metal, a thumbnail is a screenshot of the Library's view, as Sprite3D's grabs are there.
- The camera is fitted to the middle of the floor, 10 cells across, whatever is placed; it will frame the level once there is one.
- The camera view and View menu ticks are saved when the main form is destroyed, which Android and iOS do not always do before ending an application.
