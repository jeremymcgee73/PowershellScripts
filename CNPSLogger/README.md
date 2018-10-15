# CNPSLogger
This is an example Logging Module to standardize logging across a Company. I basically just changed our company name in this module to "Company Name".

## Description
This repository contains PowerShell functions to setup a standardized logger for PowerShell jobs at Company Name. This really just standardizes the 'logging' powershell module.

## Dependencies
This module references the following PowerShell modules PSGelf and Logging. These can be installed with "Install-Module PSGelf" or by copying from another server.

## Getting Started
Install the module by copying the Module (CNPSLogger) to C:\Program Files\WindowsPowerShell\Modules on a system.

## Examples
There is an included Examples.ps1 file.

## Functions

|  CNPSLogger Functions  |  Description  |
| ------------- | ------------- |
| Use-CNPoshLogging | This function sets up the logger |
| Exit-CNPoshLogging | This is used to stop a script on error but make sure the log is written. |
| New-ErrorString | Formats a PowerShell error. |



## Parameters for Use-CNPoshLogging

|  Use-CNPoshLogging Parameters  |  Description  |
| ------------- | ------------- |
| Owner | This parameter is added to a field in Graylog. This can be used for searching and alerting. IE, if there is an error and the Owner is Infrastrue, they will receive an email. |
| Environment | This parameter is added to a field in Graylog |
| LogPath | The location the error log will be written. |
| ScriptPath | The path of the script that ran. $PSCommandPath can be used in PS 3.0+ |
