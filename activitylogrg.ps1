# activitylogrg.ps1
# Set a threshold for inactivity
$daysOfInactivity = 30

$inactivityThreshold = (Get-Date).AddDays(-$daysOfInactivity)
# Get all resource groups
$resourceGroups = Get-AzResourceGroup
$subs = Get-AzSubscription
$inactiveResourceGroups = @()
$WarningPreference = 'SilentlyContinue'

foreach ($sub in $subs) {
    # Set the active subscription context
    Set-AzContext -subscription $sub.Id

    # Get all resource groups in the current subscription
    $resourceGroups = Get-AzResourceGroup

    $inactiveResourceGroups = @()

    foreach ($rg in $resourceGroups) {
        # Get activity logs for the resource group within the threshold
        $activityLogs = Get-AzActivityLog -ResourceGroupName $rg.ResourceGroupName -StartTime $inactivityThreshold

        # If no logs are returned for the duration, the RG is considered inactive
        if (-not $activityLogs) {
            $inactiveResourceGroups += $rg
        }
    }

    # Display the inactive resource groups for the current subscription
    $inactiveResourceGroups | ForEach-Object {
        Write-Host ("Subscription: " + $sub.Name + " | Resource Group: " + $_.ResourceGroupName + " has had no activity for the past " + $daysOfInactivity + " days.")
    }
}

$inactiveResourceGroups | Export-Csv -Path 'rg_activity.csv' -NoTypeInformation