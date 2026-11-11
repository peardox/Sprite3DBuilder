# Sprite3DBuilder: handover notes for Claude

Everything Claude needs to pick this project up in a new conversation: how
the owner works, the rules for the code, and where the work has got to.
`README.md` describes the program for its users and developers; this file
is for Claude. Read both.

Last updated: 11 November 2026, 05:30.

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

### Handover (11 November 2026, 05:30)

Read this first; the dated entries below it are the history.

- **GitHub `main` is at `e15caac`** ("obj import woes"), which is
  **Builder3zf** exactly (checked file by file). The zips after it, not
  yet pushed, each following the one before: **Builder3zg** (folder
  dialogs start at the last folder chosen, or the nearest one above it
  still there, never the assets folder; Clear Library keeps the last
  folder and preferred format; grab poll every 50 ms), **Builder3zh**
  (log header gives the build time; StateText counts each queued step),
  **Builder3zi** (the fix for OBJ grabs stalling: `PostStep`/`Poll` in
  `Sprite3DOffscreen`). The owner tested 3zi: "this is looking better".
  The next zip follows Builder3zi. Zip names after `3z` go `3za`, `3zb`,
  ...; Builder4 is kept for placing models on the level.
- **The Library is done for now** (owner). Artists above collections,
  counts in the bars, 128 x 128 tiles, artist import into the artist
  shown, Skip turning formats down, the import log and the skip list.
- **Open items, for later, in no order:**
  - An FBX import issue the owner saw and left for later; ask what it was.
  - Kenney names models with hyphens (`blaster-a`), so `AssetGroupName`,
    which splits at the first underscore, gives one group per model;
    split at hyphens too.
  - Speed: the fixed 120 ms settle before each grab (`THUMBNAIL_SETTLE_MS`)
    could be one drawn frame now that grabs come back promptly.
  - Why OBJ grabs (and only OBJ) lost their queued steps is not known;
    `Poll` gets round it. If stalls come back, the log line after
    `not back after 4 s` says where (`polled n times, m with something
    to run`).
  - `src/lib/Sprite3DOffscreen.pas` came from Sprite3D and now differs
    from its copy there (`StateText`, `Poll`, `PostStep`); port back if
    Sprite3D wants it.
  - The import log (`library-import.log`), the loading marker and
    `library-skipped.txt` live in the settings folder
    (`%APPDATA%\Sprite3DBuilder` on Windows).
- **Next: Builder4**, below.

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
  framed as Sprite3D frames a model (Builder3c, owner 23:25, comparing
  `bar_innercorner` with Sprite3D's: cut off and off-centre before):
  `FitCameraToSweep(FCamera.Camera, FModel, CalcSweptVolume(FModelBox,
  FModel.RotationCenter.Point, saY), W, H, 0.06)`, i.e. the camera's
  `FitPointsOnAxis`, target on the turning axis. `FModelBox` is
  `LoadModelFile`'s box, before the upright turn. Builder3a's even box with
  `FitToBounds(ABox, ASpace, ...)` and Builder3b's camera stand-off are
  gone. `TSprite3DOffscreen` at `THUMBNAIL_SIZE` (256), transparent. Each
  thumbnail logs its box, distance and ortho height to the Debug tab.
  Builder3d (owner 23:33): each model is on screen `THUMBNAIL_SETTLE_MS`
  (120) before its grab (`FSettleTimer`), so the view shows it and it has
  been drawn once; groups in `GroupsList` (TListBox, left,
  `GroupsSplitter`), the chosen group's tiles on the right (`LayoutTiles`
  hides the rest; `FEntries` in name order, never resorted, so indices in
  tiles and the queue hold); dragging a tile onto a group item moves it
  (`MoveToGroup`; "New group..." asks with `TDialogService.InputQuery`);
  once the queue is empty, the selected
  model is previewed in the viewport (`ShowPreview`) with a mouse view on
  `PreviewArea`: drag turns (azimuth) and tilts (polar angle, all the
  way round), wheel zooms (ortho height), right or Control-click resets. Group from
  `AssetGroupName`, plurals merged with their singulars, unless chosen
  (`GroupChosen`). Closing it stops the queue. `MakeNextLater` is a
  1 ms `FNextTimer` (an anonymous `TThread.ForceQueue` and an anonymous
  `TDialogService.InputQuery` close proc would not compile here, E2250);
  the new-group name comes back through the method overload
  (`NewGroupClosed`). It logs to the Debug tab through `OnLog`.
  Builder3i (owner 00:05, 00:09): FMX drag and drop (`BeginAutoDrag`)
  crashed Windows' drag session (class not found,
  dragdropsession_initialize) and dropped nowhere, so the drags are the form's own: tiles
  and group items have `AutoCapture`, a move of `TILE_DRAG_START` starts
  the drag, `FDragGhost` (the thumbnail, 72 px) follows a tile,
  `GroupItemAt` (`ItemByPoint`) finds the item under the pointer and
  `SetDropItem` marks it (a `TRectangle` in each item's `TagObject`), and
  the mouse-up drops. FMX drag and drop works if started properly (owner
  00:11, the FMX.DragAndDrop sample: from mouse-down), but is Windows and
  macOS only and hands the drag loop to the system, so it is not used
  here. Group items are
  40 high, text 15. Dragging a group onto another puts it before that one,
  onto "New group..." last; clicking "New group..." makes an empty group;
  right or Control-click on a group with no models anywhere removes it.
  Anything that rebuilds `GroupsList` from one of its own handlers goes
  through `Defer` / `DeferredWork` (`FDeferTimer`), so no item is freed in
  its own event. The palette (`FGroupOrder`, `FPaletteGroups` key to
  group, for every model ever seen, not just this folder's) is loaded in
  `HashesDone`, gets every model of the folder and new groups (sorted)
  last, and is saved by `SavePalette` after every change; `BuildGroups`
  lists a group if the folder has models in it or it has none anywhere,
  so other kits' groups are kept but hidden.
- `src/lib/Sprite3DAssetCache` (new): `TSprite3DAssetHasher` (SHA-256 of
  the model file, then, for `.gltf`, each buffer and image `uri` and that
  file's digest, digests kept per hasher so a shared texture is read once),
  `TSprite3DAssetMeta`, `SaveAssetMeta` (through a `.tmp`),
  `LoadAssetMeta` (checks every value; format `Sprite3D asset`, version 1),
  `ClearAssetCache` (Builder3b: deletes only `<64 hex>.png`, `.json` and
  `.json.tmp`, so the palette stays), `LoadAssetPalette` and
  `SaveAssetPalette` (Builder3i, replacing Builder3d's `groups.json`,
  which can be deleted: `palette.json`, format `Sprite3D asset palette`,
  version 1, `groups`: an array of `name` and `models`, the keys in
  order; `TSprite3DPaletteGroup`). JSON while it is worked on; the owner
  wants BSON in the long run (`System.JSON.BSON`), and only those two
  functions know the format.
- File, **Clear Thumbnails** (Builder3b, owner 23:09; desktop only, freed
  on mobile with Open Asset Folder): asks with `TDialogService`, then
  `TAssetsForm.ClearThumbnails` (reopens `FFolders` if showing) or, before
  the form exists, `ClearAssetCache` directly.
- Cache: `TSprite3DAppSettings.ThumbnailFolder`, `thumbnails` beside
  settings.json, `<hash>.png` and `<hash>.json`. The metadata's `file` is
  where the model was when its thumbnail was made.
- Back from Sprite3D, unchanged: `Sprite3DOffscreen`, `Sprite3DBackground`,
  `Sprite3DResample`.

Files deleted by Builder2 (`git rm`): `src/lib/Sprite3DAxes.pas`,
`src/lib/Sprite3DOpenFiles.pas`, `src/ui/Sprite3DBuilderLoadForm.*`,
`src/ui/Sprite3DBuilderNameClashForm.*`,
`src/ui/Sprite3DBuilderAnimationsUsedForm.*`.

Builder3a runs (owner's screenshot of the Assets form, 22:59; pushed as
"Debug", 23:09, with the IDE's `.dproj`, `src/Sprite3DBuilder.res` and
`licences/Sprite3DLicences.res`). Some thumbnails were wrong: `coin` blank,
`floor_foundation_allsides` cut at the top, the half-cell pieces
(`floor_foundation_diagonal_corner`, `floor_tile_small_corner`) to one
side; their glTF bounds are all even about the origin across, and the
half-cell pieces really are half a cell. After Builder3c (Sprite3D's sweep
fit) the same few seemed to stay bad (owner 23:33), hence the
preview in Builder3d; with Builder3e and the cache cleared every thumbnail
is right (owner 23:50): the bad ones had been the old cache. Slow (the
120 ms settle per model among it) but a one-time import, which the owner
accepts. Builder3f: the unused `TMainForm.UpdateView` removed (H2219).
Builder3g: the preview's turn was backwards (owner 23:55); it now adds the
pointer's move to the camera's Azimuth, as the main form's mouse view does.
Builder3h: the tilt is no longer held to +-89; it goes right round, kept in
0..360 by `Wrap360` (owner 00:01: the orbital camera's gimbals have no lock).
Builder3i: the palette and the form's own drags; see the Assets form above.
Builder3j (owner 00:27-00:29): `GroupsList` (TListBox; its hover was
disliked) replaced by `GroupsBox` (TVertScrollBox) of group buttons
(`FGroupTiles`, TRectangle, `GROUP_TILE_HEIGHT` 66: icon 32 above
"name (count)"); a click chooses (fill), Up/Down in `FormKeyDown` (scroll
boxes `CanFocus` False so the form gets the keys); the drop target gets an
outline only during a drag. "New group..." is gone: `GroupMenu`
(TPopupMenu, opened by hand from mouse-up, right or Control-click) has Add
(after the group clicked), Rename (case-insensitive clash refused),
Change Icon (`IconDialog`; an icon from outside the libraries is copied
into `UserGroupIconsFolder`) and Delete (only with no models anywhere).
Thumbnails multi-pick (`Picked`; click, Control, Shift run from `FAnchor`;
a plain press on a picked one keeps the picks until mouse-up, so they can
be dragged together); the drag ghost shows the count; `MoveEntries`.
Group reorder: drop on a group = before it, below all = last
(`GroupTileAt`'s `ABelow`), still through `Defer`. Icons: palette groups
gained `icon` (a plain file name; `TSprite3DPaletteGroup.Icon`); lookup
`IconFile`: `TSprite3DAppSettings.UserGroupIconsFolder`
(SupportFolder/icons/groups) then `GroupIconsFolder` (icons/groups beside
or above the exe, as `AssetsFolder` looks); default `<group>.svg/.png`,
else the group's first thumbnail. New lib unit `Sprite3DGroupIcons`:
`LoadGroupIcon` (PNG as is; SVG: every `path d` filled in one colour in
viewBox units, a full-view-box background square skipped, so
game-icons.net style). `icons/groups/*.png`: 40 placeholders drawn by
`tools/make_group_icons.py` (ours, no licence). The owner suggested a
large free vector icon library: game-icons.net (CC BY 3.0, needs credit in
docs/licences-required.md and the licences resource if shipped) is the
fit; it cannot be downloaded from here.
Builder3k (owner 01:04): "Model Preview" (`FPreviewLabel`, over the
viewport, shown while `FModel` is nil; `UpdatePreviewLabel` from
`FreeModel` and `LoadEntryModel`). Nested groups: `FGroupParents` (lower-
case group -> parent name; root has none), palette groups gained `parent`
(`TSprite3DPaletteGroup.Parent`; a missing parent or a loop is dropped in
`HashesDone`, walks bounded by `Length(FGroupOrder)`). Names stay globally
unique, so `FPaletteGroups` and `Meta.Group` are unchanged. Left bar: top
groups only, count = `FolderTotal` (with the groups inside); chosen mark on
`RootOf(FGroup)`. Grid: `BuildFolderTiles` (inner groups first,
`FOLDER_FILL`, double-click via `ssDouble` opens, deferred `FOpenGroup`),
`TilesPanel` (outline = drop into the group shown), `PathBar` (`UpButton`,
`PathLabel`, Backspace). Group drags: `TrackGroupDrag` / `DropGroup`; from
a button onto a button = reorder at the top, from the grid onto a button =
inside it, onto a folder tile = inside it, onto the grid = inside the one
shown, below the buttons = top, last (`Reparent`, through `Defer`). Model
drags can drop on folder tiles too. Delete needs `GroupEmpty` (no models
anywhere, no inner groups); Add from the grid adds inside the one shown.
Builder3l (owner 01:33): groups alphabetical, case ignored, at every
level (`ChildGroups` sorts), so the reorder drag is gone: a group dropped
on a button or tile goes inside it, below the buttons to the top
(`FMoveGroup`/`FMoveBefore` removed). Drags auto-scroll: `FScrollTimer`
(40 ms) while dragging, `EdgeScroll` within 28 px of (or past) the top or
bottom of `GroupsBox` or `TilesBox`, faster further out; then the drop is
tracked again (`TrackTileDrag`, `TrackGroupDrag`); `BeginDrag` starts it,
`EndDrag` stops it. At start, `FormShow` queues `OpenLastAssets`
(`TThread.ForceQueue` with a method): if the cache has `palette.json` and
settings' `AssetFolder` still exists, the Assets form opens on it
(`OpenAssets`, also used by File, Open Asset Folder). Desktop only.
Builder3m (owner 01:52, answers 02:00): a Library above palettes. The
Assets form (`TAssetsForm`, caption "Library - <collection>") gained
`CollectionBar` along the top: `CollectionCombo` (open collection),
`CollectionMenuButton` "..." (`CollectionMenu`: Rename, Delete from the
library, files and thumbnails kept), `AddFolderButton`, `RescanButton`, and
`AddCollectionButton` "Add New Asset Collection..." (`SelectFolders`, then
a name; folder's name suggested). Lib: `TSprite3DAssetLibrary`
(`library.json`: collections id+name, `last`, `lastFolder`),
`TSprite3DAssetCollection` (`collection-<id>.json`: name, folders,
`scanned`, groups as the palette, `models` key+file), `NewCollectionId`
(GUID), `Load/SaveAssetLibrary`, `Load/SaveAssetCollection`,
`DeleteAssetCollection`; `SaveAssetPalette` gone, `LoadAssetPalette` only
reads the old `palette.json`, which `LoadLibrary` turns into "Kaykit
Dungeon" (folder = settings' `AssetFolder`, via `MigrationFolder`, not
scanned) when there is no library, then renames to `palette.json.moved`.
Owner chose: open from what was saved (`OpenCollection` feeds the saved
models to `HashesDone` with no hashing), scanning only when the
collection was never scanned or on Rescan/Add Folder (`ScanCollection`,
`FScanning` marks it scanned). `SavePalette` writes the whole collection.
Main: File, Open Asset Folder became File, **Library...** (`LibraryItem`,
`OpenLibrary`, `OpenLastLibrary` at start if the library has collections
or the old palette is there); `FAssetFolders`, `OpenAssets` gone; the
form's `OpenFolders` became `ShowLibrary` and private `ScanCollection`.
Builder3n (owner 02:09): users pick a pack's root, which holds the same
models in several formats (KayKit free: Assets/gltf, fbx, fbx(unity),
obj). Helpers: `TModelFolder` (Folder, Format ext, Count, Names),
`FindModelFolders` (recursive, one entry per folder and format),
`FoundModelFormats` (by `MODEL_FORMAT_PREFERENCE`: gltf, glb, fbx, dae,
usd*, obj, ply, stl), `DefaultModelFolders` (ticks the preferred format,
skipping a folder whose names are mostly already ticked: the engine
copy), `ModelFormatName`, `AssetModelFilesOf` (format filter). New dialog
`Sprite3DBuilderImportForm` (`TImportForm`, `ChooseModelFolders`: one
folder taken without asking, several asked, modal, checkbox list,
preferred-format combo). Collections hold `Sources`
(`TSprite3DCollectionSource`: folder + formats; JSON `sources`, old
`folders` read as every format); the library holds `PreferredFormat`.
`ChooseSources` in the Library form for Add New Asset Collection and Add
Folder; `ScanCollection` scans each source with its formats.
Builder3o (owner 02:37): the owner now tests from a data drive of
thousands of assets; the assets folder is to go soon. Add Folder removed
from the Library (to come back as drag and drop). Library wider (1120)
with `Constraints` 960 x 640. **Add Artist Collections...**
(`AddArtistButton`, `AddArtistButtonClick`): each folder directly inside
the folders chosen becomes a collection named after it (skipped if the
name is taken, or no models); an ordered list of default formats grows as
it goes: the first folder asks (`Sprite3DBuilderFormatForm`, `AskFormat`:
Import / Skip / Only My Defaults / Stop), a folder with a default takes
the first one it has without asking (`DefaultModelFolders` leaves engine
copies out), one with none asks again (Import appends a default). Made
with `NewCollection` (also used by Add New Asset Collection), not scanned
until first opened; the first is opened; summary message at the end;
`Defaults[0]` becomes the library's `PreferredFormat`.
`Progress` is shown only while reading folders or making thumbnails (owner
02:38: it stayed full after an import).
Builder3p (owner 02:39): time left while making thumbnails: `FMakeWatch`
(TStopwatch from the queue's start), shown after `ETA_AFTER` (3) made as
"about 1m 20s left" (`DurationText`), and the total time in the log.
Builder3q (owner 02:51): Add Artist Collections imports every collection
it makes in full, in one go, not when each is first opened: `FBulkQueue`
of new ids, `NextBulk` opens each (scan + thumbnails); `MakeNext`'s
end, when `FBulkTotal` > 0, sets `FBulkPending` and `Defer`s, and
`DeferredWork` calls `NextBulk`; status prefixed by `BulkPrefix`
("Collection 3 of 12, name: "); at the end the first is opened and the
summary shown. `StopBulk` when another collection is chosen, the Library
closes, or a new artist import starts.
Builder3r (owner 02:55): thumbnail and metadata files go in
`AssetKeyFolder` = `<cache>/<key[0]>/<key[1]>/` (256 folders at most);
`LoadAssetMeta` first moves a key's flat files from the top
(`MoveFlatFiles`); `ClearAssetCache` walks every folder (only key files
in their own key folder or at the top), then removes empty key folders;
the form makes the key folder before saving a thumbnail.
Builder3s (owner 02:58-03:01, Enterprise; FireDAC SQLite is in
Community/Professional too): one SQLite database, `library.db` in the
settings folder (`AssetDatabaseFile` = parent of the cache folder), all in
`Sprite3DAssetCache`, same public functions as before, now DB-backed via
FireDAC (static SQLite on Windows/macOS through
`FireDAC.Phys.SQLiteWrapper.Stat`, `FireDAC.FMXUI.Wait`), one
`TFDConnection` per database file (`Databases`, main thread only, freed at
finalization), WAL, `PRAGMA user_version` = `ASSET_DATABASE_VERSION` (1).
Tables: `library` (one row: last_id, last_folder, preferred_format),
`collections` (id, name, position, scanned), `sources` (collection_id,
position, folder, formats space-separated), `palette_groups`
(collection_id, position, name, icon, parent), `group_models`
(collection_id, group_position, position, model_key), `models`
(collection_id, position, model_key, file), `meta` (model_key, name, grp,
file, files newline-separated, min/max x/y/z, thumb_width/height,
thumb_view, created). Names avoid SQLite keywords (groups, key, view,
last). `SaveAssetCollection` replaces the collection's rows in one
transaction (new ones go last by position); `SaveAssetLibrary` upserts
names and positions. Migration: `LoadAssetLibrary` on an empty `library`
table moves `library.json` + `collection-*.json` in (renamed `.moved`);
`LoadAssetMeta` moves a key's `.json` in when the DB lacks it (then
deletes it). `ClearAssetCache` = files + `DELETE FROM meta`. JSON writers
gone; JSON readers kept private as `ReadLegacy*`; BSON plan dropped.
Builder3t: `GroupMenuSeparator` declared (sync + verify, owner 03:08).
Builder3u (owner 03:13): File, Clear Thumbnails became **Clear Library...**
(`ClearLibraryItem`, warning dialog): `ClearAssetLibrary` closes and drops
the connection, deletes `library.db` (+ -wal, -shm, -journal) and the
whole cache folder recursively; `TAssetsForm.ClearLibrary` (was
`ClearThumbnails`) stops everything first, then shows the library empty
(no migration afterwards: `FLibraryLoaded` stays True). `ClearAssetCache`
is kept in the unit but nothing calls it now.
Builder3v (owner 03:19): the preview has Sprite3D's checker
(`FBackground`, TSprite3DBackground, Transparent, 16 px squares; 2D behind
the viewport, never in grabs) and a floor grid (`FPreviewGrid`,
TModelGrid, child of the preview's `FModel`, `GridLevel` 0 = the model's
own floor, `GridSize` = the level's, set by the main form through
`TAssetsForm.GridSize`, `SetExtent` from `FModelBox` and the centre of
rotation), made only in `ShowPreview`, so never while a thumbnail is made.
Builder3w (owner 03:36): `THUMBNAIL_SIZE` 128
(older ones remade as met). **Artists** above collections: lib
`TSprite3DArtist` (Id GUID, Name), `TSprite3DAssetLibrary.Artists`,
`LastArtist`, `TSprite3DLibraryEntry.ArtistId`,
`TSprite3DAssetCollection.ArtistId`; DB version 2: table `artists` (id,
name, position; rewritten as listed by `SaveAssetLibrary`), columns
`collections.artist_id`, `library.last_artist` (ALTER TABLE from 1). Form:
`ArtistBar` above `CollectionBar` (`ArtistCombo`, `ArtistMenuButton` ->
`ArtistMenu` Rename/Delete (deletes their collections from the library),
`NewArtistButton` "Add Artist...", `AddArtistButton` "Add Artist
Collections..." moved here); `CollectionCombo` lists only the artist's
(`FShownCollections`); Add New Asset Collection needs an artist and adds
to it; collection names unique per artist; artist import: the chosen
folder's name is the artist (`EnsureArtist`); `AssignOrphans` puts
artist-less collections under "Unassigned" (`UNASSIGNED_ARTIST`);
`CollectionMenu` gained **Move to Artist** (sub-menu rebuilt on open,
`MoveToArtistClick`). Owner: this is the Library done for now; next is
placing on the level, Builder4.

Builder3x (owner 03:51): the owner added the artist Kay Lousberg and
imported his KayKit folder, which made an artist KayKit (the product
line). Artist import now puts its collections under the artist shown
(`BulkArtist`); only with none shown, or Unassigned, is the chosen
folder's name the artist (`EnsureArtist`). The folder picker's title says
which. The preview grid not showing was a scan in progress (`ShowPreview`
does nothing while `Making`), not a fault.

Builder3y (owner 04:00): counts in the bars. Lib:
`TSprite3DLibraryEntry` gained `Models` and `Scanned`, read by
`LoadAssetLibrary` (a sub-select counts `models` rows per collection),
never written by `SaveAssetLibrary`. Form: `ArtistText` ("Name  (n
collections, n models)"), `CollectionText` ("Name  (n models)" or "(not
imported yet)"), `CountText`; `SavePalette` updates the entry and calls
`FillCollections` when the count or Scanned changed. Both combos 380 wide.

Builder3z (owner 04:06): tiles show thumbnails at their own size:
`TILE_IMAGE = THUMBNAIL_SIZE` (128), `TILE_WIDTH` = +8 (136),
`TILE_HEIGHT` = +28 (156); group tiles' icon box `TILE_IMAGE - 20`.

Builder3za (owner 04:26, Kenney's 50 packs, 4 FBX-only, wanted glTF):
artist import's Skip now turns down the formats the pack offered
(`Rejected`); a later pack whose formats are all turned down is passed
over without asking. `AskFormat` texts say so.

Builder3zb (owner 04:39, Kenney's OBJs hung on one model): import log and
hang guard. `Log` also writes to `library-import.log` (settings folder,
`ImportLogFile`, `DebugLog` opens/appends/closes per line so a hang
leaves it whole; deleted at the start of each artist import).
`LoadEntryModel` logs "loading <file> (bytes)" and "loaded in n ms",
`SettleTimerTimer` "grabbing". While a model is in the viewport its file
is named in `library-loading.txt` (`LoadingFile`, deleted by
`FreeModel`); `ShowLibrary` -> `LoadSkipped` moves one left there into
`library-skipped.txt` (`SkipFile`, `FSkipped`, `IsSkipped`), and
`LoadEntryModel` passes those over (thumbnail and preview). Next: read the
owner's log to see why the model hangs.

Builder3zc (owner 04:44): it was not a hang: the progress stopped but the
window still closed, so a grab never came back (Sprite3D imported the same
OBJs fine). `FGrabTimer` (`GRAB_TIMEOUT_MS` 15000), started after
`FOffscreen.Grab`, stopped by `ThumbnailGrabbed`/`StopMaking`:
`GrabTimerTimer` logs it, `FOffscreen.Cancel`, passes the model over (not
added to the skipped list) and goes on; minimised, it waits. Log lines
"grabbed an image"/"grabbed nothing: ...". Still to find: why the grab of
that model never returns.

Builder3zd (owner 04:48): the IDE refused README.md ("One or more lines
were too long and have been truncated"): the Library paragraph had grown
to 4138 characters. Split into paragraphs. **Keep every line of every
file well under 1000 characters**; add a new paragraph rather than
lengthen one.

Builder3ze (owner 04:52): a skipped format was still offered by the next
pack that had others too. Artist import now asks only about `Offered`,
the pack's formats less `Rejected`.

Builder3zf (owner 04:57, log of Kenney OBJ): 4 of Blaster Kit's 40
(blaster-a, blaster-q, crate-medium, crate-wide) loaded in ~20 ms but
their grab never came back; one Brick Kit grab took 3.7 s then worked.
Looks intermittent, not the model. Lib: `TSprite3DOffscreen.StateText`
(busy, pending, stage, drawing, iterations, enabled, verifying, render
passes begun/ended since `Grab`: `FBeginRenders`/`FEndRenders`). Form:
`GRAB_TIMEOUT_MS` 4000, `GRAB_TRIES` 3, `FGrabTries`; `GrabTimerTimer`
logs `StateText`, cancels, invalidates the viewport and grabs again, then
passes over. Next: read StateText in the owner's log (passes ended 0 =
the viewport stopped drawing; ended > 0 with pending = HandleEndRender's
stage logic; not pending = the worker/queue).

Builder3zg (owner 05:08): the log answered it: every stalled grab was
"busy True, pending False, enabled True" with hundreds of render passes
ended, so the drawings were read and the worker started, but nothing
queued for the main thread ran: not even ProcessDrawing's ForceQueue that
switches the pass off (enabled still True). The viewport drawing every
frame starves FMX's idle, where `CheckSynchronize` runs; the timer firing
let it through (each retry came back in ~30 ms). Fix: `FGrabTimer` polls
every `GRAB_POLL_MS` (50) and calls `CheckSynchronize`; `FGrabWatch`
times each try against `GRAB_TIMEOUT_MS`. Sprite3D never sees it as it
grabs once, on demand. Also: folder dialogs no longer fall back to the
assets folder (`StartFolder` climbs to the nearest folder still there,
else empty), and `ClearLibrary` keeps `LastFolder` and `PreferredFormat`.

Builder3zh (owner 05:15): the next log looked the same (stalls of 4 s,
"pending False, enabled True", retry fine in ~30 ms); not known whether it
was a 3zg build. The log header now gives the program's build time.
`StateText` also counts ProcessDrawing's queued switch-offs run, workers
begun/ended, results run and Deliver steps run (`FSwitchOffs`,
`FWorkerStarts`, `FWorkerEnds`, `FResultRuns`, `FDeliverRuns`); the form
adds how often `GrabTimerTimer` ran `CheckSynchronize` and how often it
found something (`FPumps`, `FPumpsUseful`).

Builder3zi (owner 05:21, 3zh log, OBJ only; FBX and glTF fine): every
stall was "switch-offs run 0, workers begun 1, ended 1, results run 0,
deliveries run 0; the queue run 64 times, 0 with something in it": the
worker finished and queued its result, yet `CheckSynchronize` found
nothing to run, so TThread's queue held the steps where the poll could not
reach them. Lib: every step `TSprite3DOffscreen` leaves for the main
thread now goes through `PostStep`: posted to a thread-safe list in the
shared alive flag (`IAliveFlag.Post`/`Take`, `TAliveFlag.FSteps`) and
also `TThread.ForceQueue`d to `RunSteps`; the new public `Poll` runs them
too, whichever comes first, each once. Form: `GrabTimerTimer` calls
`FOffscreen.Poll` instead of `CheckSynchronize`. Note: this unit came from
Sprite3D and now differs from its copy there (StateText, Poll); port back
if Sprite3D wants it.

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
