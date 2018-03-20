function moho_auto_pick(MainGui)
%MOHO_AUTO_PICK Start the Moho_auto_pick GUI
%   MOHO_AUTO_PICK initiates the automatic Moho picking GUI.  

%   H-k stacking gives one estimate of crustal thickness, but if we have
%   receiver functions defined in terms of depth, then we can use that to
%   estimate the crustal thickness. This does however, lead to something a
%   little bit circular as a Moho depth is an important component of a
%   velocity model, which is not normally accounted for in the depth
%   mapping. However, the uncertainty due to an incorrect velocity model
%   may be less than the uncertainties in H-k stacking.
%
%   Idea here is to give the user the option to load either the rays
%   computed in depth mapping (ie a mat file with a RayInfo cell array) or
%   to use a CCP volume to map out the Moho surface. User needs to set min
%   crustal thickness, delta crustal thickness, max crustal thickness, 
%   min amplitude, and CCPV2 or RayInfo. Output as a set of xyz points on 
%   the main window, saved in the project file, and plotted. RayInfo and 
%   CCPV2 based estimates are saved in different variable names. Once one 
%   has been plotted, use the Moho_auto_pick menu to plot a map view of the 
%   estimates. We may also add a button to visualizer to plot these 
%   estimates. Most (all) of this text should be available in the help menu.
%
%   Addon on variables:
%     MohoAutoPickStrings - {'RayInfo Moho Mat File', 'CCPV2 Moho Mat File'}
%     MohoAutoPickRIDoubles - (RIlongitude RIlatitude RIelevation RIthickness
%     RIMohoAmplitude)
%     MohoAutoPickCCPDoubles - (CCPlongitude CCPlatitude CCPelevation CCPthicknessRT
%     CCPMohoAmplitudeRT CCPThicknessG CCPAmplitudeG)
%       {Note the RT on the end of the CCP is for ray theory and G is for
%       gaussian width pulses}
%  The mat files created contain the parameters and doubles associated with
%    its run.
%
%
%   Author: Rob Porritt
%   Date Created: 05/07/2015
%   Last Updated: 05/07/2015

ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
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

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% GUI initiation
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Setup dimensions of the GUI
%--------------------------------------------------------------------------
MainPos = [0 0 60 26];
ParamTitlePos = [3 MainPos(4)-3 50 1.75];
ParamTextPos1 = [2 20 31 1.75];
ParamOptionPos1 = [32 20 20 1.75];

%--------------------------------------------------------------------------
% Create the main dialog box
%--------------------------------------------------------------------------
MohoAutoPickGui = dialog('Name','Moho Auto Picking','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');


% Set default values to userdata of main figure
% MohoAutoPickGui.UserData.MinThickness = 10.0;
% MohoAutoPickGui.UserData.MaxThickness = 60.0;
% MohoAutoPickGui.UserData.DeltaThickness = 1.0;
% MohoAutoPickGui.UserData.MinAmplitude = 0.5;
% RWP note: For this addon, I've decided to use setappdata to pass around
% information. This is similar to using a figure handle's userdata
% structure as I've done in many other functions. It is admittedly
% confusing to have several different methods of passing around parameters,
% but it is feasible that some method may go away in the future thus having
% multiple examples can be helpful for understanding how to translate one
% method into another.
setappdata(MohoAutoPickGui,'MinThickness',10.0);
setappdata(MohoAutoPickGui,'MaxThickness',80.0);
setappdata(MohoAutoPickGui,'DeltaThickness',1.0);
setappdata(MohoAutoPickGui,'MinAmplitude',0.05);
setappdata(MohoAutoPickGui,'RayInfoFile','None');
setappdata(MohoAutoPickGui,'CCPFile','None');

% Convert defaults to strings
% DefaultMinThickness_s = sprintf('%1.1f',MohoAutoPickGui.UserData.MinThickness);
% DefaultMaxThickness_s = sprintf('%1.1f',MohoAutoPickGui.UserData.MaxThickness);
% DefaultDeltaThickness_s = sprintf('%1.1f',MohoAutoPickGui.UserData.DeltaThickness);
% DefaultMinAmplitude_s = sprintf('%1.1f',MohoAutoPickGui.UserData.MinAmplitude);
DefaultMinThickness_s = sprintf('%1.1f',getappdata(MohoAutoPickGui,'MinThickness'));
DefaultMaxThickness_s = sprintf('%1.1f',getappdata(MohoAutoPickGui,'MaxThickness'));
DefaultDeltaThickness_s = sprintf('%1.1f',getappdata(MohoAutoPickGui,'DeltaThickness'));
DefaultMinAmplitude_s = sprintf('%1.1f',getappdata(MohoAutoPickGui,'MinAmplitude'));

% Check if the MohoAutoPick metadata is ready to plot
load([ProjectDirectory ProjectFile])
PlotCCPMohoEnable = 'off'; % whether or not the plot menu will be available
PlotRIMohoEnable = 'off';
if exist('MohoAutoPickCell','var')
    if size(MohoAutoPickCell,1) >= CurrentSubsetIndex
        MohoAutoPickStrings = MohoAutoPickCell{CurrentSubsetIndex};
        if ~isempty(MohoAutoPickStrings{1})
            if exist(MohoAutoPickStrings{1},'file')
                PlotRIMohoEnable = 'on';
            end
            if length(MohoAutoPickStrings) >= 2
                if exist(MohoAutoPickStrings{2},'file')
                    PlotCCPMohoEnable = 'on';
                end
            else
                MohoAutoPickStrings{2} = '';
            end
        end
    end
end

%--------------------------------------------------------------------------
% Moho_Auto_Pick Top Menu Items (for plotting and help)
%--------------------------------------------------------------------------
MPlotting = uimenu(MohoAutoPickGui,'Label','Plotting');
uimenu(MPlotting,'Label','Plot Ray Info Moho','Tag','moho_auto_pick_ri_plot_m','Enable',PlotRIMohoEnable,'Callback',{@plot_ri_moho_callback});
uimenu(MPlotting,'Label','Plot CCP Moho','Tag','moho_auto_pick_ccp_plot_m','Enable',PlotCCPMohoEnable,'Callback',{@plot_ccp_moho_callback});
MExport = uimenu(MohoAutoPickGui,'Label','Export');
uimenu(MExport,'Label','Export Ray Info Moho','Tag','moho_auto_pick_ri_export_m','Enable',PlotRIMohoEnable,'Callback',{@export_ri_moho_callback});
uimenu(MExport,'Label','Export CCP Moho','Tag','moho_auto_pick_ccp_export_m','Enable',PlotCCPMohoEnable,'Callback',{@export_ccp_moho_callback});
MHelp = uimenu(MohoAutoPickGui,'Label','Help');
uimenu(MHelp,'Label','Help','Tag','moho_auto_pick_help_m','Enable','on','Callback',{@moho_auto_pick_help_callback});

%--------------------------------------------------------------------------
% Moho auto pick Parameters
%--------------------------------------------------------------------------
TextFontSize = 0.6; % ORIGINAL
EditFontSize = 0.5;
AccentColor = [.6 0 0];

% Title
uicontrol ('Parent',MohoAutoPickGui,'Style','text','Units','characters','Tag','title_t','String','Moho auto picking',...
    'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',.8,'HorizontalAlignment','left','BackgroundColor','white');

% Close/go buttons
CloseButtonPosition = [2 2 18 2];
uicontrol('Parent',MohoAutoPickGui,'Style','Pushbutton','Units','Characters','Tag','moho_auto_pick_close_pb','String','Cancel',...
    'Position',CloseButtonPosition,'FontUnits','normalized','FontSize',0.4,'ForegroundColor',AccentColor,'FontWeight','bold',...
    'Callback',{@close_moho_auto_pick_Callback});

CloseButtonPosition = [21 2 18 2];
do_ray_info_button = uicontrol('Parent',MohoAutoPickGui,'Style','Pushbutton','Units','Characters','Tag','run_ray_info_pb','String','Pick Ray Info',...
    'Position',CloseButtonPosition,'FontUnits','normalized','FontSize',0.4,'ForegroundColor',AccentColor,'FontWeight','bold','Enable','off',...
    'Callback',{@do_ray_info_moho_auto_pick_Callback});

CloseButtonPosition = [40 2 18 2];
do_ccp_button = uicontrol('Parent',MohoAutoPickGui,'Style','Pushbutton','Units','Characters','Tag','run_ccp_pb','String','Pick CCP',...
    'Position',CloseButtonPosition,'FontUnits','normalized','FontSize',0.4,'ForegroundColor',AccentColor,'FontWeight','bold','Enable','off',...
    'Callback',{@do_ccp_moho_auto_pick_Callback});

% UI Element list
% textbox + edit box for min thickness
% textbox + edit box for max thickness
% textbox + edit box for delta thickness
% textbox + edit box for min amplitude 
%
% textbox + edit box + button for ray info file
% textbox + edit box + button for ccpv2 file
% 
% button for cancel
% button for go ray info
% button for go ccp
uicontrol('Parent',MohoAutoPickGui,'Style','Text','Units','Characters','Tag','min_thickness_t','String','Min Thickness:',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MohoAutoPickGui,'Style','Edit','Units','Characters','Tag','min_thickness_e','String',DefaultMinThickness_s,...
    'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','MinThick = str2num(get(gcbo,''String''));setappdata(gcbf,''MinThickness'',MinThick);');

ParamTextPos1(2) = 18;
ParamOptionPos1(2) = 18;
uicontrol('Parent',MohoAutoPickGui,'Style','Text','Units','Characters','Tag','max_thickness_t','String','Max Thickness:',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MohoAutoPickGui,'Style','Edit','Units','Characters','Tag','max_thickness_e','String',DefaultMaxThickness_s,...
    'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','MaxThick = str2num(get(gcbo,''String''));setappdata(gcbf,''MaxThickness'',MaxThick);');

ParamTextPos1(2) = 16;
ParamOptionPos1(2) = 16;
uicontrol('Parent',MohoAutoPickGui,'Style','Text','Units','Characters','Tag','delta_thickness_t','String','Delta Thickness:',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MohoAutoPickGui,'Style','Edit','Units','Characters','Tag','delta_thickness_e','String',DefaultDeltaThickness_s,...
    'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','DeltaThick = str2num(get(gcbo,''String''));setappdata(gcbf,''DeltaThickness'',DeltaThick);');

ParamTextPos1(2) = 14;
ParamOptionPos1(2) = 14;
uicontrol('Parent',MohoAutoPickGui,'Style','Text','Units','Characters','Tag','min_amplitude_t','String','Min amplitude:',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MohoAutoPickGui,'Style','Edit','Units','Characters','Tag','min_amplitude_e','String',DefaultMinAmplitude_s,...
    'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','MinAmp = str2num(get(gcbo,''String''));setappdata(gcbf,''MinAmplitude'',MinAmp);');

ParamTextPos1(2) = 12;
ParamOptionPos1(2) = 12;
uicontrol('Parent',MohoAutoPickGui,'Style','Text','Units','Characters','Tag','ray_info_file_t','String','Ray Info File:',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
longposition = ParamOptionPos1;
longposition(2) = 10;
longposition(1) = ParamTextPos1(1);
longposition(3) = ParamOptionPos1(1) + ParamOptionPos1(3);
rayinfo_edit = uicontrol('Parent',MohoAutoPickGui,'Style','Edit','Units','Characters','Tag','ray_info_file_e','String','',...
    'Position',longposition,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_ray_info_file_from_edit,do_ray_info_button});
uicontrol('Parent',MohoAutoPickGui,'Style','Pushbutton','Units','Characters','Tag','rayinfo_file_pb','String','Choose File',...
    'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',0.4,'ForegroundColor',AccentColor,'FontWeight','bold',...
    'Callback',{@get_ray_info_file_name,rayinfo_edit,do_ray_info_button});

ParamTextPos1(2) = 7;
ParamOptionPos1(2) = 7;
longposition = ParamOptionPos1;
longposition(2) = 5;
longposition(1) = ParamTextPos1(1);
longposition(3) = ParamOptionPos1(1) + ParamOptionPos1(3);
ccp_edit = uicontrol('Parent',MohoAutoPickGui,'Style','Edit','Units','Characters','Tag','ccp_file_e','String','',...
    'Position',longposition,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback',{@set_ccp_file_from_edit,do_ccp_button});
uicontrol('Parent',MohoAutoPickGui,'Style','Text','Units','Characters','Tag','ccp_file_t','String','CCPV2 File:',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol('Parent',MohoAutoPickGui,'Style','Pushbutton','Units','Characters','Tag','ccp_file_pb','String','Choose File',...
    'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',0.4,'ForegroundColor',AccentColor,'FontWeight','bold',...
    'Callback',{@get_ccp_file_name,ccp_edit,do_ccp_button});



 
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% Subfunction Callbacks
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% set_ray_info_file_from_edit
%--------------------------------------------------------------------------
function set_ray_info_file_from_edit(cbo, eventdata, bhandles)
FF = get(gcbo,'String');
if ~exist(FF,'file')
    disp('Ray Info edit box file not found')
    return
else
    load(FF)
    if exist('RayInfo','var')
        setappdata(gcbf,'RayInfoFile',FF);
        set(bhandles,'Enable','on');
    else
        disp('File does not contain RayInfo')
    end
end

%--------------------------------------------------------------------------
% set_ccp_file_from_edit
%--------------------------------------------------------------------------
function set_ccp_file_from_edit(cbo, eventdata, bhandles)
FF = get(gcbo,'String');
if ~exist(FF,'file')
    disp('CCP edit box file not found')
    return
else
    load(FF)
    if exist('CCPHits','var')
        setappdata(gcbf,'CCPFile',FF);
        set(bhandles,'Enable','on');
    else
        disp('File does not contain CCPV2 data')
    end
end

%--------------------------------------------------------------------------
% get_ccp_file_name
% launches a gui for the user to enter a matfile containing the ccp
%--------------------------------------------------------------------------
function get_ccp_file_name(cbo, eventdata, ehandles, bhandles)
[FileName, PathName] = uigetfile('*.mat','Choose a ccpv2 volume mat file');
if isequal(FileName,0) || isequal(PathName,0)
    disp('User canceled choosing ccpv2 volume')
    return
else
    load([PathName FileName]);
    if exist('CCPHits','var')
        setappdata(gcbf,'CCPFile',[PathName FileName]);
        set(ehandles,'String',[PathName FileName]);
        set(bhandles,'Enable','on');
    else
        disp('File does not contain CCPV2 data!')
        return
    end
end


%--------------------------------------------------------------------------
% get_ray_info_file_name
% launches a gui for the user to enter a matfile containing the ray info
%--------------------------------------------------------------------------
function get_ray_info_file_name(cbo, eventdata, ehandles, bhandles)
[FileName, PathName] = uigetfile('*.mat','Choose a ray info mat file');
if isequal(FileName,0) || isequal(PathName,0)
    disp('User canceled choosing Ray Info data')
    return
else
    load([PathName FileName]);
    if exist('RayInfo','var')
        setappdata(gcbf,'RayInfoFile',[PathName FileName])
        set(ehandles,'String',[PathName FileName]);
        set(bhandles,'Enable','on');
    else
        disp('File does not contain Ray Info data!')
        return
    end
end

%--------------------------------------------------------------------------
% do_ray_info_moho_auto_pick_Callback
% Finds the maximum in the depth window in the ray info for each ray
%--------------------------------------------------------------------------
function do_ray_info_moho_auto_pick_Callback(cbo, eventdata)

WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
    'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'},'Color','White');
uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
    'String','Please wait, finding Moho from the Ray Info.','BackgroundColor','white',...
    'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
drawnow;
H = guihandles(WaitGui);
guidata(WaitGui,H);

SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');

% Check for MohoAutoPickStrings
% MohoAutoPickStringsFlag = evalin('base','exist(''MohoAutoPickStrings'',''var'')');
% if MohoAutoPickStringsFlag
%     MohoAutoPickStrings = evalin('base','MohoAutoPickStrings');
% else
%     MohoAutoPickStrings = cell(2,1);
% end
MohoAutoPickCellFlag = evalin('base','exist(''MohoAutoPickCell'',''var'')');

if MohoAutoPickCellFlag
    MohoAutoPickCell = evalin('base','MohoAutoPickCell');
    if size(MohoAutoPickCell,1) >= CurrentSubsetIndex
        MohoAutoPickStrings = MohoAutoPickCell{CurrentSubsetIndex,1};
    else
        tmp = cell(size(SetManagementCell,1),3);
        for idx=1:size(MohoAutoPickCell)
            tmp{idx,1} = MohoAutoPickCell{idx,1};
            tmp{idx,3} = MohoAutoPickCell{idx,2};
            tmp{idx,3} = MohoAutoPickCell{idx,3};
        end
        MohoAutoPickCell = tmp;
        MohoAutoPickStrings = cell(2,1);
        MohoAutoPickStrings{1} = '';
        MohoAutoPickStrings{2} = '';
    end
end

% Get the data from the calling function
params = getappdata(gcbf);

obj = findobj('Tag','min_amplitude_e');
params.MinAmplitude = str2double(obj.String);
obj = findobj('Tag','min_thickness_e');
params.MinThickness = str2double(obj.String);
obj = findobj('Tag','max_thickness_e');
params.MaxThickness = str2double(obj.String);
obj = findobj('Tag','delta_thickness_e');
params.DeltaThickness = str2double(obj.String);


% returning to the tracking variable
MohoAutoPickStrings{1} = params.RayInfoFile;

% Quick error checking
params.DeltaThickness = abs(params.DeltaThickness);
if params.MinThickness < 0 || params.MaxThickness < 0
    disp('Warning, searching in negative depth, aka the atmosphere!')
end
if params.MinThickness > params.MaxThickness
    tmp = params.MinThickness;
    params.MinThickness = params.MaxThickness;
    params.MaxThickness = tmp;
end
if params.MinThickness == params.MaxThickness
    disp('Error, min and max thicknesses cannot be equal!')
    return
end

% Load the ray info
load(params.RayInfoFile,'RayInfo')
% RayInfo is a nray x 1 cell array
% Each cell element is a structure with vectors:
%   Latitude, Longitude, Radius, AmpR, and AmpT
%   It also contains a scalar 'RecordNumber' which can be used to reference
%     it to RecordMetadataStrings and RecordMetadataDoubles

% Remove rays with nan values for AmpR
for iray=1:length(RayInfo)
    for idz=1:length(RayInfo{iray}.AmpR)
        if isnan(RayInfo{iray}.AmpR(idz))
            RayInfo{iray}.AmpR(idz) = -1;
        end
    end
end


% Prepare memory
MohoAutoPickRIDoubles = zeros(length(RayInfo),5);
% Longitude, Latitude, Elevation, Depth, Amp

% Setup the search depth vector
SearchDepths = params.MinThickness:params.DeltaThickness:params.MaxThickness;

% Loop through all the rays looking up the maximum amplitude greater than
% the min amplitude in the parameters. If one is found in the search depth
% window, add it to the doubles array
for iray = 1:length(RayInfo)
    
    % easy parameter is MohoAutoPickRIDoubles(:,3) = Elevation
    MohoAutoPickRIDoubles(iray,3) = RayInfo{iray}.Radius(1) - 6371;
    
    % Interpolate the ray info's AmpR(Radius) to AmpRInterp(SearchDepths)
    AmpRInterp = interp1(6371-RayInfo{iray}.Radius, RayInfo{iray}.AmpR,SearchDepths,'spline',NaN);
    % Using extrap NaN sets the values outside the range to NaN. This
    % prevents them from being a positive result in the searching. The 
    % spline interp is chosen for a smoother model of amplitude vs. depth.
    
    % Check if this is greater than the minimum acceptable Moho peak
    if max(AmpRInterp) > params.MinAmplitude
        PeakIndex = find(AmpRInterp == max(AmpRInterp));
        MohoAutoPickRIDoubles(iray, 1) = interp1(6371-RayInfo{iray}.Radius, RayInfo{iray}.Longitude, SearchDepths(PeakIndex),'spline');
        MohoAutoPickRIDoubles(iray, 2) = interp1(6371-RayInfo{iray}.Radius, RayInfo{iray}.Latitude, SearchDepths(PeakIndex),'spline');
        MohoAutoPickRIDoubles(iray, 4) = SearchDepths(PeakIndex);
        MohoAutoPickRIDoubles(iray, 5) = AmpRInterp(PeakIndex);
    else
        MohoAutoPickRIDoubles(iray,:) = NaN;
    end
    
end

% Second loop to remove outliers
% First getting mean and standard deviation (may not need?)
%MeanThickness = mean(MohoAutoPickRIDoubles(:,4),'omitnan');
StdThickness = std(MohoAutoPickRIDoubles(:,4),'omitnan');
%MeanAmplitude = mean(MohoAutoPickRIDoubles(:,5),'omitnan');
%StdAmplitude = std(MohoAutoPickRIDoubles(:,5),'omitnan');

% Prepare a scatteredInterpolant to find an expected value at each station
nfound = sum(~isnan(MohoAutoPickRIDoubles(:,4)));
x=zeros(nfound,1);
y=zeros(nfound,1);
z=zeros(nfound,1);
idx = 0;
for jdx=1:length(RayInfo)
    if ~isnan(MohoAutoPickRIDoubles(jdx,1))
        idx = idx+1;
        x(idx) = MohoAutoPickRIDoubles(jdx,1);
        y(idx) = MohoAutoPickRIDoubles(jdx,2);
        z(idx) = MohoAutoPickRIDoubles(jdx,4);
    end
end
MohoFunction = scatteredInterpolant(x,y,z);
MohoFunction.Method = 'natural';
MohoFunction.ExtrapolationMethod = 'nearest';

for iray=1:length(RayInfo)
    
    % Set the search space based on the coordinates of this ray at the
    % surface and our interpolated function
    ExpectedThickness = MohoFunction(RayInfo{iray}.Longitude(1), RayInfo{iray}.Latitude(1));
    NewMinThickness = ExpectedThickness - StdThickness;
    if NewMinThickness < params.MinThickness
        NewMinThickness = params.MinThickness;
    end
    NewMaxThickness = ExpectedThickness + StdThickness;
    if NewMaxThickness > params.MaxThickness
        NewMaxThickness = params.MaxThickness;
    end
    NewSearchDepths = NewMinThickness:params.DeltaThickness:NewMaxThickness;
    
    % Interpolate the ray info's AmpR(Radius) to AmpRInterp(SearchDepths)
    AmpRInterp = interp1(6371-RayInfo{iray}.Radius, RayInfo{iray}.AmpR,NewSearchDepths,'spline',NaN);
    % Using extrap NaN sets the values outside the range to NaN. This
    % prevents them from being a positive result in the searching. The 
    % spline interp is chosen for a smoother model of amplitude vs. depth.
    
    % Check if this is greater than the minimum acceptable Moho peak
    if max(AmpRInterp) > params.MinAmplitude
        PeakIndex = find(AmpRInterp == max(AmpRInterp));
        MohoAutoPickRIDoubles(iray, 1) = interp1(6371-RayInfo{iray}.Radius, RayInfo{iray}.Longitude, NewSearchDepths(PeakIndex),'spline');
        MohoAutoPickRIDoubles(iray, 2) = interp1(6371-RayInfo{iray}.Radius, RayInfo{iray}.Latitude, NewSearchDepths(PeakIndex),'spline');
        MohoAutoPickRIDoubles(iray, 4) = NewSearchDepths(PeakIndex);
        MohoAutoPickRIDoubles(iray, 5) = AmpRInterp(PeakIndex);
    else
        MohoAutoPickRIDoubles(iray,:) = NaN;
    end
    
end

% Remove nans
for iray=length(RayInfo):-1:1
    if isnan(MohoAutoPickRIDoubles(iray,1))
        MohoAutoPickRIDoubles(iray,:) = [];
    end
end


% Output
assignin('base','MohoAutoPickRIDoubles',MohoAutoPickRIDoubles);
assignin('base','MohoAutoPickStrings',MohoAutoPickStrings);
MohoAutoPickCell{CurrentSubsetIndex,1} = MohoAutoPickStrings;
MohoAutoPickCell{CurrentSubsetIndex,2} = MohoAutoPickRIDoubles;
assignin('base','MohoAutoPickCell',MohoAutoPickCell);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
save([ProjectDirectory ProjectFile],'MohoAutoPickRIDoubles','MohoAutoPickStrings','MohoAutoPickCell','-append');

PlotHandles = findobj('Tag','moho_auto_pick_ri_plot_m');
ExportHandles = findobj('Tag','moho_auto_pick_ri_export_m');

% turn on export and plot options
set(ExportHandles,'Enable','on');
set(PlotHandles,'Enable','on');

close(WaitGui)

%--------------------------------------------------------------------------
% do_ccp_moho_auto_pick_Callback
% Finds the maximum window in the ccp volume for cells with non-zero hits
%--------------------------------------------------------------------------
function do_ccp_moho_auto_pick_Callback(cbo, eventdata)

WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
    'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'},'Color','White');
uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
    'String','Please wait, finding Moho from the ccp.','BackgroundColor','white',...
    'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
drawnow;
H = guihandles(WaitGui);
guidata(WaitGui,H);


SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
MohoAutoPickCellFlag = evalin('base','exist(''MohoAutoPickCell'',''var'')');

if MohoAutoPickCellFlag
    MohoAutoPickCell = evalin('base','MohoAutoPickCell');
    if size(MohoAutoPickCell,1) >= CurrentSubsetIndex
        MohoAutoPickStrings = MohoAutoPickCell{CurrentSubsetIndex,1};
    else
        tmp = cell(size(SetManagementCell,1),3);
        for idx=1:size(MohoAutoPickCell)
            tmp{idx,1} = MohoAutoPickCell{idx,1};
            tmp{idx,3} = MohoAutoPickCell{idx,2};
            tmp{idx,3} = MohoAutoPickCell{idx,3};
        end
        MohoAutoPickCell = tmp;
        MohoAutoPickStrings = cell(2,1);
    end
end


% Get the data from the calling function
params = getappdata(gcbf);
obj = findobj('Tag','min_amplitude_e');
params.MinAmplitude = str2double(obj.String);
obj = findobj('Tag','min_thickness_e');
params.MinThickness = str2double(obj.String);
obj = findobj('Tag','max_thickness_e');
params.MaxThickness = str2double(obj.String);
obj = findobj('Tag','delta_thickness_e');
params.DeltaThickness = str2double(obj.String);

% returning to the tracking variable
MohoAutoPickStrings{2} = params.CCPFile;

% Quick error checking
params.DeltaThickness = abs(params.DeltaThickness);
if params.MinThickness < 0 || params.MaxThickness < 0
    disp('Warning, searching in negative depth, aka the atmosphere!')
end
if params.MinThickness > params.MaxThickness
    tmp = params.MinThickness;
    params.MinThickness = params.MaxThickness;
    params.MaxThickness = tmp;
end
if params.MinThickness == params.MaxThickness
    disp('Error, min and max thicknesses cannot be equal!')
    return
end

% Load the ray info
load(params.CCPFile)
% The CCP File contains several important matrices
%   xvector: 1xNlongitude; longitude coordinates in the CCP
%   yvector: 1xNlatitude; latitude coordinates in the CCP
%   zvector: 1xNdepths: depth coordinates in the CCP
%   CCPStackR: NXxNYxNZ ray theory radial component RF CCP
%   CCPStackT: NXxNYxNZ ray theory tangential component RF CCP
%   CCPHits: NXxNYxNZ ray theory hit count CCP
%   CCPStackKernelR: NXxNYxNZ gaussian radial component RF CCP
%   CCPStackKernelT: NXxNYxNZ gaussian tangential component RF CCP
%   CCPHitsKernel: NXxNYxNZ gaussian hit count CCP
% At this point we search based on both ray theory and gaussian
% and in the plotting script put a switch between the two or just plot both
% as two separate figures


% Normalize by hit count first
for ix=1:length(xvector)
    for iy=1:length(yvector)
        for iz=1:length(zvector)
            if CCPHits(ix,iy,iz) >= 1
                CCPStackR(ix,iy,iz) = CCPStackR(ix,iy,iz) / CCPHits(ix,iy,iz);
                CCPStackT(ix,iy,iz) = CCPStackT(ix,iy,iz) / CCPHits(ix,iy,iz);
            else
                CCPStackR(ix,iy,iz) = 0.0;
                CCPStackT(ix,iy,iz) = 0.0;
            end
            if CCPHitsKernel(ix,iy,iz) >= 1
                CCPStackKernelR(ix,iy,iz) = CCPStackKernelR(ix,iy,iz) / CCPHitsKernel(ix,iy,iz);
                CCPStackKernelT(ix,iy,iz) = CCPStackKernelT(ix,iy,iz) / CCPHitsKernel(ix,iy,iz);
            else
                CCPStackKernelR(ix,iy,iz) = 0.0;
                CCPStackKernelT(ix,iy,iz) = 0.0;
            end
        end
    end
end

% peak-to-peak normalization for each column in depth. 
CCPStackTempR = CCPStackR;
CCPStackTempT = CCPStackT;
for ix=1:length(xvector)
    for iy=1:length(yvector)
        % Get peak at this point
        peakAmpR = -9001;
        peakAmpT = -9001;
        for iz=1:length(zvector)
            if abs(CCPStackTempR(ix,iy,iz)) > peakAmpR
                peakAmpR = abs(CCPStackTempR(ix,iy,iz));
            end
            if abs(CCPStackTempT(ix,iy,iz)) > peakAmpT
                peakAmpT = abs(CCPStackTempT(ix,iy,iz));
            end
        end
        % Now do normalization
        if peakAmpR > 0.001
            for iz=1:length(zvector)
                CCPStackR(ix,iy,iz) = CCPStackTempR(ix,iy,iz) / peakAmpR;
                CCPStackT(ix,iy,iz) = CCPStackTempT(ix,iy,iz) / peakAmpT;
            end
        else
            CCPStackR(ix,iy,iz) = 0.0;
            CCPStackT(ix,iy,iz) = 0.0;
        end
    end
end

% Repeat for FF
CCPStackTempR = CCPStackKernelR;
CCPStackTempT = CCPStackKernelT;
for ix=1:length(xvector)
    for iy=1:length(yvector)
        % Get peak at this point
        peakAmpR = -9001;
        peakAmpT = -9001;
        for iz=1:length(zvector)
            if abs(CCPStackTempR(ix,iy,iz)) > peakAmpR
                peakAmpR = abs(CCPStackTempR(ix,iy,iz));
            end
            if abs(CCPStackTempT(ix,iy,iz)) > peakAmpT
                peakAmpT = abs(CCPStackTempT(ix,iy,iz));
            end
        end
        % Now do normalization
        if peakAmpR > 0.001
            for iz=1:length(zvector)
                CCPStackKernelR(ix,iy,iz) = CCPStackTempR(ix,iy,iz) / peakAmpR;
                CCPStackKernelT(ix,iy,iz) = CCPStackTempT(ix,iy,iz) / peakAmpT;
            end
        else
            CCPStackKernelR(ix,iy,iz) = 0.0;
            CCPStackKernelT(ix,iy,iz) = 0.0;
        end
    end
end  

% Search space will be NX x NY
NLateralPoints = length(xvector) * length(yvector);

% Prepare memory
MohoAutoPickCCPDoubles = zeros(NLateralPoints, 7);
% Longitude, Latitude, Elevation, DepthRT, AmpRT, DepthG, AmpG

% Setup the search depth vector
SearchDepths = params.MinThickness:params.DeltaThickness:params.MaxThickness;

% Loop through all the rays looking up the maximum amplitude greater than
% the min amplitude in the parameters. If one is found in the search depth
% window, add it to the doubles array
tmpVector = ones(length(zvector),1);
iloc = 0;
for idx = 1:length(xvector)
    for idy=1:length(yvector)
    
        % location in the long matrix
        iloc = iloc + 1;
        
        % easy parameter is MohoAutoPickCCPDoubles(:,3) = Elevation
        MohoAutoPickCCPDoubles(iloc,3) = 0; % Not sure how to get this, nor do I think I'll ever actually use this.

        % Interpolate the ray info's AmpR(Radius) to AmpRInterp(SearchDepths)
        for idz=1:length(zvector)
            tmpVector(idz) = CCPStackR(idx, idy, idz);
        end
        AmpRInterpRT = interp1(zvector, tmpVector, SearchDepths,'spline',NaN);
        for idz=1:length(zvector)
            tmpVector(idz) = CCPStackR(idx, idy, idz);
        end
        AmpRInterpG = interp1(zvector, tmpVector, SearchDepths,'spline',NaN);
        
        % Update the location based on the xvector and yvector
        MohoAutoPickCCPDoubles(iloc, 1) = xvector(idx);
        MohoAutoPickCCPDoubles(iloc, 2) = yvector(idy);
        
        % Using extrap NaN sets the values outside the range to NaN. This
        % prevents them from being a positive result in the searching. The 
        % spline interp is chosen for a smoother model of amplitude vs. depth.

        % Check if this is greater than the minimum acceptable Moho peak
        if max(AmpRInterpRT) > params.MinAmplitude 
            PeakIndex = find(AmpRInterpRT == max(AmpRInterpRT));
            MohoAutoPickCCPDoubles(iloc, 4) = SearchDepths(PeakIndex);
            MohoAutoPickCCPDoubles(iloc, 5) = AmpRInterpRT(PeakIndex);
        else
            MohoAutoPickCCPDoubles(iloc,1:4:5) = NaN;
        end
        
        
        if max(AmpRInterpG) > params.MinAmplitude
            PeakIndex = find(AmpRInterpG == max(AmpRInterpG));
            MohoAutoPickCCPDoubles(iloc, 6) = SearchDepths(PeakIndex);
            MohoAutoPickCCPDoubles(iloc, 7) = AmpRInterpG(PeakIndex);
        else
            MohoAutoPickCCPDoubles(iloc,6:7) = NaN;
        end
        
    end
end

% Cull out nans and 0's
for iloc=NLateralPoints:-1:1
    if isequal(MohoAutoPickCCPDoubles(iloc,1),0) || isnan(MohoAutoPickCCPDoubles(iloc,1))
        MohoAutoPickCCPDoubles(iloc,:) = [];
    end
end


% Output
assignin('base','MohoAutoPickCCPDoubles',MohoAutoPickCCPDoubles);
assignin('base','MohoAutoPickStrings',MohoAutoPickStrings);
MohoAutoPickCell{CurrentSubsetIndex,1} = MohoAutoPickStrings;
MohoAutoPickCell{CurrentSubsetIndex,3} = MohoAutoPickCCPDoubles;
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
save([ProjectDirectory ProjectFile],'MohoAutoPickCCPDoubles','MohoAutoPickStrings','MohoAutoPickCell','-append');

PlotHandles = findobj('Tag','moho_auto_pick_ccp_plot_m');
ExportHandles = findobj('Tag','moho_auto_pick_ccp_export_m');

% turn on export and plot options
set(ExportHandles,'Enable','on');
set(PlotHandles,'Enable','on');

close(WaitGui)


%--------------------------------------------------------------------------
% plot_ri_moho_callback
% Plots the auto-picked moho based on ray info in new figure window
%--------------------------------------------------------------------------
function plot_ri_moho_callback(cbo, eventdata, handles)
% Get project data
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
load([ProjectDirectory ProjectFile],'MohoAutoPickCell')
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
MohoAutoPickRIDoubles = MohoAutoPickCell{CurrentSubsetIndex,2};
load([ProjectDirectory ProjectFile],'FuncLabPreferences')

% Get information about the projection, map limits, and color table
NorthLat = str2double(FuncLabPreferences{13});
SouthLat = str2double(FuncLabPreferences{14});
WestLon = str2double(FuncLabPreferences{15});
EastLon = str2double(FuncLabPreferences{16});
CPTFile = FuncLabPreferences{19};
CPTFileFlip = FuncLabPreferences{20};
CoastPref = FuncLabPreferences{12};
% Set map projection
%--------------------------------------------------------------------------
MapProjection = FuncLabPreferences{10};

% Call another m file to do the actual plotting. Switch for whether or not
% the mapping toolbox is found
if license('test', 'MAP_Toolbox')
    fl_moho_auto_pick_MAP_Toolbox_view_scatter(...
        MohoAutoPickRIDoubles(:,1), MohoAutoPickRIDoubles(:,2), MohoAutoPickRIDoubles(:,4),...
        SouthLat, NorthLat, WestLon, EastLon,...
        CPTFile, CPTFileFlip,MapProjection,CoastPref,'Ray Info Moho');
else
    fl_moho_auto_pick_M_MAP_view_scatter(...
        MohoAutoPickRIDoubles(:,1), MohoAutoPickRIDoubles(:,2), MohoAutoPickRIDoubles(:,4),...
        SouthLat, NorthLat, WestLon, EastLon,...
        CPTFile, CPTFileFlip,MapProjection, 'Ray Info Moho');
end


%--------------------------------------------------------------------------
% plot_ccp_moho_callback
% Plots the auto-picked moho based on CCP in new figure window
%--------------------------------------------------------------------------
function plot_ccp_moho_callback(cbo, eventdata, handles)
% Get project data
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
load([ProjectDirectory ProjectFile],'MohoAutoPickCell')
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
MohoAutoPickCCPDoubles = MohoAutoPickCell{CurrentSubsetIndex,3};
load([ProjectDirectory ProjectFile],'FuncLabPreferences')

% Get information about the projection, map limits, and color table
NorthLat = str2double(FuncLabPreferences{13});
SouthLat = str2double(FuncLabPreferences{14});
WestLon = str2double(FuncLabPreferences{15});
EastLon = str2double(FuncLabPreferences{16});
CPTFile = FuncLabPreferences{19};
CPTFileFlip = FuncLabPreferences{20};
CoastPref = FuncLabPreferences{12};
% Set map projection
%--------------------------------------------------------------------------
MapProjection = FuncLabPreferences{10};

% Call another m file to do the actual plotting. Switch for whether or not
% the mapping toolbox is found
if license('test', 'MAP_Toolbox')
    fl_moho_auto_pick_MAP_Toolbox_view_scatter(...
        MohoAutoPickCCPDoubles(:,1), MohoAutoPickCCPDoubles(:,2), MohoAutoPickCCPDoubles(:,4),...
        SouthLat, NorthLat, WestLon, EastLon,...
        CPTFile, CPTFileFlip,MapProjection,CoastPref,'Ray Theory Moho');
else
    fl_moho_auto_pick_M_MAP_view_scatter(...
        MohoAutoPickCCPDoubles(:,1), MohoAutoPickCCPDoubles(:,2), MohoAutoPickCCPDoubles(:,4),...
        SouthLat, NorthLat, WestLon, EastLon,...
        CPTFile, CPTFileFlip,MapProjection,'Ray Theory Moho');
end
if license('test', 'MAP_Toolbox')
    fl_moho_auto_pick_MAP_Toolbox_view_scatter(...
        MohoAutoPickCCPDoubles(:,1), MohoAutoPickCCPDoubles(:,2), MohoAutoPickCCPDoubles(:,4),...
        SouthLat, NorthLat, WestLon, EastLon,...
        CPTFile, CPTFileFlip,MapProjection,CoastPref,'Gaussian Moho');
else
    fl_moho_auto_pick_M_MAP_view_scatter(...
        MohoAutoPickCCPDoubles(:,1), MohoAutoPickCCPDoubles(:,2), MohoAutoPickCCPDoubles(:,4),...
        SouthLat, NorthLat, WestLon, EastLon,...
        CPTFile, CPTFileFlip,MapProjection,'Gaussian Moho');
end

%--------------------------------------------------------------------------
% export_ri_moho_callback
% Exports the auto-picked moho based on ray info to text file
%--------------------------------------------------------------------------
function export_ri_moho_callback(cbo, eventdata, handles)
% Get filename from user
[filename, pathname] = uiputfile('RayInfoMoho.txt','Save Ray Info based Moho as...');

% Check if the user canceled
if isequal(pathname,0) || isequal(filename,0)
    disp('Canceled')
    return
end

WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
    'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'},'Color','White');
uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
    'String','Please wait, exporting ray info file to text.','BackgroundColor','white',...
    'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
drawnow;
H = guihandles(WaitGui);
guidata(WaitGui,H);


% Check if the directory exists. Make it and parents if necessary
if ~exist(pathname,'dir')
    [~, ~, ~] = mkdir(pathname);
end

% Get info from the project
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
load([ProjectDirectory ProjectFile],'MohoAutoPickCell')
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
MohoAutoPickRIDoubles = MohoAutoPickCell{CurrentSubsetIndex,2};

% Remove nans from data
for idx=size(MohoAutoPickRIDoubles,1):-1:1
    if isnan(MohoAutoPickRIDoubles(idx,1))
        MohoAutoPickRIDoubles(idx,:) = [];
    end
end

% Open the file to export to
fid = fopen(fullfile(pathname, filename),'w');
for idx=1:size(MohoAutoPickRIDoubles,1)
    fprintf(fid,'%f %f %f %f\n',MohoAutoPickRIDoubles(idx,1),MohoAutoPickRIDoubles(idx,2),MohoAutoPickRIDoubles(idx,4),MohoAutoPickRIDoubles(idx,5));
end
fclose(fid);
close(WaitGui)

%--------------------------------------------------------------------------
% export_ccp_moho_callback
% Exports the auto-picked moho based on CCP to text file
%--------------------------------------------------------------------------
function export_ccp_moho_callback(cbo, eventdata, handles)
% Get filename from user
[filename, pathname] = uiputfile('CCPMoho.txt','Save CCP based Moho as...');

% Check if the user canceled
if isequal(pathname,0) || isequal(filename,0)
    disp('Canceled')
    return
end

WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
    'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'},'Color','White');
uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
    'String','Please wait, exporting ccp Moho file to text.','BackgroundColor','white',...
    'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
drawnow;
H = guihandles(WaitGui);
guidata(WaitGui,H);

% Check if the directory exists. Make it and parents if necessary
if ~exist(pathname,'dir')
    [~, ~, ~] = mkdir(pathname);
end

% Get info from the project
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
load([ProjectDirectory ProjectFile],'MohoAutoPickCell')
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
MohoAutoPickCCPDoubles = MohoAutoPickCell{CurrentSubsetIndex,3};

% Open the file to export to. This still prints nan values, but we're going
% to let the user filter those out when they decide if they want to use RT
% or gaussian
fid = fopen(fullfile(pathname, filename),'w');
for idx=1:size(MohoAutoPickCCPDoubles,1)
    fprintf(fid,'%f %f %f %f %f %f\n',MohoAutoPickCCPDoubles(idx,1),MohoAutoPickCCPDoubles(idx,2),MohoAutoPickCCPDoubles(idx,4),MohoAutoPickCCPDoubles(idx,5),MohoAutoPickCCPDoubles(idx,6),MohoAutoPickCCPDoubles(idx,7));
end
fclose(fid);
close(WaitGui)

%--------------------------------------------------------------------------
% moho_auto_pick_help_callback
%
% This callback function closes the project and removes variables from the
% workspace.
%--------------------------------------------------------------------------
function moho_auto_pick_help_callback(cbo, eventdata, handles)

MainPos = [0 0 75 25];
ProcButtonPos = [30 2 25 3];

HelpDlg = dialog('Name','Moho auto pick help','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

str = ['This addon allows the user to run an auto-picker through CCP stacking volumes or ' ...
    'depth mapped receiver functions computed in FuncLab. Once the handful of parameters are ' ...
    'set and the addon is allowed to run, the plotting menu activates allowing visualiation. '...
    'Use the export menu to send the data to .txt files for use in other programs. '...
    'The possible Ray Info files are those created in either Compute > PRF to depth in which '...
    'case the default is ProjectDirectory/DepthTraces/DepthTracesRayInfo.mat or from the CCPV2 '...
    'in which case the mat file is CCPV2/CCPV2.mat. The CCP file is by default CCPV2/CCPV2_Volume.mat'];
    
HelpText = uicontrol('Parent',HelpDlg,'Style','Edit','String',str,'Units','Characters',...
    'Position',[5 7 65 16],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left',...
    'Max',100,'Min',1);

OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','Ok','Units','Characters',...
    'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
    'Callback','close(gcf)');



%--------------------------------------------------------------------------
% close_moho_auto_pick_Callback
%
% This callback function closes the addon
%--------------------------------------------------------------------------
function close_moho_auto_pick_Callback(cbo,eventdata,handles)
close(gcf)

