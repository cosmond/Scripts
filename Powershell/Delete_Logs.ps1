# File Cleaning process...
# Chad Osmond <chad.osmond@compfitness.com >
# 2010-04-28 
# Delete files matching a specific glob in a specific directory (Log files, stale files, etc..)
# C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe D:\IISLogs\clean_wss-block.ps1


# max_age = Number of days in age for a file 
# dir_to_clean = Directory to clean up
# Partern = File Glob to match..
# Descend = 0 or 1  - Do you want to descend into directories



$max_age = 10
$dir_to_clean = "F:\IISLogs\W3SVC"
$pattern = "ex*.log"
$descend = 0 
$debug = 0

######################
# End of editable items
######################

# Ensure the we're looking at a directory that is atlease X:\XXX or longer
if ($dir_to_clean.length -lt 6) {write-host Aborting because  $dir_to_clean seems too short? ; break}


#####
# Cleaning Function Check that we've been passed Directory, Age, and Pattern. Then get a list of files in that directory,
# if they're not a directory, and we've found files, then go ahead and clean them out.
#####

Function Clean_Dir {
    param (
        [parameter(mandatory=$true)]
        $dir_to_clean, 
        
        [parameter(mandatory=$true)]
        [int64]
        $max_age, 
        
        [parameter(mandatory=$true)]
        $pattern
        )
    if ($debug -gt 0 ) {write-host Cleaning $dir_to_clean with an age of $max_age and pattern of $pattern}
    #Begin Function to clean directories
    $files = Get-ChildItem $dir_to_clean 
    if ($files -and $files.Count  -gt 0)
        {
        foreach ($file in $files)
           { 
            if ($file.PsISContainer -ne $True) # Ignore Directories 
            {
                $age = ((Get-Date) - $file.Creationtime).Days 
                  if ( $age -gt $max_age -and $file.PsISContainer -ne $True -and $file -like $pattern) 
                  {
                  if ($debug -gt 0 ) {write-host $file was found and is $age  days old}
                  #$file.Delete()
                  if ($debug -gt 0 ) {write-host $file was deleted}
                  }
                }
            }
        }
}


if ($descend -eq 0) 
 { 
 Clean_Dir $dir_to_clean $max_age $pattern 
 }


if ($descend -eq 1)
    { $dirs = Get-ChildItem $dir_to_clean -recurse | where-object {$_.PSISContainer -eq "True" }
      foreach ($dir in $dirs)
        { 
        write-host Cleaning $dir.fullname 
        Clean_Dir $dir.FullName $max_age $pattern 
        }
    }
