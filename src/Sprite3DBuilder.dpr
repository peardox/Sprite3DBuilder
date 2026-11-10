//** @abstract(Sprite3DBuilder: a level builder for 3D model kits, grown from Sprite3D.)
//**
//** The program loads glTF, FBX, OBJ, USD, Collada, STL or PLY models into a Gorilla3D
//** viewport, each in its rest pose, on an ever-present floor grid, and frames them with the
//** Spritely package's orbital camera, @code(TSpritelyOrbitalCamera). TMainForm, in
//** Sprite3DBuilderMain, holds the view and every command. On Windows FastMM5 is the memory
//** manager, and with REPORT_LEAKS defined it writes every leak still allocated at shut-down,
//** in full, to Sprite3DBuilder_MemoryManager_EventLog.txt beside the executable. Builds for
//** Windows, macOS, Linux, Android and iOS. On Windows a copy started while another is
//** running hands its files to that one and ends; see HandOffToRunningInstance.
//**
//** @preformatted(
//** ui/      the forms and the settings kept between sessions
//** lib/     the grid, axes, swept volumes, settings storage and platform helpers
//** common/  display information, GPU preference and system folder helpers
//** )
program Sprite3DBuilder;
// {$DEFINE REPORT_LEAKS}
{
  Sprite3DBuilder: a level builder for 3D model kits, grown from Sprite3D.

  The program loads glTF, FBX, OBJ, USD, Collada, STL or PLY models into a
  Gorilla3D viewport, each in its rest pose, on an ever-present floor grid,
  and frames them with the Spritely package's orbital camera,
  TSpritelyOrbitalCamera. TMainForm, in Sprite3DBuilderMain, holds the view
  and every command. On Windows FastMM5 is the memory manager, and with
  REPORT_LEAKS defined it writes every leak still allocated at shut-down, in
  full, to Sprite3DBuilder_MemoryManager_EventLog.txt beside the executable.
  Builds for Windows, macOS, Linux, Android and iOS. On Windows a copy
  started while another is running hands its files to that one and ends;
  see HandOffToRunningInstance.

    ui/      the forms and the settings kept between sessions
    lib/     the grid, axes, swept volumes, settings storage and platform helpers
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
  Sprite3DAxes in 'lib\Sprite3DAxes.pas',
  Sprite3DGrid in 'lib\Sprite3DGrid.pas',
  Sprite3DAnimFrames in 'lib\Sprite3DAnimFrames.pas',
  Sprite3DSweep in 'lib\Sprite3DSweep.pas',
  Sprite3DStorage in 'lib\Sprite3DStorage.pas',
  Sprite3DOpenFiles in 'lib\Sprite3DOpenFiles.pas',
  Sprite3DBuilderOrbitalForm in 'ui\Sprite3DBuilderOrbitalForm.pas' {OrbitalSettingsForm},
  OSPaths in 'common\OSPaths.pas',
  JsonText in 'common\JsonText.pas',
  GpuPreference in 'common\GpuPreference.pas',
  DisplayData in 'common\DisplayData.pas',
  Sprite3DStyles in 'lib\Sprite3DStyles.pas',
  Sprite3DTitleBar in 'lib\Sprite3DTitleBar.pas',
  Sprite3DBuilderSettingsForm in 'ui\Sprite3DBuilderSettingsForm.pas' {GeneralSettingsForm},
  Sprite3DBuilderAnimationsUsedForm in 'ui\Sprite3DBuilderAnimationsUsedForm.pas' {AnimationsUsedForm},
  Sprite3DBuilderLoadForm in 'ui\Sprite3DBuilderLoadForm.pas' {ModelLoadForm},
  Sprite3DBuilderNameClashForm in 'ui\Sprite3DBuilderNameClashForm.pas' {NameClashForm},
  Sprite3DLicences in 'lib\Sprite3DLicences.pas',
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
  // A model opened while Sprite3DBuilder is already running goes to the
  // copy running, which loads it, rather than opening a second window; this
  // copy then ends at once. See HandOffToRunningInstance.
  if HandOffToRunningInstance('Sprite3DBuilder') then
    Exit;

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
