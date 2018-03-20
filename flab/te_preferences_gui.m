function varargout = te_preferences_gui(ProjectDirectory,ProjectFile,TraceEditPreferences)
%TE_PREFERENCES_GUI Starts the trace editing preferences GUI
%   TE_PREFERENCES_GUI(ProjectDirectory,ProjectFile,TraceEditPreferences)
%   initiates the trace editing preferences GUI so the user is able to view
%   and edit.

%   Author: Kevin C. Eagar
%   Date Created: 09/08/2009
%   Last Updated: 08/09/2010

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% GUI initiation
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Setup dimensions of the GUI
%--------------------------------------------------------------------------
PrefPos = [0 0 90 42];
DefaultButtonPos = [PrefPos(3)/2-15 PrefPos(4)-5 30 2.5];
ButtonPos = [0 1.5 30 2.5];
PrefTextPos = [5 PrefPos(4)-7 45 1.75];
PrefOptionPos = [55 PrefPos(4)-7 30 1.75];
AccentColor = [.6 0 0];

%--------------------------------------------------------------------------
% Create the main dialog box
%--------------------------------------------------------------------------
PrefGui = dialog('Name','Trace Editing Preferences','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
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
te_pref_fieldnames;

% Check if the number of preferences is too low - ie from an earlier
% version
if length(TraceEditPreferences) < 14
    te_default_prefs;
end

% Trace editing parameters
%--------------------------------------------------------------------------
PrefTextPos(2) = 35;
PrefOptionPos(2) = 35;
for n = 1:2
    PrefTextPos(2) = PrefTextPos(2)-2;
    PrefOptionPos(2) = PrefOptionPos(2)-2;
    uicontrol ('Parent',PrefGui,'Style','text','Units','characters','String',PrefTitles{n},'TooltipString',PrefDescript{n},...
        'Position',PrefTextPos,'BackgroundColor',BackColor,'FontUnits','normalized','FontSize',0.6,'HorizontalAlignment','left');
    switch n
        case 1
            List = {'Radial','Transverse','Non-RF Vertical','Non-RF Radial','Non-RF Transverse'};
        case 2
            VelocityModelPath = regexprep(which('funclab'),'funclab.m','VELMODELS/');
            List = dir([VelocityModelPath '*.vel']);
            List = sortrows({List.name}');
    end
    Choice = strmatch(TraceEditPreferences{n},List,'exact');
    uicontrol ('Parent',PrefGui,'Style','popupmenu','Units','characters','Tag',['e_' num2str(n,'%.0f')],'String',List,'Value',Choice,...
        'Position',PrefOptionPos,'BackgroundColor',[.7 .7 .7],'FontUnits','normalized','HorizontalAlignment','left');
end
for n = 3:14
    PrefTextPos(2) = PrefTextPos(2)-2;
    PrefOptionPos(2) = PrefOptionPos(2)-2;
    uicontrol('Parent',PrefGui,'Style','text','Units','characters','String',PrefTitles{n},'TooltipString',PrefDescript{n},...
        'Position',PrefTextPos,'BackgroundColor',BackColor,'FontUnits','normalized','FontSize',0.6,'HorizontalAlignment','left');
    uicontrol('Parent',PrefGui,'Style','edit','Units','characters','Tag',['e_' num2str(n,'%.0f')],'String',TraceEditPreferences{n},...
        'Position',PrefOptionPos,'BackgroundColor',[.7 .7 .7],'FontUnits','normalized','HorizontalAlignment','left');
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
% This callback function reverts to the default parameter settings.
%--------------------------------------------------------------------------
function defaults_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
Question = ['Are you sure you want to revert to the default parameters?'];
try
    Answer = questdlg_kce(Question,'Revert to defaults','Yes','No','Yes');
catch
    Answer = questdlg(Question,'Revert to defaults','Yes','No','Yes');
end
if strcmp(Answer,'No'); return; end
te_default_prefs;
te_pref_fieldnames;
set(h.e_1,'Value',1)
for n = 2:14
    eval(['set(h.e_' num2str(n,'%.0f') ',''String'',' TraceEditPreferences{n} ')']);
end

%--------------------------------------------------------------------------
% save_Callback
%
% This callback function assigns the parameter settings to the calling
% workspace if it is a new project, OR saves these to the Project file it
% exists.
%--------------------------------------------------------------------------
function save_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
te_pref_fieldnames;
for n = 1:2
    List = eval(['get(h.e_' num2str(n,'%.0f') ',''String'')']);
    Value = eval(['get(h.e_' num2str(n,'%.0f') ',''Value'')']);
    TraceEditPreferences{n} = List{Value};
end
for n = 3:14
    TraceEditPreferences{n} = eval(['get(h.e_' num2str(n,'%.0f') ',''String'')']);
end
ProjectDirectory = h.projdir;
ProjectFile = h.projfile;
if exist([ProjectDirectory ProjectFile],'file')
    save([ProjectDirectory ProjectFile],'TraceEditPreferences','-append');
    LogFile = [ProjectDirectory 'Logfile.txt'];
    CTime = clock;
    NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - Saved New Trace Editing Preferences',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6));
    fl_edit_logfile(LogFile,NewLog)
    Message = 'Message: Saved changes to trace editing preferences.';
    set(0,'userdata',Message);
else
    assignin('base','TraceEditPreferences',TraceEditPreferences);
end
close(gcf)

%--------------------------------------------------------------------------
% close_Callback
%
% This callback function closes the parameter GUI without saving.
%--------------------------------------------------------------------------
function close_Callback(cbo,eventdata,handles)
Message = 'Cancelled';
set(0,'userdata',Message);
close(gcf)