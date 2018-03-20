function FL_new_fetch_project_setup_Callback(cbo,eventdata)
%% FL_new_fetch_project_setup_Callback
%  acquires the parameters from the panels
%  Calls iris fetch to find some last minute parameters
%  Then calls iris fetch to obtain waveform data
%  data is then preprocessed and raw traces are written into event
%  directories
%  RFs are computed with the params chosen by user

% Wait dialog is annoying. Off for debugging
% WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
%     'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
% uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
%     'String','Please wait, Fetching data, computing RFs, and loading in datasets and creating station and event tables',...
%     'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
% drawnow

%% Get the directory to put the project
h = guidata(gcbf);
%ProjectDirectoryHdls = findobj('Tag','new_fetch_projdir_e');
ProjectDirectory = get(h.new_fetch_projdir_e,'String');
if ~strcmp(filesep,ProjectDirectory(end))
    ProjectDirectory = [ProjectDirectory, filesep];
end
assignin('base','ProjectDirectory',ProjectDirectory)
assignin('base','ProjectFile','Project.mat')
if isempty(ProjectDirectory)
    errordlg('Must type a full pathname for the project directory.') % 11/12/2011: DELETED ERRORDLG_KCE 
    return
end
if exist(ProjectDirectory,'dir')
    errordlg('Project directory already exists.  We do not want to overwrite this project, or any other information.') % 11/12/2011: DELETED ERRORDLG_KCE
    return
end
mkdir(ProjectDirectory)
mkdir([ProjectDirectory 'RAWDATA'])
mkdir([ProjectDirectory 'RAWTRACES'])
mkdir([ProjectDirectory 'FIGURES'])


%% get the user input data
stationPanelHandles = findobj('Tag','new_fetch_station_panel');
eventPanelHandles = findobj('Tag','new_fetch_events_panel');
tracePanelHandles = findobj('Tag','new_fetch_traces_panel');
rfProcessingPanelHandles = findobj('Tag','new_fetch_rfprocessing_params_panel');

stationInfo = get(stationPanelHandles,'UserData');
%.stations: cell array
%.networks: cell array
%.latitudes: double array
%.longitudes: double array
eventInfo = get(eventPanelHandles,'UserData');
% all cell arrays:
%.OriginName
%.OriginTime
%.OriginLatitude
%.OriginLongitude
%.OriginDepth (km)
%.OriginMagnitude 
% And just values
%.minDistance
%.maxDistance
traceInfo = get(tracePanelHandles,'UserData');
%{trace start, before or after, phase or origin, trace end, before or after, phase or origin, sample rate, response}
rfProcessingInfo = get(rfProcessingPanelHandles,'UserData');
%{taper1, filter_hp1, filter_lp1, filter_order1, pre-phase cut1, post-phase cut1, numerator1, denominator1,
%  array or single1, gaussian1, decontype1, waterlevel1, maxiterations1,
%  minerror1, taper2, filter_hp2, filter_lp2, filter_order2, pre_phase
%  cut2, post_phase cut2, numerator2, denominator2, array or single2,
%  gaussian2, decontype2, waterlevel2, maxiteration2, minerror2,
%  incidentphase1, incidentphase2

%% Station info has been found to have numerous duplicates, so use unique to
% get only the necessary stations
uniqueStations = unique(stationInfo.stations);
cleanStationInfo.stations = cell(1,length(uniqueStations));
cleanStationInfo.networks = cell(1,length(uniqueStations));
cleanStationInfo.latitudes = zeros(1,length(uniqueStations));
cleanStationInfo.longitudes = zeros(1,length(uniqueStations));
for istation = 1:length(uniqueStations)
    for jstation = 1:length(stationInfo.stations)
        if strcmp(uniqueStations{istation},stationInfo.stations{jstation})
           cleanStationInfo.stations{istation} = stationInfo.stations{jstation};
           cleanStationInfo.networks{istation} = stationInfo.networks{jstation};
           cleanStationInfo.latitudes(istation) = stationInfo.latitudes{jstation};
           cleanStationInfo.longitudes(istation) = stationInfo.longitudes{jstation};
           break
        end
    end
end

%% Get the number of events and stations for the loops
nevents = length(eventInfo.OriginLatitude);
nstations = length(cleanStationInfo.stations);

%% Break these cell arrays into easier to use variables (structures will be
% parsed in loops below)
% Trace Info
if strcmp(traceInfo{2},'Before')
    traceStartSecondsOffset = -1 * str2double(traceInfo{1});
else
    traceStartSecondsOffset = str2double(traceInfo{1});
end
if strcmp(traceInfo{5},'Before')
    traceEndSecondsOffset = -1 * str2double(traceInfo{4});
else
    traceEndSecondsOffset = str2double(traceInfo{4});
end
traceStartPhase = sprintf('%s',traceInfo{3});
traceEndPhase = sprintf('%s',traceInfo{6});
traceSampleRate = str2double(traceInfo{7});
traceResponseSelection = sprintf('%s',traceInfo{8});

%% RF processing info
FL_rfOpt(1).processingTaper = sprintf('%s',rfProcessingInfo{1});
FL_rfOpt(2).processingTaper = sprintf('%s',rfProcessingInfo{15});
FL_rfOpt(1).processingFilterHp = str2double(rfProcessingInfo{2});
FL_rfOpt(2).processingFilterHp = str2double(rfProcessingInfo{16});
FL_rfOpt(1).processingFilterLp = str2double(rfProcessingInfo{3});
FL_rfOpt(2).processingFilterLp = str2double(rfProcessingInfo{17});
FL_rfOpt(1).processingFilterOrder = str2double(rfProcessingInfo{4});
FL_rfOpt(2).processingFilterOrder = str2double(rfProcessingInfo{18});
FL_rfOpt(1).processingPrePhaseCut = str2double(rfProcessingInfo{5});
FL_rfOpt(2).processingPrePhaseCut = str2double(rfProcessingInfo{19});
FL_rfOpt(1).processingPostPhaseCut = str2double(rfProcessingInfo{6});
FL_rfOpt(2).processingPostPhaseCut = str2double(rfProcessingInfo{20});
FL_rfOpt(1).processingNumerator = sprintf('%s',rfProcessingInfo{7});
FL_rfOpt(2).processingNumerator = sprintf('%s',rfProcessingInfo{21});
FL_rfOpt(1).processingDenominator = sprintf('%s',rfProcessingInfo{8});
FL_rfOpt(2).processingDenominator = sprintf('%s',rfProcessingInfo{22});
FL_rfOpt(1).processingDenominatorMethod = sprintf('%s',rfProcessingInfo{9});
FL_rfOpt(2).processingDenominatorMethod = sprintf('%s',rfProcessingInfo{23});
FL_rfOpt(1).processingGaussian = str2double(rfProcessingInfo{10});
FL_rfOpt(2).processingGaussian = str2double(rfProcessingInfo{24});
FL_rfOpt(1).processingDeconvolution = sprintf('%s',rfProcessingInfo{11});
FL_rfOpt(2).processingDeconvolution = sprintf('%s',rfProcessingInfo{25});
FL_rfOpt(1).processingWaterlevel = str2double(rfProcessingInfo{12});
FL_rfOpt(2).processingWaterlevel = str2double(rfProcessingInfo{26});
FL_rfOpt(1).processingMaxIterations = str2double(rfProcessingInfo{13});
FL_rfOpt(2).processingMaxIterations = str2double(rfProcessingInfo{27});
FL_rfOpt(1).processingMinError = str2double(rfProcessingInfo{14});
FL_rfOpt(2).processingMinError = str2double(rfProcessingInfo{28});
FL_rfOpt(1).processingIncidentPhase = sprintf('%s',rfProcessingInfo{29});
FL_rfOpt(2).processingIncidentPhase = sprintf('%s',rfProcessingInfo{30});
FL_rfOpt(1).sampleRate = 1 / traceSampleRate;
FL_rfOpt(2).sampleRate = 1 / traceSampleRate;


%% A cell variable to hold the raw trace file names as they are written.
%  This is to allow re-upping the file names quickly between writing the
%  raw files and beginning the RF processing
rawTracesFileNames = cell(nevents,nstations);


%% At this point RWP would like to query the data center to determine the
% proper location codes and network codes for the set of stations. However,
% stations can change metadata and thus its best just to decide location
% code and channel codes for the time frame requested. :(

%% Loop through each event

for ievent = 1:nevents;
    eventLatitude = eventInfo.OriginLatitude{ievent};
    eventLongitude = eventInfo.OriginLongitude{ievent};
    eventDepth = eventInfo.OriginDepth{ievent};
    eventTime = irisTimeStringToEpoch(eventInfo.OriginTime{ievent});
    
    fprintf('***      Requesting event %s     ***\n',eventInfo.OriginTime{ievent});
    
    
    %% Loop through stations...debateable whether it would be better to
    % request all stations at once, or request stations one at a time.
    % Going with one station at a time as its easiest to deal with, but
    % going for all at once may be faster
    for istation = 1:nstations;
        % Determine if this station is within the distance window
        [kmdist, azi, gcarc] = distaz(eventLatitude,eventLongitude,cleanStationInfo.latitudes(istation),cleanStationInfo.longitudes(istation));
        if gcarc <= eventInfo.maxDistance && gcarc >= eventInfo.minDistance
            % determine time to start trace request
            if ~strcmp(traceStartPhase,'Origin')
                tt = taupTime('iasp91',eventDepth,traceStartPhase,'deg',gcarc);
                if ~isempty(tt) % avoid searching when phase is not available at distance
                    startPhaseArrivalTime = tt(1).time; % time in seconds relative to origin
                    startPhaseRayParam = tt(1).rayParam; % ray parameter in (I think) seconds per radian 
                    startTimeString = epochTimeToIrisString(eventTime+((startPhaseArrivalTime+traceStartSecondsOffset)/24/60/60));                
                end
            else
                startTimeString = epochTimeToIrisString(eventTime+(traceStartSecondsOffset/24/60/60));
            end
            
            %% determine time to end trace request
            if ~strcmp(traceEndPhase,'Origin')
                tt = taupTime('iasp91',eventDepth,traceEndPhase,'deg',gcarc);
                if ~isempty(tt) % avoid searching when phase is not available at distance
                    endPhaseArrivalTime = tt(1).time; % time in seconds relative to origin
                    endPhaseRayParam = tt(1).rayParam; % ray parameter in (I think) seconds per radian 
                    endTimeString = epochTimeToIrisString(eventTime+((endPhaseArrivalTime+traceEndSecondsOffset)/24/60/60));                
                end
            else
                endTimeString = epochTimeToIrisString(eventTime+(traceEndSecondsOffset/24/60/60));
            end
            
            
            %% Now get traces for this station. This will include all
            % locations and broadband channels
            if ~strcmp(cleanStationInfo.networks{istation},'BK')
                serviceDataCenter = 'http://service.iris.edu/';
            else
                serviceDataCenter = 'http://service.ncedc.org/';
            end
            
            fprintf('Fetching data for station %s\n',stationInfo.stations{istation});
            
            %% Note that this does not allow for restricted access right
            % now. Add a ui element to allow a password entry, then create
            % a cell array for input as the final argument to
            % irisFetch.Traces
            dataTraces = irisFetch.Traces(stationInfo.networks{istation},stationInfo.stations{istation},'*','?H?',startTimeString, endTimeString,'includePZ',serviceDataCenter);
            %dataTraces = irisFetch.Traces(stationInfo.networks{istation},stationInfo.stations{istation},'*','?H?',startTimeString, endTimeString,'includePZ');
           
            %% Find number of traces obtained
            ntraces = length(dataTraces);
            
            %% Check empty return or lack of 3 component data
            if ntraces < 3
                fprintf('No data found for station %s!\n',cleanStationInfo.stations{istation});
                interpedMergedData = cell(1,3);
                rotatedInterpedMergedData = cell(1,3);
                continue  % no traces, so go on to next station
            end
            
            %% Init flags for rotation and interpolation
            rotateFlag = 0;
            interpFlag = 0;
            
            %% prepare interpolation array
            startTimeEpoch = irisTimeStringToEpoch(startTimeString);
            endTimeEpoch = irisTimeStringToEpoch(endTimeString);
            outputTimeArray = startTimeEpoch:1/traceSampleRate/24/60/60:endTimeEpoch;
            
            %% init for interpolation and rotation
            interpedMergedData = cell(1,3);
            rotatedInterpedMergedData = cell(1,3);
            
            %% Check for the ideal, but almost never real case of only 3
            % traces (one per channel)
            if ntraces == 3
                interpedMergedData{1} = dataTraces(1);
                interpedMergedData{2} = dataTraces(2);
                interpedMergedData{3} = dataTraces(3);
                %% Check to interpolate to output time array
                for itrace = 1:ntraces
                   obtainedTimeArray = linspace(dataTraces(itrace).startTime, dataTraces(itrace).endTime, dataTraces(itrace).sampleCount);
                   interpolatedAmplitude = interp1(obtainedTimeArray, dataTraces(itrace).data, outputTimeArray,'linear','extrap');
                   interpedMergedData{itrace}.data = interpolatedAmplitude;
                   interpedMergedData{itrace}.sampleRate = traceSampleRate;
                   interpedMergedData{itrace}.sampleCount = length(interpedMergedData{itrace}.data);
                   interpedMergedData{itrace}.startTime = startTimeEpoch;
                   interpedMergedData{itrace}.endTime = endTimeEpoch;
                end
                %% rotate if necessary
                ierr = 0;
                [rotatedInterpedMergedData, ierr] = FL_rotateCellTripleToENZ(interpedMergedData);
                
                %% response removal if requested
                % Note that this really should be a selection between
                % primary and secondary so the user can compare response
                % deconvolved and non-response deconvolved data.
                if ierr == 0
                    [DeconnedData, ierr] = FL_responseRemoval( rotatedInterpedMergedData, 0.002, traceResponseSelection );
                end
                %% Split at this point.
                % 1. If we are using the traditional single station
                % deconvolution method, then we can compute that here and
                % write files.
                % 2. If we are using the array based source method of
                % deconvolution, then we'll need to start computing the
                % source function and write three component data files
                %
                % Let's proceed by creating a 'RAWTRACES' directory in the
                % project folder. We can then compute the RFs once the
                % RAWTRACES are ready. 
                
                %% Write E,N,Z sac files in RAWTRACES
                if ierr == 0
                    [writtenTraces, ierr] = FL_writeFetchedTraces(DeconnedData, ProjectDirectory, 'RAWTRACES', traceResponseSelection, eventInfo, ievent);
                end
                
                % WrittenTraces now have the file name in: writtenTraces{itrace}.fullSacFileName
                % Rejoining thread with case of multiple channels for a
                % given station
                if ierr == 0
                    rawTracesFileNames{ievent,istation} = sprintf('%s %s %s',writtenTraces{1}.fullSacFileName, writtenTraces{2}.fullSacFileName, writtenTraces{3}.fullSacFileName);
                end
                
            else

                %% must have more than 3 traces. May be multiple location
                % codes, multiple sets of channel codes, or gappy data
                locs = cell(1,length(dataTraces));
                for i=1:length(dataTraces)
                    locs{i} = sprintf('%s',dataTraces(i).location);
                end
                uniqueLocs = unique(locs);
                nlocs = length(uniqueLocs);
                
                %% The most correct thing to do is to treat each location
                % code as its own "station"
                for iloc = 1:nlocs
                    %% Find the number of traces under this location code
                    jchan = 0;
                    jhorizontal1 = 0;
                    jhorizontal2 = 0;
                    jhorizontale = 0;
                    jhorizontaln = 0;
                    jverticalz = 0;
                    for jloc = 1:length(dataTraces)
                        if strcmp(sprintf('%s',dataTraces(jloc).location),uniqueLocs{iloc})
                            jchan = jchan + 1;
                            if strcmp(dataTraces(jloc).channel(3),'1')
                                jhorizontal1 = jhorizontal1 + 1;
                            elseif strcmp(dataTraces(jloc).channel(3),'2')
                                jhorizontal2 = jhorizontal2 + 1;
                            elseif strcmp(dataTraces(jloc).channel(3),'E')
                                jhorizontale = jhorizontale + 1;
                            elseif strcmp(dataTraces(jloc).channel(3),'N')
                                jhorizontaln = jhorizontaln + 1;
                            elseif strcmp(dataTraces(jloc).channel(3),'Z')
                                jverticalz = jverticalz + 1;
                            else
                                fprintf('Unknown component: %s\n',dataTraces(jloc).channel(3));
                            end
                            
                        end
                    end
                    % init the kept channels vectors
                    keptchans1=[];
                    keptchans2=[];
                    keptchanse=[];
                    keptchansn=[];
                    keptchansz=[];
                    
                    %% So the number of channels under this location code is
                    % now jchan
                    % and the number of traces in each of the 1, 2, e, n,
                    % and z directions is set in jhorizontal{1,2,e,n} and
                    % jverticalz. This should cover most common
                    % conventions, but may need an adjustment in the future
                    % if other naming conventions become popular
                    if jhorizontal1 > 0
                        jhorizontal1Indices = zeros(1,jhorizontal1);
                        kchan = 0;
                        for jloc=1:length(dataTraces)
                            if strcmp(dataTraces(jloc).channel(3),'1') 
                                kchan = kchan + 1;
                                jhorizontal1Indices(kchan) = jloc;
                            end
                        end
                        
                        keptchans1 = zeros(1,length(jhorizontal1Indices));
                        mchans = 0;
                        keptSampleRate = 1000;
                        for lchan = 1:length(jhorizontal1Indices)
                            if dataTraces(jhorizontal1Indices(lchan)).sampleRate >= traceSampleRate && dataTraces(jhorizontal1Indices(lchan)).sampleRate <= keptSampleRate
                                keptSampleRate = dataTraces(jhorizontal1Indices(lchan)).sampleRate;
                                %mchans = mchans+1;
                                %keptchans1(mchans) = jhorizontal1Indices(lchan);
                            end
                        end
                        for lchan = 1:length(jhorizontal1Indices)
                            if dataTraces(jhorizontal1Indices(lchan)).sampleRate == keptSampleRate
                                %keptSampleRate = dataTraces(jhorizontal1Indices(lchan)).sampleRate;
                                mchans = mchans+1;
                                keptchans1(mchans) = jhorizontal1Indices(lchan);
                            end
                        end
                        keptchans1(keptchans1==0) = [];
                    end
                    % Repeat for ?H2
                    if jhorizontal2 > 0
                        jhorizontal2Indices = zeros(1,jhorizontal2);
                        kchan = 0;
                        for jloc=1:length(dataTraces)
                            if strcmp(dataTraces(jloc).channel(3),'2') 
                                kchan = kchan + 1;
                                jhorizontal2Indices(kchan) = jloc;
                            end
                        end
                        keptchans2 = zeros(1,length(jhorizontal2Indices));
                        mchans = 0;
                        keptSampleRate = 1000;
                        for lchan = 1:length(jhorizontal2Indices)
                            if dataTraces(jhorizontal2Indices(lchan)).sampleRate >= traceSampleRate && dataTraces(jhorizontal2Indices(lchan)).sampleRate <= keptSampleRate
                                keptSampleRate = dataTraces(jhorizontal2Indices(lchan)).sampleRate;
                                %mchans = mchans+1;
                                %keptchans2(mchans) = jhorizontal2Indices(lchan);
                            end
                        end
                        for lchan = 1:length(jhorizontal2Indices)
                            if dataTraces(jhorizontal2Indices(lchan)).sampleRate == keptSampleRate
                                %keptSampleRate = dataTraces(jhorizontal1Indices(lchan)).sampleRate;
                                mchans = mchans+1;
                                keptchans2(mchans) = jhorizontal2Indices(lchan);
                            end
                        end
                        keptchans2(keptchans2==0) = [];
                    end
                    % Repeat for ?HE
                    if jhorizontale > 0
                        jhorizontaleIndices = zeros(1,jhorizontale);
                        kchan = 0;
                        for jloc=1:length(dataTraces)
                            if strcmp(dataTraces(jloc).channel(3),'E') 
                                kchan = kchan + 1;
                                jhorizontaleIndices(kchan) = jloc;
                            end
                        end
                        keptchanse = zeros(1,length(jhorizontaleIndices));
                        mchans = 0;
                        keptSampleRate = 1000;
                        for lchan = 1:length(jhorizontaleIndices)
                            if dataTraces(jhorizontaleIndices(lchan)).sampleRate >= traceSampleRate && dataTraces(jhorizontaleIndices(lchan)).sampleRate <= keptSampleRate
                                keptSampleRate = dataTraces(jhorizontaleIndices(lchan)).sampleRate;
                                %mchans = mchans+1;
                                %keptchanse(mchans) = jhorizontaleIndices(lchan);
                            end
                        end
                        for lchan = 1:length(jhorizontaleIndices)
                            if dataTraces(jhorizontaleIndices(lchan)).sampleRate == keptSampleRate
                                %keptSampleRate = dataTraces(jhorizontal1Indices(lchan)).sampleRate;
                                mchans = mchans+1;
                                keptchanse(mchans) = jhorizontaleIndices(lchan);
                            end
                        end
                        keptchanse(keptchanse==0) = [];
                    end
                    % Repeat for ?HN
                    if jhorizontaln > 0
                        jhorizontalnIndices = zeros(1,jhorizontaln);
                        kchan = 0;
                        for jloc=1:length(dataTraces)
                            if strcmp(dataTraces(jloc).channel(3),'N') 
                                kchan = kchan + 1;
                                jhorizontalnIndices(kchan) = jloc;
                            end
                        end
                        keptchansn= zeros(1,length(jhorizontalnIndices));
                        mchans = 0;
                        keptSampleRate = 1000;
                        for lchan = 1:length(jhorizontalnIndices)
                            if dataTraces(jhorizontalnIndices(lchan)).sampleRate >= traceSampleRate && dataTraces(jhorizontalnIndices(lchan)).sampleRate <= keptSampleRate
                                keptSampleRate = dataTraces(jhorizontalnIndices(lchan)).sampleRate;
                                %mchans = mchans+1;
                                %keptchansn(mchans) = jhorizontalnIndices(lchan);
                            end
                        end
                        for lchan = 1:length(jhorizontalnIndices)
                            if dataTraces(jhorizontalnIndices(lchan)).sampleRate == keptSampleRate
                                %keptSampleRate = dataTraces(jhorizontal1Indices(lchan)).sampleRate;
                                mchans = mchans+1;
                                keptchansn(mchans) = jhorizontalnIndices(lchan);
                            end
                        end
                        keptchansn(keptchansn==0) = [];
                    end
                    % Repeat for ?HZ
                    if jverticalz > 0
                        jverticalzIndices = zeros(1,jverticalz);
                        kchan = 0;
                        for jloc=1:length(dataTraces)
                            if strcmp(dataTraces(jloc).channel(3),'Z') 
                                kchan = kchan + 1;
                                jverticalzIndices(kchan) = jloc;
                            end
                        end
                        keptchansz = zeros(1,length(jverticalzIndices));
                        mchans = 0;
                        keptSampleRate = 1000;
                        for lchan = 1:length(jverticalzIndices)
                            if dataTraces(jverticalzIndices(lchan)).sampleRate >= traceSampleRate && dataTraces(jverticalzIndices(lchan)).sampleRate <= keptSampleRate
                                keptSampleRate = dataTraces(jverticalzIndices(lchan)).sampleRate;
                                %mchans = mchans+1;
                                %keptchansz(mchans) = jverticalzIndices(lchan);
                            end
                        end
                        for lchan = 1:length(jverticalzIndices)
                            if dataTraces(jverticalzIndices(lchan)).sampleRate == keptSampleRate
                                %keptSampleRate = dataTraces(jhorizontal1Indices(lchan)).sampleRate;
                                mchans = mchans+1;
                                keptchansz(mchans) = jverticalzIndices(lchan);
                            end
                        end
                        keptchansz(keptchansz==0) = [];
                    end
                                         
                    %% merge traces and interp
                    if ~isempty(keptchans1)
                        if length(keptchans1) > 1
                            nptsObtained = 0;
                            for itrace=keptchans1
                                nptsObtained = nptsObtained + dataTraces(itrace).sampleCount;
                            end
                            % preallocate time and amplitude
                            yMergeArray = zeros(1,nptsObtained);
                            xMergeArray = zeros(1,nptsObtained);
                 
                            % Create x and y arrays of time and amplitudes
                            jtrace = 1;
                            for itrace=keptchans1
                                yMergeArray(jtrace:(jtrace+dataTraces(itrace).sampleCount-1)) = dataTraces(itrace).data(:)';
                                % find time offset between this trace and the origin
                                % populate the xMergeArray with the time (in seconds)
                                % since the origin
                                traceStartOffsetSeconds = dataTraces(itrace).startTime;

                                % This method of determining the timing of fetch may
                                % have problems when the sample rate and requested
                                % origin are slightly off.
                                % traceEndOriginOffsetSeconds = (dataTracesNew(itrace).endTime - originEpochTime) * 24 * 60 * 60;
                                % xMergeArray(jtrace:(jtrace+dataTracesNew(itrace).sampleCount-1)) = traceStartOriginOffsetSeconds:1.0/dataTracesNew(itrace).sampleRate:traceEndOriginOffsetSeconds;

                                % More robust for interpolation, but *probably* slower
                                xMergeArray(jtrace) = traceStartOffsetSeconds;
                                for ii=1:dataTraces(itrace).sampleCount-1
                                    xMergeArray(jtrace+ii) = xMergeArray(jtrace+ii-1) + 1.0/dataTraces(itrace).sampleRate;
                                end

                                % update the jtrace - index used to find location
                                % within the merge arrays
                                jtrace = jtrace + dataTraces(itrace).sampleCount;

                            end

                            % interp1
                            interpolatedAmplitude = interp1(xMergeArray,yMergeArray,outputTimeArray,'linear','extrap');

                            % repack the interpolated array into dataTracesMerged
                            interpedMergedData{1} = dataTraces(keptchans1(1));
                            interpedMergedData{1}.data = zeros(1,length(interpolatedAmplitude));
                            interpedMergedData{1}.data = interpolatedAmplitude;
                            interpedMergedData{1}.sampleCount = length(interpedMergedData{1}.data);
                            interpedMergedData{1}.sampleRate = traceSampleRate;
                            interpedMergedData{1}.endTime = endTimeEpoch;
                            interpedMergedData{1}.startTime = startTimeEpoch;
                            
                        else
                            itrace = keptchans1(1);
                            obtainedTimeArray = linspace(dataTraces(itrace).startTime, dataTraces(itrace).endTime, dataTraces(itrace).sampleCount);
                            interpolatedAmplitude = interp1(obtainedTimeArray, dataTraces(itrace).data, outputTimeArray,'linear','extrap');
                            interpedMergedData{1} = dataTraces(keptchans1(1));
                            interpedMergedData{1}.data = zeros(1,length(interpolatedAmplitude));
                            interpedMergedData{1}.data = interpolatedAmplitude;
                            interpedMergedData{1}.sampleRate = traceSampleRate;
                            interpedMergedData{1}.sampleCount = length(interpedMergedData{1}.data);
                            interpedMergedData{1}.startTime = startTimeEpoch;
                            interpedMergedData{1}.endTime = endTimeEpoch;
                        end
                        
                    end
                    % Repeat merge for ?H2
                    if ~isempty(keptchans2)
                        if length(keptchans2) > 1
                            nptsObtained = 0;
                            for itrace=keptchans2
                                nptsObtained = nptsObtained + dataTraces(itrace).sampleCount;
                            end
                            % preallocate time and amplitude
                            yMergeArray = zeros(1,nptsObtained);
                            xMergeArray = zeros(1,nptsObtained);
                 
                            % Create x and y arrays of time and amplitudes
                            jtrace = 1;
                            for itrace=keptchans2
                                yMergeArray(jtrace:(jtrace+dataTraces(itrace).sampleCount-1)) = dataTraces(itrace).data(:)';
                                % find time offset between this trace and the origin
                                % populate the xMergeArray with the time (in seconds)
                                % since the origin
                                traceStartOffsetSeconds = (dataTraces(itrace).startTime - startTimeEpoch) * 24 * 60 * 60;

                                % This method of determining the timing of fetch may
                                % have problems when the sample rate and requested
                                % origin are slightly off.
                                % traceEndOriginOffsetSeconds = (dataTracesNew(itrace).endTime - originEpochTime) * 24 * 60 * 60;
                                % xMergeArray(jtrace:(jtrace+dataTracesNew(itrace).sampleCount-1)) = traceStartOriginOffsetSeconds:1.0/dataTracesNew(itrace).sampleRate:traceEndOriginOffsetSeconds;

                                % More robust for interpolation, but *probably* slower
                                xMergeArray(jtrace) = traceStartOffsetSeconds;
                                for ii=1:dataTraces(itrace).sampleCount-1
                                    xMergeArray(jtrace+ii) = xMergeArray(jtrace+ii-1) + 1.0/dataTraces(itrace).sampleRate;
                                end

                                % update the jtrace - index used to find location
                                % within the merge arrays
                                jtrace = jtrace + dataTraces(itrace).sampleCount;

                            end

                            % interp1
                            interpolatedAmplitude = interp1(xMergeArray,yMergeArray,outputTimeArray,'linear','extrap');

                            % repack the interpolated array into dataTracesMerged
                            interpedMergedData{2} = dataTraces(keptchans2(1));
                            interpedMergedData{2}.data = zeros(1,length(interpolatedAmplitude));
                            interpedMergedData{2}.data = interpolatedAmplitude;
                            interpedMergedData{2}.sampleCount = length(interpedMergedData{2}.data);
                            interpedMergedData{2}.sampleRate = traceSampleRate;
                            interpedMergedData{2}.endTime = endTimeEpoch;
                            interpedMergedData{2}.startTime = startTimeEpoch;
                            
                        else
                            itrace = keptchans2(1);
                            obtainedTimeArray = linspace(dataTraces(itrace).startTime, dataTraces(itrace).endTime, dataTraces(itrace).sampleCount);
                            interpolatedAmplitude = interp1(obtainedTimeArray, dataTraces(itrace).data, outputTimeArray,'linear','extrap');
                            interpedMergedData{2} = dataTraces(keptchans2(1));
                            interpedMergedData{2}.data = zeros(1,length(interpolatedAmplitude));
                            interpedMergedData{2}.data = interpolatedAmplitude;
                            interpedMergedData{2}.sampleRate = traceSampleRate;
                            interpedMergedData{2}.sampleCount = length(interpedMergedData{2}.data);
                            interpedMergedData{2}.startTime = startTimeEpoch;
                            interpedMergedData{2}.endTime = endTimeEpoch;
                        end
                        
                    end
                    % Repeat merge for ?HE
                    if ~isempty(keptchanse)
                        if length(keptchanse) > 1
                            nptsObtained = 0;
                            for itrace=keptchanse
                                nptsObtained = nptsObtained + dataTraces(itrace).sampleCount;
                            end
                            % preallocate time and amplitude
                            yMergeArray = zeros(1,nptsObtained);
                            xMergeArray = zeros(1,nptsObtained);
                 
                            % Create x and y arrays of time and amplitudes
                            jtrace = 1;
                            for itrace=keptchanse
                                yMergeArray(jtrace:(jtrace+dataTraces(itrace).sampleCount-1)) = dataTraces(itrace).data(:)';
                                % find time offset between this trace and the origin
                                % populate the xMergeArray with the time (in seconds)
                                % since the origin
                                traceStartOffsetSeconds = (dataTraces(itrace).startTime - startTimeEpoch) * 24 * 60 * 60;

                                % This method of determining the timing of fetch may
                                % have problems when the sample rate and requested
                                % origin are slightly off.
                                % traceEndOriginOffsetSeconds = (dataTracesNew(itrace).endTime - originEpochTime) * 24 * 60 * 60;
                                % xMergeArray(jtrace:(jtrace+dataTracesNew(itrace).sampleCount-1)) = traceStartOriginOffsetSeconds:1.0/dataTracesNew(itrace).sampleRate:traceEndOriginOffsetSeconds;

                                % More robust for interpolation, but *probably* slower
                                xMergeArray(jtrace) = traceStartOffsetSeconds;
                                for ii=1:dataTraces(itrace).sampleCount-1
                                    xMergeArray(jtrace+ii) = xMergeArray(jtrace+ii-1) + 1.0/dataTraces(itrace).sampleRate;
                                end

                                % update the jtrace - index used to find location
                                % within the merge arrays
                                jtrace = jtrace + dataTraces(itrace).sampleCount;

                            end

                            % interp1
                            interpolatedAmplitude = interp1(xMergeArray,yMergeArray,outputTimeArray,'linear','extrap');

                            % repack the interpolated array into dataTracesMerged
                            interpedMergedData{1} = dataTraces(keptchanse(1));
                            interpedMergedData{1}.data = zeros(1,length(interpolatedAmplitude));
                            interpedMergedData{1}.data = interpolatedAmplitude;
                            interpedMergedData{1}.sampleCount = length(interpedMergedData{1}.data);
                            interpedMergedData{1}.sampleRate = traceSampleRate;
                            interpedMergedData{1}.endTime = endTimeEpoch;
                            interpedMergedData{1}.startTime = startTimeEpoch;
                            
                        else
                            itrace = keptchanse(1);
                            obtainedTimeArray = linspace(dataTraces(itrace).startTime, dataTraces(itrace).endTime, dataTraces(itrace).sampleCount);
                            interpolatedAmplitude = interp1(obtainedTimeArray, dataTraces(itrace).data, outputTimeArray,'linear','extrap');
                            interpedMergedData{1} = dataTraces(keptchanse(1));
                            interpedMergedData{1}.data = zeros(1,length(interpolatedAmplitude));
                            interpedMergedData{1}.data = interpolatedAmplitude;
                            interpedMergedData{1}.sampleRate = traceSampleRate;
                            interpedMergedData{1}.sampleCount = length(interpedMergedData{1}.data);
                            interpedMergedData{1}.startTime = startTimeEpoch;
                            interpedMergedData{1}.endTime = endTimeEpoch;
                        end
                        
                    end
                    % Repeat merge for ?HN
                    if ~isempty(keptchansn)
                        if length(keptchansn) > 1
                            nptsObtained = 0;
                            for itrace=keptchansn
                                nptsObtained = nptsObtained + dataTraces(itrace).sampleCount;
                            end
                            % preallocate time and amplitude
                            yMergeArray = zeros(1,nptsObtained);
                            xMergeArray = zeros(1,nptsObtained);
                 
                            % Create x and y arrays of time and amplitudes
                            jtrace = 1;
                            for itrace=keptchansn
                                yMergeArray(jtrace:(jtrace+dataTraces(itrace).sampleCount-1)) = dataTraces(itrace).data(:)';
                                % find time offset between this trace and the origin
                                % populate the xMergeArray with the time (in seconds)
                                % since the origin
                                traceStartOffsetSeconds = (dataTraces(itrace).startTime - startTimeEpoch) * 24 * 60 * 60;

                                % This method of determining the timing of fetch may
                                % have problems when the sample rate and requested
                                % origin are slightly off.
                                % traceEndOriginOffsetSeconds = (dataTracesNew(itrace).endTime - originEpochTime) * 24 * 60 * 60;
                                % xMergeArray(jtrace:(jtrace+dataTracesNew(itrace).sampleCount-1)) = traceStartOriginOffsetSeconds:1.0/dataTracesNew(itrace).sampleRate:traceEndOriginOffsetSeconds;

                                % More robust for interpolation, but *probably* slower
                                xMergeArray(jtrace) = traceStartOffsetSeconds;
                                for ii=1:dataTraces(itrace).sampleCount-1
                                    xMergeArray(jtrace+ii) = xMergeArray(jtrace+ii-1) + 1.0/dataTraces(itrace).sampleRate;
                                end

                                % update the jtrace - index used to find location
                                % within the merge arrays
                                jtrace = jtrace + dataTraces(itrace).sampleCount;

                            end

                            % interp1
                            interpolatedAmplitude = interp1(xMergeArray,yMergeArray,outputTimeArray,'linear','extrap');

                            % repack the interpolated array into dataTracesMerged
                            interpedMergedData{2} = dataTraces(keptchansn(1));
                            interpedMergedData{2}.data = zeros(1,length(interpolatedAmplitude));
                            interpedMergedData{2}.data = interpolatedAmplitude;
                            interpedMergedData{2}.sampleCount = length(interpedMergedData{2}.data);
                            interpedMergedData{2}.sampleRate = traceSampleRate;
                            interpedMergedData{2}.endTime = endTimeEpoch;
                            interpedMergedData{2}.startTime = startTimeEpoch;
                            
                        else
                            itrace = keptchansn(1);
                            obtainedTimeArray = linspace(dataTraces(itrace).startTime, dataTraces(itrace).endTime, dataTraces(itrace).sampleCount);
                            interpolatedAmplitude = interp1(obtainedTimeArray, dataTraces(itrace).data, outputTimeArray,'linear','extrap');
                            interpedMergedData{2} = dataTraces(keptchansn(1));
                            interpedMergedData{2}.data = zeros(1,length(interpolatedAmplitude));
                            interpedMergedData{2}.data = interpolatedAmplitude;
                            interpedMergedData{2}.sampleRate = traceSampleRate;
                            interpedMergedData{2}.sampleCount = length(interpedMergedData{2}.data);
                            interpedMergedData{2}.startTime = startTimeEpoch;
                            interpedMergedData{2}.endTime = endTimeEpoch;
                        end
                        
                    end
                    % Repeat merge for ?HZ
                    if ~isempty(keptchansz)
                        if length(keptchansz) > 1
                            nptsObtained = 0;
                            for itrace=keptchansz
                                nptsObtained = nptsObtained + dataTraces(itrace).sampleCount;
                            end
                            % preallocate time and amplitude
                            yMergeArray = zeros(1,nptsObtained);
                            xMergeArray = zeros(1,nptsObtained);
                 
                            % Create x and y arrays of time and amplitudes
                            jtrace = 1;
                            for itrace=keptchansz
                                yMergeArray(jtrace:(jtrace+dataTraces(itrace).sampleCount-1)) = dataTraces(itrace).data(:)';
                                % find time offset between this trace and the origin
                                % populate the xMergeArray with the time (in seconds)
                                % since the origin
                                traceStartOffsetSeconds = (dataTraces(itrace).startTime - startTimeEpoch) * 24 * 60 * 60;

                                % This method of determining the timing of fetch may
                                % have problems when the sample rate and requested
                                % origin are slightly off.
                                % traceEndOriginOffsetSeconds = (dataTracesNew(itrace).endTime - originEpochTime) * 24 * 60 * 60;
                                % xMergeArray(jtrace:(jtrace+dataTracesNew(itrace).sampleCount-1)) = traceStartOriginOffsetSeconds:1.0/dataTracesNew(itrace).sampleRate:traceEndOriginOffsetSeconds;

                                % More robust for interpolation, but *probably* slower
                                xMergeArray(jtrace) = traceStartOffsetSeconds;
                                for ii=1:dataTraces(itrace).sampleCount-1
                                    xMergeArray(jtrace+ii) = xMergeArray(jtrace+ii-1) + 1.0/dataTraces(itrace).sampleRate;
                                end

                                % update the jtrace - index used to find location
                                % within the merge arrays
                                jtrace = jtrace + dataTraces(itrace).sampleCount;

                            end

                            % interp1
                            interpolatedAmplitude = interp1(xMergeArray,yMergeArray,outputTimeArray,'linear','extrap');

                            % repack the interpolated array into dataTracesMerged
                            interpedMergedData{3} = dataTraces(keptchansz(1));
                            interpedMergedData{3}.data = zeros(1,length(interpolatedAmplitude));
                            interpedMergedData{3}.data = interpolatedAmplitude;
                            interpedMergedData{3}.sampleCount = length(interpedMergedData{3}.data);
                            interpedMergedData{3}.sampleRate = traceSampleRate;
                            interpedMergedData{3}.endTime = endTimeEpoch;
                            interpedMergedData{3}.startTime = startTimeEpoch;
                            
                        else
                            itrace = keptchansz(1);
                            obtainedTimeArray = linspace(dataTraces(itrace).startTime, dataTraces(itrace).endTime, dataTraces(itrace).sampleCount);
                            interpolatedAmplitude = interp1(obtainedTimeArray, dataTraces(itrace).data, outputTimeArray,'linear','extrap');
                            interpedMergedData{3} = dataTraces(keptchansz(1));
                            interpedMergedData{3}.data = zeros(1,length(interpolatedAmplitude));
                            interpedMergedData{3}.data = interpolatedAmplitude;
                            interpedMergedData{3}.sampleRate = traceSampleRate;
                            interpedMergedData{3}.sampleCount = length(interpedMergedData{3}.data);
                            interpedMergedData{3}.startTime = startTimeEpoch;
                            interpedMergedData{3}.endTime = endTimeEpoch;
                        end
                        
                    end
                
                    
                    %% So now for this combination of station and location
                    % code, we have a triple cell array interpedMergedData
                    ierr = 0;
                    [rotatedInterpedMergedData, ierr] = FL_rotateCellTripleToENZ(interpedMergedData);

                    % remove response:
                    if ierr == 0
                        [DeconnedData, ierr] = FL_responseRemoval( rotatedInterpedMergedData, 0.002, traceResponseSelection );
                    end
                    
                    
                    
                    %% Split at this point.
                    % 1. If we are using the traditional single station
                    % deconvolution method, then we can compute that here and
                    % write files.
                    % 2. If we are using the array based source method of
                    % deconvolution, then we'll need to start computing the
                    % source function and write three component data files
                    % Write E,N,Z sac files in RAWTRACES
                    if ierr == 0
                        [writtenTraces, ierr] = FL_writeFetchedTraces(DeconnedData, ProjectDirectory, 'RAWTRACES', traceResponseSelection, eventInfo, ievent);
                    end
                    
                    % keep track of files written
                    if ierr == 0
                        rawTracesFileNames{ievent,istation} = sprintf('%s %s %s',writtenTraces{1}.fullSacFileName, writtenTraces{2}.fullSacFileName, writtenTraces{3}.fullSacFileName);
                    end
%                     figure(2)
%                     subplot(3,1,1)
%                     plot(outputTimeArray,DeconnedData{1}.data,'k-');
%                     subplot(3,1,2)
%                     plot(outputTimeArray,DeconnedData{2}.data,'k-');
%                     subplot(3,1,3)
%                     plot(outputTimeArray,DeconnedData{3}.data,'k-');
                end  % loop for each unique location code
            end  % if there are three channels exactly
        end  % if station is in distance window
    end  % station loop
    
    %% RF processing now
    %  Split between deconvolution based on the station or on the array
    %  Deal with it in another subroutine and write the files into the
    %  rawtraces directory. We will then copy them into rawdata later
    FL_processAndWriteRFS(FL_rfOpt(1), rawTracesFileNames, ievent, nstations, ProjectDirectory, 'eqr');
    FL_processAndWriteRFS(FL_rfOpt(2), rawTracesFileNames, ievent, nstations, ProjectDirectory, 'eqt');
    
    
end   % event loop

%% set data directory
DataDirectory = fullfile(ProjectDirectory, 'RAWTRACES');
DataDir{1} = DataDirectory;
DirName = strread(DataDirectory,'%s','delimiter',filesep);
DirName = DirName{end};
if ~exist([ProjectDirectory, 'RAWDATA', filesep, DirName],'dir')
    copyfile(DataDirectory,[ProjectDirectory, 'RAWDATA', filesep, DirName])
    [RecordMetadataStrings,RecordMetadataDoubles] = fl_add_new_data(ProjectDirectory,'Project.mat',DirName);
end

% Prepare project wide data
if evalin('base','~exist(''FuncLabPreferences'',''var'')')
    fl_default_prefs;
else
    FuncLabPreferences = evalin('base','FuncLabPreferences');
    if length(FuncLabPreferences) == 18
        FuncLabPreferences{19} = 'Blue to red';
        FuncLabPreferences{20} = '1.6.0';
    elseif length(FuncLabPreferences) == 19
        FuncLabPreferences{20} = '1.6.0';
    end
end
if evalin('base','~exist(''TraceEditPreferences'',''var'')')
    te_default_prefs;
else
    TraceEditPreferences = evalin('base','TraceEditPreferences');
end
Tablemenu = {'Station Tables','RecordMetadata',2,3,'Stations: ','Records (Listed by Event)','Events: ','fl_record_fields','string';
    'Event Tables','RecordMetadata',3,2,'Events: ','Records (Listed by Station)','Stations: ','fl_record_fields','string'};
save([ProjectDirectory 'Project.mat'],'TraceEditPreferences','FuncLabPreferences','Tablemenu','-append')
fl_init_logfile([ProjectDirectory 'Logfile.txt'],DataDir)
fl_datainfo(ProjectDirectory,'Project.mat',RecordMetadataStrings,RecordMetadataDoubles)
set(h.project_t,'string',ProjectDirectory)
set(h.new_title_t,'visible','off')
set(h.new_projdir_t,'visible','off')
set(h.new_projdir_e,'visible','off')
set(h.new_adddata_t,'visible','off')
set(h.new_start_pb,'visible','off')
set(h.explorer_fm,'visible','on')
set(h.tablemenu_pu,'visible','on')
set(h.tablesinfo_t,'visible','on')
set(h.tables_ls,'visible','on')
set(h.records_t,'visible','on')
set(h.recordsinfo_t,'visible','on')
set(h.records_ls,'visible','on')
set(h.info_t,'visible','on')
set(h.info_ls,'visible','on')
set(h.new_m,'Enable','off')
set(h.new_fetch_m,'Enable','off')
set(h.load_m,'Enable','off')
set(h.add_m,'Enable','on')
set(h.param_m,'Enable','on')
set(h.log_m,'Enable','on')
set(h.close_m,'Enable','on')
set(h.manual_m,'Enable','on')
set(h.autoselect_m,'Enable','on')
set(h.autoall_m,'Enable','on')
set(h.im_te_m,'Enable','on')
set(h.tepref_m,'Enable','on')
set(h.seis_m,'Enable','on')
set(h.record_m,'Enable','on')
set(h.stacked_record_m,'Enable','on')
set(h.moveout_m,'Enable','on')
set(h.moveout_image_m,'Enable','on')
set(h.baz_m,'Enable','on')
set(h.baz_image_m,'Enable','on')
set(h.datastats_m,'Enable','on')
set(h.stamap_m,'Enable','on')
set(h.evtmap_m,'Enable','on')
set(h.datadiagram_m,'Enable','on')
set(h.ex_stations_m,'Enable','on')
set(h.ex_events_m,'Enable','on')
set(h.ex_te_m,'Enable','on')
set(h.ex_rfs_m,'Enable','on')
if isfield(h,'addons')
    addons = h.addons;
    for n = 1:length(addons)
        eval(['set(h.' addons{n} '_m,''Enable'',''on'')'])
    end
end

% Turn off all the fetch buttons
set(h.new_fetch_title_t,'visible','off')
set(h.new_fetch_projdir_t,'visible','off')
set(h.new_fetch_projdir_e,'visible','off')
set(h.new_fetch_start_pb,'visible','off')
set(h.new_fetch_get_map_coords_pb,'visible','off')
set(h.new_fetch_lat_max_e,'visible','off');
set(h.new_fetch_lat_min_e,'visible','off');
set(h.new_fetch_lon_max_e,'visible','off');
set(h.new_fetch_lon_min_e,'visible','off');
set(h.new_fetch_get_stations_pb,'visible','off');
set(h.new_fetch_station_panel,'visible','off');
set(h.new_fetch_events_panel,'Visible','off');
set(h.new_fetch_search_start_time_text,'Visible','off');
set(h.new_fetch_search_end_time_text,'Visible','off');
set(h.new_fetch_start_year_pu,'visible','off');
set(h.new_fetch_start_month_pu,'visible','off');
set(h.new_fetch_start_day_pu,'visible','off');
set(h.new_fetch_end_year_pu,'visible','off');
set(h.new_fetch_end_month_pu,'visible','off');
set(h.new_fetch_end_day_pu,'visible','off');
set(h.new_fetch_search_magnitude_text,'visible','off');
set(h.new_fetch_min_mag_pu,'visible','off');
set(h.new_fetch_max_mag_pu,'visible','off');
set(h.new_fetch_event_mag_divider_t,'Visible','off');
set(h.new_fetch_search_distance_text,'Visible','off');
set(h.new_fetch_max_dist_e,'Visible','off');
set(h.new_fetch_min_dist_e,'Visible','off');
set(h.new_fetch_event_distance_divider_t,'Visible','off');
set(h.new_fetch_find_events_pb,'Visible','off');
set(h.new_fetch_max_depth_e,'Visible','off');
set(h.new_fetch_min_depth_e,'Visible','off');
set(h.new_fetch_search_depth_text,'Visible','off');
set(h.new_fetch_event_depth_divider_t,'Visible','off');
set(h.new_fetch_search_depth_text,'visible','off');
set(h.new_fetch_traces_panel,'visible','off');
%set(h.new_fetch_traces_timing_text,'Visible','off');
%set(h.new_fetch_traces_seconds_before_edit,'Visible','off');
%set(h.new_fetch_traces_phase_popup,'Visible','off');
set(h.new_fetch_traces_start_phase_popup,'Visible','off');
set(h.new_fetch_traces_start_time_text,'Visible','off');
set(h.new_fetch_traces_prior_seconds_edit,'Visible','off');
set(h.new_fetch_traces_start_seconds_label,'Visible','off');
set(h.new_fetch_traces_start_before_or_after_popup,'Visible','off');
set(h.new_fetch_traces_end_phase_popup,'Visible','off');
set(h.new_fetch_traces_end_time_text,'Visible','off');
set(h.new_fetch_traces_after_seconds_edit,'Visible','off');
set(h.new_fetch_traces_end_seconds_label,'Visible','off');
set(h.new_fetch_traces_end_before_or_after_popup,'Visible','off');
set(h.new_fetch_traces_end_phase_popup,'Visible','off');
set(h.new_fetch_traces_sample_rate_text,'Visible','off');
set(h.new_fetch_traces_sample_rate_popup,'Visible','off');
set(h.new_fetch_traces_sample_rate_label,'Visible','off');
set(h.new_fetch_traces_debug_button,'Visible','off');
set(h.easterEggPanel,'Visible','off');
set(h.new_fetch_rfprocessing_params_panel,'Visible','off');
set(h.new_fetch_traces_response_text,'Visible','off');
set(h.new_fetch_traces_response_popup,'Visible','off');
set(h.new_fetch_rfprocessing_taper_popup,'Visible','off');
set(h.new_fetch_rfprocessing_taper_text,'Visible','off');
set(h.new_fetch_rfprocessing_high_pass_edit,'Visible','off');
set(h.new_fetch_rfprocessing_filter_high_pass_text,'Visible','off');
set(h.new_fetch_rfprocessing_low_pass_edit,'Visible','off');
set(h.new_fetch_rfprocessing_filter_low_pass_text,'Visible','off');
set(h.new_fetch_rfprocessing_filter_order_text,'Visible','off');
set(h.new_fetch_rfprocessing_order_popup,'Visible','off');
set(h.new_fetch_rfprocessing_cut_before_phase_text,'Visible','off');
set(h.new_fetch_rfprocessing_cut_after_phase_text,'Visible','off');
set(h.new_fetch_rfprocessing_cut_after_phase_edit,'Visible','off');
set(h.new_fetch_rfprocessing_cut_before_phase_edit,'Visible','off');
set(h.new_fetch_rfprocessing_numerator_text,'Visible','off');
set(h.new_fetch_rfprocessing_numerator_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_text,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_method_text,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_method_popup,'Visible','off');
set(h.new_fetch_rfprocessing_deconvolution_method_text,'Visible','off');
set(h.new_fetch_rfprocessing_deconvolution_method_popup,'Visible','off');
set(h.new_fetch_rfprocessing_waterlevel_edit,'Visible','off');
set(h.new_fetch_rfprocessing_waterlevel_text,'Visible','off');
set(h.new_fetch_rfprocessing_max_iterations_text,'Visible','off');
set(h.new_fetch_rfprocessing_max_iterations_edit,'Visible','off');
set(h.new_fetch_rfprocessing_gaussian_edit,'Visible','off');
set(h.new_fetch_rfprocessing_gaussian_text,'Visible','off');
set(h.new_fetch_rfprocessing_min_error_text,'Visible','off');
set(h.new_fetch_rfprocessing_min_error_edit,'Visible','off');
set(h.new_fetch_rfprocessing_primary_choice_text,'Visible','off');
set(h.new_fetch_rfprocessing_secondary_choice_text,'Visible','off');
set(h.new_fetch_rfprocessing_taper_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_high_pass_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_low_pass_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_order_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_cut_after_phase_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_cut_before_phase_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_numerator_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_denominator_method_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_deconvolution_method_2_popup,'Visible','off');
set(h.new_fetch_rfprocessing_waterlevel_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_max_iterations_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_gaussian_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_min_error_2_edit,'Visible','off');
set(h.new_fetch_rfprocessing_incident_phase_text,'Visible','off');
set(h.new_fetch_rfprocessing_incident_phase_popup,'Visible','off');
set(h.new_fetch_rfprocessing_incident_phase_2_popup,'Visible','off');


assignin('base','RecordMetadataStrings',RecordMetadataStrings)
assignin('base','RecordMetadataDoubles',RecordMetadataDoubles)
assignin('base','Tablemenu',Tablemenu)
set(h.tablemenu_pu,'String',Tablemenu(:,1))
TableValue = 1;
set(h.tablemenu_pu,'Value',TableValue)
Tables = sort(unique(RecordMetadataStrings(:,2)));
set(h.tables_ls,'String',Tables)
set(h.tablesinfo_t,'String',[Tablemenu{TableValue,5} num2str(length(Tables))])
set(h.records_t,'String',Tablemenu{TableValue,6})
set(h.message_t,'String','Message:')
%close(WaitGui)
tables_Callback







