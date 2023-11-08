$subs = get-azsubscription
$results = @()


foreach ($SUB in $subs) {
    Set-AzContext -subscription $sub.Id
    $VMs = Get-AzVm
    foreach ($VM in $VMs)
    {
        [Hashtable]$VMTag = (Get-AzVM -ResourceGroupName $VM.ResourceGroupName -Name  $VM.Name).Tags
        foreach ($h in $VMTag.GetEnumerator()) {
        if (($h.Name -eq "Owner"))
            {
                Write-host "VM" $VM.Name "Owner" $h.value
                $results += [PSCustomObject]@{
                    'VM'        = $vm.Name
                    'Sub' = $SUB
                    'Owner' = $h.Value
                   
                }
            }
        }
    }
}

$results | Export-Csv -Path 'vm_owners.csv' -NoTypeInformation