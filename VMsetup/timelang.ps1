#language, time and timezone settings:
#language, time and timezone settings:
# Se hvilke språkpakker (capabilities) som er tilgjengelige og evt. installert:
Get-WindowsCapability -Online -Name Language* | 
    Where-Object { $_.Name -like '*nb-NO*' } |
    Format-Table -Autosize

# Installer Bokmål grunnpakke:
Add-WindowsCapability -Online -Name Language.Basic~~~nb-NO~0.0.1.0

# (Valgfritt) Installer OCR / TextToSpeech / Handwriting / Speech om ønskelig:
# Add-WindowsCapability -Online -Name Language.OCR~~~nb-NO~0.0.1.0
# Add-WindowsCapability -Online -Name Language.TextToSpeech~~~nb-NO~0.0.1.0
# Add-WindowsCapability -Online -Name Language.Handwriting~~~nb-NO~0.0.1.0
# Add-WindowsCapability -Online -Name Language.Speech~~~nb-NO~0.0.1.0

# Sett Windows sin brukerliste for språk 
# (NB: -Force hindrer bekreftelsesdialog):
Set-WinUserLanguageList -LanguageList nb-NO -Force

# Sett system-lokale:
Set-WinSystemLocale nb-NO

# Sett kultur (valutafomat, dato/klokkeslett osv.):
Set-Culture nb-NO

# Sett standard grensesnittspråk for UI (f.eks. "Press any key to continue"):
Set-WinUILanguageOverride nb-NO


