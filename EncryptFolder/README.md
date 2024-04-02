# EncryptFolder

This repository contains a PowerShell script for encrypting or decrypting all files in a specified folder and its subfolders using the AES algorithm with a hardcoded key. The script serves as a proof of concept (POC) for using PowerShell to showcase ransomware-like behavior. It can potentially be used to validate security controls on a device, although it has not been tested with an Endpoint Detection and Response (EDR) solution.

## Usage

The script takes two parameters: `folderPath` and `operation`. `folderPath` specifies the path to the folder containing the files to be encrypted or decrypted. `operation` specifies whether to encrypt or decrypt the files and can be either "Encrypt" or "Decrypt".

Example usage:

```
.\EncryptFolder.ps1 -folderPath "C:\myfolder" -operation "Encrypt"
```

## Author
This script was written by Samuel Kneppel (samuelkneppel@gmail.com) in May 2023.

## Version
The current version of this script is 2023.05.24.

