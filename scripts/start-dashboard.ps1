<#
.SYNOPSIS
  Starts the local dashboard in its own minimised window and opens it in the browser.

.DESCRIPTION
  The dashboard keeps running after this script ends. Close its window to stop it.
  From the dashboard you can start, stop and restart the Mule runtime, each app
  and the Docker systems.

.EXAMPLE
  .\scripts\start-dashboard.ps1
#>
$repo = Split-Path -Parent $PSScriptRoot
$url = 'http://localhost:8090/'

$running = $false
try { $running = (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 2).StatusCode -eq 200 } catch { }

if (-not $running) {
  Start-Process -FilePath 'node' -ArgumentList 'dashboard\server.js' -WorkingDirectory $repo -WindowStyle Minimized
  foreach ($attempt in 1..20) {
    try { if ((Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 2).StatusCode -eq 200) { $running = $true; break } }
    catch { Start-Sleep -Milliseconds 500 }
  }
}

if ($running) { Start-Process $url; Write-Host "Dashboard: $url" }
else { Write-Host 'The dashboard did not start. Check that Node 18 or later is installed.' }
