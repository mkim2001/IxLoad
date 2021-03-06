#!/usr/bin/expect

#!/opt/ActiveTcl-8.5/bin/tclsh

# By Hubert Gee
#
# Description
#
#    This script will load a saved IxLoad config file stored in the
#    Windows Client PC.
# 
#    You could also reassign ports so you could use this config file
#    on any testbed or device.  Making your config file dynamic.
#    If you do not wish to reassign ports, comment out the variable:
#    $portsToReassign
#
#    Runs traffic and show real time stats.
#
#    While traffic is running, all stats are saved in a CSV format file locally
#    into a file name that you could name by using the variable: $csvFilePathAndName
#
# Notes:
#
#   In order for this script to save the stats to a csv format file on your local
#   Linux machine, you have to go to the IxLoad GUI, under File/Preferences/Statistics, 
#   enabled "CSV Logging".
#
#   All Statistics results are saved in the Windows PC C: drive under the variable
#   name $resultDirectoryOnWindows.  This is a value that you could define.
#
#   To get all the statistics that you want, you have configure everything on IxLoad,
#   run traffic and ensure the configuration and traffic runs fine, then do a Scriptgen
#   to generate a script.  Open the script and scroll near the bottom and copy and paste
#   the stats that you want to the variable name HTTP_Client_StatList and HTTP_Server_StatList.
#   You can change the variable names.
#

package require IxLoadCsv

# The IP address to the IxLoad Windows PC
set windowsClientIp 192.168.70.3

# The full path and filename to your saved config file on the IxLoad Windows PC.
set configFile "C:\\Results\\IxL_Http_Ipv4Ftp_vm_8.20.rxf"

# This is the location on the IxLoad Windows PC c: drive where you 
# want to store all the statistic files.
set resultDirectoryOnWindows "c:\\Results"

# Set the path and the PDF file name to copy from Windows to Linux at the end of the test.
set pdfPathOnWindows "$resultDirectoryOnWindows\\IxLoad Summary Report.pdf"
set generatePdfResult 1

# Uncomment this line to enable port reassignment.
set portsToReassign {{"192.168.70.11" 1 1} {"192.168.70.11" 2 1}}

# The CSV format file name to store all the statistics on your local
# Linux machine running this script.  
set csvFilePathAndName IxL_statResults.csv

# These are the stats that you want.  You get these from IxLoad GUI 
# Scriptgen
set HTTP_Client_StatList {
    { "HTTP Client" "TCP Connections Established" "kSum" } 
    { "HTTP Client" "TCP Connection Requests Failed" "kSum" }
    { "HTTP Client" "HTTP Simulated Users" "kSum" }
    { "HTTP Client" "HTTP Concurrent Connections" "kSum" }
    { "HTTP Client" "HTTP Connections" "kSum" }
    { "HTTP Client" "HTTP Transactions" "kSum" }
    { "HTTP Client" "HTTP Connection Attempts" "kSum" }
}
set HTTP_Server_StatList {
    { "HTTP Server" "TCP Connections Established" "kSum" }
    { "HTTP Server" "TCP Connection Requests Failed" "kSum" }
}

# This script already saves the stats in a csv file under the variable name
# $csvFilePathAndName.
# If you are still interested in downloading the CSV stat files from the Windows
# PC, you need to know the exact file names. Use backslashes to break the whitespaces.
set statsToGet {
    "per\ IP.csv"
    "HTTP\ Client\ -\ Objectives.csv"
    "HTTP\ Client\ -\ TCP\ Connections.csv"
    "HTTP\ Client\ -\ TCP\ Failures.csv"
    "HTTP\ Server\ -\ TCP\ Connections.csv"
    "HTTP\ Server\ -\ TCP\ Failures.csv"
}

set retrieveResultFileList {
    Test_Client.csv
    Test_Server.csv
    {HTTP Client - Per URL.csv}
    {L2-3 Throughput Stats.csv}
}

proc IxL_RetrieveResultFiles {retrieveResultFileList {deleteResultsTempFolder 0}} {
    # Description
    #    Retrieve all the IxLoad result files from IxLoad to local Linxux
    #    and copy all the wanted result files into a local results folder.
    #
    #    1> Create a local folder to save the wanted results called ixLoadTestResults.
    #    2> If folder doesn't exists, create it.
    #    3> Copy all IxLoad result files to local Linux folder called ixLoadTestResultTemp.
    #    4> If folder doesn't exists, create it.
    #    5> Remove all the junk files such as *.xml, *.metadata and *.jpg
    #    6> Loop through each wanted result file.
    #       If found, save it in folder ixLoadTestResults.
    #    7> At the end, if the variable deleteResultsTempFolder == 1, delete the ixLoadTestResultTemp folder. 
    #
    # Parameters
    #    retrieveList: A list of all the result file names to retrieve.
    #    deleteResultsTempFolder: 0|1: 0 = Don't delete the folder containing all the IxLoad result files.
    #                                  1 = Delete 

    set resultsTempFolder ixLoadTestResultsTemp2
    set saveToFolder ixLoadTestResults
    
    # Create the temp folder first
    if {[file exists $resultsTempFolder] == 0} {
	file mkdir $resultsTempFolder
    }
    
    if {[file exists $saveToFolder] == 0} {
	file mkdir $saveToFolder
    }
    
    # Retrieve all the IxLoad result files
    # ::IxLoad retrieveResults $resultsTempFolder
    
    # Remove all the junk files in case user wants to look in the folder
    catch {eval file delete [glob $resultsFolder/*.xml]}
    catch {eval file delete [glob $resultsFolder/*.jpg]}
    catch {eval file delete [glob $resultsFolder/*.metadata]}
    
    foreach resultFile $retrieveResultFileList {
	set currentFile [glob -nocomplain -dir $resultsTempFolder *$resultFile]
	puts "\nSearch for result file: $resultFile"
	
	if {$currentFile == ""} {
	    puts "\tFile not found: $resultFile"
	    continue
	} 

	# currentFile: {ixLoadTestResultsTemp2/HTTP Client - Per URL.csv}
	set copyFile [lindex $currentFile 0]

	if {[llength [split $copyFile " "]] == 1} {
	    puts "\tFound: [lindex $currentFile 0]: lenth:[llength $currentFile]"
	    # currentFile: {ixLoadTestResultsTemp/Test_Server.csv}
	    set destFile [lindex [split $copyFile "/"] end]
	    puts "\tCopying to $saveToFolder/$destFile ..."
	    file copy -force $copyFile $saveToFolder/$resultFile
	}
	
	if {[llength [split $copyFile " "]] == 2} {
	    puts "\tFound: [lindex $currentFile 0]: lenth:[llength $currentFile]"
	    # currentFile: {ixLoadTestResultsTemp/IxL_Http_Ipv4Ftp_vm_8.20_20180101_161018 Test_Server.csv}
	    set destFile [lindex [split $copyFile " "] end]
	    puts "\tCopying to $saveToFolder/$destFile ..."
	    file copy -force $copyFile $saveToFolder/$destFile
	}
	
	if {[llength [split $copyFile " "]] > 2} {
	    if {[regexp "\{" $copyFile]} {
		# currentFile: ixLoadTestResultsTemp/IxL_Http_Ipv4Ftp_vm_8.20_20180101_161018\ \{HTTP\ Client\ -\ Per\ URL.csv
		set destFile [lrange [split $copyFile " "] 1 end]
		set destFile [string range $destFile 2 end]
		set destFile [string map {" " ""} $destFile]
	    } else {
		# ixLoadTestResultsTemp2/L2-3 Throughput Stats.csv
		set destFile [lindex [split $copyFile "/"] end]
		set destFile [string map {" " ""} $destFile]
	    }

	    puts "\tCopying to $saveToFolder/$destFile ..."
	    file copy -force $copyFile $saveToFolder/$destFile
	}
    }
    
    if {$deleteResultsTempFolder == 1} {
	file delete -force $resultsTempFolder
    }
}

proc IxL_GeneratePdfReport {testController pdfPathOnWindows testName} {
    # This will first remove the existing PDF file on Windows c: drive.
    # Then Generate a new PDF file.
    
    puts "Generating PDF result file ..."
    if {[catch {$testController generateReport -detailedReport 0 -format "PDF" -orientation "Portrait" -outputFile $pdfPathOnWindows -testName $testName} err] == 1} {
	puts "Failed to generate PDF Report: $err"
    } else {
	puts "PDF Report Generated successful"
    } 
}

proc IxL_CopyFileFromWindows {sourcePath destPath} {
    ::IxLoad retrieveFileCopy $sourcePath $destPath
}

proc IxL_StatCollectorCommand {args} {
    # statcollectorutils {timestamp 140000 stats {{kInt 0} {kInt 1872} {kInt 0} {kInt 0}}}
    set stats [lindex [lindex $args 1] 3]
    set timestamp [lindex [lindex $args 1] 1]

    puts "============================================"
    puts "Incoming stats: Time interval: $timestamp"
    puts "============================================"

    # This is to collect all the stats for csv file logging
    set eachRowStatsForCsv {}

    for {set index 0} {$index <= [llength $stats]} {incr index} {
	# { "HTTP Server" "TCP Connections Established" "kSum" }
	set sourceType [lindex [lindex $::statList $index] 0]
	set statName   [lindex [lindex $::statList $index] 1]
	set statNumber      [lindex [lindex $stats $index] 1]

	if {$sourceType != "" || $statName != ""} {	    
	    puts "$sourceType: $statName: $statNumber"
	    if {$eachRowStatsForCsv == ""} {
		append eachRowStatsForCsv $statNumber
	    } else {
		append eachRowStatsForCsv ",$statNumber"
	    }
	}
    }

    if {[info exists ::csvFilePathAndName]} {
	exec echo $eachRowStatsForCsv >> $::csvFilePathAndName
    }
}

proc IxL_CreateCsvResultFile {} {
    # Create a csv result file on local Linux machine

    set topCsvColumnLine [join $::statList ,]
    
    if {[info exists ::csvFilePathAndName]} {
	puts "\nIxL_CreateCsvResultFile: $::csvFilePathAndName\n"
	exec echo $topCsvColumnLine > $::csvFilePathAndName
    }
}

proc IxL_GetIxLoadFiles { fromWindowsDir filesToGet localFileName} {
    foreach currentFile $filesToGet {
	puts "IxL_GetCsvStatFiles:  $currentFile ..."
	catch {::IxLoad retrieveFileCopy $fromWindowsDir\\$currentFile $localFileName} errMsg
	if {$errMsg != ""} {
	    puts "\nError: Copying file from Windows PC: $currentFile\n"
	}
    }
}

proc ReassignPorts { test repository portsToReassign } { 
    set chassisChain [$repository cget -chassisChain]
    set chassisList [$chassisChain getChassisNames]

    # communityTypes: clientCommunityList serverCommunityList    
    set communityTypes [list clientCommunityList serverCommunityList]
    
    set startListIdx -1
    set endListIdx -1
    set portsToSet {}
    
    foreach communityType $communityTypes {
	set numCommunities [$test ${communityType}.indexCount]
	puts "\nReassignPorts numCommunities: $numCommunities"

	set comunityDestinations {}
	
	# Run through the list of available communities (networks)
	for {set i 0} {$i < $numCommunities} {incr i} {
	    set networkObj [$test ${communityType}($i).cget -network]
	    set currentSourceList [$networkObj cget -portList]
	    set sourceListNum [llength $currentSourceList]
	    
	    # Extract the corresponding target ports 
	    set startListIdx [expr {$endListIdx+1}]
	    set endListIdx [expr { $startListIdx + $sourceListNum - 1 }]		
	    set partialDestinationList [lrange $portsToReassign $startListIdx $endListIdx]
	    set formattedDestinations {}
	    
	    if {[llength $partialDestinationList] == 0 && $sourceListNum != 0} {
		puts "\nError: Unable to remap the hardware. Too few ports.\n"
		::IxLoad delete $repository
		::IxLoad disconnect
	    }

	    # Run through the partial list of destinations and format them nicely
	    foreach currentDestination $partialDestinationList {
		set currentDestinationChassis [lindex $currentDestination 0]
		set currentDestinationCard [lindex $currentDestination 1]
		set currentDestinationPort [lindex $currentDestination 2]
		lappend formattedDestinations "\"$currentDestinationChassis;$currentDestinationCard;$currentDestinationPort\""
	    }
	    set comunityDestinations [concat $comunityDestinations \{$formattedDestinations\}]
	}
	set portsToSet [concat $portsToSet $comunityDestinations]
    }

    puts "\nReassigning ports: $portsToSet\n"
    
    if {[catch {$test setPorts $portsToSet}]} { 
	puts "\nError: Could not remap for target $portsToSet.\n"
	::IxLoad delete $repository
	::IxLoad disconnect
    }
}


set connectStatus [::IxLoad connect $windowsClientIp]
if {$connectStatus == ""} {
    puts "\nSuccessfully connected to $windowsClientIp"
    # signal action siglist ?command?
} else {
    puts "\nFailed to connect to $windowsClientIp"
    exit
}

#IxL_RetrieveResultFiles $retrieveResultFileList
#exit

#signal trap [list SIGKILL SIGHUP SIGTERM] [::IxLoad disconnect;exit]

# setup logger
set logtag "IxLoad-api"

# This statCollectorUtils package must be loaded AFTER IxLoad connect and aafter set logtag
package require statCollectorUtils

# Stats are located at: C:\Program x86\Ixia\IxLoad\6.50EA\TclScripts\remoteScriptingService\RESULTS
set logName "reprun"
set logger [::IxLoad new ixLogger $logtag 1]
set logEngine [$logger getEngine]

$logEngine setLevels $::ixLogger(kLevelDebug) $::ixLogger(kLevelInfo)
$logEngine setFile $logName 4 2048 1

#::IxLoad retrieveResults myResults

#-----------------------------------------------------------------------
# Create a test controller bound to the previosuly allocated # chassis chain. 
# This will eventually run the test we created earlier.
#-----------------------------------------------------------------------
# By stating -outputDir = 1, means to enable csv logging
set testController [::IxLoad new ixTestController -outputDir 1]
set repository  [::IxLoad new ixRepository -name $configFile]
set testName    [$repository testList(0).cget -name]
set test        [$repository testList.getItem $testName]
$testController setResultDir $resultDirectoryOnWindows
$testController enableAutoGenerateReport 1

puts "\nTest Controller: $testController"
puts "\nRepository: $repository"
puts "\nTest name: $testName"
puts "\nTest: $test"

# To capture ctrl-c signal and exit gracefully. This works for Expect.
#trap  {$testController stopRun;::IxLoad disconnect;exit} SIGINT

#----- Inserting port remapping begin ------"
if {[info exists portsToReassign]} {
    ReassignPorts $test $repository $portsToReassign
}

set testConfigStatus [$test config \
			  -csvInterval 2 \
			  -enableForceOwnership true \
			  -enableResetPorts 0 \
			  -statsRequired 1 \
		     ]
if {$testConfigStatus != ""} {
    puts "\nError: Test Config failed"
    exit
}

puts "\nRunning all tests in repository $testName"

# Get real time stats
set NS statCollectorUtils

set test_server_handle [$testController getTestServerHandle]
${NS}::Initialize -testServerHandle $test_server_handle

${NS}::ClearStats
$test clearGridStats

set statList [concat $HTTP_Client_StatList $HTTP_Server_StatList]

set count 1
foreach stat $statList {
    set caption         [format "Watch_Stat_%s" $count]
    set statSourceType  [lindex $stat 0]
    set statName        [lindex $stat 1]
    set aggregationType [lindex $stat 2]
    
    # StatUtils::AddStat
    ${NS}::AddStat \
	-caption            $caption \
	-statSourceType     $statSourceType \
	-statName           $statName \
	-aggregationType    $aggregationType \
	-filterList         {}
    
	incr count
}

IxL_CreateCsvResultFile 

${NS}::StartCollector -command IxL_StatCollectorCommand -interval 2

# Press <RETURN> or <ENTER> to gracefully abort test
# set test controller monitor to an empty value
# IxLoad will set it to something else when the test is done
set ::ixTestControllerMonitor ""

# Start the test
$testController run $test

if 0 {
# --------------------------------------------------------
# For graceful abortion by pressing the <ENTER> key
fconfigure stdin -blocking 0 -buffering none
# wait for the first sample or test stop
while {$::ixTestControllerMonitor == "" && [read stdin] == ""} {
    after 100 
    set wakeup 1
    # The script must call vwait or update while test runs 
    # to keep TCL event loop going. Otherwise, no stat collector
    # callbacks will be made, and ixTestControllerMonitor will
    # never be set.
    vwait wakeup
}
# If aborted, then stop test gracefully
if {$::ixTestControllerMonitor == ""} {
    puts "\nAborting test at earliest opportunity!!!"
    # stop the run
    $testController stopRun
    # (v)wait until the test really stops
    #vwait ::ixTestControllerMonitor
    #puts $::ixTestControllerMonitor
}
# --------------------------------------------------------
}

vwait ::ixTestControllerMonitor
puts $::ixTestControllerMonitor

${NS}::StopCollector

if {$generatePdfResult} {
    IxL_GeneratePdfReport $testController $pdfPathOnWindows $testName
}

IxL_CopyFileFromWindows $pdfPathOnWindows ./IxLoadTestResult.pdf

$testController releaseConfigWaitFinish

# Cleanup
::IxLoad delete $repository
::IxLoad delete $testController
::IxLoad delete $logger
::IxLoad delete $logEngine

puts "\nIxLoad test is done\n"

IxL_RetrieveResultFiles $retrieveResultFileList

# Another example on how to retrieve individual files from Windows to local Linux.
# This last part is commented out. Enable it only if you need to copy/retrieve
# something from the Windows PC to your local Linux machine.
# This is just an example to show you how to retrieve files off of the Windows
# C: drive.

if 0 {
# Retrieve the csv statistic files from Windows to local Linux machine
foreach statFile $statsToGet {
    set localStatFile ixLoad_[string map {" " ""} [string map {- _} $statFile]]
    puts "Getting csv stats:  $statFile ..."
    catch {::IxLoad retrieveFileCopy $resultDirectoryOnWindows\\$statFile $localStatFile} errMsg
    if {$errMsg != ""} {
	puts "\nError: Copying csv stat file from Windows PC: $statFile\n"
    }
}
}

::IxLoad disconnect
