function fl_log_gui (LogFile)
%FL_LOG_GUI Display log file
%   FL_LOG_GUI(LogFile) opens the log text file and displays the contents
%   in a figure window.  This text is not editable.

%   Author: Kevin C. Eagar
%   Date Created: 01/07/2008
%   Last Updated: 02/05/2008

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% GUI initiation
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Create the main dialog box
%--------------------------------------------------------------------------
LogGui = dialog ('Name','FuncLab Log File','Resize','off','NumberTitle','off','Units','characters','WindowStyle','modal',...
    'Position',[0 0 120 50],'CreateFcn',{@movegui_kce,'center'});
Logbox = uicontrol ('Parent',LogGui,'Style','listbox','Units','characters',...
    'Position',[1 4 118 45],'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',0.0225);
uicontrol ('Parent',LogGui,'Style','pushbutton','Units','characters','String','Ok',...
    'Position',[50 1 20 2.25],'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',0.4,'Callback','close(gcf)');
fid = fopen(LogFile,'r');
if (fid == -1) 
  error('Cannot open file')
end
Count=1;
while 1
     tline = fgetl(fid);
     if ~ischar(tline); break; end
     strings{Count} = tline;
     Count = Count + 1;
end
fclose(fid);
set(Logbox,'String',strings);