function ccpv2(MainGui)
%CCPV2 Start the CCPV2 GUI
%   CCPV2 initiates the common conversion point stacking GUI.  The user is
%   able to run all of the FuncLab commands from this interface with a
%   push of a button.

%   RWP ran into significant problems with the original CCP code when
%   trying to stack ~20,000 receiver functions. The original code works on
%   a this idea of independent bins which are a new table. This version
%   sets up two independent tasks which can be done in either order:
%     1. Determine the CCP Geometry
%     2. Determine the raypaths
%   Once these are ready, then the CCP Stacking can be performed placing
%   the raypaths onto the geometry.

%   The problem in the original ccp may actually lie in the close callback 
%   where it clears the variables rather than simply closing the gui. The 
%   original CCP and GCCP should have "clear/close" and "save/close" buttons.

%   Author: Rob Porritt
%   Date Created: 04/29/2015
%   Last Updated: 04/29/2015

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


%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% GUI initiation
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Setup dimensions of the GUI
%--------------------------------------------------------------------------
MainPos = [0 0 75 16];
ParamTitlePos = [3 MainPos(4)-3 50 1.75];
ParamTextPos1 = [1 0 31 1.75];
ParamOptionPos1 = [32 0 7 1.75];
ParamTextPos2 = [41 0 30 1.75];
ParamOptionPos2 = [72 0 7 1.75];
ProcTitlePos = [80 MainPos(4)-2 50 1.25];
ProcButtonPos = [1 0 46 3];
CloseButtonPos = [49 3 20 3];

%--------------------------------------------------------------------------
% Create the main dialog box
%--------------------------------------------------------------------------
CCPGui = dialog('Name','CCP Stacking V2','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

% Check if the CCPV2 metadata is ready to stack
load([ProjectDirectory ProjectFile])
StackEnable = 'off';
if exist('CCPV2MetadataStrings','var')
    if exist(CCPV2MetadataStrings{1},'file')
        load(CCPV2MetadataStrings{1});
        if exist('CCPV2Geometry','var') && exist('CCPV2RayTraceParams','var') && exist('RayInfo','var')
             StackEnable = 'on';
        end
    end
end

%--------------------------------------------------------------------------
% CCP Top Menu Items (help dialog)
%--------------------------------------------------------------------------
MHelp = uimenu(CCPGui,'Label','Help');
uimenu(MHelp,'Label','Help','Tag','ccpv2_help_m','Enable','on','Callback',{@ccpv2_help_Callback}); % EXPORT PIERCING POINTS

%--------------------------------------------------------------------------
% CCP Parameters
%--------------------------------------------------------------------------
TextFontSize = 0.6; % ORIGINAL
EditFontSize = 0.5;
AccentColor = [.6 0 0];

% Big message as title
uicontrol ('Parent',CCPGui,'Style','text','Units','characters','Tag','title_t','String','CCP Stacking V2',...
    'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',.8,'HorizontalAlignment','left','BackgroundColor','white');

% Button to set the geometry - calls a gui that sets evenly sampled
% spherical cap. Would be ideal to update this with a more dynamic meshing
% routine which makes smaller elements in regions more densely sampled by
% data
ProcButtonPos(3) = 20;
ProcButtonPos(2) = 9;
ProcButtonPos(1) = 5;
uicontrol ('Parent',CCPGui,'Style','pushbutton','Units','characters','Tag','ccpv2_set_geometry','String','Set Geometry',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@ccpv2_set_geometry});

% Button to set the parameters to run depth mapping for ccp stacking
ProcButtonPos(2) = 9;
ProcButtonPos(1) = 27;
uicontrol ('Parent',CCPGui,'Style','pushbutton','Units','characters','Tag','ccpv2_raytrace','String','Ray Tracing',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@ccpv2_raytrace});

% Button does the CCP Stacking IF the geometry and ray info exist
ProcButtonPos(2) = 9;
ProcButtonPos(1) = 49;
uicontrol ('Parent',CCPGui,'Style','pushbutton','Units','characters','Tag','ccpv2_stacking_button','String','CCP Stacking',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Enable',StackEnable,...
    'Callback',{@ccpv2_stacking});

% Button to load RayInfo from a mat file
ProcButtonPos(2) = 5;
ProcButtonPos(1) = 27;
uicontrol ('Parent',CCPGui,'Style','pushbutton','Units','characters','Tag','ccpv2_load_rays','String','Load Ray Info',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@ccpv2_load_rays});

% Closes the gui
CloseButtonPos(2) = 2;
uicontrol ('Parent',CCPGui,'Style','pushbutton','Units','characters','Tag','ccpclose_b','String','Close',...
    'Position',CloseButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@closeccp_Callback});
handles = guihandles(CCPGui);
handles.MainGui = MainGui;
guidata(CCPGui,handles);


% Subfunction Callbacks
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% closeccp_Callback
%
% This callback function closes the project and removes variables from the
% workspace.
%--------------------------------------------------------------------------
function closeccp_Callback(cbo,eventdata,handles)
% if evalin('base','exist(''CCPV2MetadataStrings'',''var'')')
%     evalin('base','clear(''CCPV2MetadataStrings'',''CCPV2MetadataDoubles'')')
% end
close(gcf)

%--------------------------------------------------------------------------
% ccpv2_help_Callback
%
% This callback function displays a help message in a new window.
%--------------------------------------------------------------------------
function ccpv2_help_Callback(cbo, eventdata, handles)

MainPos = [0 0 75 25];
ProcButtonPos = [30 2 25 3];

HelpDlg = dialog('Name','CCP Stacking V2 Help','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

str1 = 'This addon allows a simplified method of CCP stacking. ';
str2 = 'The set geometry button and ray tracing buttons work independently ';
str3 = 'and the ccp stacking button becomes active once the geometry is set ';
str4 = 'and the rays have been traced. If you used the compute > PRF to depth ';
str5 = 'function, you can use Load Ray Info to load the DepthTraces/DepthTracesRayInfo.mat ';
str6 = 'rather than re-tracing the rays. ';
str7 = 'CCP Stacking outputs a mat file and a ';
str8 = 'text file containing ray hit counts, radial component CCP, tangential ';
str9 = 'component CCP, and both ray theory based and gaussian width based estimates. ';
str10 = 'Use the Visualizer addon to view the CCPV2 outputs.';

HelpText = uicontrol('Parent',HelpDlg,'Style','Text','String',[str1 str2 str3 str4 str5 str6 str7 str8 str9 str10],'Units','Characters',...
    'Position',[5 7 65 16],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','Ok','Units','Characters',...
    'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
    'Callback','close(gcbf)');

%--------------------------------------------------------------------------
% ccpv2_load_rays
%
% This callback function calls uigetfile to have the user select a mat file
% with a RayInfo{}. structure cell array. Appends this to the standard ccp
% mat files.
%--------------------------------------------------------------------------
function ccpv2_load_rays(cbo, eventdata, handles)
[FileName, PathName] = uigetfile('*.mat','Load a .mat file with RayInfo');

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

if isequal(FileName,0) || isequal(PathName,0)
    disp('Loading RayInfo canceled.')
else
   load([PathName FileName],'RayInfo')
   ProjectDirectory = evalin('base','ProjectDirectory');
   %outputFile = fullfile(ProjectDirectory, 'CCPV2', 'CCPV2.mat');
   % Save the rays to the matrix
   
   % Check that we only have the right rays for this set
   if size(RayInfo,1) > size(SetManagementCell{CurrentSubsetIndex,1},1)
       idx = SetManagementCell{CurrentSubsetIndex,1};
       tmp = RayInfo(idx);
       RayInfo = tmp;
   elseif size(RayInfo,1) < size(SetManagementCell{CurrentSubsetIndex,1},1)
       disp('Warning, not all rays accounted for it chosen Ray Info file!')
       idx = SetManagementCell{CurrentSubsetIndex,1};
       tmp = RayInfo;
       for kdx=1:length(idx)
           if idx(kdx) <= size(RayInfo,1)
               tmp(kdx) = RayInfo(idx(kdx));
           end
       end
       for kdx=size(SetManagementCell{CurrentSubsetIndex,1},1):-1:length(RayInfo)
           tmp(kdx) = [];
       end
       RayInfo = ~isempty(tmp);
   end
   
   if CurrentSubsetIndex == 1
        outputFile = fullfile(ProjectDirectory, 'CCPV2', 'CCPV2.mat');
    else
        outputFile = fullfile(ProjectDirectory, 'CCPV2', SetName, 'CCPV2.mat');
    end
   
   save(outputFile,'RayInfo','-append');
   
   % check if geometry exists and if so turn on stacking
   load(outputFile)
   if exist('CCPV2Geometry','var')
       stackbuttonhdls = findobj('Tag','ccpv2_stacking_button');
       set(stackbuttonhdls,'Enable','on');
   end 
end




