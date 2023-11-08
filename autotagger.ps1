# Fetch details of the specified resource groups
$resourceGroups = Get-AzResourceGroup | Where-Object { $_.Tags -ne $null -and $_.Tags.Count -gt 0 }
$allResources = Get-AzResource

foreach ($rg in $resourceGroups) {
    $rgTags = $rg.Tags

    # Filter resources based on ResourceGroupName without making another API call
    $resourcesInRG = $allResources | Where-Object { $_.ResourceGroupName -eq $rg.ResourceGroupName }

    foreach ($resource in $resourcesInRG) {

        # Initialize newTags based on resource's current tags or create a new hashtable if there are no tags
        $newTags = if ($resource.Tags) { $resource.Tags } else { @{} }

        # Identify the missing tags from the resource group
        $missingTags = $rgTags.Keys | Where-Object { -not $newTags.ContainsKey($_) }

        if ($missingTags.Count -gt 0) {
            # Add the missing tags from the resource group to the resource's tags
            foreach ($tag in $missingTags) {
                $newTags[$tag] = $rgTags[$tag]
            }

            # Overwrite the tags on the resource using New-AzTag
            New-AzTag -ResourceId $resource.Id -Tag $newTags
        }

        # Output the tags for the resource
        Write-Host ("Resource: " + $resource.Name)
        foreach ($tag in $newTags.GetEnumerator()) {
            Write-Host ("`tTag Key: " + $tag.Key + " | Value: " + $tag.Value)
        }
    }
}