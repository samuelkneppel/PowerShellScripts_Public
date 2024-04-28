<#
.SYNOPSIS
This script authenticates and connects to the Zscaler API and returns back the URL category of the Domains/IPs provided via the input file.

.DESCRIPTION
This script authenticates and connects to the Zscaler API and returns back the URL category of the Domains/IPs provided via the input file.

For additional information regarding how to authenticate to ZScaler's API, please see Zscaler's own documentation: https://help.zscaler.com/zia/getting-started-zia-api

Additional information on the API calls used in this script: https://help.zscaler.com/zia/url-categories#/urlLookup-post


.PARAMETER baseUri
The base URI for the API. This is the endpoint to which the script will send requests.

.PARAMETER inputFile
The path to the input file containing data to be processed by the script.

.PARAMETER outputFile
(Optional) The path to the output file where the results will be saved.

.PARAMETER transcriptFile
(Optional) The path to the transcript file where the session transcript will be saved.

.EXAMPLE
.\ZscalerLookup.ps1 -baseUri "zsapi.zscalerbeta.net" -inputFile "data.txt" -outputFile "output.csv" -transcriptFile "transcript.txt"
This example shows how to run the script with the base URI, input file (one domain/IP address per line), output file, and transcript file as parameters.

## NOTES
Author: Sam Kneppel
Date: 2024-04-02
Version: 2024.04.27
#>

# Define script parameters
param(
    [Parameter(Mandatory=$true, HelpMessage="Enter the base URI for the API.")]
    [string]$baseUri,

    [Parameter(Mandatory=$true, HelpMessage="Enter the path to the input file.")]
    [string]$inputFile,

    [Parameter(HelpMessage="Enter the path to the output file.")]
    [string]$outputFile,

    [Parameter(HelpMessage="Enter the path to the transcript file.")]
    [string]$transcriptFile
)

Write-Host @"
Zscaler URL Lookup Script

This script authenticates and connects to the Zscaler API and returns back the URL category of the Domains/IPs provided via the input file.

Usage:
  .\Zscaler_URLLookup.ps1 -baseUri <baseUri> -inputFile <inputFile> [-outputFile <outputFile>] [-transcriptFile <transcriptFile>]

Parameters:
  -baseUri       The base URI for the API. This is the endpoint to which the script will send requests.
  -inputFile     The path to the input file containing data to be processed by the script.
  -outputFile    (Optional) The path to the output file where the results will be saved.
  -transcriptFile  (Optional) The path to the transcript file where the session transcript will be saved.

Example:
  .\ZscalerLookup.ps1 -baseUri "zsapi.zscalerbeta.net" -inputFile "data.txt" -outputFile "output.csv" -transcriptFile "transcript.txt"

Author: Sam Kneppel
Date: 2024-04-02
Version: 2024.04.11
================================================================
"@

if ($transcriptFile) {
    Start-Transcript -Path $transcriptFile
}

# Get the current timestamp in Unix time milliseconds
$timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

# Prompt the user for their credentials
$UserCredential = Get-Credential -Message "Please enter your credentials"
# Extract the username and password from the credential object
$username = $UserCredential.UserName
$password = $UserCredential.GetNetworkCredential().Password

# Prompt the user to enter the API key securely
$secureApiKey = Read-Host -Prompt "API key" -AsSecureString
# Convert the secure string to plaintext for use in the API call
$apiKeyBSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureApiKey)
$apiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($apiKeyBSTR)

# Display user inputted variables
Write-Host "User Inputted Variables:"
Write-Host "  Base URI: $baseUri"
Write-Host "  Input File: $inputFile"
if ($outputFile) { Write-Host "  Output File: $outputFile" }
if ($transcriptFile) { Write-Host "  Transcript File: $transcriptFile" }
Write-Host "  Username: $username"
Write-Host "  API Key: $apiKey"

# Function to obfuscate API key
function obfuscateApiKey {
    param (
        [string]
        $apiKey,
        [string]
        $timestamp
    )
 
    $high = $timestamp.substring($timestamp.length - 6)
    $low = ([int]$high -shr 1).toString()
    $obfuscatedApiKey = ''
 
    while ($low.length -lt 6) {
        $low = '0' + $low
    }
 
    for ($i = 0; $i -lt $high.length; $i++) {
        $obfuscatedApiKey += $apiKey[[int64]($high[$i].toString())]
    }
 
    for ($j = 0; $j -lt $low.length; $j++) {
        $obfuscatedApiKey += $apiKey[[int64]$low[$j].ToString() + 2]
    }
 
    return $obfuscatedApiKey
}
 
# Authenticate and get JSESSIONID
$obfuscatedApiKey = obfuscateApiKey -apiKey $apiKey -timestamp $timestamp
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")
$headers.Add("Server", "Zscaler")
$body = @"
{`"username`":`"$username`",`"password`":`"$password`",`"apiKey`":`"$obfuscatedApiKey`",`"timestamp`":$timestamp}
"@
$response = Invoke-WebRequest -Uri "$baseUri/api/v1/authenticatedSession" -Method 'POST' -Headers $headers -Body $body
$rawResponse = $response.RawContent
$headers = @{}
$rawResponse.Split([Environment]::NewLine) | ForEach-Object {
    if ($_ -match '^(.*?):\s+(.*)$') {
        $headers[$Matches[1]] = $Matches[2]
    }
}
$cookieValue = $headers["Set-Cookie"]
$jsessionid = ($cookieValue -split '; ' | Where-Object { $_ -like 'JSESSIONID=*' }) -replace 'JSESSIONID='
$cookieValue = "JSESSIONID=$jsessionid"
 
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")
$headers.Add("Cookie", $cookieValue)
 
# Read the file content
$fileContent = Get-Content $inputFile

# Prepare array to store responses
$responses = @()

# Rate limiting parameters
$requestsPerSecond = 1
$requestsPerHour = 400
$secondsPerHour = 3600
$secondsBetweenRequests = [Math]::Max(1 / $requestsPerSecond, $secondsPerHour / $requestsPerHour)

# Counter to track the number of requests made in the current hour
$requestCount = 0

# Process the file content in chunks of 100 lines
for ($i = 0; $i -lt $fileContent.Count; $i += 100) {
    # Check if the rate limit of 400 requests per hour is reached
    if ($requestCount -eq $requestsPerHour) {
        Write-Host "Rate limit reached. Waiting for the next hour to continue..."
        # Calculate the remaining seconds until the next hour
        $remainingSeconds = $secondsPerHour - ([DateTime]::Now).Second
        Start-Sleep -Seconds $remainingSeconds
        $requestCount = 0
    }

    # Take 100 lines or the remaining lines if less than 100
    $chunk = $fileContent[$i..([Math]::Min($i + 99, $fileContent.Count - 1))]
    $body = $chunk | ConvertTo-Json

    # Make API request and store response
    Write-Host "`nSending chunk starting with line $($i+1)..."
    $response = Invoke-RestMethod "$baseUri/api/v1/urlLookup" -Method 'POST' -Headers $headers -Body $body
    $responses += $response
    $requestCount++

    # Output all responses
    $responses | Select-Object url, urlClassifications, urlClassificationsWithSecurityAlert, Application | Format-Table -AutoSize

    # Wait before the next request
    Start-Sleep -Seconds $secondsBetweenRequests
}



# If outputFile is provided, export results to CSV
if($outputFile){
    $responses | ForEach-Object {
        $_.urlClassifications = $_.urlClassifications -join ', '
        $_.urlClassificationsWithSecurityAlert = $_.urlClassificationsWithSecurityAlert -join ', '
        $_
    } | Export-Csv -Path $outputFile -NoTypeInformation
    Write-Host "`nResults exported to $outputFile"
}

if ($transcriptFile) {
    Stop-Transcript
}