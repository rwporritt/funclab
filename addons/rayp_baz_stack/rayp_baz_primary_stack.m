function rayp_baz_primary_stack(cbo,eventdata,handles)
% RAYP_BAZ_PRIMARY_STACK
%  Callback function to run the actual stack outputting SAC files with
%  filenames indicating the ray parameter and back azimuth at the center of
%  the stack
%  Forms the basis for RAYP_BAZ_SECONDARY_STACK
%
%  Author: Robert W. Porritt
%  Date Created: Oct. 7th, 2014


% Time the runtime of this function.
%--------------------------------------------------------------------------
tic

% Get the handles of the FuncLab GUI
%--------------------------------------------------------------------------
h = guidata(gcbf);

% Wait message
%--------------------------------------------------------------------------
WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
    'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
    'String','Please wait, performing ray parameter and backazimuth stacking for the primary RFs in the dataset.',...
    'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
drawnow;
H = guihandles(WaitGui);
guidata(WaitGui,H);

ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
% Sets the name of the set. Removes white spaces and capitalizes between
% words
if CurrentSubsetIndex ~= 1
    SetName = SetManagementCell{CurrentSubsetIndex,5};
    % Remove spaces because they make filesystems go a little haywire
    % sometimes
    SpaceIDX = isspace(SetName);
    for idx=2:length(SetName)
        if isspace(SetName(idx-1))
            SetName(idx) = upper(SetName(idx));
        end
    end
    SetName = SetName(~SpaceIDX);
else
    SetName = 'Base';
end

% Get the Station Table to perform stacking
%--------------------------------------------------------------------------
Value = get(h.MainGui.tablemenu_pu,'Value');
CurrentRecords = evalin('base','CurrentRecords');
CurrentIndices = evalin('base','CurrentIndices');
RecordMetadataStrings = evalin('base','RecordMetadataStrings');
RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
if Value ~= 1
    Tablemenu = evalin('base','Tablemenu');
    if strmatch('RaypBazMetadata',Tablemenu{Value,2})
        RecordIndex = get(h.MainGui.records_ls,'Value');
        Station = CurrentRecords{RecordIndex,2};
        Gaussian = CurrentRecords{RecordIndex,10};
        % Get all records for this selected station and redo
        % CurrentRecords and CurrentIndices
        in = strmatch(Station,RecordMetadataStrings(:,2),'exact');
        CurrentRecords = [RecordMetadataStrings(in,:) num2cell(RecordMetadataDoubles(in,:))];
        [CurrentRecords,ind] = sortrows(CurrentRecords,Tablemenu{Value,4});
        CurrentIndices = in(ind);
    else
        TableIndex = get(h.MainGui.tables_ls,'Value');
        TableList = get(h.MainGui.tables_ls,'String');
        TableName = TableList{TableIndex};
        disp(['Not the right table: ' TableName])
        return
    end
else
    Station = CurrentRecords{1,2};
    Gaussian = CurrentRecords{1,10};
end

% CurrentRecords contains all the data about the selected station
% RecordMetadataStrings and RecordMetadataDoubles contain the data about
% all the stations
% File names from the ProjectDirectory are in:
%   CurrentRecords{ievent,1}
%   RecordMetadataStrings{itrace,1}
% Trace editted status is in:
%   CurrentRecords{ievent,5}
%   RecordMetadataDoubles(itrace,2)


% Get the parameters from the GUI to define the grid
minRayP = sscanf(get(h.min_rayp_e,'String'),'%f');
maxRayP = sscanf(get(h.max_rayp_e,'String'),'%f');
incRayP = sscanf(get(h.inc_rayp_e,'String'),'%f');

minBaz = sscanf(get(h.min_baz_e,'String'),'%f');
maxBaz = sscanf(get(h.max_baz_e,'String'),'%f');
incBaz = sscanf(get(h.inc_baz_e,'String'),'%f');

outputStartTime = sscanf(get(h.output_start_time_e,'String'),'%f');
outputEndTime = sscanf(get(h.output_end_time_e,'String'),'%f');
outputSampleRate = sscanf(get(h.output_sample_rate_e,'String'),'%f');
%nptsOut = floor((outputEndTime - outputStartTime) / outputSampleRate + 1.5);


activeOrAllFlag = get(h.active_or_all_records_pd,'Value'); % 1 = Active only,    2 = all records
stationsToShowFlag = get(h.stations_to_stack_pd,'Value');  % 1 = Active station, 2 = all stations

% Make sure there is an output directory for the stacked data
if CurrentSubsetIndex == 1
    OutputDir = 'RAYP_BAZ_STACK';
else
    OutputDir = ['RAYP_BAZ_STACK' filesep SetName];
end
[~,~,~] = mkdir(ProjectDirectory,OutputDir);


% Init the search space
RayP = minRayP:incRayP:maxRayP;
nrayP = length(RayP);
Baz = minBaz:incBaz:maxBaz;
nBaz = length(Baz);

% Convert the desired parameters from the cell array to simple vectors
tmp = size(CurrentRecords);
nRecords = tmp(1);
currentRayP = zeros(1,nRecords);
currentBaz = zeros(1,nRecords);
currentActives = zeros(1,nRecords);
for i=1:nRecords
    currentRayP(i) = CurrentRecords{i,21};
    currentBaz(i) = CurrentRecords{i,22};
    currentActives(i) = CurrentRecords{i,5};
end

% Switch case between all stations to stack and single station
switch stationsToShowFlag
    case 1  % stack only the current station in view
        for irayp=1:nrayP
            tmpRayP = irayp * incRayP + minRayP; 
            for ibaz=1:nBaz
                clear iHits;
                tmpBaz = ibaz * incBaz + minBaz;
                tmpMinRayP = tmpRayP - incRayP / 2;
                tmpMaxRayP = tmpRayP + incRayP / 2;
                tmpMinBaz = tmpBaz - incBaz / 2;
                tmpMaxBaz = tmpBaz + incBaz / 2;
                if activeOrAllFlag == 1
                    iHits = find(currentActives == 1 & currentRayP >= tmpMinRayP & currentRayP <= tmpMaxRayP & currentBaz >= tmpMinBaz & currentBaz <= tmpMaxBaz );
                else
                    iHits = find(currentRayP >= tmpMinRayP & currentRayP <= tmpMaxRayP & currentBaz >= tmpMinBaz & currentBaz <= tmpMaxBaz );
                end
                if ~isempty(iHits)
                    % Create a filename for the data stacked
                    sfnameMEAN = sprintf('STACK_%s_eqr_%03.3f_%03.3f_%03.3f_mean.SAC',CurrentRecords{1,2},CurrentRecords{1,10},tmpRayP,tmpBaz);
                    sfnameSD = sprintf('STACK_%s_eqr_%03.3f_%03.3f_%03.3f_sd.SAC',CurrentRecords{1,2},CurrentRecords{1,10},tmpRayP,tmpBaz);

                    outputStackFileNameMean = fullfile(ProjectDirectory,OutputDir,sfnameMEAN);
                    outputStackFileNameSD = fullfile(ProjectDirectory,OutputDir,sfnameSD);
                    
                    % Arrays to hold metadata being averaged for this stack
                    evLongitudes = zeros(1,length(iHits));
                    evLatitudes = zeros(1,length(iHits));
                    evDepths = zeros(1,length(iHits));
                    stackedRayP = zeros(1,length(iHits));
                    stackedBaz = zeros(1,length(iHits));
                    evstaDist = zeros(1,length(iHits));
                    evstaAz = zeros(1,length(iHits));
                    evstaGcarc = zeros(1,length(iHits));
                    
                    % Loop through the RFs in this bin
                    iistack = 1;
                    for istack=iHits
                        % get the filename to read and read the sac file
                        sfname = sprintf('%s%s%seqr',ProjectDirectory,filesep,CurrentRecords{istack,1});
                        [hd1, hd2, hd3, dat] = sac(sfname);
                        hdr = sachdr(hd1, hd2, hd3);
                        
                        % Quickly getting metadata for mean computation at
                        % end
                        evLongitudes(iistack) = hdr.event.evlo;
                        evLatitudes(iistack) = hdr.event.evla;
                        evDepths(iistack) = hdr.event.evdp;
                        stackedRayP(iistack) = currentRayP(istack);
                        stackedBaz(iistack) = currentBaz(istack);
                        evstaDist(iistack) = hdr.evsta.dist;
                        evstaAz(iistack) = hdr.evsta.az;
                        evstaGcarc(iistack) = hdr.evsta.gcarc;
                                                
                        % Ok, so there is a chance the sample rate, start
                        % time, and end time are NOT always the same...
                        % So we need to have the user set these for the
                        % output in the gui and then adjust before
                        % stacking.
                        % Should be easy enough with IWB's resampleSeis and
                        % chopSeis
                        % [SEIS, DT, TIME] = resampleSeis( SEIS, TIME, DTOUT )
                        % [SEIS, T] = chopSeis( SEIS, T, T1, T2 )
                        inputTimes = linspace(hdr.times.b, hdr.times.e, hdr.trcLen);
                        [choppedSeis, choppedTime] = chopSeis(dat, inputTimes, outputStartTime, outputEndTime);
                        [resampledSeis, ~, resampledTime] = resampleSeis(choppedSeis, choppedTime, outputSampleRate);
                        
                        % Init the output arrays on first pass
                        % An array to hold all the seismograms before stacking
                        if iistack == 1
                            nptsOut = length(resampledSeis);
                            stackingArray = zeros(length(iHits),nptsOut);
                            stackedMean = zeros(1,nptsOut);
                            stackedSd = zeros(1,nptsOut);
                        end
                        
                        % Append to the stacking array
                        % Note that if resampledSeis and
                        % stackingArray(istack,:) are different sizes, this
                        % will crash.
                        stackingArray(iistack,:) = resampledSeis;
                        iistack = iistack + 1;
                    end  % loop over RFs
                    
                    % compute the stack. Each row is a different seismogram
                    % and each column is a different time
                    stackedMean = mean(stackingArray,1);
                    %stackedMean = sum(stackingArray,1);  % Debatable to
                    %use the mean or the stack
                    stackedSd = std(stackingArray,0,1);
                    
                    % Update the sac header - standard bits
                    hdr.times.b = outputStartTime;
                    hdr.times.e = outputEndTime;
                    hdr.times.delta = outputSampleRate;
                    hdr.times.o = 0;
                    
                    hdr.event.evla = mean(evLatitudes);
                    hdr.event.evlo = mean(evLongitudes);
                    hdr.event.evdp = mean(evDepths);
                    hdr.event.kevnm = sprintf('RF Stack');
                    
                    hdr.evsta.dist = mean(evstaDist);
                    hdr.evsta.az = mean(evstaAz);
                    hdr.evsta.gcarc = mean(evstaGcarc);
                    hdr.evsta.baz = mean(stackedBaz);
                    
                    % Update the sac header - special bits
                    %   Available if using .tcsh scripts that come with
                    %   FuncLab and Ammon's code.
                    % user6 - mean ray parameter
                    % user7 - bin-center ray parameter
                    % user8 - bin-center backazimuth
                    % user4 - bin-center ray parameter (for Herrmann inversion)
                    hdr.user(5).data = tmpRayP;
                    hdr.user(5).label = 'Center p';
                    hdr.user(7).data = mean(stackedRayP);
                    hdr.user(7).label = 'Mean p';
                    hdr.user(8).data = tmpRayP;
                    hdr.user(8).label = 'Center p';
                    hdr.user(9).data = tmpBaz;
                    hdr.user(9).label = 'Cen Baz';
                    
                    % and finish by writing the sac files
                    writeSAC(outputStackFileNameMean, hdr, stackedMean);
                    writeSAC(outputStackFileNameSD, hdr, stackedSd);
                    
                    
                end  % if there are hits in this bin
            end % backazimuth bin
        end % rayp bins
        
 
    case 2  % Stacking all stations, but make sure to not stack different stations together!
        % Begin with station loop
        StationList = sort(unique(RecordMetadataStrings(:,2)));
        for n = 1:length(StationList)
            in = strcmp(StationList{n},RecordMetadataStrings(:,2));
            CurrentRecords = [RecordMetadataStrings(in,:) num2cell(RecordMetadataDoubles(in,:))];
            [CurrentRecords,ind] = sortrows(CurrentRecords,3);
        
            % Convert the desired parameters from the cell array to simple vectors
            tmp = size(CurrentRecords);
            nRecords = tmp(1);
            currentRayP = zeros(1,nRecords);
            currentBaz = zeros(1,nRecords);
            currentActives = zeros(1,nRecords);
            for i=1:nRecords
                currentRayP(i) = CurrentRecords{i,21};
                currentBaz(i) = CurrentRecords{i,22};
                currentActives(i) = CurrentRecords{i,5};
            end
            
            for irayp=1:nrayP
                tmpRayP = irayp * incRayP + minRayP; 
                for ibaz=1:nBaz

                    clear iHits;
                    tmpBaz = ibaz * incBaz + minBaz;
                    tmpMinRayP = tmpRayP - incRayP / 2;
                    tmpMaxRayP = tmpRayP + incRayP / 2;
                    tmpMinBaz = tmpBaz - incBaz / 2;
                    tmpMaxBaz = tmpBaz + incBaz / 2;
                    if activeOrAllFlag == 1
                        iHits = find(currentActives == 1 & currentRayP >= tmpMinRayP & currentRayP <= tmpMaxRayP & currentBaz >= tmpMinBaz & currentBaz <= tmpMaxBaz );
                    else
                        iHits = find(currentRayP >= tmpMinRayP & currentRayP <= tmpMaxRayP & currentBaz >= tmpMinBaz & currentBaz <= tmpMaxBaz );
                    end
                    if ~isempty(iHits)
                        % Create a filename for the data stacked
                        sfnameMEAN = sprintf('STACK_%s_eqr_%03.3f_%03.3f_%03.3f_mean.SAC',CurrentRecords{1,2},CurrentRecords{1,10},tmpRayP,tmpBaz);
                        sfnameSD = sprintf('STACK_%s_eqr_%03.3f_%03.3f_%03.3f_sd.SAC',CurrentRecords{1,2},CurrentRecords{1,10},tmpRayP,tmpBaz);

                        outputStackFileNameMean = fullfile(ProjectDirectory,OutputDir,sfnameMEAN);
                        outputStackFileNameSD = fullfile(ProjectDirectory,OutputDir,sfnameSD);

                        % Arrays to hold metadata being averaged for this stack
                        evLongitudes = zeros(1,length(iHits));
                        evLatitudes = zeros(1,length(iHits));
                        evDepths = zeros(1,length(iHits));
                        stackedRayP = zeros(1,length(iHits));
                        stackedBaz = zeros(1,length(iHits));
                        evstaDist = zeros(1,length(iHits));
                        evstaAz = zeros(1,length(iHits));
                        evstaGcarc = zeros(1,length(iHits));

                        % Loop through the RFs in this bin
                        iistack = 1;
                        for istack=iHits
                            % get the filename to read and read the sac file
                            sfname = sprintf('%s%s%seqr',ProjectDirectory,filesep,CurrentRecords{istack,1});
                            [hd1, hd2, hd3, dat] = sac(sfname);
                            hdr = sachdr(hd1, hd2, hd3);

                            % Quickly getting metadata for mean computation at
                            % end
                            evLongitudes(iistack) = hdr.event.evlo;
                            evLatitudes(iistack) = hdr.event.evla;
                            evDepths(iistack) = hdr.event.evdp;
                            stackedRayP(iistack) = currentRayP(istack);
                            stackedBaz(iistack) = currentBaz(istack);
                            evstaDist(iistack) = hdr.evsta.dist;
                            evstaAz(iistack) = hdr.evsta.az;
                            evstaGcarc(iistack) = hdr.evsta.gcarc;

                            % Ok, so there is a chance the sample rate, start
                            % time, and end time are NOT always the same...
                            % So we need to have the user set these for the
                            % output in the gui and then adjust before
                            % stacking.
                            % Should be easy enough with IWB's resampleSeis and
                            % chopSeis
                            % [SEIS, DT, TIME] = resampleSeis( SEIS, TIME, DTOUT )
                            % [SEIS, T] = chopSeis( SEIS, T, T1, T2 )
                            inputTimes = linspace(hdr.times.b, hdr.times.e, hdr.trcLen);
                            [choppedSeis, choppedTime] = chopSeis(dat, inputTimes, outputStartTime, outputEndTime,0);
                            [resampledSeis, ~, resampledTime] = resampleSeis(choppedSeis, choppedTime, outputSampleRate);

                            % Init the output arrays on first pass
                            % An array to hold all the seismograms before stacking
                            if iistack == 1
                                nptsOut = length(resampledSeis);
                                stackingArray = zeros(length(iHits),nptsOut);
                                stackedMean = zeros(1,nptsOut);
                                stackedSd = zeros(1,nptsOut);
                            end

                            % Append to the stacking array
                            % Note that if resampledSeis and
                            % stackingArray(istack,:) are different sizes, this
                            % will crash.
                            stackingArray(iistack,:) = resampledSeis;
                            iistack = iistack + 1;
                        end  % loop over RFs

                        % compute the stack. Each row is a different seismogram
                        % and each column is a different time
                        stackedMean = mean(stackingArray,1);
                        %stackedMean = sum(stackingArray,1);  % Debatable to
                        %use the mean or the stack
                        stackedSd = std(stackingArray,0,1);

                        % Update the sac header - standard bits
                        hdr.times.b = outputStartTime;
                        hdr.times.e = outputEndTime;
                        hdr.times.delta = outputSampleRate;
                        hdr.times.o = 0;

                        hdr.event.evla = mean(evLatitudes);
                        hdr.event.evlo = mean(evLongitudes);
                        hdr.event.evdp = mean(evDepths);
                        hdr.event.kevnm = sprintf('RF Stack');

                        hdr.evsta.dist = mean(evstaDist);
                        hdr.evsta.az = mean(evstaAz);
                        hdr.evsta.gcarc = mean(evstaGcarc);
                        hdr.evsta.baz = mean(stackedBaz);

                        % Update the sac header - special bits
                        %   Available if using .tcsh scripts that come with
                        %   FuncLab and Ammon's code.
                        % user6 - mean ray parameter
                        % user7 - bin-center ray parameter
                        % user8 - bin-center backazimuth
                        % user4 - bin-center ray parameter (for Herrmann inversion)
                        hdr.user(5).data = tmpRayP;
                        hdr.user(5).label = 'Center p';
                        hdr.user(7).data = mean(stackedRayP);
                        hdr.user(7).label = 'Mean p';
                        hdr.user(8).data = tmpRayP;
                        hdr.user(8).label = 'Center p';
                        hdr.user(9).data = tmpBaz;
                        hdr.user(9).label = 'Cen Baz';

                        % and finish by writing the sac files
                        writeSAC(outputStackFileNameMean, hdr, stackedMean);
                        writeSAC(outputStackFileNameSD, hdr, stackedSd);
                    

                    end  % if there are hits in this bin
                end % backazimuth bin
            end % rayp bins
        end % station loop
        
end % Switch between active station and all stations

% % Save RayP_BAZ table to the project file (WARNING: THIS OVERWRITES EXISTING HK)
% %--------------------------------------------------------------------------
%save([ProjectDirectory ProjectFile],'RaypBazMetadataStrings','RaypBazMetadataDoubles','-append');
% 
% 
% % Update the Log File
% %--------------------------------------------------------------------------
LogFile = [ProjectDirectory 'Logfile.txt'];
CTime = clock;
NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - RayP-Baz Stacking Set %s',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6), SetName);
NewLog{2} = ['     1. RayParam Min: ' num2str(minRayP)];
NewLog{3} = ['     2. RayParam Max: ' num2str(maxRayP)];
NewLog{4} = ['     3. RayParam Inc: ' num2str(incRayP)];
NewLog{5} = ['     4. Backazimuth Min: ' num2str(minBaz)];
NewLog{6} = ['     5. Backazimuth Max: ' num2str(maxBaz)];
NewLog{7} = ['     6. Backazimuth Inc: ' num2str(incBaz)];
NewLog{8} = ['     7. Stack Start Time: ' num2str(outputStartTime)];
NewLog{9} = ['     8. Stack End Time: ' num2str(outputEndTime)];
NewLog{10} = ['     9. Stack Sample Rate: ' num2str(outputSampleRate)];
if activeOrAllFlag == 1
    tmp = sprintf('Active records only');
else
    tmp = sprintf('All records');
end
NewLog{11} = ['     10. Records Choice: ' tmp ];
if stationsToShowFlag == 1
    tmp = sprintf('Active station only');
else
    tmp = sprintf('All stations');
end
NewLog{12} = ['     11. Stations Choice: ' tmp ];
t_temp = toc;
NewLog{14} = ['     12. RayP-Baz Stacking took ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).'];
fl_edit_logfile(LogFile,NewLog)
close(WaitGui)
set(h.MainGui.message_t,'String',['Message: RayP-Baz Stacking: Stacking took ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).'])
%set(h.MainGui.tablemenu_pu,'String',Tablemenu(:,1))





