function hk_view_moveout_image(cbo,eventdata,handles)
%HK_VIEW_MOVEOUT_IMAGE Plot receiver functions vs. ray parameter
%    HK_VIEW_MOVEOUT_IMAGE plots the radial and transverse receiver
%    functions in the input ensemble table ordered by ray parameter.

%   Author: Kevin C. Eagar
%   Date Created: 12/07/2009
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
ColorMapChoice = FuncLabPreferences{19};


dz = 35;
VpVs = 1.75;
Vp = str2num(get(h.vp_e,'string'));
% VpVs = 1.83;

TimeMin = str2double(FuncLabPreferences{4});
TimeMax = str2double(FuncLabPreferences{5});
TimeInc = str2double(FuncLabPreferences{1});
ytics = TimeMin:TimeInc:TimeMin+(TimeInc*10);

% % Static corrections (arbitrary just to test for now)
% %--------------------------------------------------------------------------
% SC = 0;

RaypMin = str2double(get(h.raypmin_e,'string'));
RaypMax = str2double(get(h.raypmax_e,'string'));
RaypInc = str2double(FuncLabPreferences{2});
% RaypMin = 0.04;
% RaypMax = 0.08;
% RaypInc = 0.005;
rpaxis = RaypMin:RaypInc:RaypMax;

count = 0;
for n = 1:size(CurrentRecords,1)
    if CurrentRecords{n,5} == 1
        count = count + 1;
        Rayp(count) = CurrentRecords{n,21};
        if count > 1
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'eqr']);
            if length(TempAmps) ~= length(RRFAmps); RRFAmps(count,:) = interp1(TIME,TempAmps,RRFTime); else RRFAmps(count,:) = TempAmps; end
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'eqt']);
            if length(TempAmps) ~= length(TRFAmps); TRFAmps(count,:) = interp1(TIME,TempAmps,TRFTime); else TRFAmps(count,:) = TempAmps; end
        else
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'eqr']);
            RRFAmps(count,:) = TempAmps; RRFTime = TIME;
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'eqt']);
            TRFAmps(count,:) = TempAmps; TRFTime = TIME;
        end
    end
end

for n = 1:count
    CPamp = max(RRFAmps(n,:));
    RRFAmps(n,:) = RRFAmps(n,:) / CPamp;
    TRFAmps(n,:) = TRFAmps(n,:) / CPamp;
end

rpmatrix = repmat(rpaxis,length(RRFTime),1);
RRFTimeMatrix = repmat(RRFTime,1,length(rpaxis));

TRFTimeMatrix = repmat(TRFTime,1,length(rpaxis));
nramps = NaN * zeros(length(rpaxis),length(RRFTime));
ntamps = NaN * zeros(length(rpaxis),length(TRFTime));

NumberOfBins = length(rpaxis);
BinMaximum = RaypMax;
BinMinimum = RaypMin;
BinWidth = (BinMaximum - BinMinimum)/NumberOfBins;
BinInformation = Rayp;
BinTraceCount = [];
for n = 1:NumberOfBins
    BinLowCutoff = BinMinimum + ((n-1) * BinWidth);
    BinHighCutoff = BinMinimum + (n * BinWidth);
    BinIndices = find (BinInformation > BinLowCutoff & BinInformation <= BinHighCutoff);
    BinTraceCount(n) = length(BinIndices);
    count = 0;
    if BinTraceCount(n) > 0
        TempRRFAmps = RRFAmps(BinIndices,:)./max(RRFAmps(BinIndices,:),2);
        TempTRFAmps = TRFAmps(BinIndices,:)./max(RRFAmps(BinIndices,:),2);
        nramps(n,:) = mean(TempRRFAmps,1);
        ntamps(n,:) = mean(TempTRFAmps,1);
    end
end

Vs = Vp ./ VpVs;
R = 6371 - dz';

p = [0.035:0.001:0.085]; % ray parameters (s/km)
for n = 1:length(p)
    RayP = skm2srad (p(n));
    Tps(1,n) = cumsum((sqrt((R./Vs).^2 - RayP^2) - sqrt((R./Vp).^2 - RayP^2)) .* (dz./R));
    Tpp(1,n) = cumsum((sqrt((R./Vs).^2 - RayP^2) + sqrt((R./Vp).^2 - RayP^2)) .* (dz./R));
    Tss(1,n) = cumsum(sqrt((R./Vs).^2 - RayP^2) .* (2*dz./R));
end

fig = figure ('Name',[Station ' - Receiver Functions'],'Units','characters','NumberTitle','off','PaperPositionMode','auto',...
    'WindowStyle','normal','MenuBar','figure','Position',[0 0 180 58],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});
uicontrol('Parent',fig,'Style','text','Units','normalized','String',['Station: ' Station],...
    'Position',[.1 .94 .8 .05],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',14);

s1 = axes('Parent',fig,'Units','characters','Position',[10 5 65 42]);
set(fig,'RendererMode','manual','Renderer','painters');
p1 = pcolor(s1,rpmatrix-(RaypInc/2),RRFTimeMatrix,nramps');
set(p1,'LineStyle','none')

line(p,Tps,'Parent',s1,'Color','k','LineWidth',2);
line(p,Tpp,'Parent',s1,'Color','k','LineStyle',':','LineWidth',2);
line(p,Tss,'Parent',s1,'Color','k','LineStyle',':','LineWidth',2);
text(RaypMax+0.001,Tps(end),'Ps','Parent',s1)
text(RaypMax+0.001,Tpp(end),'PpPs','Parent',s1)
text(RaypMax+0.001,Tss(end),{'PsPs','+','PpSs'},'Parent',s1)

XInc=0.01;
XTics = RaypMin:XInc:RaypMax;
set(s1,'Box','on','Units','normalized','Color',[1 1 1],'YDir','reverse','TickDir','out','XTick',XTics,'clipping','off');
axis(s1,[RaypMin RaypMax TimeMin TimeMax])
set(s1,'Clipping','on')
if FuncLabPreferences{20} == false
    cmap = cptcmap(FuncLabPreferences{19});
else
    cmap = cptcmap(FuncLabPreferences{19},'flip',true);
end
colormap(cmap);

caxis([-0.1 0.1])
t1 = title(s1,'Radial RF');
t1pos = get(t1,'position');
set(t1,'position',[t1pos(1) t1pos(2)-5 t1pos(3)]);
ylabel(s1,'Time (sec)');
xlabel(s1,'Ray Parameter (sec/km)');

h1 = axes('Parent',fig,'Units','characters','Position',[10 47 65 6]);
bar(h1,rpaxis,BinTraceCount,'k')
set(h1,'Box','on','XAxisLocation','top','XTickLabel',[],'XTick',[],'TickDir','out')
axis(h1,[RaypMin RaypMax 0 max(BinTraceCount)])
ylabel(h1,'Trace Count')
yticks = get(h1,'YTick');
set(h1,'YTick',yticks(2:end),'Units','normalized')

s2 = axes('Parent',fig,'Units','characters','Position',[85 5 65 42]);
set(fig,'RendererMode','manual','Renderer','painters');
p2 = pcolor(s2,rpmatrix-(RaypInc/2),TRFTimeMatrix,ntamps');
set(p2,'LineStyle','none');
set(s2,'Box','on','Units','normalized','Color',[1 1 1],'YDir','reverse','TickDir','out','XTick',rpaxis,'YTick',ytics,'YAxisLocation','right');
axis(s2,[RaypMin RaypMax TimeMin TimeMax])
if FuncLabPreferences{20} == false
    cmap = cptcmap(FuncLabPreferences{19});
else
    cmap = cptcmap(FuncLabPreferences{19},'flip',true);
end
colormap(cmap);

caxis([-0.1 0.1])
t2 = title(s2,'Transverse RF');
t2pos = get(t2,'position');
set(t2,'position',[t2pos(1) t2pos(2)-5 t2pos(3)]);
xlabel(s2,'Ray Parameter (sec/km)');

h2 = axes('Parent',fig,'Units','characters','Position',[85 47 65 6]);
bar(h2,rpaxis,BinTraceCount,'k')
set(h2,'Box','on','XAxisLocation','top','XTickLabel',[],'XTick',[],'TickDir','out','YAxisLocation','right')
axis(h2,[RaypMin RaypMax 0 max(BinTraceCount)])
set(h2,'Clipping','on')
yticks = get(h2,'YTick');
set(h2,'YTick',yticks(2:end),'Units','normalized')

c1 = colorbar('peer',s2);
set(c1,'Parent',fig,'Units','characters','Position',[160 5 2.5 48])
set(get(c1,'YLabel'),'String','Amplitude');

% print(fig,'-depsc2',[ProjectDirectory 'FIGURES/HK/' strrep(Station,'-','_') '_rfmoveout.eps']);