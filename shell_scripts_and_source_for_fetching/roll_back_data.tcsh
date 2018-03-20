#!/bin/tcsh

# Assumes all events have been copied into a backup folder named backup
# Script to copy the backup data back into the main folder

cd backup

foreach ff (`ls -d Event_*/`)

if (! -d ../${ff}) then
  echo "Recreating $ff"
  mkdir ../${ff}
  cp ${ff}/*.SAC ../${ff}/
endif


end

cd ../
rmdir Event_*
