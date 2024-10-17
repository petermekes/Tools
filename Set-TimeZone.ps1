# ---------------------------------------------------------------------------- #
# Author(s)    : Peter Mekes                                                   #
#                Original script from Koen Van den Broeck & Peter Klapwijk     #
# Version      : 1.0                                                           #
#                                                                              #
# Description  : Automatically configure the time zone                         #
#                                                                              #
# Notes:                                                                       #
# https://ipinfo.io/ has a limit of 50k requests per month without a license   #
#                                                                              #
# This script is provide "As-Is" without any warranties                        #
#                                                                              #
# ---------------------------------------------------------------------------- #

# Microsoft Intune Management Extension might start a 32-bit PowerShell instance. If so, restart as 64-bit PowerShell
If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    Try {
        &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH
    }
    Catch {
        Throw "Failed to start $PSCOMMANDPATH"
    }
    Exit
}

#region Functions
Function CleanUpAndExit() {
    Param(
        [Parameter(Mandatory=$True)][String]$ErrorLevel
    )

    # Write results to registry for Intune Detection
    $Key = "HKEY_CURRENT_USER\Software\$StoreResults"
    $NOW = Get-Date -Format "yyyyMMdd-hhmmss"

    If ($ErrorLevel -eq "0") {
        [microsoft.win32.registry]::SetValue($Key, "Success", $NOW)
    } else {
        [microsoft.win32.registry]::SetValue($Key, "Failure", $NOW)
        [microsoft.win32.registry]::SetValue($Key, "Error Code", $Errorlevel)
    }
    
    # Exit Script with the specified ErrorLevel
    EXIT $ErrorLevel
}
#endregion Functions


# ------------------------------------------------------------------------------------------------------- #
# Variables, change to your needs
# ------------------------------------------------------------------------------------------------------- #
$StoreResults = "TriFinance\TimeZone\v1.0"

# Start Transcript
Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$($(Split-Path $PSCommandPath -Leaf).ToLower().Replace(".ps1",".log"))" | Out-Null

$Error.Clear()
$IPInfo = Invoke-RestMethod http://ipinfo.io/json
$Location = $IPInfo.country

$xml_file = get-content "C:/Windows/Globalization/Time Zone/timezoneMapping.xml"
$xml_file = [xml]$xml_file

$Winid = $xml_file.Timezonemapping.MAPTZ | Where-Object Region -eq $Location
$TZ = $Winid.WinID
# $TZ = ""
If (![string]::IsNullOrEmpty($TZ))
{
Get-TimeZone -Id $TZ
Set-TimeZone -Id $TZ
}

If ($Error.Count -gt 0) {
    Write-Output "Failed to set the time zone: $($Error[0])"
    CleanUpAndExit -ErrorLevel 101
} else {
    Write-Output "Successfully set the time zone"
}

CleanUpAndExit -ErrorLevel 0

Stop-Transcript
