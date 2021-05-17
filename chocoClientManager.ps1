#
# Francesco Buresta Uniurb 2021 
#
# Chocolatey Remote Client Manager
#

function Get-InitialPrompt {
    Clear-Host
    Write-Host -ForegroundColor Cyan "================================================================="
    Write-Host -ForegroundColor Cyan "================ Chocolatey Remote Client Manager================"
    Write-Host -ForegroundColor Cyan "================================================================="
    $sharedFolder = Read-Host -Prompt 'Computer list filepath'
    $adminUser = Read-Host -Prompt 'Domain administrator username (domain\administrator)'
    $adminPw = Read-Host -Prompt 'Password'
    return @($sharedFolder, $adminUser, $adminPw)
}

function Get-Menu {
    param (
        [string]$psExec,
        [string]$adminUser,
        [string]$sharedFolder
    )
    Clear-Host
    Write-Host -ForegroundColor Cyan "================================================================="
    Write-Host -ForegroundColor Cyan "================ Chocolatey Remote Client Manager================"
    Write-Host -ForegroundColor Cyan "================================================================="
    Write-Host "Running $psExec to listed PCs $sharedFolder via $adminUser"
    Write-Host ""    
    Write-Host "1: Check only if choco is installed"
    Write-Host "2: Install choco if not installed"
    Write-Host "3: Upgrade all currently installed packages"
    Write-Host "4: Install new apps"
    Write-Host "X: Exit"
    Write-Host ""
    Write-Host "[ ctrl+C ] : Exit immediately" 
    Write-Host ""
}

function Start-ExecuteCmd {
    param (
        [string]$psExec,
        [string]$hname,
        [string]$adminUser,
        [string]$adminPw,
        [string]$comd
    )
    $r = & $psExec @('-accepteula', '-nobanner', "\\$hname", '-u', $adminUser, '-p', $adminPw, '-h', 'powershell.exe','-Noninteractive', '-Command', "$comd") 2>&1
    return $r
}

function Get-IsChocoInstalled {
    param (
        [string]$psExec,
        [string]$hname,
        [string]$adminUser,
        [string]$adminPw,
        [string]$comd
    )
    $isInstalled = Start-ExecuteCmd $psExec $hname $adminUser $adminPw $cmdChocoCheck
    if($isDebug) { Write-Host "[ DEBUG ] last operation" : $? }
    if($isDebug) { Write-Host "[ DEBUG ] last exit code" : $lastexitcode }
    if($lastexitcode){
        return @(0, '')
    }
    return @(1, $isInstalled[0])
}

$isDebug = $false

$arrGenerals = Get-InitialPrompt
$sharedFolder = $arrGenerals[0]
$adminUser = $arrGenerals[1]
$adminPw = $arrGenerals[2]

$psExec = "C:\psexec\PSTools\PsExec.exe"
$cmdChocoCheck = "choco -v"
$cmdChocoInstall = "Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://<local-repo>/install.ps1'))"
$cmdChocoUpgradeAll = "choco upgrade all"
$cmdChocoPkgInstall = "choco install -y"

do{
    Get-Menu $psExec $adminUser $sharedFolder
    $opt = Read-Host 'Choose an option'
    $files = Get-ChildItem $sharedFolder -Filter *.csv -File
    if($opt -ne 'X'){
        Foreach ($f in $files){
            if($isDebug) { Write-Host "[ DEBUG ] File" : $f.FullName }
            Foreach ($computer in Get-Content $f.FullName | Select-Object -Skip 1){
                $computerDetail = $computer.Split(',')
                if($isDebug){ Write-Host "[ DEBUG ] line" : $computer }
                if($isDebug){ Write-Host "[ DEBUG ] hostname" : $computerDetail[0] }
                $hname = $computerDetail[0]
                Write-Output "[ ACK ] Connecting to $hname"
                if (test-Connection -Cn $hname -quiet) {
                    Write-Host -ForegroundColor Green -BackgroundColor Black "[ LINK-UP ] Connected to $hname"
                    switch($opt){
                        '1'{
                            Write-Output "--- Check only if choco is installed ---"
                            $isInstalled = Get-IsChocoInstalled $psExec $hname $adminUser $adminPw $cmdChocoCheck
                            if(-not($isInstalled[0])){
                                Write-Host -ForegroundColor Red -BackgroundColor White "[ NONE ] Chocolatey not found"
                            }else{
                                Write-Host "[ SKIP ] Chocolatey already installed" : $isInstalled[1]
                            }
                        }
                        '2'{
                            Write-Output "--- Install choco if not installed ---"
                            $isInstalled = Get-IsChocoInstalled $psExec $hname $adminUser $adminPw $cmdChocoCheck
                            if(-not($isInstalled[0])){
                                Write-Output "[ INST ] Installing Chocolatey to $hname"
                                $isInstalled = Start-ExecuteCmd $psExec $hname $adminUser $adminPw $cmdChocoInstall
                                if($isDebug) { Write-Host "[ DEBUG ] last operation" : $? }
                                if($isDebug) { Write-Host "[ DEBUG ] last exit code" : $lastexitcode }
                                if(-not($lastexitcode)){
                                    Write-Host "[ OK ] Install completed"
                                }else{
                                    Write-Host -ForegroundColor Red -BackgroundColor White "[ FAIL ] Failed to install Chocolatey"
                                }
                            }else{
                                 Write-Host "[ SKIP ] Chocolatey already installed" : $isInstalled[1]
                            }
                        }
                        '3'{
                            Write-Output "--- Upgrade all currently installed packages ---"
                            $isInstalled = Get-IsChocoInstalled $psExec $hname $adminUser $adminPw $cmdChocoCheck
                            if(-not($isInstalled[0])){
                                Write-Output "[ NONE ] Chocolatey not found, nothing to do"
                            }else{
                                $isInstalled = Start-ExecuteCmd $psExec $hname $adminUser $adminPw $cmdChocoUpgradeAll
                                if($isDebug) { Write-Host "[ DEBUG ] last operation" : $? }
                                if($isDebug) { Write-Host "[ DEBUG ] last exit code" : $lastexitcode }
                                if(-not($lastexitcode)){
                                    Write-Host "[ OK ] Upgrade completed"
                                }else{
                                    Write-Host -ForegroundColor Red -BackgroundColor White "[ FAIL ] Upgrade failed"
                                }
                            }
                        
                        }
                        '4'{
                             Write-Output "--- Install new app from file ---"
                            $isInstalled = Get-IsChocoInstalled $psExec $hname $adminUser $adminPw $cmdChocoCheck
                            if(-not($isInstalled[0])){
                                Write-Output "[ NONE ] Chocolatey not found, nothing to do"
                            }else{
                                $pkg = Read-Host -Prompt 'Packages to install (space separated) or remote reachable file (*.config) which contains pkg list'
                                $xec = Start-ExecuteCmd $psExec $hname $adminUser $adminPw "$cmdChocoPkgInstall $pkg"
                                if($isDebug) { Write-Host "[ DEBUG ] last operation" : $? }
                                if($isDebug) { Write-Host "[ DEBUG ] last exit code" : $lastexitcode }
                                if(-not($lastexitcode)){
                                    Write-Host "[ OK ] Packages installed"
                                }else{
                                    Write-Host -ForegroundColor Red -BackgroundColor White "[ FAIL ] Failed to install package $pkg"
                                }
                            }
                        }
                    }
                }else{
                    Write-Host -ForegroundColor Yellow -BackgroundColor Black "[ LINK-DOWN ] Unable to connect to $hname"
                }
            }
        }
    }else{
		Write-Output "Preparing to quit ..."
		Write-Output "Deleting files from $sharedFolder"
		if($isDebug) { 
			Get-ChildItem $sharedFolder -Include *.csv -Recurse | Remove-Item -WhatIf
		}else{
			Get-ChildItem $sharedFolder -Include *.csv -Recurse | Remove-Item -ErrorAction Ignore
		}
		if($?){
			Write-Output "[ OK ] Deleted successfully" 
		}else{
			Write-Output "[ FAIL ] Unable to delete files"
		}
	}
    pause
} until ($opt -eq 'X')
