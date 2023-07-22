Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = $MyInvocation.MyCommand.Path}
$null = $FileBrowser.ShowDialog()
$filePath = $FileBrowser.FileName
$steamId = 1
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$steamId = [Microsoft.VisualBasic.Interaction]::InputBox("Players SteamID or 1 for all", "SteamID", "1")
$directionSelection = [Microsoft.VisualBasic.Interaction]::InputBox("Enter All, To, or From", "Direction", "All")

if ($steamId){
    if ($steamId.length -ne 17){
        $datePattern = '(\[\d{2}\/\d{2} \d{2}:\d{2}:\d{2}\]) T:ItemMove(.*) S:(.*) (\[.*\]) T:.* (\[-?\d+(\.\d+)?, -?\d+(\.\d+)?, -?\d+(\.\d+)?\])'}
    else{
        $datePattern = '(\[\d{2}\/\d{2} \d{2}:\d{2}:\d{2}\]) T:ItemMove(.*) S:('+$steamId+') (\[.*\]) T:.* (\[-?\d+(\.\d+)?, -?\d+(\.\d+)?, -?\d+(\.\d+)?\])'
    }
    $extraPatternFrom = 'Extra:(\d+)x (.+) (?<!moved )from (.+)'
    $extraPatternTo = 'Extra:(\d+)x (.+) moved to (.+)'
    $date = $null
    $direction = $null
    $output = @()

    $lines = Get-Content $filePath
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]

        if ($line -match $datePattern) {
            if ($Matches[5] -eq "[0, 0, 0]" -and ($directionSelection -eq "From" -or $directionSelection -eq "All")){
                $direction = "FROM"
                }
            elseif ($directionSelection -eq "To" -or $directionSelection -eq "All"){
                $direction = "TO"
                }
            
            $date = $Matches[1]
            $name = $Matches[2]
            $PlayerID = $Matches[3]
            if ($i -lt $lines.Length - 1) {
                $nextLine = $lines[$i+1]

if ($direction -eq "FROM") {
    $pattern = $extraPatternFrom
} elseif ($direction -eq "TO") {
    $pattern = $extraPatternTo
}

if ($nextLine -match $pattern) {
    $quantity = $Matches[1]
    $item = $Matches[2]
    $container = $Matches[3]
    $entry = [PSCustomObject]@{
        Date = $date
        PlayerID = $PlayerID
        Name = $name
        Quantity = $quantity
        Item = $item
        Direction = $direction
        Container = $container
        
    }
    $output += $entry
}
            }
        }

    }
    $writefile = (Get-Item $filePath ).DirectoryName
    $date = Get-Date �format 'yyyyMMdd_HHmmss'
    Write-Host ""
    Write-Host "Report saved to $writefile\$steamId-$date.txt"
    $output | Format-Table -AutoSize | Out-File "$writefile\\$steamId-$date.txt"
    $output | Export-Csv -Path "$writefile\\$steamId-$date.csv" -NoTypeInformation
    &notepad.exe "$writefile\\$steamId-$date.txt"
}
