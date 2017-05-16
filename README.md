# Server-Health-Check
Perfoms light technical acceptance testing Checks windows server for: ping, domain trust, internet access, vmware tools is running and any new error events in application or system logs in the last eight hours compared to the last eight days

HelthCheck.ps1 reads in a CSV file in the same directory named 'TATservers.csv'. 

TATservers.csv is layed out as below


name
server1
server2
server3
