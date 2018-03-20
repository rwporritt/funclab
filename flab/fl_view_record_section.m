function fl_view_record_section(ProjectDirectory,CurrentRecords,TableName,FuncLabPreferences)
%FL_VIEW_RECORD_SECTION Plot event record section
%   FL_VIEW_RECORD_SECTION(ProjectDirectory,CurrentRecords,TableName,
%   FuncLabPreferences) plots the vertical, radial, and transverse component
%   seismograms, plus the radial and transverse receiver functions for the
%   input event table.  Plots are shown for epicentral distance vs. time.

%   Author: Kevin C. Eagar
%   Date Created: 01/30/2008
%   Last Updated: 05/15/2010

TimeMin = str2double(FuncLabPreferences{4});
TimeMax = str2double(FuncLabPreferences{5});

DeltaMin = 180;
DeltaMax = 0;
count = 0;
for n = 1:size(CurrentRecords,1)
    if CurrentRecords{n,5} == 1
        count = count + 1;
        if CurrentRecords{n,20} > DeltaMax; DeltaMax = CurrentRecords{n,20}; end
        if CurrentRecords{n,20} < DeltaMin; DeltaMin = CurrentRecords{n,20}; end
        Degs(count) = CurrentRecords{n,20};
        if count > 1
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'z']);
            if length(TempAmps) ~= length(VertAmps); VertAmps(count,:) = interp1(TIME,TempAmps,VertTime); else VertAmps(count,:) = TempAmps; end
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'r']);
            if length(TempAmps) ~= length(RadAmps); RadAmps(count,:) = interp1(TIME,TempAmps,RadTime); else RadAmps(count,:) = TempAmps; end
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 't']);
            if length(TempAmps) ~= length(TransAmps); TransAmps(count,:) = interp1(TIME,TempAmps,TransTime); else TransAmps(count,:) = TempAmps; end
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'eqr']);
            if length(TempAmps) ~= length(RRFAmps); RRFAmps(count,:) = interp1(TIME,TempAmps,RRFTime); else RRFAmps(count,:) = TempAmps; end
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'eqt']);
            if length(TempAmps) ~= length(TRFAmps); TRFAmps(count,:) = interp1(TIME,TempAmps,TRFTime); else TRFAmps(count,:) = TempAmps; end
        else
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'z']);
            VertAmps(count,:) = TempAmps; VertTime = TIME;
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'r']);
            RadAmps(count,:) = TempAmps; RadTime = TIME;
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 't']);
            TransAmps(count,:) = TempAmps; TransTime = TIME;
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'eqr']);
            RRFAmps(count,:) = TempAmps; RRFTime = TIME;
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'eqt']);
            TRFAmps(count,:) = TempAmps; TRFTime = TIME;
        end
    end
end
if count == 0; set(0,'userdata','Message: No active records in selected event.'); return; end
if DeltaMax == 360; return; end
if count == 1
    YBuffer = 0.5;
    YInc = 0.2;
else
    YBuffer = (DeltaMax - DeltaMin) * .05;
    YInc = (DeltaMax - DeltaMin + 2*YBuffer)/10;
end
YTics = (DeltaMin - YBuffer):YInc:(DeltaMax + YBuffer);
if DeltaMax == 180; YInc = (DeltaMax - DeltaMin + YBuffer)/10; YTics = (DeltaMin - YBuffer):YInc:DeltaMax; end
if DeltaMin == 0; YInc = (DeltaMax - DeltaMin + YBuffer)/10; YTics = DeltaMin:YInc:(DeltaMax + YBuffer); end
if DeltaMin == 0 && DeltaMax == 180; YInc = (DeltaMax - DeltaMin)/10; YTics = DeltaMin:YInc:DeltaMax; end
Scale = (YTics(end) - YTics(1)) * 0.05;
for n = 1:count
        VertAmps(n,:) = Scale * VertAmps(n,:) / max(abs(VertAmps(n,:))) + Degs(n);
        RadAmps(n,:) = Scale * RadAmps(n,:) / max(abs(RadAmps(n,:))) + Degs(n);
        TransAmps(n,:) = Scale * TransAmps(n,:) / max(abs(TransAmps(n,:))) + Degs(n);
        RRFAmps(n,:) = Scale * RRFAmps(n,:) / max(abs(RRFAmps(n,:))) + Degs(n);
        TRFAmps(n,:) = Scale * TRFAmps(n,:) / max(abs(TRFAmps(n,:)))+ Degs(n);
end

fig = figure ('Name',[TableName ' - Record Section'],'Units','characters','NumberTitle','off','WindowStyle','normal','MenuBar','figure',...
    'Position',[0 0 200 58],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});

s5 = subplot('Position',[.8 .075 .175 .8]);
line(TRFTime,TRFAmps,'Color','k');
set(s5,'Box','off','Units','normalized','Color',[1 1 1],'Ycolor',[1 1 1],'TickDir','out','FontSize',10,'YLim',[YTics(1) YTics(end)],'XLim',[TimeMin TimeMax]);
xl5 = xlabel(s5,'Time (sec)','FontName','FixedWidth','FontSize',10);
t5 = uicontrol('Parent',fig,'Style','text','Units','normalized','String','Transverse RFs','Position',[.8 .905 .175 .025],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',12);
s4 = subplot('Position',[.615 .075 .175 .8]);
line(RRFTime,RRFAmps,'Color','k');
set(s4,'Box','off','Units','normalized','Color',[1 1 1],'Ycolor',[1 1 1],'TickDir','out','FontSize',10,'YLim',[YTics(1) YTics(end)],'XLim',[TimeMin TimeMax]);
xl4 = xlabel(s4,'Time (sec)','FontName','FixedWidth','FontSize',10);
t4 = uicontrol('Parent',fig,'Style','text','Units','normalized','String','Radial RFs','Position',[.615 .905 .175 .025],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',12);
s3 = subplot('Position',[.43 .075 .175 .8]);
line(TransTime,TransAmps,'Color','k');
set(s3,'Box','off','Units','normalized','Color',[1 1 1],'Ycolor',[1 1 1],'TickDir','out','FontSize',10,'YLim',[YTics(1) YTics(end)],'XLim',[TimeMin TimeMax]);
xl3 = xlabel(s3,'Time (sec)','FontName','FixedWidth','FontSize',10);
t3 = uicontrol('Parent',fig,'Style','text','Units','normalized','String','Transverse','Position',[.43 .905 .175 .025],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',12);
s2 = subplot('Position',[.245 .075 .175 .8]);
line(RadTime,RadAmps,'Color','k');
set(s2,'Box','off','Units','normalized','Color',[1 1 1],'Ycolor',[1 1 1],'TickDir','out','FontSize',10,'YLim',[YTics(1) YTics(end)],'XLim',[TimeMin TimeMax]);
xl2 = xlabel(s2,'Time (sec)','FontName','FixedWidth','FontSize',10);
t2 = uicontrol('Parent',fig,'Style','text','Units','normalized','String','Radial','Position',[.245 .905 .175 .025],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',12);
s1 = subplot('Position',[.06 .075 .175 .8]);
line(VertTime,VertAmps,'Color','k');
set(s1,'Box','off','Units','normalized','Color',[1 1 1],'TickDir','out','FontSize',10,'YLim',[YTics(1) YTics(end)],'YTick',round(100*YTics)/100,'XLim',[TimeMin TimeMax]);
xl1 = xlabel(s1,'Time (sec)','FontName','FixedWidth','FontSize',10);
yl = ylabel(s1,'\Delta \circ','FontName','FixedWidth','FontSize',14);
t1 = uicontrol('Parent',fig,'Style','text','Units','normalized','String','Vertical','Position',[.06 .905 .175 .025],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',12);

tt = uicontrol('Parent',fig,'Style','text','Units','normalized','String',['Record Section: ' TableName],...
    'Position',[.1 .95 .8 .025],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',14);

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
set(xl1,'Units','normalized'); set(xl1,'FontUnits','normalized');
set(xl2,'Units','normalized'); set(xl2,'FontUnits','normalized');
set(xl3,'Units','normalized'); set(xl3,'FontUnits','normalized');
set(xl4,'Units','normalized'); set(xl4,'FontUnits','normalized');
set(xl5,'Units','normalized'); set(xl5,'FontUnits','normalized');
set(yl,'Units','normalized'); set(yl,'FontUnits','normalized');
set(tt,'Units','normalized'); set(tt,'FontUnits','normalized');