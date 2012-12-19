# Create a predefined folder layout and assign permissions to the shares.
# Expects the group to already exist
# .. Folder,Group format for $Directories

$Path = '\\192.168.35.10\Common\Projects'

$Project = Read-Host 'Please enter the Job and Project Name'
Write-Host "Creating directories for $Path\$Project"

$Directories = @(
	("1. Estimating", "Administration"),
	("2. Contract", "Administration"),
	("3. CCO", "Administration"),
	("4. Billing", "Administration"),
	("10. Drawings", "Field"),
	("11. Specifications", "Field"),
	("12. Scheduling", "Field"),
	("13. Minutes", "Field"),
	("14. RFI", "Field"),
	("15. Site Instructions", "Field"),
	("16. Approved CCO", "Field"),
	("17. T&M - Work Orders", "Field"),
	("20. Electrical Shop Drawings", "Field"),
	("21. General Shop Drawings", "Field"),
	("30. Sub-Contractors", "Field")
)

if (!(test-path $Path\$Project))
    {
		New-Item -itemtype "Directory" -path $Path -name $Project -force
        foreach ($FolderName in $Directories)
		{
			#Write-Host $FolderName[0]
			New-Item -itemtype "Directory" -path  $Path\$Project -name $FolderName[0] -force
			$ACL = Get-ACL "$Path\$Project\$($FolderName[0])"
			$FileSystemRights=[System.Security.AccessControl.FileSystemRights]"FullControl"
			$AccessControlType =[System.Security.AccessControl.AccessControlType]"Allow"
			$InheritanceFlags = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
			$PropagationFlags = [System.Security.AccessControl.PropagationFlags]"InheritOnly"
			$Perm = "Metricelectric.local\$($FolderName[1])",$FileSystemRights, $InheritanceFlags, $PropagationFlags, $AccessControlType
			$ACLRule = New-Object System.Security.AccessControl.FileSystemAccessRule $Perm
			$ACL.SetAccessRule($ACLRule)
			Set-Acl "$Path\$Project\$($FolderName[0])" $ACL
			Write-Host "Granted perms for $($FolderName[0]) to $($FolderName[1])"
			}
	}	
