Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = $MyInvocation.MyCommand.Path }
$null = $FileBrowser.ShowDialog()
$filePath = $FileBrowser.FileName
$steamId = 1
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$steamId = [Microsoft.VisualBasic.Interaction]::InputBox("Players SteamID or 1 for all", "SteamID", "1")
$directionSelection = [Microsoft.VisualBasic.Interaction]::InputBox("Enter All, To, or From", "Direction", "All")
$p1 = '(\[\d{2}\/\d{2} \d{2}:\d{2}:\d{2}\]) T:ItemMove(.*) S:(.*) (\[.*\]) T:.* (\[-?\d+(\.\d+)?, -?\d+(\.\d+)?, -?\d+(\.\d+)?\])'
$p2 = '(\[\d{2}\/\d{2} \d{2}:\d{2}:\d{2}\]) T:ItemMove(.*) S:(' + $steamId + ') (\[.*\]) T:.* (\[-?\d+(\.\d+)?, -?\d+(\.\d+)?, -?\d+(\.\d+)?\])'
if ($steamId) {
    if ($steamId.length -ne 17) {
        $datePatternset = $p1
    }
    else {
        $datePatternset = $p2
    }
    $extraPatternFrom = 'Extra:(\d+)x (.+) (?<!moved )from (.+)'
    $extraPatternFromPicked = 'Extra:picked up (\d+)x (.*)'
    $extraPatternTo = 'Extra:(\d+)x (.+) moved to (.+)'
    $extraPatternToDropped = 'Extra:dropped (\d+)x (.*)'
    $date = $null
    $direction = $null
    $output = @()

    $lines = Get-Content $filePath
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        $nextLine = $lines[$i + 1]
        $datePattern = $datePatternset
        try {
            if ($line -match $datePattern -or $nextLine.Contains($steamId)) {
                <# Action to perform if the condition is true #>
                if ($steamId.length -ne 1 -and $nextLine.Contains($steamId)) {
                    $datePattern = $p1
                }
                if (($line -match $datePattern -or ($steamId.length -ne 1 -and $nextLine.Contains($steamId))) -and !$nextLine.Contains("moved from") -and ($nextLine.Contains("moved to") -or $nextLine.Contains("from") -or $nextLine.Contains("picked up") -or $nextLine.Contains("dropped"))) {
                    if ($nextLine.Contains($steamId)) {
                        $line -match '(\[\d{2}\/\d{2} \d{2}:\d{2}:\d{2}\]) T:ItemMove(.*) S:(.*) (\[.*\]) T:.* (\[-?\d+(\.\d+)?, -?\d+(\.\d+)?, -?\d+(\.\d+)?\])'
                    }
                    if ($Matches[5] -eq "[0, 0, 0]" -and ($directionSelection -eq "From" -or $directionSelection -eq "All")) {
                        $direction = "FROM"
                    }
                    elseif ($directionSelection -eq "To" -or $directionSelection -eq "All") {
                        $direction = "TO"
                    }
                
                    $date = $Matches[1]
                    $name = $Matches[2]
                    $PlayerID = $Matches[3]
                    if ($i -lt $lines.Length - 1) {
                    
    
                        if ($direction -eq "FROM") {
                            $pattern = $extraPatternFrom
                            $pattern1 = $extraPatternFromPicked
                        }
                        elseif ($direction -eq "TO") {
                            $pattern = $extraPatternTo
                            $pattern1 = $extraPatternToDropped
                        }
    
                        if ($nextLine -match $pattern -or $nextLine -match $pattern1) {
                            $container = "ground"
                            $quantity = $Matches[1]
                            $item = $Matches[2]
                            $container = $Matches[3]
                            $entry = [PSCustomObject]@{
                                Date      = $date
                                PlayerID  = $PlayerID
                                Name      = $name
                                Quantity  = $quantity
                                Item      = $item
                                Direction = $direction
                                Container = if ( $Container ) { $Container } else { "ground" }
            
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
    $output | Format-Table -AutoSize | Out-File "$writefile\\$steamId-$date.txt"
    $output | Export-Csv -Path "$writefile\\$steamId-$date.csv" -NoTypeInformation
    &notepad.exe "$writefile\\$steamId-$date.txt"
}
