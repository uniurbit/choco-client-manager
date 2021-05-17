#
# Francesco Buresta UniUrb 2021
# 
# Get AD Computer from choosen OU then output into file.
#

$isDebug = $false

$ou = @()
$i = 1
Get-ADOrganizationalUnit -Filter 'Name -like "*" -and Name -notlike "OU_*"' | Sort-Object -Property Name | Foreach {
    $item = [PSCustomObject]@{
        id = $i
        name = $_.Name.Replace(" ","_")
        dn = $_.DistinguishedName.Replace(" ","_")
    }
    $ou += $item
    $i++
}

function Get-InitialPrompt {
    param (
        [Array]$ou
    )
    
    Clear-Host
    For ($i = 0; $i -lt $ou.Count; $i++){
        Write-Host "$($ou[$i].id): $($ou[$i].name)"
    }
    Write-Host "X: Exit"
    Write-Host ""
    Write-Host "[ ctrl+C ] : Exit immediately" 
    Write-Host ""
}

$sharedFolder = "C:\shared_choco"
do {
    Get-InitialPrompt($ou)
    $opt = Read-Host 'Choose an option'
    if($opt -ne 'X'){
        $sel = $opt-1
        Write-Host "Querying ... $($ou[$sel].dn)"
        $pattern = $($ou[$sel].dn).Replace("OU=", "#")
        $pattern = $pattern.Replace("DC=example,DC=org", "")
        $pattern = $pattern.Replace(",", "")
        $arrExploded = $pattern.Split("#")
        [Array]::Reverse($arrExploded)
        $pathToCreate = $arrExploded -join '\'
        $fullPath = $("$sharedFolder\$pathToCreate")
        if(-not(Test-Path -Path $fullPath)) {
            Write-Host "[ INFO ] Making folder path" : $fullPath
            if($isDebug) { 
                New-Item -ItemType Directory -Path $fullPath -Force -Confirm:$false -WhatIf 
            }else{
                New-Item -ItemType Directory -Path $fullPath -Force -Confirm:$false -ErrorAction Ignore
            }
        }
        if(Test-Path -Path $fullPath) {
            $filePath = "$fullPath\list-$($ou[$sel].name).csv"
            Write-Host "OU" : $($ou[$sel].name)
            Write-Host "Output file" : $filePath
            Get-ADComputer -SearchBase $($ou[$sel].dn) -Filter 'operatingsystem -notlike "*server*" -and enabled -eq "true"' -Properties Name,Operatingsystem,OperatingSystemVersion,IPv4Address | Select-Object -Property Name,IPv4Address | ConvertTo-Csv -NoTypeInformation | % { $_ -replace '"', ""}  | out-file $filePath -fo -en utf8
        }else{
            Write-Output "[ ERR ] Failed to create folder path"
        }
    }
    pause
} until ($opt -eq 'X')



