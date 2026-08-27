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
if ($Approved.Count -ne 8) { $Failures.Add("Expected 8 approved UI boards; found $($Approved.Count)") }

$ExpectedHashes = @{
    'ui-01-onboarding-journal.png' = 'F94224325FB6A9977AF58CAAAE25DA82E10EE38DC489A106ECADFEF6EECCF5D0'
    'ui-02-journal-templates.png' = '23FFE05AABB29E22FE0538C673E9C39B41605900A9AC72CC353F354BBF76CB51'
    'ui-03-journal-history.png' = 'E645F69C42B70D732FB7DB703E35316F214034160096CA411ABD8C4E6592EE94'
    'ui-04-library-notes-organize.png' = '58580B82DF523B0CC40573B96D83246EC2884B27E32851CE46F83B0FB36BC698'
    'ui-05-video-audio-create.png' = '7F61B655D21496228A96850EAA2D42F49D107CBDEC8CFDDB01F12FB47C9ACDD1'
    'ui-06-media-search-errors.png' = '2A50800B3193D53014BFCF7CCCAD789FD19152EDC692D97A3BCA5F7CC882996F'
    'ui-07-settings-export.png' = 'B44BBADE22225DF56477D2364CAD8546A492A32E6E2F102FC959E2E3BD8F7AC6'
    'ui-08-lock-delete-help.png' = '69AFFF70B5B28324743F5B1C06C1096D80B5389ED7C4DBEF2F5F2B5BF29BD345'
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
foreach ($RequiredText in @('Journal History','Record Video','Record Audio','Data Not Collected','deviceOwnerAuthentication','AES.GCM','isExcludedFromBackup')) {
    if (-not $AllSwift.Contains($RequiredText) -and $RequiredText -ne 'Data Not Collected') {
        $Failures.Add("Expected implementation marker missing: $RequiredText")
    }
}
foreach ($Forbidden in @('GoogleMobileAds','FirebaseAnalytics','CloudKit','HealthKit','ATTrackingManager')) {
    if ($AllSwift.Contains($Forbidden)) { $Failures.Add("Forbidden MVP dependency: $Forbidden") }
}
foreach ($RemovedOnboardingCopy in @('Your words and recordings stay with you.','A note about care.','I understand what this journal can and cannot do.')) {
    if ($AllSwift.Contains($RemovedOnboardingCopy)) { $Failures.Add("Removed onboarding copy is still present: $RemovedOnboardingCopy") }
}

$SpanishCatalog = Get-Content -LiteralPath (Join-Path $ProjectRoot 'GentleNote\Resources\es.lproj\Localizable.strings') -Raw
$SpanishKeys = [regex]::Matches($SpanishCatalog, '(?m)^"(?:\\.|[^"])*"\s*=')
if ($SpanishKeys.Count -lt 330) { $Failures.Add("Spanish catalog is unexpectedly incomplete: $($SpanishKeys.Count) keys") }
foreach ($RequiredSpanish in @('"Journal" = "Diario";','"Library" = "Biblioteca";','"Settings" = "Ajustes";','"Gentle Check-In" = "Pausa para escucharte";')) {
    if (-not $SpanishCatalog.Contains($RequiredSpanish)) { $Failures.Add("Missing required Spanish translation: $RequiredSpanish") }
}

$Pbx = Get-Content -LiteralPath (Join-Path $ProjectRoot 'GentleNote.xcodeproj\project.pbxproj') -Raw
foreach ($Source in @('GentleNoteApp.swift','Models.swift','SecureStore.swift','AppModel.swift','AuthenticationService.swift','MediaServices.swift','ExportService.swift','SupportStore.swift','DesignSystem.swift','Components.swift','OnboardingAndRoot.swift','JournalViews.swift','LibraryViews.swift','SettingsViews.swift','GentleNoteTests.swift','PrivacyInfo.xcprivacy')) {
    if (-not $Pbx.Contains($Source)) { $Failures.Add("Xcode project omits: $Source") }
}
foreach ($LocalizedResource in @('Localizable.strings','InfoPlist.strings','knownRegions = (en, es, Base)')) {
    if (-not $Pbx.Contains($LocalizedResource)) { $Failures.Add("Xcode project omits localization marker: $LocalizedResource") }
}
if (-not $Pbx.Contains('MARKETING_VERSION = 0.2')) { $Failures.Add('Marketing version is not 0.2') }
if (-not $Pbx.Contains('CURRENT_PROJECT_VERSION = 1')) { $Failures.Add('Build number is not 1') }
if (-not $Pbx.Contains('IPHONEOS_DEPLOYMENT_TARGET = 16.0')) { $Failures.Add('Minimum iOS version is not 16.0') }

if ($Failures.Count -gt 0) {
    Write-Output 'VERIFY: FAIL'
    $Failures | ForEach-Object { Write-Output " - $_" }
    exit 1
}

Write-Output 'VERIFY: PASS'
Write-Output "Swift files: $($Swift.Count)"
Write-Output "Approved boards: $($Approved.Count)"
Write-Output 'Version: 0.2 (1), iOS 16+'
Write-Output 'Scope: iPhone, English and Spanish, local-only, no accounts/ads/analytics/tracking'
