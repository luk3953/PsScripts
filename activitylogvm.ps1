# Set a threshold for the duration
$daysOfDuration = 30
$endTime = Get-Date
$startTime = (Get-Date).AddDays(-$daysOfDuration)
$WarningPreference = 'SilentlyContinue'
# Get all subscriptions
$subscriptions = Get-AzSubscription

$results = @()

foreach ($subscription in $subscriptions) {
    # Set the active subscription context
    Set-AzContext -Subscription $subscription.Id

    # Get all VMs in the current subscription
    $vms = Get-AzVM

    foreach ($vm in $vms) {
        # Fetch the VM metrics
        $cpuMetrics = Get-AzMetric -ResourceId $vm.Id -MetricName "Percentage CPU" -StartTime $startTime -EndTime $endTime -AggregationType Average
        $diskReadMetrics = Get-AzMetric -ResourceId $vm.Id -MetricName "Disk Read Bytes" -StartTime $startTime -EndTime $endTime -AggregationType Average
        $diskWriteMetrics = Get-AzMetric -ResourceId $vm.Id -MetricName "Disk Write Bytes" -StartTime $startTime -EndTime $endTime -AggregationType Average

        # Calculate averages
        $averageCpu = ($cpuMetrics.Data | Measure-Object -Property Average -Average).Average
        $averageDiskRead = ($diskReadMetrics.Data | Measure-Object -Property Average -Average).Average
        $averageDiskWrite = ($diskWriteMetrics.Data | Measure-Object -Property Average -Average).Average

        # Create a custom object with the metrics and add it to results
        $results += [PSCustomObject]@{
            'VM'        = $vm.Name
            'CPU'       = $averageCpu
            'DiskRead'  = $averageDiskRead
            'DiskWrite' = $averageDiskWrite
        }
    }
}