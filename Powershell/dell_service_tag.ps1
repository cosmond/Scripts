$ESXServers = Get-VMHost
$ESXServerView = $ESXServers | Get-View
$ESXInfo = @()
 
$oWeb = New-Object System.Net.WebClient
 
Foreach ($ESX in $ESXServers){
$TargetESXServerView = $ESXServerView | where {$_.MoRef -eq $ESX.Id}
$NewObj         = "" | Select Cluster, Name, Model, Version, BIOs, ServiceTag, AssetTag, ShipDate, ExpiryDate
$NewObj.Cluster = $ESX.Parent.Name
$NewObj.Name    = $ESX.Name
$NewObj.Model    = $ESX.Model
$NewObj.Version    = $ESX.Version
$NewObj.BIOs    = (($TargetESXServerView.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo | where {$_.Name -like "*BIOS*"  -and $_.SensorType -eq "Software Components"}).Name) -replace(".* BIOS ","") -replace(" .*","")
$NewObj.ServiceTag     = ($TargetESXServerView.hardware.systeminfo.OtherIdentifyingInfo | where {$_.IdentifierType.Key -eq "servicetag"}).identifierValue -replace(" ","")
$NewObj.AssetTag    = ($TargetESXServerView.hardware.systeminfo.OtherIdentifyingInfo | where {$_.IdentifierType.Key -eq "assettag"}).identifierValue -replace(" ","")
## Gets ServiceTag Info from Dell
#$oWeb = New-Object System.Net.WebClient
$ServiceTag = $null
If ($NewObj.ServiceTag -eq $null -or $NewObj.ServiceTag -eq "unknown" -or $NewObj.ServiceTag -eq "") {$ServiceTag = $NewObj.AssetTag} Else {$ServiceTag = $NewObj.ServiceTag}
$sUrl = "http://support.dell.com/support/topics/global.aspx/support/my_systems_info/details?c=us&l=en&s=gen&~ck=anavml&servicetag=$($ServiceTag)"
$sData = $oWeb.DownloadString($sUrl)
#get just the dates from the dell site.
$oRegEx = [regex]'\d{1,2}/\d{1,2}/\d{4}'
$cMatches = $oRegEx.Matches($sData)
#convert to a date object
$test = @()
foreach ($a in $cMatches){$Test += ([datetime]$a.Value)}
#Sort by the year
$datedata = $test | Sort-Object year
#Grab the earliest date for Shipdate
$ShipDate = ($Datedata[0]).toshortdatestring()
#Find the last object in the array
$cDates = ($Datedata.count) - 1
#Grab the latest date from the array for the warranty end date
$EndDate = ($Datedata[$cDates]).toshortdatestring()
## End Dell Site Code
$NewObj.ShipDate    = $ShipDate
$NewObj.ExpiryDate     = $EndDate
 
$ESXInfo += $NewObj
$ShipDate = $null
$EndDate = $null
}
$ESXInfo
