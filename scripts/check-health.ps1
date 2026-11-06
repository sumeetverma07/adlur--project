param(
    [Parameter(Mandatory = $true)]
    [string]$AlbDnsName,
    [int]$Attempts = 20
)

$ErrorActionPreference = 'Stop'
$uri = "http://$AlbDnsName/healthz"

for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
    try {
        $response = Invoke-WebRequest -Uri $uri -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
            Write-Output "PASS: $uri returned $($response.StatusCode) on attempt $attempt"
            exit 0
        }
    }
    catch {
        Write-Warning "Attempt $attempt failed: $($_.Exception.Message)"
    }
    Start-Sleep -Seconds 15
}

throw "Health check failed after $Attempts attempts: $uri"
