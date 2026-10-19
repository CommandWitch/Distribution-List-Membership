# Add or Remove Bulk Users to DLs — CSV or Manual Entry
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$WarningPreference = 'SilentlyContinue'

Write-Host "=== Distribution Group Bulk Membership Tool ===" -ForegroundColor Cyan
Write-Host ""

# Choose Action
$action = Read-Host "Type ADD to add members or REMOVE to remove members"
$action = $action.Trim().ToUpper()
if ($action -notin @("ADD", "REMOVE")) {
    Write-Host "Invalid action. Enter only ADD or REMOVE. Exiting." -ForegroundColor Yellow
    return
}

# Choose Input Mode
Write-Host ""
Write-Host "How would you like to provide email addresses?" -ForegroundColor Cyan
Write-Host "  1 = Upload CSV file (bulk list)"
Write-Host "  2 = Enter 1 to 3 email addresses manually"
$choice = Read-Host "Enter 1 or 2"
$choice = $choice.Trim()

$members = @()

if ($choice -eq "1") {
    # ==================================================
    # ?? CSV Mode
    # ==================================================
    Add-Type -AssemblyName System.Windows.Forms
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileDialog.Filter = "CSV Files (*.csv)|*.csv"
    $fileDialog.Title = "Select your CSV file"
    $fileDialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")

    $result = $fileDialog.ShowDialog()
    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        Write-Host "No file selected. Exiting." -ForegroundColor Yellow
        return
    }
    $csvPath = $fileDialog.FileName
    Write-Host "Selected file: $csvPath`n" -ForegroundColor Green

    if (-not (Test-Path $csvPath)) {
        Write-Host "CSV file not found. Exiting." -ForegroundColor Yellow
        return
    }
    try {
        $csvData = Import-Csv $csvPath
    }
    catch {
        Write-Host "Failed to read CSV: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    if (-not $csvData -or -not ($csvData | Get-Member -Name EmailAddress -ErrorAction SilentlyContinue)) {
        Write-Host "CSV empty or missing 'EmailAddress' column. Exiting." -ForegroundColor Yellow
        return
    }

    $members = $csvData |
        ForEach-Object { if ($_.EmailAddress) { $_.EmailAddress.Trim().ToLower() } } |
        Where-Object { $_ } |
        Sort-Object -Unique
}
elseif ($choice -eq "2") {
    # ==================================================
    # ?? Manual Entry Mode
    # ==================================================
    Write-Host ""
    Write-Host "Enter up to 3 email addresses — leave blank and press Enter when done" -ForegroundColor Cyan

    for ($i = 1; $i -le 3; $i++) {
        $email = Read-Host "Email address $i"
        $email = $email.Trim().ToLower()
        if ($email -ne "") {
            $members += $email
        }
        else {
            break
        }
    }

    $members = $members | Sort-Object -Unique
}
else {
    Write-Host "Invalid choice. Exiting." -ForegroundColor Yellow
    return
}

# Validate Members List
if (-not $members -or $members.Count -eq 0) {
    Write-Host "No valid email addresses provided. Exiting." -ForegroundColor Yellow
    return
}

Write-Host "`nProcessing $($members.Count) member(s)`n" -ForegroundColor Cyan

# ==================================================
# ?? Connect to Exchange
# ==================================================
if (-not (Get-Module -ListAvailable ExchangeOnlineManagement)) {
    Write-Host "ExchangeOnlineManagement module not found." -ForegroundColor Red
    Write-Host "Install: Install-Module -Name ExchangeOnlineManagement -Force -Scope CurrentUser" -ForegroundColor Yellow
    return
}
if (-not (Get-Module ExchangeOnlineManagement)) {
    Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
}

Write-Host "Opening Exchange sign-in window..." -ForegroundColor Cyan
try {
    Connect-ExchangeOnline -ShowBanner:$false
}
catch {
    Write-Host "Sign-in failed. Exiting." -ForegroundColor Red
    return
}

Write-Host "Connected. Loading Distribution Groups...`n" -ForegroundColor Green

# ==================================================
# ?? Get & Select DLs
# ==================================================
Write-Host "Fetching Distribution Groups (please wait)..." -ForegroundColor Cyan
$allDLs = Get-DistributionGroup -ResultSize Unlimited -WarningAction SilentlyContinue

if (-not $allDLs) {
    Write-Host "No Distribution Groups found. Check permissions." -ForegroundColor Red
    return
}

Write-Host "Total groups available: $($allDLs.Count)`n" -ForegroundColor Green

$selectedDLs = $allDLs | Sort-Object Name | Out-GridView -Title "Select one or more Distribution Groups" -OutputMode Multiple

if (-not $selectedDLs) {
    Write-Host "No DLs selected. Exiting." -ForegroundColor Yellow
    return
}

Write-Host "Selected $($selectedDLs.Count) DL(s)`n" -ForegroundColor Green

# ==================================================
# ?? Logs to Desktop
# ==================================================
$desktopPath = [Environment]::GetFolderPath("Desktop")
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logDir = Join-Path $desktopPath "DL-Membership-Logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }

$detailedLogPath = Join-Path $logDir "DL-Details-$action-$timestamp.csv"
$summaryLogPath  = Join-Path $logDir "DL-Summary-$action-$timestamp.csv"
$detailedLog = @()
$summaryLog  = @()

# ==================================================
# ?? Process Each DL
# ==================================================
foreach ($dl in $selectedDLs) {
    Write-Host "Processing: $($dl.Name)" -ForegroundColor Cyan
    $dlTotal = $dlSuccess = $dlSkipped = $dlFailed = 0

    try {
        $dlMembers = Get-DistributionGroupMember -Identity $dl.Identity -ResultSize Unlimited -WarningAction SilentlyContinue
        $existingMembers = @()
        foreach ($m in $dlMembers) {
            if ($m.PrimarySmtpAddress) { $existingMembers += $m.PrimarySmtpAddress.ToString().ToLower() }
            elseif ($m.WindowsLiveID) { $existingMembers += $m.WindowsLiveID.ToString().ToLower() }
        }

        foreach ($member in $members) {
            $dlTotal++
            $logEntry = [PSCustomObject]@{
                Timestamp   = Get-Date
                Action      = $action
                GroupName   = $dl.Name
                GroupSmtp   = $dl.PrimarySmtpAddress
                MemberEmail = $member
                Result      = $null
                Message     = $null
            }

            try {
                if ($action -eq "ADD") {
                    if ($existingMembers -contains $member) {
                        $logEntry.Result = "Skipped"; $logEntry.Message = "Already a member"; $dlSkipped++
                        Write-Host "??  $member — already member" -ForegroundColor Yellow
                    }
                    else {
                        Add-DistributionGroupMember -Identity $dl.Identity -Member $member -ErrorAction Stop -WarningAction SilentlyContinue
                        $logEntry.Result = "Success"; $logEntry.Message = "Added"; $dlSuccess++
                        Write-Host "? $member — added" -ForegroundColor Green
                    }
                }
                else { # REMOVE
                    if ($existingMembers -contains $member) {
                        Remove-DistributionGroupMember -Identity $dl.Identity -Member $member -Confirm:$false -ErrorAction Stop -WarningAction SilentlyContinue
                        $logEntry.Result = "Success"; $logEntry.Message = "Removed"; $dlSuccess++
                        Write-Host "? $member — removed" -ForegroundColor Green
                    }
                    else {
                        $logEntry.Result = "Skipped"; $logEntry.Message = "Not a member"; $dlSkipped++
                        Write-Host "??  $member — not member" -ForegroundColor Yellow
                    }
                }
            }
            catch {
                $logEntry.Result = "Failed"; $logEntry.Message = $_.Exception.Message; $dlFailed++
                Write-Host "? $member — FAILED: $($_.Exception.Message)" -ForegroundColor Red
            }
            $detailedLog += $logEntry
        }
    }
    catch {
        Write-Host "? Cannot get members for '$($dl.Name)': $($_.Exception.Message)" -ForegroundColor Red
        $summaryLog += [PSCustomObject]@{
            Timestamp = Get-Date; Action = $action; GroupName = $dl.Name; GroupSmtp = $dl.PrimarySmtpAddress
            Total = $members.Count; Success = 0; Skipped = 0; Failed = $members.Count; Error = $_.Exception.Message
        }
        continue
    }

    $summaryLog += [PSCustomObject]@{
        Timestamp = Get-Date; Action = $action; GroupName = $dl.Name; GroupSmtp = $dl.PrimarySmtpAddress
        Total = $dlTotal; Success = $dlSuccess; Skipped = $dlSkipped; Failed = $dlFailed; Error = $null
    }
}

# Save Logs
if ($detailedLog.Count -gt 0) { $detailedLog | Export-Csv -Path $detailedLogPath -NoTypeInformation -Encoding UTF8 }
if ($summaryLog.Count -gt 0) { $summaryLog | Export-Csv -Path $summaryLogPath -NoTypeInformation -Encoding UTF8 }

Write-Host "`n? DONE — $action $($members.Count) member(s) across $($selectedDLs.Count) DL(s)" -ForegroundColor Green
Write-Host "?? Logs saved to: $logDir" -ForegroundColor Cyan