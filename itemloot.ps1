Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = $MyInvocation.MyCommand.Path}
$null = $FileBrowser.ShowDialog()
$filePath = $FileBrowser.FileName

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$steamId = [Microsoft.VisualBasic.Interaction]::InputBox("Victims SteamID", "SteamID", "")

if ($steamId){
    $datePattern = '(\[\d{2}/\d{2} \d{2}:\d{2}:\d{2}\]) T:ItemMove(.*) S:'+$steamId+' (\[.*\]) T:0 \[0, 0, 0\]'
    $extraPattern = 'Extra:(\d+)x (.+) (?<!moved )from (.+)'

    $date = $null
    $output = @()

    $lines = Get-Content $filePath
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]

        if ($line -match $datePattern) {
            $date = $Matches[1]

            if ($i -lt $lines.Length - 1) {
                $nextLine = $lines[$i+1]

                if ($nextLine -match $extraPattern) {
                    $quantity = $Matches[1]
                    $item = $Matches[2]
                    $container = $Matches[3]
                    $entry = [PSCustomObject]@{
                        Date = $date
                        Quantity = $quantity
                        Item = $item
                        Container = $container
                    }
                    $output += $entry
                } 
            }
        }
    }
    $writefile = (Get-Item $filePath ).DirectoryName
    $date = Get-Date –format 'yyyyMMdd_HHmmss'
    Write-Host ""
    Write-Host "Report saved to $writefile\$steamId-$date.txt"
    $output | Format-Table -AutoSize | Out-File "$writefile\\$steamId-$date.txt"
    &notepad.exe "$writefile\\$steamId-$date.txt"
}
