function fl_choose_subset(h)
%% FL_CHOOSE_SUBSET 
%   Funclab function to launch a new window for the user to select a set
%   and then make it active. The UI is just a window with a popup menu, a cancel
%   button, and a confirm button. Confirm button callback must check that
%   the selected station is not 'Base' which is the main project
%   
%
%   Author:  Robert W. Porritt
%   Created: May 14th, 2015

% Todo:
% Editing menu
%   Auto Trace edit all/selected -> check in/out. Expect it works the same
%   as manual, but need to double check
% Addons
%   H-k seemed to work, but rest need a thorough investigation
%   Check output of H-k. 
%   As many add ons seem to add their own sets of doubles and strings, they
%   may need a correlating set manager


%% Top level project info
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');

%% Prepare metadata
load([ProjectDirectory ProjectFile],'RecordMetadataDoubles','RecordMetadataStrings','SetManagementCell');

%% Prepare options for popup menu
nsets = size(SetManagementCell,1);
SubsetNames = SetManagementCell(1:nsets,5);


%% Gui
MainPos = [0 0 80 10];
ParamTitlePos = [3 MainPos(4)-3 50 1.75];
TextFontSize = 0.6; % ORIGINAL
EditFontSize = 0.5;
AccentColor = [.6 0 0];

%--------------------------------------------------------------------------
% Create the main dialog box
%--------------------------------------------------------------------------
MainSubsetGUI = dialog('Name','Choose a subset','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

setappdata(MainSubsetGUI,'IndexToChoose',CurrentSubsetIndex);

% Help menu
MHelp = uimenu(MainSubsetGUI,'Label','Help');
uimenu(MHelp,'Label','Help','Tag','subset_help_m','Enable','on','Callback',{@choose_subset_help_callback});

% Title
uicontrol ('Parent',MainSubsetGUI,'Style','text','Units','characters','Tag','title_t','String','Choose a subset',...
    'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',.8,'HorizontalAlignment','left','BackgroundColor','white');

% Simple text
ParamTextPos = [3 5 30 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','select_t','String','Select set to make active: ',...
    'Position',ParamTextPos,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');

% Popup selection
ParamOptionPos = [35 5 35 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Popupmenu','Units','Characters','Tag','select_pu','String',SubsetNames,'Value',CurrentSubsetIndex,...
    'Position',ParamOptionPos,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','v=get(gcbo,''Value'');setappdata(gcf,''IndexToChoose'',v);');

% Pushbutton for cancel
% Close/go buttons
CloseButtonPosition = [30 1 18 2];
uicontrol('Parent',MainSubsetGUI,'Style','Pushbutton','Units','Characters','Tag','cancel_choose_subset_pb','String','Cancel',...
    'Position',CloseButtonPosition,'FontUnits','normalized','FontSize',0.4,'ForegroundColor',AccentColor,'FontWeight','bold',...
    'Callback',{@cancel_choose_subset_Callback});

% Pushbutton for delete
ConfirmButtonPosition = [50 1 18 2];
uicontrol('Parent',MainSubsetGUI,'Style','Pushbutton','Units','Characters','Tag','confirm_subset_pb','String','Confirm',...
    'Position',ConfirmButtonPosition,'FontUnits','normalized','FontSize',0.4,'ForegroundColor',AccentColor,'FontWeight','bold',...
    'Callback',{@confirm_subset_Callback, h});


%% Callbacks

%--------------------------------------------------------------------------
% confirm_subset_callback
% Makes the chosen set active
%--------------------------------------------------------------------------
function confirm_subset_Callback(cbo, eventdata,h)
appdata = getappdata(gcbf);
assignin('base','CurrentSubsetIndex',appdata.IndexToChoose);
close(gcbf)
% Set the colors of the main window to help the user keep track of which
% set is active
SetManagementCell = evalin('base','SetManagementCell');
if appdata.IndexToChoose == 1
    AccentColor = [153 0 0] / 255;
    SetManagementCell{1,6} = [153 0 0];
    assignin('base','SetManagementCell',SetManagementCell);
else
    AccentColor = SetManagementCell{appdata.IndexToChoose, 6} / 255;
end
set(h.explorer_fm,'BackgroundColor',AccentColor);
set(h.project_t,'BackgroundColor',AccentColor);
set(h.tablesinfo_t,'BackgroundColor',AccentColor);
set(h.records_t,'BackgroundColor',AccentColor);
set(h.recordsinfo_t,'BackgroundColor',AccentColor);
set(h.info_t,'BackgroundColor',AccentColor);
set(h.message_t,'ForegroundColor',AccentColor);

ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
RecordMetadataDoubles = SetManagementCell{appdata.IndexToChoose, 3};
RecordMetadataStrings = SetManagementCell{appdata.IndexToChoose, 2};
save([ProjectDirectory ProjectFile], 'RecordMetadataDoubles','RecordMetadataStrings','-append');
ChosenSetName = SetManagementCell{appdata.IndexToChoose,5};
LogFile = [ProjectDirectory 'Logfile.txt'];
CTime = clock;
NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - Activated set %s',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6), ChosenSetName);
fl_edit_logfile(LogFile,NewLog)
set(h.message_t,'String',['Message: set ',ChosenSetName, ' now active'])

% Sets the main gui tables to just the subset currently active.
tables_Callback(h)


%--------------------------------------------------------------------------
% delete_subset_help_callback
% Throws up a little help gui
%--------------------------------------------------------------------------
function choose_subset_help_callback(cbo, eventdata)
MainPos = [0 0 60 20];
ProcButtonPos = [30 2 25 3];

HelpDlg = dialog('Name','Choose subset help','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

str = ['This feature is used to select an existing subset from the project to make active. ' ...
    'Existing functions within FuncLab will be directed to operate only on this set. ' ...
    'If you wish to make the full project active, choose "Base".'];
    
HelpText = uicontrol('Parent',HelpDlg,'Style','Text','String',str,'Units','Characters',...
    'Position',[2 5 60 14],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','Ok','Units','Characters',...
    'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
    'Callback','close(gcf)');


%--------------------------------------------------------------------------
% cancel_delete_subset_Callback
% Close without doing anything
%--------------------------------------------------------------------------
function cancel_choose_subset_Callback(cbo, eventdata)
close(gcbf);


%--------------------------------------------------------------------------
% tables_Callback
%
% This callback function controls the display of records in the middle
% listbox for the selected table in the "Tables" listbox.
% Specially modified for use in fl_choose_subset.m
%--------------------------------------------------------------------------
function tables_Callback(h)
set(h.records_ls,'String','');
set(h.records_ls,'Value',1)
% Which table (stations/events/etc... is active
Value = get(h.tablemenu_pu,'Value');
% Get metadata about the subset
SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
Tablemenu = SetManagementCell{CurrentSubsetIndex, 4};
assignin('base','Tablemenu',Tablemenu);
assignin('base','RecordMetadataDoubles',SetManagementCell{CurrentSubsetIndex,3});
assignin('base','RecordMetadataStrings',SetManagementCell{CurrentSubsetIndex,2});
% Available tables based on pre-processing
AvailableTables = cell(size(Tablemenu,1),1);
for idx=1:size(Tablemenu,1)
    AvailableTables{idx} = Tablemenu{idx};
end
% We're changing the subset, so returning the active table to "Stations"
set(h.tablemenu_pu,'Value',1);
set(h.tablemenu_pu,'String',AvailableTables);
% Get metadata for the subset
%MetadataStrings = SetManagementCell{CurrentSubsetIndex,2};
%MetadataDoubles = SetManagementCell{CurrentSubsetIndex,3};
if strcmp(Tablemenu{Value,2},'RecordMetadata')
    MetadataStrings = SetManagementCell{CurrentSubsetIndex,2};
    MetadataDoubles = SetManagementCell{CurrentSubsetIndex,3};
else
    MetadataCell = evalin('base',[Tablemenu{Value,2} 'Cell']);
    MetadataStrings = MetdataCell{CurrentSubsetIndex,1};
    MetadataDoubles = MetdataCell{CurrentSubsetIndex,2};
end
Tablemenu = evalin('base','Tablemenu');
% Repopulate the h.tables_ls to the new subset values
Tables = sort(unique(MetadataStrings(:,2)));
set(h.tables_ls,'String',Tables)
set(h.tables_ls,'Value',1);
% Match the entries to the currently active table to the metadata for this
% set
in = strmatch(Tables{1},MetadataStrings(:,Tablemenu{Value,3}),'exact');
CurrentRecords = [MetadataStrings(in,:) num2cell(MetadataDoubles(in,:))];
switch Tablemenu{Value,9}
    case 'string'
        [CurrentRecords,ind] = sortrows(CurrentRecords,Tablemenu{Value,4});
    case 'double'
        [CurrentRecords,ind] = sortrows(CurrentRecords,Tablemenu{Value,4});
        for n = 1:size(CurrentRecords,1)
            CurrentRecords{n,Tablemenu{Value,4}} = num2str(CurrentRecords{n,Tablemenu{Value,4}},'%.0f');
        end
end
CurrentIndices = in(ind);
assignin('base','CurrentRecords',CurrentRecords);
assignin('base','CurrentIndices',CurrentIndices);
RecordList = CurrentRecords(:,Tablemenu{Value,4});
Active = size(find(cat(1,CurrentRecords{:,5})),1);
set(h.records_ls,'String',RecordList)
set(h.records_ls,'Value',1);
set(h.recordsinfo_t,'String',{[Tablemenu{Value,7} num2str(length(RecordList))],['Active: ' num2str(Active)]})
records_Callback(h)

%--------------------------------------------------------------------------
% records_Callback
%
% This callback function controls the display of information, shown on the
% right, for selected record in the "Records" listbox.
% Specially modified for fl_choose_subset.
%--------------------------------------------------------------------------
function records_Callback(h)
Value = get(h.tablemenu_pu,'Value');
Tablemenu = evalin('base','Tablemenu');
CurrentRecords = evalin('base','CurrentRecords');
RecordIndex = get(h.records_ls,'Value');
Record = CurrentRecords(RecordIndex,:)';
eval(Tablemenu{Value,8})
Information = cell(length(RecordFields),1);
for n = 1:length(Record)
    if isnumeric(Record{n})
        Value = num2str(Record{n});
    else
        Value = Record{n};
    end
    Information{n} = [RecordFields{n} Value];
end
set(h.info_ls,'Value',1)
set(h.info_ls,'String',Information)







