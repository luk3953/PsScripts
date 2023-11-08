# Set a threshold for analysis
$daysOfAnalysis = 30
$analysisEndTime = Get-Date
$analysisStartTime = $analysisEndTime.AddDays(-$daysOfAnalysis)
$WarningPreference = 'SilentlyContinue'
# CSV File Output
$outputFile = "StorageAccountsMetrics.csv"

# Create an array to hold the results
$results = @()

# Get all subscriptions
$subscriptions = Get-AzSubscription

foreach ($subscription in $subscriptions) {
    # Set the active subscription context
    Set-AzContext -Subscription $subscription.Id

    # Get all storage accounts in the current subscription
    $storageAccounts = Get-AzStorageAccount

    foreach ($account in $storageAccounts) {
        # Fetch metrics
        Write-Output "Processing: $($account.StorageAccountName)"
       
        # Example for Used Capacity Metric
        $usedCapacityMetric = Get-AzMetric -ResourceID $account.ID -MetricName "UsedCapacity" -StartTime $analysisStartTime -EndTime $analysisEndTime 
        $usedCapacityValues = $usedCapacityMetric.Data.Average | Where-Object { $_ -ne $null }
        $usedCapacityAvg = ($usedCapacityValues | Measure-Object -Sum).Sum / $usedCapacityValues.Count
       
        # Similarly for other metrics
        $IngressValues = (Get-AzMetric -ResourceID $account.ID -MetricName "Ingress" -StartTime $analysisStartTime -EndTime $analysisEndTime).Data.Average | Where-Object { $_ -ne $null }
        $ingressSum = ($IngressValues | Measure-Object -Sum).Sum / $IngressValues.Count
   
        $transactionsValues = (Get-AzMetric -ResourceID $account.ID -MetricName "Transactions" -StartTime $analysisStartTime -EndTime $analysisEndTime).Data.Sum | Where-Object { $_ -ne $null }
        $transactionsSum = ($transactionsValues | Measure-Object -Sum).Sum
   
        $EgressValues = (Get-AzMetric -ResourceID $account.ID -MetricName "Egress" -StartTime $analysisStartTime -EndTime $analysisEndTime).Data.Average | Where-Object { $_ -ne $null }
        $egressSum = ($EgressValues | Measure-Object -Sum).Sum / $EgressValues.Count
   

        # Calculate average values
        # Create a result object and add it to the results array
        $result = [PSCustomObject]@{
            "StorageAccountName"  = $account.StorageAccountName
            "ResourceGroupName"   = $account.ResourceGroupName
            "Location"            = $account.Location
            "AverageUsedCapacity" = $usedCapacityAvg
            "TotalTransactions"   = $transactionsSum
            "Ingress" = $ingressSum
            "Egress" = $egressSum
            "AccessTier"          = $account.AccessTier  # Access tier added here
        }
        $results += $result
    }
}    

# Export the results to a CSV file
$results | Export-Csv -Path $outputFile -NoTypeInformation

Write-Host "Exported metrics to $outputFile"