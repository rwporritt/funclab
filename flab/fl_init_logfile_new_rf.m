function fl_init_logfile_new_rf (LogFile,InitData)
%FL_INIT_LOGFILE_NEW_RF Starts new log file
%   FL_INIT_LOGFILE_NEW_RF writes the  opening lines of a new log file and saves
%   it to a text file in the project directory.

%   Author: Rob Porritt
%   Date Created: 05/06/2015
% Edit 12/09/2015 - replaced some unix directory slashes with filesep for
% portability

fid = fopen(LogFile,'w');
if (fid == -1) 
  error('Cannot open file')
end
fprintf(fid,'          FUNCLAB LOG FILE\n');
ProjectDir = regexprep(LogFile,'\Logfile.txt','');
fprintf(fid,'          Project Directory: %s\n',ProjectDir);
CTime = clock;
fprintf(fid,'          Created: %02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f\n',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6));
fprintf(fid,'          Last Updated: %02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f\n',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6));
fprintf(fid,'\n');
CTime = clock;
fprintf(fid,'%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - Initiated FuncLab Project\n',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6));
DataDir = [ProjectDir filesep 'RAWDATA'];
Data = dir(DataDir);
Data = sortrows({Data.name}');
Data = Data(3:end);
for n = 1:length(InitData)
    if ~strcmp(InitData{n},'Removed')
        fprintf(fid,'     %.0f. Copied Data Directory: %s to %s\n',n*2-1,InitData{n},DataDir);
        fprintf(fid,'     %.0f. Imported Data To Station and Event Tables: %s\n',n*2,[DataDir filesep Data{n}]);
    end
end
CTime = clock;
fprintf(fid,'%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - Created and Saved New Trace Editing Preferences\n',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6));
fclose(fid);