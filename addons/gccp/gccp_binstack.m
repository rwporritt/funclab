function gccp_binstack(cbo,eventdata,handles)
%GCCP_BINSTACK Plots the GCCP stack
%   GCCP_BINSTACK is a callback function that plots the GCCP stack for the
%   selected bin in the FuncLab main window.

%   Author: Kevin C. Eagar
%   Date Created: 12/30/2010
%   Last Updated: 06/15/2011

% Get the handles of the FuncLab GUI
%--------------------------------------------------------------------------
h = guidata(gcbf);

ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');

% Make sure that you have selected the correct type of table
%--------------------------------------------------------------------------
SelectedIndex = get(h.MainGui.tables_ls,'Value');
TableList = get(h.MainGui.tables_ls,'String');
Table = TableList{SelectedIndex};
% 06/15/2011: REPLACED CALLING  OLD Ensemble WITH CALLING THE NEW CurrentRecords TABLE
List = get(h.MainGui.tablemenu_pu,'String');
Value = get(h.MainGui.tablemenu_pu,'Value');
TableType = List{Value};
if isempty(strmatch(TableType,'GCCP Tables'))
    disp(['Not the right table type: ' TableType])
    return
end

Record = get(h.MainGui.records_ls,'Value');
CurrentRecords = evalin('base','CurrentRecords');   
load([ProjectDirectory CurrentRecords{Record,1}]);

PositiveColor = [0 0 0];
NegativeColor = [.9 .9 .9];
TraceColor = [0 0 0];
TraceWidth = 1;
RFAmpCut = 0.4;

fig = dialog ('Name',[Table ' (' num2str(Record) ') - Radial Stack'],'NumberTitle','off','Units','characters','Resize','off','WindowStyle','normal',...
    'Position',[0 0 90 56],'PaperPosition',[2 1 4.5 9],'MenuBar','figure','Color',[1 1 1],'Visible','off','CreateFcn',{@movegui_kce,'center'});
ax = axes ('Units','normalized','Clipping','off','Box','on','Layer','top','TickDir','out','Position',[.2 .05 .65 .85]);

ValueIndices = find(~isnan(RRFBootMean));
if length(ValueIndices) ~= length(RRFBootMean)
    count = 0;
    for j = 1:length(ValueIndices)
        if ~exist('K')
            count = count + 1;
            K(count) = ValueIndices(j);
        elseif j == length(ValueIndices)
            if exist('K')
                YAxis = BootAxis(K); % 06/15/2011: REPLACED RRFBOOTAXIS WITH BOOTAXIS
                Confidence = [(RRFBootMean(K)+RRFBootSigma(K))' fliplr((RRFBootMean(K)-RRFBootSigma(K))')];
                ConAxis = [YAxis' fliplr(YAxis')];
                NewAMPS = RRFBootMean(K);
                NewCon = Confidence;
                NewSig = RRFBootSigma(K);
                PositiveIndices = find (NewAMPS - NewSig >= 0);
                NegativeIndices = find (NewAMPS + NewSig < 0);
                pos = zeros (length(NewAMPS),1);
                neg = zeros (length(NewAMPS),1);
                pos(PositiveIndices) = NewAMPS(PositiveIndices) - NewSig(PositiveIndices);
                neg(NegativeIndices) = NewAMPS(NegativeIndices) + NewSig(NegativeIndices);
                pos = [0; pos; 0];
                neg = [0; neg; 0];
                t = [YAxis(1); YAxis; YAxis(end)];
                patch (pos',t',PositiveColor,'EdgeColor','none')
                patch (neg',t',NegativeColor,'EdgeColor','none')
                patch (NewCon,ConAxis',[.7 .7 .7],'EdgeColor',[.7 .7 .7])
                line(NewAMPS,YAxis,'Color',TraceColor,'LineWidth',TraceWidth)
            end
            clear K
        else
            if ValueIndices(j+1) - ValueIndices(j) == 1
                count = count + 1;
                K(count) = ValueIndices(j);
            else
                count = 0;
                if exist('K')
                    YAxis = BootAxis(K); % 06/15/2011: REPLACED RRFBOOTAXIS WITH BOOTAXIS
                    Confidence = [(RRFBootMean(K)+RRFBootSigma(K))' fliplr((RRFBootMean(K)-RRFBootSigma(K))')];
                    ConAxis = [YAxis' fliplr(YAxis')];
                    NewAMPS = RRFBootMean(K);
                    NewCon = Confidence;
                    NewSig = RRFBootSigma(K);
                    PositiveIndices = find (NewAMPS - NewSig >= 0);
                    NegativeIndices = find (NewAMPS + NewSig < 0);
                    pos = zeros (length(NewAMPS),1);
                    neg = zeros (length(NewAMPS),1);
                    pos(PositiveIndices) = NewAMPS(PositiveIndices) - NewSig(PositiveIndices);
                    neg(NegativeIndices) = NewAMPS(NegativeIndices) + NewSig(NegativeIndices);
                    pos = [0; pos; 0];
                    neg = [0; neg; 0];
                    t = [YAxis(1); YAxis; YAxis(end)];
                    patch (pos',t',PositiveColor,'EdgeColor','none')
                    patch (neg',t',NegativeColor,'EdgeColor','none')
                    patch (NewCon ,ConAxis',[.7 .7 .7],'EdgeColor',[.7 .7 .7])
                    line(NewAMPS,YAxis,'Color',TraceColor,'LineWidth',TraceWidth)
                end
                clear K
            end
        end
    end
else
    YAxis = BootAxis(K); % 06/15/2011: REPLACED RRFBOOTAXIS WITH BOOTAXIS
    Confidence = [(RRFBootMean+RRFBootSigma)' fliplr((RRFBootMean-RRFBootSigma)')];
    ConAxis = [YAxis' fliplr(YAxis')];
    NewAMPS = RRFBootMean;
    NewCon = Confidence;
    NewSig = RRFBootSigma;
    PositiveIndices = find (NewAMPS - NewSig >= 0);
    NegativeIndices = find (NewAMPS + NewSig < 0);
    pos = zeros (length(NewAMPS),1);
    neg = zeros (length(NewAMPS),1);
    pos(PositiveIndices) = NewAMPS(PositiveIndices) - NewSig(PositiveIndices);
    neg(NegativeIndices) = NewAMPS(NegativeIndices) + NewSig(NegativeIndices);
    pos = [0; pos; 0];
    neg = [0; neg; 0];
    t = [YAxis(1); YAxis; YAxis(end)];
    patch (pos',t',PositiveColor,'EdgeColor','none')
    patch (neg',t',NegativeColor,'EdgeColor','none')
    patch (NewCon,ConAxis',[.7 .7 .7],'EdgeColor',[.7 .7 .7])
    line(NewAMPS,YAxis,'Color',TraceColor,'LineWidth',TraceWidth)
end

% Final axis touchups
%--------------------------------------------------------------------------
set(ax,'TickDir','out','XLim',[-RFAmpCut RFAmpCut],'YLim',[CurrentRecords{Record,7} CurrentRecords{Record,8}],'Xcolor',[.1 .1 .1],...
    'Position',[.2 .05 .65 .85],'XAxisLocation','top','Ycolor',[.1 .1 .1],'YDir','reverse','FontUnits','normalized','FontSize',0.021);  % 06/15/2011: REPLACED Ensemble.BeginDepth WITH CurrentRecords{Record,7} AND Ensemble.EndDepth WITH CurrentRecords{Record,8}
yl = ylabel(ax,'Depth (km)','Units','normalized','FontUnits','normalized','FontSize',0.021);
TitleText = ['GCCP Bin Centered at ' num2str(CurrentRecords{Record,14},'%02.2f') ' Lat., ' num2str(CurrentRecords{Record,15},'%03.2f') ' Lon.'];  % 06/15/2011: REPLACED Ensemble.BinLatitude WITH CurrentRecords{Record,14} AND Ensemble.BinLongitude WITH CurrentRecords{Record,15}
tl = title(ax,TitleText,'Units','normalized','FontUnits','normalized','FontSize',0.022,'FontWeight','bold');
pos = get(tl,'Position');
set(tl,'Position',[pos(1) 1.05 pos(3)]);
axis ([-RFAmpCut RFAmpCut CurrentRecords{Record,7} CurrentRecords{Record,8}]);  % 06/15/2011: REPLACED Ensemble.BeginDepth WITH CurrentRecords{Record,7} AND Ensemble.EndDepth WITH CurrentRecords{Record,8}
set(ax,'Units','normalized'); set(ax,'FontUnits','normalized');
set(yl,'Units','normalized'); set(yl,'FontUnits','normalized');
set(tl,'Units','normalized'); set(tl,'FontUnits','normalized');
set(fig,'Resize','on');
set(fig,'Visible','on');


% % Add depth histograms, depth pick and error bars
% %--------------------------------------------------------------------------
% CenterMethod = @median;
% SpreadMethod = @std;
% 
% HistColor = [0 1 0];
% 
% % set the x-axis to define the bin centers
% %--------------------------------------------------------------------------
% x410 = [379.5:2:440.5];
% x660 = [619.5:2:700.5];
% 
% Range410 = [380 440];
% Range660 = [620 700];
% YAxis = [0:2:800];
% Indices410 = intersect(find(YAxis >= Range410(1)),find(YAxis <= Range410(2)));
% Indices660 = intersect(find(YAxis >= Range660(1)),find(YAxis <= Range660(2)));
% max410 = max(RRFBootMean(Indices410)-RRFBootSigma(Indices410));
% max660 = max(RRFBootMean(Indices660)-RRFBootSigma(Indices660));
% 
% % Compute the average number of traces included in the stacks within the
% % 410 range. 
% %--------------------------------------------------------------------------
% avghits = ignoreNan(Ensemble.TraceCount(191:221),@mean,2);
% text(-0.3,410,sprintf('Avg. Hitcount = \n%0.1f',avghits))
% 
% % Plot the 410 depth pick distribution and mark the mean with a red line
% % and label it.
% %--------------------------------------------------------------------------
% nc = histc(Ensemble.P410sDepth,x410+0.5);
% nc = nc./max(nc).*max410;
% md = ignoreNan(Ensemble.P410sDepth,CenterMethod,2);
% sd = ignoreNan(Ensemble.P410sDepth,SpreadMethod,2);
% if sd < 3; sd = 3; end
% for n = 1:length(nc)
%     newy = [x410(n) x410(n) x410(n)+1 x410(n)+1 x410(n)];
%     newx = [0 nc(n) nc(n) 0 0];
%     patch(newx,newy,HistColor,'EdgeColor',HistColor,'FaceColor',HistColor);
% end
% hold on
% errorbar(-0.05,md,sd,'Color',[1 0 0],'Marker','.')
% text(0.15,md,sprintf('Depth = \n%0.1f +- %0.1f km',md,sd))
% 
% % Compute the average number of traces included in the stacks within the
% % 660 range.
% %--------------------------------------------------------------------------
% avghits = ignoreNan(Ensemble.TraceCount(311:351),@mean,2);
% text(-0.3,660,sprintf('Avg. Hitcount = \n%0.1f',avghits))
% 
% % Plot the 660 depth pick distribution and mark the mean with a red line
% % and label it.
% %--------------------------------------------------------------------------
% nc = histc(Ensemble.P660sDepth,x660+0.5);
% nc = nc./max(nc).*max660;
% md = ignoreNan(Ensemble.P660sDepth,CenterMethod,2);
% sd = ignoreNan(Ensemble.P660sDepth,SpreadMethod,2);
% if sd < 3; sd = 3; end
% for n = 1:length(nc)
%     newy = [x660(n) x660(n) x660(n)+1 x660(n)+1 x660(n)];
%     newx = [0 nc(n) nc(n) 0 0];
%     patch(newx,newy,HistColor,'EdgeColor',HistColor,'FaceColor',HistColor);
% end
% errorbar(-0.05,md,sd,'Color',[1 0 0],'Marker','.')
% text(0.15,md,sprintf('Depth = \n%0.1f +- %0.1f km',md,sd))
% hold off
% 
% ha = axes('Parent',fig,'Units','normalized','Position',[.7 .5 .2 .15],'FontSize',6);
% qqplot(Ensemble.P410sDepth);
% ha = axes('Parent',fig,'Units','normalized','Position',[.7 .075 .2 .15],'FontSize',6);
% qqplot(Ensemble.P660sDepth);
% 
% set(ax,'YLim',[300 800])