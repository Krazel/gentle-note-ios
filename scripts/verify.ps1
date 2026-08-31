$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Failures = [System.Collections.Generic.List[string]]::new()

function Require-File([string]$RelativePath) {
    $Path = Join-Path $ProjectRoot $RelativePath
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $Failures.Add("Missing file: $RelativePath")
    }
}

$Required = @(
    'GentleNote.xcodeproj\project.pbxproj',
    'GentleNote.xcodeproj\xcshareddata\xcschemes\GentleNote.xcscheme',
    '.github\workflows\ios-verify.yml',
    'GentleNote\Info.plist',
    'GentleNote\Resources\PrivacyInfo.xcprivacy',
    'GentleNote\Resources\es.lproj\Localizable.strings',
    'GentleNote\Resources\es.lproj\InfoPlist.strings',
    'GentleNote\Core\Models.swift',
    'GentleNote\Core\SecureStore.swift',
    'GentleNote\Core\AppModel.swift',
    'GentleNote\Services\AuthenticationService.swift',
    'GentleNote\Services\MediaServices.swift',
    'GentleNote\Services\ExportService.swift',
    'GentleNote\Services\SupportStore.swift',
    'GentleNote\UI\DesignSystem.swift',
    'GentleNote\UI\OnboardingAndRoot.swift',
    'GentleNote\UI\JournalViews.swift',
    'GentleNote\UI\LibraryViews.swift',
    'GentleNote\UI\MealReflectionsViews.swift',
    'GentleNote\UI\SettingsViews.swift',
    'GentleNoteTests\GentleNoteTests.swift',
    'design\APPROVALS.md',
    'design\ASSETS.md',
    'docs\DATA-FLOW.md',
    'docs\IMPLEMENTATION.md',
    'docs\RELEASE-GATES.md'
)
$Required | ForEach-Object { Require-File $_ }

$Approved = Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'design\approved') -Filter 'ui-*.png'
if ($Approved.Count -ne 15) { $Failures.Add("Expected 15 approved UI boards; found $($Approved.Count)") }

$ExpectedHashes = @{
    'ui-01-onboarding-journal.png' = 'F94224325FB6A9977AF58CAAAE25DA82E10EE38DC489A106ECADFEF6EECCF5D0'
    'ui-02-journal-templates.png' = '23FFE05AABB29E22FE0538C673E9C39B41605900A9AC72CC353F354BBF76CB51'
    'ui-03-journal-history.png' = 'E645F69C42B70D732FB7DB703E35316F214034160096CA411ABD8C4E6592EE94'
    'ui-04-library-notes-organize.png' = '58580B82DF523B0CC40573B96D83246EC2884B27E32851CE46F83B0FB36BC698'
    'ui-05-video-audio-create.png' = '7F61B655D21496228A96850EAA2D42F49D107CBDEC8CFDDB01F12FB47C9ACDD1'
    'ui-06-media-search-errors.png' = '2A50800B3193D53014BFCF7CCCAD789FD19152EDC692D97A3BCA5F7CC882996F'
    'ui-07-settings-export.png' = 'B44BBADE22225DF56477D2364CAD8546A492A32E6E2F102FC959E2E3BD8F7AC6'
    'ui-08-lock-delete-help.png' = '69AFFF70B5B28324743F5B1C06C1096D80B5389ED7C4DBEF2F5F2B5BF29BD345'
    'ui-09-meal-reflections-creation-en.png' = 'D5E8275130EA36D979E766DF1CC7957CB7DBF3672E22E090F7587AC3C836D753'
    'ui-10-meal-reflections-review-en.png' = 'A08229FDA378184D438C57239E07633DCF612FFA503E3A064833BF58057D2092'
    'ui-11-meal-reflections-creation-es.png' = '1EE628BF165AACC4E80F12B7377325940EF7F1669C01011D1AC1E6EBFFE8C4C8'
    'ui-12-meal-reflections-review-es.png' = 'C80F099BDE4B2FBE0F7DED7520F679A0153319F9D1F100F4FF577047DCDB7C3B'
    'ui-13-meal-reflections-calendar-en.png' = '4CB081F0508F7535D294490491D50C358818E31A0F81F8CFE425389BCEF0DDE5'
    'ui-14-meal-reflections-calendar-es.png' = '5F1FEDD0ACA9A4A46E98C6C7B0F56BA19CD2C2BE1EE46F906E2931F589FDF0AF'
    'ui-15-first-run-overview-es.png' = '12D373601C4344C4735CC17BFA766A5D74024D389511771D7E73E09F7AA2BF5F'
}
foreach ($File in $Approved) {
    $Actual = (Get-FileHash -LiteralPath $File.FullName -Algorithm SHA256).Hash
    if ($ExpectedHashes[$File.Name] -ne $Actual) { $Failures.Add("Approval hash mismatch: $($File.Name)") }
}

$Info = Get-Content -LiteralPath (Join-Path $ProjectRoot 'GentleNote\Info.plist') -Raw
foreach ($Key in @('NSCameraUsageDescription','NSMicrophoneUsageDescription','NSFaceIDUsageDescription')) {
    if (-not $Info.Contains($Key)) { $Failures.Add("Missing permission purpose: $Key") }
}
if ($Info.Contains('NSPhotoLibraryUsageDescription')) { $Failures.Add('Photos permission must not be present in MVP') }

$Swift = Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'GentleNote') -Filter '*.swift' -Recurse |
    ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }
$AllSwift = $Swift -join "`n"
foreach ($RequiredText in @('Journal History','Record Video','Record Audio','Add Image','PhotosPicker','selectedTagID','migrateCollectionsToTags','PickedVideoFile','PhotoCapturePicker','fileImporter','Data Not Collected','deviceOwnerAuthentication','AES.GCM','isExcludedFromBackup','enteredInactive','MFMessageComposeViewController','tel:112','tel:024','trustedContact','requireAuthenticationForDeletion','KeyboardDismissInstaller','DefaultCollectionKind','Helpful Reminders','languageOverride','showLibraryIntroduction','template.summary','MealReflection','MealReflectionsRootView','ReflectionCalendarView','MealMoment','IntakeGuidePrompt','guidedAnswers','schemaVersion = 3','OnboardingStep','OnboardingFlowState','Three spaces, each with its own purpose.','Continue to App Lock','Show Intakes in the app','Choose Photos','Open Calendar')) {
    if (-not $AllSwift.Contains($RequiredText) -and $RequiredText -ne 'Data Not Collected') {
        $Failures.Add("Expected implementation marker missing: $RequiredText")
    }
}
foreach ($Forbidden in @('GoogleMobileAds','FirebaseAnalytics','CloudKit','HealthKit','ATTrackingManager')) {
    if ($AllSwift.Contains($Forbidden)) { $Failures.Add("Forbidden MVP dependency: $Forbidden") }
}
$AppModel = Get-Content -LiteralPath (Join-Path $ProjectRoot 'GentleNote\Core\AppModel.swift') -Raw
$LanguageSetterStart = $AppModel.IndexOf('func setLanguage(_ language: AppLanguage?)')
$LanguageSetterEnd = if ($LanguageSetterStart -ge 0) { $AppModel.IndexOf('func setLibraryIntroductionVisible', $LanguageSetterStart) } else { -1 }
$LanguageSetter = if ($LanguageSetterStart -ge 0 -and $LanguageSetterEnd -gt $LanguageSetterStart) {
    $AppModel.Substring($LanguageSetterStart, $LanguageSetterEnd - $LanguageSetterStart)
} else { '' }
if (-not $AppModel.Contains('@Published private(set) var activeLanguageOverride: AppLanguage?')) {
    $Failures.Add('The active app language must be observable so Settings changes refresh the interface')
}
if (-not $LanguageSetter.Contains('GentleLocalization.configure(language)') -or
    -not $LanguageSetter.Contains('activeLanguageOverride = language')) {
    $Failures.Add('Changing App Language must configure localization and publish the active language')
}
foreach ($RemovedOnboardingCopy in @('Your words and recordings stay with you.','A note about care.','I understand what this journal can and cannot do.')) {
    if ($AllSwift.Contains($RemovedOnboardingCopy)) { $Failures.Add("Removed onboarding copy is still present: $RemovedOnboardingCopy") }
}

$Onboarding = Get-Content -LiteralPath (Join-Path $ProjectRoot 'GentleNote\UI\OnboardingAndRoot.swift') -Raw
foreach ($OnboardingMarker in @('case welcome','case overview','case appLock','flow.skipTour()','Button("Skip tour".gentleLocalized)','Button("Not Now".gentleLocalized)')) {
    if (-not $Onboarding.Contains($OnboardingMarker)) { $Failures.Add("Onboarding flow marker missing: $OnboardingMarker") }
}
$JournalPosition = $Onboarding.IndexOf('title: "Journal"')
$LibraryPosition = $Onboarding.IndexOf('title: "Library"')
$ReflectionPosition = $Onboarding.IndexOf('title: "Intakes"')
if ($JournalPosition -lt 0 -or $LibraryPosition -lt 0 -or $ReflectionPosition -lt 0 -or
    -not ($JournalPosition -lt $LibraryPosition -and $LibraryPosition -lt $ReflectionPosition)) {
    $Failures.Add('Onboarding overview must keep Journal, Library, and Intakes in that order')
}
$OnboardingCompletionCalls = [regex]::Matches($Onboarding, 'model\.setOnboardingComplete\(\)').Count
if ($OnboardingCompletionCalls -ne 2) {
    $Failures.Add("Onboarding completion must remain exclusive to the two App Lock choices; found $OnboardingCompletionCalls calls")
}
$Components = Get-Content -LiteralPath (Join-Path $ProjectRoot 'GentleNote\UI\Components.swift') -Raw
$RootJournal = $Components.IndexOf('tab(.journal, "Journal"')
$RootLibrary = $Components.IndexOf('tab(.library, "Library"')
$RootReflections = $Components.IndexOf('tab(.reflections, "Intakes"')
$RootSettings = $Components.IndexOf('tab(.settings, "Settings"')
if ($RootJournal -lt 0 -or $RootLibrary -lt 0 -or $RootReflections -lt 0 -or $RootSettings -lt 0 -or
    -not ($RootJournal -lt $RootLibrary -and $RootLibrary -lt $RootReflections -and $RootReflections -lt $RootSettings)) {
    $Failures.Add('Root navigation must keep Journal, Library, Intakes, and Settings in that order')
}
$MealReflectionsUI = Get-Content -LiteralPath (Join-Path $ProjectRoot 'GentleNote\UI\MealReflectionsViews.swift') -Raw
foreach ($MealMarker in @('NavigationLink {','ReflectionCalendarScreen','maxSelectionCount: 20','Take Another Photo','Choose Audio File','Record Video','setMealReflectionIntroductionVisible(false)','Use guided questions','Guided intake check-in','guidedBinding(for:')) {
    if (-not $MealReflectionsUI.Contains($MealMarker)) { $Failures.Add("Meal Reflections marker missing: $MealMarker") }
}
foreach ($RemovedMealUI in @('Image(systemName: "lock.shield")','Picker("View", selection: $mode)','A moment, held gently','There is nothing to complete and no schedule to keep.')) {
    if ($MealReflectionsUI.Contains($RemovedMealUI)) { $Failures.Add("Removed Meal Reflections UI is still present: $RemovedMealUI") }
}
foreach ($RemovedVisibleCopy in @('Reflection templates are not therapy or medical advice.','No account. No ads. No analytics.','New Journal Entry','Start blank or choose a gentle template.','Nothing is due.','There is nothing to keep up with.','Write whatever feels useful right now.','Write whatever feels useful…','Use a structure, start blank, or leave.','Every prompt is optional.','Answer any question, in any order. Leave anything blank.','Keep a note, image, or recording without creating a journal entry.','Add as many photos as you like, plus optional audio or video.','Everything is optional after the main photo and stays encrypted on this iPhone.')) {
    if ($AllSwift.Contains($RemovedVisibleCopy)) { $Failures.Add("Removed visible copy is still present: $RemovedVisibleCopy") }
}
$SettingsUI = Get-Content -LiteralPath (Join-Path $ProjectRoot 'GentleNote\UI\SettingsViews.swift') -Raw
foreach ($SettingsSummaryMarker in @(
    '@State private var librarySummaryExpanded = false',
    '@State private var mealReflectionsSummaryExpanded = false',
    'DisclosureGroup(isExpanded: $librarySummaryExpanded)',
    'DisclosureGroup(isExpanded: $mealReflectionsSummaryExpanded)',
    'Label("What Library is for", systemImage: "info.circle")',
    'Label("What Intakes is for", systemImage: "info.circle")'
)) {
    if (-not $SettingsUI.Contains($SettingsSummaryMarker)) {
        $Failures.Add("Settings summary disclosure marker missing: $SettingsSummaryMarker")
    }
}
foreach ($RemovedLibraryUI in @('Button("Collections")','selectedCollectionID','Organize them with collections and tags.','questionmark.shield','text.document','case .noticeSomethingSmall: "sprout"')) {
    if ($AllSwift.Contains($RemovedLibraryUI)) { $Failures.Add("Removed Library/UI marker is still present: $RemovedLibraryUI") }
}

$MediaServices = Get-Content -LiteralPath (Join-Path $ProjectRoot 'GentleNote\Services\MediaServices.swift') -Raw
if ($MediaServices.Contains('setCategory(.record, mode: .spokenAudio')) {
    $Failures.Add('Audio recording still uses the incompatible record/spokenAudio session pair')
}
foreach ($AudioSafetyMarker in @(
    'static let sessionCategory: AVAudioSession.Category = .record',
    'static let sessionMode: AVAudioSession.Mode = .default',
    'recorder.prepareToRecord()',
    'options: .notifyOthersOnDeactivation'
)) {
    if (-not $MediaServices.Contains($AudioSafetyMarker)) {
        $Failures.Add("Audio recording safety marker missing: $AudioSafetyMarker")
    }
}
$BeginConfiguration = $MediaServices.IndexOf('self.session.beginConfiguration()')
$CommitConfiguration = if ($BeginConfiguration -ge 0) {
    $MediaServices.IndexOf('self.session.commitConfiguration()', $BeginConfiguration)
} else { -1 }
$StartRunning = if ($BeginConfiguration -ge 0) {
    $MediaServices.IndexOf('self.session.startRunning()', $BeginConfiguration)
} else { -1 }
if ($BeginConfiguration -lt 0 -or $CommitConfiguration -lt 0 -or $StartRunning -lt 0 -or
    -not ($BeginConfiguration -lt $CommitConfiguration -and $CommitConfiguration -lt $StartRunning)) {
    $Failures.Add('Video capture must commit configuration before calling startRunning')
}

$SpanishCatalog = Get-Content -LiteralPath (Join-Path $ProjectRoot 'GentleNote\Resources\es.lproj\Localizable.strings') -Raw
$SpanishKeys = [regex]::Matches($SpanishCatalog, '(?m)^"(?:\\.|[^"])*"\s*=')
if ($SpanishKeys.Count -lt 360) { $Failures.Add("Spanish catalog is unexpectedly incomplete: $($SpanishKeys.Count) keys") }
foreach ($RequiredSpanish in @('"Journal" = "Diario";','"Library" = "Biblioteca";','"Intakes" = "Ingestas";','"Settings" = "Ajustes";','"Gentle Check-In" = "Pausa para escucharte";','"Call 112" = "Llamar al 112";','"Call 024" = "Llamar al 024";','"Trusted Contact" = "Contacto de confianza";','"Helpful Reminders" = "Recordatorios que ayudan";','"Require Authentication to Delete" = "Solicitar autenticación para eliminar";','"App Language" = "Idioma de la app";','"What Library is for" = "Para qué sirve la Biblioteca";','"What Intakes is for" = "Para qué sirven las Ingestas";','"Show Library Introduction" = "Mostrar la introducción de la Biblioteca";','"Audio recording could not start. Please try again." = "No se ha podido iniciar la grabación de audio. Inténtalo de nuevo.";','"Three spaces, each with its own purpose." = "Tres espacios, cada uno con su propósito.";','"Write freely or choose a template. Your personal journal." = "Escribe libremente o elige una plantilla. Tu diario personal.";','"Keep private notes, images, videos, and audio to return to when you need them." = "Guarda notas, imágenes, vídeos y audios privados para volver a ellos cuando los necesites.";','"Keep one or more photos of your meals together with any words, audio, or video you want to add." = "Guarda una o más fotos de tus comidas junto al texto, audio o vídeo que quieras añadir.";','"Show Intakes in the app" = "Mostrar Ingestas en la app";','"Use guided questions" = "Usar preguntas guiadas";','"Write a note to return to later…" = "Escribe una nota a la que quieras volver más adelante…";','"Skip tour" = "Omitir recorrido";','"Continue to App Lock" = "Continuar al bloqueo";')) {
    if (-not $SpanishCatalog.Contains($RequiredSpanish)) { $Failures.Add("Missing required Spanish translation: $RequiredSpanish") }
}

$Pbx = Get-Content -LiteralPath (Join-Path $ProjectRoot 'GentleNote.xcodeproj\project.pbxproj') -Raw
$DefinedObjectIDs = [regex]::Matches($Pbx, '(?m)^\s*([A-F0-9]{24})\b(?: /\*.*?\*/)? = \{') |
    ForEach-Object { $_.Groups[1].Value }
$DuplicateObjectIDs = $DefinedObjectIDs | Group-Object | Where-Object { $_.Count -gt 1 }
foreach ($DuplicateObjectID in $DuplicateObjectIDs) {
    $Failures.Add("Xcode project reuses object identifier: $($DuplicateObjectID.Name)")
}
foreach ($Source in @('GentleNoteApp.swift','Models.swift','SecureStore.swift','AppModel.swift','AuthenticationService.swift','MediaServices.swift','ExportService.swift','SupportStore.swift','DesignSystem.swift','Components.swift','OnboardingAndRoot.swift','JournalViews.swift','LibraryViews.swift','SettingsViews.swift','GentleNoteTests.swift','PrivacyInfo.xcprivacy')) {
    if (-not $Pbx.Contains($Source)) { $Failures.Add("Xcode project omits: $Source") }
}
foreach ($LocalizedResource in @('Localizable.strings','InfoPlist.strings','knownRegions = (en, es, Base)')) {
    if (-not $Pbx.Contains($LocalizedResource)) { $Failures.Add("Xcode project omits localization marker: $LocalizedResource") }
}
if (-not $Pbx.Contains('MARKETING_VERSION = 0.8')) { $Failures.Add('Marketing version is not 0.8') }
if (-not $Pbx.Contains('CURRENT_PROJECT_VERSION = 1')) { $Failures.Add('Build number is not 1') }
if (-not $Pbx.Contains('ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon')) { $Failures.Add('Xcode target does not select the AppIcon asset catalog') }
if (-not $Pbx.Contains('IPHONEOS_DEPLOYMENT_TARGET = 16.0')) { $Failures.Add('Minimum iOS version is not 16.0') }
if (-not $Pbx.Contains('PRODUCT_BUNDLE_IDENTIFIER = com.krazel.gentlenote.B2X6D3A9J9')) { $Failures.Add('App Store bundle identifier is not configured') }
if (-not $Pbx.Contains('DEVELOPMENT_TEAM = B2X6D3A9J9')) { $Failures.Add('Apple development team is not configured') }

$InfoPlist = Get-Content -LiteralPath (Join-Path $ProjectRoot 'GentleNote\Info.plist') -Raw
if (-not $InfoPlist.Contains('<key>CFBundleIconName</key>')) { $Failures.Add('Info.plist is missing CFBundleIconName') }
if (-not $InfoPlist.Contains('<string>AppIcon</string>')) { $Failures.Add('Info.plist does not select AppIcon') }
if (-not $InfoPlist.Contains('<key>CFBundleIcons</key>')) { $Failures.Add('Info.plist is missing CFBundleIcons') }
if (-not $InfoPlist.Contains('<key>CFBundlePrimaryIcon</key>')) { $Failures.Add('Info.plist is missing CFBundlePrimaryIcon') }
$AppIconPath = Join-Path $ProjectRoot 'GentleNote\Resources\Assets.xcassets\AppIcon.appiconset\AppIcon-1024.png'
$AppIconContents = Get-Content -LiteralPath (Join-Path $ProjectRoot 'GentleNote\Resources\Assets.xcassets\AppIcon.appiconset\Contents.json') -Raw
if (-not (Test-Path -LiteralPath $AppIconPath)) { $Failures.Add('AppIcon-1024.png is missing') }
if (-not $AppIconContents.Contains('"filename" : "AppIcon-1024.png"')) { $Failures.Add('App icon catalog does not reference AppIcon-1024.png') }

$Workflow = Get-Content -LiteralPath (Join-Path $ProjectRoot '.github\workflows\ios-verify.yml') -Raw
foreach ($VersionMarker in @('runs-on: macos-26','GentleNote-0.8-build-1-${SHORT_SHA}-Local-QA-unsigned','"marketingVersion": "0.8"','"build": "1"','GentleNote-0.8-build-1-test-evidence')) {
    if (-not $Workflow.Contains($VersionMarker)) { $Failures.Add("Workflow version marker missing: $VersionMarker") }
}

$TestFlightWorkflowPath = Join-Path $ProjectRoot '.github\workflows\build-ios-testflight.yml'
if (-not (Test-Path -LiteralPath $TestFlightWorkflowPath)) {
    $Failures.Add('TestFlight workflow is missing')
} else {
    $TestFlightWorkflow = Get-Content -LiteralPath $TestFlightWorkflowPath -Raw
    foreach ($Marker in @(
        'environment: app-store-production',
        'upload_to_testflight:',
        'default: false',
        'APP_STORE_CONNECT_API_KEY_BASE64',
        'com.krazel.gentlenote.B2X6D3A9J9',
        'runs-on: macos-26',
        'CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconName',
        'GentleNote-0.8-build-1-signed-${{ github.sha }}'
    )) {
        if (-not $TestFlightWorkflow.Contains($Marker)) {
            $Failures.Add("TestFlight workflow is missing marker: $Marker")
        }
    }
}

if ($Failures.Count -gt 0) {
    Write-Output 'VERIFY: FAIL'
    $Failures | ForEach-Object { Write-Output " - $_" }
    exit 1
}

Write-Output 'VERIFY: PASS'
Write-Output "Swift files: $($Swift.Count)"
Write-Output "Approved boards: $($Approved.Count)"
Write-Output 'Version: 0.8 (1), iOS 16+'
Write-Output 'Scope: iPhone, English and Spanish, local-only, no accounts/ads/analytics/tracking'
