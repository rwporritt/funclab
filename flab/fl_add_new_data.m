function [RecordMetadataStrings,RecordMetadataDoubles] = fl_add_new_data(ProjectDirectory,ProjectFile,DataDirectory)
%FL_ADD_NEW_DATA Create new station tables
%   FL_ADD_NEW_DATA(ProjectDirectory,ProjectFile,DataDirectory) copies the
%   data directory to the project directory, loads receiver function SAC
%   files into metadata tables within the project.  The output is the
%   metadata cell and numeric arrays.

%   Author: Kevin C. Eagar
%   Date Created: 07/21/2007
%   Last Updated: 04/30/2011

tStart=tic;

% Get the Event Directories in the Data Directory
%--------------------------------------------------------------------------
FullDataDirectory = [ProjectDirectory 'RAWDATA' filesep DataDirectory];
Events = dir([FullDataDirectory filesep 'Event*']);  % Event directories must begin with 'Event'. Also, looks by the / it might only work on unixy systems
if isempty(Events)
    tElapsed=toc(tStart);
    error(['The data directory (' Events ') contains no events.  Time elapsed before error = ' tElapsed ' sec.']);
end
Events = sortrows({Events.name}');
count = 0;
for n = 1:length(Events)
    Files = dir([FullDataDirectory filesep Events{n} filesep '*.eqr']); % another place where 'filesep' could be used. needs files to end in .eqr
    count = count + length(Files);
end
    
% Load the existing station tables and the LastID, if they exist
%--------------------------------------------------------------------------
if exist([ProjectDirectory ProjectFile],'file')
    load([ProjectDirectory ProjectFile],'SetManagementCell')
    RecordMetadataStrings = SetManagementCell{1,2};
    RecordMetadataDoubles = SetManagementCell{1,3};
    LastID = size(RecordMetadataStrings,1);
    RecordMetadataStrings = vertcat(RecordMetadataStrings,cell(count,3));
    RecordMetadataDoubles = vertcat(RecordMetadataDoubles,NaN .* ones(count,19));
else
    
    RecordMetadataStrings = cell(count,3);
    RecordMetadataDoubles = NaN .* ones(count,19);
    LastID = 0;
end

FullDataDirectory = [ProjectDirectory 'RAWDATA' filesep DataDirectory];

% Load in each file at a time and populate the Event tables
%--------------------------------------------------------------------------
WarningCount = 0;
for n = 1:length(Events)
    RFs = dir([FullDataDirectory filesep Events{n} filesep '*.eqr']);
    if isempty(RFs)
        display('No receiver functions for this event.')
        % 04/30/2011: FIXED ERROR IN SYNTAX AND ADDED ERROR CHECKING TO
        % SCRIPT
        [status, message] = rmdir([FullDataDirectory filesep Events{n}],'s');
        if status==0
            display(message)
            display(['Cannot remove directory ' FullDataDirectory filesep Events{n}])
        else
            display(['Removed directory ' FullDataDirectory filesep Events{n}])
        end
    else
        % Here is where the event origin time is parsed from the event
        % directory file name
        [junk,YYYY,JJJ,HH,MM,SS] = strread(Events{n},'%s %04.0f %03.0f %02.0f %02.0f %02.0f','delimiter','_');
        EventOriginTime = [num2str(YYYY,'%04.0f ') filesep num2str(JJJ,'%03.0f') filesep ...
            num2str(HH,'%02.0f') ':' num2str(MM,'%02.0f') ':' num2str(SS,'%02.0f')];
        RFs = sortrows({RFs.name}');
        for m = 1:length(RFs)
            NewID = LastID + 1;
            sacfile = RFs{m};
            RecordMetadataStrings{NewID,1} = ['RAWDATA' filesep DataDirectory filesep Events{n} filesep sacfile(1:end-3)];
            RecordMetadataStrings{NewID,3} = EventOriginTime;
            RecordMetadataDoubles(NewID,1) = 0;
            
            % Check the byte-order of the sac file
            %--------------------------------------------------------------
            fid = fopen([FullDataDirectory filesep Events{n} filesep sacfile],'r','ieee-be');
            fread(fid,70,'single');
            fread(fid,6,'int32');
            NVHDR = fread(fid,1,'int32');
            fclose(fid);
            if (NVHDR == 4 || NVHDR == 5)
                tElapsed=toc(tStart);
                message = strcat('NVHDR = 4 or 5. File: "',sacfile,'" may be from an old version of SAC.  Time elapsed before error = ',tElapsed,' sec.');
                error(message)
            elseif NVHDR ~= 6
                endian = 'ieee-le';
            elseif NVHDR == 6
                endian = 'ieee-be';
            end
            
            % open sac file and add header information
            %--------------------------------------------------------------
            fid = fopen([FullDataDirectory filesep Events{n} filesep sacfile],'r',endian);
            filename = [FullDataDirectory filesep Events{n} filesep sacfile];
            TimeDelta = fread(fid,1,'single');
            RecordMetadataDoubles(NewID,3) = TimeDelta;
            fread(fid,4,'single');
            BeginTime = fread(fid,1,'single');
            RecordMetadataDoubles(NewID,5) = BeginTime;
            fread(fid,1,'single');
            fread(fid,24,'single');
            RecordMetadataDoubles(NewID,10) = fread(fid,1,'single'); %StaLat
            RecordMetadataDoubles(NewID,11) = fread(fid,1,'single'); %StaLon
            RecordMetadataDoubles(NewID,12) = fread(fid,1,'single') / 1000; %StaElev (km)
            % Check that station metadata is properly loaded. Send a warning to the command window if missing information
            if RecordMetadataDoubles(NewID,10) < -1000   % Note that the sacnull value is -12345
                fprintf('Error, station (%s) latitude given: %f \n',sacfile, RecordMetadataDoubles(NewID,10) );
            end
            if RecordMetadataDoubles(NewID,10) < -1000
                fprintf('Error, station (%s) longitude given: %f \n',sacfile, RecordMetadataDoubles(NewID,11) );
            end
            fread(fid,1,'single');
            RecordMetadataDoubles(NewID,13) = fread(fid,1,'single'); %EvLat
            RecordMetadataDoubles(NewID,14) = fread(fid,1,'single'); %EvLon
            if RecordMetadataDoubles(NewID,10) < -1000   % Note that the sacnull value is -12345
                fprintf('Error, event (%s) latitude given: %f \n',sacfile, RecordMetadataDoubles(NewID,13) );
            end
            if RecordMetadataDoubles(NewID,10) < -1000
                fprintf('Error, event (%s) longitude given: %f \n',sacfile, RecordMetadataDoubles(NewID,14) );
            end
            fread(fid,1,'single');
            RecordMetadataDoubles(NewID,15) = fread(fid,1,'single') /1000; %EvDepth (km)
            if RecordMetadataDoubles(NewID,15) < 1   %  Assume very shallow are actually in meters
                RecordMetadataDoubles(NewID,15) = RecordMetadataDoubles(NewID,15) * 1000;
            end
            if RecordMetadataDoubles(NewID,15) > 1000   % Assumes very deep events are in megameters
                RecordMetadataDoubles(NewID,15) = RecordMetadataDoubles(NewID,15) / 1000;
            end
            RecordMetadataDoubles(NewID,16) = fread(fid,1,'single'); %EvMag
            RecordMetadataDoubles(NewID,7) = fread(fid,1,'single'); %Gauss - aka user0
            RecordMetadataDoubles(NewID,18) = srad2skm(fread(fid,1,'single')); %RayP - aka user1
            if RecordMetadataDoubles(NewID,18) < 0 || RecordMetadataDoubles(NewID,18) > 1
                fprintf('Warning, record ray parameter for %s is negative or big (%f)\n',sacfile, RecordMetadataDoubles(NewID,18));
                fprintf('Computing for assumed direct P via taup');
                % Check for invalid station or event parameters. If one of
                % the 5 is not in the sac header, assigns a ray parameter
                % of 0.001
                if RecordMetadataDoubles(NewID,10) < -90  ||  RecordMetadataDoubles(NewID,10) > 90  || ...
                   RecordMetadataDoubles(NewID,11) < -180 ||  RecordMetadataDoubles(NewID,11) > 360 || ...
                   RecordMetadataDoubles(NewID,13) < -90  ||  RecordMetadataDoubles(NewID,13) > 90  || ...
                   RecordMetadataDoubles(NewID,14) < -180 ||  RecordMetadataDoubles(NewID,14) > 360 || ...
                   RecordMetadataDoubles(NewID,15) < 0    ||  RecordMetadataDoubles(NewID,15) > 1000
                        
                        tt = taupTime([], RecordMetadataDoubles(NewID,15), 'P','sta',[RecordMetadataDoubles(NewID,10), RecordMetadataDoubles(NewID,11)],'evt',[RecordMetadataDoubles(NewID,13), RecordMetadataDoubles(NewID,14)]);
                        RecordMetadataDoubles(NewID,18) = srad2skm(tt.rayParam);
                else
                    RecordMetadataDoubles(NewID,18) = 0.001;
                end
                        
            end
            fread(fid,6,'single');
            PreStatus = fread(fid,1,'single'); %USER8 (Predetermined Status within SAC file)
            if PreStatus == 1 || PreStatus == 0
                RecordMetadataDoubles(NewID,2) = PreStatus;
            else
                RecordMetadataDoubles(NewID,2) = 1;
            end
            if RecordMetadataDoubles(NewID,10) == -12345 || RecordMetadataDoubles(NewID,11) == -12345 || RecordMetadataDoubles(NewID,13) == -12345 || RecordMetadataDoubles(NewID,14) == -12345  || RecordMetadataDoubles(NewID,17) == -12345 || RecordMetadataDoubles(NewID,19) == -12345
                if WarningCount == 0
                    disp('WARNING: At least one record has incorrect Ray Parameter information in the SAC file.  These records will automatically be turned off for future analysis.')
                end
                RecordMetadataDoubles(NewID,2) = 0;
            end
            RadFit = fread(fid,1,'single'); %USER9
            if RadFit == -12345
                RadFit = NaN;
            end
            RecordMetadataDoubles(NewID,8) = RadFit;
            fread(fid,1,'single');
            fread(fid,1,'single');
            RecordMetadataDoubles(NewID,19) = fread(fid,1,'single'); %Baz
            RecordMetadataDoubles(NewID,17) = fread(fid,1,'single'); %DistDeg
            if RecordMetadataDoubles(NewID,19) == -12345 || RecordMetadataDoubles(NewID,17) == -12345
                [~, azi, xdeg] = distaz(RecordMetadataDoubles(NewID,10), RecordMetadataDoubles(NewID,11), RecordMetadataDoubles(NewID,13), RecordMetadataDoubles(NewID,14));
                RecordMetadataDoubles(NewID,17) = xdeg;
                RecordMetadataDoubles(NewID,19) = azi;
            end
            fread(fid,5,'single');
            fread(fid,20,'int32');
            SampleCount = fread(fid,1,'int32');
            RecordMetadataDoubles(NewID,4) = SampleCount;
            fread(fid,30,'int32');
            
            % read character header variables
            %--------------------------------------------------------------
            StationName = deblank(char(fread(fid,8,'char')'));
            fread(fid,1,'char',151);
            fread(fid,8,'char');
            NetworkName = deblank(char(fread(fid,8,'char')'));
            
            % close SAC file
            %--------------------------------------------------------------
            fclose(fid);
            Station = [NetworkName '-' StationName];
            RecordMetadataStrings{NewID,2} = Station;
            
            % Check to make sure this record is NOT in our metadata.  If it
            % IS, then delete the "new" one and skip it.
            %--------------------------------------------------------------
            OldMetadata = RecordMetadataStrings(1:NewID-1,:);
            if ~isempty(intersect(strmatch(EventOriginTime,OldMetadata(:,3),'exact'),strmatch(Station,OldMetadata(:,2),'exact')))
                display(['Record for event ' EventOriginTime ' and station ' Station ' already exists in the metadata.'])
                display('No new record was added.')
                RecordMetadataStrings(NewID,:) = [];
                RecordMetadataDoubles(NewID,:) = [];
                delete([FullDataDirectory filesep Events{n} filesep sacfile])
                sacfile = sacfile(1:end-3);  % here is where its basically a set file name and the end is appended .eqt, .r, .t, or .z
                if exist([FullDataDirectory filesep Events{n} filesep sacfile 'eqt'],'file')
                    delete([FullDataDirectory filesep Events{n} filesep sacfile 'eqt'])
                end
                if exist([FullDataDirectory filesep Events{n} filesep sacfile 'r'],'file')
                    delete([FullDataDirectory filesep Events{n} filesep sacfile 'r'])
                end
                if exist([FullDataDirectory filesep Events{n} filesep sacfile 't'],'file')
                    delete([FullDataDirectory filesep Events{n} filesep sacfile 't'])
                end
                if exist([FullDataDirectory filesep Events{n} filesep sacfile 'z'],'file')
                    delete([FullDataDirectory filesep Events{n} filesep sacfile 'z'])
                end
                continue
            end
                
            % read the transverse receiver function for the TransFit (if
            % the transverse receiver function exists)
            %--------------------------------------------------------------
            sacfile(end) = 't';
            if exist([FullDataDirectory filesep Events{n} filesep sacfile],'file')
                fid = fopen([FullDataDirectory filesep Events{n} filesep sacfile],'r','ieee-be');
                fread(fid,70,'single');
                fread(fid,6,'int32');
                NVHDR = fread(fid,1,'int32');
                fclose(fid);
                if (NVHDR == 4 || NVHDR == 5)
                    tElapsed=toc(tStart);
                    message = strcat('NVHDR = 4 or 5. File: "',sacfile,'" may be from an old version of SAC.  Time elapsed before error = ',tElapsed,' sec.');
                    error(message)
                elseif NVHDR ~= 6
                    endian = 'ieee-le';
                elseif NVHDR == 6
                    endian = 'ieee-be';
                end
                %fid = fopen([FullDataDirectory filesep Events{n} filesep sacfile],filesep,endian);
                fid = fopen([FullDataDirectory filesep Events{n} filesep sacfile],'r',endian);
                fread(fid,49,'single');
                TransFit = fread(fid,1,'single'); %USER9
                if TransFit == -12345
                    TransFit = NaN;
                end
                fclose(fid);
            else
                TransFit = NaN;
            end
            RecordMetadataDoubles(NewID,9) = TransFit;
                
            % Calculate the end time from the delta, number of points, and
            % the begin time.
            %--------------------------------------------------------------
            RecordMetadataDoubles(NewID,6) = (TimeDelta * SampleCount) + BeginTime - TimeDelta;

            LastID = NewID;
        end
        Files = dir([FullDataDirectory filesep Events{n}]);
        Files = Files(cat(1,Files.isdir)==0);
        if isempty(Files)
            rmdir([FullDataDirectory filesep Events{n}])
        end
    end
end
Events = dir(FullDataDirectory);
Events(1:2) = [];
if isempty(Events)
    rmdir(FullDataDirectory)
else
    if exist([ProjectDirectory ProjectFile],'file')
        SetManagementCell{1,2} = RecordMetadataStrings;
        SetManagementCell{1,3} = RecordMetadataDoubles;
        save([ProjectDirectory ProjectFile],'RecordMetadataStrings','RecordMetadataDoubles','SetManagementCell','-append')
    else
        SetManagementCell{1,2} = RecordMetadataStrings;
        SetManagementCell{1,3} = RecordMetadataDoubles;
        save([ProjectDirectory ProjectFile],'RecordMetadataStrings','RecordMetadataDoubles','SetManagementCell')
    end
end