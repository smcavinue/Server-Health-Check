##main function##
function main{

##import CSV of server names##
$servers = import-csv TATservers.csv

##Create array variable for results of tests##
$results = New-Object psobject
$results | Add-Member -MemberType noteproperty -Name trust -Value Notset
$results | Add-Member -MemberType noteproperty -Name logs -Value Notset
$results | Add-Member -MemberType noteproperty -Name ping -Value Notset
$results | Add-Member -MemberType noteproperty -Name web -Value Notset
$results | Add-Member -MemberType noteproperty -Name vmtools -Value Notset

##loop through server names in CSV file##
foreach($server in $servers){


##nullifies return values##
$results.trust = "error"
$results.logs = "error"
$results.ping = "error"
$results.web = "error"
$results.vmtools = "error"

##calls funtions to test server functionality and return values##
$results.trust = domaintrusttest $server.name
$results.logs = EventlogTest $server.name
$results.ping = PingTest $server.name
$results.web = webtest $server.name
$results.vmtools = vmtoolstest $server.name
htmloutput $results $server.name
}
}

##Tests the domain trust and returns true or false value, also attempts trust repair once##
function domaintrusttest{
 param( [String]$ComputerName)
 write-host Checking domain trust on $computername -foregroundcolor Green
$trust = test-computersecurechannel -Server $computerName
if(!$trust){
write-host Attempting repair -ForegroundColor yellow
test-computersecurechannel -Server $computerName -Repair
$trust = test-computersecurechannel -Server $computerName
}

if(!$trust){
return "Not Working"
}else{
return "Working"
}

}

##Compares the error events from application and system logs for the last hour to a control copy from the past eight days##
##New events are output to a file and function returns true or false depending on if new errors are found##
function EventlogTest{
 param( [String]$ComputerName)
  write-host Checking event log on $computername -foregroundcolor Green
  $logname = $computername + ".csv"
if(!(test-path C:\TATTesting)){
mkdir c:\TATTesting
}
CD c:\TATTesting


$control = invoke-command  -ComputerName $computername  -scriptblock {Get-EventLog -After (Get-Date).AddDays(-8) -Before (Get-Date).AddHours(-8) -LogName application -EntryType error}
$control += invoke-command  -ComputerName $computername  -scriptblock  {Get-EventLog -After (Get-Date).AddDays(-8) -Before (Get-Date).AddHours(-8) -LogName system -EntryType error}
$today = invoke-command  -ComputerName $computername  -scriptblock  {Get-EventLog -After (Get-Date).AddHours(-8) -LogName application -EntryType error}
$today += invoke-command  -ComputerName $computername  -scriptblock  {Get-EventLog -After (Get-Date).AddHours(-8) -LogName system -EntryType error} 
$new = $false
foreach($log in $today){
$new = $true
foreach($controllog in $control){

if(($log.message -like $controllog.message) -and ($log.source -like $controllog.source)){
$new = $false
}

}
if($new){

$log | export-csv $logname -NoClobber -NoTypeInformation -Append

}
}
if(Test-Path ("c:\TATTesting\" + $logname)){
return "Errors Logged in C:\TATTesting\"
}else{
return "No New Errors"
}
}


##Tests ping to server and returns true or false based on success##
function PingTest{
 param( [String]$ComputerName)
  write-host Checking ping test on $computername -foregroundcolor Green
 $pingtest = Test-Connection $ComputerName -quiet -count 2

 if($pingtest){
 return "Working"
 }else{
 return "Not Working"
 }


}

##Tests internet access from server and returns true or false based on success##
function webtest{
    param( [String]$ComputerName)
     write-host Checking web access on $computername -foregroundcolor Green
$webrequest = Invoke-Command -ScriptBlock{Invoke-WebRequest -Uri https://www.google.com -UseBasicParsing} -ComputerName $computername 
if($webrequest.statuscode){
return "Working"
}else{
return "Not Working"
}
}

##Checks that vmtools are running on the server and returns true or false##
function vmtoolstest{
    param( [String]$ComputerName)
     write-host Checking vmtools on $computername -foregroundcolor Green
$vmtools = Get-Service -ComputerName $computername -Name vmtools

if($vmtools.status -like "running"){
return "Running"
}else{
return "Not Running"
}
}

##Outputs results variable to a HTML file##
function htmlOutput{
 param( [array] $results, [String] $computername)
 write-host Creating html log for $computername -foregroundcolor yellow
 $path = ("TATTestResults." + (get-date).Date.ToString().Replace('/','.').Replace(' ','').Replace(':',''))
 $results | ConvertTo-Html -Head $computername -title "TAT Test Results " -as list | out-file ("C:\TATTesting\" + $path + ".html") -Append

}
main
