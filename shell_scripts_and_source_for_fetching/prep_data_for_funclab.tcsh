#!/bin/tcsh

# Script to prepare data for use in FuncLab's Compute->Compute new RFs interface
# Based on a test for data from the Banda network, which includes mostly BH1, BH2, and BHZ data
# Also has some -1.SAC files, which need to be cleaned up
# Assumes data has been downloaded with FetchData and entered into directories formatted as
# Event_YYYY_JJJ_HH_MM_SS
# and the data is in sac files, created by miniseed2sac (version2.0)
# Steps:
# First, remove -1.SAC files. These are just dupilcates
# Second, move the location code to the end of the station name in the file name
# Third, remove dead traces
# Fourth, remove non-three component traces
# Fifth, add event parameters.
# Sixth, interpolate data
# Seventh, rotate and rename BH1 to BHN and BH2 to BHE and adjust in sac header
#
# Note, this requires SAC to properly operate
# It also assumes Event Parameter files were created as in request_data.tcsh
#

set dt = 0.025

# Loop over event directories. Will work in place, so backup data first if you're concerned
foreach event (`ls -d Event_*/`)
  cd $event
  echo "Working on $event"


  # Parse the event directory name and parameter file
  set year = `echo $event | awk -F_ '{print $2}'`
  set jday = `echo $event | awk -F_ '{print $3}'`
  set hour = `echo $event | awk -F_ '{print $4}'`
  set minute = `echo $event | awk -F_ '{print $5}'`
  set second = `echo $event | awk -F/ '{print $1}' | awk -F_ '{print $6}'`
  set evla = `awk '{if (NR == 3) print $1}' ../EventParams/Event_${year}_${jday}_${hour}_${minute}_${second}.event.params`
  set evlo = `awk '{if (NR == 3) print $2}' ../EventParams/Event_${year}_${jday}_${hour}_${minute}_${second}.event.params`
  set evdp = `awk '{if (NR == 3) print $3 * 1000}' ../EventParams/Event_${year}_${jday}_${hour}_${minute}_${second}.event.params`
  set evmag = `awk '{if (NR == 3) print $4}' ../EventParams/Event_${year}_${jday}_${hour}_${minute}_${second}.event.params`

  # 1.
  # These files occur from mseed2sac to avoid overwriting files
  echo "Removing duplicate sac files"
  rm *-1.SAC


  # 2.
  # Gets each unique network/station/location
  echo "adding location code to station name"
  foreach netstaloc (`ls *.SAC | awk -F. '{print $1"_"$2"_"$3}' | sort | uniq`)
    set net = `echo $netstaloc | awk -F_ '{print $1}'`
    set sta = `echo $netstaloc | awk -F_ '{print $2}'`
    set loc = `echo $netstaloc | awk -F_ '{print $3}'`

    # Gets each waveform for this unique net/sta/loc
    foreach wf (`ls ${net}.${sta}.${loc}.*.SAC`)
      # YS.TL04..BHZ.M.2016.338.092840.SAC
      set chan = `echo $wf | awk -F. '{print $4}'`
      set qual = `echo $wf | awk -F. '{print $5}'`
      set yy = `echo $wf | awk -F. '{print $6}'`
      set dd = `echo $wf | awk -F. '{print $7}'`
      set ts = `echo $wf | awk -F. '{print $8}'`
      mv $wf ${net}.${sta}${loc}..${chan}.${qual}.${yy}.${dd}.${ts}.SAC
    end # end each wf

  end # end each netstaloc

  # 3.
  # remove dead traces. requires saclst utility that is distributed with sac
  echo "Removing dead traces with saclst"

# This call to sac initializes the depmin and depmax
sac << EOF
read *.SAC
write over
quit
EOF

  foreach sf (`ls *.SAC`)

    set depmin = `saclst depmin f $sf | awk '{print $2}'`
    set depmax = `saclst depmax f $sf | awk '{print $2}'`
    if ($depmin == $depmax || $depmin == "-nan" || $depmin == "nan" || $depmax == "-nan" || $depmax == "nan") then
      echo "rm $sf"
      #rm $sf
    endif

  end

  # 4.
  # Counts the sac files for each net/station/loc and forces exactly 3
  # If you're worried about scrapping together every bit of data, you may need to merge data first
  echo "Removing non-three component data"
  foreach netstaloc (`ls *.SAC | awk -F. '{print $1"_"$2"_"$3}' | sort | uniq`)
    set net = `echo $netstaloc | awk -F_ '{print $1}'`
    set sta = `echo $netstaloc | awk -F_ '{print $2}'`
    set loc = `echo $netstaloc | awk -F_ '{print $3}'`

    set nsac = `ls ${net}.${sta}.${loc}.*.SAC | wc | awk '{print $1}'`
    if ($nsac != 3) then
      echo "Removing $net $sta $loc"
      rm ${net}.${sta}.${loc}.*.SAC
    endif
  end

  # 5.
  # Adds event metadata to the sac headers. Really would be better to do in the mseed2sac step of the request_data.tcsh script
  # Note, do not move off the left justified as it can mess up the interpretation
  echo "Adding header information"

sac << EOF
read *.SAC
ch o GMT $year $jday $hour $minute $second
ch evla $evla evlo $evlo evdp $evdp mag $evmag
write over
quit
EOF

  # 6.
  # interpolate
  echo "Interpolating to a common delta: $dt"

sac << EOF
read *.SAC
interpolate delta $dt
write over
quit
EOF

  # 7.
  # Rotate and rename BH1 and BH2 into BHN and BHE
  echo "Rotating data"
  foreach netstaloc (`ls *.SAC | awk -F. '{print $1"_"$2"_"$3}' | sort | uniq`)
    set net = `echo $netstaloc | awk -F_ '{print $1}'`
    set sta = `echo $netstaloc | awk -F_ '{print $2}'`
    set loc = `echo $netstaloc | awk -F_ '{print $3}'`
    foreach chan (`ls ${net}.${sta}.${loc}.*SAC | awk -F. '{print $4}'`)
      if ($chan == "BH1") then
        set sf = `ls ${net}.${sta}.${loc}.${chan}.*.SAC`
        set tail = `echo $sf | awk -F. '{print $5"."$6"."$7"."$8"."$9}'`
        mv $sf ${net}.${sta}.${loc}.BHN.${tail}
        set chan = "BHN"

sac << EOF
read ${net}.${sta}.${loc}.BHN.${tail}
ch kcmpnm BHN
write over
quit
EOF

      endif

      if ($chan == "BH2") then
        set sf = `ls ${net}.${sta}.${loc}.${chan}.*.SAC`
        set tail = `echo $sf | awk -F. '{print $5"."$6"."$7"."$8"."$9}'`
        mv $sf ${net}.${sta}.${loc}.BHE.${tail}
        set chan = "BHE"

sac << EOF
read ${net}.${sta}.${loc}.BHE.${tail}
ch kcmpnm BHE
write over
quit
EOF

      endif
    end # end each chan

    # Rotate

sac << EOF
read ${net}.${sta}.${loc}.BHN.* ${net}.${sta}.${loc}.BHE.*
rotate to 0 normal
write over
quit
EOF


  end

  # Done with this event, so backup for next event
  cd ../

end
