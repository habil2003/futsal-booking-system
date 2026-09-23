$client = New-Object System.Net.WebClient
try {
    $data = $client.DownloadString('http://localhost:5000/api/futsals')
    Write-Output('Futsals data retrieved successfully')
    Write-Output('Response length: ' + $data.Length)
} catch {
    Write-Output('Error: ' + $_.Exception.Message)
}