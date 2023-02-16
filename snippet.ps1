$cleanScriptPath = "C:\k\antrea_cleanup.ps1"
"stop-service antrea-agent -ErrorAction SilentlyContinue; C:\k\antrea\Clean-AntreaNetwork.ps1" | Out-File $cleanScriptPath -encoding ascii

if (Test-Path "C:\k\antrea\Clean-AntreaNetwork.ps1") {
    $method = "Shutdown"
    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy"
    $RegScriptsPath = "$RegPath\Scripts\$method\0"
    $RegSmScriptsPath = "$RegPath\State\Machine\Scripts\$method\0"
    # Create the path if not exist
    $gpoPath = "$ENV:systemRoot\System32\GroupPolicy\Machine"
    $methodPath = "$gpoPath\Scripts\$method"
    if (-not (Test-Path $methodPath)) {
        New-Item -path $methodPath -itemType Directory
    }
    # Create sub-path
    $items = @("$RegScriptsPath\0", "$RegSmScriptsPath\0")
    foreach ($item in $items) {
        if (-not (Test-Path $item)) {
            New-Item -path $item -force
        }
    }
    # Register callback script to GPO
    $items = @("$RegScriptsPath", "$RegSmScriptsPath")
    foreach ($item in $items) {
        New-ItemProperty -path "$item" -name DisplayName -propertyType String -value "Local Group Policy" -force
        New-ItemProperty -path "$item" -name FileSysPath -propertyType String -value "$gpoPath" -force
        New-ItemProperty -path "$item" -name GPO-ID -propertyType String -value "LocalGPO" -force
        New-ItemProperty -path "$item" -name GPOName -propertyType String -value "Local Group Policy" -force
        New-ItemProperty -path "$item" -name PSScriptOrder -propertyType DWord -value 2 -force
        New-ItemProperty -path "$item" -name SOM-ID -propertyType String -value "Local" -force
    }
    $BinaryString = "00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00"
    $ExecTime = $BinaryString.Split(',') | ForEach-Object {"0x$_"}
    $items = @("$RegScriptsPath\0", "$RegSmScriptsPath\0")
    foreach ($item in $items) {
        New-ItemProperty -path "$item" -name Script -propertyType String -value $cleanScriptPath -force
        New-ItemProperty -path "$item" -name Parameters -propertyType String -value $method -force
        New-ItemProperty -path "$item" -name IsPowershell -propertyType DWord -value 1 -force
        New-ItemProperty -path "$item" -name ExecTime -propertyType Binary -value ([byte[]]$ExecTime) -force
    }
}