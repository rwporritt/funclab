function hk_view_stacked_records(cbo,eventdata,handles)
%HK_VIEW_STACKED_RECORDS Plot station records stacked
%   HK_VIEW_STACKED_RECORDS plots the radial and transverse receiver
%   functions for the input event table.  Plots are shown on top of one
%   another.  The time-domain stack is shown in red, as well as predicted
%   arrivals for Ps, PpPs, and PpSs + PsPs from a simple crustal model.

%   Author: Kevin C. Eagar
%   Date Created: 01/14/2009
%   Last Updated: 05/17/2010

% Get the handles of the FuncLab GUI
%--------------------------------------------------------------------------
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');

% Get the Station Table to perform stacking
%--------------------------------------------------------------------------
Value = get(h.MainGui.tablemenu_pu,'Value');
CurrentRecords = evalin('base','CurrentRecords');
RecordMetadataStrings = evalin('base','RecordMetadataStrings');
RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
if Value ~= 1
    Tablemenu = evalin('base','Tablemenu');
    if strmatch('HkMetadata',Tablemenu{Value,2})
        RecordIndex = get(h.MainGui.records_ls,'Value');
        Station = CurrentRecords{RecordIndex,2};
        % Get all records for this selected station and redo
        % CurrentRecords and CurrentIndices
        in = strmatch(Station,RecordMetadataStrings(:,2),'exact');
        CurrentRecords = [RecordMetadataStrings(in,:) num2cell(RecordMetadataDoubles(in,:))];
    else
        TableIndex = get(h.MainGui.tables_ls,'Value');
        TableList = get(h.MainGui.tables_ls,'String');
        TableName = TableList{TableIndex};
        disp(['Not the right table: ' TableName])
        return
    end
else
    Station = CurrentRecords{1,2};
end
load([ProjectDirectory ProjectFile],'FuncLabPreferences')

dz = 35;
VpVs = 1.75;
Vp = str2double(get(h.vp_e,'string'));

TimeMin = str2double(FuncLabPreferences{4});
TimeMax = str2double(FuncLabPreferences{5});
TimeInc = str2double(FuncLabPreferences{1});

xlimits = [TimeMin TimeMax];
xtics = [TimeMin:TimeInc:TimeMin+(TimeInc*10)];

% Load in the seismograms from this table and gather into separate matrices
%--------------------------------------------------------------------------
count = 0;
for n = 1:size(CurrentRecords,1)
    if CurrentRecords{n,5} == 1
        count = count + 1;
        if count > 1
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'eqr']);
            if length(TempAmps) ~= length(RRFAmps); RRFAmps(count,:) = interp1(TIME,TempAmps,RRFTime); else RRFAmps(count,:) = TempAmps; end
        else
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'eqr']);
            RRFAmps(count,:) = TempAmps; RRFTime = TIME;
        end
    end
end
if count == 0; set(0,'userdata','Message: No active records in selected event.'); return; end

% Normalize the waveforms
%--------------------------------------------------------------------------
for n = 1:count
    RRFAmps(n,:) = RRFAmps(n,:) / max(abs(RRFAmps(n,:)));
end

% Compute the predicted arrivals of Ps, PpPs, and PpSs+PsPs from 1-layer
% crustal model (Vp = 6.5; Vs = 3.75; dz = 35;)
%--------------------------------------------------------------------------
R = 6371;
RayP = skm2srad(0.06);
Vs = Vp ./ VpVs;

VpVs1 = 1.7;
tps1 = (sqrt((R./(Vp./VpVs1)).^2 - RayP.^2) - sqrt((R./Vp).^2 - RayP.^2)) .* (dz./R);
tpp1 = (sqrt((R./(Vp./VpVs1)).^2 - RayP.^2) + sqrt((R./Vp).^2 - RayP.^2)) .* (dz./R);
tss1 = sqrt((R./(Vp./VpVs1)).^2 - RayP.^2) .* (2.*(dz./R));
VpVs2 = 1.8;
tps2 = (sqrt((R./(Vp./VpVs2)).^2 - RayP.^2) - sqrt((R./Vp).^2 - RayP.^2)) .* (dz./R);
tpp2 = (sqrt((R./(Vp./VpVs2)).^2 - RayP.^2) + sqrt((R./Vp).^2 - RayP.^2)) .* (dz./R);
tss2 = sqrt((R./(Vp./VpVs2)).^2 - RayP.^2) .* (2.*(dz./R));
VpVs3 = 1.9;
tps3 = (sqrt((R./(Vp./VpVs3)).^2 - RayP.^2) - sqrt((R./Vp).^2 - RayP.^2)) .* (dz./R);
tpp3 = (sqrt((R./(Vp./VpVs3)).^2 - RayP.^2) + sqrt((R./Vp).^2 - RayP.^2)) .* (dz./R);
tss3 = sqrt((R./(Vp./VpVs3)).^2 - RayP.^2) .* (2.*(dz./R));

aps = max(max(((sum(RRFAmps,1)./size(RRFAmps,1))+max(max(RRFAmps)))));
app = max(max(((sum(RRFAmps,1)./size(RRFAmps,1))+max(max(RRFAmps)))));
ass = max(max(((sum(RRFAmps,1)./size(RRFAmps,1))+max(max(RRFAmps)))));

fig = figure ('Units','characters','NumberTitle','off','WindowStyle','normal','MenuBar','figure',...
    'Position',[0 0 150 40],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});

% Radial Receiver Functions
%--------------------------------------------------------------------------
s4 = subplot('Position',[.075 .1 .8 .7]);
line(RRFTime,RRFAmps,'Color','k');
line(RRFTime,((sum(RRFAmps,1)./size(RRFAmps,1))+1),'Color','r','LineWidth',3);
line(tps1,aps,'LineStyle','none','Marker','o','MarkerFaceColor','b','MarkerEdgeColor','b','MarkerSize',7);
line(tpp1,app,'LineStyle','none','Marker','o','MarkerFaceColor','b','MarkerEdgeColor','b','MarkerSize',7);
line(tss1,ass,'LineStyle','none','Marker','o','MarkerFaceColor','b','MarkerEdgeColor','b','MarkerSize',7);
line(tps2,aps,'LineStyle','none','Marker','d','MarkerFaceColor','b','MarkerEdgeColor','b','MarkerSize',7);
line(tpp2,app,'LineStyle','none','Marker','d','MarkerFaceColor','b','MarkerEdgeColor','b','MarkerSize',7);
line(tss2,ass,'LineStyle','none','Marker','d','MarkerFaceColor','b','MarkerEdgeColor','b','MarkerSize',7);
line(tps3,aps,'LineStyle','none','Marker','s','MarkerFaceColor','b','MarkerEdgeColor','b','MarkerSize',7);
line(tpp3,app,'LineStyle','none','Marker','s','MarkerFaceColor','b','MarkerEdgeColor','b','MarkerSize',7);
line(tss3,ass,'LineStyle','none','Marker','s','MarkerFaceColor','b','MarkerEdgeColor','b','MarkerSize',7);
ylimits = [-1 1];
ytics = [-2:0.25:2];
set(s4,'Box','off','Units','normalized','Color',[1 1 1],'TickDir','out','FontSize',10,'YLim',ylimits,'YTick',ytics,'XLim',xlimits,'XTick',xtics);
set(s4,'YLim',[min(min(RRFAmps)) max(max(((sum(RRFAmps,1)./size(RRFAmps,1))+max(max(RRFAmps)))))]);
uicontrol('Parent',fig,'Style','text','Units','normalized','String','Rad. RFs','Position',[.88 .5 .1 .025],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',10);
xlabel(s4,'Time (sec)','FontName','FixedWidth','FontSize',10);
uicontrol('Parent',fig,'Style','text','Units','normalized','String',['Station: ' Station],...
    'Position',[.1 .9 .8 .05],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',14);
LegendLabels = {[num2str(dz,'%.0f') ' km crust'];
    ['Assumed Vp = ' num2str(Vp,'%.1f') ' km/s']
    'Vp/Vs for Symbols';
    ['Circle = ' num2str(VpVs1,'%.2f')];
    ['Diamond = ' num2str(VpVs2,'%.2f')];
    ['Square = ' num2str(VpVs3,'%.2f')];};
    
uicontrol('Parent',fig,'Style','text','Units','normalized','String',LegendLabels,...
    'Position',[.75 .7 .2 .24],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontUnits','normalized','FontSize',0.1);

set(fig,'Name',[Station ' - Stacked Records']);