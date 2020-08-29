param
(
    [string]$solrPort = "44011",
    [string]$solrName = "localhost",
    [string]$collectionNamesFile
)

function Test-SolrConfigSetExists
{
    param(
        [string]$solrHost,
        [int]$solrPort,
        [string]$configSetName
    )
    
    $url = "http://$($solrHost):$solrPort/solr/admin/configs?action=LIST"
    
    $result = Invoke-WebRequest -UseBasicParsing -Uri $url
    $match = $result.Content.Contains("`"$configSetName`"")
    
    return $match
}

function Upload-SolrConfigSet
{
    param(
        [string]$solrHost,
        [int]$solrPort,
        [string]$zipFile,
        [string]$configName
    )

    $exists = Test-SolrConfigSetExists $solrHost $solrPort $configName

    if( $exists -ne $true )
    {
        Write-Host "Uploading config set $configName"

        # https://lucene.apache.org/solr/guide/7_2/configsets-api.html
        $uri = "http://$($solrHost):$solrPort/solr/admin/configs?action=UPLOAD&name=$configName"

        Invoke-RestMethod -Uri $uri -Method Post -InFile $zipFile -ContentType "application/octet-stream" | Out-Null
    }
    else
    {
        Write-Host "Config set $configName exists - skipping"
    }
}

function Upload-SolrCollectionConfig
{
    param(
        [string]$solrFolder,
        [string]$coreConfigFolder,
        [string]$coreConfigName,
        [string]$zkConnStr
    )

    Write-Host "Uploading Solr core config for $coreConfigName"

    $solrCmd = "$solrFolder\bin\solr.cmd"

    & $solrCmd zk upconfig -d $coreConfigFolder -n $coreConfigName -z $zkConnStr
}
#

function Test-SolrCollectionExists
{
    param(
        [string]$solrHost,
        [int]$solrPort,
        [string]$solrCollectionName
    )

    $url = "http://$($solrHost):$solrPort/solr/admin/collections?action=LIST"
    
    $result = Invoke-WebRequest -UseBasicParsing -Uri $url
    $match = $result.Content.Contains("`"$solrCollectionName`"")
    
    return $match
}

function Test-SolrAliasExists
{
    param(
        [string]$solrHost,
        [int]$solrPort,
        [string]$solrAliasName
    )
    
    $url = "http://$($solrHost):$solrPort/solr/admin/collections?action=LISTALIASES"
    
    $result = Invoke-WebRequest -UseBasicParsing -Uri $url
    $match = $result.Content.Contains("`"$solrAliasName`"")
    
    return $match
}

function Create-SolrCollection
{
    param(
        [string]$solrHost,
        [int]$solrPort,
        $solrCollectionName,
        $solrCollectionConfig,
        [int]$shards = 1,
        [int]$replicas = 1,
        [int]$shardsPerNode = 1
    )

    $exists = Test-SolrCollectionExists $solrHost $solrPort $solrCollectionName

    if( $exists -eq $false)
    {
        Write-Host "Creating collection $solrCollectionName with config $solrCollectionConfig"

        $url = "http://$($solrHost):$solrPort/solr/admin/collections?action=CREATE&name=$solrCollectionName&numShards=$shards&replicationFactor=$replicas&maxShardsPerNode=$shardsPerNode&collection.configName=$solrCollectionConfig"
        Invoke-WebRequest -UseBasicParsing -Uri $url | Out-Null
    }
    else
    {
        Write-Host "Collection $solrCollectionName exists - skipping"
    }
}

function Create-SolrCollectionAlias
{
    param(
        [string]$solrHost,
        [int]$solrPort,
        $solrCollectionName,
        $solrCollectionAlias
    )

    $exists = Test-SolrAliasExists $solrHost $solrPort $solrCollectionAlias

    if( $exists -eq $false )
    {
        Write-Host "Creating alias $solrCollectionAlias for collection $solrCollectionName"

        # /admin/collections?action=CREATEALIAS&name=name&collections=collectionlist
        $url = "http://$($solrHost):$solrPort/solr/admin/collections?action=CREATEALIAS&name=$solrCollectionAlias&collections=$solrCollectionName"
        Invoke-WebRequest -UseBasicParsing -Uri $url | Out-Null
    }
    else
    {
        Write-Host "Alias $solrCollectionAlias exists - skipping"
    }
}

<#
 .Synopsis
  Creates the standard set of collections and aliases for Sitecore, as an example.
 .Description
  Uses the Solr APIs to create a set of collections for Sitecore, with the specified set of
  replication and sharding parameters. And adds a switch-on-rebuild alias for the xDB index. It will
  upload the standard Sitecore core configs for content and analytics cores, and then use these to set
  up the collections.
 .Parameter targetFolder
  The absolute path to the folder that Solr and/or Zookeeper were installed to. Used to unpack
  the core config archives into prior to setup.
 .Parameter solrHostname
  The host name for accessing the Solr UI/API. This can be the load balanced address of the cluster or
  that of any individual node.
 .Parameter solrClientPort
  The port that the Solr UI/API is exposed on.
 .Parameter shards
  The number of shard cores to split this collection into.
 .Parameter replicas
  The number of replica cores to create for this collection.
 .Parameter shardsPerNode
  The maximum number of shards of a collection which can be put on each Solr node.
 .Parameter collectionPrefix
  The Sitecore instance name prefix put on the beginning of all the collection and alias names.
#>
function Configure-SolrCollection
{
	param(
		[string]$targetFolder = "C:\SolrCloud",
		[string]$solrHostname = "solr",
		[int]$solrClientPort = 9999,

		[int]$shards = 1,
        [int]$replicas = 1,
        [int]$shardsPerNode = 1,

        [string]$collectionNamesFile
	)

    $coreConfigFolder = $targetFolder

	$collections = Get-Content $collectionNamesFile

	Upload-SolrConfigSet $solrHostname $solrClientPort "$coreConfigFolder\Sitecore.zip" "Sitecore"
	Upload-SolrConfigSet $solrHostname $solrClientPort "$coreConfigFolder\xDB.zip" "xDB"

	$sitecoreCores = $collections | where { -not $_.Contains("xdb") }

	foreach($core in $sitecoreCores)
	{
		Create-SolrCollection $solrHostname $solrClientPort $core "Sitecore" -shards $shards -replicas $replicas -shardsPerNode $shardsPerNode
	}

	$xDbCores = $collections | where { $_.Contains("xdb") }

	foreach($core in $xDbCores)
	{
		Create-SolrCollection $solrHostname $solrClientPort "$($core)_internal" "xDB" -shards $shards -replicas $replicas -shardsPerNode $shardsPerNode
		Create-SolrCollectionAlias $solrHostname $solrClientPort "$($core)_internal" $core
	}
}

function Wait-ForSolrToStart
{
    param(
        [string]$solrHost,
        [int]$solrPort
    )

	Write-Host "Waiting for Solr to start on http://$($solrHost):$solrPort"
    $done = $false
    while(!$done)
    {
        try
        {
            Invoke-WebRequest "http://$($solrHost):$($solrPort)/solr" -UseBasicParsing | Out-Null
            $done = $true
        }
        catch
        {
        }
    }
	Write-Host "Solr is up..."
}

function Get-CollectionCount
{
    param(
        [string]$solrHost,
        [int]$solrPort
    )

    # check for collections - /solr/admin/collections?action=LIST&wt=json
    $url = "http://$($solrName):$solrPort/solr/admin/collections?action=LIST"
    $response = Invoke-WebRequest -UseBasicParsing -Uri $url
    $obj = $response | ConvertFrom-Json
    $collectionCount = $obj.Collections.Length
    Write-Host "Collection count: $collectionCount"

    return $collectionCount
}

# wait for it to start
Write-Host "### Waiting on http://$($solrName):$solrPort..."
Wait-ForSolrToStart $solrName $solrPort
Write-Host "### Started..."

$collectionCount = Get-CollectionCount $solrName $solrPort
if($collectionCount -eq 0)
{
    Write-Host "### Need to create collections"

    Configure-SolrCollection "c:\cloud" "localhost" "$solrPort" 1 1 1 $collectionNamesFile
}
else
{
    Write-Host "### $collectionCount Collections already exist - skipping create"
}