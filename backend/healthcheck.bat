$client = New-Object System.Net.WebClient
$response = $client.DownloadString('http://localhost:5000/api/health')
Write-Output('STATUS: 200')
Write-Output('BODY: ' + $response)