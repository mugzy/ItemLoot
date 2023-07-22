Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = $MyInvocation.MyCommand.Path}
$null = $FileBrowser.ShowDialog()
$filePath = $FileBrowser.FileName
$steamId = 1
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$steamId = [Microsoft.VisualBasic.Interaction]::InputBox("Players SteamID or blank for all", "SteamID", "1")

if ($steamId){
    if ($steamId.length -ne 17){
        $datePattern = '(\[\d{2}/\d{2} \d{2}:\d{2}:\d{2}\]) T:ItemMove(.*) S:(.*) (\[.*\]) T:0 (\[-?\d+(\.\d+)?, -?\d+(\.\d+)?, -?\d+(\.\d+)?\])'}
    else{
        $datePattern = '(\[\d{2}/\d{2} \d{2}:\d{2}:\d{2}\]) T:ItemMove(.*) S:('+$steamId+') (\[.*\]) T:0 (\[-?\d+(\.\d+)?, -?\d+(\.\d+)?, -?\d+(\.\d+)?\])'
    }
    $extraPatternFrom = 'Extra:(\d+)x (.+) (?<!moved )from (.+)'
    $extraPatternTo = 'Extra:(\d+)x (.+) moved to (.+)'
    $direction = null
    $date = $null
    $output = @()

    $lines = Get-Content $filePath
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]

        if ($line -match $datePattern) {
            if ($Matches[4] = "[0, 0, 0]"){
                $direction = "FROM"
            else
                $direction = "TO"
            }
            $date = $Matches[1]
            $name = $Matches[2]
            $PlayerID = $Matches[3]
            if ($i -lt $lines.Length - 1) {
                $nextLine = $lines[$i+1]

if ($direction -eq "FROM") {
    $pattern = $extraPattern
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
        Container = $container
        Direction = $direction
    }
    $output += $entry
}
            }
        }
        if ($line -match $datePatternTo) {
            $date = $Matches[1]
            $name = $Matches[2]
            $PlayerID = $Matches[3]
            if ($i -lt $lines.Length - 1) {
                $nextLine = $lines[$i+1]

                if ($nextLine -match $extraPattern) {
                    $quantity = $Matches[1]
                    $item = $Matches[2]
                    $container = $Matches[3]
                    $entry = [PSCustomObject]@{
                        Date = $date
                        PlayerID = $PlayerID
                        Name = $name
                        Quantity = $quantity
                        Item = $item
                        Container = $container
                        Direction = "TO"
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
