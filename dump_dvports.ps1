# Connect to your vCenter server
Connect-VIServer -Server <vcsa.fqdn> -User <username> -Password <password>

Get-ResourcePool CDMs |
Get-VM | ForEach-Object {
    $vm = $_
    Get-NetworkAdapter -VM $vm | ForEach-Object {
        $adapter = $_
        $portgroup = Get-VDPortgroup -NetworkAdapter $adapter
        if ($portgroup.Name -like "*dv-CUST*") {
            [PSCustomObject]@{
                'VM Name' = $vm.Name
                'VLAN ID' = $portgroup.ExtensionData.Config.DefaultPortConfig.Vlan.VlanId
                'Network Name' = $portgroup.Name
            }
        }
    }
}

|ft -auto 
