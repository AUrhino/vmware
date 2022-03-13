Connect-VIServer -Server hostname.fqdn -User $YourU -Password $YourP -Protocol https -WarningAction SilentlyContinue
Get-VM | where {$_.PowerState -eq 'PoweredOn' } | Sort-Object -Property name `
| Get-NetworkAdapter | Where-object { -not $_.ConnectionState.StartConnected } `
| Select @{N='VM';E={$_.Parent.Name}},Name,NetworkName,ConnectionState `
| Export-Csv –path c:\temp\VM_with_nic_issues.csv -NoTypeInformation -UseCulture `
disconnect-viserver * -confirm:$false
