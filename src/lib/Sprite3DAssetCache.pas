//** @abstract(A cache of model thumbnails and metadata, keyed by a hash of each model's content.)
//**
//** Every model gets a key: a SHA-256 of its file and of every file it names, so identical
//** copies in different folders share one key, and any change to the model, its buffers or
//** its textures gives a new one. TSprite3DAssetHasher works the key out. For a glTF file
//** (@code(.gltf)) the files named are the @code(uri) of each of its @code(buffers) and
//** @code(images) that is not a @code(data:) URI, relative to the model's folder, in the
//** order the file gives them; their names and contents both count. For every other format
//** only the file itself counts.
//**
//** The cache is a folder holding, for each key, @code(<key>.png), the thumbnail, and
//** @code(<key>.json), the model's metadata as a TSprite3DAssetMeta: its name, group, the
//** file it was first seen as, the files it names, its bounding box in its own units, and
//** how the thumbnail was made. SaveAssetMeta writes the metadata, through a temporary file,
//** so a crash never leaves half of one; LoadAssetMeta reads it back, checking every value,
//** so a damaged or older file only means the thumbnail is made again.
//**
//** The unit knows nothing of the application. TSprite3DAssetHasher only reads files, so it
//** may run on a worker thread, one hasher to a thread; the rest is for any thread that does
//** not share the record it works on.
//**
//** @preformatted(
//** <cache folder>
//** |-- <key>.png    the thumbnail
//** `-- <key>.json   TSprite3DAssetMeta
//** )
unit Sprite3DAssetCache;

{
  A cache of model thumbnails and metadata, keyed by a hash of each model's
  content.

  Every model gets a key: a SHA-256 of its file and of every file it names,
  so identical copies in different folders share one key, and any change to
  the model, its buffers or its textures gives a new one.
  TSprite3DAssetHasher works the key out. For a glTF file (.gltf) the files
  named are the uri of each of its buffers and images that is not a data:
  URI, relative to the model's folder, in the order the file gives them;
  their names and contents both count. For every other format only the file
  itself counts.

  The cache is a folder holding, for each key, <key>.png, the thumbnail, and
  <key>.json, the model's metadata as a TSprite3DAssetMeta: its name, group,
  the file it was first seen as, the files it names, its bounding box in its
  own units, and how the thumbnail was made. SaveAssetMeta writes the
  metadata, through a temporary file, so a crash never leaves half of one;
  LoadAssetMeta reads it back, checking every value, so a damaged or older
  file only means the thumbnail is made again.

  The unit knows nothing of the application. TSprite3DAssetHasher only reads
  files, so it may run on a worker thread, one hasher to a thread; the rest
  is for any thread that does not share the record it works on.

    <cache folder>
    |-- <key>.png    the thumbnail
    `-- <key>.json   TSprite3DAssetMeta
}

interface

uses
  System.SysUtils, System.Types, System.Math.Vectors, System.Generics.Collections;

const
  //** @abstract(The @code(format) written in, and looked for in, every metadata file.)
  ASSET_META_FORMAT = 'Sprite3D asset';
  //** @abstract(The metadata files' version: one of another version is not read.)
  ASSET_META_VERSION = 1;

type
  //** @abstract(What the cache keeps about one model.)
  TSprite3DAssetMeta = record
    //** @abstract(The model's key: the SHA-256 of its content, as 64 lower-case hex digits.)
    Hash: String;
    //** @abstract(The model's name: its file's name without the extension.)
    Name: String;
    //** @abstract(The group the caller put it in, such as the first word of its name.)
    Group: String;
    //** @abstract(The model's file, as a full path: where it was when its thumbnail was made,
    //** or, once read back, where the caller found it this time.)
    FileName: String;
    //** @abstract(The files the model names, as it names them, relative to its folder.)
    Files: TArray<String>;
    //** @abstract(The low corner of its bounding box, in its own coordinates and units.)
    BoxMin: TPoint3D;
    //** @abstract(The high corner of its bounding box, in its own coordinates and units.)
    BoxMax: TPoint3D;
    //** @abstract(The thumbnail's width in pixels.)
    ThumbWidth: Integer;
    //** @abstract(The thumbnail's height in pixels.)
    ThumbHeight: Integer;
    //** @abstract(How the thumbnail was drawn, such as @code(isometric orthographic).)
    View: String;
    //** @abstract(When the thumbnail was made, as ISO 8601 text.)
    Created: String;
    //** @abstract(The bounding box's size: BoxMax less BoxMin.)
    //**
    //** @returns(Width, height and depth, in the model's own units.)
    function Size: TPoint3D;
  end;

  //** @abstract(Works out models' keys; see the unit's description.)
  //**
  //** A file several models name, such as a texture they share, is hashed once per hasher:
  //** its digest is kept, by full path, for the next model that names it. Use one hasher for
  //** one scan of a folder, on one thread.
  TSprite3DAssetHasher = class
  private
    //** @abstract(The digest of each file named so far, by its full path in upper case.)
    FDigests: TDictionary<String, TBytes>;
    //** @abstract(The SHA-256 of AFileName's content, from FDigests if it is there.)
    //**
    //** @param(AFileName A full path.)
    //**
    //** @returns(The 32-byte digest.)
    function FileDigest(const AFileName: String): TBytes;
  public
    //** @abstract(Creates a hasher with nothing remembered.)
    constructor Create;
    //** @abstract(Frees the hasher and the digests it kept.)
    destructor Destroy; override;
    //** @abstract(The key of the model in AFileName.)
    //**
    //** @param(AFileName The model file.)
    //**
    //** @param(AFiles On return, the files it names, as it names them; empty but for glTF.)
    //**
    //** @param(AError On return, why there is no key; empty if there is one. A file it names
    //** that is missing is not an error: it counts by its name alone, so the key changes when
    //** it appears.)
    //**
    //** @returns(The key, 64 lower-case hex digits; empty if AFileName cannot be read.)
    function HashModel(const AFileName: String; out AFiles: TArray<String>;
      out AError: String): String;
  end;

//** @abstract(The metadata file of key AHash in the cache folder ACacheFolder.)
//**
//** @param(ACacheFolder The cache folder.)
//**
//** @param(AHash A model's key.)
//**
//** @returns(The file's full path, @code(<AHash>.json); it need not exist.)
function AssetMetaFile(const ACacheFolder, AHash: String): String;

//** @abstract(The thumbnail file of key AHash in the cache folder ACacheFolder.)
//**
//** @param(ACacheFolder The cache folder.)
//**
//** @param(AHash A model's key.)
//**
//** @returns(The file's full path, @code(<AHash>.png); it need not exist.)
function AssetThumbnailFile(const ACacheFolder, AHash: String): String;

//** @abstract(Writes AMeta to its metadata file in ACacheFolder, making the folder if need be.)
//**
//** Written to a temporary file first, then moved into place.
//**
//** @param(ACacheFolder The cache folder.)
//**
//** @param(AMeta The metadata; its Hash names the file.)
//**
//** @raises(Exception If the folder cannot be made or the file written.)
procedure SaveAssetMeta(const ACacheFolder: String; const AMeta: TSprite3DAssetMeta);

//** @abstract(Reads the metadata of key AHash from ACacheFolder.)
//**
//** @param(ACacheFolder The cache folder.)
//**
//** @param(AHash The model's key.)
//**
//** @param(AMeta On return, the metadata when True.)
//**
//** @returns(True if the file is there, of ASSET_META_FORMAT and ASSET_META_VERSION, for
//** AHash, and every value has the right type; False otherwise, never an exception.)
function LoadAssetMeta(const ACacheFolder, AHash: String;
  out AMeta: TSprite3DAssetMeta): Boolean;

implementation

uses
  System.IOUtils, System.Hash, System.JSON, System.NetEncoding, OSPaths,
  JsonText;

function TSprite3DAssetMeta.Size: TPoint3D;
begin
  Result := BoxMax - BoxMin;
end;

{ TSprite3DAssetHasher }

constructor TSprite3DAssetHasher.Create;
begin
  inherited Create;
  FDigests := TDictionary<String, TBytes>.Create;
end;

destructor TSprite3DAssetHasher.Destroy;
begin
  FDigests.Free;
  inherited;
end;

function TSprite3DAssetHasher.FileDigest(const AFileName: String): TBytes;
var
  Key: String;
begin
  Key := UpperCase(AFileName);
  if FDigests.TryGetValue(Key, Result) then
    Exit;
  Result := THashSHA2.GetHashBytesFromFile(AFileName, THashSHA2.TSHA2Version.SHA256);
  FDigests.Add(Key, Result);
end;

// The uri of every element of AArray, an array of objects, that names a file
function NamedFiles(const AArray: TJSONValue): TArray<String>;
var
  Uri: String;
begin
  Result := nil;
  if not (AArray is TJSONArray) then
    Exit;
  for var Item in TJSONArray(AArray) do
    if (Item is TJSONObject) and TJSONObject(Item).TryGetValue<String>('uri', Uri) and
      (Uri <> String.Empty) and not Uri.StartsWith('data:', True) then
      Result := Result + [Uri];
end;

function TSprite3DAssetHasher.HashModel(const AFileName: String;
  out AFiles: TArray<String>; out AError: String): String;
var
  FileName, Folder, Named: String;
  Bytes: TBytes;
  Hash: THashSHA2;
  Root: TJSONValue;
begin
  Result := String.Empty;
  AFiles := nil;
  AError := String.Empty;
  FileName := OSFriendlyPath(AFileName);
  try
    Bytes := TFile.ReadAllBytes(FileName);
  except
    on E: Exception do
    begin
      AError := E.Message;
      Exit;
    end;
  end;
  Hash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
  Hash.Update(Bytes);
  if SameText(ExtractFileExt(FileName), '.gltf') then
  begin
    // A glTF that is not JSON is the loader's to report; here it is only
    // its own bytes
    Root := nil;
    try
      Root := TJSONObject.ParseJSONValue(Bytes, 0);
    except
      Root := nil;
    end;
    try
      if Root is TJSONObject then
        AFiles := NamedFiles(TJSONObject(Root).GetValue('buffers')) +
          NamedFiles(TJSONObject(Root).GetValue('images'));
    finally
      Root.Free;
    end;
    Folder := ExtractFilePath(FileName);
    for var Uri in AFiles do
    begin
      // The name counts, so a model naming another file is another model;
      // then the content, if the file is there
      Hash.Update(TEncoding.UTF8.GetBytes(Uri + #0));
      Named := OSFriendlyPath(TPath.Combine(Folder, TNetEncoding.URL.Decode(Uri)));
      if TFile.Exists(Named) then
        try
          Hash.Update(FileDigest(ExpandFileName(Named)));
        except
          // Unreadable now: it counts by its name, as a missing one does
        end;
    end;
  end;
  Result := LowerCase(Hash.HashAsString);
end;

{ The cache folder }

function AssetMetaFile(const ACacheFolder, AHash: String): String;
begin
  Result := OSFriendlyPath(TPath.Combine(ACacheFolder, AHash + '.json'));
end;

function AssetThumbnailFile(const ACacheFolder, AHash: String): String;
begin
  Result := OSFriendlyPath(TPath.Combine(ACacheFolder, AHash + '.png'));
end;

// A point as a JSON array of three numbers
function PointToJson(const APoint: TPoint3D): TJSONArray;
begin
  Result := TJSONArray.Create;
  Result.Add(APoint.X);
  Result.Add(APoint.Y);
  Result.Add(APoint.Z);
end;

// A JSON array of three numbers as a point; False for anything else
function JsonToPoint(const AValue: TJSONValue; out APoint: TPoint3D): Boolean;
var
  Items: TJSONArray;
begin
  Result := False;
  if not (AValue is TJSONArray) then
    Exit;
  Items := TJSONArray(AValue);
  if Items.Count <> 3 then
    Exit;
  for var I := 0 to 2 do
    if not (Items.Items[I] is TJSONNumber) then
      Exit;
  APoint := Point3D(TJSONNumber(Items.Items[0]).AsDouble,
    TJSONNumber(Items.Items[1]).AsDouble, TJSONNumber(Items.Items[2]).AsDouble);
  Result := True;
end;

procedure SaveAssetMeta(const ACacheFolder: String; const AMeta: TSprite3DAssetMeta);
var
  Root, Box, Thumb: TJSONObject;
  Files: TJSONArray;
  Target, Temp: String;
begin
  Root := TJSONObject.Create;
  try
    Root.AddPair('format', ASSET_META_FORMAT);
    Root.AddPair('version', TJSONNumber.Create(ASSET_META_VERSION));
    Root.AddPair('hash', AMeta.Hash);
    Root.AddPair('name', AMeta.Name);
    Root.AddPair('group', AMeta.Group);
    Root.AddPair('file', AMeta.FileName);
    Files := TJSONArray.Create;
    for var Named in AMeta.Files do
      Files.Add(Named);
    Root.AddPair('files', Files);
    Box := TJSONObject.Create;
    Box.AddPair('min', PointToJson(AMeta.BoxMin));
    Box.AddPair('max', PointToJson(AMeta.BoxMax));
    Box.AddPair('size', PointToJson(AMeta.Size));
    Root.AddPair('bounds', Box);
    Thumb := TJSONObject.Create;
    Thumb.AddPair('width', TJSONNumber.Create(AMeta.ThumbWidth));
    Thumb.AddPair('height', TJSONNumber.Create(AMeta.ThumbHeight));
    Thumb.AddPair('view', AMeta.View);
    Thumb.AddPair('created', AMeta.Created);
    Root.AddPair('thumbnail', Thumb);

    ForceDirectories(OSFriendlyPath(ACacheFolder));
    Target := AssetMetaFile(ACacheFolder, AMeta.Hash);
    Temp := Target + '.tmp';
    TFile.WriteAllBytes(Temp, JsonToBytes(Root));
    if TFile.Exists(Target) then
      TFile.Delete(Target);
    TFile.Move(Temp, Target);
  finally
    Root.Free;
  end;
end;

function LoadAssetMeta(const ACacheFolder, AHash: String;
  out AMeta: TSprite3DAssetMeta): Boolean;
var
  FileName, Text: String;
  Root: TJSONValue;
  Obj, Box, Thumb: TJSONObject;
  Version, Width, Height: Integer;
  Files: TJSONArray;
begin
  Result := False;
  AMeta := Default(TSprite3DAssetMeta);
  FileName := AssetMetaFile(ACacheFolder, AHash);
  if not TFile.Exists(FileName) then
    Exit;
  Root := nil;
  try
    try
      Root := TJSONObject.ParseJSONValue(TFile.ReadAllBytes(FileName), 0);
      if not (Root is TJSONObject) then
        Exit;
      Obj := TJSONObject(Root);
      if not Obj.TryGetValue<String>('format', Text) or (Text <> ASSET_META_FORMAT) then
        Exit;
      if not Obj.TryGetValue<Integer>('version', Version) or
        (Version <> ASSET_META_VERSION) then
        Exit;
      if not Obj.TryGetValue<String>('hash', AMeta.Hash) or
        not SameText(AMeta.Hash, AHash) then
        Exit;
      if not Obj.TryGetValue<String>('name', AMeta.Name) or
        not Obj.TryGetValue<String>('group', AMeta.Group) or
        not Obj.TryGetValue<String>('file', AMeta.FileName) then
        Exit;
      if Obj.TryGetValue<TJSONArray>('files', Files) then
        for var Item in Files do
          if Item is TJSONString then
            AMeta.Files := AMeta.Files + [TJSONString(Item).Value]
          else
            Exit;
      if not Obj.TryGetValue<TJSONObject>('bounds', Box) or
        not JsonToPoint(Box.GetValue('min'), AMeta.BoxMin) or
        not JsonToPoint(Box.GetValue('max'), AMeta.BoxMax) then
        Exit;
      if not Obj.TryGetValue<TJSONObject>('thumbnail', Thumb) or
        not Thumb.TryGetValue<Integer>('width', Width) or
        not Thumb.TryGetValue<Integer>('height', Height) or
        (Width <= 0) or (Height <= 0) then
        Exit;
      AMeta.ThumbWidth := Width;
      AMeta.ThumbHeight := Height;
      Thumb.TryGetValue<String>('view', AMeta.View);
      Thumb.TryGetValue<String>('created', AMeta.Created);
      Result := True;
    except
      // A damaged file: as if there were none
      Result := False;
    end;
  finally
    Root.Free;
    if not Result then
      AMeta := Default(TSprite3DAssetMeta);
  end;
end;

end.
