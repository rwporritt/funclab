function ccp_corrections(cbo,eventdata,handles)
%CCP_CORRECTIONS Velocity heterogeneity corrections
%   CCP_CORRECTIONS is a callback function that computes the differential
%   travel time associated with each 1D ray segment as interpolated from a
%   3D tomographic model.
%
%   NOTE: This may be kind of repetitious because we need to specify which
%   1D model we are computing time residuals for.  Therefore, if we wanted
%   to just include this step in the migration, we could.  However, for
%   the sake of keeping certain steps seperate and clearly stated, we will
%   make this a seperate step.
%
%   12/10/2008 - Added the feature where NaN's in the correction matrix
%   turn into zeros.

%   Author: Kevin C. Eagar
%   Date Created: 03/08/2008
%   Last Updated: 05/18/2010

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
    'String','Please wait, calculating travel time corrections for 1D P- and S-wave rays.',...
    'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
drawnow;
H = guihandles(WaitGui);
guidata(WaitGui,H);
%WaitGui = waitbar(0,'Please wait while calculating travel time corrections');

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

if CurrentSubsetIndex == 1
    CCPDataDir = fullfile(ProjectDirectory, 'CCPData');
    CCPMatFile = fullfile(ProjectDirectory, 'CCPData', 'CCPData.mat');
    CCPBinLead = ['CCPData' filesep 'Bin_'];
else
    CCPDataDir = fullfile(ProjectDirectory, 'CCPData', SetName);
    CCPMatFile = fullfile(ProjectDirectory, 'CCPData', SetName, 'CCPData.mat');
    CCPBinLead = ['CCPData' filesep SetName filesep 'Bin_'];
end

% Set initial values
%--------------------------------------------------------------------------
DepthIncrement = str2double(get(h.depthinc_e,'string'));
DepthMax = str2double(get(h.depthmax_e,'string'));
VModel = get(h.velocity_p,'string');
VModel = VModel{get(h.velocity_p,'value')};
TModel = get(h.tomo_p,'string');
TModel = TModel{get(h.tomo_p,'value')};
RayDepths(:,1) = 1:DepthIncrement:DepthMax;

% Load and setup the 3D tomography model
%--------------------------------------------------------------------------
Datapath = regexprep(which('funclab'),'funclab.m','TOMOMODELS/');
Tomo = [Datapath TModel];
load(Tomo);
TDepths(:,1) = Depths(1,1,:);
TLons(:,1) = Lons(:,1,1);
TLats(:,1) = Lats(1,:,1);
%disp('Model loaded')

% Load and setup the 1D velocity model
%--------------------------------------------------------------------------
Datapath = regexprep(which('funclab'),'funclab.m','VELMODELS/');
Velocity1D = [Datapath VModel];
VelocityModel = load(Velocity1D,'-ascii');
VDepths = VelocityModel(:,1);
Vp = VelocityModel(:,2);
Vs = VelocityModel(:,3);
NewVp(1,1,:) = interp1(VDepths,Vp,TDepths);
NewVs(1,1,:) = interp1(VDepths,Vs,TDepths);
NewVp = repmat(NewVp,[length(TLons) length(TLats) 1]);
NewVs = repmat(NewVs,[length(TLons) length(TLats) 1]);
if strcmp(TomoType,'velocity')
    dModelP = (ModelP - NewVp)./NewVp;
    dModelS = (ModelS - NewVs)./NewVs;
elseif strcmp(TomoType,'perturbation')
    dModelP = ModelP;
    dModelS = ModelS;
end
CVp = interp1(VDepths,Vp,RayDepths);
CVs = interp1(VDepths,Vs,RayDepths);
%disp('CVp and CVs ready')
close(WaitGui)
% Compute the travel time perturbations in each ray tracing matrix
%--------------------------------------------------------------------------
temp = who('-file',CCPMatFile,'MidPoints*');
for n = 1:length(temp)
    Numb = num2str(n,'%02.0f');
    load(CCPMatFile,['MidPoints_' Numb])
    MidPoints = eval(['MidPoints_' Numb]);
    nmidpoints = size(MidPoints,2);
    updatemidpoints = floor(nmidpoints/100);
    waitstring = sprintf('Calculating through MidPoints %d',n);
    littlewaithdls = waitbar(0,waitstring);
    
    for m = 1:size(MidPoints,2)
        xi = MidPoints(:,m,4); yi = MidPoints(:,m,5); zi = RayDepths;
        StopIndex = find(isnan(xi),1);
        if ~isempty(StopIndex)
            xi = xi(1:StopIndex-1); yi = yi(1:StopIndex-1); zi = zi(1:StopIndex-1);
            dvp = interp3(Lats,Lons,Depths,dModelP,xi,yi,zi);
            dvp = [dvp;(NaN * ones(size(MidPoints,1)-StopIndex+1,1))];
        else
            dvp = interp3(Lats,Lons,Depths,dModelP,xi,yi,zi);
        end
        xi = MidPoints(:,m,1); yi = MidPoints(:,m,2); zi = RayDepths;
        StopIndex = find(isnan(xi),1);
        if ~isempty(StopIndex)
            xi = xi(1:StopIndex-1); yi = yi(1:StopIndex-1); zi = zi(1:StopIndex-1);
            dvs = interp3(Lats,Lons,Depths,dModelS,xi,yi,zi);
            dvs = [dvs;(NaN * ones(size(MidPoints,1)-StopIndex+1,1))];
        else
            dvs = interp3(Lats,Lons,Depths,dModelS,xi,yi,zi);
        end
        dls = MidPoints(:,m,3); dlp = MidPoints(:,m,6);
        Temp = (dls./(CVs.*(1+dvs)) - dls./CVs) - (dlp./(CVp.*(1+dvp)) - dlp./CVp);
        Temp(isnan(Temp)) = 0;
        TimeCorrections(:,m) = cumsum([0; Temp]);
        if mod(m,updatemidpoints) == 0
            waitbar(m/nmidpoints,littlewaithdls);
        end
    end
    delete(littlewaithdls);
    eval(['TimeCorrections_' Numb ' = TimeCorrections;'])
    save(CCPMatFile,['TimeCorrections_' Numb],'-append');
    clear TimeCorrections* MidPoints*
end

% Update the Log File
%--------------------------------------------------------------------------
LogFile = [ProjectDirectory 'Logfile.txt'];
CTime = clock;
NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - CCP Stacking: Velocity Heterogeneity Corrections. Set %s',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6), SetName);
NewLog{2} = ['     1. ' VModel ' 1D velocity model'];
NewLog{3} = ['     2. ' TModel ' tomography model'];
NewLog{4} = ['     3. ' num2str(DepthIncrement) ' km depth increment'];
NewLog{5} = ['     4. ' num2str(DepthMax) ' km imaging depth'];
t_temp = toc;
NewLog{6} = ['     5. Velocity heterogeneity corrections took ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).'];
fl_edit_logfile(LogFile,NewLog)
%close(WaitGui)
set(h.MainGui.message_t,'String',['Message: CCP Stacking: 3D Timing Corrections took ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).'])