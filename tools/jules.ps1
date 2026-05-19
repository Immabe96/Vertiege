param(
  [Parameter(Mandatory = $true, Position = 0)]
  [ValidateSet('sources', 'sessions', 'create-session', 'activities', 'send-message', 'approve-plan')]
  [string]$Command,

  [string]$Source,
  [string]$Branch = 'main',
  [string]$Title,
  [string]$Prompt,
  [string]$Session,
  [int]$PageSize = 10,
  [switch]$AutoCreatePr,
  [switch]$RequirePlanApproval
)

$ErrorActionPreference = 'Stop'

$BaseUrl = 'https://jules.googleapis.com/v1alpha'
$ApiKey = $env:JULES_API_KEY
if ([string]::IsNullOrWhiteSpace($ApiKey)) {
  $ApiKey = [Environment]::GetEnvironmentVariable('JULES_API_KEY', 'User')
}

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
  throw 'Set JULES_API_KEY in your environment before running this script.'
}

function Invoke-Jules {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [ValidateSet('GET', 'POST')]
    [string]$Method = 'GET',

    [object]$Body
  )

  $headers = @{
    'X-Goog-Api-Key' = $ApiKey
  }

  $uri = "$BaseUrl/$Path"
  if ($null -ne $Body) {
    $json = $Body | ConvertTo-Json -Depth 20
    return Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers -ContentType 'application/json' -Body $json
  }

  return Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers
}

switch ($Command) {
  'sources' {
    Invoke-Jules -Path "sources?pageSize=$PageSize" | ConvertTo-Json -Depth 20
  }

  'sessions' {
    Invoke-Jules -Path "sessions?pageSize=$PageSize" | ConvertTo-Json -Depth 20
  }

  'create-session' {
    if ([string]::IsNullOrWhiteSpace($Source)) { throw '-Source is required, for example sources/github/Immabe96/Vertiege.' }
    if ([string]::IsNullOrWhiteSpace($Prompt)) { throw '-Prompt is required.' }
    if ([string]::IsNullOrWhiteSpace($Title)) { $Title = 'Vertiege Jules Task' }

    $body = @{
      title = $Title
      prompt = $Prompt
      sourceContext = @{
        source = $Source
        githubRepoContext = @{
          startingBranch = $Branch
        }
      }
    }

    if ($AutoCreatePr) {
      $body.automationMode = 'AUTO_CREATE_PR'
    }

    if ($RequirePlanApproval) {
      $body.requirePlanApproval = $true
    }

    Invoke-Jules -Path 'sessions' -Method POST -Body $body | ConvertTo-Json -Depth 20
  }

  'activities' {
    if ([string]::IsNullOrWhiteSpace($Session)) { throw '-Session is required, for example sessions/123 or 123.' }
    $sessionName = if ($Session -like 'sessions/*') { $Session } else { "sessions/$Session" }
    Invoke-Jules -Path "$sessionName/activities?pageSize=$PageSize" | ConvertTo-Json -Depth 30
  }

  'send-message' {
    if ([string]::IsNullOrWhiteSpace($Session)) { throw '-Session is required, for example sessions/123 or 123.' }
    if ([string]::IsNullOrWhiteSpace($Prompt)) { throw '-Prompt is required.' }
    $sessionName = if ($Session -like 'sessions/*') { $Session } else { "sessions/$Session" }
    Invoke-Jules -Path "${sessionName}:sendMessage" -Method POST -Body @{ prompt = $Prompt } | ConvertTo-Json -Depth 20
  }

  'approve-plan' {
    if ([string]::IsNullOrWhiteSpace($Session)) { throw '-Session is required, for example sessions/123 or 123.' }
    $sessionName = if ($Session -like 'sessions/*') { $Session } else { "sessions/$Session" }
    Invoke-Jules -Path "${sessionName}:approvePlan" -Method POST | ConvertTo-Json -Depth 20
  }
}
