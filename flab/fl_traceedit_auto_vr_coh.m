function fl_traceedit_auto_vr_coh(varargin)
%FL_TRACEEDIT_AUTO_VR_COH Automated trace editing
%
%    FL_TRACEEDIT_AUTO_VR_COH (ProjectDirectory,ProjectFile,CurrentRecords,CurrentIndices,Table) runs the automated
%    trace editing algorithm on the input table.  This will reset the
%    status of the records before running.  The "FuncLabGenParam" input
%    specifies the parameters that control aspects of the automation.
%
%    FL_TRACEEDIT_AUTO_VR_COH (ProjectDirectory,ProjectFile, SetIndex) This will
%    run the auto trace editing algorithm over only the set indicated in
%    SetIndex
%
%    FL_TRACEEDIT_AUTO_VR_COH (ProjectDirectory,ProjectFile) runs the automated trace
%    editing algorithm on all the tables in the project.  This will reset
%    the status of the records before running.
%    
%    Based on FL_TRACEEDIT_AUTO, but using an algorithm which looks at a
%    receiver gather to select for highly similar traces by using the
%    variance reduction and coherence of each trace with respect to a
%    stacked RF. Requires signal processing toolbox for coherence. 
%    
%
%    Author: Robert W. Porritt
%    Date Created: June 16, 2015
%    Last Updated: June 16, 2015

% Wait message
%--------------------------------------------------------------------------
WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
    'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
    'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
h = guihandles(WaitGui);
guidata(WaitGui,h);
drawnow

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% Initial Defaults
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
ProjectDirectory = varargin{1};
ProjectFile = varargin{2};
RecordMetadataStrings = evalin('base','RecordMetadataStrings');
RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');

% Check for signal processing toolbox and set a flag to use coherence or
% not
if license('test','signal_toolbox')
    UseCoherenceFlag = 1;
end

if nargin == 5
    CurrentRecords = varargin{3};
    CurrentIndices = varargin{4};
    Table = varargin{5};
    set(h.message_t,'String',['Please wait, performing automated trace editing for ' Table])
elseif nargin == 2
    CurrentRecords = [RecordMetadataStrings num2cell(RecordMetadataDoubles)];
    CurrentIndices = [1:size(CurrentRecords,1)]';
    set(h.message_t,'String','Please wait, performing automated trace editing for ALL TABLES in dataset')
else
    error ('Incorrect number of inputs')
end
load([ProjectDirectory ProjectFile],'TraceEditPreferences')
% Going to hard wire some parameters here that should be adequate for the
% test case at least. If kept, these might go into the trace edit
% preferences
MinVR = 0.0; % Minimum acceptable variance reduction between the trace and the stack
NSigmaCoherence = 2; % number of standard deviations below the mean coherence to keep
% These are similarity tests designed to only accept highly similar
% waveforms. They are not really appropriate for deep structure with large
% moveouts; a possible improvement would be to consider making multiple
% means - one for each rayp and baz bin.


% Cycle through the tables for automated processing
%--------------------------------------------------------------------------
StationNames = unique(CurrentRecords(:,2));
for istation=1:length(StationNames)
    StationName = StationNames(istation);
    AllStationNames = CurrentRecords(:,2);
    CurrentStationIndices = find(strcmp(StationName,AllStationNames));
    % Drop to just curent records for possible speed up (ie work with a smaller
    % variable)
    CurrentStationRecords = CurrentRecords(CurrentStationIndices,:);
    
    % Get memory for the data
    nptsTime = CurrentStationRecords{1,7};
    ntraces = size(CurrentStationRecords,1);
    RecordIndices = size(CurrentStationRecords,1);
    RRFAmps = zeros(ntraces, nptsTime);
    TRFAmps = zeros(ntraces, nptsTime);
    %Rayp = zeros(ntraces,1);
    %Baz = zeros(ntraces,1);
    isjunkarray = zeros(ntraces,1);

    % The time array (all are the same for each station due to shortcuts in the
    % coding)
    timeArray = zeros(1,nptsTime);
    for itime = 1:nptsTime
        timeArray(itime) = CurrentStationRecords{1,8} + (itime-1) * CurrentStationRecords{1,6};
    end

    % Read the traces
    disp('Reading traces')
    for itrace = 1:ntraces
        %Rayp(itrace) = CurrentStationRecords{itrace, 21};
        %Baz(itrace) = CurrentStationRecords{itrace, 22};
        RecordIndices(itrace) = CurrentStationIndices(itrace);
        %[RRFAmps(itrace,:),~] = fl_readseismograms([ProjectDirectory CurrentStationRecords{itrace,1} 'eqr']);
        [tmpAmps, tmpTime] = fl_readseismograms([ProjectDirectory CurrentStationRecords{itrace,1} 'eqr']);
        if isnan(tmpAmps(1)) || isinf(tmpAmps(1))
            isjunkarray(itrace) = 1;
            tmpAmps = zeros(1,length(tmpTime));
        end
        if length(tmpTime) ~= nptsTime
            RRFAmps(itrace,:) = interp1(tmpTime, tmpAmps, timeArray,'spline','extrap');
        else
            RRFAmps(itrace,:) = tmpAmps;
        end
        %[TRFAmps(itrace,:),~] = fl_readseismograms([ProjectDirectory CurrentStationRecords{itrace,1} 'eqt']);
        [tmpAmps, tmpTime] = fl_readseismograms([ProjectDirectory CurrentStationRecords{itrace,1} 'eqt']);
        if isnan(tmpAmps(1)) || isinf(tmpAmps(1))
            isjunkarray(itrace) = 1;
            tmpAmps = zeros(1,length(tmpTime));
        end
        if length(tmpTime) ~= nptsTime
            TRFAmps(itrace,:) = interp1(tmpTime, tmpAmps, timeArray,'spline','extrap');
        else
            TRFAmps(itrace,:) = tmpAmps;
        end
    end

    % Clear out nan or inf values
    disp('Removing bad traces')
    RRFAmpsClean = RRFAmps;
    TRFAmpsClean = TRFAmps;
    RecordIndicesClean = RecordIndices;
    nTracesNonNan = 0;
    for n=ntraces:-1:1
        if isnan(RRFAmps(n,1)) || isinf(RRFAmps(n,1)) || isnan(TRFAmps(n,1)) || isinf(TRFAmps(n,1))
            RRFAmpsClean(n,:) = [];
            TRFAmpsClean(n,:) = [];
            %Rayp(n) = [];
            %Baz(n) = [];
            RecordIndicesClean(n) = [];
            isjunkarray(n) = 1;
        elseif isjunkarray(n) == 1
            RRFAmpsClean(n,:) = [];
            TRFAmpsClean(n,:) = [];
            %Rayp(n) = [];
            %Baz(n) = [];
            RecordIndicesClean(n) = [];
        else
            % normalize
            RRFAmps(n,:) = RRFAmps(n,:) ./ max(RRFAmps(n,:));
            TRFAmps(n,:) = TRFAmps(n,:) ./ max(TRFAmps(n,:));
            RRFAmpsClean(n,:) = RRFAmps(n,:);
            TRFAmpsClean(n,:) = TRFAmps(n,:);
            nTracesNonNan = nTracesNonNan + 1;
        end
    end

    % Get the overall mean
    disp('Computing the mean')
    MeanRRFAmp = mean(RRFAmpsClean,1);
    MeanTRFAmp = mean(TRFAmpsClean,1);

    if UseCoherenceFlag == 1
        disp('Computing Coherence')
        % Get peak coherence of each trace with the mean
        CoherenceArrayRClean = zeros(nTracesNonNan,1);
        CoherenceArrayTClean = zeros(nTracesNonNan,1);
        CoherenceArrayR = zeros(ntraces,1);
        CoherenceArrayT = zeros(ntraces,1);
        jtrace = 0;
        for itrace=1:ntraces
            if isjunkarray(itrace) == 0
                jtrace = jtrace + 1;
                coh = mscohere(MeanRRFAmp, RRFAmps(itrace,:));
                CoherenceArrayR(itrace) = max(coh); 
                CoherenceArrayRClean(jtrace) = CoherenceArrayR(itrace);

                coh = mscohere(MeanTRFAmp, TRFAmps(itrace,:));
                CoherenceArrayT(itrace) = max(coh);
                CoherenceArrayTClean(jtrace) = CoherenceArrayT(itrace);
            else
                CoherenceArrayR(itrace) = -1;
                CoherenceArrayT(itrace) = -1;
            end
        end
    end
 
    % Get VR of each trace with the mean
    disp('Computing VR')
    VRArrayR = zeros(ntraces,1);
    VRArrayT = zeros(ntraces,1);
    for itrace=1:ntraces
        if isjunkarray(itrace) == 0
            vr = vr_calc(MeanRRFAmp, RRFAmps(itrace,:));
            VRArrayR(itrace) = vr;

            vr = vr_calc(MeanTRFAmp, TRFAmps(itrace,:));
            VRArrayT(itrace) = vr;
        else
            VRArrayR(itrace) = -100;
            VRArrayT(itrace) = -100;
        end
    end
    
    % Remove low VR and low coherence
    %CleanRRFAmps = RRFAmps;
    %CleanTRFAmps = TRFAmps;

    if UseCoherenceFlag == 1
        minCoherenceR = mean(CoherenceArrayRClean) - NSigmaCoherence * std(CoherenceArrayRClean);
        minCoherenceT = mean(CoherenceArrayTClean) - NSigmaCoherence * std(CoherenceArrayTClean);
        % Avoid having coherence minimum being too small
        if minCoherenceR < 0.1
            minCoherenceR = 0.1;
        end
        if minCoherenceT < 0.1
            minCoherenceT = 0.1;
        end
    end
    
    %ntracesClean = ntraces;
    disp('Filtering')
    for itrace=1:ntraces
        if UseCoherenceFlag == 1
            RejectFlag = VRArrayR(itrace) <= MinVR || VRArrayT(itrace) <= MinVR || CoherenceArrayR(itrace) < minCoherenceR || CoherenceArrayT(itrace) < minCoherenceT;
        else
            RejectFlag = VRArrayR(itrace) <= MinVR || VRArrayT(itrace) <= MinVR; 
        end
        %if VRArrayR(itrace) <= MinVR || VRArrayT(itrace) <= MinVR || CoherenceArrayR(itrace) < minCoherenceR || CoherenceArrayT(itrace) < minCoherenceT
        if RejectFlag == 1
            %CleanRRFAmps(itrace,:) = [];
            %CleanTRFAmps(itrace,:) = [];
            %ntracesClean = ntracesClean - 1;
            CurrentStationRecords{itrace,5} = 0;
            CurrentStationRecords{itrace,4} = 1;
        else
            % Turn on passing RFs
            CurrentStationRecords{itrace,5} = 1;
            CurrentStationRecords{itrace,4} = 1;
        end
    end
    CurrentRecords(CurrentStationIndices,:) = CurrentStationRecords;
    fprintf('Done with station %s\n', StationName{1});
end

% Save the records that we are editing into the overall project file
%--------------------------------------------------------------------------
for n = 1:size(CurrentRecords,1)
    RecordMetadataDoubles(CurrentIndices(n),1) = 1;
    RecordMetadataDoubles(CurrentIndices(n),2) = CurrentRecords{n,5};
end
if nargin == 5
    assignin('base','CurrentRecords',CurrentRecords);
end
assignin('base','RecordMetadataDoubles',RecordMetadataDoubles);
SetManagementCell{CurrentSubsetIndex,3} = RecordMetadataDoubles;
assignin('base','SetManagementCell',SetManagementCell);
save([ProjectDirectory ProjectFile],'RecordMetadataDoubles','SetManagementCell','-append')

% Collect the new dataset statistics
%--------------------------------------------------------------------------
set(h.message_t,'String','Please wait, updating dataset statistics');
drawnow
fl_datainfo(ProjectDirectory,ProjectFile,RecordMetadataStrings,RecordMetadataDoubles)

% Update the Log File
%--------------------------------------------------------------------------
LogFile = [ProjectDirectory 'Logfile.txt'];
CTime = clock;
t_temp = toc;
SecTime = num2str((t_temp),'%.2f');
MinTime = num2str((t_temp)/60,'%.2f');
if nargin == 5
    NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - Auto Trace Editing: %s',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6),Table);
    NewLog{2} = ['     1. Automatic edits for ' Table ' took ' SecTime ' seconds (or ' MinTime ' minutes).'];
end
if nargin == 2
    NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - Auto Trace Editing: ALL TABLES',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6));
    NewLog{2} = ['     1. Automatic edits for ALL TABLES took ' SecTime ' seconds (or ' MinTime ' minutes).'];
end
fl_edit_logfile(LogFile,NewLog)
close(WaitGui)