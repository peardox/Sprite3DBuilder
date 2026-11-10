//** @abstract(The Assets form: every model of the asset folders chosen, as thumbnails in groups.)
//**
//** File, Open Asset Folder gives the folders to OpenFolders, which shows the form and finds
//** every model in them (AssetModelFiles). Their keys, the SHA-256 of each model's content
//** (TSprite3DAssetHasher, from Sprite3DAssetCache), are worked out on a worker thread, as
//** that is only reading files. A model whose key the thumbnail cache knows, with a thumbnail
//** of THUMBNAIL_SIZE, is shown from the cache at once; every other one is queued, and its
//** thumbnail made, one model at a time: loaded into the form's own viewport, turned upright,
//** framed in a fixed isometric view in orthographic projection, and grabbed off screen by a
//** TSprite3DOffscreen at THUMBNAIL_SIZE square, with a transparent background. The PNG and
//** the model's metadata, its bounding box among it, go into the cache, so the next time the
//** folder is opened nothing need be made. Two files with the same key are one model: the
//** second is noted in the log and not shown again.
//**
//** The thumbnails are laid out in a grid, under a heading for each group, AssetGroupName of
//** each name, with a plural group put with its singular when the folder has both; groups and
//** models are in alphabetical order. Clicking a thumbnail selects it, and the panel at the top
//** gives its name, group, size in its own units, and file. The viewport at the top left
//** shows each model while its thumbnail is made.
//**
//** Dragging a thumbnail onto the level is the next step; it is not here yet.
//**
//** Closing the form stops making thumbnails; those made so far stay in the cache, and opening
//** the folder again carries on from there. Everything the form has to report goes to OnLog,
//** for the Debug tab. For the main thread only, but for the hashing, which keeps to its own
//** data and hands back its results with @code(TThread.Queue).
//**
//** @preformatted(
//** TAssetsForm
//** |-- TopLayout
//** |   |-- PreviewArea     dark grey; the TGorillaViewport, made in code, fills it
//** |   `-- InfoLayout      StatusLabel, Progress, NameLabel, SizeLabel, FileLabel
//** `-- TilesBox            TVertScrollBox
//**     `-- FTilesLayout    made in code: a heading per group, then its tiles
//** )
unit Sprite3DBuilderAssetsForm;

{
  The Assets form: every model of the asset folders chosen, as thumbnails in
  groups.

  File, Open Asset Folder gives the folders to OpenFolders, which shows the
  form and finds every model in them (AssetModelFiles). Their keys, the
  SHA-256 of each model's content (TSprite3DAssetHasher, from
  Sprite3DAssetCache), are worked out on a worker thread, as that is only
  reading files. A model whose key the thumbnail cache knows, with a
  thumbnail of THUMBNAIL_SIZE, is shown from the cache at once; every other
  one is queued, and its thumbnail made, one model at a time: loaded into
  the form's own viewport, turned upright, framed in a fixed isometric view
  in orthographic projection, and grabbed off screen by a TSprite3DOffscreen
  at THUMBNAIL_SIZE square, with a transparent background. The PNG and the
  model's metadata, its bounding box among it, go into the cache, so the
  next time the folder is opened nothing need be made. Two files with the
  same key are one model: the second is noted in the log and not shown
  again.

  The thumbnails are laid out in a grid, under a heading for each group,
  AssetGroupName of each name, with a plural group put with its singular
  when the folder has both; groups and models are in alphabetical order.
  Clicking a thumbnail selects it, and the panel at the top gives its name,
  group, size in its own units, and file. The viewport at the top left shows
  each model while its thumbnail is made.

  Dragging a thumbnail onto the level is the next step; it is not here yet.

  Closing the form stops making thumbnails; those made so far stay in the
  cache, and opening the folder again carries on from there. Everything the
  form has to report goes to OnLog, for the Debug tab. For the main thread
  only, but for the hashing, which keeps to its own data and hands back its
  results with TThread.Queue.

    TAssetsForm
    |-- TopLayout
    |   |-- PreviewArea     dark grey; the TGorillaViewport, made in code, fills it
    |   `-- InfoLayout      StatusLabel, Progress, NameLabel, SizeLabel, FileLabel
    `-- TilesBox            TVertScrollBox
        `-- FTilesLayout    made in code: a heading per group, then its tiles
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math.Vectors,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.Types3D, Gorilla.Viewport, Gorilla.Model,
  Gorilla.Camera, Spritely.OrbitalCamera, Sprite3DOffscreen, Sprite3DAssetCache;

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
    //** @abstract(Its tile in FTilesLayout; nil until the tiles are laid out.)
    Tile: TRectangle;
    //** @abstract(The image on Tile showing the thumbnail.)
    Image: TImage;
    //** @abstract(True once the thumbnail is in the cache and on Tile.)
    HasThumbnail: Boolean;
  end;

  //** @abstract(Says whether the form is still there, for work handed back from another
  //** thread or a later main-loop turn.)
  IAssetsAlive = interface
    ['{6C2B0E5A-3D41-4E8B-9A7F-1B5C8D2E4F60}']
    //** @abstract(True until the form is freed.)
    //**
    //** @returns(Whether the form is still there.)
    function Alive: Boolean;
    //** @abstract(Marks the form as gone.)
    procedure Kill;
  end;

  //** @abstract(The Assets form; see the unit's description.)
  TAssetsForm = class(TForm)
    //** @abstract(The strip along the top: PreviewArea and InfoLayout.)
    TopLayout: TLayout;
    //** @abstract(Dark grey behind the viewport made in FormCreate, which fills it.)
    PreviewArea: TRectangle;
    //** @abstract(Right of PreviewArea: the status, the progress and the selected model's
    //** details.)
    InfoLayout: TLayout;
    //** @abstract(What the form is doing: reading the folder, making thumbnails, or done.)
    StatusLabel: TLabel;
    //** @abstract(How far making the thumbnails has got.)
    Progress: TProgressBar;
    //** @abstract(The selected model's name and group.)
    NameLabel: TLabel;
    //** @abstract(The selected model's size, in its own units.)
    SizeLabel: TLabel;
    //** @abstract(The selected model's file.)
    FileLabel: TLabel;
    //** @abstract(Scrolls the groups and their tiles.)
    TilesBox: TVertScrollBox;
    //** @abstract(Makes the viewport, its camera and the off-screen pass.)
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
    //** @abstract(Lays the tiles out again for the new width.)
    //**
    //** @param(Sender TilesBox.)
    procedure TilesBoxResize(Sender: TObject);
  private
    //** @abstract(The form's own viewport, in PreviewArea, where thumbnails are drawn.)
    FViewport: TGorillaViewport;
    //** @abstract(The viewport's camera, from the Spritely package, fixed in the isometric
    //** view in orthographic projection, with its headlight on.)
    FCamera: TSpritelyOrbitalCamera;
    //** @abstract(Grabs each thumbnail off screen, THUMBNAIL_SIZE square, transparent.)
    FOffscreen: TSprite3DOffscreen;
    //** @abstract(The model whose thumbnail is being made, or nil.)
    FModel: TGorillaModel;
    //** @abstract(FModel's bounding box in its own space, as LoadModelFile gave it, before
    //** it was turned upright.)
    FModelBox: TBoundingBox;
    //** @abstract(The thumbnail cache, TSprite3DAppSettings.ThumbnailFolder.)
    FCacheFolder: String;
    //** @abstract(Counts the folders opened, so results for an earlier one are dropped.)
    FScanId: Integer;
    //** @abstract(Every model shown, by group, then name.)
    FEntries: TArray<TAssetEntry>;
    //** @abstract(The entries still to have their thumbnails made, first first.)
    FQueue: TArray<Integer>;
    //** @abstract(How many thumbnails this folder needed, for Progress.)
    FQueueTotal: Integer;
    //** @abstract(The entry whose thumbnail is being made; -1 for none.)
    FMaking: Integer;
    //** @abstract(The entry selected; -1 for none.)
    FSelected: Integer;
    //** @abstract(Holds the headings and tiles; made by BuildTiles.)
    FTilesLayout: TLayout;
    //** @abstract(The headings of the groups, in order, each above its tiles.)
    FHeadings: TArray<TLabel>;
    //** @abstract(Shared with work handed back later, which does nothing once the form is
    //** gone.)
    FAlive: IAssetsAlive;
    //** @abstract(Backing field for OnLog.)
    FOnLog: TAssetsLogEvent;
    //** @abstract(Hands AText to OnLog, if it is set.)
    //**
    //** @param(AText The line.)
    procedure Log(const AText: String);
    //** @abstract(The hashing's results for folder AScanId: the entries from them, cached or
    //** queued, grouped and sorted, then the tiles, then the first thumbnail.)
    //**
    //** @param(AScanId The folder they are for; anything but FScanId is dropped.)
    //**
    //** @param(AResults One per model file.)
    procedure HashesDone(const AScanId: Integer; const AResults: TArray<TAssetHashResult>);
    //** @abstract(Puts each plural group with its singular one, when both are there.)
    procedure MergePluralGroups;
    //** @abstract(Frees the tiles and headings and makes them again for FEntries.)
    procedure BuildTiles;
    //** @abstract(Places the headings and tiles in rows as wide as TilesBox.)
    procedure LayoutTiles;
    //** @abstract(Selects the clicked tile's model.)
    //**
    //** @param(Sender The tile; its Tag is the entry.)
    procedure TileClick(Sender: TObject);
    //** @abstract(Selects entry AIndex, shows its details, and marks its tile.)
    //**
    //** @param(AIndex An entry of FEntries; -1 for none.)
    procedure SelectEntry(const AIndex: Integer);
    //** @abstract(Starts making the next queued thumbnail, or says all are made.)
    procedure MakeNext;
    //** @abstract(Queues MakeNext for a fresh main-loop turn, unless the form has gone.)
    procedure MakeNextLater;
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
    //** centred on its centre of rotation.)
    //**
    //** The box framed is FModelBox widened in X and Z to be even about the model's
    //** RotationCenter, so the up axis through that centre, the axis the builder will turn
    //** the piece about and the point it places on the grid, is the middle of the picture
    //** across, wherever the piece's geometry lies about it: a corner piece is drawn off to
    //** one side of its cell, as it will sit in it. Up and down, the box's own middle is
    //** used.
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
    //** @abstract(Frees FModel, if there is one.)
    procedure FreeModel;
    //** @abstract(Stops making thumbnails: the grab under way is dropped, and the queue
    //** emptied.)
    procedure StopMaking;
  public
    //** @abstract(Shows the form and the models of AFolders, making the thumbnails it lacks.)
    //**
    //** Anything still under way for the folders opened before is dropped first.
    //**
    //** @param(AFolders The asset folders; their sub-folders are not looked in.)
    procedure OpenFolders(const AFolders: TArray<String>);
    //** @abstract(Every model shown, by group, then name.)
    property Entries: TArray<TAssetEntry> read FEntries;
    //** @abstract(The entry selected, or -1.)
    property Selected: Integer read FSelected;
    //** @abstract(Called with each line the form has to report, for the Debug tab.)
    property OnLog: TAssetsLogEvent read FOnLog write FOnLog;
  end;

implementation

uses
  System.Threading, System.Math, System.DateUtils, System.IOUtils,
  System.Generics.Collections, System.Generics.Defaults, Sprite3DBuilderHelpers;

{$R *.fmx}

const
  //** @abstract(A tile's width and height, and the thumbnail's size on it, in logical
  //** pixels.)
  TILE_WIDTH = 104;
  TILE_HEIGHT = 124;
  TILE_IMAGE = 96;
  //** @abstract(The room between tiles, and round the grid's edge.)
  TILE_GAP = 6;
  //** @abstract(A group heading's height.)
  HEADING_HEIGHT = 26;
  //** @abstract(The room left round a model in its thumbnail, as a fraction of the view.)
  THUMBNAIL_MARGIN = 0.06;
  //** @abstract(The thumbnails' view: the isometric inclination, ArcTan@(1/Sqrt@(2@)@) in
  //** degrees, and the camera's azimuth for Sprite3D's 45, which ApplyAngles in the main
  //** form reverses to 315.)
  THUMBNAIL_INCLINATION = 35.26439;
  THUMBNAIL_AZIMUTH = 315;
  //** @abstract(How the cache's metadata names the thumbnails' view.)
  THUMBNAIL_VIEW = 'isometric orthographic';
  //** @abstract(A tile's outline, and a selected tile's.)
  TILE_STROKE = TAlphaColor($60808080);
  TILE_SELECTED_STROKE = TAlphaColor($FF2A9FD6);

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

{ TAssetsForm }

procedure TAssetsForm.FormCreate(Sender: TObject);
begin
  FAlive := TAssetsAlive.Create;
  FMaking := -1;
  FSelected := -1;
  FCacheFolder := TSprite3DAppSettings.ThumbnailFolder;

  FViewport := TGorillaViewport.Create(PreviewArea);
  FViewport.Parent := PreviewArea;
  FViewport.Align := TAlignLayout.Client;
  FViewport.UseFixedFrameRate := True;
  FViewport.VSync := False;
  FViewport.FixedFrameRate := 60;
  FViewport.HitTest := False;

  // The Spritely camera, as the main form's, fixed: the isometric view in
  // orthographic projection, lit from the camera
  FCamera := TSpritelyOrbitalCamera.Create(Self);
  FCamera.Headlight := True;
  FCamera.Viewport := FViewport;
  FCamera.Camera.ProjectionMode := TGorillaCameraProjection.cpOrthographic;
  FCamera.Camera.Azimuth := THUMBNAIL_AZIMUTH;
  FCamera.Camera.PolarAngle := THUMBNAIL_INCLINATION;
  FCamera.Camera.Roll := 0;

  // Every thumbnail the same size, its background transparent
  FOffscreen := TSprite3DOffscreen.Create(FViewport);
  FOffscreen.Viewport := FViewport;
  FOffscreen.Width := THUMBNAIL_SIZE;
  FOffscreen.Height := THUMBNAIL_SIZE;
  FOffscreen.TransparentBackground := True;
  FOffscreen.OnBeforeGrab := OffscreenBeforeGrab;

  FTilesLayout := TLayout.Create(Self);
  FTilesLayout.Parent := TilesBox;
  FTilesLayout.Align := TAlignLayout.Top;
  FTilesLayout.Height := 0;
  FTilesLayout.HitTest := False;

  StatusLabel.Text := 'No asset folder open';
  Progress.Value := 0;
  SelectEntry(-1);
end;

procedure TAssetsForm.FormDestroy(Sender: TObject);
begin
  FAlive.Kill;
  if FOffscreen <> nil then
    FOffscreen.Cancel;
  FreeModel;
end;

procedure TAssetsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Length(FQueue) > 0 then
    Log(Format('Assets: stopped with %d thumbnails still to make; open the folder ' +
      'again to carry on', [Length(FQueue) + Ord(FMaking >= 0)]));
  StopMaking;
  Action := TCloseAction.caHide;
end;

procedure TAssetsForm.Log(const AText: String);
begin
  if Assigned(FOnLog) then
    FOnLog(AText);
end;

procedure TAssetsForm.OpenFolders(const AFolders: TArray<String>);
var
  Files: TArray<String>;
  ScanId: Integer;
  Alive: IAssetsAlive;
begin
  StopMaking;
  Inc(FScanId);
  FEntries := nil;
  SelectEntry(-1);
  BuildTiles;
  Show;
  BringToFront;

  Files := nil;
  for var Folder in AFolders do
    Files := Files + AssetModelFiles(Folder);
  if Length(Files) = 0 then
  begin
    StatusLabel.Text := 'No models in the folder chosen';
    Log('Assets: no models in ' + String.Join(', ', AFolders));
    Exit;
  end;
  StatusLabel.Text := Format('Reading %d models...', [Length(Files)]);
  Progress.Value := 0;
  Log(Format('Assets: %d models in %s', [Length(Files), String.Join(', ', AFolders)]));

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
  First: String;
  Cached: Integer;
begin
  if AScanId <> FScanId then
    Exit;   // another folder has been opened since
  FEntries := nil;
  FQueue := nil;
  Cached := 0;
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
      Entry.Meta.Group := AssetGroupName(Entry.Meta.Name);
      Entry.Meta.FileName := R.FileName;
      Entry.Meta.Files := R.Files;
      FEntries := FEntries + [Entry];
    end;
  finally
    Seen.Free;
  end;
  MergePluralGroups;

  TArray.Sort<TAssetEntry>(FEntries, TComparer<TAssetEntry>.Construct(
    function(const A, B: TAssetEntry): Integer
    begin
      Result := CompareText(A.Meta.Group, B.Meta.Group);
      if Result = 0 then
        Result := CompareText(A.Meta.Name, B.Meta.Name);
    end));
  for var I := 0 to High(FEntries) do
    if not FEntries[I].HasThumbnail then
      FQueue := FQueue + [I];
  FQueueTotal := Length(FQueue);

  BuildTiles;
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
    for var I := 0 to High(FEntries) do
    begin
      Group := FEntries[I].Meta.Group;
      if (Group.Length > 1) and Group.EndsWith('s') and
        Groups.ContainsKey(Group.Substring(0, Group.Length - 1)) then
        FEntries[I].Meta.Group := Group.Substring(0, Group.Length - 1);
    end;
  finally
    Groups.Free;
  end;
end;

procedure TAssetsForm.BuildTiles;
var
  Group: String;
  Heading: TLabel;
  Tile: TRectangle;
  Image: TImage;
  Caption: TLabel;
  Count: Integer;
  Bitmap: TBitmap;
begin
  TilesBox.BeginUpdate;
  try
    FTilesLayout.DeleteChildren;
    FHeadings := nil;
    Group := #0;
    for var I := 0 to High(FEntries) do
    begin
      if FEntries[I].Meta.Group <> Group then
      begin
        Group := FEntries[I].Meta.Group;
        Count := 0;
        for var Entry in FEntries do
          if Entry.Meta.Group = Group then
            Inc(Count);
        Heading := TLabel.Create(FTilesLayout);
        Heading.Parent := FTilesLayout;
        Heading.StyledSettings := Heading.StyledSettings - [TStyledSetting.Style];
        Heading.TextSettings.Font.Style := [TFontStyle.fsBold];
        Heading.Text := Format('%s (%d)', [Group, Count]);
        Heading.HitTest := False;
        // The first tile of the group follows it
        Heading.Tag := I;
        FHeadings := FHeadings + [Heading];
      end;

      Tile := TRectangle.Create(FTilesLayout);
      Tile.Parent := FTilesLayout;
      Tile.Width := TILE_WIDTH;
      Tile.Height := TILE_HEIGHT;
      Tile.XRadius := 4;
      Tile.YRadius := 4;
      Tile.Fill.Kind := TBrushKind.None;
      Tile.Stroke.Color := TILE_STROKE;
      Tile.Tag := I;
      Tile.Hint := FEntries[I].Meta.Name;
      Tile.ShowHint := True;
      Tile.OnClick := TileClick;

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
  Columns, Column, HeadingIndex: Integer;
  Y: Single;
begin
  if FTilesLayout = nil then
    Exit;
  Columns := Max(1, Trunc((TilesBox.Width - TILE_GAP) / (TILE_WIDTH + TILE_GAP)));
  Y := TILE_GAP;
  Column := 0;
  HeadingIndex := 0;
  for var I := 0 to High(FEntries) do
  begin
    // A group's heading, on a row of its own
    if (HeadingIndex <= High(FHeadings)) and (FHeadings[HeadingIndex].Tag = I) then
    begin
      if Column > 0 then
        Y := Y + TILE_HEIGHT + TILE_GAP;
      Column := 0;
      FHeadings[HeadingIndex].SetBounds(TILE_GAP, Y, Max(1,
        TilesBox.Width - 2 * TILE_GAP), HEADING_HEIGHT);
      Y := Y + HEADING_HEIGHT;
      Inc(HeadingIndex);
    end;
    if FEntries[I].Tile <> nil then
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

procedure TAssetsForm.TileClick(Sender: TObject);
begin
  if Sender is TRectangle then
    SelectEntry(TRectangle(Sender).Tag);
end;

procedure TAssetsForm.SelectEntry(const AIndex: Integer);
var
  Size: TPoint3D;
begin
  if (FSelected >= 0) and (FSelected <= High(FEntries)) and
    (FEntries[FSelected].Tile <> nil) then
  begin
    FEntries[FSelected].Tile.Stroke.Color := TILE_STROKE;
    FEntries[FSelected].Tile.Stroke.Thickness := 1;
  end;
  if (AIndex < 0) or (AIndex > High(FEntries)) then
  begin
    FSelected := -1;
    NameLabel.Text := String.Empty;
    SizeLabel.Text := String.Empty;
    FileLabel.Text := String.Empty;
    Exit;
  end;
  FSelected := AIndex;
  if FEntries[AIndex].Tile <> nil then
  begin
    FEntries[AIndex].Tile.Stroke.Color := TILE_SELECTED_STROKE;
    FEntries[AIndex].Tile.Stroke.Thickness := 2;
  end;
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
end;

procedure TAssetsForm.FreeModel;
begin
  if FModel = nil then
    Exit;
  FModel.Parent := nil;
  FreeAndNil(FModel);
end;

procedure TAssetsForm.StopMaking;
begin
  if FOffscreen <> nil then
    FOffscreen.Cancel;
  FQueue := nil;
  FMaking := -1;
  FreeModel;
end;

procedure TAssetsForm.MakeNextLater;
var
  Alive: IAssetsAlive;
begin
  Alive := FAlive;
  TThread.ForceQueue(nil,
    procedure
    begin
      if Alive.Alive then
        MakeNext;
    end);
end;

procedure TAssetsForm.MakeNext;
var
  Index: Integer;
  Box: TBoundingBox;
begin
  FMaking := -1;
  FreeModel;
  if Length(FQueue) = 0 then
  begin
    Progress.Value := Progress.Max;
    StatusLabel.Text := Format('%d models', [Length(FEntries)]);
    if FQueueTotal > 0 then
      Log(Format('Assets: %d thumbnails made', [FQueueTotal]));
    FQueueTotal := 0;
    Exit;
  end;
  Index := FQueue[0];
  Delete(FQueue, 0, 1);
  Progress.Max := Max(1, FQueueTotal);
  Progress.Value := FQueueTotal - Length(FQueue) - 1;
  StatusLabel.Text := Format('Making thumbnails: %d of %d, %s', [FQueueTotal -
    Length(FQueue), FQueueTotal, FEntries[Index].Meta.Name]);

  // Loaded as the builder will load it: upright, as each model was in
  // Sprite3D, since FMX's Y points down
  FModel := TGorillaModel.Create(FViewport);
  try
    FModel.Parent := FViewport;
    LoadModelFile(FModel, FEntries[Index].Meta.FileName, Box);
    FModel.RotationAngle.X := 180;
    FModel.ResetToBindPose();
  except
    on E: Exception do
    begin
      Log('Assets: can''t load ' + FEntries[Index].Meta.FileName + ': ' + E.Message);
      FreeModel;
      MakeNextLater;
      Exit;
    end;
  end;
  FModelBox := Box;
  FEntries[Index].Meta.BoxMin := Box.TopLeftNear;
  FEntries[Index].Meta.BoxMax := Box.BottomRightFar;
  // On screen too, so the viewport shows it as the thumbnail will
  FrameModel(FViewport.Width, FViewport.Height);
  FMaking := Index;
  if not FOffscreen.Grab(GrabDone(Index, FScanId)) then
  begin
    Log('Assets: can''t start the thumbnail of ' + FEntries[Index].Meta.Name);
    FMaking := -1;
    FreeModel;
    MakeNextLater;
  end;
end;

procedure TAssetsForm.FrameModel(const AWidth, AHeight: Single);
var
  Pivot: TPoint3D;
  HalfX, HalfZ: Single;
  Box: TBoundingBox;
begin
  if (FModel = nil) or (AWidth <= 0) or (AHeight <= 0) then
    Exit;
  Pivot := FModel.RotationCenter.Point;
  HalfX := Max(Abs(FModelBox.Left - Pivot.X), Abs(FModelBox.Right - Pivot.X));
  HalfZ := Max(Abs(FModelBox.Near - Pivot.Z), Abs(FModelBox.Far - Pivot.Z));
  Box := TBoundingBox.Create(Point3D(Pivot.X - HalfX, FModelBox.Top, Pivot.Z - HalfZ),
    Point3D(Pivot.X + HalfX, FModelBox.Bottom, Pivot.Z + HalfZ));
  // The box is in the model's own space, so the model is its space and
  // the upright turn is applied once
  FCamera.Camera.FitToBounds(Box, FModel, AWidth, AHeight, THUMBNAIL_MARGIN);
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
  if ABitmap = nil then
    Log('Assets: no thumbnail for ' + FEntries[AIndex].Meta.Name + ': ' + AError)
  else
    try
      ForceDirectories(FCacheFolder);
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

end.
