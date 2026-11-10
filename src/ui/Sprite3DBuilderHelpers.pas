//** @abstract(Support routines for the Sprite3DBuilder application that are neither UI nor
//** library.)
//**
//** The application keeps three kinds of code apart. The units in @code(ui) only handle the
//** user interface; the units in @code(lib) are a library with no knowledge of this
//** application, usable in other projects; and this unit holds what is left: the
//** application's own rules, such as where models are found, what settings are kept and how
//** a loaded model is placed. It uses the library and the RTL, never the UI.
//**
//** TSprite3DAppSettings holds the settings kept between sessions, in @code(settings.json)
//** in the application's own per-user folder, SupportFolder. The measured bounds of each
//** model's animations are kept there too, one file per model in its @code(bounds) folder,
//** through LoadAnimationBoundsCache and SaveAnimationBoundsCache.
//**
//** Loading a model through LoadModelFile also registers Gorilla3D's loaders for glTF, FBX,
//** OBJ, USD, Collada, STL and PLY files, as this unit uses them. Each model the application
//** keeps loaded, in its Models list, is held in a TSprite3DModelSlot, made with
//** NewModelSlot, found with ModelSlotIndex and freed with FreeModelSlot; ShowModelWithHelpers
//** shows or hides one with everything drawn beside it.
//**
//** All routines are for the main thread, except the members of IModelFileRead.
unit Sprite3DBuilderHelpers;

{
  Support routines for the Sprite3DBuilder application that are neither UI
  nor library.

  The application keeps three kinds of code apart. The units in ui only
  handle the user interface; the units in lib are a library with no
  knowledge of this application, usable in other projects; and this unit
  holds what is left: the application's own rules, such as where models are
  found, what settings are kept and how a loaded model is placed.
  It uses the library and the RTL, never the UI.

  TSprite3DAppSettings holds the settings kept between sessions, in
  settings.json in the application's own per-user folder, SupportFolder.
  The measured bounds of each model's animations are kept there too, one
  file per model in its bounds folder, through LoadAnimationBoundsCache and
  SaveAnimationBoundsCache.

  Loading a model through LoadModelFile also registers Gorilla3D's loaders
  for glTF, FBX, OBJ, USD, Collada, STL and PLY files, as this unit uses
  them. Each model the application keeps loaded, in its Models list, is
  held in a TSprite3DModelSlot, made with NewModelSlot, found with
  ModelSlotIndex and freed with FreeModelSlot; ShowModelWithHelpers shows
  or hides one with everything drawn beside it.

  All routines are for the main thread, except the members of
  IModelFileRead.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Math.Vectors,
  FMX.Graphics, FMX.Types3D, FMX.Controls3D,
  System.JSON, Gorilla.Model, Sprite3DStorage, Sprite3DSweep, Neon.Core.Attributes;

const
  //** @abstract(The application's name, used for its per-user folder.)
  APP_NAME = 'Sprite3DBuilder';
  //** @abstract(The name of the settings file in SupportFolder.)
  SETTINGS_FILE_NAME = 'settings.json';
  //** @abstract(The largest shift or rise either way, as a fraction of how far the picture
  //** can slide.)
  //**
  //** 1 slides it until the near side of the model's fitted volume is on that edge of the
  //** picture: the model just gone off it.
  PAN_LIMIT = 1.0;
  //** @abstract(The lowest frame rate File, Settings lets the view be drawn at.)
  VIEW_FPS_MIN = 1;
  //** @abstract(The highest frame rate kept for the view; File, Settings offers no more than
  //** the display's refresh rate.)
  VIEW_FPS_MAX = 1000;
  //** @abstract(The frame rate the view is drawn at until File, Settings changes it, and the
  //** most it offers where the display's refresh rate is not known.)
  VIEW_FPS_DEFAULT = 60;

type
  //** @abstract(What the application loads when it starts and no file was asked for.)
  //**
  //** @code(saNone) loads nothing; @code(saDefaultModel) loads the sample model;
  //** @code(saLastModel) loads the model last opened, or the sample model if it has gone;
  //** after Clear has emptied the Models list it loads nothing. A file the operating system asks the application to open always
  //** comes first.
  TSprite3DStartupAction = (saNone, saDefaultModel, saLastModel);

  //** @abstract(The application's look: FMX's own default style, or one of the FMX styles
  //** that come with RAD Studio.)
  //**
  //** @code(thDefault) is the platform's own style. @code(thDark) is Dark.style; the others
  //** are the coloured Graphite styles, dark grey with an accent: @code(thAquaGraphite) blue,
  //** @code(thRubyGraphite) red and @code(thGoldenGraphite) gold.
  TSprite3DTheme = (thDefault, thDark, thAquaGraphite, thRubyGraphite, thGoldenGraphite);

  //** @abstract(The projection chosen in View, Projection on the main form.)
  //**
  //** Perspective and orthographic are the camera's own (its ProjectionMode). The four
  //** oblique projections are drawn by the Spritely package's TSpritelyProjection, with the
  //** camera in perspective: the picture is made from what the perspective shows at the
  //** orbit centre's distance, with depth drawn across it. Cavalier draws depth at full
  //** length at 45 degrees, cabinet at half length at 63.43 degrees (2 in 1), military at
  //** full length straight down the picture (with the camera looking straight down, height
  //** goes straight up and the plan keeps its shape), and plan oblique at full length down
  //** and to the right (with the camera straight down and the plan square to the picture,
  //** height goes up and to the left at 45 degrees). The camera's angles are left to View,
  //** Camera: these look as intended from Head On (cavalier, cabinet) and Top Down (military,
  //** plan oblique).
  TSprite3DProjection = (
    //** @abstract(The camera's own perspective.)
    prPerspective,
    //** @abstract(The camera's own orthographic projection.)
    prOrthographic,
    //** @abstract(Oblique: depth at full length, at 45 degrees.)
    prCavalier,
    //** @abstract(Oblique: depth at half length, at 63.43 degrees.)
    prCabinet,
    //** @abstract(Oblique: depth at full length, straight down the picture.)
    prMilitary,
    //** @abstract(Oblique: depth at full length, down and to the right, so height goes up and
    //** to the left.)
    prPlanOblique);

  //** @abstract(How a TSprite3DProjection is named in each place it appears.)
  TSprite3DProjectionInfo = record
    //** @abstract(In settings.json and as the menu item's name: Perspective, Orthographic,
    //** Cavalier, Cabinet, Military, PlanOblique.)
    Key: String;
    //** @abstract(As the menu, the window caption and the Debug tab show it.)
    Caption: String;
  end;

  //** @abstract(Which graphics processor Windows gives the application.)
  //**
  //** @code(gmSystem) lets Windows decide; @code(gmPowerSaving) asks for the low-power GPU and
  //** @code(gmHighPerformance) for the high-performance one. Used on Windows only, and only
  //** after the application is restarted.
  TSprite3DGpuMode = (gmSystem, gmPowerSaving, gmHighPerformance);

  //** @abstract(The choices made in File, Settings, together.)
  TSprite3DGeneralSettings = record
    //** @abstract(What is loaded at start-up.)
    StartupAction: TSprite3DStartupAction;
    //** @abstract(The application's look.)
    Theme: TSprite3DTheme;
    //** @abstract(The graphics processor asked for; Windows only.)
    GpuMode: TSprite3DGpuMode;
    //** @abstract(The frame rate the view is drawn at, VIEW_FPS_MIN to MaxViewFps.)
    ViewFps: Integer;
    //** @abstract(Whether JSON files are written minified.)
    MinifyJson: Boolean;
    //** @abstract(The most ViewFps may be: the display's refresh rate, set by the caller; not
    //** kept.)
    MaxViewFps: Integer;
  end;

  //** @abstract(Protected-access helper for TControl3D; nothing in the project uses it yet.)
  //**
  //** Casting a TControl3D to this class exposes its protected members inside the unit that
  //** declares the cast. Because it is in the interface section, other units can use it too.
  TControl3DAccess = class(TControl3D);

  //** @abstract(One loaded model and what was measured of it as it loaded: one entry of the
  //** Models list.)
  //**
  //** The application keeps every model it has loaded in the viewport, hidden while another
  //** is shown, each with one of these. Make one with NewModelSlot, find one by file with
  //** ModelSlotIndex, and free its model with FreeModelSlot. A record with Model nil stands
  //** for no model; EmptyModelSlot returns one.
  TSprite3DModelSlot = record
    //** @abstract(The model, parented to the viewport; nil for none.)
    Model: TGorillaModel;
    //** @abstract(The file it was loaded from, expanded.)
    FileName: String;
    //** @abstract(The name it is listed by: its file's name without the
    //** extension, unless that was taken and it was renamed with UniqueModelName.)
    Name: String;
    //** @abstract(Its own bounds, measured as it loaded, before any helper was added.)
    Box: TBoundingBox;
    //** @abstract(Each animation's bounds over all its poses; empty for a model without
    //** animations, as every model is in Sprite3DBuilder, which shows each in its rest pose.)
    Bounds: TArray<TAnimationBounds>;
    //** @abstract(Every animation the model has, in its order; empty for a static model.)
    Names: TArray<String>;
    //** @abstract(The animations used; every one, as loaded.)
    Used: TArray<String>;
    //** @abstract(Whether the model has animations; always False in Sprite3DBuilder, which loads
    //** every model in its rest pose.)
    IsAnimated: Boolean;
    //** @abstract(When it was first listed, counting up from 1, so the static models can be
    //** shown in the order they were opened whether or not Models, Models Used lists them;
    //** 0 until it is listed.)
    Order: Integer;
  end;

  //** @abstract(The application's settings, kept between sessions in settings.json.)
  //**
  //** Create it, call Load once at start-up, and call Save after changing a setting. The file
  //** is @code(settings.json) in SupportFolder; on the first run it does not exist yet, so
  //** every setting keeps its default until the first Save. For the main thread only.
  //**
  //** @seealso(TSprite3DJsonSettings)
  TSprite3DAppSettings = class(TSprite3DJsonSettings)
  private
    FShowBoundingBox: Boolean;
    FShowAxes: Boolean;
    FShowSweptVolume: Boolean;
    FShowCombinedSweptVolume: Boolean;
    FOrthographic: Boolean;
    //** @abstract(Backing fields for Headlight and OriginalLight.)
    FHeadlight, FOriginalLight: Boolean;
    //** @abstract(Backing field for Projection.)
    FProjection: String;
    FCameraView: String;
    FVariableAzimuth: Single;
    FVariableInclination: Single;
    FVariableRoll: Single;
    FPanEnabled: Boolean;
    FPanX: Single;
    FPanZ: Single;
    FKeepShift: Boolean;
    FDistanceFactor: Single;
    FStartupAction: TSprite3DStartupAction;
    FLastModel: String;
    FTheme: String;
    FGpuMode: TSprite3DGpuMode;
    FViewFps: Integer;
    FMinifyJson: Boolean;
    FMouseView: Boolean;
    procedure SetViewFps(const Value: Integer);
    procedure SetMinifyJson(const Value: Boolean);
    function GetThemeKind: TSprite3DTheme;
    procedure SetThemeKind(const Value: TSprite3DTheme);
    //** @abstract(Getter for ProjectionKind.)
    function GetProjectionKind: TSprite3DProjection;
    //** @abstract(Setter for ProjectionKind.)
    procedure SetProjectionKind(const Value: TSprite3DProjection);
  public
    //** @abstract(Creates the settings with their defaults, for settings.json in
    //** SupportFolder.)
    //**
    //** Nothing is read until Load is called.
    constructor Create; reintroduce;
    //** @abstract(The application's per-user folder, for settings.json and support files.)
    //**
    //** AppDataFolder for APP_NAME: for example @code(%APPDATA%\Sprite3DBuilder) on Windows. It is
    //** created by the first Save.
    //**
    //** @returns(The folder's full path, without a trailing path delimiter.)
    class function SupportFolder: String; static;
    //** @abstract(Theme as a TSprite3DTheme.)
    //**
    //** A name in settings.json that is not one of the themes, such as one from an older
    //** version, reads as thDefault.
    property ThemeKind: TSprite3DTheme read GetThemeKind write SetThemeKind;
    //** @abstract(Projection as a TSprite3DProjection.)
    //**
    //** A settings.json without @code(projection), as earlier versions wrote, reads as
    //** prOrthographic if its @code(orthographic) is true and prPerspective if not; a name
    //** this version does not know reads as prPerspective. Writing sets Orthographic too, so
    //** an earlier version reading the file still finds orthographic or perspective.
    property ProjectionKind: TSprite3DProjection read GetProjectionKind write SetProjectionKind;
  published
    //** @abstract(Whether View, Show bounding box is ticked on the main form; False by
    //** default.)
    //**
    //** Stored as @code(showBoundingBox).
    property ShowBoundingBox: Boolean read FShowBoundingBox write FShowBoundingBox;
    //** @abstract(Whether View, Show axes is ticked on the main form; False by default.)
    //**
    //** Stored as @code(showAxes).
    property ShowAxes: Boolean read FShowAxes write FShowAxes;
    //** @abstract(Whether View, Show Model Volume is ticked on the main form; False by
    //** default.)
    //**
    //** Stored as @code(showSweptVolume).
    property ShowSweptVolume: Boolean read FShowSweptVolume write FShowSweptVolume;
    //** @abstract(Whether View, Show Animation Volume is ticked on the main form; False by
    //** default.)
    //**
    //** Stored as @code(showCombinedSweptVolume).
    property ShowCombinedSweptVolume: Boolean read FShowCombinedSweptVolume
      write FShowCombinedSweptVolume;
    //** @abstract(Whether the main form's projection is orthographic; False by default.)
    //**
    //** Stored as @code(orthographic). Before View, Projection it was the View, Orthographic
    //** tick; now Projection says which projection, and this is kept in step with it for
    //** earlier versions, and read only when Projection is missing.
    property Orthographic: Boolean read FOrthographic write FOrthographic;
    //** @abstract(The projection chosen in View, Projection on the main form; empty by default,
    //** which reads as Orthographic says.)
    //**
    //** Stored as @code(projection): one of Perspective, Orthographic, Cavalier, Cabinet,
    //** Military and PlanOblique. Kept as text so a name this version does not know can never
    //** stop settings.json loading; use ProjectionKind in code.
    property Projection: String read FProjection write FProjection;
    //** @abstract(Whether View, Lights, Headlight is ticked on the main form: the Spritely
    //** camera's own light; True by default.)
    //**
    //** Stored as @code(headlight).
    property Headlight: Boolean read FHeadlight write FHeadlight;
    //** @abstract(Whether View, Lights, Original Light is ticked on the main form: the light
    //** the form made before the Spritely camera; False by default.)
    //**
    //** Stored as @code(originalLight).
    property OriginalLight: Boolean read FOriginalLight write FOriginalLight;
    //** @abstract(The main form's camera view, the checked View, Camera item; Isometric by
    //** default.)
    //**
    //** Stored as @code(cameraView): the item's name without its View prefix and Item suffix,
    //** one of Variable, Isometric, Pixel2To1, ThreeQuarter, HeadOn, TopDown and Side. An
    //** unknown name gives Isometric.
    property CameraView: String read FCameraView write FCameraView;
    //** @abstract(The Azimuth dial's angle in the Variable view, in degrees; 0 by default.)
    //**
    //** Stored as @code(variableAzimuth). Kept whenever the session ends in the Variable
    //** view, and restored with it.
    property VariableAzimuth: Single read FVariableAzimuth write FVariableAzimuth;
    //** @abstract(The Inclination dial's angle in the Variable view, in degrees; 0 by
    //** default.)
    //**
    //** Stored as @code(variableInclination). Kept whenever the session ends in the Variable
    //** view, and restored with it.
    property VariableInclination: Single read FVariableInclination
      write FVariableInclination;
    //** @abstract(The Roll dial's angle in the Variable view, in degrees; 0 by default.)
    //**
    //** Stored as @code(variableRoll). Kept whenever the session ends in the Variable view,
    //** and restored with it.
    property VariableRoll: Single read FVariableRoll write FVariableRoll;
    //** @abstract(Whether the shift and rise are applied; False by default.)
    //**
    //** Stored as @code(panEnabled), the name from before they were a lens shift. Set by the
    //** Shift and rise box in the Variable camera dialog. While False, PanX and PanZ are kept
    //** but have no effect.
    property PanEnabled: Boolean read FPanEnabled write FPanEnabled;
    //** @abstract(The shift: the picture slid right (positive) or left, as a fraction of how
    //** far it can go; 0 by default.)
    //**
    //** Stored as @code(panX). Values beyond PAN_LIMIT either way are limited to it, which also
    //** brings a value from before, when it was a multiple of the model's radius, into range.
    property PanX: Single read FPanX write FPanX;
    //** @abstract(The rise: the picture slid up (positive) or down, as a fraction of how far
    //** it can go; 0 by default.)
    //**
    //** Stored as @code(panZ). Values beyond PAN_LIMIT either way are limited to it.
    property PanZ: Single read FPanZ write FPanZ;
    //** @abstract(Whether the shift and rise are kept for the next session; False by
    //** default.)
    //**
    //** Stored as @code(keepShift). Set by Save shift, rise and distance values between
    //** sessions in the Variable camera dialog. While False, PanEnabled, PanX and PanZ are
    //** saved off and at 0 and DistanceFactor at 1, and none is read at start-up, so each
    //** session starts without a shift or rise, at the fitted distance.
    property KeepShift: Boolean read FKeepShift write FKeepShift;
    //** @abstract(The Variable camera dialog's distance, a factor on the fitted distance; 1
    //** by default.)
    //**
    //** Stored as @code(distanceFactor); saved, and read at start-up, only while KeepShift.
    //** A value of 0 or less counts as 1.
    property DistanceFactor: Single read FDistanceFactor write FDistanceFactor;
    //** @abstract(What is loaded at start-up; nothing by default.)
    //**
    //** Stored as @code(startupAction), by name.
    property StartupAction: TSprite3DStartupAction read FStartupAction write FStartupAction;
    //** @abstract(The full path of the model last loaded, of either kind; empty until one is,
    //** or once Clear has emptied both tabs.)
    //**
    //** Stored as @code(lastModel). Used when StartupAction is saLastModel, which loads it
    //** last, so its tab is the one shown.
    property LastModel: String read FLastModel write FLastModel;
    //** @abstract(The application's look, by name; Default by default.)
    //**
    //** Stored as @code(theme): one of Default, Dark, AquaGraphite, RubyGraphite and
    //** GoldenGraphite. Kept as text rather than as an enumeration so that a name this version
    //** does not know can never stop settings.json loading; use ThemeKind in code.
    property Theme: String read FTheme write FTheme;
    //** @abstract(The graphics processor last chosen in File, Settings; Windows only.)
    //**
    //** Stored as @code(gpuMode), by name. Windows keeps the choice itself, per program file;
    //** the dialog shows what Windows has, so this is a record of the last choice.
    property GpuMode: TSprite3DGpuMode read FGpuMode write FGpuMode;
    //** @abstract(The frame rate the view is drawn at, in frames per second;
    //** VIEW_FPS_DEFAULT by default.)
    //**
    //** Set in File, Settings, which offers up to the display's refresh rate. Stored as
    //** @code(viewFps). Written values are limited to VIEW_FPS_MIN to VIEW_FPS_MAX.
    property ViewFps: Integer read FViewFps write SetViewFps;
    //** @abstract(Whether JSON files are written minified, with no indents or line breaks;
    //** False by default.)
    //**
    //** Set in File, Settings. Stored as @code(minifyJson). Writing it, loading settings.json
    //** included, sets JsonText.MinifyJson, which every JSON file Sprite3DBuilder writes follows,
    //** settings.json itself among them.
    property MinifyJson: Boolean read FMinifyJson write SetMinifyJson;
    //** @abstract(Whether View, Camera, Temporary Mouse View is ticked; False by default.)
    //**
    //** Stored as @code(mouseView); set by the menu item, and saved as soon as it changes.
    //** Only the tick is kept: the turn and zoom the mouse gives the view never are, and
    //** each session starts from the normal view. Desktop only; ignored on Android and iOS.
    property MouseView: Boolean read FMouseView write FMouseView;
  end;

//** @abstract(Shifts an angle in degrees by whole turns into the range 0 to 360.)
//**
//** @param(ADegrees Any angle in degrees, negative or past a full turn.)
//**
//** @returns(The same direction as an angle from 0 up to, but not including, 360.)
function Wrap360(const ADegrees: Single): Single;

//** @abstract(The abbreviated name of a point of the 32-point compass, if a bearing is on
//** one.)
//**
//** The points are 11.25 degrees apart, named as the mariner's compass names them: the
//** cardinal points N, E, S and W; the intercardinal NE, SE, SW and NW; the eight winds
//** between them, NNE, ENE and so on; and the sixteen "by" points, NbE (north by east),
//** NEbN and so on.
//**
//** @param(ADegrees A bearing in degrees clockwise from north, any number of turns.)
//**
//** @returns(The point's abbreviation, such as N, NbE, NNE or NEbN, for a bearing within a
//** hundredth of a degree of one; otherwise an empty string, so a whole-degree bearing only
//** has a name on the eight points that fall on whole degrees.)
function CompassPointName(const ADegrees: Single): String;

//** @abstract(Formats an angle from Wrap360 as whole degrees for a readout.)
//**
//** Rounds to the nearest degree, so 359.6 shows as 0, never 360, and pads to three
//** characters so readouts stay the same width.
//**
//** @param(ADegrees An angle from 0 up to 360.)
//**
//** @returns(The angle as text, such as @code('  0') or @code(' 45').)
function DegreesText(const ADegrees: Single): String;

//** @abstract(The folder that holds the application's models folder, for this platform.)
//**
//** The program's assets folder, from @link(GetAssetsPath): the executable's folder on Windows
//** (three folders up from it, @code('../../../'), when started from the IDE), the bundle's
//** Resources folder on macOS, and the application's resource folder on Android.
//**
//** @returns(A folder path ending in a path delimiter.)
function DefaultModelDir: String;

//** @abstract(Replaces a model's contents with a model file and starts its last animation.)
//**
//** Clears AModel, loads AFileName into it, and, if the file has animations, plays the one
//** whose name sorts last. Blocks while the file loads.
//**
//** @param(AModel The model to load into; its old contents are removed first.)
//**
//** @param(AFileName A glTF, FBX, OBJ, USD, Collada, STL or PLY file.)
//**
//** @param(ABox The model's bounding box straight after loading, before anything is added
//** to it or it is moved; pass it to PlaceModel.)
//**
//** @returns(The names of the model's animations in sorted order; empty if it has none.)
//**
//** @raises(Exception If the file cannot be read or loaded; AModel is then left cleared or
//** part-loaded.)
function LoadModelFile(const AModel: TGorillaModel; const AFileName: String;
  out ABox: TBoundingBox): TArray<String>;

//** @abstract(Centres a loaded model on its bounding box and turns it right way up.)
//**
//** Moves AModel to the centre of ABox and turns it 180 degrees about X, which the
//** application's models need to stand upright.
//**
//** @param(AModel The model to place.)
//**
//** @param(ABox The box LoadModelFile returned for it.)
procedure PlaceModel(const AModel: TGorillaModel; const ABox: TBoundingBox);

//** @abstract(A slot holding no model: Model nil, every other field empty or zero.)
//**
//** Use this rather than @code(Default(TSprite3DModelSlot)): where Gorilla.DefTypes is in
//** scope, @code(Default) names its TGorillaOAuthMode value instead of the intrinsic.
//**
//** @returns(The empty slot.)
function EmptyModelSlot: TSprite3DModelSlot;

//** @abstract(A slot for a model just loaded, with every animation used.)
//**
//** IsAnimated is set from ANames: True if the model has any animation. Name is the file's
//** name without its extension.
//**
//** @param(AModel The model, loaded with LoadModelFile and placed with PlaceModel.)
//**
//** @param(AFileName The file it was loaded from, expanded.)
//**
//** @param(ABox The box LoadModelFile returned for it.)
//**
//** @param(ABounds Each animation's bounds, measured or from the bounds cache; empty for a
//** model without animations.)
//**
//** @param(ANames The names LoadModelFile returned: its animations, empty if it has none.)
//**
//** @returns(The slot; it does not own the model until FreeModelSlot is called on it.)
function NewModelSlot(const AModel: TGorillaModel; const AFileName: String;
  const ABox: TBoundingBox; const ABounds: TArray<TAnimationBounds>;
  const ANames: TArray<String>): TSprite3DModelSlot;

//** @abstract(Which of ASlots was loaded from AFileName.)
//**
//** Names are compared expanded, in this platform's form, as the platform compares them.
//**
//** @param(ASlots The slots to look in.)
//**
//** @param(AFileName A model file.)
//**
//** @returns(The index of the first slot loaded from that file, or -1 if there is none.)
function ModelSlotIndex(const ASlots: TArray<TSprite3DModelSlot>;
  const AFileName: String): Integer;

//** @abstract(Which of ASlots is listed as AName.)
//**
//** @param(ASlots The slots to look in.)
//**
//** @param(AName A name as a slot's Name gives it; compared ignoring case, as files that
//** differ only in case would be hard to tell apart.)
//**
//** @returns(The index of the first slot with that name, or -1 if there is none.)
function ModelSlotNameIndex(const ASlots: TArray<TSprite3DModelSlot>;
  const AName: String): Integer;

//** @abstract(A name based on AName that no slot of ASlots has: AName itself if it is free,
//** otherwise @code(AName (2)), @code(AName (3)) and so on, the first that is free.)
//**
//** @param(AName The name wanted.)
//**
//** @param(ASlots The slots whose names are taken.)
//**
//** @returns(The free name.)
function UniqueModelName(const AName: String; const ASlots: TArray<TSprite3DModelSlot>): String;

//** @abstract(The file spec of every model format LoadModelFile loads.)
//**
//** @returns(@code(*.glb;*.gltf;*.fbx;*.obj;*.usdc;*.usda;*.usd;*.usdz;*.dae;*.stl;*.ply),
//** from the same list IsModelFile uses.)
function AllModelsFileSpec: String;

//** @abstract(Frees a slot's model, with its helpers, and empties the slot.)
//**
//** The model's axes, grid and swept volumes are its own components, so go
//** with it. Afterwards ASlot is EmptyModelSlot. The caller must first
//** stop using the model, if it is the one shown.
//**
//** @param(ASlot The slot whose model goes; nothing is freed if its Model is nil.)
procedure FreeModelSlot(var ASlot: TSprite3DModelSlot);

//** @abstract(Shows or hides a model together with what is drawn beside it.)
//**
//** Its axes and grid, from Sprite3DAxes and Sprite3DGrid, and its swept volumes, from
//** Sprite3DSweep, are drawn in the model's parent rather than as its children, so they do
//** not follow the model's Visible: each is shown or hidden here with it.
//**
//** @param(AModel The model; nothing happens if it is nil.)
//**
//** @param(AShown True to show it, False to hide it.)
procedure ShowModelWithHelpers(const AModel: TGorillaModel; const AShown: Boolean);

//** @abstract(Whether a file is a model LoadModelFile can load, judged by its extension.)
//**
//** The extensions are those of the loaders this unit registers: .glb, .gltf, .fbx, .obj,
//** .usdc, .usda, .usd, .usdz, .dae, .stl and .ply, in any case. The file's contents are not checked.
//**
//** @param(AFileName A file name or path.)
//**
//** @returns(True if its extension is one of the model formats.)
function IsModelFile(const AFileName: String): Boolean;

//** @abstract(The model to load at start-up: the first one the system asked to open, or
//** ADefault.)
//**
//** @param(ARequested The files the operating system asked the application to open, oldest
//** first, as Sprite3DOpenFiles collects them; files that are not models are skipped.)
//**
//** @param(ADefault The model to load when none was asked for.)
//**
//** @returns(The first model in ARequested, or ADefault if it holds none.)
function StartupModelFile(const ARequested: TArray<String>;
  const ADefault: String): String;

type
  //** @abstract(A read of a model file on a worker thread, from StartModelFileRead.)
  //**
  //** Every member may be called from the main thread while the read goes on. The worker holds
  //** its own reference, so letting go of this one, or cancelling, never leaves it reading
  //** freed memory.
  IModelFileRead = interface
    ['{3E8B6A51-2C4D-4F7A-9E1B-5D7C8A9F0B24}']
    //** @abstract(Asks the worker to stop at the next block; Done follows soon after.)
    procedure Cancel;
    //** @abstract(True once the worker has stopped: read to the end, cancelled, or failed.)
    //**
    //** @returns(Whether the read is over.)
    function Done: Boolean;
    //** @abstract(How many bytes have been read so far.)
    //**
    //** @returns(The count, from 0 to TotalBytes.)
    function BytesRead: Int64;
    //** @abstract(The file's size in bytes; 0 until the file has been opened.)
    //**
    //** @returns(The size.)
    function TotalBytes: Int64;
    //** @abstract(Why the read failed, once Done; empty if it did not.)
    //**
    //** @returns(The error message, or an empty string.)
    function Error: String;
  end;

//** @abstract(Starts reading a model file from start to end on a worker thread.)
//**
//** Nothing is kept: the point is to bring the file into the operating system's file cache,
//** which is where a cold load spends most of its time, while the user interface goes on and
//** the read can be cancelled; Gorilla3D's own load, which cannot, then finds it there. The
//** file is read in blocks of a megabyte, shared for reading and writing.
//**
//** @param(AFileName The file to read.)
//**
//** @returns(The read under way.)
function StartModelFileRead(const AFileName: String): IModelFileRead;

//** @abstract(Where the measured animation bounds of a model file are kept between
//** sessions.)
//**
//** A file in the bounds folder of SupportFolder, named from a hash of the model's full path,
//** size and time of last change, so a model that is changed or replaced gets a new file
//** and its old figures are never used. Nothing is created.
//**
//** @param(AModelFile The model file; it must exist.)
//**
//** @returns(The cache file's path, or empty if the model file cannot be found.)
function AnimationBoundsCacheFile(const AModelFile: String): String;

//** @abstract(Reads the animation bounds saved for a model file, so they need not be measured
//** again.)
//**
//** The figures are used only if they were saved for exactly the animations named, in any
//** order, and by this version of the cache; anything else, a damaged file included, gives
//** False and leaves the model to be measured.
//**
//** @param(AModelFile The model file, as loaded.)
//**
//** @param(ANames Every animation the model has, as LoadModelFile listed them.)
//**
//** @param(ABounds The figures, in the order they were saved; empty when False, and without
//** any animation that had no pose to measure.)
//**
//** @returns(True if usable figures were read.)
function LoadAnimationBoundsCache(const AModelFile: String; const ANames: TArray<String>;
  out ABounds: TArray<TAnimationBounds>): Boolean;

//** @abstract(Saves a model file's measured animation bounds for the next time it is
//** loaded.)
//**
//** Writes AnimationBoundsCacheFile as JSON, making the folder if need be. A failure to write
//** is ignored: the model is simply measured again next time.
//**
//** @param(AModelFile The model file the figures were measured from.)
//**
//** @param(ANames Every animation the model has, as LoadModelFile listed them.)
//**
//** @param(ABounds The figures, as TAnimationBoundsMeasurer gave them.)
procedure SaveAnimationBoundsCache(const AModelFile: String; const ANames: TArray<String>;
  const ABounds: TArray<TAnimationBounds>);

//** @abstract(The names of a projection: its settings key and caption.)
//**
//** @param(AProjection The projection.)
//** @returns(Its names.)
function ProjectionInfo(const AProjection: TSprite3DProjection): TSprite3DProjectionInfo;

//** @abstract(Gives the whole application, title bars included, the look ATheme names.)
//**
//** thDefault puts back FMX's own platform style and the system's title bars. The other
//** themes are the FMX styles that come with RAD Studio: Dark.style, AquaGraphite.style,
//** RubyGraphite.style and GoldenGraphite.style. Each is looked for as a linked-in RCDATA
//** resource called @code(Sprite3D<Name>Style), such as @code(Sprite3DDarkStyle), which
//** @code(styles\Sprite3DThemes.rc) links into every build, then, should that be missing, as a
//** file in a @code(styles) folder beside the program or its assets, beside the program,
//** in a @code(styles) folder in SupportFolder, or, on Windows, in RAD Studio's
//** @code(Redist\styles\Fmx) folder when the BDS environment variable is set, as it is when
//** run from the IDE. Once the style is in use, the title bars take its form background
//** colour, with the theme's accent as the window border, where the system allows; see
//** Sprite3DTitleBar.
//**
//** @param(ATheme The look to use.)
//**
//** @param(AError On failure, why, including where it looked.)
//**
//** @returns(True if the look is now in use; False leaves the current one, title bars
//** included.)
function ApplyTheme(const ATheme: TSprite3DTheme; out AError: String): Boolean;

//** @abstract(True where the GPU preference can be set: Windows only.)
//**
//** @returns(True on Windows.)
function GpuModeSupported: Boolean;

//** @abstract(The GPU preference Windows has for this program file now.)
//**
//** @returns(The preference, or gmSystem where there is none or the platform has none.)
function ReadGpuMode: TSprite3DGpuMode;

//** @abstract(Asks Windows for a GPU for this program file, from the next start.)
//**
//** gmSystem removes the program's entry, handing the choice back to Windows. Uses
//** GpuPreference.SetGpuPreference.
//**
//** @param(AMode The preference.)
//**
//** @returns(True if it was stored; always False where GpuModeSupported is False.)
function WriteGpuMode(const AMode: TSprite3DGpuMode): Boolean;

//** @abstract(The File, Settings choices as they stand now.)
//**
//** The GPU preference is read from the system, where it can say; the rest come from
//** ASettings.
//**
//** @param(ASettings The application's settings.)
//**
//** @returns(The choices.)
function ReadGeneralSettings(const ASettings: TSprite3DAppSettings): TSprite3DGeneralSettings;

implementation

uses
  System.Classes, System.Math, System.IOUtils, System.Hash, System.StrUtils,
  System.Threading, System.SyncObjs, System.Generics.Collections,
  OSPaths, JsonText, Sprite3DStyles, Sprite3DTitleBar, Sprite3DAxes, Sprite3DGrid,
  {$IF DEFINED(MSWINDOWS)}
  GpuPreference,
  {$ENDIF}
  Gorilla.DefTypes,
  Gorilla.Animation,
  Gorilla.GLB.Loader,
  Gorilla.GLTF.Loader,
  Gorilla.OBJ.Loader,
  Gorilla.USD.Loader,
  Gorilla.FBX.Loader,
  Gorilla.DAE.Loader,
  Gorilla.STL.Loader,
  Gorilla.PLY.Loader;

const
  // The turn every loaded model is given so that it stands upright
  MODEL_ROTATION: TPoint3D = (X: 180; Y: 0; Z: 0);

{ TSprite3DAppSettings }

constructor TSprite3DAppSettings.Create;
begin
  inherited Create(TPath.Combine(SupportFolder, SETTINGS_FILE_NAME));
  // As the main form's check boxes start: all off, the first run showing
  // the model alone; a settings.json without these keys leaves them so.
  // The grid is not among them: it is always shown.
  FShowBoundingBox := False;
  FShowAxes := False;
  FShowSweptVolume := False;
  FShowCombinedSweptVolume := False;
  FOrthographic := False;
  // Empty: decided by FOrthographic, so a file from before View, Projection
  // keeps its projection
  FProjection := String.Empty;
  FHeadlight := True;
  FOriginalLight := False;
  // The main form's view as it starts
  FCameraView := 'Isometric';
  FVariableAzimuth := 0;
  FVariableInclination := 0;
  FVariableRoll := 0;
  // Panning is rare: off, and centred, until chosen
  FPanEnabled := False;
  FPanX := 0;
  FPanZ := 0;
  FKeepShift := False;
  FDistanceFactor := 1;
  // File, Settings: nothing loaded at the first start, as no sample model
  // comes with the program
  FStartupAction := saNone;
  FLastModel := String.Empty;
  SetThemeKind(thDefault);
  FGpuMode := gmSystem;
  FViewFps := VIEW_FPS_DEFAULT;
  SetMinifyJson(False);
  FMouseView := False;
end;

procedure TSprite3DAppSettings.SetViewFps(const Value: Integer);
begin
  FViewFps := EnsureRange(Value, VIEW_FPS_MIN, VIEW_FPS_MAX);
end;

procedure TSprite3DAppSettings.SetMinifyJson(const Value: Boolean);
begin
  FMinifyJson := Value;
  JsonText.MinifyJson := Value;   // every JSON file written from now on
end;

class function TSprite3DAppSettings.SupportFolder: String;
begin
  Result := OSFriendlyPath(AppDataFolder(APP_NAME));
end;

function CompassPointName(const ADegrees: Single): String;
const
  // The 32 points, from north clockwise, 11.25 degrees apart
  POINT_STEP = 360 / 32;
  POINT_TOLERANCE = 0.01;
  NAMES: array[0..31] of String = (
    'N', 'NbE', 'NNE', 'NEbN', 'NE', 'NEbE', 'ENE', 'EbN',
    'E', 'EbS', 'ESE', 'SEbE', 'SE', 'SEbS', 'SSE', 'SbE',
    'S', 'SbW', 'SSW', 'SWbS', 'SW', 'SWbW', 'WSW', 'WbS',
    'W', 'WbN', 'WNW', 'NWbW', 'NW', 'NWbN', 'NNW', 'NbW');
var
  Angle: Single;
  Steps: Integer;
begin
  Result := String.Empty;
  Angle := Wrap360(ADegrees);
  Steps := Round(Angle / POINT_STEP);
  if Abs(Angle - Steps * POINT_STEP) <= POINT_TOLERANCE then
    Result := NAMES[Steps mod 32];
end;

function Wrap360(const ADegrees: Single): Single;
begin
  Result := ADegrees - 360 * Floor(ADegrees / 360);
end;

function DegreesText(const ADegrees: Single): String;
begin
  Result := Format('%3d', [Round(ADegrees) mod 360]);
end;

function DefaultModelDir: String;
begin
  // Once the library path on macOS and the home folder on Linux, with the
  // current folder on Windows when it had a models subfolder; a later line
  // overrode all of that with the assets folder, so that is what it is
  Result := GetAssetsPath('../../../');
end;

const
  // One for each loader in the uses clause above
  // (Gorilla.USD.Loader reads USD's binary, text and either-format files,
  // and the zipped package)
  MODEL_EXTENSIONS: array[0..10] of String =
    ('.glb', '.gltf', '.fbx', '.obj', '.usdc', '.usda', '.usd', '.usdz', '.dae', '.stl',
     '.ply');

function AllModelsFileSpec: String;
begin
  Result := String.Empty;
  for var Known in MODEL_EXTENSIONS do
  begin
    if Result <> String.Empty then
      Result := Result + ';';
    Result := Result + '*' + Known;
  end;
end;

function IsModelFile(const AFileName: String): Boolean;
var
  Ext: String;
begin
  Ext := ExtractFileExt(AFileName);
  for var Known in MODEL_EXTENSIONS do
    if SameText(Ext, Known) then
      Exit(True);
  Result := False;
end;

function StartupModelFile(const ARequested: TArray<String>;
  const ADefault: String): String;
begin
  for var FileName in ARequested do
    if IsModelFile(FileName) then
      Exit(FileName);
  Result := ADefault;
end;

type
  // The read StartModelFileRead starts; the counters are shared with the
  // worker, so they are only touched through TInterlocked
  TModelFileRead = class(TInterfacedObject, IModelFileRead)
  private
    FFileName: String;
    FCancelled: Integer;
    FDone: Integer;
    FBytesRead: Int64;
    FTotalBytes: Int64;
    FError: String;   // written before FDone is set
    procedure Run;
  public
    procedure Cancel;
    function Done: Boolean;
    function BytesRead: Int64;
    function TotalBytes: Int64;
    function Error: String;
  end;

procedure TModelFileRead.Cancel;
begin
  TInterlocked.Exchange(FCancelled, 1);
end;

function TModelFileRead.Done: Boolean;
begin
  Result := TInterlocked.CompareExchange(FDone, 0, 0) <> 0;
end;

function TModelFileRead.BytesRead: Int64;
begin
  Result := TInterlocked.Read(FBytesRead);
end;

function TModelFileRead.TotalBytes: Int64;
begin
  Result := TInterlocked.Read(FTotalBytes);
end;

function TModelFileRead.Error: String;
begin
  if Done then
    Result := FError
  else
    Result := String.Empty;
end;

// On the worker: read the file to the end, a block at a time, stopping
// early if cancelled
procedure TModelFileRead.Run;
const
  BLOCK = 1024 * 1024;
var
  Stream: TFileStream;
  Buffer: TBytes;
  Count: Integer;
begin
  try
    try
      Stream := TFileStream.Create(FFileName, fmOpenRead or fmShareDenyNone);
      try
        TInterlocked.Exchange(FTotalBytes, Stream.Size);
        SetLength(Buffer, BLOCK);
        repeat
          if TInterlocked.CompareExchange(FCancelled, 0, 0) <> 0 then
            Break;
          Count := Stream.Read(Buffer[0], BLOCK);
          if Count > 0 then
            TInterlocked.Add(FBytesRead, Count);
        until Count <= 0;
      finally
        Stream.Free;
      end;
    except
      on E: Exception do
        FError := E.Message;
    end;
  finally
    TInterlocked.Exchange(FDone, 1);
  end;
end;

function StartModelFileRead(const AFileName: String): IModelFileRead;
var
  Read: TModelFileRead;
  Keep: IModelFileRead;
begin
  Read := TModelFileRead.Create;
  Read.FFileName := OSFriendlyPath(AFileName);
  Keep := Read;   // the worker's own reference
  Result := Keep;
  TTask.Run(
    procedure
    begin
      Read.Run;
      Keep := nil;
    end);
end;

const
  // Raised whenever what is measured, or how, changes, so older figures are
  // not used. 2: models were measured hidden, which left every animation at
  // its rest pose, so those figures are wrong
  BOUNDS_CACHE_VERSION = 2;
  BOUNDS_CACHE_FOLDER = 'bounds';

function AnimationBoundsCacheFile(const AModelFile: String): String;
var
  Search: TSearchRec;
  FullName, Key: String;
begin
  Result := String.Empty;
  FullName := ExpandFileName(OSFriendlyPath(AModelFile));
  if FindFirst(FullName, faAnyFile, Search) <> 0 then
    Exit;
  try
    Key := Format('%s|%d|%s|%d', [FullName, Search.Size,
      FormatDateTime('yyyymmddhhnnsszzz', Search.TimeStamp), BOUNDS_CACHE_VERSION]);
  finally
    FindClose(Search);
  end;
  Result := OSFriendlyPath(TPath.Combine(TPath.Combine(TSprite3DAppSettings.SupportFolder,
    BOUNDS_CACHE_FOLDER), THashMD5.GetHashString(Key) + '.json'));
end;

function LoadAnimationBoundsCache(const AModelFile: String; const ANames: TArray<String>;
  out ABounds: TArray<TAnimationBounds>): Boolean;
var
  FileName: String;
  Root: TJSONValue;
  Items, Names: TJSONArray;
  Item: TJSONObject;
  Box: TJSONArray;
  Entry: TAnimationBounds;
  Found: TArray<TAnimationBounds>;
  Saved: TArray<String>;
  Name: String;

  function Coord(const AIndex: Integer): Single;
  begin
    Result := (Box.Items[AIndex] as TJSONNumber).AsDouble;
  end;

begin
  Result := False;
  ABounds := nil;
  FileName := AnimationBoundsCacheFile(AModelFile);
  if (FileName = String.Empty) or not FileExists(FileName) then
    Exit;
  Root := nil;
  try
    try
      Root := TJSONObject.ParseJSONValue(TFile.ReadAllText(FileName, TEncoding.UTF8));
      if not (Root is TJSONObject) or
        (TJSONObject(Root).GetValue<Integer>('version', 0) <> BOUNDS_CACHE_VERSION) then
        Exit;
      // Saved for exactly these animations, each once
      Names := TJSONObject(Root).GetValue('names') as TJSONArray;
      if (Names = nil) or (Names.Count <> Length(ANames)) then
        Exit;
      for var I := 0 to Names.Count - 1 do
        Saved := Saved + [Names.Items[I].Value];
      for Name in ANames do
      begin
        var Count := 0;
        for var Other in Saved do
          if Other = Name then
            Inc(Count);
        if Count <> 1 then
          Exit;
      end;
      Items := TJSONObject(Root).GetValue('animations') as TJSONArray;
      if (Items = nil) or (Items.Count > Length(ANames)) then
        Exit;
      for var I := 0 to Items.Count - 1 do
      begin
        Item := Items.Items[I] as TJSONObject;
        Box := Item.GetValue('box') as TJSONArray;
        if (Box = nil) or (Box.Count <> 6) then
          Exit;
        Entry.Name := Item.GetValue<String>('name');
        Entry.Poses := Item.GetValue<Integer>('poses');
        Entry.Box.TopLeftNear := Point3D(Coord(0), Coord(1), Coord(2));
        Entry.Box.BottomRightFar := Point3D(Coord(3), Coord(4), Coord(5));
        if IndexStr(Entry.Name, Saved) < 0 then
          Exit;
        Found := Found + [Entry];
      end;
      ABounds := Found;
      Result := True;
    except
      ABounds := nil;   // damaged or unreadable: measure again
      Result := False;
    end;
  finally
    Root.Free;
  end;
end;

procedure SaveAnimationBoundsCache(const AModelFile: String; const ANames: TArray<String>;
  const ABounds: TArray<TAnimationBounds>);
var
  FileName: String;
  Root, Item: TJSONObject;
  Items, Box, Names: TJSONArray;
  Entry: TAnimationBounds;

  procedure AddCoord(const AValue: Double);
  begin
    Box.AddElement(TJSONNumber.Create(AValue));
  end;

begin
  FileName := AnimationBoundsCacheFile(AModelFile);
  if FileName = String.Empty then
    Exit;
  Root := TJSONObject.Create;
  try
    Root.AddPair('version', TJSONNumber.Create(BOUNDS_CACHE_VERSION));
    Root.AddPair('model', ExpandFileName(AModelFile));
    Names := TJSONArray.Create;
    Root.AddPair('names', Names);
    for var Name in ANames do
      Names.Add(Name);
    Items := TJSONArray.Create;
    Root.AddPair('animations', Items);
    for Entry in ABounds do
    begin
      Item := TJSONObject.Create;
      Items.AddElement(Item);
      Item.AddPair('name', Entry.Name);
      Item.AddPair('poses', TJSONNumber.Create(Entry.Poses));
      Box := TJSONArray.Create;
      Item.AddPair('box', Box);
      AddCoord(Entry.Box.TopLeftNear.X);
      AddCoord(Entry.Box.TopLeftNear.Y);
      AddCoord(Entry.Box.TopLeftNear.Z);
      AddCoord(Entry.Box.BottomRightFar.X);
      AddCoord(Entry.Box.BottomRightFar.Y);
      AddCoord(Entry.Box.BottomRightFar.Z);
    end;
    try
      ForceDirectories(ExtractFilePath(FileName));
      // UTF-8 without a byte order mark, indented or minified as asked
      TFile.WriteAllBytes(FileName, JsonToBytes(Root));
    except
      // Not kept: measured again next time
    end;
  finally
    Root.Free;
  end;
end;

function LoadModelFile(const AModel: TGorillaModel; const AFileName: String;
  out ABox: TBoundingBox): TArray<String>;
var
  Names: TStringList;
  I: Integer;
  Ani: TArray<TGorillaAnimation>;
begin
  AModel.Clear;
  AModel.LoadFromFile(nil, OSFriendlyPath(AFileName), [TAnimationCachingFlag.VertexPosition]);

  Names := TStringList.Create;
  try
    Ani := AModel.AnimationManager.GetSortedAnimations();
    for I := 0 to Length(Ani) - 1 do
      Names.Add(Ani[I].Id);
    Result := Names.ToStringArray;
  finally
    Names.Free;
  end;

  // Taken before the caller adds axes or a grid to the model, which would
  // otherwise count towards it
  ABox := AModel.GetBoundingBox();
end;

procedure PlaceModel(const AModel: TGorillaModel; const ABox: TBoundingBox);
begin
  AModel.Position.Point := Point3D(ABox.TopLeftNear.X + (ABox.Width / 2),
                                   ABox.TopLeftNear.Y + (ABox.Height / 2),
                                   ABox.TopLeftNear.Z + (ABox.Depth / 2));
  AModel.RotationAngle.X := MODEL_ROTATION.X;
  AModel.RotationAngle.Y := MODEL_ROTATION.Y;
  AModel.RotationAngle.Z := MODEL_ROTATION.Z;
end;

function EmptyModelSlot: TSprite3DModelSlot;
begin
  // Every field set; Default() would mean Gorilla's TGorillaOAuthMode.Default
  Result.Model := nil;
  Result.FileName := String.Empty;
  Result.Name := String.Empty;
  Result.Box.TopLeftNear := TPoint3D.Zero;
  Result.Box.BottomRightFar := TPoint3D.Zero;
  Result.Bounds := nil;
  Result.Names := nil;
  Result.Used := nil;
  Result.IsAnimated := False;
  Result.Order := 0;
end;

function NewModelSlot(const AModel: TGorillaModel; const AFileName: String;
  const ABox: TBoundingBox; const ABounds: TArray<TAnimationBounds>;
  const ANames: TArray<String>): TSprite3DModelSlot;
begin
  Result := EmptyModelSlot;
  Result.Model := AModel;
  Result.FileName := AFileName;
  Result.Name := TPath.GetFileNameWithoutExtension(AFileName);
  Result.Box := ABox;
  Result.Bounds := ABounds;
  Result.Names := ANames;
  Result.Used := Copy(ANames);
  Result.IsAnimated := Length(ANames) > 0;
end;

function ModelSlotIndex(const ASlots: TArray<TSprite3DModelSlot>;
  const AFileName: String): Integer;
var
  Wanted: String;
  I: Integer;
begin
  Result := -1;
  Wanted := ExpandFileName(OSFriendlyPath(AFileName));
  for I := 0 to High(ASlots) do
    if SameFileName(ExpandFileName(OSFriendlyPath(ASlots[I].FileName)), Wanted) then
      Exit(I);
end;

function ModelSlotNameIndex(const ASlots: TArray<TSprite3DModelSlot>;
  const AName: String): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(ASlots) do
    if SameText(ASlots[I].Name, AName) then
      Exit(I);
end;

function UniqueModelName(const AName: String; const ASlots: TArray<TSprite3DModelSlot>): String;
var
  Number: Integer;
begin
  Result := AName;
  Number := 1;
  while ModelSlotNameIndex(ASlots, Result) >= 0 do
  begin
    Inc(Number);
    Result := Format('%s (%d)', [AName, Number]);
  end;
end;

procedure FreeModelSlot(var ASlot: TSprite3DModelSlot);
var
  Model: TGorillaModel;
begin
  Model := ASlot.Model;
  ASlot := EmptyModelSlot;
  if Model = nil then
    Exit;
  Model.Parent := nil;
  Model.Free;
end;

procedure ShowModelWithHelpers(const AModel: TGorillaModel; const AShown: Boolean);
var
  Sweep: TModelSweep;
  Combined: TCombinedSweep;
  Axes: TModelAxes;
  Grid: TModelGrid;
begin
  if AModel = nil then
    Exit;
  AModel.Visible := AShown;
  Sweep := FindModelSweep(AModel);
  if Sweep <> nil then
    Sweep.Visible := AShown;
  Combined := FindCombinedSweep(AModel);
  if Combined <> nil then
    Combined.Visible := AShown;
  // Hidden with Shown, as their lines are not their children either
  Axes := FindModelAxes(AModel);
  if Axes <> nil then
    Axes.Shown := AShown;
  Grid := FindModelGrid(AModel);
  if Grid <> nil then
    Grid.Shown := AShown;
end;

type
  // What the application knows about each theme
  TThemeInfo = record
    Key: String;             // in settings.json, and the style's file name
    Fallback: TAlphaColor;   // caption colour if the style's background can't be read
    Accent: TAlphaColor;     // window border; Null for the system's
  end;

const
  THEMES: array[TSprite3DTheme] of TThemeInfo = (
    (Key: 'Default';        Fallback: TAlphaColors.White; Accent: TAlphaColors.Null),
    (Key: 'Dark';           Fallback: $FF2B2B2B;          Accent: TAlphaColors.Null),
    (Key: 'AquaGraphite';   Fallback: $FF3A3A3A;          Accent: $FF2A9FD6),
    (Key: 'RubyGraphite';   Fallback: $FF3A3A3A;          Accent: $FFC0262C),
    (Key: 'GoldenGraphite'; Fallback: $FF3A3A3A;          Accent: $FFD4A017));

function TSprite3DAppSettings.GetThemeKind: TSprite3DTheme;
begin
  for var Kind := Low(TSprite3DTheme) to High(TSprite3DTheme) do
    if SameText(FTheme, THEMES[Kind].Key) then
      Exit(Kind);
  Result := thDefault;
end;

procedure TSprite3DAppSettings.SetThemeKind(const Value: TSprite3DTheme);
begin
  FTheme := THEMES[Value].Key;
end;

const
  //** @abstract(The names of each projection; see TSprite3DProjectionInfo.)
  PROJECTIONS: array[TSprite3DProjection] of TSprite3DProjectionInfo = (
    (Key: 'Perspective';  Caption: 'Perspective'),
    (Key: 'Orthographic'; Caption: 'Orthographic'),
    (Key: 'Cavalier';     Caption: 'Cavalier'),
    (Key: 'Cabinet';      Caption: 'Cabinet'),
    (Key: 'Military';     Caption: 'Military'),
    (Key: 'PlanOblique';  Caption: 'Plan Oblique'));

function ProjectionInfo(const AProjection: TSprite3DProjection): TSprite3DProjectionInfo;
begin
  Result := PROJECTIONS[AProjection];
end;

function TSprite3DAppSettings.GetProjectionKind: TSprite3DProjection;
begin
  if FProjection = String.Empty then
  begin
    if FOrthographic then
      Exit(prOrthographic);
    Exit(prPerspective);
  end;
  for var Kind := Low(TSprite3DProjection) to High(TSprite3DProjection) do
    if SameText(FProjection, PROJECTIONS[Kind].Key) then
      Exit(Kind);
  Result := prPerspective;
end;

procedure TSprite3DAppSettings.SetProjectionKind(const Value: TSprite3DProjection);
begin
  FProjection := PROJECTIONS[Value].Key;
  FOrthographic := Value = prOrthographic;
end;

function ApplyTheme(const ATheme: TSprite3DTheme; out AError: String): Boolean;
var
  Folders: TArray<String>;
  Assets, Bds, StyleName, ResourceName: String;
begin
  Assets := GetAssetsPath('../../../');
  Folders := [];
  if Assets <> String.Empty then
    Folders := Folders + [TPath.Combine(Assets, 'styles'), Assets];
  Folders := Folders + [TPath.Combine(TSprite3DAppSettings.SupportFolder, 'styles')];
  {$IF DEFINED(MSWINDOWS)}
  // Set by the IDE for programs it runs, so a development build finds the
  // styles that come with RAD Studio without copying them
  Bds := GetEnvironmentVariable('BDS');
  if Bds <> String.Empty then
    Folders := Folders + [TPath.Combine(Bds, 'Redist\styles\Fmx')];
  {$ELSE}
  Bds := String.Empty;
  {$ENDIF}

  if ATheme = thDefault then
  begin
    StyleName := String.Empty;
    ResourceName := String.Empty;
  end
  else
  begin
    StyleName := THEMES[ATheme].Key;
    ResourceName := 'Sprite3D' + StyleName + 'Style';
  end;

  Result := ApplyFmxStyle(StyleName, ResourceName, Folders, AError);
  if not Result then
    Exit;   // the old style is still in use; so are its title bars

  if ATheme = thDefault then
    SetTitleBarSpec(TSprite3DTitleBarSpec.System)
  else
    SetTitleBarSpec(TitleBarSpecFromStyle(THEMES[ATheme].Fallback, THEMES[ATheme].Accent));
end;

const
  // The MIME types Linux knows the model files by; each pairs with an
  // extension in MODEL_EXTENSIONS
  MODEL_MIME_TYPES: array[0..10] of String =
    ('model/gltf-binary', 'model/gltf+json', 'model/x-fbx', 'model/obj',
     'model/x-usdc', 'model/x-usda', 'model/x-usd', 'model/vnd.usdz+zip',
     'model/vnd.collada+xml', 'model/stl', 'model/x-ply');
  MODEL_DESCRIPTIONS: array[0..10] of String =
    ('glTF binary model', 'glTF model', 'FBX model', 'Wavefront OBJ model',
     'USD binary model', 'USD text model', 'USD model', 'USD package', 'Collada model',
     'STL model', 'PLY model');

function GpuModeSupported: Boolean;
begin
  {$IF DEFINED(MSWINDOWS)}
  Result := True;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function ReadGpuMode: TSprite3DGpuMode;
{$IF DEFINED(MSWINDOWS)}
var
  Preference: TGpuPreference;
{$ENDIF}
begin
  Result := gmSystem;
  {$IF DEFINED(MSWINDOWS)}
  if GetGpuPreference(Preference, gpAutomatic) then
    case Preference of
      gpPowerSaving: Result := gmPowerSaving;
      gpHighPerformance: Result := gmHighPerformance;
    end;
  {$ENDIF}
end;

function WriteGpuMode(const AMode: TSprite3DGpuMode): Boolean;
begin
  {$IF DEFINED(MSWINDOWS)}
  case AMode of
    gmPowerSaving: Result := SetGpuPreference(gpPowerSaving);
    gmHighPerformance: Result := SetGpuPreference(gpHighPerformance);
  else
    Result := SetGpuPreference(gpAutomatic);
  end;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function ReadGeneralSettings(const ASettings: TSprite3DAppSettings): TSprite3DGeneralSettings;
begin
  Result.StartupAction := ASettings.StartupAction;
  Result.Theme := ASettings.ThemeKind;
  Result.ViewFps := ASettings.ViewFps;
  Result.MinifyJson := ASettings.MinifyJson;
  // The caller knows the display; until it says, at least the rate in use
  Result.MaxViewFps := Max(ASettings.ViewFps, VIEW_FPS_DEFAULT);
  if GpuModeSupported then
    Result.GpuMode := ReadGpuMode
  else
    Result.GpuMode := ASettings.GpuMode;
end;

end.
