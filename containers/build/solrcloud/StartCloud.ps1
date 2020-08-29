param(
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ -PathType 'Container' })]
    [string]$InstallPath,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ -PathType 'Container' })]
    [string]$DataPath,
	
	[int]$SolrPort = 8983
)


$dataFolderEmpty = ($null -eq (Get-ChildItem -Path $DataPath -Filter "solr.xml"))
if ($dataFolderEmpty)
{
    Write-Host "INFO: SolrCloud configuration not found in '$DataPath', copying clean configuration..."

	Copy-Item "$InstallPath\server\solr\solr.xml" "c:\data"
	Copy-Item "$InstallPath\server\solr\zoo.cfg" "c:\data"

	Write-Host "INFO: Triggering background execution of collection creation..."
	
	# The create process starts in the background, so it can wait for Solr to start and then do its processing
    Start-Process "powershell.exe" -ArgumentList "-f","C:\Cloud\MakeCollections.ps1 $SolrPort localhost C:\Cloud\Collections.txt" -NoNewWindow
}
else
{
    Write-Host "INFO: Existing SolrCloud configuration found in '$DataPath'..."
}

c:\solr\bin\solr.cmd start -port $SolrPort -f -c