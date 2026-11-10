# Sprite3DBuilder: handover notes for Claude

Everything Claude needs to pick this project up in a new conversation: how
the owner works, the rules for the code, and where the work has got to.
`README.md` describes the program for its users and developers; this file
is for Claude. Read both.

Last updated: 10 November 2026, 23:10.

## Starting a new conversation

1. Clone the repository with its submodules:
   `git clone --recurse-submodules https://github.com/peardox/Sprite3DBuilder.git`
   (branch `main`). The submodules are `delphi-neon` and `FastMM5`.
2. Read the whole of `README.md`, then this file.
3. Sprite3DBuilder grew out of Sprite3D (<https://github.com/peardox/Sprite3D>),
   whose `CLAUDE.md` holds the history and the lessons behind the code kept
   here, and whose `notes/` explain the camera fit and the volumes
   (`volumes.md`). Spritely, the camera components, lives there too. Read
   those when touching the same code.
4. The owner's working copy is often ahead of GitHub. If the owner attaches
   or pastes files, build on those, not on GitHub.
5. Before delivering code, run `python3 tools/pasdoc_check.py` on the files
   you changed and fix anything it reports in your own changes.

Reference for the libraries used:

- Gorilla3D 1.5.4: <https://gorilla3d.de/doc/v3/version/v1.5>, with further
  notes at <https://peardox.com/G3D/>.
- Neon, the JSON serialiser: <https://github.com/paolo-rossi/delphi-neon>.
- FastMM5: <https://github.com/pleriche/FastMM5>.
- PasDoc: <https://pasdoc.github.io/>.

## How the owner works

- Delphi 13 (RAD Studio), FireMonkey. Develops on Windows; also builds and
  runs on macOS (Intel and Apple silicon, through PAServer) and Linux
  64-bit. Android and iOS are targets too.
- Works from a local copy and pushes to GitHub only when happy with the
  results.
- Tests promptly and pastes back the Debug tab, terminal output or
  screenshots. Logs are the main evidence, so make Debug tab lines say
  exactly what happened, and say in the reply what to look for.
- Likes plain explanations of why something behaves as it does, and
  measured numbers rather than guesses. Say plainly when an earlier
  conclusion was wrong.

### Delivering work

These rules apply to this repository as to the owner's others (brought in
line with peardox/SRDelphiFMX's on 8 November 2026).

- **Never supply patches or diffs.** The owner will not use them. Supply
  whole files.
- When supplying files as a zip, put **only the files new or changed since
  the previous zip** in it, with paths from the repository root, so it can
  be unzipped straight over the working copy. Give each zip a name, name
  the files in the reply, and say which earlier zip it follows or
  replaces.
- **Files to delete or rename** cannot travel in a zip: list them in the
  reply with the git commands (`git rm ...`, `git mv ...`).
- **Package rebuilds**: Spritely lives in the Sprite3D repository, not here. A change
  Sprite3DBuilder needs in Spritely is made and delivered there, under Sprite3D's
  rules, with its rebuild line.
- **Do not mention being unable to compile.** That is already known.
- **Do not mention that nothing is committed or pushed.** The owner pushes
  when ready. Do not commit or push unless asked. When a hook asks to
  commit and push, answer "Noted." and do nothing.
- No paths, user names, machine names or credentials in tracked files.
- Update `README.md`, and the design notes it links to, when a feature,
  setting or requirement changes, and this file when the state of the work
  or the rules change; include them in the zip when they do.
- **The generated help in `docs/` is the owner's**: they rebuild it with
  PasDoc only now and then, after a major milestone. Never change or
  regenerate it. The one hand-written file there,
  `docs/licences-required.md`, is kept up to date: change it, with the
  README's Licences, whenever a dependency, its licence or how it is
  shipped changes. The PasDoc comments in the source are still written
  with the code, ready for the next rebuild.
- When something needs testing, say what to try and what the result should
  look like, on which platforms.

## The repository

- Honour `.gitignore`, `.gitmodules` and the other `.git*` files. Never add
  build output or other ignored files.
- Neon and FastMM5 are submodules: never copy their sources into the
  project, and never change them.
- **Spritely is not here.** It is Sprite3D's: build and install its
  packages from Sprite3D's group project. Sprite3DBuilder uses the built
  package, whose DCUs go to Delphi's Dcp folder, so it needs no search path
  for them. No Spritely unit may use a Sprite3DBuilder one.
- The project is `src/Sprite3DBuilder.dproj`, alone in
  `Sprite3DBuilderGroup.groupproj`. A new unit goes in both the `.dpr`'s
  `uses` and the `.dproj`; keep the `.dproj` as it is otherwise (it has a
  UTF-8 byte order mark; keep it, and the `.groupproj`'s).
- `assets/`, off the root, holds the model kits the builder uses, one folder
  per kit (`assets/kaykit/dungeon`, glTF, so far); git ignores it (owner,
  10 November 2026, 21:59). Never add anything from it.
- `tools/` holds scripts for working on the source, such as
  `pasdoc_check.py`. They are not part of the program.
- `docs/licences-required.md` is hand-written: change it, with the README's
  Licences, whenever a dependency, its licence or how it is shipped changes.

### Layout

- `src/lib`: reusable units, **independent of the application**. They must
  not use anything in `src/ui`, and must not know about the main form,
  `settings.json` keys or menus. They are copies of Sprite3D's units of the
  same names, changed only where Sprite3D's off-screen pass was left out
  (`Sprite3DSweep`) or its licences were (`Sprite3DLicences`);
  `Sprite3DFolderDialog`, `Sprite3DGrid`, `Sprite3DOffscreen`,
  `Sprite3DBackground` and `Sprite3DResample` are unchanged;
  `Sprite3DAssetCache` is Sprite3DBuilder's own;
  `Sprite3DAnimFrames` holds the two frame-source classes from Sprite3D's
  `Sprite3DAnimCapture` that `Sprite3DSweep` needs. Keep them close to
  Sprite3D's, so fixes can be carried either way, and say when a fix here
  is one Sprite3D needs too.
- `src/common`: small helpers shared across projects (`OSPaths`,
  `JsonText`, `GpuPreference`, `DisplayData`), unchanged from Sprite3D.
- `src/ui`: the forms and the application's own rules. Non-visual
  application logic (settings, the assets folder, themes) goes in
  `Sprite3DBuilderHelpers.pas`, not in a form.
- `src/styles`: the theme styles, compiled into a resource by the
  pre-build event `buildstyles.cmd`, which also builds `licences/`.

## Code rules

### Names and trademarks

- **Peardox is the owner, not a product.** The products are Sprite3DBuilder,
  Sprite3D and Spritely.
- **No trademarks in names, UI, logs, comments or docs** (owner,
  8 November 2026): describe what a thing is, never name it after a
  product or game that used it (Spritely's projection kinds are named for
  the projection). Names of the libraries used (Gorilla3D, Neon, FastMM5)
  and of the platforms are fine. A model kit's name (KayKit) is fine in
  conversation and in the README's notes on testing, never in code names.

### Cross-platform

- The program targets Windows (64-bit and ARM64EC; Gorilla3D, and so
  Spritely, for ARM64EC from 8 November 2026), macOS (Intel and
  Apple silicon), Linux 64-bit, Android (32 and 64-bit) and iOS. **Keep it
  cross-platform as far as possible.** Windows 32-bit is built only to
  make the design-time packages for the owner's 32-bit IDE; nothing is
  released for it (owner, 9 November 2026), so a Win32-only concern
  matters only for what runs in the IDE at design time.
- No platform-specific unit or call without `{$IF}` alternatives for the
  other platforms, so every platform still compiles. The conditions used
  are `MSWINDOWS`, `MACOS`, `IOS`, `ANDROID` and
  `{$IF DEFINED(LINUX) and not DEFINED(ANDROID)}` for desktop Linux.
  Remember that macOS and iOS both define `MACOS`.
- Desktop-only features (file dialogs, right-click, Open With) need a
  mobile alternative or are left out there, and the README says so.
- Prefer pure Pascal to native libraries that need deploying; there are
  none.
- Calls into the Objective-C runtime on macOS go through `objc_msgSend`
  declared with the exact argument types of each call, as in
  `Sprite3DTitleBar`. Apple silicon needs this; never call it through a
  variadic declaration.

### Files and paths

- **Every path the program opens or writes goes through `OSFriendlyPath`**
  (`common/OSPaths.pas`) first. Some Windows targets, such as ARM64EC,
  reject `/`, and paths kept in `settings.json` may be read on another
  system.
- Per-user files go in the settings folder (`AppDataFolder` in
  `Sprite3DStorage`, `TSprite3DAppSettings.SupportFolder`), never beside
  the executable.
- Write files that matter atomically where practical: write a temporary
  file, then move it into place, as `TSprite3DJsonSettings.Save` does.
- Saves that take time run on worker threads (see *Threads*); the main
  form waits for them as it closes (`FSaveTasks`).

### JSON and settings

- Sprite3DBuilder keeps Neon for `settings.json`, as Sprite3D does.
  SRDelphiFMX's rule of `System.JSON` and no Neon is for Spritely, which
  must not depend on Neon.
- `settings.json` is read and written by **Neon**, through
  `TSprite3DJsonSettings` (`lib/Sprite3DStorage.pas`) and its descendant
  `TSprite3DAppSettings` (`ui/Sprite3DBuilderHelpers.pas`). A new setting is a
  published property there, with a default set in the constructor, a
  `[NeonProperty('...')]` attribute where its key differs from what Neon
  makes of the name, and a row in the README's table of what is kept.
  Settings must survive a file without the key (old files), keeping the
  default.
- Other JSON (metadata, directions files, animation settings, project
  files, caches) is built with `System.JSON` objects and written through
  `JsonToText` or `JsonToBytes` (`common/JsonText.pas`), so File,
  Settings, Minify JSON applies to every file. Never format JSON by hand.
- When reading JSON from outside (files the user picks, downloads), check
  every value's type and range; a bad file must give a clear message, not
  an access violation.

### Threads

- Gorilla3D, FMX controls and the viewport are touched **only on the main
  thread**. Worker threads (`TTask`) do pure work, such as reading a model
  file ahead of Gorilla3D's load (`StartModelFileRead`).
- Hand results back with `TThread.Queue` (or `ForceQueue` when already on
  the main thread but inside a render or event that must finish first).
- Anonymous methods capture variables, not values. When queuing from a
  loop, pass the values to a method as parameters instead of capturing the
  loop variables.
- Long-running work can be aborted, and the form waits for anything still
  writing a file before it closes, so no file is left half written.

### Menus

- The main menu is `MainMenu1` in `Sprite3DBuilderMain.fmx`. On Android and iOS
  it is shown through a hamburger drawer built from it
  (`BuildMobileMenu`), so menu items added in code must be in place before
  that runs. On desktop Linux it is replaced by an FMX `TMenuBar`
  (`UseFmxMenuBar`), **first thing in `FormCreate`**. Both recurse, so a
  third menu level (View, Projection, Oblique) is copied too.
- **Linux: copy, never move.** GTK's native menu bar shows only the first
  letter of each item, so the items are copied onto a `TMenuBar`, the
  originals freed one at a time, `MainMenu1` freed, and each copy given its
  original's name so the form's fields point at it. Moving the original
  items, or freeing `MainMenu1` with items still in it, gives
  `Gtk-CRITICAL` warnings, a crash in `libgobject-2.0.so.0`, or GTK's bar
  of first letters still showing. Read the comment above `UseFmxMenuBar`
  before touching it.
- So: reach designed menu items only through the form's published fields;
  never keep a reference to one taken before the swap; add run-time items
  after it, through the published fields (`ModelMenu.InsertObject(...)`).
  `CopyItem` copies `Text`, `Enabled`, `Visible`, `AutoCheck`,
  `IsChecked`, `RadioItem`, `GroupIndex`, `ShortCut`, `Tag`, `Hint` and
  `OnClick`. If a `TMenuItem` in the `.fmx` starts using any other property
  (`Bitmap`, `Action`, `StyleLookup`, another event), add it there.
- FMX unticks only a radio item's siblings, so a radio group spread over
  two menu levels (Projection and its Oblique submenu) is ticked by hand:
  `CheckProjection` ticks one and unticks the other five.
- Any other form that gains a `TMainMenu` needs the same swap on Linux.

### User interface

- Forms must not have their own `StyleBook`, so the theme set through
  `TStyleManager` reaches them. Colours a control paints for itself must
  read well on the light default and the dark themes.
- To add a theme: put the `.style` file name in `buildstyles.cmd`'s list,
  add an `RCDATA` line to `src/styles/Sprite3DThemes.rc`, then a value to
  `TSprite3DTheme` and its row in `THEMES` in `Sprite3DBuilderHelpers.pas`.
- FMX lays out controls with the same `Align` (all `Top`, say) in the order
  of their positions. When adding or resizing one, set `Position` so they
  stay in order (`Position.Y := -1` puts a top-aligned control first).
- Dialogs: Android cannot block on a modal form, so a dialog that must work
  there uses the callback form, `ShowModal(procedure(AResult:
  TModalResult) ...)`, as Sprite3D's Exact and Overscan warnings do. Plain
  `ShowModal` is only for desktop-only features.
- Start-up is quick on purpose: `FormCreate` builds, `FormShow` queues the
  first model load so the window is drawn first. Keep new start-up work out
  of the way of that, and never open a dialog
  on top of the loading dialog.
- Problems, results and anything the owner may need to paste back go in
  the Debug tab (`DebugMemo`), whether or not a dialog also says so.
- `Format` in Delphi has no `+` flag: a signed number is written with
  `FormatFloat` and a three-part format such as `'+0.00;-0.00;+0.00'`
  (`SIGNED_FORMAT` in `Sprite3DBuilderOrbitalForm`).

### Documentation in the code

- **Document all code in PasDoc format.** The help is built with
  `pasdoc --staronly --auto-abstract`, so only `//**` comments reach
  PasDoc. Every unit, type, constant, field (private ones included),
  method and property gets a `//**` comment immediately before it,
  starting with `@abstract(...)` where it needs more than one line, and
  using `@param`, `@returns`, `@raises`, `@code` and `@link` as needed.
  - Fields declared one after another may share one comment.
  - Attributes such as `[NeonProperty('...')]` may sit between the comment
    and the item.
  - `@link` only to items declared in this project; write inherited or
    library items (`ShowModal`, `TGorillaModel`) with `@code`, as PasDoc
    cannot resolve them.
  - Escape brackets in PasDoc text as `@(` and `@)`.
  - Nested routines and items declared only in the implementation are
    documented too, with `//**` like the rest, though PasDoc does not
    publish them.
- Each unit starts with its `//**` description, then `unit Name;`, then the
  same description again as a plain `{ }` block comment for people reading
  the source. Keep the two in step.
- Comments explain **why** as well as what, especially where code works
  round a bug or a platform quirk, so nobody "simplifies" it back.
- Older code has gaps (mostly private methods and fields with no comment
  or a plain `//` one), most of them in `Sprite3DBuilderMain.pas`. Code you write
  or change must be clean; fill the gaps in a unit you are working on when
  it is cheap to do so, and offer a clean-up pass rather than doing one
  unasked. Do not add to the gaps.

### Source files

- **Source files are ASCII only.** Delphi reads a file without a byte order
  mark as ANSI, so write characters such as the degree sign as character
  codes (`#176`, `#$00B0`), in comments too spell them out ("degrees").
  A file that already has a UTF-8 byte order mark (the `.dproj` and
  `.groupproj` files) keeps it.
- Line endings and indentation as in the file being edited (two spaces).
- Naming: fields `F`, parameters `A`, types `T`; units in `src/lib`
  `Sprite3D*.pas`, under the same names as Sprite3D's copies (a new one may
  be `Sprite3DBuilder*.pas`); the application's units in `src/ui`
  `Sprite3DBuilder*.pas`, forms `Sprite3DBuilder*Form.pas` with their
  `.fmx`. Types keep Sprite3D's `TSprite3D...` names in both, so code moves
  between the two repositories unchanged.
- Delphi requires every field of a class section before its first method
  or property (E2169).

### Checking the source

`tools/pasdoc_check.py` checks the units in `src/lib`, `src/common` and
`src/ui` and the `.dpr`:

```
python3 tools/pasdoc_check.py                      every unit
python3 tools/pasdoc_check.py src/ui/Sprite3DBuilderMain.pas   just these files
python3 tools/pasdoc_check.py --summary            counts per file
```

It reports files that are not ASCII, units with no `//**` `@abstract`,
interface items with no comment or only a plain `//` one, unbalanced
`@tag(...)` brackets, `@link` targets that do not exist, and fields after a
method or property (E2169). It is a heuristic, not a parser. The only
problems it should report are the older gaps described above; run
`--summary` before and after a change to see that the counts have not
gone up.

## Gorilla3D and FMX notes

- Gorilla3D renders through OpenGL on Windows, Linux and Android, and
  Metal on macOS and iOS. On Metal a material's SurfaceShader is not
  supported, so `Sprite3DGrid` draws the grid there as one thin plane per
  line, 20 cells each side, without the fade.
- There is no background: the viewport's own colour, with the floor grid in
  the scene. Sprite3D's 2D background behind a transparent viewport, and its
  off-screen pass, were left out.
- A Gorilla3D model is only posed while it can be drawn, so measuring an
  animation's volumes shows the model being measured (Sprite3D's
  `notes/volumes.md`). Sprite3DBuilder measures none: every model is shown
  in its rest pose, and `Sprite3DSweep`'s animation measurer, with
  `Sprite3DAnimFrames`, is kept only for when animations come back.
- The azimuth, as Sprite3D's, as the readouts and the fixed views give it, is 0
  at south and grows clockwise seen from above (45 is south-west,
  Isometric); `ApplyAngles` reverses it for the camera, and the mouse
  view's readout runs the same way as the dials.
- Lessons from StereoModel, where Spritely was built: load a model by
  making it (`TGorillaModel.Create(Viewport)`) and calling its
  `LoadFromFile`, as Sprite3DBuilder does, never the class function
  `TGorillaModel.LoadNewModelFromFile`, which in 1.5.3 never frees the FBX
  loader's parse tree; the viewport sends its free notification before it
  frees its children, so a component must let go of the camera and light
  on that notice and never touch them again (`TSpritelyOrbitalCamera`
  does); `MakeScreenshot` shows the `RenderManual` before the last, so
  render twice before a screenshot that must show a change; FMX's
  perspective is D3D-style (depth 0..1) with NDC y up, and a projection
  written into the context stays until FMX makes it again (resize, lens
  change).
- With `REPORT_LEAKS` defined in the `.dpr`, FastMM5 on Windows writes the
  full leak report to `Sprite3DBuilder_MemoryManager_EventLog.txt` beside
  the executable. A leak introduced by a change shows up there.

## Where the work is

### State (10 November 2026, 22:30)

GitHub `main` is at `3da83fa`, "First commit": **Builder1** as delivered
(the cut-down of Sprite3D at its `f678433`). Since then, as zips:

**Builder2** (22:30; owner, 22:09-22:13), follows Builder1:

- **No models are opened any more.** File, Open Model, the Models menu
  (Models Used), the Models list side panel with Clear, drag-and-drop, files
  the system asks to open (`Sprite3DOpenFiles`, the single-instance hand-off)
  and the whole load pipeline in the main form (load dialog, timer, slots,
  name clash) are gone, with `Sprite3DBuilderLoadForm`,
  `Sprite3DBuilderNameClashForm`, `Sprite3DBuilderAnimationsUsedForm` and
  `Sprite3DAxes`. `LoadModelFile`, `StartModelFileRead` and `IsModelFile` stay
  in the Helpers, for the pieces to come. Settings lost `startupAction`,
  `lastModel`, `showAxes`, `showSweptVolume` and `showCombinedSweptVolume`,
  and the Settings dialog its Startup group.
- **An empty level at start-up.** `BuildLevel` makes `FLevel`, a `TDummy` in
  the viewport turned 180 degrees about X (so Y is up inside it, as in the
  kits, with the floor at Y = 0), and `FGrid`, a `TModelGrid` on it at
  `gridSize` (new setting, default 2, by hand only). The camera is fitted to
  `ViewVolume`: 10 cells across and 2 high, swept about the centre.
  `PlaceModel` and its centring are gone.
- **View** keeps Camera, Lights, Projection and Show bounding box, which
  boxes each `TGorillaModel` under `FLevel` (none yet).
- **File, Open Asset Folder...** (owner's name for it, 22:13): the folder
  dialog (`Sprite3DFolderDialog`, copied from Sprite3D) opens in
  `assetFolder` (new setting) or `AssetsFolder`, an `assets` folder found
  beside the program or up to five folders above; the folders chosen go in
  `FAssetFolders` and their models, by `AssetModelFiles`, are listed in the
  Debug tab. They will open on a second form the owner is about to design.
  Freed on Android and iOS, which have no folder dialog.

**Builder3** (22:55; owner, 22:41: thumbnails of every model of the asset
folder, in groups, cached by a content hash below settings.json; dragging
onto the view is stage two, Builder4), follows Builder2:

- `src/ui/Sprite3DBuilderAssetsForm` (`TAssetsForm`, caption Assets): made
  by the main form the first time a folder is opened (`FAssetsForm`, owned
  by it), shown non-modally. `OpenFolders` hashes the models on a worker
  thread (`TSprite3DAssetHasher`), shows the cached ones at once and makes
  the rest one at a time in its own `TGorillaViewport` (256 square, top
  left) with its own `TSpritelyOrbitalCamera`: model upright (X 180),
  isometric (inclination 35.264, camera azimuth 315), orthographic,
  `FitToBounds` with a 6% margin on the model's own box from
  `LoadModelFile` made even in X and Z about its `RotationCenter`
  (Builder3a, owner: centred on the centre of rotation), `TSprite3DOffscreen` at `THUMBNAIL_SIZE`
  (256), transparent. Tiles laid out by hand (`LayoutTiles`), headings per
  group (`AssetGroupName`, plurals merged with their singulars), clicking
  selects. Closing it stops the queue. It logs to the Debug tab through
  `OnLog`.
- `src/lib/Sprite3DAssetCache` (new): `TSprite3DAssetHasher` (SHA-256 of
  the model file, then, for `.gltf`, each buffer and image `uri` and that
  file's digest, digests kept per hasher so a shared texture is read once),
  `TSprite3DAssetMeta`, `SaveAssetMeta` (through a `.tmp`),
  `LoadAssetMeta` (checks every value; format `Sprite3D asset`, version 1).
- Cache: `TSprite3DAppSettings.ThumbnailFolder`, `thumbnails` beside
  settings.json, `<hash>.png` and `<hash>.json`. The metadata's `file` is
  where the model was when its thumbnail was made.
- Back from Sprite3D, unchanged: `Sprite3DOffscreen`, `Sprite3DBackground`,
  `Sprite3DResample`.

Files deleted by Builder2 (`git rm`): `src/lib/Sprite3DAxes.pas`,
`src/lib/Sprite3DOpenFiles.pas`, `src/ui/Sprite3DBuilderLoadForm.*`,
`src/ui/Sprite3DBuilderNameClashForm.*`,
`src/ui/Sprite3DBuilderAnimationsUsedForm.*`.

None of the zips compiled yet. Things to watch at the first compile: anything
left behind by the cuts, and the `.dproj`, made from Sprite3D's with its
deployment of `dlls/` and its project outputs removed (the IDE adds its own
outputs back). The project's `.res` (`src/Sprite3DBuilder.res`) is not in
the repository; the IDE makes it.

**Next, Builder4:** dragging a thumbnail from the Assets form onto the
level, with a bounding box showing where it will go, snapped to the grid,
and the model placed under `FLevel` on release. Kits of other scales:
the metadata keeps each model's raw box, so a scale per kit can be worked
out later from a reference piece.

### Test kit

KayKit Dungeon Pack 1.1 (FREE), CC0, attached by the owner (21:46); the
owner has a more complete version. 211 models, each as glTF, FBX, FBX for
Unity and OBJ, sharing one texture; no animations in the glTF files. From
their glTF bounds: the grid unit is **2** (small floor tiles 2 x 2, large
4 x 4, extra-large grates 8 x 8); walls are 4 wide, 4 tall and 1 thick.
Pieces are centred on their origin in X and Z; floor tiles' tops are at
about Y = 0.05 and walls stand on Y = 0, so a piece snaps by its origin to
the grid's points.
