Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = $MyInvocation.MyCommand.Path}
$null = $FileBrowser.ShowDialog()
$filePath = $FileBrowser.FileName

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$steamId = [Microsoft.VisualBasic.Interaction]::InputBox("Victims SteamID", "SteamID", "")

if ($steamId){
    $datePattern = '(\[\d{2}\/\d{2} \d{2}:\d{2}:\d{2}\]).*P:(.*) S:([0-9]+) \['
    $extraPattern = "Extra:(\d.*)x (.*?) (?<!moved )from Corpse of (.*)\[.*$steamId.*"

    $date = $null
    $output = @()

    $matches = Get-Content $filePath | ForEach-Object {
        $line = $_

        if ($line -match $datePattern) {
            $date = $Matches[1]
            $looter = $Matches[2]
            $looterid = $Matches[3]
        }
        elseif ($line -match $extraPattern) {
            $quantity = $Matches[1]
            $item = $Matches[2]
            $victim = $Matches[3]
            $entry = [PSCustomObject]@{
                Date = $date
                Quantity = $quantity
                Item = $item
                looter = $looter
                looterId = $looterid
            }
            $output += $entry
        } 
    }
    $writefile = (Get-Item $filePath ).DirectoryName
	$date = Get-Date –format 'yyyyMMdd_HHmmss'
    Write-Host ""
    Write-Host "Report saved to $writefile\$steamId-$date"".txt"
    "Items taken from $victim $steamId" > "$writefile\$steamId-$date.txt"
    $output | Format-Table -AutoSize | Out-File "$writefile\\$steamId-$date.txt" -append
	&notepad.exe "$writefile\\$steamId-$date.txt"
}
