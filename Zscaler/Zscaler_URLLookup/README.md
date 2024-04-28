# Zscaler API URL Lookup Script

## SYNOPSIS
This script authenticates and connects to the Zscaler API and returns back the URL category of the Domains/IPs provided via the input file.

## DESCRIPTION
This script authenticates and connects to the Zscaler API and returns back the URL category of the Domains/IPs provided via the input file.\

For additional information regarding how to authenticate to ZScaler's API, please see Zscaler's own documentation: [Getting Started | Zscaler](https://help.zscaler.com/zia/getting-started-zia-api)

Additional information on the API calls used in this script: [URL Categories | Zscaler](https://help.zscaler.com/zia/url-categories#/urlLookup-post)

## PARAMETERS

### baseUri
The base URI for the API. This is the endpoint to which the script will send requests.

### inputFile
The path to the input file containing data to be processed by the script.

### outputFile
(Optional) The path to the output file where the results will be saved.

### transcriptFile
(Optional) The path to the transcript file where the session transcript will be saved.

## EXAMPLE
```powershell
.\ZscalerLookup.ps1 -baseUri "zsapi.zscalerbeta.net" -inputFile "input.txt" -outputFile "output.csv" -transcriptFile "transcript.txt"
```
This example shows how to run the script with the base URI, input file (one domain/IP address per line), output file, and transcript file as parameters.

## NOTES
Author: Sam Kneppel

Date: 2024-04-02

Version: 2024.04.27