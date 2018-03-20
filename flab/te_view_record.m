function [GuiHandles] = te_view_record(ProjectDirectory,Record,TimeMin,TimeMax,StatusValue,PatchTime,RFPos,RFNeg,NewTime,RFAmps,RFName)
%TE_VIEW_RECORD Plot 3-component seismograms plus receiver function
%   TE_VIEW_RECORD(ProjectDirectory,Record,TimeMin,TimeMax,StatusValue,
%   PatchTime,RFPos,RFNeg,NewTime,RFAmps,RFName) plots the vertical,
%   radial, and transverse component seismograms, plus the radial or
%   transverse receiver functions for the record.

%   Author: Kevin C. Eagar
%   Date Created: 10/30/2009
%   Last Updated: 05/14/2010

% Plot the seismograms
%--------------------------------------------------------------------------
H = figure ('Name',['Station: ' Record{2} ' Event: ' Record{3} ' - Seismograms'],'Units','characters','NumberTitle','off','WindowStyle','normal','MenuBar','figure',...
    'Position',[0 0 160 58],'Tag','dialogbox','Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'},'CloseRequestFcn',{@close_Callback});

s1 = axes('Parent',H,'Units','characters','Position',[32 41 123 10.5]);
[TempAmps,TIME] = fl_readseismograms([ProjectDirectory Record{1} 'z']);
line(TIME,TempAmps,'Parent',s1,'color','k');
set(s1,'Box','off','Units','normalized','Color',[1 1 1],'Xcolor',[1 1 1],'Ycolor',[.1 .1 .1],'TickDir','out','FontUnits','normalized','FontSize',0.1);
axis(s1,'tight');
xlim(s1,[TimeMin TimeMax]);
uicontrol('Parent',H,'Style','text','Units','characters','String','Vertical','Position',[1 46.75 22 1],'BackgroundColor',[1 1 1],'FontUnits','normalized','FontWeight','Bold','FontSize',1);

s2 = axes('Parent',H,'Units','characters','Position',[32 29 123 10.5]);
[TempAmps,TIME] = fl_readseismograms([ProjectDirectory Record{1} 'r']);
line(TIME,TempAmps,'Parent',s2,'color','k');
set(s2,'Box','off','Units','normalized','Color',[1 1 1],'Xcolor',[1 1 1],'Ycolor',[.1 .1 .1],'TickDir','out','FontUnits','normalized','FontSize',0.1);
axis(s2,'tight');
xlim(s2,[TimeMin TimeMax]);
uicontrol('Parent',H,'Style','text','Units','characters','String','Radial','Position',[1 34.75 22 1],'BackgroundColor',[1 1 1],'FontUnits','normalized','FontWeight','Bold','FontSize',1);

s3 = axes('Parent',H,'Units','characters','Position',[32 17 123 10.5]);
[TempAmps,TIME] = fl_readseismograms([ProjectDirectory Record{1} 't']);
line(TIME,TempAmps,'Parent',s3,'color','k');
set(s3,'Box','off','Units','normalized','Color',[1 1 1],'Xcolor',[1 1 1],'Ycolor',[.1 .1 .1],'TickDir','out','FontUnits','normalized','FontSize',0.1);
axis(s3,'tight');
xlim(s3,[TimeMin TimeMax]);
uicontrol('Parent',H,'Style','text','Units','characters','String','Transverse','Position',[1 22.75 22 1],'BackgroundColor',[1 1 1],'FontUnits','normalized','FontWeight','Bold','FontSize',1);

s4 = axes('Parent',H,'Units','characters','Position',[32 5 123 10.5]);
patch(PatchTime,RFPos,[0 0 0],'Parent',s4,'EdgeColor','none')
patch(PatchTime,RFNeg,[.4 .4 .4],'Parent',s4,'EdgeColor','none')
line(NewTime,RFAmps,'Parent',s4,'color','k');
set(s4,'Box','off','Units','normalized','Color',[1 1 1],'Xcolor',[.1 .1 .1],'Ycolor',[.1 .1 .1],'TickDir','out','FontUnits','normalized','FontSize',0.1);
axis(s4,'tight');
xlim(s4,[TimeMin TimeMax]);
uicontrol('Parent',H,'Style','text','Units','characters','String',RFName,'Position',[1 10.75 22 1],'BackgroundColor',[1 1 1],'FontUnits','normalized','FontWeight','Bold','FontSize',1);
uicontrol('Parent',H,'Style','text','Units','characters','String','Time (s)','Position',[32 1 123 1],'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',1);

uicontrol('Parent',H,'Style','text','Units','characters','HorizontalAlignment','left','String',...
    {['Mag: ' num2str(Record{19},'%.1f') ' mb'];['Dist: ' num2str(Record{20},'%.2f') ' deg'];['Depth: ' num2str(Record{18},'%.2f') ' km']},...
    'Position',[0 53.5 20 4],'BackgroundColor',[1 1 1],'FontUnits','normalized','FontWeight','Bold','FontSize',0.25);

uicontrol('Parent',H,'Style','checkbox','Units','characters','String','Status ',...
    'Position',[33 55.5 12 2],'Tag','check','Value',StatusValue);
uicontrol('Parent',H,'Style','pushbutton','Units','characters','String','Close',...
    'Position',[50 55.5 12 2],'FontUnits','normalized','FontSize',0.5,'CallBack',{@close_Callback});

handles = guihandles(H);
guidata(H,handles);
GuiHandles = handles;

%--------------------------------------------------------------------------
% close_Callback
%
% This callback function closes the trace editing GUI without saving.
%--------------------------------------------------------------------------
function close_Callback (cbo,eventdata,handles)
GuiHandles = guidata(gcbf);
set(0,'userdata',get(GuiHandles.check,'Value'));
delete(gcf)