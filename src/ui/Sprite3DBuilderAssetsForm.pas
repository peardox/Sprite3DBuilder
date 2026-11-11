//** @abstract(The Library: the user's collections of models, each shown as thumbnails in
//** groups, with a 3D preview of the one selected.)
//**
//** File, Library calls ShowLibrary. The library (LoadLibrary) lists collections, each a set of
//** models from one or more folders with its own palette of groups; CollectionBar chooses the
//** one shown, adds a new one (folders, then a name), adds many at once, rescans it, and
//** renames or deletes it. A collection opens from what was saved (OpenCollection); its folders
//** are read only when it has never been, or on Rescan (ScanCollection), which
//** finds every model in them (AssetModelFiles). Their keys, the SHA-256 of each model's content
//** (TSprite3DAssetHasher, from Sprite3DAssetCache), are worked out on a worker thread, as that
//** is only reading files. A model whose key the thumbnail cache knows, with a thumbnail of
//** THUMBNAIL_SIZE, is shown from the cache at once; every other one is queued, and its
//** thumbnail made, one model at a time: loaded into the form's own viewport, turned upright,
//** framed in a fixed isometric view in orthographic projection as Sprite3D frames a model, left
//** on screen for THUMBNAIL_SETTLE_MS so the viewport has drawn it, and grabbed off screen by a
//** TSprite3DOffscreen at THUMBNAIL_SIZE square, with a transparent background. The PNG and the
//** model's metadata, its bounding box among it, go into the cache, so the next time the folder
//** is opened nothing need be made. Two files with the same key are one model: the second is
//** noted in the log and not shown again.
//**
//** The groups are down the left, in GroupsBox, one button each: its icon above its name and
//** how many models it has. Clicking one, or Up and Down, chooses it, and its thumbnails fill
//** the right, in name order. A group's icon is the one chosen for it from the icon library
//** (GroupIconsFolder, then the user's own, TSprite3DAppSettings.UserGroupIconsFolder), or
//** else the library's icon named after the group, or else the thumbnail of its first model.
//** A right-click on the groups opens GroupMenu: Add Group, Rename Group, Change Icon and,
//** for a group with no models anywhere and no groups inside, Delete Group.
//**
//** Groups nest, as folders do, and are in alphabetical order, case ignored, at every level.
//** A group dragged into the grid goes inside the group shown, dragged onto a group's tile
//** or button, inside that one, and dragged below the buttons, back to the top. A drag held
//** at the top or bottom edge of the groups or the grid scrolls it. The left shows the top
//** groups; the groups inside the one shown are tiles at the start of its grid, opened with
//** a double-click; PathBar shows where the group shown is, and UpButton, or Backspace, goes
//** up. A right-click on the grid adds a group inside the one shown. Names are unique at
//** every level. Counts take in the groups inside.
//**
//** A model's group is the one the palette gives it, or else AssetGroupName of its name, with
//** a plural group put with its singular when the folder has both. Thumbnails are picked as
//** files are: a click picks one, Control and a click adds or takes one away, Shift and a
//** click picks the run from the last one clicked. Dragging a picked thumbnail onto a group
//** moves every picked model there. The drags are the form's own, with the mouse
//** captured, not FMX's drag and drop, which hands over to the system's and is not on every
//** platform the program is built for. The groups, where each is, with their icons and the
//** key of every model in each, are the palette, kept in the cache (LoadAssetPalette), so the
//** arrangement comes back next time; groups of other kits are kept in it but not shown.
//**
//** Clicking a thumbnail also shows its name, group, size in its own units and file, and,
//** once every thumbnail is made, the model itself in the viewport at the top left, in the
//** thumbnails' view to start with. Dragging across the viewport turns it, up and down tilts
//** it, right round if need be, the wheel zooms, and a right-click puts the thumbnails' view
//** back. While thumbnails are being made, the viewport shows each one as it is made.
//**
//** Dragging a thumbnail onto the level is the next step; it is not here yet, and will take
//** one model at a time.
//**
//** Closing the form stops making thumbnails; those made so far stay in the cache, and opening
//** the collection again carries on from there. Everything the form has to report goes to OnLog,
//** for the Debug tab. For the main thread only, but for the hashing, which keeps to its own
//** data and hands back its results with @code(TThread.Queue).
//**
//** @preformatted(
//** TAssetsForm
//** |-- CollectionBar     CollectionLabel, CollectionCombo, CollectionMenuButton,
//** |                     RescanButton, AddArtistButton, AddCollectionButton
//** |-- GroupsBox         TVertScrollBox, left: a button per group, made in code
//** |-- GroupsSplitter
//** |-- TopLayout
//** |   |-- PreviewArea     dark grey; the TGorillaViewport, made in code, fills it
//** |   `-- InfoLayout      StatusLabel, Progress, NameLabel, SizeLabel, FileLabel, HelpLabel
//** |-- TilesPanel          outlined while a group dragged would go into the one shown
//** |   |-- PathBar         UpButton, PathLabel
//** |   `-- TilesBox        TVertScrollBox
//** |       `-- FTilesLayout  made in code: the inner groups' tiles, then every model's;
//** |                         the chosen group's shown
//** |-- GroupMenu         TPopupMenu: AddGroupItem, RenameGroupItem, IconGroupItem,
//** |                     DeleteGroupItem
//** |-- CollectionMenu    TPopupMenu: RenameCollectionItem, DeleteCollectionItem
//** `-- IconDialog        TOpenDialog, for Change Icon
//** )
unit Sprite3DBuilderAssetsForm;

{
  The Library: the user's collections of models, each shown as thumbnails
  in groups, with a 3D preview of the one selected.

  File, Library calls ShowLibrary. Each collection is a set of models from
  one or more folders with its own palette of groups; CollectionBar chooses
  the one shown, adds one or many at once, rescans, renames or deletes
  it. A collection opens from what was saved; its folders are read only
  when it has never been, or on Rescan (ScanCollection),
  which finds every model in them (AssetModelFiles). Their keys, the
  SHA-256 of each model's content (TSprite3DAssetHasher, from
  Sprite3DAssetCache), are worked out on a worker thread, as that is only
  reading files. A model whose key the thumbnail cache knows, with a
  thumbnail of THUMBNAIL_SIZE, is shown from the cache at once; every other
  one is queued, and its thumbnail made, one model at a time, in the form's
  own viewport, and grabbed off screen with a transparent background. The
  PNG and the model's metadata go into the cache.

  The groups are down the left, in GroupsBox, one button each: its icon
  above its name and how many models it has. Clicking one, or Up and Down,
  chooses it, and its thumbnails fill the right. A group's icon is the one
  chosen for it from the icon library, or the library's icon named after
  the group, or the thumbnail of its first model. A right-click on the
  groups opens GroupMenu: Add Group, Rename Group, Change Icon and, for a
  group with no models anywhere, Delete Group.

  Groups nest, as folders do: dragged into the grid, a group goes inside the
  one shown; onto a group's tile, inside that one; below the buttons, back
  to the top. Inner groups are tiles at the start of the grid, opened with
  a double-click; PathBar shows the path, and Up or Backspace goes up.

  Thumbnails are picked as files are: click, Control-click, Shift-click.
  Dragging a picked thumbnail onto a group moves every picked model there.
  Groups are in alphabetical order at every level; a drag held at the edge
  of the groups or the grid scrolls it. The drags are the form's own, with
  the mouse captured, not FMX's drag and drop. The groups, with their icons
  and their models' keys, are the palette, kept in the cache, so the
  arrangement comes back next time.

  Clicking a thumbnail also shows its details and, once every thumbnail is
  made, the model itself in the viewport, which the mouse turns, tilts and
  zooms. Closing the form stops making thumbnails. Everything the form has
  to report goes to OnLog. For the main thread only, but for the hashing.

    TAssetsForm
    |-- CollectionBar     the collection drop-down and the library's buttons
    |-- GroupsBox         TVertScrollBox, left: a button per group, made in code
    |-- GroupsSplitter
    |-- TopLayout
    |   |-- PreviewArea     dark grey; the TGorillaViewport, made in code, fills it
    |   `-- InfoLayout      StatusLabel, Progress, NameLabel, SizeLabel, FileLabel, HelpLabel
    |-- TilesPanel          outlined while a group dragged would go into the one shown
    |   |-- PathBar         UpButton, PathLabel
    |   `-- TilesBox        TVertScrollBox
    |       `-- FTilesLayout  made in code: the inner groups' tiles, then the models'
    |-- GroupMenu         TPopupMenu: AddGroupItem, RenameGroupItem, IconGroupItem,
    |                     DeleteGroupItem
    |-- CollectionMenu    TPopupMenu: RenameCollectionItem, DeleteCollectionItem
    `-- IconDialog        TOpenDialog, for Change Icon
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math.Vectors,
  System.Generics.Collections, System.Diagnostics,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.Types3D, FMX.Menus, FMX.Dialogs, FMX.ListBox,
  Gorilla.Viewport, Gorilla.Model, Gorilla.Camera, Spritely.OrbitalCamera,
  Sprite3DOffscreen, Sprite3DAssetCache;

type
  //** @abstract(Receives a line for the log; see TAssetsForm.OnLog.)
  //**
  //** @param(AText The line.)
  TAssetsLogEvent = reference to procedure(const AText: String);

  //** @abstract(One model's key, the files it names, and why it has none, as the hashing
  //** worker hands them back.)
  TAssetHashResult = record
    //** @abstract(The model file, as a full path.)
    FileName: String;
    //** @abstract(Its key; empty if Error is set.)
    Hash: String;
    //** @abstract(The files it names; see TSprite3DAssetHasher.HashModel.)
    Files: TArray<String>;
    //** @abstract(Why there is no key; empty if there is one.)
    Error: String;
  end;

  //** @abstract(One model shown on the form: its metadata, its tile, and whether its
  //** thumbnail is there yet.)
  TAssetEntry = record
    //** @abstract(Its metadata, from the cache or as its thumbnail is made.)
    Meta: TSprite3DAssetMeta;
    //** @abstract(Its tile in FTilesLayout; nil until the tiles are made.)
    Tile: TRectangle;
    //** @abstract(The image on Tile showing the thumbnail.)
    Image: TImage;
    //** @abstract(True once the thumbnail is in the cache and on Tile.)
    HasThumbnail: Boolean;
    //** @abstract(True if Meta.Group came from the palette, so it is not merged with
    //** another.)
    GroupChosen: Boolean;
    //** @abstract(True while the thumbnail is picked, to be dragged with the others picked.)
    Picked: Boolean;
  end;

  //** @abstract(Says whether the form is still there, for work handed back from another
  //** thread.)
  IAssetsAlive = interface
    ['{6C2B0E5A-3D41-4E8B-9A7F-1B5C8D2E4F60}']
    //** @abstract(True until the form is freed.)
    //**
    //** @returns(Whether the form is still there.)
    function Alive: Boolean;
    //** @abstract(Marks the form as gone.)
    procedure Kill;
  end;

  //** @abstract(What GroupNameClosed is answering: a new group, or a new name.)
  TGroupNameAsk = (
    //** @abstract(Nothing asked.)
    gnNone,
    //** @abstract(Add Group: the new group goes after FMenuGroup, or last.)
    gnAdd,
    //** @abstract(Rename Group: FMenuGroup's new name.)
    gnRename,
    //** @abstract(Add New Asset Collection: the name of the collection of FNewSources.)
    gnNewCollection,
    //** @abstract(Rename Collection: the open collection's new name.)
    gnRenameCollection);

  //** @abstract(The Assets form; see the unit's description.)
  TAssetsForm = class(TForm)
    //** @abstract(Along the top: the collection open, and what can be done to the library.)
    CollectionBar: TLayout;
    //** @abstract(Says "Collection".)
    CollectionLabel: TLabel;
    //** @abstract(The library's collections; choosing one opens it.)
    CollectionCombo: TComboBox;
    //** @abstract(Add New Asset Collection...: folders, then a name, for a new collection.)
    AddCollectionButton: TButton;
    //** @abstract(Add Artist Collections...: a collection for each folder in the folders
    //** chosen, named after it.)
    AddArtistButton: TButton;
    //** @abstract(Rescan: the collection's folders read again, for models added, changed or
    //** gone.)
    RescanButton: TButton;
    //** @abstract(Opens CollectionMenu.)
    CollectionMenuButton: TButton;
    //** @abstract(Rename and Delete for the collection open.)
    CollectionMenu: TPopupMenu;
    //** @abstract(Rename Collection...)
    RenameCollectionItem: TMenuItem;
    //** @abstract(Delete Collection: from the library; its models and thumbnails stay.)
    DeleteCollectionItem: TMenuItem;
    //** @abstract(The groups, down the left: a button per group, made by BuildGroups.)
    GroupsBox: TVertScrollBox;
    //** @abstract(Between GroupsBox and the rest, to widen the groups.)
    GroupsSplitter: TSplitter;
    //** @abstract(The strip along the top: PreviewArea and InfoLayout.)
    TopLayout: TLayout;
    //** @abstract(Dark grey behind the viewport made in FormCreate, which fills it; it takes
    //** the mouse for the preview.)
    PreviewArea: TRectangle;
    //** @abstract(Right of PreviewArea: the status, the progress and the selected model's
    //** details.)
    InfoLayout: TLayout;
    //** @abstract(What the form is doing: reading the folder, making thumbnails, or done.)
    StatusLabel: TLabel;
    //** @abstract(How far making the thumbnails has got; shown only while a collection's
    //** folders are being read or its thumbnails made.)
    Progress: TProgressBar;
    //** @abstract(The selected model's name and group.)
    NameLabel: TLabel;
    //** @abstract(The selected model's size, in its own units.)
    SizeLabel: TLabel;
    //** @abstract(The selected model's file.)
    FileLabel: TLabel;
    //** @abstract(How to use the preview, the thumbnails and the groups.)
    HelpLabel: TLabel;
    //** @abstract(Holds PathBar and TilesBox; outlined while a group dragged over it would
    //** go into the group shown.)
    TilesPanel: TRectangle;
    //** @abstract(Above the tiles: UpButton and PathLabel.)
    PathBar: TLayout;
    //** @abstract(Goes up to the group the one shown is inside.)
    UpButton: TButton;
    //** @abstract(The group shown, with the groups it is inside, from the top.)
    PathLabel: TLabel;
    //** @abstract(Scrolls the chosen group's groups and tiles.)
    TilesBox: TVertScrollBox;
    //** @abstract(The groups' right-click menu.)
    GroupMenu: TPopupMenu;
    //** @abstract(Add Group...: a new empty group after the one clicked, or last.)
    AddGroupItem: TMenuItem;
    //** @abstract(Rename Group...: a new name for the group clicked.)
    RenameGroupItem: TMenuItem;
    //** @abstract(Change Icon...: an icon from the library, or any PNG or SVG, for the group
    //** clicked.)
    IconGroupItem: TMenuItem;
    //** @abstract(Delete Group: only for a group with no models anywhere.)
    DeleteGroupItem: TMenuItem;
    //** @abstract(Chooses a group's icon.)
    IconDialog: TOpenDialog;
    //** @abstract(Makes the viewport, its camera, the off-screen pass and the timers.)
    //**
    //** @param(Sender The form.)
    procedure FormCreate(Sender: TObject);
    //** @abstract(Lets go of everything still to come back: the hashing's results and a
    //** grab under way are dropped.)
    //**
    //** @param(Sender The form.)
    procedure FormDestroy(Sender: TObject);
    //** @abstract(Stops making thumbnails and hides the form.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Action Left as caHide, so the form is kept for the next folder.)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    //** @abstract(Up and Down choose the top group above or below; Backspace goes up to the
    //** group the one shown is inside.)
    //**
    //** @param(Sender The form.)
    //**
    //** @param(Key The key; set to 0 when taken.)
    //**
    //** @param(KeyChar The character.)
    //**
    //** @param(Shift The keys held.)
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar;
      Shift: TShiftState);
    //** @abstract(Lays the tiles out again for the new width.)
    //**
    //** @param(Sender TilesBox.)
    procedure TilesBoxResize(Sender: TObject);
    //** @abstract(A right-click on the space below the groups opens GroupMenu for no group;
    //** a group dropped there goes last.)
    //**
    //** @param(Sender GroupsBox.)
    //**
    //** @param(Button The button.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across GroupsBox.)
    //**
    //** @param(Y Where, down GroupsBox.)
    procedure GroupsBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(A right-click on the tiles' empty space opens GroupMenu to add a group
    //** inside the one shown.)
    //**
    //** @param(Sender TilesBox.)
    //**
    //** @param(Button The button.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across TilesBox.)
    //**
    //** @param(Y Where, down TilesBox.)
    procedure TilesBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Shows the group the one shown is inside.)
    //**
    //** @param(Sender UpButton.)
    procedure UpButtonClick(Sender: TObject);
    //** @abstract(Asks for a new group's name.)
    //**
    //** @param(Sender AddGroupItem.)
    procedure AddGroupItemClick(Sender: TObject);
    //** @abstract(Asks for the group's new name.)
    //**
    //** @param(Sender RenameGroupItem.)
    procedure RenameGroupItemClick(Sender: TObject);
    //** @abstract(Chooses the group's icon with IconDialog, in the icon library.)
    //**
    //** @param(Sender IconGroupItem.)
    procedure IconGroupItemClick(Sender: TObject);
    //** @abstract(Deletes the group, if it has no models anywhere.)
    //**
    //** @param(Sender DeleteGroupItem.)
    procedure DeleteGroupItemClick(Sender: TObject);
    //** @abstract(Opens the collection chosen.)
    //**
    //** @param(Sender CollectionCombo.)
    procedure CollectionComboChange(Sender: TObject);
    //** @abstract(Chooses folders for a new collection, then asks its name.)
    //**
    //** @param(Sender AddCollectionButton.)
    procedure AddCollectionButtonClick(Sender: TObject);
    //** @abstract(Makes a collection of each folder directly inside the folders chosen, such
    //** as each pack in an artist's folder, named after it, in one go.)
    //**
    //** Each is searched for models (FindModelFolders). The first time, the user is asked
    //** which format to take (AskFormat), and that becomes the default; a folder with that
    //** format gets it, the engine copies left out (DefaultModelFolders), without asking. A
    //** folder with none of the defaults so far asks again: Import adds the format chosen as
    //** the next default, Skip passes it over, Only My Defaults passes over it and every later
    //** one like it, Stop ends there. A folder with no models, or the name of a collection
    //** already in the library, is passed over. Then each is imported in full, one after
    //** another (NextBulk): its folders read and its thumbnails made, the status saying which
    //** of how many. The first made is opened, and a summary shown, at the end. Choosing
    //** another collection or closing the Library stops it; the rest are imported as each is
    //** opened.
    //**
    //** @param(Sender AddArtistButton.)
    procedure AddArtistButtonClick(Sender: TObject);
    //** @abstract(Reads the collection's folders again.)
    //**
    //** @param(Sender RescanButton.)
    procedure RescanButtonClick(Sender: TObject);
    //** @abstract(Opens CollectionMenu under the button.)
    //**
    //** @param(Sender CollectionMenuButton.)
    procedure CollectionMenuButtonClick(Sender: TObject);
    //** @abstract(Asks the collection's new name.)
    //**
    //** @param(Sender RenameCollectionItem.)
    procedure RenameCollectionItemClick(Sender: TObject);
    //** @abstract(Asks, then takes the collection out of the library.)
    //**
    //** @param(Sender DeleteCollectionItem.)
    procedure DeleteCollectionItemClick(Sender: TObject);
  private
    //** @abstract(The form's own viewport, in PreviewArea, where thumbnails are drawn and
    //** the selected model shown.)
    FViewport: TGorillaViewport;
    //** @abstract(The viewport's camera, from the Spritely package, in orthographic
    //** projection with its headlight on; in the isometric view for every thumbnail.)
    FCamera: TSpritelyOrbitalCamera;
    //** @abstract(Grabs each thumbnail off screen, THUMBNAIL_SIZE square, transparent.)
    FOffscreen: TSprite3DOffscreen;
    //** @abstract(Starts each grab THUMBNAIL_SETTLE_MS after its model is loaded.)
    FSettleTimer: TTimer;
    //** @abstract(Runs MakeNext on a later main-loop turn; see MakeNextLater. Owned by the
    //** form, so it never fires once the form has gone.)
    FNextTimer: TTimer;
    //** @abstract(Does what a group button's own mouse handler asks for once the handler has
    //** returned, as it rebuilds the buttons; see DeferredWork.)
    FDeferTimer: TTimer;
    //** @abstract(The model in the viewport, whose thumbnail is being made or which is
    //** previewed; nil for none.)
    FModel: TGorillaModel;
    //** @abstract(FModel's bounding box in its own space, as LoadModelFile gave it, before
    //** it was turned upright.)
    FModelBox: TBoundingBox;
    //** @abstract(The entry FModel is the preview of; -1 if it is none, or is a thumbnail's.)
    FPreviewIndex: Integer;
    //** @abstract(The thumbnail cache, TSprite3DAppSettings.ThumbnailFolder, where the
    //** library and its collections are kept too.)
    FCacheFolder: String;
    //** @abstract(The library: every collection; read once, by LoadLibrary.)
    FLibrary: TSprite3DAssetLibrary;
    //** @abstract(True once LoadLibrary has run.)
    FLibraryLoaded: Boolean;
    //** @abstract(True from ScanCollection until its results are in, so HashesDone marks
    //** the collection scanned.)
    FScanning: Boolean;
    //** @abstract(The collection open; its Id is empty for none.)
    FCollection: TSprite3DAssetCollection;
    //** @abstract(The folders and formats chosen for a new collection, while its name is
    //** asked.)
    FNewSources: TArray<TSprite3DCollectionSource>;
    //** @abstract(True while FillCollections fills CollectionCombo, so its change is not a
    //** choice.)
    FFillingCollections: Boolean;
    //** @abstract(Backing field for MigrationFolder.)
    FMigrationFolder: String;
    //** @abstract(The group of every model the palette knows, key to group, in this folder
    //** or not; see SavePalette.)
    FPaletteGroups: TDictionary<String, String>;
    //** @abstract(The palette's groups in the user's order.)
    FGroupOrder: TArray<String>;
    //** @abstract(The icon chosen for each group, by the group's name in lower case: a file
    //** name in the icon library.)
    FGroupIcons: TDictionary<String, String>;
    //** @abstract(The group each group is inside, by the inner group's name in lower case;
    //** a group at the top has no entry. Names are unique across every level.)
    FGroupParents: TDictionary<String, String>;
    //** @abstract(The groups inside the one shown, with a tile at the start of the grid, in
    //** the palette's order.)
    FFolderNames: TArray<String>;
    //** @abstract(Their tiles, in FFolderNames' order; each one's Tag is its index.)
    FFolderTiles: TArray<TRectangle>;
    //** @abstract(Says "Model Preview" over the viewport while it shows no model.)
    FPreviewLabel: TLabel;
    //** @abstract(The icons loaded, by full path, so each is read once; the form's.)
    FIconBitmaps: TObjectDictionary<String, TBitmap>;
    //** @abstract(Counts the folders opened, so results for an earlier one are dropped.)
    FScanId: Integer;
    //** @abstract(Every model shown, in name order.)
    FEntries: TArray<TAssetEntry>;
    //** @abstract(The entries still to have their thumbnails made, first first.)
    FQueue: TArray<Integer>;
    //** @abstract(How many thumbnails this folder needed, for Progress.)
    FQueueTotal: Integer;
    //** @abstract(Times making the queue's thumbnails, for the time left.)
    FMakeWatch: TStopwatch;
    //** @abstract(The collections an artist import still has to import in full, by id.)
    FBulkQueue: TArray<String>;
    //** @abstract(How many collections the artist import under way made; 0 when none is.)
    FBulkTotal: Integer;
    //** @abstract(The first collection the artist import made, shown when it is done.)
    FBulkFirst: String;
    //** @abstract(What the artist import made and passed over, shown when it is done.)
    FBulkSummary: String;
    //** @abstract(True when DeferredWork is to go on to the next collection to import.)
    FBulkPending: Boolean;
    //** @abstract(The entry whose thumbnail is being made; -1 for none.)
    FMaking: Integer;
    //** @abstract(The entry selected, whose details and preview are shown; -1 for none.)
    FSelected: Integer;
    //** @abstract(Where a Shift-click's run of picked thumbnails starts; -1 for none.)
    FAnchor: Integer;
    //** @abstract(The group shown in the tiles; empty for none.)
    FGroup: String;
    //** @abstract(The groups with a button, in order.)
    FShownGroups: TArray<String>;
    //** @abstract(The groups' buttons, in FShownGroups' order; each one's Tag is its index.)
    FGroupTiles: TArray<TRectangle>;
    //** @abstract(Holds the tiles; made in FormCreate.)
    FTilesLayout: TLayout;
    //** @abstract(The entry whose tile the left button is down on; -1 for none.)
    FTileDown: Integer;
    //** @abstract(True when a plain click on a picked thumbnail is to pick it alone, once
    //** the button comes up without a drag.)
    FPickOnUp: Boolean;
    //** @abstract(The group whose button or tile the left button is down on; empty for
    //** none.)
    FGroupDown: String;
    //** @abstract(True if FGroupDown's press is on a group's tile in the grid, not its
    //** button on the left.)
    FGroupDownInGrid: Boolean;
    //** @abstract(The group tile in the grid marked as where the drag would drop; -1 for
    //** none.)
    FDropFolder: Integer;
    //** @abstract(Scrolls GroupsBox or TilesBox while a drag holds the pointer near or past
    //** its top or bottom edge; see ScrollTimerTimer.)
    FScrollTimer: TTimer;
    //** @abstract(Where the pointer was at the drag's last move, in the form's coordinates.)
    FDragAt: TPointF;
    //** @abstract(True while a dragged group would go into the group shown: TilesPanel is
    //** outlined.)
    FDropInto: Boolean;
    //** @abstract(True while a dragged group would go to the top, last: the space below the
    //** buttons.)
    FDropBelow: Boolean;
    //** @abstract(Where the left button went down, in the form's coordinates.)
    FDownAt: TPointF;
    //** @abstract(True once the pointer has moved TILE_DRAG_START with the button down: the
    //** thumbnails or group are being dragged.)
    FDragging: Boolean;
    //** @abstract(Follows the pointer while thumbnails are dragged: the one pressed, made in
    //** FormCreate.)
    FDragGhost: TImage;
    //** @abstract(On FDragGhost: how many are dragged, when more than one.)
    FDragCount: TLabel;
    //** @abstract(The group button marked as where the drag would drop; -1 for none.)
    FDropIndex: Integer;
    //** @abstract(The group GroupMenu was opened on; empty for empty space.)
    FMenuGroup: String;
    //** @abstract(True if GroupMenu was opened in the grid: a group added goes inside the one
    //** shown, not at the top.)
    FMenuInGrid: Boolean;
    //** @abstract(What the name dialog open is for.)
    FAskName: TGroupNameAsk;
    //** @abstract(The group DeferredWork is to put inside FReparentTo, or at the top if
    //** FReparentTo is empty; empty FReparentGroup: none.)
    FReparentGroup, FReparentTo: String;
    //** @abstract(The group DeferredWork is to show, opened from its tile; empty for none.)
    FOpenGroup: String;
    //** @abstract(True while the left button turns the preview.)
    FTurning: Boolean;
    //** @abstract(Where the pointer was at the last move of the turn, in PreviewArea's
    //** coordinates.)
    FTurnLast: TPointF;
    //** @abstract(Shared with the hashing worker, which hands back nothing once the form is
    //** gone.)
    FAlive: IAssetsAlive;
    //** @abstract(Backing field for OnLog.)
    FOnLog: TAssetsLogEvent;
    //** @abstract(Reads the library, once; if there is none but there is a palette of
    //** before it, makes that the first collection, "Kaykit Dungeon", from MigrationFolder.)
    procedure LoadLibrary;
    //** @abstract(Writes the library, logging a failure.)
    procedure SaveLibrary;
    //** @abstract(Fills CollectionCombo with the library's collections, chooses the one open,
    //** and enables what can be done.)
    procedure FillCollections;
    //** @abstract(Opens collection AId: from its saved models if its folders have been
    //** scanned, else by scanning them.)
    //**
    //** @param(AId The collection's id; empty shows no collection.)
    procedure OpenCollection(const AId: String);
    //** @abstract(Reads the open collection's folders: every model hashed on a worker
    //** thread, then shown, its groups kept.)
    procedure ScanCollection;
    //** @abstract(The folders and formats to take from ARoots: every folder holding models
    //** under them is found, and if there is more than one, the user chooses
    //** (ChooseModelFolders), with the library's preferred format ticked.)
    //**
    //** @param(ARoots The folders the user chose.)
    //**
    //** @returns(The sources; empty if there are no models, or the user cancelled.)
    function ChooseSources(const ARoots: TArray<String>): TArray<TSprite3DCollectionSource>;
    //** @abstract(Makes a new collection called AName from ASources and adds it to the
    //** library, which is saved; it is scanned when first opened.)
    //**
    //** @param(AName The name.)
    //**
    //** @param(ASources Its folders and formats.)
    //**
    //** @returns(Its id; empty if it could not be saved.)
    function NewCollection(const AName: String;
      const ASources: TArray<TSprite3DCollectionSource>): String;
    //** @abstract(Imports the artist import's next collection in full, opening it, which
    //** reads its folders and makes its thumbnails; when there are none left, opens the
    //** first and shows the summary.)
    procedure NextBulk;
    //** @abstract(Says which of the artist import's collections is under way, to go before
    //** the status; empty when none is.)
    //**
    //** @returns(The text.)
    function BulkPrefix: String;
    //** @abstract(Ends the artist import under way, if there is one; the collections not yet
    //** imported are when each is opened.)
    //**
    //** @param(AWhy Why, for the log.)
    procedure StopBulk(const AWhy: String);
    //** @abstract(Whether the library has a collection called AName, case ignored.)
    //**
    //** @param(AName The name.)
    //**
    //** @returns(True if it has.)
    function HasCollection(const AName: String): Boolean;
    //** @abstract(The open collection's sources, for the log: each folder, with its formats.)
    //**
    //** @returns(The text.)
    function SourcesText: String;
    //** @abstract(The folder a folder dialog starts in: the last chosen, or the assets folder.)
    //**
    //** @returns(The folder.)
    function StartFolder: String;
    //** @abstract(Makes the new collection of FNewSources called AName, or renames the open
    //** one, as AAsk says; a name another collection has is refused.)
    //**
    //** @param(AAsk gnNewCollection or gnRenameCollection.)
    //**
    //** @param(AName The name, trimmed; empty does nothing.)
    procedure CollectionNamed(const AAsk: TGroupNameAsk; const AName: String);
    //** @abstract(Deletes the open collection, if the user said Yes; the delete dialog's
    //** answer.)
    //**
    //** @param(Sender The dialog's context; not used.)
    //**
    //** @param(AResult How the dialog was closed.)
    procedure DeleteCollectionClosed(Sender: TObject; const AResult: TModalResult);
    //** @abstract(Hands AText to OnLog, if it is set.)
    //**
    //** @param(AText The line.)
    procedure Log(const AText: String);
    //** @abstract(True while thumbnails are queued or one is being made.)
    //**
    //** @returns(Whether the viewport is busy with thumbnails.)
    function Making: Boolean;
    //** @abstract(The hashing's results for folder AScanId: the entries from them, cached or
    //** queued, in their groups and sorted, then the groups and tiles, then the first
    //** thumbnail.)
    //**
    //** @param(AScanId The folder they are for; anything but FScanId is dropped.)
    //**
    //** @param(AResults One per model file.)
    procedure HashesDone(const AScanId: Integer; const AResults: TArray<TAssetHashResult>);
    //** @abstract(Puts each plural group with its singular one, when both are there, for
    //** the models the palette does not place.)
    procedure MergePluralGroups;
    //** @abstract(Makes a button for each of the palette's groups, in its order, with its
    //** icon, name and how many models of the folder it has, and chooses FGroup again, or
    //** the first group if it has gone.)
    //**
    //** A group with none of the folder's models has a button only if it has no models at
    //** all, one the user has just made: the groups of other kits are kept, but not shown.
    procedure BuildGroups;
    //** @abstract(Marks the button of the chosen group's top group, and the button, tile or
    //** panel a drag would drop on.)
    procedure UpdateGroupMarks;
    //** @abstract(The group AGroup is inside, as named in the palette.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @returns(The group it is inside; empty for one at the top.)
    function ParentOf(const AGroup: String): String;
    //** @abstract(The group at the top that AGroup is in, or AGroup if it is at the top.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @returns(The top group.)
    function RootOf(const AGroup: String): String;
    //** @abstract(Whether AOuter is AGroup, or a group AGroup is inside, at any depth.)
    //**
    //** @param(AOuter The group that may hold it.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @returns(True if so, ignoring case.)
    function Holds(const AOuter, AGroup: String): Boolean;
    //** @abstract(The groups directly inside AGroup, in alphabetical order, case ignored.)
    //**
    //** @param(AGroup The group; empty for those at the top.)
    //**
    //** @returns(Their names.)
    function ChildGroups(const AGroup: String): TArray<String>;
    //** @abstract(How many of the folder's models are in AGroup and every group inside it.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @returns(The count.)
    function FolderTotal(const AGroup: String): Integer;
    //** @abstract(Whether AGroup has a button or tile: models of the folder in it or the
    //** groups inside it, or no models anywhere, as a group just made has.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @returns(True if it is shown.)
    function GroupShown(const AGroup: String): Boolean;
    //** @abstract(Whether AGroup has no models anywhere and no groups inside it, so it may
    //** be deleted.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @returns(True if it is empty.)
    function GroupEmpty(const AGroup: String): Boolean;
    //** @abstract(Puts group AGroup inside AParent, or at the top, unless that would put a
    //** group inside itself; saves the palette and shows the groups again.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @param(AParent The group to put it in; empty for the top.)
    procedure Reparent(const AGroup, AParent: String);
    //** @abstract(Frees the tiles of the groups inside the one shown and makes them again.)
    procedure BuildFolderTiles;
    //** @abstract(The group tile in the grid under a point.)
    //**
    //** @param(AAbsolute The point, in the form's coordinates.)
    //**
    //** @returns(Its index in FFolderNames, or -1.)
    function FolderTileAt(const AAbsolute: TPointF): Integer;
    //** @abstract(Whether a point is over the grid, TilesPanel.)
    //**
    //** @param(AAbsolute The point, in the form's coordinates.)
    //**
    //** @returns(True if it is.)
    function OverTiles(const AAbsolute: TPointF): Boolean;
    //** @abstract(Shows the group shown and the groups it is inside in PathLabel, and enables
    //** UpButton if there is a group to go up to.)
    procedure UpdatePath;
    //** @abstract(Shows FPreviewLabel while the viewport has no model.)
    procedure UpdatePreviewLabel;
    //** @abstract(Readies a group's tile in the grid to be dragged; a double-click opens it.)
    //**
    //** @param(Sender A group's tile.)
    //**
    //** @param(Button The button.)
    //**
    //** @param(Shift The keys and buttons held; ssDouble for a double-click.)
    //**
    //** @param(X Where, across the tile.)
    //**
    //** @param(Y Where, down the tile.)
    procedure FolderTileMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Marks where the dragged group would go: into another group's button or
    //** tile, or to the top below the buttons.)
    //**
    //** @param(At Where the pointer is, in the form's coordinates.)
    procedure TrackGroupDrag(const At: TPointF);
    //** @abstract(Marks where the dragged thumbnails would drop: another group's button, or
    //** a group's tile in the grid.)
    //**
    //** @param(At Where the pointer is, in the form's coordinates.)
    procedure TrackTileDrag(const At: TPointF);
    //** @abstract(Scrolls ABox a step if At is near or past its top or bottom edge, and
    //** within it across.)
    //**
    //** @param(ABox GroupsBox or TilesBox.)
    //**
    //** @param(At The pointer, in the form's coordinates.)
    //**
    //** @returns(True if it scrolled.)
    function EdgeScroll(const ABox: TVertScrollBox; const At: TPointF): Boolean;
    //** @abstract(Scrolls the box the dragging pointer is at the edge of, and marks the drop
    //** again, as what is under the pointer has moved.)
    //**
    //** @param(Sender FScrollTimer.)
    procedure ScrollTimerTimer(Sender: TObject);
    //** @abstract(Starts a drag: FScrollTimer on, the ghost shown.)
    procedure BeginDrag;
    //** @abstract(Ends a group's drag at a point: moves it before another at the top,
    //** inside another, or to the top, as TrackGroupDrag marked.)
    //**
    //** @param(At Where the pointer is, in the form's coordinates.)
    procedure DropGroup(const At: TPointF);
    //** @abstract(The icon for group AGroup: the one chosen for it, or the library's named
    //** after it, or its first model's thumbnail.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @returns(The bitmap, which is not the caller's; nil if there is none.)
    function GroupIcon(const AGroup: String): TBitmap;
    //** @abstract(Where an icon of the library is: the user's own folder first, then the one
    //** that comes with the program.)
    //**
    //** @param(AName The icon's file name.)
    //**
    //** @returns(Its full path; empty if neither has it.)
    function IconFile(const AName: String): String;
    //** @abstract(Where group AGroup is in FGroupOrder, ignoring case.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @returns(Its index, or -1.)
    function GroupIndex(const AGroup: String): Integer;
    //** @abstract(How many models of the palette, in this folder or not, are in AGroup.)
    //**
    //** @param(AGroup The group.)
    //**
    //** @returns(The count.)
    function PaletteCount(const AGroup: String): Integer;
    //** @abstract(Writes the open collection, its palette, FGroupOrder with its icons and
    //** every key of FPaletteGroups in its group, and its models, to the cache, logging a
    //** failure.)
    //**
    //** Each group's models are this folder's in name order, then those of other folders in
    //** key order.
    procedure SavePalette;
    //** @abstract(Shows group AGroup's tiles; the picks are dropped.)
    //**
    //** @param(AGroup The group; empty for none.)
    procedure ShowGroup(const AGroup: String);
    //** @abstract(Frees the tiles and makes one for every entry of FEntries.)
    procedure BuildTiles;
    //** @abstract(Places the tiles of FGroup in rows as wide as TilesBox, in name order,
    //** and hides the rest.)
    procedure LayoutTiles;
    //** @abstract(Gives each tile the look of picked, selected, or neither.)
    procedure UpdateTileMarks;
    //** @abstract(The entries picked, in name order.)
    //**
    //** @returns(Their indices in FEntries.)
    function PickedEntries: TArray<Integer>;
    //** @abstract(Picks as a click with Shift held does: AIndex alone, added or taken away
    //** with Control, or the run from FAnchor with Shift.)
    //**
    //** @param(AIndex The entry clicked.)
    //**
    //** @param(AShift The keys held.)
    procedure PickEntry(const AIndex: Integer; const AShift: TShiftState);
    //** @abstract(Picks and selects the tile's model, and makes ready to drag.)
    //**
    //** @param(Sender The tile; its Tag is the entry.)
    //**
    //** @param(Button The button.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across the tile.)
    //**
    //** @param(Y Where, down the tile.)
    procedure TileMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Drags the picked thumbnails once the pointer has moved TILE_DRAG_START:
    //** the one pressed follows the pointer, with how many there are, and the group under
    //** it is marked.)
    //**
    //** The tile keeps the mouse while the button is down (AutoCapture), so the moves come
    //** here wherever the pointer goes.
    //**
    //** @param(Sender The tile.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across the tile.)
    //**
    //** @param(Y Where, down the tile.)
    procedure TileMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    //** @abstract(Drops the dragged thumbnails on the group under the pointer, moving their
    //** models there; without a drag, a plain click on a picked one picks it alone.)
    //**
    //** @param(Sender The tile.)
    //**
    //** @param(Button The button.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across the tile.)
    //**
    //** @param(Y Where, down the tile.)
    procedure TileMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Chooses the group with the left button and readies it to be dragged.)
    //**
    //** @param(Sender A group's button.)
    //**
    //** @param(Button The button.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across the button.)
    //**
    //** @param(Y Where, down the button.)
    procedure GroupTileMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Drags the group once the pointer has moved TILE_DRAG_START, marking the
    //** group it would go before.)
    //**
    //** @param(Sender A group's button.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across the button.)
    //**
    //** @param(Y Where, down the button.)
    procedure GroupTileMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    //** @abstract(Drops a dragged group before the one under the pointer, or last below
    //** them; with the right button, opens GroupMenu on the group.)
    //**
    //** @param(Sender A group's button.)
    //**
    //** @param(Button The button.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across the button.)
    //**
    //** @param(Y Where, down the button.)
    procedure GroupTileMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(The group button under a point.)
    //**
    //** @param(AAbsolute The point, in the form's coordinates.)
    //**
    //** @param(ABelow On return, True if the point is in GroupsBox but below every button.)
    //**
    //** @returns(The button's index in FShownGroups, or -1.)
    function GroupTileAt(const AAbsolute: TPointF; out ABelow: Boolean): Integer;
    //** @abstract(Marks group button AIndex as where the drag would drop.)
    //**
    //** @param(AIndex The button; -1 for none.)
    procedure SetDropIndex(const AIndex: Integer);
    //** @abstract(Ends a drag: the ghost hidden, the mark taken off.)
    procedure EndDrag;
    //** @abstract(Starts DeferredWork on a later main-loop turn.)
    procedure Defer;
    //** @abstract(Moves the group a drag dropped; FDeferTimer's OnTimer.)
    //**
    //** @param(Sender FDeferTimer.)
    procedure DeferredWork(Sender: TObject);
    //** @abstract(Opens GroupMenu on group AGroup, with only what can be done to it enabled.)
    //**
    //** @param(AGroup The group; empty for the space below the groups.)
    //**
    //** @param(AAbsolute Where, in the form's coordinates.)
    procedure ShowGroupMenu(const AGroup: String; const AAbsolute: TPointF);
    //** @abstract(Adds the group or renames FMenuGroup, as FAskName says; the name dialog's
    //** answer.)
    //**
    //** @param(Sender The dialog's context; not used.)
    //**
    //** @param(AResult How the dialog was closed.)
    //**
    //** @param(AValues The name typed, first.)
    procedure GroupNameClosed(Sender: TObject; const AResult: TModalResult;
      const AValues: array of String);
    //** @abstract(Moves entries AIndices to group AGroup, adding the group last if it is new,
    //** saves the palette, and shows the groups again.)
    //**
    //** @param(AIndices The entries.)
    //**
    //** @param(AGroup The group; trimmed and put in lower case; empty does nothing.)
    procedure MoveEntries(const AIndices: TArray<Integer>; const AGroup: String);
    //** @abstract(Selects entry AIndex, shows its details, and previews it.)
    //**
    //** @param(AIndex An entry of FEntries; -1 for none.)
    procedure SelectEntry(const AIndex: Integer);
    //** @abstract(Loads entry AIndex into the viewport, in the thumbnails' view, unless
    //** thumbnails are being made.)
    //**
    //** @param(AIndex The entry; -1 empties the viewport.)
    procedure ShowPreview(const AIndex: Integer);
    //** @abstract(Loads entry AIndex's model into the viewport as FModel, upright, and
    //** records its box in its metadata.)
    //**
    //** @param(AIndex The entry.)
    //**
    //** @returns(True if it loaded; False, with the reason logged and FModel nil, if not.)
    function LoadEntryModel(const AIndex: Integer): Boolean;
    //** @abstract(Puts the camera back in the thumbnails' view: isometric, orthographic.)
    procedure ResetCameraAngles;
    //** @abstract(Starts making the next queued thumbnail, or says all are made and
    //** previews the selected model.)
    procedure MakeNext;
    //** @abstract(Starts FNextTimer, so MakeNext runs on a later main-loop turn.)
    procedure MakeNextLater;
    //** @abstract(Runs MakeNext; FNextTimer's OnTimer.)
    //**
    //** @param(Sender FNextTimer.)
    procedure NextTimerTimer(Sender: TObject);
    //** @abstract(Starts the grab of the thumbnail being made, once its model has been on
    //** screen for THUMBNAIL_SETTLE_MS.)
    //**
    //** @param(Sender FSettleTimer.)
    procedure SettleTimerTimer(Sender: TObject);
    //** @abstract(The procedure the off-screen pass calls with entry AIndex's thumbnail.)
    //**
    //** Made here, so the entry and folder are passed by value, not captured as variables.
    //**
    //** @param(AIndex The entry.)
    //**
    //** @param(AScanId The folder it was made for.)
    //**
    //** @returns(The procedure.)
    function GrabDone(const AIndex, AScanId: Integer): TSprite3DGrabProc;
    //** @abstract(Saves entry AIndex's thumbnail and metadata to the cache and shows it, then
    //** goes on to the next.)
    //**
    //** @param(AIndex The entry.)
    //**
    //** @param(AScanId The folder it was made for; anything but FScanId is dropped.)
    //**
    //** @param(ABitmap The thumbnail; nil if the grab failed. It is the caller's.)
    //**
    //** @param(AError Why the grab failed; empty if it did not.)
    procedure ThumbnailGrabbed(const AIndex, AScanId: Integer; const ABitmap: TBitmap;
      const AError: String);
    //** @abstract(Frames FModel in a view AWidth by AHeight, as the thumbnail shows it,
    //** centred on its centre of rotation, as Sprite3D frames a model.)
    //**
    //** The volume FModelBox sweeps turning about the up axis through the model's
    //** RotationCenter (CalcSweptVolume) is fitted by FitCameraToSweep, which uses the
    //** camera's FitPointsOnAxis: the camera's target stays on that axis, the axis the
    //** builder will turn the piece about, so it is the middle of the picture across, and
    //** the piece is the same size in the picture whichever way it is turned.
    //**
    //** @param(AWidth The view's width; only its ratio to AHeight matters.)
    //**
    //** @param(AHeight The view's height.)
    procedure FrameModel(const AWidth, AHeight: Single);
    //** @abstract(Frames FModel for the grab's own size; the off-screen pass's OnBeforeGrab.)
    //**
    //** @param(Sender FOffscreen.)
    //**
    //** @param(AWidth The grab's width in pixels.)
    //**
    //** @param(AHeight The grab's height in pixels.)
    procedure OffscreenBeforeGrab(Sender: TObject; const AWidth, AHeight: Integer);
    //** @abstract(Starts turning the preview with the left button; puts the thumbnails'
    //** view back with the right, or Control and the left.)
    //**
    //** @param(Sender PreviewArea.)
    //**
    //** @param(Button The button.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across PreviewArea.)
    //**
    //** @param(Y Where, down PreviewArea.)
    procedure PreviewMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Turns the preview by how far the pointer moved across, and tilts it by
    //** how far it moved down, right round if need be: the Spritely camera's gimbals have
    //** no lock.)
    //**
    //** @param(Sender PreviewArea.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across PreviewArea.)
    //**
    //** @param(Y Where, down PreviewArea.)
    procedure PreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    //** @abstract(Ends a turn of the preview.)
    //**
    //** @param(Sender PreviewArea.)
    //**
    //** @param(Button The button.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across PreviewArea.)
    //**
    //** @param(Y Where, down PreviewArea.)
    procedure PreviewMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Zooms the preview: away from you nearer, towards you further.)
    //**
    //** @param(Sender PreviewArea.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(WheelDelta How far the wheel turned; a notch is 120.)
    //**
    //** @param(Handled Set to True when the preview took it.)
    procedure PreviewMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
      var Handled: Boolean);
    //** @abstract(True when the preview has a model to turn: one is shown and no thumbnail
    //** is being made.)
    //**
    //** @returns(Whether the mouse may turn and zoom the preview.)
    function CanTurnPreview: Boolean;
    //** @abstract(Frees FModel, if there is one.)
    procedure FreeModel;
    //** @abstract(Stops making thumbnails: the grab under way is dropped, and the queue
    //** emptied.)
    procedure StopMaking;
  public
    //** @abstract(Shows the Library, opening the collection open last, if there is one.)
    procedure ShowLibrary;
    //** @abstract(Deletes every cached thumbnail and its metadata, then, if the form is
    //** showing a collection, opens it again, so every thumbnail is made afresh.)
    //**
    //** The thumbnail being made is dropped first. Uses ClearAssetCache on the cache folder,
    //** TSprite3DAppSettings.ThumbnailFolder, and reports what it did through OnLog. The
    //** palette is kept.
    procedure ClearThumbnails;
    //** @abstract(Every model shown, in name order.)
    property Entries: TArray<TAssetEntry> read FEntries;
    //** @abstract(The entry selected, or -1.)
    property Selected: Integer read FSelected;
    //** @abstract(Called with each line the form has to report, for the Debug tab.)
    property OnLog: TAssetsLogEvent read FOnLog write FOnLog;
    //** @abstract(The folder of the one palette of before the library, palette.json, for the
    //** collection LoadLibrary makes of it; set before ShowLibrary.)
    property MigrationFolder: String read FMigrationFolder write FMigrationFolder;
  end;


implementation

uses
  System.Threading, System.Math, System.DateUtils, System.IOUtils,
  System.Generics.Defaults, System.StrUtils, FMX.DialogService, OSPaths, Sprite3DSweep,
  Sprite3DGroupIcons, Sprite3DFolderDialog, Sprite3DBuilderHelpers,
  Sprite3DBuilderImportForm, Sprite3DBuilderFormatForm;

{$R *.fmx}

const
  //** @abstract(A tile's width and height, and the thumbnail's size on it, in logical
  //** pixels.)
  TILE_WIDTH = 104;
  TILE_HEIGHT = 124;
  TILE_IMAGE = 96;
  //** @abstract(The room between tiles, and round the grid's edge.)
  TILE_GAP = 6;
  //** @abstract(How far, in logical pixels, the pointer moves with the left button down
  //** before a thumbnail or group is dragged.)
  TILE_DRAG_START = 5;
  //** @abstract(The room left round a model in its thumbnail, as a fraction of the view.)
  THUMBNAIL_MARGIN = 0.06;
  //** @abstract(The thumbnails' view: the isometric inclination, ArcTan@(1/Sqrt@(2@)@) in
  //** degrees, and the camera's azimuth for Sprite3D's 45, which ApplyAngles in the main
  //** form reverses to 315.)
  THUMBNAIL_INCLINATION = 35.26439;
  THUMBNAIL_AZIMUTH = 315;
  //** @abstract(How the cache's metadata names the thumbnails' view.)
  THUMBNAIL_VIEW = 'isometric orthographic';
  //** @abstract(How long, in milliseconds, a model is on screen before its thumbnail is
  //** grabbed, so the viewport has drawn it at least once.)
  THUMBNAIL_SETTLE_MS = 120;
  //** @abstract(A tile's outline; a picked tile's; and the selected tile's fill.)
  TILE_STROKE = TAlphaColor($60808080);
  TILE_SELECTED_STROKE = TAlphaColor($FF2A9FD6);
  TILE_SELECTED_FILL = TAlphaColor($302A9FD6);
  //** @abstract(The preview's turn and tilt, in degrees, for each logical pixel the pointer
  //** moves.)
  PREVIEW_DEGREES_PER_PIXEL = 0.5;
  //** @abstract(The preview's zoom for a notch of the wheel.)
  PREVIEW_ZOOM_STEP = 1.1;
  //** @abstract(A group button's height, its icon's size on it, and its text's size, big
  //** enough to drop on easily.)
  GROUP_TILE_HEIGHT = 66;
  GROUP_ICON_SIZE = 32;
  GROUP_FONT_SIZE = 13;
  //** @abstract(The chosen group's fill, and the outline of the group a drag would drop on.)
  GROUP_CHOSEN_FILL = TAlphaColor($502A9FD6);
  GROUP_DROP_STROKE = TAlphaColor($FFFFC040);
  //** @abstract(The colour an SVG icon is drawn in, and the size it is drawn at, in pixels:
  //** twice its size on the button, for a sharp picture.)
  GROUP_ICON_COLOUR = TAlphaColor($FFE0E0E0);
  GROUP_ICON_PIXELS = 64;
  //** @abstract(The dragged thumbnail's size, in logical pixels.)
  GHOST_SIZE = 72;
  //** @abstract(How often, in milliseconds, a drag at a box's edge scrolls it; how near
  //** the edge, in logical pixels, it starts; and how far a step goes at the edge, more
  //** the further past it the pointer is.)
  DRAG_SCROLL_MS = 40;
  DRAG_SCROLL_EDGE = 28;
  DRAG_SCROLL_STEP = 10;
  //** @abstract(How many thumbnails are made before the time left is shown, so the average
  //** it is worked out from is a fair one.)
  ETA_AFTER = 3;
  //** @abstract(The fill of a group's tile in the grid, so it stands apart from models.)
  FOLDER_FILL = TAlphaColor($28FFFFFF);

type
  //** @abstract(IAssetsAlive: True until Kill.)
  TAssetsAlive = class(TInterfacedObject, IAssetsAlive)
  private
    //** @abstract(Whether Kill has been called.)
    FDead: Boolean;
  public
    //** @abstract(True until Kill.)
    //**
    //** @returns(Whether the form is still there.)
    function Alive: Boolean;
    //** @abstract(Marks the form as gone.)
    procedure Kill;
  end;

function TAssetsAlive.Alive: Boolean;
begin
  Result := not FDead;
end;

procedure TAssetsAlive.Kill;
begin
  FDead := True;
end;

//** @abstract(A length of time for people: 45s, 3m 05s, 1h 02m.)
//**
//** @param(ASeconds The time in seconds; less than 0 counts as 0.)
//**
//** @returns(The text.)
function DurationText(const ASeconds: Double): String;
var
  Total: Int64;
begin
  Total := Round(Max(0, ASeconds));
  if Total < 60 then
    Result := Format('%ds', [Total])
  else if Total < 3600 then
    Result := Format('%dm %.2ds', [Total div 60, Total mod 60])
  else
    Result := Format('%dh %.2dm', [Total div 3600, (Total mod 3600) div 60]);
end;

{ TAssetsForm }

procedure TAssetsForm.FormCreate(Sender: TObject);
begin
  FAlive := TAssetsAlive.Create;
  FMaking := -1;
  FSelected := -1;
  FAnchor := -1;
  FPreviewIndex := -1;
  FTileDown := -1;
  FDropIndex := -1;
  FCacheFolder := TSprite3DAppSettings.ThumbnailFolder;
  FPaletteGroups := TDictionary<String, String>.Create;
  FGroupIcons := TDictionary<String, String>.Create;
  FIconBitmaps := TObjectDictionary<String, TBitmap>.Create([doOwnsValues]);
  FGroupParents := TDictionary<String, String>.Create;
  FDropFolder := -1;

  FViewport := TGorillaViewport.Create(PreviewArea);
  FViewport.Parent := PreviewArea;
  FViewport.Align := TAlignLayout.Client;
  FViewport.UseFixedFrameRate := True;
  FViewport.VSync := False;
  FViewport.FixedFrameRate := 60;
  // The mouse goes to PreviewArea, which turns the preview
  FViewport.HitTest := False;

  FPreviewLabel := TLabel.Create(PreviewArea);
  FPreviewLabel.Parent := PreviewArea;
  FPreviewLabel.Align := TAlignLayout.Contents;
  FPreviewLabel.StyledSettings := FPreviewLabel.StyledSettings - [TStyledSetting.Size,
    TStyledSetting.FontColor];
  FPreviewLabel.TextSettings.Font.Size := 16;
  FPreviewLabel.TextSettings.FontColor := TAlphaColor($FFA0A0A0);
  FPreviewLabel.TextSettings.HorzAlign := TTextAlign.Center;
  FPreviewLabel.TextSettings.VertAlign := TTextAlign.Center;
  FPreviewLabel.Text := 'Model Preview';
  FPreviewLabel.HitTest := False;
  FPreviewLabel.BringToFront;

  // The Spritely camera, as the main form's: orthographic, lit from the
  // camera, in the thumbnails' view to start with
  FCamera := TSpritelyOrbitalCamera.Create(Self);
  FCamera.Headlight := True;
  FCamera.Viewport := FViewport;
  FCamera.Camera.ProjectionMode := TGorillaCameraProjection.cpOrthographic;
  ResetCameraAngles;

  // Every thumbnail the same size, its background transparent
  FOffscreen := TSprite3DOffscreen.Create(FViewport);
  FOffscreen.Viewport := FViewport;
  FOffscreen.Width := THUMBNAIL_SIZE;
  FOffscreen.Height := THUMBNAIL_SIZE;
  FOffscreen.TransparentBackground := True;
  FOffscreen.OnBeforeGrab := OffscreenBeforeGrab;

  FSettleTimer := TTimer.Create(Self);
  FSettleTimer.Enabled := False;
  FSettleTimer.Interval := THUMBNAIL_SETTLE_MS;
  FSettleTimer.OnTimer := SettleTimerTimer;

  FNextTimer := TTimer.Create(Self);
  FNextTimer.Enabled := False;
  FNextTimer.Interval := 1;
  FNextTimer.OnTimer := NextTimerTimer;

  FDeferTimer := TTimer.Create(Self);
  FDeferTimer.Enabled := False;
  FDeferTimer.Interval := 1;
  FDeferTimer.OnTimer := DeferredWork;

  FScrollTimer := TTimer.Create(Self);
  FScrollTimer.Enabled := False;
  FScrollTimer.Interval := DRAG_SCROLL_MS;
  FScrollTimer.OnTimer := ScrollTimerTimer;

  FDragGhost := TImage.Create(Self);
  FDragGhost.Parent := Self;
  FDragGhost.Width := GHOST_SIZE;
  FDragGhost.Height := GHOST_SIZE;
  FDragGhost.WrapMode := TImageWrapMode.Fit;
  FDragGhost.Opacity := 0.85;
  FDragGhost.HitTest := False;
  FDragGhost.Visible := False;
  FDragCount := TLabel.Create(FDragGhost);
  FDragCount.Parent := FDragGhost;
  FDragCount.Align := TAlignLayout.Bottom;
  FDragCount.Height := 20;
  FDragCount.StyledSettings := FDragCount.StyledSettings - [TStyledSetting.Size,
    TStyledSetting.Style];
  FDragCount.TextSettings.Font.Size := 15;
  FDragCount.TextSettings.Font.Style := [TFontStyle.fsBold];
  FDragCount.TextSettings.HorzAlign := TTextAlign.Trailing;
  FDragCount.HitTest := False;

  PreviewArea.HitTest := True;
  PreviewArea.OnMouseDown := PreviewMouseDown;
  PreviewArea.OnMouseMove := PreviewMouseMove;
  PreviewArea.OnMouseUp := PreviewMouseUp;
  PreviewArea.OnMouseWheel := PreviewMouseWheel;

  // Nothing here takes the keys, so the form's OnKeyDown has Up and Down
  GroupsBox.CanFocus := False;
  TilesBox.CanFocus := False;

  FTilesLayout := TLayout.Create(Self);
  FTilesLayout.Parent := TilesBox;
  FTilesLayout.Align := TAlignLayout.Top;
  FTilesLayout.Height := 0;
  FTilesLayout.HitTest := False;

  StatusLabel.Text := 'No asset folder open';
  Progress.Value := 0;
  Progress.Visible := False;
  SelectEntry(-1);
end;

procedure TAssetsForm.FormDestroy(Sender: TObject);
begin
  FAlive.Kill;
  if FSettleTimer <> nil then
    FSettleTimer.Enabled := False;
  if FNextTimer <> nil then
    FNextTimer.Enabled := False;
  if FDeferTimer <> nil then
    FDeferTimer.Enabled := False;
  if FScrollTimer <> nil then
    FScrollTimer.Enabled := False;
  if FOffscreen <> nil then
    FOffscreen.Cancel;
  FreeModel;
  FreeAndNil(FPaletteGroups);
  FreeAndNil(FGroupIcons);
  FreeAndNil(FIconBitmaps);
  FreeAndNil(FGroupParents);
end;

procedure TAssetsForm.FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar;
  Shift: TShiftState);
var
  Index: Integer;
  TileTop, TileBottom: Single;
begin
  if FDragging then
    Exit;
  if Key = vkBack then
  begin
    Key := 0;
    UpButtonClick(UpButton);
    Exit;
  end;
  if ((Key <> vkUp) and (Key <> vkDown)) or (Length(FShownGroups) = 0) then
    Exit;
  Index := IndexText(RootOf(FGroup), FShownGroups);
  if Key = vkUp then
    Index := Max(0, Index - 1)
  else
    Index := Min(High(FShownGroups), Index + 1);
  Key := 0;
  if not SameText(FShownGroups[Index], RootOf(FGroup)) then
    ShowGroup(FShownGroups[Index]);
  // Kept in view
  if Index <= High(FGroupTiles) then
  begin
    TileTop := FGroupTiles[Index].Position.Y - FGroupTiles[Index].Margins.Top;
    TileBottom := FGroupTiles[Index].Position.Y + FGroupTiles[Index].Height +
      FGroupTiles[Index].Margins.Bottom;
    if TileTop < GroupsBox.ViewportPosition.Y then
      GroupsBox.ViewportPosition := TPointF.Create(0, TileTop)
    else if TileBottom > GroupsBox.ViewportPosition.Y + GroupsBox.Height then
      GroupsBox.ViewportPosition := TPointF.Create(0, TileBottom - GroupsBox.Height);
  end;
end;

procedure TAssetsForm.ShowLibrary;
begin
  LoadLibrary;
  Show;
  BringToFront;
  if FCollection.Id <> String.Empty then
    Exit;   // open already
  if FLibrary.Last <> String.Empty then
    for var Entry in FLibrary.Collections do
      if SameText(Entry.Id, FLibrary.Last) then
      begin
        OpenCollection(Entry.Id);
        Exit;
      end;
  if Length(FLibrary.Collections) > 0 then
    OpenCollection(FLibrary.Collections[0].Id)
  else
    OpenCollection(String.Empty);
end;

procedure TAssetsForm.LoadLibrary;
var
  Palette: TArray<TSprite3DPaletteGroup>;
  Moved: TSprite3DAssetCollection;
  Entry: TSprite3DLibraryEntry;
  OldFile: String;
begin
  if FLibraryLoaded then
    Exit;
  FLibraryLoaded := True;
  if LoadAssetLibrary(FCacheFolder, FLibrary) then
    Exit;
  // No library yet. The one palette of before it, if there is one, becomes
  // its first collection, to be scanned from the folder it was made from
  OldFile := TPath.Combine(FCacheFolder, ASSET_PALETTE_FILE_NAME);
  if not LoadAssetPalette(FCacheFolder, Palette) then
    Exit;
  Moved := Default(TSprite3DAssetCollection);
  Moved.Id := NewCollectionId;
  Moved.Name := 'Kaykit Dungeon';
  if (FMigrationFolder <> String.Empty) and DirectoryExists(FMigrationFolder) then
  begin
    SetLength(Moved.Sources, 1);
    Moved.Sources[0].Folder := FMigrationFolder;
    Moved.Sources[0].Formats := nil;
  end;
  Moved.Groups := Palette;
  Moved.Scanned := False;
  try
    SaveAssetCollection(FCacheFolder, Moved);
  except
    on E: Exception do
    begin
      Log('Assets: can''t save the collection ' + Moved.Name + ': ' + E.Message);
      Exit;
    end;
  end;
  Entry.Id := Moved.Id;
  Entry.Name := Moved.Name;
  FLibrary.Collections := [Entry];
  FLibrary.Last := Moved.Id;
  FLibrary.LastFolder := FMigrationFolder;
  SaveLibrary;
  // Kept, renamed, so it is not moved again
  try
    TFile.Move(OldFile, OldFile + '.moved');
  except
    on E: Exception do
      Log('Assets: can''t rename ' + OldFile + ': ' + E.Message);
  end;
  Log('Assets: the palette is now the collection ' + Moved.Name + ' in the library');
end;

procedure TAssetsForm.SaveLibrary;
begin
  try
    SaveAssetLibrary(FCacheFolder, FLibrary);
  except
    on E: Exception do
      Log('Assets: can''t save the library in ' + FCacheFolder + ': ' + E.Message);
  end;
end;

procedure TAssetsForm.FillCollections;
var
  Chosen: Integer;
begin
  FFillingCollections := True;
  try
    CollectionCombo.BeginUpdate;
    try
      CollectionCombo.Clear;
      Chosen := -1;
      for var I := 0 to High(FLibrary.Collections) do
      begin
        CollectionCombo.Items.Add(FLibrary.Collections[I].Name);
        if SameText(FLibrary.Collections[I].Id, FCollection.Id) then
          Chosen := I;
      end;
      CollectionCombo.ItemIndex := Chosen;
    finally
      CollectionCombo.EndUpdate;
    end;
  finally
    FFillingCollections := False;
  end;
  CollectionCombo.Enabled := Length(FLibrary.Collections) > 0;
  RescanButton.Enabled := FCollection.Id <> String.Empty;
  CollectionMenuButton.Enabled := FCollection.Id <> String.Empty;
  if FCollection.Id <> String.Empty then
    Caption := 'Library - ' + FCollection.Name
  else
    Caption := 'Library';
end;

procedure TAssetsForm.OpenCollection(const AId: String);
var
  Results: TArray<TAssetHashResult>;
  Opened: TSprite3DAssetCollection;
begin
  StopMaking;
  Inc(FScanId);
  FScanning := False;
  FEntries := nil;
  FGroup := String.Empty;
  SelectEntry(-1);
  BuildTiles;
  if (AId = String.Empty) or not LoadAssetCollection(FCacheFolder, AId, Opened) then
  begin
    if AId <> String.Empty then
      Log('Assets: can''t read the collection ' + AId);
    FCollection := Default(TSprite3DAssetCollection);
    FGroupOrder := nil;
    FPaletteGroups.Clear;
    FGroupParents.Clear;
    FGroupIcons.Clear;
    BuildGroups;
    FillCollections;
    if Length(FLibrary.Collections) = 0 then
      StatusLabel.Text := 'No collections yet: Add New Asset Collection... to start'
    else
      StatusLabel.Text := 'No collection open';
    Progress.Value := 0;
    Progress.Visible := False;
    Exit;
  end;
  // The library's name for it stands
  for var Entry in FLibrary.Collections do
    if SameText(Entry.Id, AId) then
      Opened.Name := Entry.Name;
  FCollection := Opened;
  FLibrary.Last := FCollection.Id;
  SaveLibrary;
  FillCollections;
  Log('Assets: collection ' + FCollection.Name + ' opened');
  if not FCollection.Scanned or (Length(FCollection.Models) = 0) then
  begin
    ScanCollection;
    Exit;
  end;
  // As it was saved: no files read but each thumbnail's
  SetLength(Results, Length(FCollection.Models));
  for var I := 0 to High(FCollection.Models) do
  begin
    Results[I].FileName := FCollection.Models[I].FileName;
    Results[I].Hash := FCollection.Models[I].Key;
    Results[I].Files := nil;
    Results[I].Error := String.Empty;
  end;
  HashesDone(FScanId, Results);
end;

function TAssetsForm.StartFolder: String;
begin
  Result := OSFriendlyPath(FLibrary.LastFolder);
  if (Result = String.Empty) or not DirectoryExists(Result) then
    Result := AssetsFolder;
end;

function TAssetsForm.ChooseSources(const ARoots: TArray<String>):
  TArray<TSprite3DCollectionSource>;
var
  Found, Chosen: TArray<TModelFolder>;
  Preferred: String;
  Source: TSprite3DCollectionSource;
begin
  Result := nil;
  Found := FindModelFolders(ARoots);
  if Length(Found) = 0 then
  begin
    TDialogService.ShowMessage('There are no models in ' + String.Join(', ', ARoots) +
      ' or the folders below.');
    Exit;
  end;
  Preferred := FLibrary.PreferredFormat;
  if not ChooseModelFolders(ARoots, Found, Preferred, Chosen) then
    Exit;
  if (Length(Found) > 1) and not SameText(Preferred, FLibrary.PreferredFormat) then
  begin
    FLibrary.PreferredFormat := Preferred;
    SaveLibrary;
  end;
  for var Folder in Chosen do
  begin
    Source.Folder := Folder.Folder;
    Source.Formats := [Folder.Format];
    Result := Result + [Source];
  end;
end;

function TAssetsForm.SourcesText: String;
var
  Part: String;
begin
  Result := String.Empty;
  for var Source in FCollection.Sources do
  begin
    Part := Source.Folder;
    if Length(Source.Formats) > 0 then
      Part := Part + ' (' + String.Join(' ', Source.Formats) + ')';
    if Result <> String.Empty then
      Result := Result + ', ';
    Result := Result + Part;
  end;
end;

procedure TAssetsForm.CollectionComboChange(Sender: TObject);
begin
  if FFillingCollections or (CollectionCombo.ItemIndex < 0) or
    (CollectionCombo.ItemIndex > High(FLibrary.Collections)) then
    Exit;
  if not SameText(FLibrary.Collections[CollectionCombo.ItemIndex].Id, FCollection.Id) then
  begin
    StopBulk('another collection chosen');
    OpenCollection(FLibrary.Collections[CollectionCombo.ItemIndex].Id);
  end;
end;

procedure TAssetsForm.AddCollectionButtonClick(Sender: TObject);
var
  Folders: TArray<String>;
  Suggested: String;
begin
  if not SelectFolders('Add New Asset Collection', StartFolder, Folders) then
    Exit;
  FLibrary.LastFolder := Folders[0];
  SaveLibrary;
  FNewSources := ChooseSources(Folders);
  if Length(FNewSources) = 0 then
    Exit;
  // The folder's name, as a start
  Suggested := ExtractFileName(ExcludeTrailingPathDelimiter(Folders[0]));
  if Suggested <> String.Empty then
    Suggested := UpperCase(Suggested.Substring(0, 1)) + Suggested.Substring(1);
  FAskName := gnNewCollection;
  TDialogService.InputQuery('Add New Asset Collection', ['Name of the collection'],
    [Suggested], GroupNameClosed);
end;

procedure TAssetsForm.RescanButtonClick(Sender: TObject);
begin
  if FCollection.Id <> String.Empty then
    ScanCollection;
end;

procedure TAssetsForm.CollectionMenuButtonClick(Sender: TObject);
var
  At: TPointF;
begin
  if FCollection.Id = String.Empty then
    Exit;
  At := ClientToScreen(CollectionMenuButton.LocalToAbsolute(
    TPointF.Create(0, CollectionMenuButton.Height)));
  CollectionMenu.Popup(At.X, At.Y);
end;

procedure TAssetsForm.RenameCollectionItemClick(Sender: TObject);
begin
  if FCollection.Id = String.Empty then
    Exit;
  FAskName := gnRenameCollection;
  TDialogService.InputQuery('Rename Collection', ['New name for the collection'],
    [FCollection.Name], GroupNameClosed);
end;

procedure TAssetsForm.CollectionNamed(const AAsk: TGroupNameAsk; const AName: String);
var
  Entry: TSprite3DLibraryEntry;
  Id: String;
begin
  if AName = String.Empty then
    Exit;
  for Entry in FLibrary.Collections do
    if SameText(Entry.Name, AName) and
      ((AAsk = gnNewCollection) or not SameText(Entry.Id, FCollection.Id)) then
    begin
      TDialogService.ShowMessage('There is a collection called ' + AName + ' already.');
      Exit;
    end;
  if AAsk = gnRenameCollection then
  begin
    if FCollection.Id = String.Empty then
      Exit;
    Log('Assets: collection ' + FCollection.Name + ' renamed ' + AName);
    FCollection.Name := AName;
    for var I := 0 to High(FLibrary.Collections) do
      if SameText(FLibrary.Collections[I].Id, FCollection.Id) then
        FLibrary.Collections[I].Name := AName;
    SavePalette;
    SaveLibrary;
    FillCollections;
    Exit;
  end;
  // A new one, with its folders, scanned as it opens
  Id := NewCollection(AName, FNewSources);
  FNewSources := nil;
  if Id <> String.Empty then
    OpenCollection(Id);
end;

function TAssetsForm.NewCollection(const AName: String;
  const ASources: TArray<TSprite3DCollectionSource>): String;
var
  Made: TSprite3DAssetCollection;
  Entry: TSprite3DLibraryEntry;
begin
  Result := String.Empty;
  Made := Default(TSprite3DAssetCollection);
  Made.Id := NewCollectionId;
  Made.Name := AName;
  Made.Sources := ASources;
  try
    SaveAssetCollection(FCacheFolder, Made);
  except
    on E: Exception do
    begin
      Log('Assets: can''t save the collection ' + AName + ': ' + E.Message);
      Exit;
    end;
  end;
  Entry.Id := Made.Id;
  Entry.Name := Made.Name;
  FLibrary.Collections := FLibrary.Collections + [Entry];
  SaveLibrary;
  Log('Assets: collection ' + AName + ' added');
  Result := Made.Id;
end;

function TAssetsForm.HasCollection(const AName: String): Boolean;
begin
  for var Entry in FLibrary.Collections do
    if SameText(Entry.Name, AName) then
      Exit(True);
  Result := False;
end;

procedure TAssetsForm.AddArtistButtonClick(Sender: TObject);
var
  Roots, Folders, Formats, Defaults: TArray<String>;
  Found: TArray<TModelFolder>;
  Counts: TArray<Integer>;
  Ticks: TArray<Boolean>;
  Sources: TArray<TSprite3DCollectionSource>;
  Source: TSprite3DCollectionSource;
  CollectionName, Pick, Chosen, FirstId, Id: String;
  NewIds: TArray<String>;
  OnlyDefaults, Stopped: Boolean;
  Added, NoModels, NoFormat, Existing: Integer;
begin
  if not SelectFolders('Add Artist Collections', StartFolder, Roots) then
    Exit;
  FLibrary.LastFolder := Roots[0];
  SaveLibrary;
  // Each folder directly inside, in name order
  Folders := nil;
  for var Root in Roots do
    try
      Folders := Folders + TDirectory.GetDirectories(OSFriendlyPath(Root));
    except
      on E: Exception do
        Log('Assets: can''t read ' + Root + ': ' + E.Message);
    end;
  TArray.Sort<String>(Folders, TComparer<String>.Construct(
    function(const A, B: String): Integer
    begin
      Result := CompareText(A, B);
    end));
  if Length(Folders) = 0 then
  begin
    TDialogService.ShowMessage('There are no folders in ' + String.Join(', ', Roots) + '.');
    Exit;
  end;

  StopBulk('a new one started');
  NewIds := nil;
  Defaults := nil;
  OnlyDefaults := False;
  Stopped := False;
  FirstId := String.Empty;
  Added := 0;
  NoModels := 0;
  NoFormat := 0;
  Existing := 0;
  CollectionBar.Enabled := False;
  try
    for var Folder in Folders do
    begin
      CollectionName := ExtractFileName(ExcludeTrailingPathDelimiter(Folder));
      if HasCollection(CollectionName) then
      begin
        Log('Assets: ' + CollectionName + ' is a collection already; passed over');
        Inc(Existing);
        Continue;
      end;
      StatusLabel.Text := 'Looking in ' + CollectionName + '...';
      Application.ProcessMessages;
      Found := FindModelFolders([Folder]);
      if Length(Found) = 0 then
      begin
        Log('Assets: no models in ' + Folder);
        Inc(NoModels);
        Continue;
      end;
      Formats := FoundModelFormats(Found);
      // The first of the defaults so far that it has
      Pick := String.Empty;
      for var Ext in Defaults do
        if IndexText(Ext, Formats) >= 0 then
        begin
          Pick := Ext;
          Break;
        end;
      if Pick = String.Empty then
      begin
        if OnlyDefaults then
        begin
          Log('Assets: ' + CollectionName + ' has none of the formats chosen; passed over');
          Inc(NoFormat);
          Continue;
        end;
        SetLength(Counts, Length(Formats));
        for var I := 0 to High(Formats) do
        begin
          Counts[I] := 0;
          for var Item in Found do
            if Item.Format = Formats[I] then
              Inc(Counts[I], Item.Count);
        end;
        case AskFormat(CollectionName, Formats, Counts, Defaults, Chosen) of
          faImport:
            begin
              Pick := Chosen;
              Defaults := Defaults + [Chosen];
              Log('Assets: ' + ModelFormatName(Chosen) + ' is default ' +
                IntToStr(Length(Defaults)));
            end;
          faSkip:
            begin
              Inc(NoFormat);
              Continue;
            end;
          faOnlyDefaults:
            begin
              OnlyDefaults := True;
              Inc(NoFormat);
              Continue;
            end;
        else
          Stopped := True;
          Break;
        end;
      end;
      // That format's folders, an engine's second copy left out
      Ticks := DefaultModelFolders(Found, Pick);
      Sources := nil;
      for var I := 0 to High(Found) do
        if Ticks[I] then
        begin
          Source.Folder := Found[I].Folder;
          Source.Formats := [Found[I].Format];
          Sources := Sources + [Source];
        end;
      Id := NewCollection(CollectionName, Sources);
      if Id = String.Empty then
        Continue;
      Inc(Added);
      NewIds := NewIds + [Id];
      if FirstId = String.Empty then
        FirstId := Id;
    end;
  finally
    CollectionBar.Enabled := True;
  end;
  if Length(Defaults) > 0 then
  begin
    FLibrary.PreferredFormat := Defaults[0];
    SaveLibrary;
  end;
  FBulkSummary := Format('%d collections added.%s%s%s%s', [Added,
    IfThen(Existing > 0, Format(' %d were in the library already.', [Existing]), ''),
    IfThen(NoModels > 0, Format(' %d had no models.', [NoModels]), ''),
    IfThen(NoFormat > 0, Format(' %d had none of the formats chosen.', [NoFormat]), ''),
    IfThen(Stopped, ' Stopped before the end.', '')]);
  // Each imported in full now, one after another: folders read, thumbnails
  // made; the first is shown at the end
  FBulkQueue := NewIds;
  FBulkTotal := Length(NewIds);
  FBulkFirst := FirstId;
  FillCollections;
  if Length(NewIds) = 0 then
  begin
    TDialogService.ShowMessage(FBulkSummary);
    FBulkSummary := String.Empty;
    Exit;
  end;
  NextBulk;
end;

procedure TAssetsForm.NextBulk;
var
  Id: String;
  Probe: TSprite3DAssetCollection;
begin
  while Length(FBulkQueue) > 0 do
  begin
    Id := FBulkQueue[0];
    Delete(FBulkQueue, 0, 1);
    // One that cannot be read would never finish: passed over
    if LoadAssetCollection(FCacheFolder, Id, Probe) then
    begin
      OpenCollection(Id);
      Exit;
    end;
    Log('Assets: can''t read the collection ' + Id + '; passed over');
  end;
  // All done
  if FBulkTotal = 0 then
    Exit;
  FBulkTotal := 0;
  Log('Assets: artist collections imported');
  if FBulkFirst <> String.Empty then
    OpenCollection(FBulkFirst);
  FBulkFirst := String.Empty;
  if FBulkSummary <> String.Empty then
    TDialogService.ShowMessage(FBulkSummary);
  FBulkSummary := String.Empty;
end;

function TAssetsForm.BulkPrefix: String;
begin
  if FBulkTotal > 0 then
    Result := Format('Collection %d of %d, %s: ', [FBulkTotal - Length(FBulkQueue),
      FBulkTotal, FCollection.Name])
  else
    Result := String.Empty;
end;

procedure TAssetsForm.StopBulk(const AWhy: String);
begin
  if FBulkTotal = 0 then
    Exit;
  Log(Format('Assets: artist import stopped (%s); %d collections not yet imported will ' +
    'be as each is opened', [AWhy, Length(FBulkQueue)]));
  FBulkQueue := nil;
  FBulkTotal := 0;
  FBulkFirst := String.Empty;
  FBulkSummary := String.Empty;
  FBulkPending := False;
end;

procedure TAssetsForm.DeleteCollectionItemClick(Sender: TObject);
begin
  if FCollection.Id = String.Empty then
    Exit;
  TDialogService.MessageDialog('Delete the collection ' + FCollection.Name +
    ' from the library? Its groups go with it; its models, folders and thumbnails stay.',
    TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
    DeleteCollectionClosed);
end;

procedure TAssetsForm.DeleteCollectionClosed(Sender: TObject; const AResult: TModalResult);
var
  Id: String;
begin
  if (AResult <> mrYes) or (FCollection.Id = String.Empty) then
    Exit;
  Id := FCollection.Id;
  Log('Assets: collection ' + FCollection.Name + ' deleted');
  for var I := High(FLibrary.Collections) downto 0 do
    if SameText(FLibrary.Collections[I].Id, Id) then
      Delete(FLibrary.Collections, I, 1);
  if not DeleteAssetCollection(FCacheFolder, Id) then
    Log('Assets: can''t delete the file of collection ' + Id);
  FCollection := Default(TSprite3DAssetCollection);
  FLibrary.Last := String.Empty;
  SaveLibrary;
  if Length(FLibrary.Collections) > 0 then
    OpenCollection(FLibrary.Collections[0].Id)
  else
    OpenCollection(String.Empty);
end;


procedure TAssetsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Length(FQueue) > 0 then
    Log(Format('Assets: stopped with %d thumbnails still to make; open the collection ' +
      'again to carry on', [Length(FQueue) + Ord(FMaking >= 0)]));
  StopBulk('the Library closed');
  StopMaking;
  Action := TCloseAction.caHide;
end;

procedure TAssetsForm.Log(const AText: String);
begin
  if Assigned(FOnLog) then
    FOnLog(AText);
end;

function TAssetsForm.Making: Boolean;
begin
  Result := (FMaking >= 0) or (Length(FQueue) > 0);
end;

procedure TAssetsForm.ClearThumbnails;
var
  Count, Failed: Integer;
begin
  StopMaking;
  Inc(FScanId);   // drops hashing still under way
  Count := ClearAssetCache(FCacheFolder, Failed);
  Log(Format('Assets: %d cached thumbnails deleted from %s', [Count, FCacheFolder]));
  if Failed > 0 then
    Log(Format('Assets: %d files in %s could not be deleted', [Failed, FCacheFolder]));
  if Visible and (FCollection.Id <> String.Empty) then
    OpenCollection(FCollection.Id)
  else
  begin
    // Not showing: nothing to make now; opening a collection makes them
    FEntries := nil;
    SelectEntry(-1);
    BuildTiles;
    BuildGroups;
    StatusLabel.Text := 'Thumbnails cleared';
  end;
end;

procedure TAssetsForm.ScanCollection;
var
  Files: TArray<String>;
  ScanId: Integer;
  Alive: IAssetsAlive;
begin
  StopMaking;
  Inc(FScanId);
  if FCollection.Id = String.Empty then
    Exit;
  FScanning := True;
  Files := nil;
  for var Source in FCollection.Sources do
    if DirectoryExists(OSFriendlyPath(Source.Folder)) then
      Files := Files + AssetModelFilesOf(OSFriendlyPath(Source.Folder), Source.Formats)
    else
      Log('Assets: the folder ' + Source.Folder + ' of ' + FCollection.Name +
        ' is not there');
  if Length(Files) = 0 then
  begin
    StatusLabel.Text := 'No models in the collection''s folders';
    Log('Assets: no models in ' + SourcesText);
    // Still shown, with the groups it has
    HashesDone(FScanId, nil);
    Exit;
  end;
  StatusLabel.Text := BulkPrefix + Format('Reading %d models...', [Length(Files)]);
  Progress.Value := 0;
  Progress.Visible := True;
  Log(Format('Assets: %s, %d models in %s', [FCollection.Name, Length(Files),
    SourcesText]));

  // Only reading files: off the main thread. The results come back to the
  // main thread as one array, and are dropped if another folder has been
  // opened meanwhile or the form has gone
  ScanId := FScanId;
  Alive := FAlive;
  TTask.Run(
    procedure
    var
      Hasher: TSprite3DAssetHasher;
      Results: TArray<TAssetHashResult>;
    begin
      SetLength(Results, Length(Files));
      Hasher := TSprite3DAssetHasher.Create;
      try
        for var I := 0 to High(Files) do
        begin
          Results[I].FileName := Files[I];
          Results[I].Hash := Hasher.HashModel(Files[I], Results[I].Files,
            Results[I].Error);
        end;
      finally
        Hasher.Free;
      end;
      TThread.Queue(nil,
        procedure
        begin
          if Alive.Alive then
            HashesDone(ScanId, Results);
        end);
    end);
end;

procedure TAssetsForm.HashesDone(const AScanId: Integer;
  const AResults: TArray<TAssetHashResult>);
var
  Seen: TDictionary<String, String>;
  Entry: TAssetEntry;
  First, Chosen: String;
  Cached: Integer;
  NewGroups: TArray<String>;
begin
  if AScanId <> FScanId then
    Exit;   // another folder has been opened since
  FEntries := nil;
  FQueue := nil;
  Cached := 0;
  // The collection's palette as it is now: the groups, and every model's
  FPaletteGroups.Clear;
  FGroupIcons.Clear;
  FGroupParents.Clear;
  FGroupOrder := nil;
  for var Group in FCollection.Groups do
  begin
    FGroupOrder := FGroupOrder + [Group.Name];
    if Group.Icon <> String.Empty then
      FGroupIcons.AddOrSetValue(LowerCase(Group.Name), Group.Icon);
    if Group.Parent <> String.Empty then
      FGroupParents.AddOrSetValue(LowerCase(Group.Name), Group.Parent);
    for var Key in Group.Models do
      FPaletteGroups.AddOrSetValue(Key, Group.Name);
  end;
  // A parent that is not a group, or that would make a loop, is dropped:
  // that group goes to the top
  for var Key in FGroupParents.Keys.ToArray do
    if (GroupIndex(FGroupParents[Key]) < 0) or Holds(Key, FGroupParents[Key]) then
      FGroupParents.Remove(Key);
  Seen := TDictionary<String, String>.Create;
  try
    for var R in AResults do
    begin
      if R.Error <> String.Empty then
      begin
        Log('Assets: can''t read ' + R.FileName + ': ' + R.Error);
        Continue;
      end;
      if Seen.TryGetValue(R.Hash, First) then
      begin
        Log(Format('Assets: %s is the same model as %s; shown once', [R.FileName, First]));
        Continue;
      end;
      Seen.Add(R.Hash, R.FileName);
      Entry := Default(TAssetEntry);
      Entry.HasThumbnail := LoadAssetMeta(FCacheFolder, R.Hash, Entry.Meta) and
        (Entry.Meta.ThumbWidth = THUMBNAIL_SIZE) and
        (Entry.Meta.ThumbHeight = THUMBNAIL_SIZE) and
        TFile.Exists(AssetThumbnailFile(FCacheFolder, R.Hash));
      if not Entry.HasThumbnail then
      begin
        Entry.Meta := Default(TSprite3DAssetMeta);
        Entry.Meta.Hash := R.Hash;
      end
      else
        Inc(Cached);
      // Where it is now, whatever the cache last saw
      Entry.Meta.Name := ChangeFileExt(ExtractFileName(R.FileName), '');
      Entry.GroupChosen := FPaletteGroups.TryGetValue(R.Hash, Chosen);
      if Entry.GroupChosen then
        Entry.Meta.Group := Chosen
      else
        Entry.Meta.Group := AssetGroupName(Entry.Meta.Name);
      Entry.Meta.FileName := R.FileName;
      // A collection opened from its saved models knows only each file
      if R.Files <> nil then
        Entry.Meta.Files := R.Files;
      FEntries := FEntries + [Entry];
    end;
  finally
    Seen.Free;
  end;
  MergePluralGroups;
  // Every model in the palette, and every group new to it last, in
  // alphabetical order, so the palette holds the folder from now on
  NewGroups := nil;
  for var I := 0 to High(FEntries) do
  begin
    FPaletteGroups.AddOrSetValue(FEntries[I].Meta.Hash, FEntries[I].Meta.Group);
    FEntries[I].GroupChosen := True;
    if (GroupIndex(FEntries[I].Meta.Group) < 0) and
      (IndexText(FEntries[I].Meta.Group, NewGroups) < 0) then
      NewGroups := NewGroups + [FEntries[I].Meta.Group];
  end;
  TArray.Sort<String>(NewGroups, TComparer<String>.Construct(
    function(const A, B: String): Integer
    begin
      Result := CompareText(A, B);
    end));
  FGroupOrder := FGroupOrder + NewGroups;
  // From a scan, the models are now the folders' as they are
  if FScanning then
    FCollection.Scanned := True;
  FScanning := False;
  SavePalette;

  // Name order throughout, whatever the group: a move to another group
  // leaves every entry where it is
  TArray.Sort<TAssetEntry>(FEntries, TComparer<TAssetEntry>.Construct(
    function(const A, B: TAssetEntry): Integer
    begin
      Result := CompareText(A.Meta.Name, B.Meta.Name);
      if Result = 0 then
        Result := CompareText(A.Meta.FileName, B.Meta.FileName);
    end));
  for var I := 0 to High(FEntries) do
    if not FEntries[I].HasThumbnail then
      FQueue := FQueue + [I];
  FQueueTotal := Length(FQueue);
  // Timed from the first, for the time left
  FMakeWatch := TStopwatch.StartNew;

  BuildTiles;
  FGroup := String.Empty;
  BuildGroups;
  Log(Format('Assets: %d models shown, %d thumbnails from the cache, %d to make',
    [Length(FEntries), Cached, FQueueTotal]));
  MakeNext;
end;

procedure TAssetsForm.MergePluralGroups;
var
  Groups: TDictionary<String, Boolean>;
  Group: String;
begin
  Groups := TDictionary<String, Boolean>.Create;
  try
    for var Entry in FEntries do
      Groups.AddOrSetValue(Entry.Meta.Group, True);
    for var GroupName in FGroupOrder do
      Groups.AddOrSetValue(GroupName, True);
    for var I := 0 to High(FEntries) do
    begin
      if FEntries[I].GroupChosen then
        Continue;   // the user's choice stands
      Group := FEntries[I].Meta.Group;
      if (Group.Length > 1) and Group.EndsWith('s') and
        Groups.ContainsKey(Group.Substring(0, Group.Length - 1)) then
        FEntries[I].Meta.Group := Group.Substring(0, Group.Length - 1);
    end;
  finally
    Groups.Free;
  end;
end;

procedure TAssetsForm.BuildGroups;
var
  Count, Chosen: Integer;
  Tile: TRectangle;
  Icon: TImage;
  Caption: TLabel;
  Bitmap: TBitmap;
begin
  FDropIndex := -1;
  // The top groups in the palette's order; another kit's are kept but not
  // shown
  FShownGroups := nil;
  for var GroupName in ChildGroups(String.Empty) do
    if GroupShown(GroupName) then
      FShownGroups := FShownGroups + [GroupName];

  GroupsBox.BeginUpdate;
  try
    for var Old in FGroupTiles do
      Old.Free;
    FGroupTiles := nil;
    Chosen := -1;
    for var I := 0 to High(FShownGroups) do
    begin
      Count := FolderTotal(FShownGroups[I]);
      Tile := TRectangle.Create(GroupsBox);
      Tile.Parent := GroupsBox;
      Tile.Align := TAlignLayout.Top;
      // Each below the last: Align Top places by Position
      Tile.Position.Y := I * (GROUP_TILE_HEIGHT + 4) + 1;
      Tile.Height := GROUP_TILE_HEIGHT;
      Tile.Margins.Rect := TRectF.Create(3, 2, 3, 2);
      Tile.XRadius := 4;
      Tile.YRadius := 4;
      Tile.Fill.Kind := TBrushKind.None;
      Tile.Stroke.Kind := TBrushKind.None;
      Tile.Tag := I;
      Tile.TagString := FShownGroups[I];
      Tile.AutoCapture := True;
      Tile.OnMouseDown := GroupTileMouseDown;
      Tile.OnMouseMove := GroupTileMouseMove;
      Tile.OnMouseUp := GroupTileMouseUp;

      Icon := TImage.Create(Tile);
      Icon.Parent := Tile;
      Icon.Align := TAlignLayout.Top;
      Icon.Height := GROUP_ICON_SIZE;
      Icon.Margins.Rect := TRectF.Create(0, 6, 0, 0);
      Icon.WrapMode := TImageWrapMode.Fit;
      Icon.HitTest := False;
      Bitmap := GroupIcon(FShownGroups[I]);
      if Bitmap <> nil then
        Icon.Bitmap.Assign(Bitmap);

      Caption := TLabel.Create(Tile);
      Caption.Parent := Tile;
      Caption.Align := TAlignLayout.Client;
      Caption.Margins.Rect := TRectF.Create(4, 0, 4, 2);
      Caption.StyledSettings := Caption.StyledSettings - [TStyledSetting.Size];
      Caption.TextSettings.Font.Size := GROUP_FONT_SIZE;
      Caption.TextSettings.HorzAlign := TTextAlign.Center;
      Caption.TextSettings.WordWrap := False;
      Caption.TextSettings.Trimming := TTextTrimming.Character;
      Caption.Text := Format('%s (%d)', [FShownGroups[I], Count]);
      Caption.HitTest := False;

      FGroupTiles := FGroupTiles + [Tile];
      if SameText(FShownGroups[I], RootOf(FGroup)) then
        Chosen := I;
    end;
  finally
    GroupsBox.EndUpdate;
  end;
  // The group shown stays if it is still there, its picks with it
  if (FGroup <> String.Empty) and (GroupIndex(FGroup) >= 0) and GroupShown(FGroup) and
    (Chosen >= 0) then
  begin
    FGroup := FGroupOrder[GroupIndex(FGroup)];
    BuildFolderTiles;
    LayoutTiles;
    UpdateGroupMarks;
    UpdatePath;
  end
  else if Length(FShownGroups) > 0 then
    ShowGroup(FShownGroups[0])
  else
    ShowGroup(String.Empty);
end;

procedure TAssetsForm.UpdateGroupMarks;
var
  Root: String;
begin
  Root := RootOf(FGroup);
  for var I := 0 to High(FGroupTiles) do
  begin
    if SameText(FShownGroups[I], Root) then
    begin
      FGroupTiles[I].Fill.Kind := TBrushKind.Solid;
      FGroupTiles[I].Fill.Color := GROUP_CHOSEN_FILL;
    end
    else
      FGroupTiles[I].Fill.Kind := TBrushKind.None;
    if I = FDropIndex then
    begin
      FGroupTiles[I].Stroke.Kind := TBrushKind.Solid;
      FGroupTiles[I].Stroke.Color := GROUP_DROP_STROKE;
      FGroupTiles[I].Stroke.Thickness := 2;
    end
    else
      FGroupTiles[I].Stroke.Kind := TBrushKind.None;
  end;
  for var I := 0 to High(FFolderTiles) do
    if I = FDropFolder then
    begin
      FFolderTiles[I].Stroke.Color := GROUP_DROP_STROKE;
      FFolderTiles[I].Stroke.Thickness := 2;
    end
    else
    begin
      FFolderTiles[I].Stroke.Color := TILE_STROKE;
      FFolderTiles[I].Stroke.Thickness := 1;
    end;
  if FDropInto then
  begin
    TilesPanel.Stroke.Kind := TBrushKind.Solid;
    TilesPanel.Stroke.Color := GROUP_DROP_STROKE;
    TilesPanel.Stroke.Thickness := 2;
  end
  else
    TilesPanel.Stroke.Kind := TBrushKind.None;
end;

function TAssetsForm.ParentOf(const AGroup: String): String;
begin
  if not FGroupParents.TryGetValue(LowerCase(AGroup), Result) then
    Result := String.Empty;
end;

function TAssetsForm.RootOf(const AGroup: String): String;
var
  Steps: Integer;
begin
  Result := AGroup;
  // Bounded, so a loop in a damaged palette cannot hang it
  Steps := Length(FGroupOrder);
  while (ParentOf(Result) <> String.Empty) and (Steps >= 0) do
  begin
    Result := ParentOf(Result);
    Dec(Steps);
  end;
end;

function TAssetsForm.Holds(const AOuter, AGroup: String): Boolean;
var
  Group: String;
  Steps: Integer;
begin
  Group := AGroup;
  Steps := Length(FGroupOrder);
  while (Group <> String.Empty) and (Steps >= 0) do
  begin
    if SameText(Group, AOuter) then
      Exit(True);
    Group := ParentOf(Group);
    Dec(Steps);
  end;
  Result := False;
end;

function TAssetsForm.ChildGroups(const AGroup: String): TArray<String>;
begin
  Result := nil;
  for var GroupName in FGroupOrder do
    if SameText(ParentOf(GroupName), AGroup) then
      Result := Result + [GroupName];
  // Alphabetical, case ignored, at every level
  TArray.Sort<String>(Result, TComparer<String>.Construct(
    function(const A, B: String): Integer
    begin
      Result := CompareText(A, B);
    end));
end;

function TAssetsForm.FolderTotal(const AGroup: String): Integer;
begin
  Result := 0;
  for var Entry in FEntries do
    if Holds(AGroup, Entry.Meta.Group) then
      Inc(Result);
end;

function TAssetsForm.GroupShown(const AGroup: String): Boolean;
begin
  // Models of this folder in it or below, or nothing anywhere: a new group
  Result := (FolderTotal(AGroup) > 0) or GroupEmpty(AGroup);
  if not Result then
    for var Child in ChildGroups(AGroup) do
      if GroupShown(Child) then
        Exit(True);
end;

function TAssetsForm.GroupEmpty(const AGroup: String): Boolean;
begin
  Result := (PaletteCount(AGroup) = 0) and (Length(ChildGroups(AGroup)) = 0);
end;

procedure TAssetsForm.Reparent(const AGroup, AParent: String);
var
  At: Integer;
  Group: String;
begin
  At := GroupIndex(AGroup);
  if At < 0 then
    Exit;
  Group := FGroupOrder[At];
  if AParent <> String.Empty then
  begin
    // Never into itself, or into a group inside it
    if (GroupIndex(AParent) < 0) or Holds(Group, AParent) or
      SameText(ParentOf(Group), AParent) then
      Exit;
    FGroupParents.AddOrSetValue(LowerCase(Group), FGroupOrder[GroupIndex(AParent)]);
    Log('Assets: group ' + Group + ' put inside ' + AParent);
  end
  else
  begin
    if ParentOf(Group) = String.Empty then
      Exit;
    FGroupParents.Remove(LowerCase(Group));
    Log('Assets: group ' + Group + ' moved to the top');
  end;
  SavePalette;
  BuildGroups;
end;

procedure TAssetsForm.BuildFolderTiles;
var
  Tile: TRectangle;
  Icon: TImage;
  Caption: TLabel;
  Bitmap: TBitmap;
begin
  FDropFolder := -1;
  for var Old in FFolderTiles do
    Old.Free;
  FFolderTiles := nil;
  FFolderNames := nil;
  if FGroup = String.Empty then
    Exit;
  for var GroupName in ChildGroups(FGroup) do
  begin
    if not GroupShown(GroupName) then
      Continue;
    Tile := TRectangle.Create(FTilesLayout);
    Tile.Parent := FTilesLayout;
    Tile.Width := TILE_WIDTH;
    Tile.Height := TILE_HEIGHT;
    Tile.XRadius := 4;
    Tile.YRadius := 4;
    // A group, not a model: a fill of its own
    Tile.Fill.Kind := TBrushKind.Solid;
    Tile.Fill.Color := FOLDER_FILL;
    Tile.Stroke.Color := TILE_STROKE;
    Tile.Tag := Length(FFolderNames);
    Tile.TagString := GroupName;
    Tile.Hint := GroupName + ': double-click to open';
    Tile.ShowHint := True;
    Tile.AutoCapture := True;
    Tile.OnMouseDown := FolderTileMouseDown;
    Tile.OnMouseMove := GroupTileMouseMove;
    Tile.OnMouseUp := GroupTileMouseUp;

    Icon := TImage.Create(Tile);
    Icon.Parent := Tile;
    Icon.Align := TAlignLayout.Top;
    Icon.Height := TILE_IMAGE;
    Icon.Margins.Rect := TRectF.Create(20, 20, 20, 0);
    Icon.WrapMode := TImageWrapMode.Fit;
    Icon.HitTest := False;
    Bitmap := GroupIcon(GroupName);
    if Bitmap <> nil then
      Icon.Bitmap.Assign(Bitmap);

    Caption := TLabel.Create(Tile);
    Caption.Parent := Tile;
    Caption.Align := TAlignLayout.Client;
    Caption.Margins.Rect := TRectF.Create(2, 0, 2, 2);
    Caption.StyledSettings := Caption.StyledSettings - [TStyledSetting.Size,
      TStyledSetting.Style];
    Caption.TextSettings.Font.Size := 11;
    Caption.TextSettings.Font.Style := [TFontStyle.fsBold];
    Caption.TextSettings.HorzAlign := TTextAlign.Center;
    Caption.TextSettings.WordWrap := False;
    Caption.TextSettings.Trimming := TTextTrimming.Character;
    Caption.Text := Format('%s (%d)', [GroupName, FolderTotal(GroupName)]);
    Caption.HitTest := False;

    FFolderTiles := FFolderTiles + [Tile];
    FFolderNames := FFolderNames + [GroupName];
  end;
end;

function TAssetsForm.FolderTileAt(const AAbsolute: TPointF): Integer;
var
  At: TPointF;
begin
  Result := -1;
  if not OverTiles(AAbsolute) then
    Exit;
  for var I := 0 to High(FFolderTiles) do
  begin
    At := FFolderTiles[I].AbsoluteToLocal(AAbsolute);
    if (At.X >= 0) and (At.Y >= 0) and (At.X < FFolderTiles[I].Width) and
      (At.Y < FFolderTiles[I].Height) then
      Exit(I);
  end;
end;

function TAssetsForm.OverTiles(const AAbsolute: TPointF): Boolean;
var
  At: TPointF;
begin
  At := TilesPanel.AbsoluteToLocal(AAbsolute);
  Result := (At.X >= 0) and (At.Y >= 0) and (At.X <= TilesPanel.Width) and
    (At.Y <= TilesPanel.Height);
end;

procedure TAssetsForm.UpdatePath;
var
  Path, Group: String;
  Steps: Integer;
begin
  Path := FGroup;
  Group := ParentOf(FGroup);
  Steps := Length(FGroupOrder);
  while (Group <> String.Empty) and (Steps >= 0) do
  begin
    Path := Group + ' / ' + Path;
    Group := ParentOf(Group);
    Dec(Steps);
  end;
  PathLabel.Text := Path;
  UpButton.Enabled := ParentOf(FGroup) <> String.Empty;
end;

procedure TAssetsForm.UpdatePreviewLabel;
begin
  FPreviewLabel.Visible := FModel = nil;
  if FPreviewLabel.Visible then
    FPreviewLabel.BringToFront;
end;

procedure TAssetsForm.UpButtonClick(Sender: TObject);
begin
  if ParentOf(FGroup) <> String.Empty then
    ShowGroup(ParentOf(FGroup));
end;

procedure TAssetsForm.FolderTileMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if not (Sender is TRectangle) or (Button <> TMouseButton.mbLeft) or
    (ssCtrl in Shift) then
    Exit;
  if ssDouble in Shift then
  begin
    // Opened once this handler has returned, as the tiles are made again
    FOpenGroup := TRectangle(Sender).TagString;
    Defer;
    Exit;
  end;
  FGroupDown := TRectangle(Sender).TagString;
  FGroupDownInGrid := True;
  FDownAt := TRectangle(Sender).LocalToAbsolute(TPointF.Create(X, Y));
  FDragging := False;
end;

procedure TAssetsForm.TrackGroupDrag(const At: TPointF);
var
  Index, Folder: Integer;
  Below, Into: Boolean;
begin
  // A button on the left: inside that group
  Index := GroupTileAt(At, Below);
  if (Index >= 0) and Holds(FGroupDown, FShownGroups[Index]) then
    Index := -1;
  Folder := FolderTileAt(At);
  if (Folder >= 0) and Holds(FGroupDown, FFolderNames[Folder]) then
    Folder := -1;
  // The grid's empty space: inside the group shown
  Into := (Folder < 0) and OverTiles(At) and not Holds(FGroupDown, FGroup) and
    not SameText(ParentOf(FGroupDown), FGroup);
  FDropBelow := Below and (ParentOf(FGroupDown) <> String.Empty);
  FDropFolder := Folder;
  FDropInto := Into;
  SetDropIndex(Index);
  UpdateGroupMarks;
end;

procedure TAssetsForm.DropGroup(const At: TPointF);
var
  Index, Folder: Integer;
  Below: Boolean;
  Group: String;
begin
  Group := FGroupDown;
  Index := GroupTileAt(At, Below);
  Folder := FolderTileAt(At);
  // Done once this handler has returned, as the buttons and tiles are made
  // again for it
  if Folder >= 0 then
  begin
    if not Holds(Group, FFolderNames[Folder]) then
    begin
      FReparentGroup := Group;
      FReparentTo := FFolderNames[Folder];
    end;
  end
  else if Index >= 0 then
  begin
    // Onto a button: inside that group
    if Holds(Group, FShownGroups[Index]) then
      Exit;
    FReparentGroup := Group;
    FReparentTo := FShownGroups[Index];
  end
  else if Below then
  begin
    // Below the buttons: back to the top
    if ParentOf(Group) = String.Empty then
      Exit;
    FReparentGroup := Group;
    FReparentTo := String.Empty;
  end
  else if OverTiles(At) and not Holds(Group, FGroup) and
    not SameText(ParentOf(Group), FGroup) then
  begin
    FReparentGroup := Group;
    FReparentTo := FGroup;
  end
  else
    Exit;
  Defer;
end;

function TAssetsForm.IconFile(const AName: String): String;
begin
  Result := String.Empty;
  if AName = String.Empty then
    Exit;
  for var Folder in TArray<String>.Create(TSprite3DAppSettings.UserGroupIconsFolder,
    GroupIconsFolder) do
    if (Folder <> String.Empty) and TFile.Exists(TPath.Combine(Folder, AName)) then
      Exit(TPath.Combine(Folder, AName));
end;

function TAssetsForm.GroupIcon(const AGroup: String): TBitmap;
var
  Chosen, FileName: String;
  Bitmap: TBitmap;
begin
  Result := nil;
  // The one chosen, or the library's of the group's name
  FileName := String.Empty;
  if FGroupIcons.TryGetValue(LowerCase(AGroup), Chosen) then
    FileName := IconFile(Chosen);
  if FileName = String.Empty then
    for var Ext in GROUP_ICON_EXTENSIONS do
    begin
      FileName := IconFile(LowerCase(AGroup) + Ext);
      if FileName <> String.Empty then
        Break;
    end;
  if FileName <> String.Empty then
  begin
    if FIconBitmaps.TryGetValue(FileName, Result) then
      Exit;
    Bitmap := LoadGroupIcon(FileName, GROUP_ICON_PIXELS, GROUP_ICON_COLOUR);
    if Bitmap <> nil then
    begin
      FIconBitmaps.AddOrSetValue(FileName, Bitmap);
      Exit(Bitmap);
    end;
    Log('Assets: can''t read the icon ' + FileName);
  end;
  // Else its first model's thumbnail
  for var Entry in FEntries do
    if Holds(AGroup, Entry.Meta.Group) and Entry.HasThumbnail and
      (Entry.Image <> nil) and not Entry.Image.Bitmap.IsEmpty then
      Exit(Entry.Image.Bitmap);
end;

function TAssetsForm.GroupTileAt(const AAbsolute: TPointF; out ABelow: Boolean): Integer;
var
  At: TPointF;
begin
  Result := -1;
  ABelow := False;
  At := GroupsBox.AbsoluteToLocal(AAbsolute);
  if (At.X < 0) or (At.Y < 0) or (At.X > GroupsBox.Width) or (At.Y > GroupsBox.Height) then
    Exit;
  for var I := 0 to High(FGroupTiles) do
  begin
    At := FGroupTiles[I].AbsoluteToLocal(AAbsolute);
    if (At.Y >= -FGroupTiles[I].Margins.Top) and
      (At.Y < FGroupTiles[I].Height + FGroupTiles[I].Margins.Bottom) then
      Exit(I);
  end;
  // Inside the box and on no button: below them all, or above the first
  ABelow := (Length(FGroupTiles) = 0) or
    (FGroupTiles[High(FGroupTiles)].AbsoluteToLocal(AAbsolute).Y > 0);
end;

procedure TAssetsForm.SetDropIndex(const AIndex: Integer);
begin
  if AIndex = FDropIndex then
    Exit;
  FDropIndex := AIndex;
  UpdateGroupMarks;
end;

procedure TAssetsForm.EndDrag;
begin
  FDragging := False;
  FScrollTimer.Enabled := False;
  FDragGhost.Visible := False;
  FDropFolder := -1;
  FDropInto := False;
  FDropBelow := False;
  FDropIndex := -1;
  UpdateGroupMarks;
end;

procedure TAssetsForm.Defer;
begin
  FDeferTimer.Enabled := False;
  FDeferTimer.Enabled := True;
end;

procedure TAssetsForm.DeferredWork(Sender: TObject);
var
  Group: String;
begin
  FDeferTimer.Enabled := False;
  if FBulkPending then
  begin
    FBulkPending := False;
    NextBulk;
  end;
  if FOpenGroup <> String.Empty then
  begin
    Group := FOpenGroup;
    FOpenGroup := String.Empty;
    if GroupIndex(Group) >= 0 then
      ShowGroup(FGroupOrder[GroupIndex(Group)]);
  end;
  if FReparentGroup <> String.Empty then
  begin
    Group := FReparentGroup;
    FReparentGroup := String.Empty;
    Reparent(Group, FReparentTo);
    FReparentTo := String.Empty;
  end;
end;

procedure TAssetsForm.GroupTileMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if not (Sender is TRectangle) or (Button <> TMouseButton.mbLeft) or
    (ssCtrl in Shift) then
    Exit;
  // Chosen at once, and stays chosen until another is; from inside one of
  // its groups, back to its top
  if not SameText(TRectangle(Sender).TagString, FGroup) then
    ShowGroup(TRectangle(Sender).TagString);
  FGroupDown := TRectangle(Sender).TagString;
  FGroupDownInGrid := False;
  FDownAt := TRectangle(Sender).LocalToAbsolute(TPointF.Create(X, Y));
  FDragging := False;
end;

procedure TAssetsForm.GroupTileMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Single);
var
  At: TPointF;
begin
  if (FGroupDown = String.Empty) or not (Sender is TRectangle) then
    Exit;
  if not (ssLeft in Shift) then
  begin
    FGroupDown := String.Empty;
    EndDrag;
    Exit;
  end;
  At := TRectangle(Sender).LocalToAbsolute(TPointF.Create(X, Y));
  if not FDragging then
  begin
    if At.Distance(FDownAt) < TILE_DRAG_START then
      Exit;
    // The group's icon follows the pointer
    FDragGhost.Bitmap.Assign(GroupIcon(FGroupDown));
    FDragCount.Text := String.Empty;
    BeginDrag;
  end;
  FDragAt := At;
  FDragGhost.Position.Point := TPointF.Create(At.X - GHOST_SIZE / 2, At.Y - GHOST_SIZE / 2);
  TrackGroupDrag(At);
end;

procedure TAssetsForm.GroupTileMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  At: TPointF;
  Dragged: Boolean;
begin
  if not (Sender is TRectangle) then
    Exit;
  At := TRectangle(Sender).LocalToAbsolute(TPointF.Create(X, Y));
  if (Button = TMouseButton.mbRight) or
    ((Button = TMouseButton.mbLeft) and (ssCtrl in Shift)) then
  begin
    FMenuInGrid := TRectangle(Sender).Parent = FTilesLayout;
    ShowGroupMenu(TRectangle(Sender).TagString, At);
    Exit;
  end;
  if Button <> TMouseButton.mbLeft then
    Exit;
  Dragged := FDragging and (FGroupDown <> String.Empty);
  if Dragged then
    DropGroup(At);
  FGroupDown := String.Empty;
  FGroupDownInGrid := False;
  EndDrag;
end;

procedure TAssetsForm.GroupsBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if (Button = TMouseButton.mbRight) or
    ((Button = TMouseButton.mbLeft) and (ssCtrl in Shift)) then
  begin
    FMenuInGrid := False;
    ShowGroupMenu(String.Empty, GroupsBox.LocalToAbsolute(TPointF.Create(X, Y)));
  end;
end;

procedure TAssetsForm.TilesBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if (FGroup <> String.Empty) and ((Button = TMouseButton.mbRight) or
    ((Button = TMouseButton.mbLeft) and (ssCtrl in Shift))) then
  begin
    FMenuInGrid := True;
    ShowGroupMenu(String.Empty, TilesBox.LocalToAbsolute(TPointF.Create(X, Y)));
  end;
end;

procedure TAssetsForm.ShowGroupMenu(const AGroup: String; const AAbsolute: TPointF);
var
  At: TPointF;
begin
  if FDragging or (Length(FEntries) = 0) then
    Exit;
  FMenuGroup := AGroup;
  RenameGroupItem.Enabled := AGroup <> String.Empty;
  IconGroupItem.Enabled := AGroup <> String.Empty;
  DeleteGroupItem.Enabled := (AGroup <> String.Empty) and GroupEmpty(AGroup);
  AddGroupItem.Text := IfThen(FMenuInGrid, 'Add Group Inside "' + FGroup + '"...',
    'Add Group...');
  if AGroup <> String.Empty then
  begin
    RenameGroupItem.Text := 'Rename "' + AGroup + '"...';
    DeleteGroupItem.Text := 'Delete "' + AGroup + '"';
  end
  else
  begin
    RenameGroupItem.Text := 'Rename Group...';
    DeleteGroupItem.Text := 'Delete Group';
  end;
  At := ClientToScreen(AAbsolute);
  GroupMenu.Popup(At.X, At.Y);
end;

procedure TAssetsForm.AddGroupItemClick(Sender: TObject);
begin
  FAskName := gnAdd;
  TDialogService.InputQuery('Add Group', ['Name of the new group'], [''],
    GroupNameClosed);
end;

procedure TAssetsForm.RenameGroupItemClick(Sender: TObject);
var
  Prompt: String;
begin
  if FMenuGroup = String.Empty then
    Exit;
  FAskName := gnRename;
  Prompt := 'New name for ' + FMenuGroup;
  TDialogService.InputQuery('Rename Group', [Prompt], [FMenuGroup], GroupNameClosed);
end;

procedure TAssetsForm.GroupNameClosed(Sender: TObject; const AResult: TModalResult;
  const AValues: array of String);
var
  Ask: TGroupNameAsk;
  GroupName, Old: String;
  At, Clash: Integer;
begin
  Ask := FAskName;
  FAskName := gnNone;
  if (AResult <> mrOk) or (Length(AValues) = 0) then
    Exit;
  if Ask in [gnNewCollection, gnRenameCollection] then
  begin
    CollectionNamed(Ask, Trim(AValues[0]));
    Exit;
  end;
  GroupName := LowerCase(Trim(AValues[0]));
  if GroupName = String.Empty then
    Exit;
  Clash := GroupIndex(GroupName);
  case Ask of
    gnAdd:
      begin
        if Clash >= 0 then
        begin
          TDialogService.ShowMessage('There is a group called ' + GroupName + ' already.');
          Exit;
        end;
        // In the grid, inside the group shown, else at the top; in its
        // alphabetical place either way
        FGroupOrder := FGroupOrder + [GroupName];
        if FMenuInGrid and (FGroup <> String.Empty) then
        begin
          FGroupParents.AddOrSetValue(LowerCase(GroupName), FGroup);
          Log('Assets: group ' + GroupName + ' added inside ' + FGroup);
        end
        else
          Log('Assets: group ' + GroupName + ' added');
      end;
    gnRename:
      begin
        At := GroupIndex(FMenuGroup);
        if At < 0 then
          Exit;
        Old := FGroupOrder[At];
        if SameText(GroupName, Old) then
          Exit;
        if Clash >= 0 then
        begin
          TDialogService.ShowMessage('There is a group called ' + GroupName + ' already.');
          Exit;
        end;
        FGroupOrder[At] := GroupName;
        for var Key in FPaletteGroups.Keys.ToArray do
          if SameText(FPaletteGroups[Key], Old) then
            FPaletteGroups[Key] := GroupName;
        for var I := 0 to High(FEntries) do
          if SameText(FEntries[I].Meta.Group, Old) then
            FEntries[I].Meta.Group := GroupName;
        // The groups inside it, and its own place
        for var Key in FGroupParents.Keys.ToArray do
          if SameText(FGroupParents[Key], Old) then
            FGroupParents[Key] := GroupName;
        if FGroupParents.ContainsKey(LowerCase(Old)) then
        begin
          FGroupParents.AddOrSetValue(LowerCase(GroupName), FGroupParents[LowerCase(Old)]);
          FGroupParents.Remove(LowerCase(Old));
        end;
        if FGroupIcons.ContainsKey(LowerCase(Old)) then
        begin
          FGroupIcons.AddOrSetValue(LowerCase(GroupName), FGroupIcons[LowerCase(Old)]);
          FGroupIcons.Remove(LowerCase(Old));
        end;
        if SameText(FGroup, Old) then
          FGroup := GroupName;
        Log('Assets: group ' + Old + ' renamed ' + GroupName);
      end;
  else
    Exit;
  end;
  SavePalette;
  BuildGroups;
  // A new group at the top is chosen; one inside is a tile in the grid
  if (Ask = gnAdd) and not FMenuInGrid then
    ShowGroup(GroupName);
end;

procedure TAssetsForm.IconGroupItemClick(Sender: TObject);
var
  Group, Source, IconName, Folder, Target: String;
begin
  Group := FMenuGroup;
  if Group = String.Empty then
    Exit;
  IconDialog.Title := 'Icon for ' + Group;
  IconDialog.Filter := 'Icons (*.svg;*.png)|*.svg;*.png|All files (*.*)|*.*';
  // The library that comes with the program, or the user's own
  Folder := GroupIconsFolder;
  if Folder = String.Empty then
    Folder := TSprite3DAppSettings.UserGroupIconsFolder;
  IconDialog.InitialDir := Folder;
  IconDialog.FileName := String.Empty;
  if not IconDialog.Execute then
    Exit;
  Source := IconDialog.FileName;
  if not IsGroupIconFile(Source) then
  begin
    TDialogService.ShowMessage('An icon is an SVG or PNG file.');
    Exit;
  end;
  IconName := ExtractFileName(Source);
  // From the library as it is; from elsewhere, copied into the user's own
  if not SameText(IconFile(IconName), ExpandFileName(Source)) then
  begin
    Target := TPath.Combine(TSprite3DAppSettings.UserGroupIconsFolder, IconName);
    try
      ForceDirectories(TSprite3DAppSettings.UserGroupIconsFolder);
      TFile.Copy(Source, Target, True);
    except
      on E: Exception do
      begin
        Log('Assets: can''t copy the icon ' + Source + ' to ' + Target + ': ' + E.Message);
        Exit;
      end;
    end;
    FIconBitmaps.Remove(Target);
  end;
  FGroupIcons.AddOrSetValue(LowerCase(Group), IconName);
  Log('Assets: group ' + Group + ' has the icon ' + IconName);
  SavePalette;
  BuildGroups;
end;

procedure TAssetsForm.DeleteGroupItemClick(Sender: TObject);
var
  At: Integer;
begin
  At := GroupIndex(FMenuGroup);
  if (At < 0) or not GroupEmpty(FMenuGroup) then
    Exit;
  Log('Assets: group ' + FGroupOrder[At] + ' deleted');
  FGroupIcons.Remove(LowerCase(FGroupOrder[At]));
  FGroupParents.Remove(LowerCase(FGroupOrder[At]));
  // Shown no more: its outer group instead
  if SameText(FGroup, FGroupOrder[At]) then
    FGroup := ParentOf(FGroupOrder[At]);
  Delete(FGroupOrder, At, 1);
  SavePalette;
  BuildGroups;
end;

function TAssetsForm.GroupIndex(const AGroup: String): Integer;
begin
  for var I := 0 to High(FGroupOrder) do
    if SameText(FGroupOrder[I], AGroup) then
      Exit(I);
  Result := -1;
end;

function TAssetsForm.PaletteCount(const AGroup: String): Integer;
begin
  Result := 0;
  for var Group in FPaletteGroups.Values do
    if SameText(Group, AGroup) then
      Inc(Result);
end;

procedure TAssetsForm.SavePalette;
var
  Palette: TArray<TSprite3DPaletteGroup>;
  Present: TDictionary<String, Boolean>;
  Others: TArray<String>;
  Group: TSprite3DPaletteGroup;
  Model: TSprite3DCollectionModel;
begin
  // A group a model is in that the order lacks goes last, so none is lost
  for var Pair in FPaletteGroups do
    if GroupIndex(Pair.Value) < 0 then
      FGroupOrder := FGroupOrder + [Pair.Value];
  Present := TDictionary<String, Boolean>.Create;
  try
    for var Entry in FEntries do
      Present.AddOrSetValue(Entry.Meta.Hash, True);
    Palette := nil;
    for var GroupName in FGroupOrder do
    begin
      Group.Name := GroupName;
      Group.Models := nil;
      if not FGroupIcons.TryGetValue(LowerCase(GroupName), Group.Icon) then
        Group.Icon := String.Empty;
      Group.Parent := ParentOf(GroupName);
      // FEntries is in name order
      for var Entry in FEntries do
        if SameText(Entry.Meta.Group, GroupName) then
          Group.Models := Group.Models + [Entry.Meta.Hash];
      Others := nil;
      for var Pair in FPaletteGroups do
        if SameText(Pair.Value, GroupName) and not Present.ContainsKey(Pair.Key) then
          Others := Others + [Pair.Key];
      TArray.Sort<String>(Others);
      Group.Models := Group.Models + Others;
      Palette := Palette + [Group];
    end;
  finally
    Present.Free;
  end;
  if FCollection.Id = String.Empty then
    Exit;
  FCollection.Groups := Palette;
  // The models as they are now, with their files
  FCollection.Models := nil;
  for var Entry in FEntries do
  begin
    Model.Key := Entry.Meta.Hash;
    Model.FileName := Entry.Meta.FileName;
    FCollection.Models := FCollection.Models + [Model];
  end;
  try
    SaveAssetCollection(FCacheFolder, FCollection);
  except
    on E: Exception do
      Log('Assets: can''t save the collection ' + FCollection.Name + ' in ' + FCacheFolder +
        ': ' + E.Message);
  end;
end;

procedure TAssetsForm.ShowGroup(const AGroup: String);
begin
  FGroup := AGroup;
  for var I := 0 to High(FEntries) do
    FEntries[I].Picked := False;
  FAnchor := -1;
  TilesBox.ViewportPosition := TPointF.Zero;
  BuildFolderTiles;
  LayoutTiles;
  UpdateGroupMarks;
  UpdatePath;
end;

procedure TAssetsForm.UpdateTileMarks;
begin
  for var I := 0 to High(FEntries) do
  begin
    if FEntries[I].Tile = nil then
      Continue;
    if FEntries[I].Picked then
    begin
      FEntries[I].Tile.Stroke.Color := TILE_SELECTED_STROKE;
      FEntries[I].Tile.Stroke.Thickness := 2;
    end
    else
    begin
      FEntries[I].Tile.Stroke.Color := TILE_STROKE;
      FEntries[I].Tile.Stroke.Thickness := 1;
    end;
    if I = FSelected then
    begin
      FEntries[I].Tile.Fill.Kind := TBrushKind.Solid;
      FEntries[I].Tile.Fill.Color := TILE_SELECTED_FILL;
    end
    else
      FEntries[I].Tile.Fill.Kind := TBrushKind.None;
  end;
end;

function TAssetsForm.PickedEntries: TArray<Integer>;
begin
  Result := nil;
  for var I := 0 to High(FEntries) do
    if FEntries[I].Picked then
      Result := Result + [I];
end;

procedure TAssetsForm.PickEntry(const AIndex: Integer; const AShift: TShiftState);
var
  Lo, Hi: Integer;
begin
  if (ssShift in AShift) and (FAnchor >= 0) and (FAnchor <= High(FEntries)) then
  begin
    // The run between, in the order shown, which is name order
    Lo := Min(FAnchor, AIndex);
    Hi := Max(FAnchor, AIndex);
    if not (ssCtrl in AShift) then
      for var I := 0 to High(FEntries) do
        FEntries[I].Picked := False;
    for var I := Lo to Hi do
      if SameText(FEntries[I].Meta.Group, FGroup) then
        FEntries[I].Picked := True;
  end
  else if ssCtrl in AShift then
  begin
    FEntries[AIndex].Picked := not FEntries[AIndex].Picked;
    FAnchor := AIndex;
  end
  else
  begin
    for var I := 0 to High(FEntries) do
      FEntries[I].Picked := I = AIndex;
    FAnchor := AIndex;
  end;
end;

procedure TAssetsForm.TileMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  Index: Integer;
begin
  if not (Sender is TRectangle) or (Button <> TMouseButton.mbLeft) then
    Exit;
  Index := TRectangle(Sender).Tag;
  if (Index < 0) or (Index > High(FEntries)) then
    Exit;
  // A plain click on one already picked keeps the others until the button
  // comes up, so they can all be dragged
  FPickOnUp := FEntries[Index].Picked and ([ssShift, ssCtrl] * Shift = []);
  if not FPickOnUp then
    PickEntry(Index, Shift);
  SelectEntry(Index);
  FTileDown := Index;
  FDownAt := TRectangle(Sender).LocalToAbsolute(TPointF.Create(X, Y));
  FDragging := False;
end;

procedure TAssetsForm.TileMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  At: TPointF;
  Count: Integer;
begin
  if (FTileDown < 0) or not (Sender is TRectangle) or
    (TRectangle(Sender).Tag <> FTileDown) then
    Exit;
  if not (ssLeft in Shift) then
  begin
    // Let go where the tile did not see it
    FTileDown := -1;
    EndDrag;
    Exit;
  end;
  At := TRectangle(Sender).LocalToAbsolute(TPointF.Create(X, Y));
  if not FDragging then
  begin
    if At.Distance(FDownAt) < TILE_DRAG_START then
      Exit;
    // Only picked ones are dragged: a drag from one not picked picks it
    if not FEntries[FTileDown].Picked then
    begin
      PickEntry(FTileDown, []);
      UpdateTileMarks;
    end;
    FPickOnUp := False;
    if FEntries[FTileDown].Image <> nil then
      FDragGhost.Bitmap.Assign(FEntries[FTileDown].Image.Bitmap);
    Count := Length(PickedEntries);
    FDragCount.Text := IfThen(Count > 1, IntToStr(Count), '');
    BeginDrag;
  end;
  FDragAt := At;
  FDragGhost.Position.Point := TPointF.Create(At.X - GHOST_SIZE / 2, At.Y - GHOST_SIZE / 2);
  TrackTileDrag(At);
end;

procedure TAssetsForm.TrackTileDrag(const At: TPointF);
var
  Index: Integer;
  Below: Boolean;
begin
  // Only another group is somewhere to drop: a button, or a group's tile
  Index := GroupTileAt(At, Below);
  if (Index >= 0) and SameText(FShownGroups[Index], FGroup) then
    Index := -1;
  FDropFolder := FolderTileAt(At);
  SetDropIndex(Index);
  UpdateGroupMarks;
end;

procedure TAssetsForm.BeginDrag;
begin
  FDragging := True;
  FDragGhost.Visible := True;
  FDragGhost.BringToFront;
  FScrollTimer.Enabled := True;
end;

function TAssetsForm.EdgeScroll(const ABox: TVertScrollBox; const At: TPointF): Boolean;
var
  Local: TPointF;
  Step, Top, Limit: Single;
begin
  Result := False;
  Local := ABox.AbsoluteToLocal(At);
  if (Local.X < 0) or (Local.X > ABox.Width) then
    Exit;
  if Local.Y < DRAG_SCROLL_EDGE then
    Step := -DRAG_SCROLL_STEP * (1 + Max(0, -Local.Y) / DRAG_SCROLL_EDGE)
  else if Local.Y > ABox.Height - DRAG_SCROLL_EDGE then
    Step := DRAG_SCROLL_STEP * (1 + Max(0, Local.Y - ABox.Height) / DRAG_SCROLL_EDGE)
  else
    Exit;
  Limit := Max(0, ABox.ContentBounds.Height - ABox.Height);
  Top := EnsureRange(ABox.ViewportPosition.Y + Step, 0, Limit);
  if SameValue(Top, ABox.ViewportPosition.Y) then
    Exit;
  ABox.ViewportPosition := TPointF.Create(ABox.ViewportPosition.X, Top);
  Result := True;
end;

procedure TAssetsForm.ScrollTimerTimer(Sender: TObject);
begin
  if not FDragging then
  begin
    FScrollTimer.Enabled := False;
    Exit;
  end;
  if not EdgeScroll(GroupsBox, FDragAt) and not EdgeScroll(TilesBox, FDragAt) then
    Exit;
  // What is under the pointer has moved
  if FTileDown >= 0 then
    TrackTileDrag(FDragAt)
  else if FGroupDown <> String.Empty then
    TrackGroupDrag(FDragAt);
end;

procedure TAssetsForm.TileMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  Index, Folder: Integer;
  Below: Boolean;
  At: TPointF;
begin
  if Button <> TMouseButton.mbLeft then
    Exit;
  Index := FTileDown;
  FTileDown := -1;
  if not FDragging then
  begin
    EndDrag;
    // A plain click on a picked one, with no drag: that one alone
    if FPickOnUp and (Index >= 0) then
    begin
      PickEntry(Index, []);
      UpdateTileMarks;
    end;
    FPickOnUp := False;
    Exit;
  end;
  if not (Sender is TRectangle) then
  begin
    EndDrag;
    Exit;
  end;
  At := TRectangle(Sender).LocalToAbsolute(TPointF.Create(X, Y));
  Index := GroupTileAt(At, Below);
  Folder := FolderTileAt(At);
  EndDrag;
  if Folder >= 0 then
    MoveEntries(PickedEntries, FFolderNames[Folder])
  else if (Index >= 0) and not SameText(FShownGroups[Index], FGroup) then
    MoveEntries(PickedEntries, FShownGroups[Index]);
end;

procedure TAssetsForm.MoveEntries(const AIndices: TArray<Integer>; const AGroup: String);
var
  Group: String;
  Moved: Integer;
begin
  Group := LowerCase(Trim(AGroup));
  if (Length(AIndices) = 0) or (Group = String.Empty) then
    Exit;
  // A group the palette has keeps its own spelling
  if GroupIndex(Group) >= 0 then
    Group := FGroupOrder[GroupIndex(Group)]
  else
    FGroupOrder := FGroupOrder + [Group];
  Moved := 0;
  for var Index in AIndices do
  begin
    if (Index < 0) or (Index > High(FEntries)) or
      SameText(FEntries[Index].Meta.Group, Group) then
      Continue;
    FEntries[Index].Meta.Group := Group;
    FEntries[Index].GroupChosen := True;
    FEntries[Index].Picked := False;
    FPaletteGroups.AddOrSetValue(FEntries[Index].Meta.Hash, Group);
    Inc(Moved);
  end;
  if Moved = 0 then
    Exit;
  SavePalette;
  if Moved = 1 then
    Log(Format('Assets: %s moved to %s', [FEntries[AIndices[0]].Meta.Name, Group]))
  else
    Log(Format('Assets: %d models moved to %s', [Moved, Group]));
  // The group shown stays, with the models gone from it
  if (FSelected >= 0) and not SameText(FEntries[FSelected].Meta.Group, FGroup) then
    SelectEntry(-1);
  BuildGroups;
  UpdateTileMarks;
end;

procedure TAssetsForm.SelectEntry(const AIndex: Integer);
var
  Size: TPoint3D;
begin
  if (AIndex < 0) or (AIndex > High(FEntries)) then
  begin
    FSelected := -1;
    NameLabel.Text := String.Empty;
    SizeLabel.Text := String.Empty;
    FileLabel.Text := String.Empty;
    UpdateTileMarks;
    ShowPreview(-1);
    Exit;
  end;
  FSelected := AIndex;
  UpdateTileMarks;
  NameLabel.Text := FEntries[AIndex].Meta.Name + '  (' + FEntries[AIndex].Meta.Group + ')';
  if FEntries[AIndex].HasThumbnail then
  begin
    Size := FEntries[AIndex].Meta.Size;
    SizeLabel.Text := Format('%s x %s x %s units', [FormatFloat('0.###', Size.X),
      FormatFloat('0.###', Size.Y), FormatFloat('0.###', Size.Z)]);
  end
  else
    SizeLabel.Text := 'Size known once its thumbnail is made';
  FileLabel.Text := FEntries[AIndex].Meta.FileName;
  FileLabel.Hint := FileLabel.Text;
  ShowPreview(AIndex);
end;

procedure TAssetsForm.BuildTiles;
var
  Tile: TRectangle;
  Image: TImage;
  Caption: TLabel;
  Bitmap: TBitmap;
begin
  TilesBox.BeginUpdate;
  try
    FTilesLayout.DeleteChildren;
    for var I := 0 to High(FEntries) do
    begin
      Tile := TRectangle.Create(FTilesLayout);
      Tile.Parent := FTilesLayout;
      Tile.Visible := False;
      Tile.Width := TILE_WIDTH;
      Tile.Height := TILE_HEIGHT;
      Tile.XRadius := 4;
      Tile.YRadius := 4;
      Tile.Fill.Kind := TBrushKind.None;
      Tile.Stroke.Color := TILE_STROKE;
      Tile.Tag := I;
      Tile.Hint := FEntries[I].Meta.Name;
      Tile.ShowHint := True;
      // Keeps the mouse while a button is down, so a drag's moves and its
      // drop come here wherever the pointer goes
      Tile.AutoCapture := True;
      Tile.OnMouseDown := TileMouseDown;
      Tile.OnMouseMove := TileMouseMove;
      Tile.OnMouseUp := TileMouseUp;

      Image := TImage.Create(Tile);
      Image.Parent := Tile;
      Image.Align := TAlignLayout.Top;
      Image.Height := TILE_IMAGE;
      Image.Margins.Rect := TRectF.Create(4, 4, 4, 0);
      Image.WrapMode := TImageWrapMode.Fit;
      Image.HitTest := False;
      if FEntries[I].HasThumbnail then
        try
          Bitmap := TBitmap.CreateFromFile(
            AssetThumbnailFile(FCacheFolder, FEntries[I].Meta.Hash));
          try
            Image.Bitmap.Assign(Bitmap);
          finally
            Bitmap.Free;
          end;
        except
          on E: Exception do
          begin
            // Unreadable after all: made again
            FEntries[I].HasThumbnail := False;
            Log('Assets: can''t read the thumbnail of ' + FEntries[I].Meta.Name + ': ' +
              E.Message);
          end;
        end;

      Caption := TLabel.Create(Tile);
      Caption.Parent := Tile;
      Caption.Align := TAlignLayout.Client;
      Caption.Margins.Rect := TRectF.Create(2, 0, 2, 2);
      Caption.TextSettings.HorzAlign := TTextAlign.Center;
      Caption.TextSettings.WordWrap := False;
      Caption.TextSettings.Trimming := TTextTrimming.Character;
      Caption.StyledSettings := Caption.StyledSettings - [TStyledSetting.Size];
      Caption.TextSettings.Font.Size := 10;
      Caption.Text := FEntries[I].Meta.Name;
      Caption.HitTest := False;

      FEntries[I].Tile := Tile;
      FEntries[I].Image := Image;
    end;
  finally
    TilesBox.EndUpdate;
  end;
  LayoutTiles;
end;

procedure TAssetsForm.LayoutTiles;
var
  Columns, Column: Integer;
  Y: Single;
begin
  if FTilesLayout = nil then
    Exit;
  Columns := Max(1, Trunc((TilesBox.Width - TILE_GAP) / (TILE_WIDTH + TILE_GAP)));
  Y := TILE_GAP;
  Column := 0;
  // The groups inside the one shown first, as folders are
  for var Tile in FFolderTiles do
  begin
    Tile.Position.Point := TPointF.Create(TILE_GAP + Column * (TILE_WIDTH + TILE_GAP), Y);
    Inc(Column);
    if Column >= Columns then
    begin
      Column := 0;
      Y := Y + TILE_HEIGHT + TILE_GAP;
    end;
  end;
  // FEntries is in name order, so the group's tiles are too
  for var I := 0 to High(FEntries) do
  begin
    if FEntries[I].Tile = nil then
      Continue;
    FEntries[I].Tile.Visible := (FGroup <> String.Empty) and
      (FEntries[I].Meta.Group = FGroup);
    if not FEntries[I].Tile.Visible then
      Continue;
    FEntries[I].Tile.Position.Point := TPointF.Create(
      TILE_GAP + Column * (TILE_WIDTH + TILE_GAP), Y);
    Inc(Column);
    if Column >= Columns then
    begin
      Column := 0;
      Y := Y + TILE_HEIGHT + TILE_GAP;
    end;
  end;
  if Column > 0 then
    Y := Y + TILE_HEIGHT + TILE_GAP;
  FTilesLayout.Height := Y;
end;

procedure TAssetsForm.TilesBoxResize(Sender: TObject);
begin
  LayoutTiles;
end;

procedure TAssetsForm.ShowPreview(const AIndex: Integer);
begin
  if Making then
    Exit;   // the viewport is the thumbnails'; MakeNext previews when done
  if (AIndex = FPreviewIndex) and (FModel <> nil) then
    Exit;
  FreeModel;
  FTurning := False;
  ResetCameraAngles;
  if (AIndex < 0) or (AIndex > High(FEntries)) then
    Exit;
  if not LoadEntryModel(AIndex) then
    Exit;
  FPreviewIndex := AIndex;
  FrameModel(FViewport.Width, FViewport.Height);
end;

function TAssetsForm.LoadEntryModel(const AIndex: Integer): Boolean;
var
  Box: TBoundingBox;
begin
  // Loaded as the builder will load it: upright, as each model was in
  // Sprite3D, since FMX's Y points down
  FModel := TGorillaModel.Create(FViewport);
  try
    FModel.Parent := FViewport;
    LoadModelFile(FModel, FEntries[AIndex].Meta.FileName, Box);
    FModel.RotationAngle.X := 180;
    FModel.ResetToBindPose();
  except
    on E: Exception do
    begin
      Log('Assets: can''t load ' + FEntries[AIndex].Meta.FileName + ': ' + E.Message);
      FreeModel;
      Exit(False);
    end;
  end;
  FModelBox := Box;
  FEntries[AIndex].Meta.BoxMin := Box.TopLeftNear;
  FEntries[AIndex].Meta.BoxMax := Box.BottomRightFar;
  UpdatePreviewLabel;
  Result := True;
end;

procedure TAssetsForm.ResetCameraAngles;
begin
  FCamera.Camera.Azimuth := THUMBNAIL_AZIMUTH;
  FCamera.Camera.PolarAngle := THUMBNAIL_INCLINATION;
  FCamera.Camera.Roll := 0;
end;

procedure TAssetsForm.FreeModel;
begin
  FPreviewIndex := -1;
  if FModel <> nil then
  begin
    FModel.Parent := nil;
    FreeAndNil(FModel);
  end;
  if FPreviewLabel <> nil then
    UpdatePreviewLabel;
end;

procedure TAssetsForm.StopMaking;
begin
  if FSettleTimer <> nil then
    FSettleTimer.Enabled := False;
  if FNextTimer <> nil then
    FNextTimer.Enabled := False;
  if FOffscreen <> nil then
    FOffscreen.Cancel;
  FQueue := nil;
  FMaking := -1;
  FreeModel;
end;

procedure TAssetsForm.MakeNextLater;
begin
  FNextTimer.Enabled := False;
  FNextTimer.Enabled := True;
end;

procedure TAssetsForm.NextTimerTimer(Sender: TObject);
begin
  FNextTimer.Enabled := False;
  MakeNext;
end;

procedure TAssetsForm.MakeNext;
var
  Index, Done: Integer;
  Left: String;
begin
  FMaking := -1;
  FreeModel;
  if Length(FQueue) = 0 then
  begin
    // Only while there is something to show progress on
    Progress.Visible := False;
    StatusLabel.Text := Format('%d models', [Length(FEntries)]);
    if FQueueTotal > 0 then
      Log(Format('Assets: %d thumbnails made in %s', [FQueueTotal,
        DurationText(FMakeWatch.Elapsed.TotalSeconds)]));
    // Groups with no icon of their own show a thumbnail, there now
    if FQueueTotal > 0 then
      BuildGroups;
    FQueueTotal := 0;
    // An artist import goes on with its next collection, once this has
    // returned
    if FBulkTotal > 0 then
    begin
      FBulkPending := True;
      Defer;
      Exit;
    end;
    // The viewport is free: the selected model, if any, in 3D
    ShowPreview(FSelected);
    Exit;
  end;
  Index := FQueue[0];
  Delete(FQueue, 0, 1);
  Progress.Visible := True;
  Progress.Max := Max(1, FQueueTotal);
  Progress.Value := FQueueTotal - Length(FQueue) - 1;
  // The time left, from the average so far, once there are a few to go by
  Done := FQueueTotal - Length(FQueue) - 1;
  Left := String.Empty;
  if Done >= ETA_AFTER then
    Left := ', about ' + DurationText(FMakeWatch.Elapsed.TotalSeconds / Done *
      (Length(FQueue) + 1)) + ' left';
  StatusLabel.Text := BulkPrefix + Format('Making thumbnails: %d of %d%s, %s', [Done + 1,
    FQueueTotal,
    Left, FEntries[Index].Meta.Name]);

  FTurning := False;
  ResetCameraAngles;
  if not LoadEntryModel(Index) then
  begin
    MakeNextLater;
    Exit;
  end;
  // On screen first, framed as the thumbnail will be, so the viewport draws
  // it before the grab; FSettleTimer starts the grab
  FrameModel(FViewport.Width, FViewport.Height);
  FMaking := Index;
  FSettleTimer.Enabled := False;
  FSettleTimer.Enabled := True;
end;

procedure TAssetsForm.SettleTimerTimer(Sender: TObject);
begin
  FSettleTimer.Enabled := False;
  if (FMaking < 0) or (FModel = nil) then
    Exit;
  if not FOffscreen.Grab(GrabDone(FMaking, FScanId)) then
  begin
    Log('Assets: can''t start the thumbnail of ' + FEntries[FMaking].Meta.Name);
    FMaking := -1;
    FreeModel;
    MakeNextLater;
  end;
end;

procedure TAssetsForm.FrameModel(const AWidth, AHeight: Single);
begin
  if (FModel = nil) or (AWidth <= 0) or (AHeight <= 0) then
    Exit;
  // As Sprite3D fits a model: the volume its box sweeps turning about the
  // up axis through its centre of rotation, framed with the camera's
  // target on that axis
  FitCameraToSweep(FCamera.Camera, FModel,
    CalcSweptVolume(FModelBox, FModel.RotationCenter.Point, saY), AWidth, AHeight,
    THUMBNAIL_MARGIN);
end;

procedure TAssetsForm.OffscreenBeforeGrab(Sender: TObject; const AWidth,
  AHeight: Integer);
begin
  FrameModel(AWidth, AHeight);
end;

function TAssetsForm.GrabDone(const AIndex, AScanId: Integer): TSprite3DGrabProc;
var
  Alive: IAssetsAlive;
begin
  Alive := FAlive;
  Result :=
    procedure(const ABitmap: TBitmap; const AError: String)
    begin
      if Alive.Alive then
        ThumbnailGrabbed(AIndex, AScanId, ABitmap, AError);
    end;
end;

procedure TAssetsForm.ThumbnailGrabbed(const AIndex, AScanId: Integer;
  const ABitmap: TBitmap; const AError: String);
begin
  if (AScanId <> FScanId) or (AIndex <> FMaking) or (AIndex > High(FEntries)) then
    Exit;   // stopped, or another folder opened, since it was started
  // For the Debug tab: what was framed and how, to check a thumbnail by
  Log(Format('Assets: %s box (%.3f, %.3f, %.3f) to (%.3f, %.3f, %.3f), distance %.3f, ' +
    'ortho height %.3f', [FEntries[AIndex].Meta.Name, FModelBox.Left, FModelBox.Top,
    FModelBox.Near, FModelBox.Right, FModelBox.Bottom, FModelBox.Far,
    FCamera.Camera.Distance, FCamera.Camera.OrthoHeight]));
  if ABitmap = nil then
    Log('Assets: no thumbnail for ' + FEntries[AIndex].Meta.Name + ': ' + AError)
  else
    try
      ForceDirectories(AssetKeyFolder(FCacheFolder, FEntries[AIndex].Meta.Hash));
      ABitmap.SaveToFile(AssetThumbnailFile(FCacheFolder, FEntries[AIndex].Meta.Hash));
      FEntries[AIndex].Meta.ThumbWidth := ABitmap.Width;
      FEntries[AIndex].Meta.ThumbHeight := ABitmap.Height;
      FEntries[AIndex].Meta.View := THUMBNAIL_VIEW;
      FEntries[AIndex].Meta.Created := DateToISO8601(Now, False);
      SaveAssetMeta(FCacheFolder, FEntries[AIndex].Meta);
      FEntries[AIndex].HasThumbnail := True;
      if FEntries[AIndex].Image <> nil then
        FEntries[AIndex].Image.Bitmap.Assign(ABitmap);
      if AIndex = FSelected then
        SelectEntry(AIndex);   // its size is known now
    except
      on E: Exception do
        Log('Assets: can''t save the thumbnail of ' + FEntries[AIndex].Meta.Name +
          ' in ' + FCacheFolder + ': ' + E.Message);
    end;
  MakeNextLater;
end;

function TAssetsForm.CanTurnPreview: Boolean;
begin
  Result := not Making and (FModel <> nil) and (FPreviewIndex >= 0);
end;

procedure TAssetsForm.PreviewMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if not CanTurnPreview then
    Exit;
  // A Control-click counts as a right-click, for a Mac with one button
  if (Button = TMouseButton.mbRight) or
    ((Button = TMouseButton.mbLeft) and (ssCtrl in Shift)) then
  begin
    FTurning := False;
    ResetCameraAngles;
    FrameModel(FViewport.Width, FViewport.Height);
  end
  else if Button = TMouseButton.mbLeft then
  begin
    FTurning := True;
    FTurnLast := TPointF.Create(X, Y);
  end;
end;

procedure TAssetsForm.PreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  DX, DY: Single;
begin
  if not FTurning then
    Exit;
  // Let go where the preview could not see it: the first move without the
  // button ends the turn
  if not CanTurnPreview or not (ssLeft in Shift) then
  begin
    FTurning := False;
    Exit;
  end;
  DX := X - FTurnLast.X;
  DY := Y - FTurnLast.Y;
  FTurnLast := TPointF.Create(X, Y);
  // The camera turns about the model's own axis, where the fit put its
  // target. Its own Azimuth runs the other way to the azimuth the views
  // show (ApplyAngles in the main form reverses it), so adding the move
  // turns the model with the pointer, as the main form's mouse view does
  if DX <> 0 then
    FCamera.Camera.Azimuth := FCamera.Camera.Azimuth + DX * PREVIEW_DEGREES_PER_PIXEL;
  // The camera's gimbals let the tilt go right round, over the top and
  // under, with no lock, so it is only kept within a turn
  if DY <> 0 then
    FCamera.Camera.PolarAngle := Wrap360(FCamera.Camera.PolarAngle +
      DY * PREVIEW_DEGREES_PER_PIXEL);
end;

procedure TAssetsForm.PreviewMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
    FTurning := False;
end;

procedure TAssetsForm.PreviewMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; var Handled: Boolean);
var
  Zoom: Single;
begin
  if not CanTurnPreview then
    Exit;
  Handled := True;
  // Away from you nearer, towards you further; in orthographic projection
  // the size of the view is what zooms, not the distance
  Zoom := Power(PREVIEW_ZOOM_STEP, -WheelDelta / 120);
  FCamera.Camera.OrthoHeight := FCamera.Camera.OrthoHeight * Zoom;
  if FCamera.Camera.OrthoWidth > 0 then
    FCamera.Camera.OrthoWidth := FCamera.Camera.OrthoWidth * Zoom;
end;

end.
