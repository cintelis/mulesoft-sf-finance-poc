<#
.SYNOPSIS
  Deploys the built Mule apps to the local Mule runtime and starts it.

.DESCRIPTION
  Uses the Mule Enterprise runtime and JDK 17 that Anypoint Code Builder
  installs under %USERPROFILE%\AnypointCodeBuilder.

  Environment variables for the apps are read from git-ignored files:
    infra\.env            database and SFTP passwords
    <app>\local\*.env     per-app settings such as the Salesforce consumer key

  Build the apps first:  mvn clean package -DskipMunitTests   (in each app folder)

.EXAMPLE
  .\scripts\start-local-runtime.ps1
#>
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$acb = Join-Path $env:USERPROFILE 'AnypointCodeBuilder'

$runtime = Get-ChildItem (Join-Path $acb 'runtime') -Directory -Filter 'mule-enterprise-standalone-*' |
  Sort-Object Name -Descending | Select-Object -First 1
if (-not $runtime) { throw "No Mule runtime found under $acb\runtime. Run 'MuleSoft: Install Runtime' in VS Code." }

$jdk = Get-ChildItem (Join-Path $acb 'java') -Directory -Filter 'jdk-17*' | Select-Object -First 1
if (-not $jdk) { throw "No JDK 17 found under $acb\java." }

# Load KEY=VALUE lines from the git-ignored env files into this process only.
$envFiles = @(Join-Path $repo 'infra\.env') + @(Get-ChildItem $repo -Recurse -Filter '*.env' -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -match '\\local\\' } | Select-Object -ExpandProperty FullName)
foreach ($file in $envFiles) {
  if (-not (Test-Path $file)) { continue }
  foreach ($line in Get-Content $file) {
    if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
      Set-Item -Path "env:$($Matches[1])" -Value $Matches[2]
    }
  }
}

# The Salesforce JWT keystore lives beside sfdc.env.
$keystore = Join-Path $repo 'sfdc-sys-api\local\sfdc-jwt.jks'
if ((Test-Path $keystore) -and -not $env:SFDC_KEYSTORE_PATH) { $env:SFDC_KEYSTORE_PATH = $keystore }

# The runtime needs these folders before it will start.
foreach ($dir in 'apps', 'domains\default', 'logs') {
  New-Item -ItemType Directory -Force (Join-Path $runtime.FullName $dir) | Out-Null
}

# Deploy every app that has been built.
Get-ChildItem $repo -Directory | ForEach-Object {
  $jar = Get-ChildItem (Join-Path $_.FullName 'target') -Filter '*-mule-application.jar' -ErrorAction SilentlyContinue |
    Select-Object -First 1
  if ($jar) {
    Copy-Item $jar.FullName (Join-Path $runtime.FullName "apps\$($_.Name).jar") -Force
    Write-Host "Deployed $($_.Name)"
  }
}

$env:JAVA_HOME = $jdk.FullName
$env:MULE_HOME = $runtime.FullName
Write-Host "Starting $($runtime.Name) with $($jdk.Name)"
Set-Location (Join-Path $runtime.FullName 'bin')
& (Join-Path $runtime.FullName 'bin\mule.bat') console
