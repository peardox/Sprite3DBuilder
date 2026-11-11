//** @abstract(Sprite3DBuilder: a level builder for 3D model kits, grown from Sprite3D.)
//**
//** The program starts with an empty level: a floor grid in a Gorilla3D viewport, framed by
//** the Spritely package's orbital camera, @code(TSpritelyOrbitalCamera). File, Library opens
//** TAssetsForm, the user's collections of models to build from, shown as thumbnails, cached
//** by a hash of each model. TMainForm, in Sprite3DBuilderMain, holds the
//** view and every command. On Windows FastMM5 is the memory
//** manager, and with REPORT_LEAKS defined it writes every leak still allocated at shut-down,
//** in full, to Sprite3DBuilder_MemoryManager_EventLog.txt beside the executable. Builds for
//** Windows, macOS, Linux, Android and iOS.
//**
//** @preformatted(
//** ui/      the forms and the settings kept between sessions
//** lib/     the grid, volumes, off-screen grabs, asset cache, settings and platform helpers
//** common/  display information, GPU preference and system folder helpers
//** )
program Sprite3DBuilder;
// {$DEFINE REPORT_LEAKS}
{
  Sprite3DBuilder: a level builder for 3D model kits, grown from Sprite3D.

  The program starts with an empty level: a floor grid in a Gorilla3D
  viewport, framed by the Spritely package's orbital camera,
  TSpritelyOrbitalCamera. File, Library opens TAssetsForm, the user's
  collections of models to build from, shown as thumbnails, cached by a
  hash of each model. TMainForm, in Sprite3DBuilderMain, holds
  the view and every command. On Windows FastMM5 is the memory manager, and with
  REPORT_LEAKS defined it writes every leak still allocated at shut-down, in
  full, to Sprite3DBuilder_MemoryManager_EventLog.txt beside the executable.
  Builds for Windows, macOS, Linux, Android and iOS.

    ui/      the forms and the settings kept between sessions
    lib/     the grid, volumes, off-screen grabs, asset cache, settings and platform helpers
    common/  display information, GPU preference and system folder helpers
}

uses
  // On Windows FastMM5 is the memory manager, so it must come first; it
  // writes the full leak report to a file beside the executable
  {$IFDEF MSWINDOWS}
  FastMM5,
  {$ENDIF}
  System.StartUpCopy,
  FMX.Forms,
  Sprite3DBuilderMain in 'ui\Sprite3DBuilderMain.pas' {MainForm},
  Sprite3DBuilderHelpers in 'ui\Sprite3DBuilderHelpers.pas',
  Sprite3DGrid in 'lib\Sprite3DGrid.pas',
  Sprite3DAnimFrames in 'lib\Sprite3DAnimFrames.pas',
  Sprite3DSweep in 'lib\Sprite3DSweep.pas',
  Sprite3DStorage in 'lib\Sprite3DStorage.pas',
  Sprite3DBuilderOrbitalForm in 'ui\Sprite3DBuilderOrbitalForm.pas' {OrbitalSettingsForm},
  OSPaths in 'common\OSPaths.pas',
  JsonText in 'common\JsonText.pas',
  GpuPreference in 'common\GpuPreference.pas',
  DisplayData in 'common\DisplayData.pas',
  Sprite3DStyles in 'lib\Sprite3DStyles.pas',
  Sprite3DTitleBar in 'lib\Sprite3DTitleBar.pas',
  Sprite3DBuilderSettingsForm in 'ui\Sprite3DBuilderSettingsForm.pas' {GeneralSettingsForm},
  Sprite3DLicences in 'lib\Sprite3DLicences.pas',
  Sprite3DFolderDialog in 'lib\Sprite3DFolderDialog.pas',
  Sprite3DBackground in 'lib\Sprite3DBackground.pas',
  Sprite3DResample in 'lib\Sprite3DResample.pas',
  Sprite3DOffscreen in 'lib\Sprite3DOffscreen.pas',
  Sprite3DAssetCache in 'lib\Sprite3DAssetCache.pas',
  Sprite3DGroupIcons in 'lib\Sprite3DGroupIcons.pas',
  Sprite3DBuilderImportForm in 'ui\Sprite3DBuilderImportForm.pas' {ImportForm},
  Sprite3DBuilderFormatForm in 'ui\Sprite3DBuilderFormatForm.pas' {FormatForm},
  Sprite3DBuilderAssetsForm in 'ui\Sprite3DBuilderAssetsForm.pas' {AssetsForm},
  Sprite3DBuilderLicencesForm in 'ui\Sprite3DBuilderLicencesForm.pas' {LicencesForm};

{$R *.res}
// The themes' FMX styles, inside the program on every platform. The .res
// is built by styles\buildstyles.cmd in the pre-build event; see
// styles\Sprite3DThemes.rc
{$R 'styles\Sprite3DThemes.res'}
// The third-party licences and notices, from licences\Sprite3DLicences.rc,
// which the pre-build step compiles; File, Licences shows them
{$R '..\licences\Sprite3DLicences.res'}

begin
  {$IF DEFINED(MSWINDOWS)}
  // FastMM5 also writes every leak, in full, to
  // Sprite3DBuilder_MemoryManager_EventLog.txt in the executable's folder,
  // its default place, so no path is given. It adds to that file each run,
  // so the last run's is deleted first, leaving this run's leaks alone in it.
  {$IF DEFINED(REPORT_LEAKS)}
  FastMM_DeleteEventLogFile;
  FastMM_LogToFileEvents := FastMM_LogToFileEvents +
    [mmetUnexpectedMemoryLeakSummary, mmetUnexpectedMemoryLeakDetail];
  {$ENDIF}
  {$ENDIF}

  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TOrbitalSettingsForm, OrbitalSettingsForm);
  Application.Run;
end.
