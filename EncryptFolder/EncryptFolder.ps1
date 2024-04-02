<##
Title: EncryptFolder.ps1
Date: May-2023
Author: Samuel Kneppel
Email: samuelkneppel@gmail.com
Version: 2023.05.24
About: This script encrypts or decrypts all files in a specified folder and its subfolders using the AES algorithm with a hardcoded key.
##>

# Define parameters for the script
param (
    [string]$folderPath,
    [string]$operation
)

# Hardcode the key as a byte array
$key = [byte[]]@(0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F,0x10)

# Define a function to encrypt or decrypt a file using the AES algorithm
function Protect-Unprotect-File([string]$inputFile, [string]$outputFile, [byte[]]$key, [bool]$encrypt) {
    # Create a new AES object
    $aes = [Security.Cryptography.Aes]::Create()
    # Set the key for the AES object
    $aes.Key = $key
    # Set the initialization vector for the AES object
    $aes.IV = New-Object Byte[] 16

    # Check if we are encrypting or decrypting
    if ($encrypt) {
        # If encrypting, create an encryptor from the AES object
        $transform = $aes.CreateEncryptor($aes.Key, $aes.IV)
    } else {
        # If decrypting, create a decryptor from the AES object
        $transform = $aes.CreateDecryptor($aes.Key, $aes.IV)
    }

    # Open the input and output files
    $inputStream = [IO.File]::OpenRead($inputFile)
    $outputStream = [IO.File]::OpenWrite($outputFile)

    # Create a CryptoStream to perform encryption or decryption
    $cryptoStream = New-Object Security.Cryptography.CryptoStream($outputStream, $transform, [Security.Cryptography.CryptoStreamMode]::Write)

    # Copy data from the input file to the CryptoStream to perform encryption or decryption
    $inputStream.CopyTo($cryptoStream)
    # Flush any remaining data from the CryptoStream to the output file
    $cryptoStream.FlushFinalBlock()

    # Close the input and output files
    $inputStream.Close()
    $outputStream.Close()
}

# Check if we are encrypting or decrypting
if ($operation -eq "Encrypt") {
    # If encrypting, get all files (but not directories) in the specified folder and its subfolders
    Get-ChildItem $folderPath -Recurse -File | ForEach-Object {
        # Encrypt each file using the Protect-Unprotect-File function and save the encrypted data to a new file with an ".encrypted" extension
        Protect-Unprotect-File $_.FullName ($_.FullName + ".encrypted") $key $true
        # Delete the original file
        Remove-Item $_.FullName
        # Rename the encrypted file to have an ".enc" extension instead of ".encrypted"
        Rename-Item ($_.FullName + ".encrypted") ($_.FullName + ".enc")
    }
} elseif ($operation -eq "Decrypt") {
    # If decrypting, get all files with an ".enc" extension in the specified folder and its subfolders
    Get-ChildItem $folderPath -Filter "*.enc" -Recurse | ForEach-Object {
        # Decrypt each file using the Protect-Unprotect-File function and save the decrypted data to a new file with a ".decrypted" extension
        Protect-Unprotect-File $_.FullName ($_.FullName + ".decrypted") $key $false
        # Delete the original (encrypted) file
        Remove-Item $_.FullName
        # Rename the decrypted file to remove the ".enc" extension
        Rename-Item ($_.FullName + ".decrypted") ($_.FullName -replace ".enc$")
    }
} else {
    # If an invalid operation was specified, display an error message
    Write-Host "Invalid operation. Please specify 'Encrypt' or 'Decrypt'."
}