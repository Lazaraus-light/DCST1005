# Ensure Winget is installed and updated
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Output "Winget is not installed. Please install Winget from the Microsoft Store."
    exit
}

# Update Winget to the latest version
Write-Output "Updating Winget to the latest version..."
winget upgrade --id Microsoft.Winget.Source --silent --accept-source-agreements

# List all installed drivers
Write-Output "Listing all installed drivers..."
$drivers = winget list | Where-Object { $_.Name -like "*Driver*" }

if ($drivers.Count -eq 0) {
    Write-Output "No drivers found that can be updated via Winget."
    exit
}

# Update all drivers
Write-Output "Updating all drivers..."
foreach ($driver in $drivers) {
    Write-Output "Updating $($driver.Name)..."
    winget upgrade --id $driver.Id --silent --accept-package-agreements
}

Write-Output "All drivers have been updated."
