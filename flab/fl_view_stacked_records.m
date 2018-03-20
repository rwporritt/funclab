function fl_view_stacked_records(ProjectDirectory,CurrentRecords,TableName,FuncLabPreferences)
%FL_VIEW_STACKED_RECORDS Plot event record section
%   FL_VIEW_STACKED_RECORDS(ProjectDirectory,CurrentRecords,TableName,
%   FuncLabPreferences) plots the vertical, radial, and transverse component
%   seismograms, plus the radial and transverse receiver functions for the
%   input event table.  Plots are shown on top of one another.

%   Author: Kevin C. Eagar
%   Date Created: 01/14/2009
%   Last Updated: 05/15/2010

TimeMin = str2double(FuncLabPreferences{4});
TimeMax = str2double(FuncLabPreferences{5});

ylimits = [-1 1];
ytics = -1:0.25:1;
xlimits = [TimeMin TimeMax];
% ticinc = floor((TimeMax - TimeMin)/10);
% xtics = [TimeMin:ticinc:TimeMin+(ticinc*10)];

% Load in the seismograms from this table and gather into separate matrices
%--------------------------------------------------------------------------
count = 0;
for n = 1:size(CurrentRecords,1)
    if CurrentRecords{n,5} == 1
        count = count + 1;
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
        RayP(count) = skm2srad(CurrentRecords{n,21});
    end
end
if count == 0; set(0,'userdata','Message: No active records in selected event.'); return; end

% Normalize the waveforms
%--------------------------------------------------------------------------
for n = 1:count
    VertAmps(n,:) = VertAmps(n,:) / max(abs(VertAmps(n,:)));
    RadAmps(n,:) = RadAmps(n,:) / max(abs(RadAmps(n,:)));
    TransAmps(n,:) = TransAmps(n,:) / max(abs(TransAmps(n,:)));
    RRFAmps(n,:) = RRFAmps(n,:) / max(abs(RRFAmps(n,:)));
    TRFAmps(n,:) = TRFAmps(n,:) / max(abs(RRFAmps(n,:)));
end

% Compute the predicted arrivals of Ps, PpPs, and PpSs+PsPs from 1-layer
% crustal model (Vp = 6.5; Vs = 3.75; dz = 35;)
%--------------------------------------------------------------------------
R = 6371;
Vp = 6.5;
Vs = 3.75;
dz = 35;
tps = (sqrt((R./Vs).^2 - RayP.^2) - sqrt((R./Vp).^2 - RayP.^2)) .* (dz./R);
tpp = (sqrt((R./Vs).^2 - RayP.^2) + sqrt((R./Vp).^2 - RayP.^2)) .* (dz./R);
tss = sqrt((R./Vs).^2 - RayP.^2) .* (2.*dz./R);
arps = ones(length(tps),1);
arpp = ones(length(tpp),1);
arss = ones(length(tss),1);
atps = max(max(TRFAmps)) .* ones(length(tps),1);
atpp = max(max(TRFAmps)) .* ones(length(tpp),1);
atss = max(max(TRFAmps)) .* ones(length(tss),1);

fig = figure('Name',[TableName ' - Stacked Records'],'Units','characters','NumberTitle','off','WindowStyle','normal','MenuBar','figure',...
    'Position',[0 0 150 58],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});

s5 = subplot('Position',[.075 .06 .8 .15]);
line(TRFTime,TRFAmps,'Color','k');
line(TRFTime,sum(TRFAmps,1)./size(TRFAmps,1),'Color','r','LineWidth',3);
line(tps,atps,'LineStyle','none','Marker','o','MarkerFaceColor','b','MarkerEdgeColor','b','MarkerSize',4);
line(tpp,atpp,'LineStyle','none','Marker','o','MarkerFaceColor','b','MarkerEdgeColor','b','MarkerSize',4);
line(tss,atss,'LineStyle','none','Marker','o','MarkerFaceColor','b','MarkerEdgeColor','b','MarkerSize',4);
set(s5,'Box','off','Units','normalized','Color',[1 1 1],'TickDir','out','FontSize',10,'YLim',ylimits,'YTick',ytics,'XLim',xlimits);
set(s5,'YLim',[min(min(TRFAmps)) max(max(TRFAmps))]);
xl5 = xlabel(s5,'Time (sec)','FontName','FixedWidth','FontSize',10);
t5 = uicontrol('Parent',fig,'Style','text','Units','normalized','String','Trans. RFs','Position',[.88 .11 .1 .025],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',12);
s4 = subplot('Position',[.075 .245 .8 .15]);
line(RRFTime,RRFAmps,'Color','k');
line(RRFTime,sum(RRFAmps,1)./size(RRFAmps,1),'Color','r','LineWidth',3);
line(tps,arps,'LineStyle','none','Marker','o','MarkerFaceColor','b','MarkerEdgeColor','b','MarkerSize',4);
line(tpp,arpp,'LineStyle','none','Marker','o','MarkerFaceColor','b','MarkerEdgeColor','b','MarkerSize',4);
line(tss,arss,'LineStyle','none','Marker','o','MarkerFaceColor','b','MarkerEdgeColor','b','MarkerSize',4);
set(s4,'Box','off','Units','normalized','Color',[1 1 1],'TickDir','out','FontSize',10,'YLim',ylimits,'YTick',ytics,'XLim',xlimits);
t4 = uicontrol('Parent',fig,'Style','text','Units','normalized','String','Rad. RFs','Position',[.88 .285 .1 .025],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',12);
s3 = subplot('Position',[.075 .43 .8 .15]);
line(TransTime,TransAmps,'Color','k');
set(s3,'Box','off','Units','normalized','Color',[1 1 1],'TickDir','out','FontSize',10,'YLim',ylimits,'YTick',ytics,'XLim',xlimits);
t3 = uicontrol('Parent',fig,'Style','text','Units','normalized','String','Trans.','Position',[.88 .48 .1 .025],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',12);
s2 = subplot('Position',[.075 .615 .8 .15]);
line(RadTime,RadAmps,'Color','k');
set(s2,'Box','off','Units','normalized','Color',[1 1 1],'TickDir','out','FontSize',10,'YLim',[-1 1],'YTick',ytics,'XLim',xlimits);
t2 = uicontrol('Parent',fig,'Style','text','Units','normalized','String','Rad.','Position',[.88 .665 .1 .025],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',12);
s1 = subplot('Position',[.075 .8 .8 .15]);
line(VertTime,VertAmps,'Color','k');
set(s1,'Box','off','Units','normalized','Color',[1 1 1],'TickDir','out','FontSize',10,'YLim',ylimits,'YTick',ytics,'XLim',xlimits);
t1 = uicontrol('Parent',fig,'Style','text','Units','normalized','String','Vert.','Position',[.88 .85 .1 .025],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',12);

tt = uicontrol('Parent',fig,'Style','text','Units','normalized','String',TableName,...
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
set(xl5,'Units','normalized'); set(xl5,'FontUnits','normalized');
set(tt,'Units','normalized'); set(tt,'FontUnits','normalized');