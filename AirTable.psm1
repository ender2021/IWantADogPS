# from https://github.com/Zulton/AirTable-Powershell-Interface/blob/master/AirTable.psm1

$Global:ContentJson = "application/json"

$Global:AirTableHeaders = $null
$Global:AirTableURI = "https://api.airtable.com/v0"


Function Set-AirTableAuth
{
    Param ([Parameter(Mandatory=$true)][string]$APIKey)
	
	$Global:AirTableHeaders = @{
		'Authorization' = "Bearer " + $APIKey
		'Content-Type' = $ContentJson
		'Accept' = $ContentJson
    }
}



Function Get-AirTableRecords
{
    Param
    (
        [string]$AirTableBaseKey,
        [string]$Table,
        [string]$Filter
    )

    If ($Filter)
    {
        Write-Verbose "Get-USPIAirTableRecords: Using $Filter as filter."
    }
    Else
    {
        Write-Verbose "Get-USPIAirTableRecords: No filter provided, querying entire table."
    }

    $Records = @()

    $Response = iwr -Method Get -Uri ("$AirTableURI/$AirTableBaseKey/$Table" + $Filter) -Headers $AirTableHeaders
    
    Do
    {
        If ($Response)
        {
            If ($Response.StatusCode -eq 200)
            {
                Write-Verbose "Page received."

                $Content = ($Response.content | ConvertFrom-Json)
                
                If ($Content.fields)
                {
                    $Records += , $Content.fields
                }
                ElseIf ($Content.records)
                {
                    $Records += $Content.records
                }
                Else
                {
                    Write-Verbose "No data received"
                }
            }
            Else
            {
                Write-Verbose "HTTP Status [$($Response.StatusDescription)]"
                
                Break
            }
        }
        Else
        {
            Write-Verbose "Response was empty"
        }

        If ($Content.offset)
        {
            $Response = $null
            Write-Verbose "Retrieving next page: offset $($Content.offset)"
            $Response = iwr -Method Get -Uri ("$AirTableURI/$AirTableBaseKey/$Table" + "?offset=$($Content.offset)") -Headers $AirTableHeaders
                    
        }
    } Until (!$Content.offset)
            
    Write-Verbose "Get-USPIAirTableRecords: Query complete."
    
    Write-Verbose "$($Records.count) records found."

    Return $Records
}



Function Add-AirTableRecord
{
    Param
    (
        [string]$AirTableBaseKey,
        [string]$Table,
        $Record
    )

    $JSONPrep = @{"fields" = $Record}
    $JSONBody = ($JSONPrep | ConvertTo-Json)
    
    $Response = iwr -Method Post -Uri ("$AirTableURI/$AirTableBaseKey/$Table") -Headers $AirTableHeaders -Body $JSONBody
    
    If ($Response.StatusCode -eq 200)
    {
        Return ($Response.content | ConvertFrom-Json)
    }
    Else
    {
        Return $Response
    } 
}



Function Update-AirTableRecord
{
    Param
    (
        [string]$AirTableBaseKey,
        [string]$Table,
        [string]$RecordID,
        $Record
    )

    $JSONPrep = @{"fields" = $Record}
    $JSONBody = $JSONPrep | ConvertTo-Json
    
    $Response = iwr -Method Patch -URI ("$AirTableURI/$AirTableBaseKey/$Table/$RecordID") -Headers $AirTableHeaders -Body $JSONBody
    
    If ($Response.StatusCode -eq 200)
    {
        Return ($Response.content | ConvertFrom-Json)
    }
    Else
    {
        Return $Response
    }
}


Function Remove-AirTableRecord
{
    Param
    (
        [string]$AirTableBaseKey,
        [string]$Table,
        [string]$RecordID
    )

    $Response = iwr -Method Delete -URI ("$AirTableURI/$AirTableBaseKey/$Table/$RecordID") -Headers $AirTableHeaders
    
    If ($Response.StatusCode -eq 200)
    {
        $Content = ($Response.content | ConvertFrom-Json)
    }
    Else
    {
        Return $Response
    }
}