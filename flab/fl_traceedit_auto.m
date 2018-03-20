function fl_traceedit_auto(varargin)
%FL_TRACEEDIT_AUTO Automated trace editing
%
%    FL_TRACEEDIT_AUTO (ProjectDirectory,ProjectFile,CurrentRecords,CurrentIndices,Table) runs the automated
%    trace editing algorithm on the input table.  This will reset the
%    status of the records before running.  The "FuncLabGenParam" input
%    specifies the parameters that control aspects of the automation.
%
%    FL_TRACEEDIT_AUTO (ProjectDirectory,ProjectFile, SetIndex) This will
%    run the auto trace editing algorithm over only the set indicated in
%    SetIndex
%
%    FL_TRACEEDIT_AUTO (ProjectDirectory,ProjectFile) runs the automated trace
%    editing algorithm on all the tables in the project.  This will reset
%    the status of the records before running.
%
%   UPDATE: Line 1 was calling just the input variables ProjectDirectory,
%   ProjectFile, CurrentRecords, CurrentIndices, and Table.  This was
%   replaced with varargin.
%
%    Author: Kevin C. Eagar
%    Date Created: 11/25/2007
%    Last Updated: 11/18/2011

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
Component = TraceEditPreferences{1};
switch TraceEditPreferences{1}
    case 'Radial'
        c_tail = 'eqr';
    case 'Transverse'
        c_tail = 'eqt';
end
AmpMax = str2double(TraceEditPreferences{10});
FitMin = str2double(TraceEditPreferences{11});

% Cycle through the tables for automated processing
%--------------------------------------------------------------------------
% 11/12/2011: SEPARATED PROCESSES FOR EITHER SINGLE TABLE TRACE EDITING OR
% PROJECT TRACE EDITING
drawnow
for n = 1:size(CurrentRecords,1)
    [AMPS,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} c_tail]);
    
    % Turn off "dead" traces, or those that have a maximum amplitude of
    % zero or less.
    %------------------------------------------------------------------
    if max(AMPS) == 0
        CurrentRecords{n,5} = 0;
        CurrentRecords{n,4} = 1;
        continue
    end
    
    % Turn off traces that have a "fit" (from iterdecon) to the data
    % below a minimum percentage.
    %----------------------------------------------------------------------
    switch Component
        case 'Radial'
            if CurrentRecords{n,11} < FitMin
                CurrentRecords{n,5} = 0;
                CurrentRecords{n,4} = 1;
                continue
            end
        case 'Transverse'
            if CurrentRecords{n,12} < FitMin
                CurrentRecords{n,5} = 0;
                CurrentRecords{n,4} = 1;
                continue
            end
    end
    
    % Turn off traces with a maximum absolute value amplitude, outside the
    % pulse width tolerance, greater than a percentage of the peak
    % positive amplitude of the P arrival.
    %----------------------------------------------------------------------
    PulseWidth = 1/sqrt(CurrentRecords{n,10})*2*sqrt(log(2));
    PeakRange = [find(TIME >= -PulseWidth,1) find(TIME >= PulseWidth,1)];
    if length(PeakRange) < 2
        CurrentRecords{n,5} = 0;
        CurrentRecords{n,4} = 1;
        continue
    end
    Peak = max(AMPS(PeakRange(1):PeakRange(2)));
    if max(abs(AMPS(PeakRange(2):end))) > (Peak * AmpMax)
        CurrentRecords{n,5} = 0;
        CurrentRecords{n,4} = 1;
        continue
    end
    
    % Marked the rest as "Turned-on" and "Edited"
    %------------------------------------------------------------------
    CurrentRecords{n,5} = 1;
    CurrentRecords{n,4} = 1;
    
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