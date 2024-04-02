<#
.SYNOPSIS
This script authenticates and connects to the Zscaler API and returns back the URL category of the Domains/IPs provided via the input file.

.DESCRIPTION
This script authenticates and connects to the Zscaler API and returns back the URL category of the Domains/IPs provided via the input file.

.PARAMETER baseUri
The base URI for the API. This is the endpoint to which the script will send requests.

.PARAMETER inputFile
The path to the input file containing data to be processed by the script.

.PARAMETER outputFile
(Optional) The path to the output file where the results will be saved.

.EXAMPLE
.\ZscalerLookup.ps1 -baseUri "zsapi.zscalerbeta.net" -inputFile "data.txt" -outputFile "output.csv"
This example shows how to run the script with the base URI, input file, and output file as parameters.

.NOTES
Author: Sam Kneppel
Date: 2024-04-02
Version: 1.0
#>

# Define script parameters
param(
    [Parameter(Mandatory=$true, HelpMessage="Enter the base URI for the API.")]
    [string]$baseUri,

    [Parameter(Mandatory=$true, HelpMessage="Enter the path to the input file.")]
    [string]$inputFile,

    [Parameter(HelpMessage="Enter the path to the output file.")]
    [string]$outputFile
)

# Get the current timestamp in Unix time milliseconds
$timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

# Prompt the user to enter the API key securely
$secureApiKey = Read-Host -Prompt "Enter the API key" -AsSecureString
# Convert the secure string to plaintext for use in the API call
$apiKeyBSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureApiKey)
$apiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($apiKeyBSTR)

# Prompt the user for their credentials
$UserCredential = Get-Credential -Message "Please enter your credentials"
# Extract the username and password from the credential object
$username = $UserCredential.UserName
$password = $UserCredential.GetNetworkCredential().Password

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
 
# Read URLs from input file
$lines = Get-Content $inputFile
 
# Prepare array to store responses
$responses = @()
 
# Rate limiting parameters
$requestsPerSecond = 2
$requestsPerHour = 1000
$secondsPerHour = 3600
$secondsBetweenRequests = [Math]::Max(1 / $requestsPerSecond, $secondsPerHour / $requestsPerHour)
 
# Process each URL and make API requests
foreach ($line in $lines) {
    $body = @"
[  
`"$line`"
]
"@
    # Make API request and store response
    Write-Output "Checking $line..."
    $response = Invoke-RestMethod 'zsapi.zscalerbeta.net/api/v1/urlLookup' -Method 'POST' -Headers $headers -Body $body
    $responses += $response
 
    # Wait before the next request
    Start-Sleep -Seconds $secondsBetweenRequests
}

# If outputFile is provided, export results to CSV
if($outputFile){
    $responses | ForEach-Object {
        $_.urlClassifications = $_.urlClassifications -join ', '
        $_.urlClassificationsWithSecurityAlert = $_.urlClassificationsWithSecurityAlert -join ', '
        $_
    } | Export-Csv -Path "output.csv" -NoTypeInformation
    Write-Output "Results exported to $outputFile"
} else {
    Write-Output "Results not exported to file"
}