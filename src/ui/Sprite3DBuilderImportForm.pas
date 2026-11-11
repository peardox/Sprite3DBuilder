//** @abstract(Choose Folders to Import: which of the folders found under a collection's folder
//** to take its models from, when there are several.)
//**
//** A model pack often holds the same models in several formats, each in its own folder, and
//** sometimes a second copy of a format for one engine; taking them all would give each model
//** two, three or four times. ChooseModelFolders lists every folder FindModelFolders found,
//** with its format and how many models it holds, each with a box to tick. The preferred
//** format, a drop-down of the formats found, ticks the folders of that format, less any that
//** hold the same models as one already ticked (DefaultModelFolders); the boxes can then be
//** changed freely. OK needs at least one ticked.
//**
//** An artist import asks it only when a pack has more than one folder of the format chosen,
//** listing those alone, with an introduction naming the pack, Skip in place of Cancel, and
//** only the folder with the most models ticked to start with: a pack can hold sample
//** projects with models of their own, which name textures kept elsewhere.
//**
//** Modal; desktop only, as the folder dialogs that lead to it are. For the main thread only.
unit Sprite3DBuilderImportForm;

{
  Choose Folders to Import: which of the folders found under a collection's
  folder to take its models from, when there are several.

  A model pack often holds the same models in several formats, each in its
  own folder, and sometimes a second copy of a format for one engine.
  ChooseModelFolders lists every folder found, with its format and how many
  models it holds, each with a box to tick. The preferred format ticks the
  folders of that format, less any holding the same models as one already
  ticked; the boxes can then be changed freely. OK needs one ticked.

  Modal; desktop only. Main thread only.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Layouts, FMX.ListBox,
  FMX.Controls.Presentation, Sprite3DBuilderHelpers;

type
  //** @abstract(The Choose Folders to Import dialog; see the unit description.)
  TImportForm = class(TForm)
    //** @abstract(The form's opaque background.)
    BackPanel: TPanel;
    //** @abstract(Says what was found and what to choose.)
    InfoLabel: TLabel;
    //** @abstract(The strip holding FormatLabel and FormatCombo.)
    FormatLayout: TLayout;
    //** @abstract(Says "Preferred format".)
    FormatLabel: TLabel;
    //** @abstract(The formats found, best first; choosing one ticks its folders.)
    FormatCombo: TComboBox;
    //** @abstract(The folders found, each with a box to tick.)
    FolderList: TListBox;
    //** @abstract(The strip holding the OK and Cancel buttons.)
    ButtonLayout: TLayout;
    //** @abstract(Takes the folders ticked.)
    OKButton: TButton;
    //** @abstract(Takes none.)
    CancelButton: TButton;
    //** @abstract(Ticks the folders of the format chosen.)
    //**
    //** @param(Sender FormatCombo.)
    procedure FormatComboChange(Sender: TObject);
    //** @abstract(Enables OK while at least one folder is ticked.)
    //**
    //** @param(Sender FolderList.)
    procedure FolderListChangeCheck(Sender: TObject);
  private
    //** @abstract(The folders listed, in FolderList's order.)
    FFolders: TArray<TModelFolder>;
    //** @abstract(The formats in FormatCombo, in its order.)
    FFormats: TArray<String>;
    //** @abstract(True while the boxes are being ticked in code.)
    FTicking: Boolean;
    //** @abstract(True to tick only the folder with the most models of those
    //** DefaultModelFolders takes.)
    FTickLargest: Boolean;
    //** @abstract(Ticks the folders DefaultModelFolders takes for format AFormat, or, with
    //** FTickLargest, the one of them with the most models.)
    //**
    //** @param(AFormat The format.)
    procedure TickFormat(const AFormat: String);
    //** @abstract(Enables OK if any folder is ticked.)
    procedure UpdateOK;
  end;

//** @abstract(Asks which of AFolders to take models from, unless there is only one.)
//**
//** With one folder, it is taken without asking. With none, nothing is.
//**
//** @param(ARoots The folders the user chose, to show the others relative to.)
//**
//** @param(AFolders The folders found under them, from FindModelFolders.)
//**
//** @param(APreferred The format the user prefers; on OK, the one chosen in the dialog.)
//**
//** @param(AChosen On return, the folders to take.)
//**
//** @param(AIntro What the dialog says at the top; empty for the usual words.)
//**
//** @param(ATickLargest True to tick only the folder with the most models to start with.)
//**
//** @param(ACancelText The Cancel button's text; empty for Cancel.)
//**
//** @returns(True if there are folders to take; False if there were none, or Cancel.)
function ChooseModelFolders(const ARoots: TArray<String>;
  const AFolders: TArray<TModelFolder>; var APreferred: String;
  out AChosen: TArray<TModelFolder>; const AIntro: String = '';
  const ATickLargest: Boolean = False; const ACancelText: String = ''): Boolean;

implementation

uses
  System.StrUtils;

{$R *.fmx}

//** @abstract(AFolder relative to the first of ARoots it is in, or as it is.)
//**
//** @param(ARoots The roots.)
//**
//** @param(AFolder The folder.)
//**
//** @returns(The path to show.)
function ShownPath(const ARoots: TArray<String>; const AFolder: String): String;
var
  Root: String;
begin
  for var Each in ARoots do
  begin
    Root := IncludeTrailingPathDelimiter(Each);
    if SameText(IncludeTrailingPathDelimiter(AFolder), Root) then
      Exit(ExtractFileName(ExcludeTrailingPathDelimiter(Each)));
    if StartsText(Root, AFolder) then
      Exit(ExtractFileName(ExcludeTrailingPathDelimiter(Each)) + PathDelim +
        AFolder.Substring(Length(Root)));
  end;
  Result := AFolder;
end;

function ChooseModelFolders(const ARoots: TArray<String>;
  const AFolders: TArray<TModelFolder>; var APreferred: String;
  out AChosen: TArray<TModelFolder>; const AIntro: String; const ATickLargest: Boolean;
  const ACancelText: String): Boolean;
var
  Dialog: TImportForm;
  Item: TListBoxItem;
  Chosen: Integer;
begin
  AChosen := nil;
  if Length(AFolders) = 0 then
    Exit(False);
  if Length(AFolders) = 1 then
  begin
    AChosen := AFolders;
    Exit(True);
  end;
  Dialog := TImportForm.Create(nil);
  try
    Dialog.FFolders := AFolders;
    Dialog.FFormats := FoundModelFormats(AFolders);
    Dialog.FTickLargest := ATickLargest;
    if AIntro <> String.Empty then
      Dialog.InfoLabel.Text := AIntro
    else
      Dialog.InfoLabel.Text := Format('Models were found in %d places under %s. A pack ' +
        'often has the same models in several formats, each in its own folder: tick the ' +
        'ones to take, usually one format only.', [Length(AFolders),
        String.Join(', ', ARoots)]);
    if ACancelText <> String.Empty then
      Dialog.CancelButton.Text := ACancelText;
    Dialog.FormatCombo.Clear;
    Chosen := 0;
    for var I := 0 to High(Dialog.FFormats) do
    begin
      Dialog.FormatCombo.Items.Add(ModelFormatName(Dialog.FFormats[I]) + ' (' +
        Dialog.FFormats[I] + ')');
      if SameText(Dialog.FFormats[I], APreferred) then
        Chosen := I;
    end;
    Dialog.FolderList.Clear;
    for var Folder in AFolders do
    begin
      Item := TListBoxItem.Create(Dialog.FolderList);
      Item.Parent := Dialog.FolderList;
      Item.Text := Format('%s   -   %d %s', [ShownPath(ARoots, Folder.Folder), Folder.Count,
        ModelFormatName(Folder.Format)]);
      Item.Hint := Folder.Folder;
      Item.ShowHint := True;
    end;
    Dialog.FTicking := True;
    Dialog.FormatCombo.ItemIndex := Chosen;
    Dialog.FTicking := False;
    if Length(Dialog.FFormats) > 0 then
      Dialog.TickFormat(Dialog.FFormats[Chosen]);
    Result := Dialog.ShowModal = mrOk;
    if not Result then
      Exit;
    for var I := 0 to High(AFolders) do
      if Dialog.FolderList.ListItems[I].IsChecked then
        AChosen := AChosen + [AFolders[I]];
    if (Dialog.FormatCombo.ItemIndex >= 0) and
      (Dialog.FormatCombo.ItemIndex <= High(Dialog.FFormats)) then
      APreferred := Dialog.FFormats[Dialog.FormatCombo.ItemIndex];
    Result := Length(AChosen) > 0;
  finally
    Dialog.Free;
  end;
end;

{ TImportForm }

procedure TImportForm.TickFormat(const AFormat: String);
var
  Ticks: TArray<Boolean>;
  Largest: Integer;
begin
  Ticks := DefaultModelFolders(FFolders, AFormat);
  // Only the biggest of them, when asked: the likeliest to be the pack itself
  if FTickLargest then
  begin
    Largest := -1;
    for var I := 0 to High(Ticks) do
      if Ticks[I] and ((Largest < 0) or (FFolders[I].Count > FFolders[Largest].Count)) then
        Largest := I;
    for var I := 0 to High(Ticks) do
      Ticks[I] := I = Largest;
  end;
  FTicking := True;
  try
    for var I := 0 to FolderList.Count - 1 do
      FolderList.ListItems[I].IsChecked := (I <= High(Ticks)) and Ticks[I];
  finally
    FTicking := False;
  end;
  UpdateOK;
end;

procedure TImportForm.UpdateOK;
var
  Any: Boolean;
begin
  Any := False;
  for var I := 0 to FolderList.Count - 1 do
    if FolderList.ListItems[I].IsChecked then
      Any := True;
  OKButton.Enabled := Any;
end;

procedure TImportForm.FormatComboChange(Sender: TObject);
begin
  if FTicking or (FormatCombo.ItemIndex < 0) or (FormatCombo.ItemIndex > High(FFormats)) then
    Exit;
  TickFormat(FFormats[FormatCombo.ItemIndex]);
end;

procedure TImportForm.FolderListChangeCheck(Sender: TObject);
begin
  if not FTicking then
    UpdateOK;
end;

end.
