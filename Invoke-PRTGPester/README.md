# Invoke-PRTGPester
Invoke-PRTGPester is a small script that is to be ran as a PRTG Advanced Sensor.

## Description
This script is called from PRTG to run Pester tests and record the results in PRTG. By default, each channel in the sensor will error if a test fails.

## Getting Started
You can install this script by copying this script to "C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML". Then, you will add a EXE/Script Advanced sensor to a Device. The sensor settings will be the following:

EXE/Script: Invoke-PRTGPester.ps1
Parameters: Path to your pester script on the PRTG server
Environment: Default
Security Contect: Can be either. I use "Use Windows credentials of parent device" so that my script does not store credentials.
Exe Result: Write EXE result to disk. This is for logging, the output of the script will be saved to "C:\scripts\GIT-PowerShellScripts\Invoke-PRTGPester".

![Alt text](Example.png?raw=true "Pester Example")

## TO DO
I have thought about changing it so that I have folder for each server that I have tests on. Then using a PRTG environment variable to know which folder contains the needed Pester tests. This would be so you do not have to set the parameter.
