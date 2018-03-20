function varargout = fl_add_data_gui(ProjectDirectory,ProjectFile)
%FL_ADD_DATA_GUI Open GUI to add data
%   FL_ADD_DATA_GUI(ProjectDirectory,ProjectFile) starts the GUI to add new
%   data directories to the existing project.

%   Author: Kevin C. Eagar
%   Date Created: 01/31/2008
%   Last Updated: 04/30/2011

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% GUI initiation
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Setup dimensions of the GUI
%--------------------------------------------------------------------------
NumData = 20;
AddPos = [0 0 150 55];
AddButtonPos = [0 .75 30 2.5];  %04/30/2011: DECREASED PUSHBUTTON HEIGHT FROM 4 TO 2.5 AND MOVED DOWN FROM 2 TO 0.75
AddTitlePos = [0 52.5 AddPos(3) 2];   %04/30/2011: PUSHED TITLE UP FROM 51 TO 52.5
AddProjTextPos = [0 50 AddPos(3) 1.5];  %04/30/2011: PUSHED PROJECT DIRECTORY UP FROM 47 TO 50
AddDirTextPos = [5 48.5 AddPos(3)-20 1];  %04/30/2011: PUSHED MESSAGE UP FROM 45 TO 48.5
AddBrowsePos = [5 0 25 2];
AddPathPos = [AddBrowsePos(3)+6 0 AddPos(3)-AddBrowsePos(3)-8 2];   
AccentColor = [.6 0 0];
AccentColor2 = [1.0000 0.7961 0];

AddGui = dialog('Name','Add New Data','Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','normal',...
    'Position',AddPos,'CreateFcn',{@movegui_kce,'center'}); % 04/30/2011: CHANGED WINDOWSTYLE PROPERTY FROM MODAL TO NORMAL
uicontrol('Parent',AddGui,'Style','text','Units','characters','Tag','new_title_t','String','Add New Data to FuncLab Project',...
    'Position',AddTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',1,'FontWeight','bold',...
     'HorizontalAlignment','center');
InfoText = ['Current Project: ' ProjectDirectory];
uicontrol('Parent',AddGui,'Style','text','Units','characters','Tag','projdir_t','String',InfoText,...
    'Position',AddProjTextPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',1,'HorizontalAlignment','center');
uicontrol('Parent',AddGui,'Style','text','Units','characters','Tag','adddata_t','String',sprintf('Please select up to %d datasets to add to this new project.',NumData),...
    'Position',AddDirTextPos,'FontUnits','normalized','FontSize',1,'HorizontalAlignment','left');
for n = 1:NumData
    Range = AddPos(4)-10;   %04/30/2011: INCREASED RANGE BY SUBTRACTING 10 INSTEAD OF 20 TO ADD HEIGHT TO TEXT BOXES 
    Inc = Range/NumData;
    Height = Inc*0.75;
    YPos = AddDirTextPos(2) - (n*Inc);  %04/30/2011: CHANGED Y-REFERENCE POINT OF TEXT BOXES TO THE Y POSITION OF THE MESSAGE TEXT ABOVE IT
    AddBrowsePos(2) = YPos;
    AddPathPos(2) = YPos;
    AddBrowsePos(4) = Height;
    AddPathPos(4) = Height;
    uicontrol('Parent',AddGui,'Style','pushbutton','Units','characters','Tag',['new_browse' sprintf('%02.0f',n) '_pb'],'String','Browse',...
        'Position',AddBrowsePos,'FontUnits','normalized','Callback',{@browse_Callback});
    uicontrol('Parent',AddGui,'Style','edit','Units','characters','Tag',['new_dataset' sprintf('%02.0f',n) '_e'],...
        'Position',AddPathPos,'BackgroundColor',[1 1 1],'FontUnits','normalized','HorizontalAlignment','left');
end
AddButtonPos(1) = (AddPos(3)/4)-(AddButtonPos(3)/2);
uicontrol ('Parent',AddGui,'Style','pushbutton','Units','characters','Tag','new_start_pb','String','Add Data',...
    'Position',AddButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.5,'FontWeight','bold','Callback',{@add_Callback});   %04/30/2011: INCREASED PUSHBUTTON TEXT SIZE FROM 0.25 TO 0.5
AddButtonPos(1) = (AddPos(3)-AddPos(3)/4)-(AddButtonPos(3)/2);
uicontrol ('Parent',AddGui,'Style','pushbutton','Units','characters','Tag','exit02_pb','String','Cancel',...
    'Position',AddButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.5,'FontWeight','bold','Callback',{@close_Callback});   %04/30/2011: INCREASED PUSHBUTTON TEXT SIZE FROM 0.25 TO 0.5
handles = guihandles(AddGui);
handles.projectdir = ProjectDirectory;
handles.projectfile = ProjectFile;
guidata(AddGui,handles);
varargout{1} = handles;

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% Subfunction Callbacks
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% browse_Callback
%
% This callback function picks the dataset directories using a GUI to
% browse the directory structure.
%--------------------------------------------------------------------------
function browse_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
try
    DataDirectory = uigetdir_kce(pwd,'Select the Data Directory');
catch
    DataDirectory = uigetdir(pwd,'Select the Data Directory');
end
Name = get(gcbo,'Tag');
n = str2num(Name(11:12));
if DataDirectory ~= 0
    eval(['set(h.new_dataset' sprintf('%02.0f',n) '_e,''String'',DataDirectory)'])
end

%--------------------------------------------------------------------------
% add_Callback
%
% This callback function adds the new data to the project.
%--------------------------------------------------------------------------
function add_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
NumData = 20;
Trigger = 0;
for n = 1:NumData
    StrCheck = eval(['get(h.new_dataset' sprintf('%02.0f',n) '_e,''String'')']);
    if ~isempty(StrCheck)
        Trigger = 1;
    end
end
if Trigger == 0
    try
        errordlg_kce ('No new data directories added.'); beep
    catch
        errordlg ('No new data directories added.'); beep
    end
    Message = 'Cancelled';
    set(0,'userdata',Message);
    close(h.dialogbox)
    return
end
WaitGui = dialog ('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
    'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
MessageText = uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
    'String','Please wait, loading in datasets and adding them to existing station and event tables',...
    'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
drawnow;
ProjectDirectory = h.projectdir;
ProjectFile = h.projectfile;
if ~strcmp(ProjectDirectory(end),filesep)
    ProjectDirectory = [ProjectDirectory filesep];
end
Count = 0;
for n = 1:NumData
    Command = ['~isempty(get(h.new_dataset' sprintf('%02.0f',n) '_e,''String''))'];
    if eval(Command)
        Count = Count + 1;
        Command = ['get(h.new_dataset' sprintf('%02.0f',n) '_e,''String'')'];
        DataDirectory = eval(Command);
        % 04/30/2011 INSERTED ERROR CHECKING STATEMENT FOR THE EXISTANCE OF
        % THE DATA DIRECTORY
        if exist(DataDirectory,'dir')
            DataDir{Count} = DataDirectory;
            DirName = strread(DataDirectory,'%s','delimiter',filesep);
            DirName = DirName{end};
            if ~exist([ProjectDirectory 'RAWDATA' filesep DirName],'dir')
                copyfile(DataDirectory,[ProjectDirectory 'RAWDATA' filesep DirName])
                NewNames{Count} = DirName;
                [RecordMetadataStrings,RecordMetadataDoubles] = fl_add_new_data(ProjectDirectory,ProjectFile,DirName);
            else
                if Count > 1
                    display(['Directory ' DirName ' already exists in the project directory.']) % 04/30/2011 FIXED AN ERROR IN OUTPUTTING THE CORRECT NAME OF THE DIRECTORY
                    display('Cannot continue adding data, but will allow setup of previous directories.')
                    DataDir(Count) = [];
                    break
                else
                    display(['Directory ' DirName ' already exists in the project directory.  Cannot continue adding data.']) % 04/30/2011 FIXED AN ERROR IN OUTPUTTING THE CORRECT NAME OF THE DIRECTORY
                    close(WaitGui)  % 04/30/2011 ADDED A CLOSE COMMAND FOR THE WAIT WINDOW
                    return
                end
            end
        else
            display(['Directory ' DataDirectory ' does not exists and will not be imported.'])
        end
    end
end
set(MessageText,'String','Please wait, updating dataset statistics');
drawnow
% 04/30/2011 ADDED TIMING OF DATASET INFO CALCULATION
tic
fl_datainfo(ProjectDirectory,ProjectFile,RecordMetadataStrings,RecordMetadataDoubles)
t_temp = toc;
disp(['Update datainfo took ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).']);
LogFile = [ProjectDirectory 'Logfile.txt'];
CTime = clock;
NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - Add Data to FuncLab Project',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6));
for n = 1:length(DataDir)
    NewLog{n*2} = sprintf('     %.0f. Moved Data Directory: %s to %s',n*2-1,DataDir{n},[ProjectDirectory 'RAWDATA']);
    NewLog{n*2+1} = sprintf('     %.0f. Imported Data To Station and Event Tables: %s',n*2,[ProjectDirectory 'RAWDATA/' NewNames{n}]);
end
fl_edit_logfile(LogFile,NewLog)
Message = ['Message: Added new data directories to project.'];
set(0,'userdata',Message);
SetManagementCell = evalin('base','SetManagementCell');
SetManagementCell{1,2} = RecordMetadataStrings;
SetManagementCell{1,3} = RecordMetadataDoubles;
assignin('base','SetManagementCell',SetManagementCell);
assignin('base','RecordMetadataStrings',RecordMetadataStrings);
assignin('base','RecordMetadataDoubles',RecordMetadataDoubles);
close(WaitGui)
close(h.dialogbox)

%--------------------------------------------------------------------------
% close_Callback
%
% This callback function closes the parameter GUI without saving.
%--------------------------------------------------------------------------
function close_Callback(cbo,eventdata,handles)
h = guidata(gcbf);
Message = 'Cancelled';
set(0,'userdata',Message);
close(h.dialogbox)