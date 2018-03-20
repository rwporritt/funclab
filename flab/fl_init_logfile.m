function fl_init_logfile (LogFile,InitData)
%FL_INIT_LOGFILE Starts new log file
%   FL_INIT_LOGFILE writes the  opening lines of a new log file and saves
%   it to a text file in the project directory.

%   Author: Kevin C. Eagar
%   Date Created: 01/07/2008
%   Last Updated: 09/08/2009

fid = fopen(LogFile,'w');
if (fid == -1) 
  error('Cannot open file')
end
fprintf(fid,'          FUNCLAB LOG FILE\n');
ProjectDir = regexprep(LogFile,'/Logfile.txt','');
fprintf(fid,'          Project Directory: %s\n',ProjectDir);
CTime = clock;
fprintf(fid,'          Created: %02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f\n',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6));
fprintf(fid,'          Last Updated: %02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f\n',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6));
fprintf(fid,'\n');
CTime = clock;
fprintf(fid,'%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - Initiated FuncLab Project\n',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6));
DataDir = [ProjectDir '/RAWDATA'];
Data = dir(DataDir);
Data = sortrows({Data.name}');
Data = Data(3:end);
for n = 1:length(InitData)
    fprintf(fid,'     %.0f. Copied Data Directory: %s to %s\n',n*2-1,InitData{n},DataDir);
    fprintf(fid,'     %.0f. Imported Data To Station and Event Tables: %s\n',n*2,[DataDir '/' Data{n}]);
end
CTime = clock;
fprintf(fid,'%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - Created and Saved New Trace Editing Preferences\n',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6));
fclose(fid);