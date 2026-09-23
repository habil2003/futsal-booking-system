try {
    $r = Invoke-WebRequest -Uri 'http://localhost:5000/api/health' -UseBasicParsing
    Write-Output "STATUS: $($r.StatusCode)"
    Write-Output "BODY: $($r.Content)"
} catch {
    Write-Output "FAILED: $($_.Exception.Message)"
}