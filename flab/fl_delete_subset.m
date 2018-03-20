function fl_delete_subset(h)
%% FL_DELETE_SUBSET 
%   Funclab function to launch a new window for the user to select a set
%   and then delete it. The UI is just a window with a popup menu, a cancel
%   button, and a confirm button. Confirm button callback must check that
%   the selected station is not 'Base' which is the main project
%   
%
%   Author:  Robert W. Porritt
%   Created: May 14th, 2015


%% Top level project info
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');

%% Prepare metadata
load([ProjectDirectory ProjectFile],'RecordMetadataDoubles','RecordMetadataStrings','SetManagementCell');

%% Prepare options for popup menu
nsets = size(SetManagementCell,1);
SubsetNames = SetManagementCell(2:nsets,5);


%% Gui
MainPos = [0 0 80 10];
ParamTitlePos = [3 MainPos(4)-3 50 1.75];
TextFontSize = 0.6; % ORIGINAL
EditFontSize = 0.5;
AccentColor = [.6 0 0];

%--------------------------------------------------------------------------
% Create the main dialog box
%--------------------------------------------------------------------------
MainSubsetGUI = dialog('Name','Delete a subset','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

setappdata(MainSubsetGUI,'IndexToDelete',2);

% Help menu
MHelp = uimenu(MainSubsetGUI,'Label','Help');
uimenu(MHelp,'Label','Help','Tag','subset_help_m','Enable','on','Callback',{@delete_subset_help_callback});

% Title
uicontrol ('Parent',MainSubsetGUI,'Style','text','Units','characters','Tag','title_t','String','Delete a subset',...
    'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',.8,'HorizontalAlignment','left','BackgroundColor','white');

% Simple text
ParamTextPos = [3 5 25 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Text','Units','Characters','Tag','select_t','String','Select set to delete: ',...
    'Position',ParamTextPos,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');

% Popup selection
ParamOptionPos = [30 5 40 1.75];
uicontrol('Parent',MainSubsetGUI,'Style','Popupmenu','Units','Characters','Tag','select_pu','String',SubsetNames,...
    'Position',ParamOptionPos,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor','white',...
    'Callback','v=get(gcbo,''Value'');setappdata(gcf,''IndexToDelete'',v+1);');

% Pushbutton for cancel
% Close/go buttons
CloseButtonPosition = [30 1 18 2];
uicontrol('Parent',MainSubsetGUI,'Style','Pushbutton','Units','Characters','Tag','cancel_delete_subset_pb','String','Cancel',...
    'Position',CloseButtonPosition,'FontUnits','normalized','FontSize',0.4,'ForegroundColor',AccentColor,'FontWeight','bold',...
    'Callback',{@cancel_delete_subset_Callback});

% Pushbutton for delete
DeleteButtonPosition = [50 1 18 2];
uicontrol('Parent',MainSubsetGUI,'Style','Pushbutton','Units','Characters','Tag','delete_subset_pb','String','Delete',...
    'Position',DeleteButtonPosition,'FontUnits','normalized','FontSize',0.4,'ForegroundColor',AccentColor,'FontWeight','bold',...
    'Callback',{@delete_subset_Callback, h});


%% Callbacks

%--------------------------------------------------------------------------
% delete_subset_callback
% Removes the set from the project.
%--------------------------------------------------------------------------
function delete_subset_Callback(cbo, eventdata,h)
appdata = getappdata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');

if appdata.IndexToDelete == 1
    disp('Error, cannot delete the main project!')
    close(gcbf)
    return
end

SetManagementCell = evalin('base','SetManagementCell');
nsets = size(SetManagementCell,1);
DeletedSetName = SetManagementCell{appdata.IndexToDelete,5};
tmp = cell(nsets-1, 6);
jdx = 0;
for idx=1:nsets
    if idx ~= appdata.IndexToDelete
        jdx = jdx+1;
        tmp{jdx,1} = SetManagementCell{idx,1};
        tmp{jdx,2} = SetManagementCell{idx,2};
        tmp{jdx,3} = SetManagementCell{idx,3};
        tmp{jdx,4} = SetManagementCell{idx,4};
        tmp{jdx,5} = SetManagementCell{idx,5};
        tmp{jdx,6} = SetManagementCell{idx,6};
    end
end
SetManagementCell = tmp;
assignin('base','SetManagementCell',SetManagementCell);
save([ProjectDirectory ProjectFile],'SetManagementCell','-append');
% Return to the default set just so we don't have to worry about what
% happens if we delete the current set
assignin('base','CurrentSubsetIndex',1);

if size(SetManagementCell,1) == 1
    set(h.delete_subset_m,'Enable','off');
end

% Fix datastats
load([ProjectDirectory ProjectFile],'Datastats');
tmp = cell(nsets-1, 1);
jdx = 0;
for idx=1:nsets
    if idx ~= appdata.IndexToDelete
        jdx = jdx+1;
        tmp{jdx,1} = Datastats{idx};
    end
end
Datastats = tmp;
save([ProjectDirectory ProjectFile],'Datastats','-append');

% If this set had been h-k stacked
ProjectVariables = whos('-file',[ProjectDirectory ProjectFile]);
for idx=1:size(ProjectVariables,1)
    if strcmp(ProjectVariables(idx).name,'HkMetadataCell')
        HkMetadataCell = evalin('base','HkMetadataCell');
        tmp = cell(nsets-1,2);
        jdx=0;
        for kdx=1:nsets
            if kdx~=appdata.IndexToDelete
                jdx=jdx+1;
                tmp{jdx,1} = HkMetadataCell{kdx,1};
                tmp{jdx,2} = HkMetadataCell{kdx,2};
            else
                tmp{jdx,1} = [];
                tmp{jdx,2} = [];
            end
        end
        HkMetadataCell = tmp;
        assignin('base','HkMetadataCell',HkMetadataCell);
        save([ProjectDirectory ProjectFile], 'HkMetadataCell','-append');
        break
    end
end

% If this set had been ccp stacked
ProjectVariables = whos('-file',[ProjectDirectory ProjectFile]);
for idx=1:size(ProjectVariables,1)
    if strcmp(ProjectVariables(idx).name,'CCPMetadataCell')
        CCPMetadataCell = evalin('base','CCPMetadataCell');
        tmp = cell(nsets-1,2);
        jdx=0;
        for kdx=1:nsets
            if kdx~=appdata.IndexToDelete
                jdx=jdx+1;
                tmp{jdx,1} = CCPMetadataCell{kdx,1};
                tmp{jdx,2} = CCPMetadataCell{kdx,2};
            else
                tmp{jdx,1} = [];
                tmp{jdx,2} = [];
            end
        end
        CCPMetadataCell = tmp;
        assignin('base','CCPMetadataCell',CCPMetadataCell);
        save([ProjectDirectory ProjectFile], 'CCPMetadataCell','-append');
        break
    end
end

% If this set had been gccp stacked
ProjectVariables = whos('-file',[ProjectDirectory ProjectFile]);
for idx=1:size(ProjectVariables,1)
    if strcmp(ProjectVariables(idx).name,'GCCPMetadataCell')
        GCCPMetadataCell = evalin('base','GCCPMetadataCell');
        tmp = cell(nsets-1,2);
        jdx=0;
        for kdx=1:nsets
            if kdx~=appdata.IndexToDelete
                jdx=jdx+1;
                tmp{jdx,1} = GCCPMetadataCell{kdx,1};
                tmp{jdx,2} = GCCPMetadataCell{kdx,2};
            else
                tmp{jdx,1} = [];
                tmp{jdx,2} = [];
            end
        end
        GCCPMetadataCell = tmp;
        assignin('base','GCCPMetadataCell',GCCPMetadataCell);
        save([ProjectDirectory ProjectFile], 'GCCPMetadataCell','-append');
        break
    end
end

% If this set had been ccpv2 stacked
ProjectVariables = whos('-file',[ProjectDirectory ProjectFile]);
for idx=1:size(ProjectVariables,1)
    if strcmp(ProjectVariables(idx).name,'CCPV2MetadataCell')
        CCPV2MetadataCell = evalin('base','CCPV2MetadataCell');
        tmp = cell(nsets-1,2);
        jdx=0;
        for kdx=1:nsets
            if kdx~=appdata.IndexToDelete
                jdx=jdx+1;
                tmp{jdx,1} = CCPVPMetadataCell{kdx,1};
            else
                tmp{jdx,1} = [];
            end
        end
        CCPV2MetadataCell = tmp;
        assignin('base','CCPV2MetadataCell',CCPV2MetadataCell);
        save([ProjectDirectory ProjectFile], 'CCPV2MetadataCell','-append');
        break
    end
end

% Early vision had this usage adding a new menu item for each set that is
% created. It makes much more sense, programatically, to instead launch a
% set choosing UI similar to this deleting UI. Therefore there's no need to
% adjust the menu
% Turn off this set's visible property
% nmenuitems = length(SubsetMenu.Children);
% offIDX = nmenuitems - appdata.IndexToDelete - 1;
% delete(SubsetMenu.Children(offIDX));

close(gcbf)

% Update the Log File
%--------------------------------------------------------------------------
LogFile = [ProjectDirectory 'Logfile.txt'];
CTime = clock;
NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - Deleted set %s',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6), DeletedSetName);
fl_edit_logfile(LogFile,NewLog)
set(h.message_t,'String',['Message: deleted set ',DeletedSetName])



%--------------------------------------------------------------------------
% delete_subset_help_callback
% Throws up a little help gui
%--------------------------------------------------------------------------
function delete_subset_help_callback(cbo, eventdata)
MainPos = [0 0 60 20];
ProcButtonPos = [30 2 25 3];

HelpDlg = dialog('Name','Delete subset help','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white');

str = ['This feature is used to remove an existing subset from the project. ' ...
    'The metadata of the selected set is removed, including data from any ' ...
    'addons you may have used. Files are not deleted, but the project variables '
    'will no longer reference them. You cannot remove ' ...
    'the base project.'];
    
HelpText = uicontrol('Parent',HelpDlg,'Style','Text','String',str,'Units','Characters',...
    'Position',[2 5 60 14],'BackgroundColor','white','FontUnits','Normalized','FontSize',0.07,'HorizontalAlignment','left');

OkButton = uicontrol('Parent',HelpDlg,'Style','Pushbutton','String','Ok','Units','Characters',...
    'Position',ProcButtonPos,'FontUnits','Normalized','FontSize',0.4,'ForegroundColor',[0.6 0 0],...
    'Callback','close(gcf)');




%--------------------------------------------------------------------------
% cancel_delete_subset_Callback
% Close without doing anything
%--------------------------------------------------------------------------
function cancel_delete_subset_Callback(cbo, eventdata)
close(gcbf);










