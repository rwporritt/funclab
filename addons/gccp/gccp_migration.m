function gccp_migration(cbo,eventdata,handles)
%GCCP_MIGRATION Convert time axis to depth
%   GCCP_MIGRATION is a callback function that migrates the time axes of
%   all traces in the dataset to depth axes.  The depth axis, along with
%   the interpolated amplitude axes is stored in a "mat" file under the
%   directory DEPTHAXES in the project directory.  The path to this "mat"
%   file is stored in the station table under the "DepthPath" field.  This
%   function uses a 1D velocity model in cartesian coordinates, and the
%   direct P wave ray parameter for the migration.

%   Author: Kevin C. Eagar
%   Date Created: 12/30/2010
%   Last Updated: 06/15/2011

%Time the runtime of this function.
%--------------------------------------------------------------------------
tic

% Get the handles of the FuncLab GUI
%--------------------------------------------------------------------------
h = guidata(gcbf);

% Wait message
%--------------------------------------------------------------------------
WaitGui = dialog ('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
    'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
    'String','Please wait, performing GCCP time-to-depth migration for ALL TRACES in the dataset',...
    'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
drawnow;
H = guihandles(WaitGui);
guidata(WaitGui,H);

ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');

% Set initial values
%--------------------------------------------------------------------------
DepthIncrement = str2double(get(h.depthinc_e,'string'));
DepthMax = str2double(get(h.depthmax_e,'string'));
VModel = get(h.velocity_p,'string');
VModel = VModel{get(h.velocity_p,'value')};
YAxisRange = 0:DepthIncrement:DepthMax;
MagicNumber = 15000;    % 06/15/2011 CHANGED MAX NUMBER OF ARRAY ELEMENTS FROM 25,000 T0 15,000 TO AVOID OUT OF MEMORY ERRORS

% Load and setup the 1D velocity model
%--------------------------------------------------------------------------
Datapath = regexprep(which('funclab'),'funclab.m','VELMODELS/');
Velocity1D = [Datapath VModel];
VelocityModel = load(Velocity1D,'-ascii');
Depths = VelocityModel(:,1);
Vp = VelocityModel(:,2);
Vs = VelocityModel(:,3);
Vp = interp1(Depths,Vp,YAxisRange)';
Vs = interp1(Depths,Vs,YAxisRange)';
Depths = YAxisRange';
dz = diff(Depths);
dz = [0;dz];
R = 6371 - Depths;

%RecordMetadataStrings = evalin('base','RecordMetadataStrings');
%RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
RecordMetadataStrings = SetManagementCell{CurrentSubsetIndex, 2};
RecordMetadataDoubles = SetManagementCell{CurrentSubsetIndex, 3};
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

if CurrentSubsetIndex == 1
    GCCPMatFile = fullfile(ProjectDirectory, 'GCCPData', 'GCCPData.mat');
else
    GCCPMatFile = fullfile(ProjectDirectory, 'GCCPData', SetName, 'GCCPData.mat');
end

% Only proceed for the traces that are turned on
%--------------------------------------------------------------------------
ActiveIndices = find(RecordMetadataDoubles(:,2));
ActiveDoubles = RecordMetadataDoubles(ActiveIndices,:);
ActiveStrings = RecordMetadataStrings(ActiveIndices,:);

% Load in timing corrections and ray tracing matrix
%--------------------------------------------------------------------------
if ~isempty(who('-file',GCCPMatFile,'TimeCorrections*'))
    load(GCCPMatFile,'TimeCorrections_01')
end
load(GCCPMatFile,'RayMatrix_01')

count = 0;
SwitchCount = 1;
for n = 1:size(ActiveStrings,1)
    count = count + 1;
    
    % Determine if another matrix needs to be loaded in
    %------------------------------------------------------------------
    if count > MagicNumber% 06/15/2011: CHANGED RELATION FROM >= TO >
        count = 1;
        SwitchCount = SwitchCount + 1;
        save(GCCPMatFile,['RayMatrix_' num2str(SwitchCount-1,'%02.0f')],'-append')
        clear RayMatrix* TimeCorrections*
        load(GCCPMatFile,['RayMatrix_' num2str(SwitchCount,'%02.0f')])
        if ~isempty(who('-file',GCCPMatFile,'TimeCorrections*'))
            clear TimeCorrections*
            load(GCCPMatFile,['TimeCorrections_' num2str(SwitchCount,'%02.0f')])
        end
    end
    
    TimeAxis = linspace(ActiveDoubles(n,5),ActiveDoubles(n,6),ActiveDoubles(n,4))';
    
    % Calculate Pds travel time and create depth axis
    %--------------------------------------------------------------------------
    RayP = skm2srad(ActiveDoubles(n,18));
    Tpds = cumsum((sqrt((R./Vs).^2 - RayP^2) - sqrt((R./Vp).^2 - RayP^2)) .* (dz./R));
    if exist(['TimeCorrections_' num2str(SwitchCount,'%02.0f')],'var');
        Tpds = eval(['TimeCorrections_' num2str(SwitchCount,'%02.0f') '(:,count) + Tpds']);
    end
    StopIndex = find(imag(Tpds),1);
    if isempty(StopIndex)
        DepthAxis = interp1(Tpds,Depths,TimeAxis);
    else
        DepthAxis = interp1(Tpds(1:(StopIndex-1)),Depths(1:(StopIndex-1)),TimeAxis);
    end
    RRFTempAmps = gccp_readamps([ProjectDirectory ActiveStrings{n,1} 'eqr']);
    TRFTempAmps = gccp_readamps([ProjectDirectory ActiveStrings{n,1} 'eqt']);
    ValueIndices = find (~isnan(DepthAxis));
    
    if isempty(ValueIndices)   % 06/15/2011: ADDED IF STATEMENT TO CHECK IF THE CORRECT INTERPOLATION OF THE DEPTHS IS HAPPENING.  IF NOT, THE RECEIVER FUNCTIONS ARE FILLED WITH NANS.
        RRFAmps = Tpds * NaN;
        TRFAmps = Tpds * NaN;
    elseif (max(ValueIndices) > length(RRFTempAmps) && max(ValueIndices) > length(TRFTempAmps))
        RRFAmps = Tpds * NaN;
        TRFAmps = Tpds * NaN;
    elseif max(ValueIndices) > length(RRFTempAmps) && max(ValueIndices) <= length(TRFTempAmps)
        RRFAmps = Tpds * NaN;
        TRFAmps = interp1(DepthAxis(ValueIndices),TRFTempAmps(ValueIndices),YAxisRange);
        TRFAmps = colvector(TRFAmps);
        TRFAmps = TRFAmps/max(RRFAmps);
    elseif max(ValueIndices) <= length(RRFTempAmps) && max(ValueIndices) > length(TRFTempAmps)
        TRFAmps = Tpds * NaN;
        RRFAmps = interp1(DepthAxis(ValueIndices),RRFTempAmps(ValueIndices),YAxisRange);
        RRFAmps = colvector(RRFAmps);
        RRFAmps = RRFAmps/max(RRFAmps);
    else
        % Interpolate the amplitudes and depth axis to a depth range
        % (This saves us having to do this step for each stack)
        %------------------------------------------------------------------
        RRFAmps = interp1(DepthAxis(ValueIndices),RRFTempAmps(ValueIndices),YAxisRange);
        TRFAmps = interp1(DepthAxis(ValueIndices),TRFTempAmps(ValueIndices),YAxisRange);
        RRFAmps = colvector(RRFAmps);
        TRFAmps = colvector(TRFAmps);
        
        % Normalization of the Receiver Functions before saving them in
        % the RayMatrix.  (Added 10/6/2008)
        %--------------------------------------------------------------
        RRFAmps = RRFAmps/max(RRFAmps);
        TRFAmps = TRFAmps/max(RRFAmps);
    end
    
    eval(['RayMatrix_' num2str(SwitchCount,'%02.0f') '(:,count,1) = RRFAmps;'])
    eval(['RayMatrix_' num2str(SwitchCount,'%02.0f') '(:,count,2) = TRFAmps;'])
end
save(GCCPMatFile,['RayMatrix_' num2str(SwitchCount,'%02.0f')],'-append')   % 06/15/2011: REPLACED THE FOR LOOP WITH THE LAST MATRIX SAVED
DepthAxis = colvector(YAxisRange);
save(GCCPMatFile,'DepthAxis','-append')

% Update the Log File
%--------------------------------------------------------------------------
LogFile = [ProjectDirectory 'Logfile.txt'];
CTime = clock;
NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - GCCP Stacking: Time-to-Depth Migration set %s',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6), SetName);
if exist(['TimeCorrections_' num2str(SwitchCount,'%02.0f')],'var')
    NewLog{2} = '     1. Timing corrections for heterogeneous sructure were applied.';
else
    NewLog{2} = '     1. No timing corrections for heterogeneous sructure were applied.';
end
NewLog{3} = ['     2. ' VModel ' velocity model'];
NewLog{4} = ['     3. ' num2str(DepthIncrement) ' km depth increment'];
NewLog{5} = ['     4. ' num2str(DepthMax) ' km imaging depth'];
t_temp = toc;
NewLog{6} = ['     5. Depth migration took ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).'];
fl_edit_logfile(LogFile,NewLog)
close(WaitGui)
set(h.MainGui.message_t,'String',['Message: GCCP Stacking: Time-to-depth migration ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).'])
set(h.assignment_b,'Enable','on')
set(h.latmax_e,'Enable','on')
set(h.latmin_e,'Enable','on')
set(h.lonmax_e,'Enable','on')
set(h.lonmin_e,'Enable','on')
set(h.binwidth_e,'Enable','on')
set(h.binspacing_e,'Enable','on')