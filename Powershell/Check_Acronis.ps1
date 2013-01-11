# Check_acronis.ps1 [function] [path]
# Check something and return it to Zabbix.
# Failure sends 999 
#
param(
[parameter(Mandatory = $True)]
[string]$function,
[parameter(Mandatory = $True)]
[string]$filepath,
[parameter(Mandatory = $True)]
[string]$Key
)

$global:Zabbix_send = "C:\zabbix\zabbix_sender.exe -c C:\zabbix\zabbix_agentd.conf"

Function Send_Zabbix {
# Sends Keys to Zabbix
#Expects [string]$key,int[value] with $global:Zabbix_send to be set to the valid path / args

    param (
        [parameter(mandatory=$true)]
        $key,
        
        [parameter(mandatory=$true)]
        [int64]$value
    )
    echo "$key : $value"
	$cmd = "$Zabbix_send -k `"$key`" -o  `"$value`""
	echo "$cmd"
    Invoke-Expression $cmd 
    
}
Function Dir_Size {

    #$Key= "Acronis_dir_size"

    if ($filepath -isnot [string]) {
        Write-Host “ERROR: You must specify a file path!” `
        -foregroundcolor “RED” -backgroundcolor “Black”;`
        $Value=999
        Send_Zabbix $Key $Value 
        return
    }
    #verify $file exists as a path

    if (Test-Path $filepath) {

        $file=dir $filepath\*.tib | Sort-Object CreationTime
        $size = $file | Measure-Object -property length -sum
    	$Value = $size.sum
        Send_Zabbix $Key $Value
    }
    else 
    {
        Write-Host “Failed to find” $filepath.ToUpper() -foregroundcolor “Red” -backgroundcolor “Black”
        $Value=999
        Send_Zabbix $Key $Value
        
    }

} #End Dir Size Function
Function File_Age {
    #$Key= "Acronis_file_age"

    if ($filepath -isnot [string]) {
        Write-Host “ERROR: You must specify a file path!” `
        -foregroundcolor “RED” -backgroundcolor “Black”;`
        $Value=999
        Send_Zabbix $Key $Value 
        return
    }
    #verify $file exists as a path

    if (Test-Path $filepath) {

        $file=dir $filepath\*.tib | Sort-Object CreationTime
        $time = New-TimeSpan $($file[-1].LastWriteTime) $(get-date)
        $Value = $time.totalhours
        Send_Zabbix $Key $Value
    }
    else 
    {
        Write-Host “Failed to find” $filepath.ToUpper() -foregroundcolor “Red” -backgroundcolor “Black”
        $Value=999
        Send_Zabbix $Key $Value
        
    }
}

#### Starting here.... 
switch ($function)  { 
        File_Age {File_Age $filepath $Key} 
        Dir_Size {Dir_Size $filepath $Key} 
        default {"The function couldn't be determined, Options are File_Age and Dir_Size"}
    }