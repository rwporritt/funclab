#!/bin/tcsh

# Script to pull data via web services
# Uses fetchEvent to find possible events, create_arrival_window to window the data, and fetchData to grab waveforms

# Requires some perl libraries to make FetchData work.

## Setup event search parameters
set regionCenterLat = 9
set regionCenterLon = 122
set startEventSearchTime = "2014-01-01:00:00:00"
set endEventSearchTime = "2018-01-24:00:00:00"
set minRadius = 30
set maxRadius = 120
set minMag = 5.5
set maxMag = 10.0
set eventOutFile = events_found.dat

## Setup phase info for taup
set phaseID = "P"
set leadMinute = 5
set endMinute = 10
set leadSecond = `echo $leadMinute | awk '{print $1 * 60}'`
set endSecond = `echo $endMinute | awk '{print $1 * 60}'`


# Fetch Data parameters for stations
set regionMinLat = -11
set regionMaxLat = -5
set regionMinLon = 114
set regionMaxLon = 131

if (! -d EventParams) mkdir EventParams

## Call fetch event to return a data file with the events
#FetchEvent -s $startEventSearchTime -e $endEventSearchTime -radius ${regionCenterLat}:${regionCenterLon}:${maxRadius}:${minRadius} -mag ${minMag}:${maxMag} -o $eventOutFile
#FetchEvent -s $startEventSearchTime -radius ${regionCenterLat}:${regionCenterLon}:${maxRadius}:${minRadius} -mag ${minMag}:${maxMag} -o $eventOutFile
./FetchEvent -s $startEventSearchTime -e $endEventSearchTime -mag ${minMag}:${maxMag} -o $eventOutFile

set nevents = `wc $eventOutFile | awk '{print $1}'`
echo "Requesting $nevents Earthquakes"

# Make a file with just the magnitudes
 awk -F"|" '{print $9}' $eventOutFile  | awk -F"," '{print $2}' > tmp.mag

## Parse found events and call fetch data for each
foreach evt (`c_utils/event_file_to_params_mags $eventOutFile tmp.mag`)
  set evtTimeFirstPart = `echo $evt | awk -F_ '{print $1}'`
  set evtTimeSecondPart = `echo $evt | awk -F_ '{print $2}'`
  set evtLatitude  = `echo $evt | awk -F_ '{print $3}'`
  set evtLongitude = `echo $evt | awk -F_ '{print $4}'`
  set evtDepth = `echo $evt | awk -F_ '{print $5}'`
  set evtMag = `echo $evt | awk -F_ '{print $6}'`

# Find predicted arrival time at center of network
# Taup can be downloaded at http://www.seis.sc.edu/taup/
# Its java, so will work anywhere, you just need to setup your paths
  set arrivalTime = `Taup-2.4.3/bin/taup_time -sta $regionCenterLat $regionCenterLon -evt $evtLatitude $evtLongitude --time -ph $phaseID -h $evtDepth | head -n 1 | awk '{if ($1 > 0) print 1, $1; else print 0,0}'`
#  set arrivalTime = ( 1 0 )
# A predicted arrival is found, so get data
  if ($arrivalTime[1] == 1) then
# Finds the window around which to cute. requires RWP code create_arrival_window(.c)
    set fetchTimeStringFull = `c_utils/create_arrival_window $evtTimeFirstPart $evtTimeSecondPart $arrivalTime[2] $leadSecond $endSecond`
    echo $evtTimeFirstPart $evtTimeSecondPart $arrivalTime[2] $leadSecond $endSecond
# parameters for a string of info about the event
    set originYear = `echo $evtTimeFirstPart | awk -F"/" '{printf("%04d", $1)}'`
    set originMonth = `echo $evtTimeFirstPart | awk -F"/" '{printf("%02d", $2)}'`
    set originDay = `echo $evtTimeFirstPart | awk -F"/" '{printf("%02d", $3)}'`
    set originHour = `echo $evtTimeSecondPart | awk -F: '{printf("%02d", $1)}'`
    set originMinute = `echo $evtTimeSecondPart | awk -F: '{printf("%02d", $2)}'`
    set originSecond = `echo $evtTimeSecondPart | awk -F: '{print $3}' | awk -F. '{printf"%02d", $1}'`
    set originJday = `c_utils/year_month_day_to_jday $originYear $originMonth $originDay | awk '{printf("%03d",$1)}'`
# a string containing the origin time for organization
#set labelString = `echo "${originYear}_${originMonth}_${originDay}_${originHour}_${originMinute}_${originSecond}"`
    set labelString = `echo Event_${originYear}_${originJday}_${originHour}_${originMinute}_${originSecond}`
    echo $fetchTimeStringFull[1] $fetchTimeStringFull[2]
# This fetchdata will only get the waveform data in miniseed format - note the -C 'BH?' forces only BH{ENZ123} channels
# For restricted data, add:  -a user:pass      User and password for access to restricted data
# Some stations may only have HH? available, so you can consider using that instead.
    echo "./FetchData -s $fetchTimeStringFull[1] -e $fetchTimeStringFull[2] -C 'BH?' --lat ${regionMinLat}:${regionMaxLat} --lon ${regionMinLon}:${regionMaxLon} --radius ${evtLatitude}:${evtLongitude}:${maxRadius}:${minRadius} -m ${labelString}.metafile -o ${labelString}.mseed"
    ./FetchData -s $fetchTimeStringFull[1] -e $fetchTimeStringFull[2] -C 'BH?' --lat ${regionMinLat}:${regionMaxLat} --lon ${regionMinLon}:${regionMaxLon} --radius ${evtLatitude}:${evtLongitude}:${maxRadius}:${minRadius} -m ${labelString}.metafile -o ${labelString}.mseed

# Move data into event directory
    if (-f ${labelString}.mseed) then
      mkdir $labelString
      mv ${labelString}.mseed $labelString
      mv ${labelString}.metafile $labelString
      cd $labelString
        # RWP note: I've had trouble getting a local version of mseed2sac working. I've included the source here, but you may have
        # to add to directory on your path
        mseed2sac ${labelString}.mseed -m ${labelString}.metafile
        rm ${labelString}.mseed ${labelString}.metafile
      cd ../

# prepare an event parameter file
      echo "$originYear $originMonth $originDay $originJday" > EventParams/${labelString}.event.params
      echo "$originHour $originMinute $originSecond" >> EventParams/${labelString}.event.params
      echo "$evtLatitude $evtLongitude $evtDepth $evtMag" >>  EventParams/${labelString}.event.params

    endif


  else
     echo "Sorry, no predicted arrival time found for $evt"
  endif
end
# Clean up - this should not go into directories, so its safe
rmdir Event_*/

exit
