$url = 'https://www.shelterluv.com/api/v3/available-animals/10032?species=Dog&embedded=1&iframeId=shelterluv_wrap_1601915424669&columns=1'

$response = Invoke-WebRequest $url

$animals = $response.Content | ConvertFrom-Json | Select-Object animals

$animals