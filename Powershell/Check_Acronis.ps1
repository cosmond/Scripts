# Check_acronis.ps1 [function] [path]
# Check something and return it to Zabbix.
# Failure sends 999 
#
param(
[parameter(Mandatory = $True)]
[string]$function,
[parameter(Mandatory = $False)]
[string]$filepath
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

    $Key= "Acronis_dir_size"

    if ($filepath -isnot [string]) {
        Write-Host "ERROR: You must specify a file path!" `
        -foregroundcolor "RED" -backgroundcolor "Black";`
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
        Write-Host "Failed to find" $filepath.ToUpper() -foregroundcolor "Red" -backgroundcolor "Black"
        $Value=999
        Send_Zabbix $Key $Value
        
    }

} #End Dir Size Function
Function File_Age {
    $Key= "Acronis_file_age"

    if ($filepath -isnot [string]) {
        Write-Host "ERROR: You must specify a file path!" `
        -foregroundcolor "RED" -backgroundcolor "Black";`
        $Value=999
        Send_Zabbix $Key $Value 
        return
    }
    #verify $file exists as a path

    if (Test-Path $filepath) {

        $file=dir $filepath\*.tib | Sort-Object CreationTime
        $time = New-TimeSpan $($file[-1].LastWriteTime) $(get-date)
        $Value = $time.hours
        Send_Zabbix $Key $Value
    }
    else 
    {
        Write-Host "Failed to find" $filepath.ToUpper() -foregroundcolor "Red" -backgroundcolor "Black"
        $Value=999
        Send_Zabbix $Key $Value
        
    }
}
Function Replication_Age {
                $Key= "AD_Replication_Age"
                $result = repadmin /showrepl * /csv| ConvertFrom-Csv | sort-object 'Last Success Time'| Select-Object 'Last Success Time' 
                $lastrep = New-TimeSpan $($result[0].'Last Success Time') $(get-date)
                $Value = [int]$lastrep.TotalMinutes
                Write-Host "$Value - Last successful Replication"
                Send_Zabbix $Key $Value
}

Function File_Info {
param (
        [parameter(mandatory=$true)]
        $filename
)
        

    if ($filename -isnot [string]) {
        Write-Host "ERROR: You must specify a file and name" `
        -foregroundcolor "RED" -backgroundcolor "Black";`
	$Key = "$($file.Basename)_Age"
        $Value=999
        Send_Zabbix $Key $Value 
	$Key = "$($file.Basename)_Size"
	Send_Zabbix $Key $Value
        return
    }
    #verify $file exists as a path

    if (Test-Path $filename) {
        $file=dir $filename 
        $Key = "$($file.Basename)_Age"
        $time = New-TimeSpan $($file.LastWriteTime) $(get-date)
        $Value = [int]$time.TotalHours
        Send_Zabbix $Key $Value
        $Key = "$($file.Basename)_Size"
        $Value = [int]$($file.Length / 1MB)
	Send_Zabbix $Key $Value
        
    }
    else 
    {
        Write-Host "Failed to find" $filepath.ToUpper() -foregroundcolor "Red" -backgroundcolor "Black"
        $Value=999
        Send_Zabbix $Key $Value
        
    }
}

Function Mbox_Count {
    param (
        [parameter(mandatory=$true)]
        $mailbox
    )
    # Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin -- Should be done via remote Powershell but who got time for that?
    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue
    if ($mailbox_stats=get-mailboxstatistics $mailbox) {
        $Key = "${mailbox}_Count"
        $Value = [int]$mailbox_stats.ItemCount
        Write-Host "Send_Zabbix $Key $Value"
    }
    else {
        $Key = "${mailbox}_Count"
        $Value = 999
        #Send_Zabbix $Key $Value
        Write-Host 
    }
    
}

#### Starting here.... 
switch ($function)  { 
        File_Age {File_Age $filepath} 
        Dir_Size {Dir_Size $filepath} 
        Replication_Age {Replication_Age}
        File_Info {File_Info $filepath}
        Mbox_Count {Mbox_Count $mailbox}
        default {"The function couldn't be determined, Options are File_Age, Dir_Size, Replication_Age, File_Info <filename>, or Mbox_Count <mailbox>"}
}
