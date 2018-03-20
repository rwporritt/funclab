function fl_view_record(ProjectDirectory,Record,FuncLabPreferences)
%FL_VIEW_RECORD Plot 3-component seismograms plus receiver functions
%   FL_VIEW_RECORD(ProjectDirectory,Record,FuncLabPreferences) plots the
%   vertical, radial, and transverse component seismograms, plus the radial
%   and transverse receiver functions for the record number in the input
%   ensemble table.

%   Author: Kevin C. Eagar
%   Date Created: 01/30/2008
%   Last Updated: 05/15/2010

TimeMin = str2double(FuncLabPreferences{4});
TimeMax = str2double(FuncLabPreferences{5});

fig = figure('Name',['Station: ' Record{2} ' Event: ' Record{3} ' - Seismograms'],'Units','characters','NumberTitle','off',...
    'WindowStyle','normal','MenuBar','figure','Position',[0 0 160 58],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});

s1 = axes('Parent',fig,'Units','characters','Position',[32 45 123 8.5]);
[TempAmps,Time] = fl_readseismograms([ProjectDirectory Record{1} 'z']);
line(Time,TempAmps,'Parent',s1,'color','k')
set(s1,'Box','off','Units','normalized','Color',[1 1 1],'Xcolor',[1 1 1],'Ycolor',[.1 .1 .1],'TickDir','out','FontUnits','normalized','FontSize',0.1);
axis(s1,'tight')
xlim(s1,[TimeMin TimeMax]);
t1 = uicontrol('Parent',fig,'Style','text','Units','characters','String','Vertical','Position',[1 49.25 22 1],'BackgroundColor',[1 1 1],'FontUnits','normalized','FontWeight','Bold','FontSize',1);

s2 = axes('Parent',fig,'Units','characters','Position',[32 35 123 8.5]);
[TempAmps,Time] = fl_readseismograms([ProjectDirectory Record{1} 'r']);
line(Time,TempAmps,'Parent',s2,'color','k')
set(s2,'Box','off','Units','normalized','Color',[1 1 1],'Xcolor',[1 1 1],'Ycolor',[.1 .1 .1],'TickDir','out','FontUnits','normalized','FontSize',0.1);
axis(s2,'tight')
xlim(s2,[TimeMin TimeMax]);
t2 = uicontrol('Parent',fig,'Style','text','Units','characters','String','Radial','Position',[1 39.25 22 1],'BackgroundColor',[1 1 1],'FontUnits','normalized','FontWeight','Bold','FontSize',1);

s3 = axes('Parent',fig,'Units','characters','Position',[32 25 123 8.5]);
[TempAmps,Time] = fl_readseismograms([ProjectDirectory Record{1} 't']);
line(Time,TempAmps,'Parent',s3,'color','k')
set(s3,'Box','off','Units','normalized','Color',[1 1 1],'Xcolor',[1 1 1],'Ycolor',[.1 .1 .1],'TickDir','out','FontUnits','normalized','FontSize',0.1);
axis(s3,'tight')
xlim(s3,[TimeMin TimeMax]);
t3 = uicontrol('Parent',fig,'Style','text','Units','characters','String','Transverse','Position',[1 29.25 22 1],'BackgroundColor',[1 1 1],'FontUnits','normalized','FontWeight','Bold','FontSize',1);

s4 = axes('Parent',fig,'Units','characters','Position',[32 15 123 8.5]);
[TempAmps,Time] = fl_readseismograms([ProjectDirectory Record{1} 'eqr']);
line(Time,TempAmps,'Parent',s4,'color','k')
set(s4,'Box','off','Units','normalized','Color',[1 1 1],'Xcolor',[1 1 1],'Ycolor',[.1 .1 .1],'TickDir','out','FontUnits','normalized','FontSize',0.1);
axis(s4,'tight')
xlim(s4,[TimeMin TimeMax]);
t4 = uicontrol('Parent',fig,'Style','text','Units','characters','String','Radial RF','Position',[1 19.25 22 1],'BackgroundColor',[1 1 1],'FontUnits','normalized','FontWeight','Bold','FontSize',1);

s5 = axes('Parent',fig,'Units','characters','Position',[32 5 123 8.5]);
[TempAmps,Time] = fl_readseismograms([ProjectDirectory Record{1} 'eqt']);
line(Time,TempAmps,'Parent',s5,'color','k')
set(s5,'Box','off','Units','normalized','Color',[1 1 1],'Xcolor',[.1 .1 .1],'Ycolor',[.1 .1 .1],'TickDir','out','FontUnits','normalized','FontSize',0.1);
axis(s5,'tight')
xlim(s5,[TimeMin TimeMax]);
t5 = uicontrol('Parent',fig,'Style','text','Units','characters','String','Transverse RF','Position',[1 9.25 22 1],'BackgroundColor',[1 1 1],'FontUnits','normalized','FontWeight','Bold','FontSize',1);
xl = uicontrol('Parent',fig,'Style','text','Units','characters','String','Time (s)','Position',[32 1 123 1],'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',1);
RecName = ['Station: ' Record{2} ' Event: ' Record{3}];

tt = uicontrol('Parent',fig,'Style','text','Units','characters','String',RecName,...
    'Position',[0 55.5 150 2],'BackgroundColor',[1 1 1],'FontUnits','normalized','FontWeight','Bold','FontSize',0.75);

set(s1,'Units','normalized'); set(s1,'FontUnits','normalized');
set(s2,'Units','normalized'); set(s2,'FontUnits','normalized');
set(s3,'Units','normalized'); set(s3,'FontUnits','normalized');
set(s4,'Units','normalized'); set(s4,'FontUnits','normalized');
set(s5,'Units','normalized'); set(s5,'FontUnits','normalized');
set(t1,'Units','normalized'); set(t1,'FontUnits','normalized');
set(t2,'Units','normalized'); set(t2,'FontUnits','normalized');
set(t3,'Units','normalized'); set(t3,'FontUnits','normalized');
set(t4,'Units','normalized'); set(t4,'FontUnits','normalized');
set(t5,'Units','normalized'); set(t5,'FontUnits','normalized');
set(xl,'Units','normalized'); set(xl,'FontUnits','normalized');
set(tt,'Units','normalized'); set(tt,'FontUnits','normalized');