$oldPref = $VerbosePreference
$VerbosePreference = "SilentlyContinue"

Import-Module $PSScriptRoot\AirTable.psm1
. $PSScriptRoot\keys.ps1

#api key param = $airTableKey
#base key param = $dogsBaseKey

#script config
$url = 'https://www.shelterluv.com/api/v3/available-animals/10032?species=Dog&embedded=1&iframeId=shelterluv_wrap_1601915424669&columns=1'
$tableName = 'Dogs'

#fetch new dog data
$animals = ((Invoke-WebRequest $url).Content | ConvertFrom-Json | Select-Object animals).animals | Select-Object nid, name, uniqueId, sex, weight, weight_group, age_group, breed, secondary_breed, primary_color, secondary_color
$currentIds = $animals.uniqueId

#get logged data from airtable
Set-AirTableAuth $airTableKey
$records = Get-AirTableRecords $dogsBaseKey $tableName
if ($records.count -gt 0) {
    $loggedIds = $records.fields.uniqueId
} else {
    $loggedIds = @()
}

#check to see if there are any new dogs, and push them to airtable if so
if ($loggedIds.length -gt 0) {
    $newIds = (Compare-Object -ReferenceObject $loggedIds -DifferenceObject ($currentIds) | Where-Object{$_.sideIndicator -eq "=>"}).InputObject
} else {
    $newIds = $currentIds
}
if ($newIds.Count -gt 0) {
    foreach($id in $newIds) {
        $pup = $animals | Where-Object { $_.uniqueId -eq $id }

        $pup | Add-Member -NotePropertyName 'Link' -NotePropertyValue "https://www.shelterluv.com/embed/animal/$id"
        
        Add-AirTableRecord $dogsBaseKey $tableName $pup
    }
}

$VerbosePreference = $oldPref