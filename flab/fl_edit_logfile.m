function fl_edit_logfile (LogFile,NewLog)
%FL_EDIT_LOGFILE Add new line to log file
%   FL_EDIT_LOGFILE(LogFile,NewLog) adds the string "NewLog" to the end
%   of the log file, and changes the 4th line to reflect the time that the
%   log file was updated.

%   Author: Kevin C. Eagar
%   Date Created: 01/07/2008
%   Last Updated: 05/13/2010

fid = fopen(LogFile,'r');
if (fid == -1) 
  error('Cannot open file')
end
Count = 0;
while 1
    Count = Count + 1;
    tline = fgetl(fid);
     if ~ischar(tline)
         break
     end
     Log{Count} = tline;
end
CTime = clock;
Log{4} = sprintf('          Last Updated: %02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6));
fclose(fid);

fid = fopen(LogFile,'w');
if (fid == -1) 
  error('Cannot open file')
end
for n = 1:length(Log)
    fprintf(fid,'%s\n',Log{n});
end
for n = 1:length(NewLog)
    fprintf(fid,'%s\n',NewLog{n});
end
fclose(fid);