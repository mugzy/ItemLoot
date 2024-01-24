Add-Type -AssemblyName System.Windows.Forms

#editor: notepad.exe or notepad++.exe
$editor = "C:\Program Files\Notepad++\notepad++.exe"
#$editor = "notepad.exe"

$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = $MyInvocation.MyCommand.Path }
$null = $FileBrowser.ShowDialog()
$filePath = $FileBrowser.FileName
$steamId = 1
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$steamId = [Microsoft.VisualBasic.Interaction]::InputBox("Players SteamID or 1 for all", "SteamID", "1")
$directionSelection = [Microsoft.VisualBasic.Interaction]::InputBox("Enter All, To, or From", "Direction", "All")

# Regex patterns 
$p1 = '(\[\d{2}\/\d{2} \d{2}:\d{2}:\d{2}\]) T:ItemMove(.*) S:(.*) (\[.*\]) T:.* (\[-?\d+(\.\d+)?, -?\d+(\.\d+)?, -?\d+(\.\d+)?\])'
$p2 = '(\[\d{2}\/\d{2} \d{2}:\d{2}:\d{2}\]) T:ItemMove(.*) S:(' + $steamId + ') (\[.*\]) T:.* (\[-?\d+(\.\d+)?, -?\d+(\.\d+)?, -?\d+(\.\d+)?\])'
$extraPatternFrom = 'Extra:(\d+)x (.+) (?<!moved )from (.+)'
$extraPatternFromPicked = 'Extra:picked up (\d+)x (.*)'
$extraPatternNoFrom = '^Extra:(?!.*\bfrom\b).+'
$extraPatternTo = 'Extra:(\d+)x (.+) moved to (.+)'
$extraPatternToDropped = 'Extra:dropped (\d+)x (.*)'
#define regex to match "Extra:1x Burlap Shirt"
$extraPatternUnknown = 'Extra:(\d+)x (.+)'


$scriptpath = Get-Location
#If the csv file does not exist, download from https://github.com/mugzy/ItemLoot/blob/main/rust_items_full.csv
if (!(Test-Path "$scriptpath\rust_items_full.csv")) {
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile("https://raw.githubusercontent.com/mugzy/ItemLoot/main/rust_items_full.csv", "$scriptpath\rust_items_full.csv")
}
$itemlist = Import-Csv "$scriptpath\rust_items_full.csv"
"Processing $filePath larger exports will take longer"

function Get-RustItemID {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ItemName
    )
    
    $itemlist | Where-Object { $_.Name -eq $ItemName.Replace('?','-')} | Select-Object -ExpandProperty shortname
}

$date = $null
$direction = $null
$output = @()

if ($steamId) {
    if ($steamId.length -ne 17) {
        $datePatternset = $p1
    }
    else {
        $datePatternset = $p2
    }
    $lines = Get-Content $filePath
    #remove blank lines from $lines
    $lines = $lines | Where-Object { $_ -ne "" }
    
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        $nextLine = $lines[$i + 1]
        $nextLine3 = $lines[$i + 3]
        $datePattern = $datePatternset
        try {
            if ($line -match $datePattern -or $nextLine.Contains($steamId)) {
                
                if ($steamId.length -ne 1 -and $nextLine.Contains($steamId)) {
                    $datePattern = $p1
                }
                if (($line -match $datePattern -or ($steamId.length -ne 1 -and $nextLine.Contains($steamId))) -and !$nextLine.Contains("moved from") ) {

                    if ($Matches[5] -eq "[0, 0, 0]" -and ($directionSelection -eq "From" -or $directionSelection -eq "All") -and !$nextLine.Contains("dropped")) {
                        $direction = "FROM"
                    }
                    elseif ($directionSelection -eq "To" -or $directionSelection -eq "All") {
                        $direction = "TO"
                    }
                    elseif ($Matches[5] -eq "[0, 0, 0]" -and ($directionSelection -eq "All") -and $nextLine -notmatch "(?i)(dropped|moved|from|to)"){
                        $direction = "unknown"
                    }
                
                    $date = $Matches[1]
                    $name = $Matches[2]
                    $PlayerID = $Matches[3]
                    if ($i -lt $lines.Length - 1) {

    
                        if ($direction -eq "FROM") {
                            $pattern = $extraPatternFrom
                            $pattern1 = $extraPatternFromPicked
                            $pattern3 = $extraPatternNoFrom
                        }
                        elseif ($direction -eq "TO") {
                            $pattern = $extraPatternTo
                            $pattern1 = $extraPatternToDropped
                        }
                        elseif ($direction -eq "unknown") {
                            $pattern = $extraPatternUnknown
                        }
    
                        if ($nextLine -match $pattern -or $nextLine -match $pattern1 -or ($nextLine -match $pattern3 -and !$nextLine3.Contains("from"))) {
                            if (!$nextLine.Contains("from")) {
                                if($nextLine -match $extraPatternUnknown){}
                            }
                            $OuterLoopProgressParameters = @{
                                Activity         = 'Parsing File'
                                Status           = 'Progress->'
                                PercentComplete  =  ($i / $lines.Length) * 100
                                CurrentOperation = "Line $i of $($lines.Length)"
                            }
                            Write-Progress @OuterLoopProgressParameters
                            
                            $container = "unknown"
                            $quantity = $Matches[1]
                            $item = $Matches[2]
                            $shortname = Get-RustItemID -ItemName $item
                            $container = $Matches[3]
                            $entry = [PSCustomObject]@{
                                Date      = $date
                                PlayerID  = $PlayerID
                                Name      = $name
                                Quantity  = $quantity
                                Item      = $item.Replace('?','-')
                                Direction = $direction
                                Command = "inventory.give $shortname $quantity"
                                Container = if ( $Container ) { $Container } else { "unknown" }
                            }
                            
                            $output += $entry
                            
                        }
                    }
                }
            }
        } 
        catch [System.Exception] {          
        }
    }
       
    
    $writefile = (Get-Item $filePath ).DirectoryName
    $date = Get-Date -format 'yyyyMMdd_HHmmss'
    Write-Host ""
    Write-Host "Report saved to $writefile\$steamId-$date.txt"
    $output | Format-Table -AutoSize | Out-File -Width 300 "$writefile\\$steamId-$date.txt"
    
    $export = [Microsoft.VisualBasic.Interaction]::MsgBox("Do you want to export to CSV?", "YesNo", "Export to CSV")
    if ($export -eq "Yes") {
        $output | Export-Csv -Path "$writefile\\$steamId-$date.csv" -NoTypeInformation
        Write-Host "Report saved to $writefile\$steamId-$date.csv"
    }
    
    &$editor "$writefile\\$steamId-$date.txt"
}
else {
    Write-Host "No SteamID entered"
}