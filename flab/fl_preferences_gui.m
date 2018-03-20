function varargout = fl_preferences_gui(ProjectDirectory,ProjectFile,FuncLabPreferences)
%FL_PREFERENCES_GUI Starts the Preference file GUI
%   FL_PREFERENCES_GUI(ProjectDirectory,ProjectFile,FuncLabPrefeters)
%   initiates the FuncLab preferences GUI so the user is able to view and
%   edit the FuncLab preferences used in stacking, and plotting.

%   Author: Kevin C. Eagar
%   Date Created: 01/04/2008
%   Last Updated: 08/10/2010
%   Edit: 05/09/2015. Rob Porritt
%     Adjusted options for mapping projection and palettes

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% GUI initiation
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Setup dimensions of the GUI
%--------------------------------------------------------------------------
PrefPos = [0 0 90 50];
DefaultButtonPos = [PrefPos(3)/2-15 PrefPos(4)-5 30 2.5];
ButtonPos = [0 1.5 30 2.5];
PrefTextPos = [5 PrefPos(4)-7 45 1.75];
PrefOptionPos = [55 PrefPos(4)-7 30 1.75];
AccentColor = [.6 0 0];

%--------------------------------------------------------------------------
% Create the main dialog box
%--------------------------------------------------------------------------
PrefGui = dialog ('Name','FuncLab Preferences','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
    'Color',[1 1 1],'Position',PrefPos,'CreateFcn',{@movegui_kce,'center'});
BackColor = get(PrefGui,'Color');
uicontrol ('Parent',PrefGui,'Style','pushbutton','Units','characters','Tag','defaults_pb','String','Revert to Defaults',...
    'Position',DefaultButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.4,'FontWeight','bold','Callback',{@defaults_Callback});
ButtonPos(1) = (PrefPos(3)/4)-(ButtonPos(3)/2);
uicontrol ('Parent',PrefGui,'Style','pushbutton','Units','characters','Tag','save_pb','String','Save',...
    'Position',ButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.4,'FontWeight','bold','Callback',{@save_Callback});
ButtonPos(1) = (PrefPos(3)-PrefPos(3)/4)-(ButtonPos(3)/2);
uicontrol ('Parent',PrefGui,'Style','pushbutton','Units','characters','Tag','exit_pb','String','Cancel',...
    'Position',ButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.4,'FontWeight','bold','Callback',{@close_Callback});
fl_pref_fieldnames;

% Check version. Note that RWP added 2 options for color and version
% tracking
%--------------------------------------------------------------------------
if size(FuncLabPreferences) == 18
    % Assume version 1.5.4
    FuncLabPreferences{19} = 'parula.cpt';
    FuncLabPreferences{20} = false;
    FuncLabPreferences{21} = '1.8.1';
end
if size(FuncLabPreferences) == 19
    % Assume version 1.5.4
    FuncLabPreferences{20} = false;
    FuncLabPreferences{21} = '1.8.1';
end
if size(FuncLabPreferences) == 20
    % Assume version 1.5.4
    FuncLabPreferences{21} = '1.8.1';
end


% Set available projections
if license('test', 'MAP_Toolbox')
%  Top block allows a limited set of projections
    ProjectionListNames = {'Balthasart Cylindrical','Behrmann Cylindrical','Bolshoi Sovietskii Atlas Mira','Braun Perspective',...
        'Cassini Cylindrical', 'Cassini Cylindrical - Standard','Central Cylindrical','Equal-Area Cylindrical','Equidistance Cylindrical',...
        'Gall Isographic','Gall Orthographic','Gall Stereographic','Lambert Conformal Conic','Mercator','Miller Cylindrical',...
        'Plate Carree','Transverse Mercator','Trystan Edwards Cylindrical','Wetch Cylindrical','Albers Equal-Area Conic',...
        'Albers Equal-Area - Standard','Equidistance Conic','Equidistant Conic - Standard','Lambert Conformal Conic','Lamert Conformal Conic - Standard',...
        'Murdoch I Conic','Murdoch III Minimum Error Conic','Aitoff','Breusing Harmonic Mean','Briesemeister','Lambert Azimuthal Equal-Area',...
        'Equidistant Azimuthal','Gnomonic','Hammer','Orthographic','Stereographic','Vertical Perspective Azimuthal','Wiechel'};
    ProjectionListIDs = {'balthsrt','behrmann','bsam','braun','cassini','cassinistd','ccylin','eqacylin','eqdcylin',...
        'giso','gortho','gstereo','lambert','mercator','miller','pcarree','tranmerc','trystan','wetch','eqaconic','eqaconicstd',...
        'eqdconic','eqdconicstd','lambert','lambertstd','murdoch1','murdoch3','aitoff','breusing','bries','eqaazim','eqdazim',...
        'gnomonic','hammer','ortho','stereo','vperspec','wiechel'};

% Below should allow all available projections, but was tested on system
% without mapping toolbox
%     ProjectionListNames = maps('namelist');
%     ProjectionListIDs = maps('idlist');
else
    ProjectionListNames = {'Stereographic','Orthographic','Azimuthal Equal-area','Azimuthal Equidistant','Gnomonic',...
        'Satellite','Albers Equal-Area Conic','Lambert Conformal Conic','Mercator','Miller Cylindrical','Equidistant Cylindrical',...
        'Transverse Mercator','Sinusoidal','Gall-Peters','Hammer-Aitoff','Mollweide','Robinson','UTM'};
    ProjectionListIDs = ProjectionListNames;
end


% FuncLab preferences
%--------------------------------------------------------------------------
for n = 1:7
    PrefTextPos(2) = PrefTextPos(2)-2;
    PrefOptionPos(2) = PrefOptionPos(2)-2;
    uicontrol('Parent',PrefGui,'Style','text','Units','characters','String',PrefTitles{n},'TooltipString',PrefDescript{n},...
        'Position',PrefTextPos,'BackgroundColor',BackColor,'FontUnits','normalized','FontSize',0.6,'HorizontalAlignment','left');
    uicontrol('Parent',PrefGui,'Style','edit','Units','characters','Tag',['e_' num2str(n,'%.0f')],'String',FuncLabPreferences{n},...
        'Position',PrefOptionPos,'BackgroundColor',[.7 .7 .7],'FontUnits','normalized','HorizontalAlignment','left');
end
for n = 8:12
    PrefTextPos(2) = PrefTextPos(2)-2;
    PrefOptionPos(2) = PrefOptionPos(2)-2;
    uicontrol ('Parent',PrefGui,'Style','text','Units','characters','String',PrefTitles{n},'TooltipString',PrefDescript{n},...
        'Position',PrefTextPos,'BackgroundColor',BackColor,'FontUnits','normalized','FontSize',0.6,'HorizontalAlignment','left');
    switch n
        case 8
            VelocityModelPath = regexprep(which('funclab'),'funclab.m','VELMODELS/');
            List = dir([VelocityModelPath '*.vel']);
            List = sortrows({List.name}');
        case 9
            List = {'All','Active','Inactive'};
        case 10
            List = ProjectionListNames;
        case 11
            List = ProjectionListNames;
        case 12
            List = {'Coastlines (low-res)','Coastlines (medium-res)','Coastlines (hi-res)','Topography (low-res)','Topography (medium-res)','Topography (hi-res)'};
    end
    Choice = strmatch(FuncLabPreferences{n},List,'exact');
    % 1.7.3 update - projection choosing actually now works, so to be
    % backwards compatible, we need to put in some error catching
    if n == 10 && isempty(Choice)
        if license('test', 'MAP_Toolbox')
            Choice = 14; % mercator
        else
            Choice = 9; % equidistant azimuthal
        end
    end
    if n == 11 && isempty(Choice)
        if license('test', 'MAP_Toolbox')
            Choice = 32; % mercator
        else
            Choice = 4; % azimuthal equidistant
        end
    end 
    uicontrol ('Parent',PrefGui,'Style','popupmenu','Units','characters','Tag',['e_' num2str(n,'%.0f')],'String',List,'Value',Choice,...
        'Position',PrefOptionPos,'BackgroundColor',[.7 .7 .7 ],'FontUnits','normalized','HorizontalAlignment','left');
end
for n = 13:18
    PrefTextPos(2) = PrefTextPos(2)-2;
    PrefOptionPos(2) = PrefOptionPos(2)-2;
    uicontrol('Parent',PrefGui,'Style','text','Units','characters','String',PrefTitles{n},'TooltipString',PrefDescript{n},...
        'Position',PrefTextPos,'BackgroundColor',BackColor,'FontUnits','normalized','FontSize',0.6,'HorizontalAlignment','left');
    uicontrol('Parent',PrefGui,'Style','edit','Units','characters','Tag',['e_' num2str(n,'%.0f')],'String',FuncLabPreferences{n},...
        'Position',PrefOptionPos,'BackgroundColor',[.7 .7 .7],'FontUnits','normalized','HorizontalAlignment','left');
end
for n=19:19
    PrefTextPos(2) = PrefTextPos(2)-2;
    PrefOptionPos(2) = PrefOptionPos(2)-2;
    PrefOptionPos(3) = PrefOptionPos(3) * 0.5;
    uicontrol ('Parent',PrefGui,'Style','text','Units','characters','String',PrefTitles{n},'TooltipString',PrefDescript{n},...
        'Position',PrefTextPos,'BackgroundColor',BackColor,'FontUnits','normalized','FontSize',0.6,'HorizontalAlignment','left');
    %List = {'Red to blue', 'Blue to red', 'Jet','Parula','Vel'};
    % Need to setup a list of color palettes based on availability in
    % cptfiles directory and add a button to reverse the sense
    cptmapdir = regexprep(which('funclab'),'funclab.m','cptcmap');
    cptmapdir = [cptmapdir,filesep,'cptfiles'];
    D = dir([cptmapdir filesep '*.cpt']);
    cptfiles = sortrows({D.name});
    List = cptfiles;
    if length(FuncLabPreferences) < 21
        FuncLabPreferences{19} = 'parula.cpt';
        FuncLabPreferences{20} = false; % true to reverse the color palette
        FuncLabPreferences{21} = '1.8.1';
    end
    Choice = strmatch(FuncLabPreferences{n},List,'exact');
    uicontrol ('Parent',PrefGui,'Style','popupmenu','Units','characters','Tag',['e_' num2str(n,'%.0f')],'String',List,'Value',Choice,...
        'Position',PrefOptionPos,'BackgroundColor',[.7 .7 .7 ],'FontUnits','normalized','HorizontalAlignment','left');
    PrefOptionPos(1) = PrefOptionPos(1) + PrefOptionPos(3) * 1.1;
    if FuncLabPreferences{20} == false
        checkvalue = 0;
    else
        checkvalue = 1;
    end
    checkhdls = uicontrol('Parent',PrefGui,'Style','checkbox','Units','Characters','Tag','reverse_colormap_checkbox','String','Reverse?','Position',PrefOptionPos,'BackgroundColor',[1 1 1], 'Value',checkvalue);        
end
for n=21:21
    PrefTextPos(2) = PrefTextPos(2)-2;
    PrefOptionPos(2) = PrefOptionPos(2)-2;
    %uicontrol ('Parent',PrefGui,'Style','text','Units','characters','String',PrefTitles{n},'TooltipString',PrefDescript{n},...
    %    'Position',PrefTextPos,'BackgroundColor',BackColor,'FontUnits','normalized','FontSize',0.6,'HorizontalAlignment','left');
    %List = {'Red to blue', 'Blue to red', 'Jet'};
    %Choice = strmatch(FuncLabPreferences{n},List,'exact');
    %uicontrol ('Parent',PrefGui,'Style','popupmenu','Units','characters','Tag',['e_' num2str(n,'%.0f')],'String',List,'Value',Choice,...
    %    'Position',PrefOptionPos,'BackgroundColor',[.7 .7 .7 ],'FontUnits','normalized','HorizontalAlignment','left');
end


handles = guihandles(PrefGui);
handles.projdir = ProjectDirectory;
handles.projfile = ProjectFile;
guidata(PrefGui,handles);
varargout{1} = handles;


%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% Subfunction Callbacks
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% defaults_Callback
%
% This callback function reverts to the default Prefeter settings.
%--------------------------------------------------------------------------
function defaults_Callback (cbo,eventdata,handles)
h = guidata(gcbf);
Question = ['Are you sure you want to revert to the default preferences?'];
try
    Answer = questdlg_kce(Question,'Revert to defaults','Yes','No','Yes');
catch
    Answer = questdlg(Question,'Revert to defaults','Yes','No','Yes');
end
if strcmp(Answer,'No'); return; end
%fl_default_prefs;
RecordMetadataDoubles = evalin('Base','RecordMetadataDoubles');
FuncLabPreferences = fl_default_prefs(RecordMetadataDoubles);
fl_pref_fieldnames;
for n = [1:6 13:18]
    eval(['set(h.e_' num2str(n,'%.0f') ',''String'',' FuncLabPreferences{n} ');']);
end
for n = 8:12
    eval(['set(h.e_' num2str(n,'%.0f') ',''Value'',1);'])
end
for n=19:19
    eval(['set(h.e_' num2str(n,'%.0f') ',''Value'',1);'])
end
for n=20:20
    tmphdls = findobj('Tag','reverse_colormap_checkbox');
    set(tmphdls,'Value',0);
end 
%for n=21:21
%    eval(['set(h.e_' num2str(n,'%.0f') ',''String'',' FuncLabPreferences{n} ');']);
%end

%--------------------------------------------------------------------------
% save_Callback
%
% This callback function assigns the Preferences settings to the calling
% workspace if it is a new project, OR saves these to the Project file it
% exists.
%--------------------------------------------------------------------------
function save_Callback (cbo,eventdata,handles)
h = guidata(gcbf);
fl_pref_fieldnames;
for n = [1:7 13:18]
    FuncLabPreferences{n} = eval(['get(h.e_' num2str(n,'%.0f') ',''String'')']);
end
for n = 8:12
    List = eval(['get(h.e_' num2str(n,'%.0f') ',''String'')']);
    Value = eval(['get(h.e_' num2str(n,'%.0f') ',''Value'')']);
    FuncLabPreferences{n} = List{Value};
end
for n = 19:19
    List = eval(['get(h.e_' num2str(n,'%.0f') ',''String'')']);
    Value = eval(['get(h.e_' num2str(n,'%.0f') ',''Value'')']);
    FuncLabPreferences{n} = List{Value};
end
for n = [20]
    tmphdls = findobj('Tag','reverse_colormap_checkbox');
    if tmphdls.Value == 0
        FuncLabPreferences{n} = false;
    else
        FuncLabPreferences{n} = true;
    end
end
for n = [21]
    FuncLabPreferences{n} = '1.8.1';
end

ProjectDirectory = h.projdir;
ProjectFile = h.projfile;
if exist([ProjectDirectory ProjectFile],'file')
    save([ProjectDirectory ProjectFile],'FuncLabPreferences','-append');
    LogFile = [ProjectDirectory 'Logfile.txt'];
    CTime = clock;
    NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - Saved New FuncLab Preferences',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6));
    fl_edit_logfile(LogFile,NewLog)
    Message = 'Message: Saved changes to FuncLab preferences.';
    set(0,'userdata',Message);
    assignin('base','FuncLabPreferences',FuncLabPreferences);
else
    assignin('base','FuncLabPreferences',FuncLabPreferences);
end
close(gcf)

%--------------------------------------------------------------------------
% close_Callback
%
% This callback function closes the Prefeter GUI without saving.
%--------------------------------------------------------------------------
function close_Callback (cbo,eventdata,handles)
Message = 'Cancelled';
set(0,'userdata',Message);
close(gcf)
