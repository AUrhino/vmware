<#
.SYNOPSIS
  This script will connect to Vsphere and capture VM details for audit purposes.
  
.DESCRIPTION
  See above
  This should run from a host that can connect to vSphere
  
.INPUTS
  Will prompt for vshere creds and machine name
  
.OUTPUTS
  Will write to the screen
  
.NOTES
  Version:        1.0
  Author:         Ryan Gillan
  Creation Date:  07-Feb-2022
  
.EXAMPLE
   get-help ./Dump_VM_details.ps1
  
  #Run via:
  .\Dump_VM_details.ps1

#Input Credentials
$path = "."  #Path where script is
$vi_server = "VSPHERE_HOSTNAME"
$Protocol = "https"
$VM_User = "USERNAME"
$VM_Password = "PASSWORD"

$credential = "svc_vsphere_RO" #The first name entered into the credential script
$VM_filename = "VMware-VMs.csv"
#$vmware_physical_servers = $path + $VMHost_Filename
$vmware_vms = $VM_filename

$SMTPserver = "mailhost"
$SMTPSubject = "VMware server list"
$SMTPfrom = "from@email.com"
$SMTPto = "to@email.com"


# To capture the commands and messages, uncomment the following 3 lines:
#$DebugPreference = "Continue"
#$VerbosePreference = "Continue"
#$InformationPreference = "Continue"

try {
  Write-debug "Connecting to vCenter, please wait.."
  Connect-ViServer -server $vi_server -Protocol https -User $VM_User -Password $VM_Password | Out-Null
  #add VMtools details
  New-VIProperty -Name ToolsVersion -ObjectType VirtualMachine -ValueFromExtensionProperty 'Config.tools.ToolsVersion' -Force
  New-VIProperty -Name ToolsVersionStatus -ObjectType VirtualMachine -ValueFromExtensionProperty 'Guest.ToolsVersionStatus' -Force
  if ($? -eq $false) {throw $error[0].exception}
}
catch [Exception]{
  $status = 1
  $exception = $_.Exception
  Write-debug "Could not connect to vCenter. Sending error to hc.gsoa.ddau"
  Send-MailMessage -smtpServer $SMTPserver -from $SMTPfrom -to $SMTPto -subject "Issue connecting to vsphere from Vmware audit script" $exception.message
}


#===================== VM Guest Data=========================================================
Get-VM  | Select @{N="VM Name";E={$_.Name}},
@{N="ID"; E={$_.PersistentId}},
@{N='IP Address';E={($_.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork})  }},
@{N="VM vmomi";E={$_.Id}},
@{N="Folder";E={$_.Folder}},
@{N="Guest";E={$_.Guest}},
@{N="ResourcePool";E={$_.ResourcePool}},
@{N="Power State";E={$_.PowerState}},
@{N='Network Vlan';Expression={($_ | Get-NetworkAdapter).NetworkName}},
@{N="CPU (Cores)";E={$_.NumCpu}},
@{N="RAM (GB)";E={$_.MemoryGB}},
@{N="Disk (GB)"; E={[math]::round($_.ProvisionedSpaceGB)}},
@{N='Disk Path';Expression={($_ | Get-HardDisk).Filename}},
@{N='Disk Persistence';Expression={($_ | Get-HardDisk).Persistence}},
@{N="Datastore";E={Get-Datastore -VM $_}},
@{N="Operating System";E={$_.Guest.OsFullName}},
@{N='Resource Pool';Expression={($_ | Get-ResourcePool).name}} | Export-Csv $vmware_vms -UseCulture -Encoding UTF8 -NoTypeInformation

# Finished. Disconnecting and sending email
disconnect-viserver -Server * -confirm:$false
Send-MailMessage -smtpServer $SMTPserver -from $SMTPfrom -to $SMTPto -subject $SMTPsubject -attachments $vmware_vms
