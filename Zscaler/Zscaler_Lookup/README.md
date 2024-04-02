# Zscaler API URL Category Lookup Script

## Synopsis
This PowerShell script authenticates and connects to the Zscaler API and retrieves the URL category for the provided Domains/IPs from an input file.

## Description
The script requires a base URI for the Zscaler API endpoint and an input file containing the Domains/IPs to be categorized. It outputs the results, which include the URL category of each item from the input file to a .csv file.

## Parameters

- **baseUri**: The base URI for the Zscaler API endpoint. This is the URL to which the script will send requests.
- **inputFile**: The path to the input file that contains the Domains/IPs to be processed by the script.
- **outputFile**: (Optional) The path to the output file where the results will be saved.

## Usage

Run the script from the PowerShell command line:

```powershell
.\ZscalerLookup.ps1 -baseUri "zsapi.zscalerbeta.net" -inputFile "data.txt" -outputFile "output.csv"
```
This example shows how to run the script with the base URI, input file, and output file as parameters.

## Notes
Author: Sam Kneppel

Date: 2024-04-02

Version: 1.0

Please ensure you have the necessary permissions and credentials to access the Zscaler API before running this script