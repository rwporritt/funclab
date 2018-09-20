function fl_view_origintime_image(ProjectDirectory,CurrentRecords,TableName,FuncLabPreferences)
%FL_VIEW_ORIGINTIME_IMAGE Plot receiver functions vs. origin time
%   FL_VIEW_ORIGINTIME_IMAGE (ProjectDirectory,CurrentRecords,TableName,
%   FuncLabPreferences) plots the radial and transverse receiver functions
%   in the input ensemble table ordered by origin time.
%
%   Currently hard wired to display traces relative to Tohoku Oki
%   Author: Robert Porritt
%   Date Created: 06/12/2015
%   Last Updated: 06/12/2015

TimeMin = str2double(FuncLabPreferences{4});
TimeMax = str2double(FuncLabPreferences{5});
XInc = str2double(FuncLabPreferences{2});
if length(FuncLabPreferences) < 21
    FuncLabPreferences{19} = 'vel.cpt';
    FuncLabPreferences{20} = false;
    FuncLabPreferences{21} = '1.8.2';
end

% Tohoku-Oki
mainshockEpochTime = datenum('2011-03-11');

% New figure window
fig = figure ('Name',[TableName ' - Receiver Functions'],'Units','characters','NumberTitle','off',...
    'WindowStyle','normal','MenuBar','figure','Position',[0 0 220 58],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});

% Count up the active records
nrecords = 0;
for idx=1:size(CurrentRecords,1)
    nrecords = nrecords + CurrentRecords{idx,5};
end

% Figure out the min/max origin time and the timing of all the records
% Allocate space for a vector of all the origin times in datenum format
OriginTimeArray = zeros(nrecords,1);
jevent = 0;
for ievent=1:size(CurrentRecords,1)
    if CurrentRecords{ievent,5} == 1
        jevent = jevent + 1;
        tmpTimeVector = sscanf(CurrentRecords{ievent,3},'%d/%d/%d:%d:%d');
        [month, mday] = jul2cal(tmpTimeVector(1),tmpTimeVector(2));
        OriginTimeArray(jevent) = datenum(tmpTimeVector(1), month, mday, tmpTimeVector(3), tmpTimeVector(4), tmpTimeVector(5)) - mainshockEpochTime;
    end
end
%minOriginTime = min(OriginTimeArray);
%maxOriginTime = max(OriginTimeArray);
minOriginTime = -60;
maxOriginTime = 60;
stepOriginTime = 20; % 60 days for a test. 
% Note that with datenum, values are stored in days since 1-jan-1900
% so we are doing math on decimal days


% Allocate space for the eventual pcolor image
% Below assumes all records have the same number of points
RRFAmps = zeros(nrecords, CurrentRecords{1,7});
TRFAmps = zeros(nrecords, CurrentRecords{1,7});

count = 0;
for n = 1:size(CurrentRecords,1)
    if CurrentRecords{n,5} == 1
        count = count + 1;
        %Rayp(count) = CurrentRecords{n,21};
        if count > 1
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'eqr']);
            if isnan(TempAmps(1)) || isinf(TempAmps(1))
                TempAmps = 0 * TempAmps;
            end
            if length(TempAmps) ~= length(RRFAmps)
                RRFAmps(count,:) = interp1(TIME,TempAmps,RRFTime); 
            else
                RRFAmps(count,:) = TempAmps; 
            end
            
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'eqt']);
            if isnan(TempAmps(1)) || isinf(TempAmps(1))
                TempAmps = 0 * TempAmps;
            end
            if length(TempAmps) ~= length(TRFAmps)
                TRFAmps(count,:) = interp1(TIME,TempAmps,TRFTime); 
            else
                TRFAmps(count,:) = TempAmps; 
            end
        else
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'eqr']);
            if isnan(TempAmps(1)) || isinf(TempAmps(1))
                TempAmps = 0 * TempAmps;
            end
            RRFAmps(count,:) = TempAmps; RRFTime = TIME;
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'eqt']);
            if isnan(TempAmps(1)) || isinf(TempAmps(1))
                TempAmps = 0 * TempAmps;
            end
            TRFAmps(count,:) = TempAmps; TRFTime = TIME;
        end
    end
end
if count == 0; set(0,'userdata','Message: No active records in selected event.'); return; end

% Clear out nan or inf values
for n=count:-1:1
    if isnan(RRFAmps(n,1)) || isinf(RRFAmps(n,1)) || isnan(TRFAmps(n,1)) || isinf(TRFAmps(n,1))
        RRFAmps(n,:) = [];
        TRFAmps(n,:) = [];
        count = count - 1;
        OriginTimeArray(n) = [];
    end
end
        
%XTics = RaypMin:XInc:RaypMax;
%XTics = 0:stepOriginTime:maxOriginTime-minOriginTime;
XTics = minOriginTime:stepOriginTime:maxOriginTime;
for n = 1:count
    CPamp = max(RRFAmps(n,:));
    RRFAmps(n,:) = RRFAmps(n,:) / CPamp;
    TRFAmps(n,:) = TRFAmps(n,:) / CPamp;
end

%oTimeAxis = RaypMin:RayPInc:RaypMax;
oTimeAxis = minOriginTime:stepOriginTime:maxOriginTime;
oTimeMatrix = repmat(oTimeAxis,length(RRFTime),1);
% rpmatrix = rpmatrix - (RayPInc/2);
% rpmatrix = horzcat(rpmatrix,(rpmatrix(:,end) + RayPInc));
% rpmatrix = vertcat(rpmatrix,rpmatrix(end,:));
RRFTimeMatrix = repmat(RRFTime,1,length(oTimeAxis));

TRFTimeMatrix = repmat(TRFTime,1,length(oTimeAxis));
nramps = NaN * zeros(length(oTimeAxis),length(RRFTime));
ntamps = NaN * zeros(length(oTimeAxis),length(TRFTime));

NumberOfBins = length(oTimeAxis);
BinMaximum = maxOriginTime;
BinMinimum = minOriginTime;
BinWidth = (BinMaximum - BinMinimum)/NumberOfBins;
BinInformation = OriginTimeArray;

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

% fig = figure ('Name',[TableName ' - Receiver Functions'],'Units','characters','NumberTitle','off',...
%     'WindowStyle','normal','MenuBar','figure','Position',[0 0 220 58],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});

% orig position vector: [0 0 180 58]

s1 = axes('Parent',fig,'Units','characters','Position',[10 5 65 42]);
% imagesc(oTimeAxis,RRFTime,nramps','Parent',s1);
set(fig,'RendererMode','manual','Renderer','painters');
%nramps=smooth_nxm_matrix(nramps,3,3);
p1 = pcolor(s1,oTimeMatrix-(stepOriginTime/2),RRFTimeMatrix,nramps');
set(p1,'LineStyle','none')
% shading flat % -another option, maybe somewhat between the default
% faceted and the interped which can go wonky if there are nans
%shading interp % - creates an interpolated appearance rather than the
% default boxy appearance.

% RWP commented out for SRF
% if exist('Tps')
%     for n = 1:size(Tps,1)
%         line(p,Tps(n,:),'Parent',s1,'Color','k','LineWidth',2);
%         text(RaypMax+0.001,Tps(n,end),TpsPhase{n},'Parent',s1)
%     end
% end
% if exist('Tpp')
%     for n = 1:size(Tpp,1)
%         line(p,Tpp(n,:),'Parent',s1,'Color','k','LineStyle',':','LineWidth',2);
%         text(RaypMax+0.001,Tpp(n,end),TppPhase{n},'Parent',s1)
%     end
% end
% if exist('Tss')
%     for n = 1:size(Tss,1)
%         line(p,Tss(n,:),'Parent',s1,'Color','k','LineStyle',':','LineWidth',2);
%         text(RaypMax+0.001,Tss(n,end),TssPhase{n},'Parent',s1)
%     end
% end

set(s1,'Box','on','Units','normalized','Color',[1 1 1],'YDir','reverse','TickDir','out','XTick',XTics,'clipping','off');
axis(s1,[minOriginTime maxOriginTime TimeMin TimeMax])
set(s1,'Clipping','on')
%a = makeColorMap([1 0 0],[1 1 1],[0 0 1]);
%a = makeColorMap([0 10/255 160/255],[1 1 1],[160/255 10/255 0]);
% cmap = colormap(grey);
% cmap = flipud(cmap);
% colormap(cmap);
if FuncLabPreferences{20} == false
    cmap = cptcmap(FuncLabPreferences{19});
else
    cmap = cptcmap(FuncLabPreferences{19},'flip',true);
end
colormap(cmap);


caxis([-0.1 0.1])
%t1 = title(s1,'Radial RF');
%t1pos = get(t1,'position');
%set(t1,'position',[t1pos(1) t1pos(2)-4 t1pos(3)]);
yl = ylabel(s1,'Time (sec)');
%yl = ylabel(s1,'Depth (km)');
%xl1 = xlabel(s1,'Ray Parameter (sec/km)');
xl1 = xlabel(s1,'Origin Time (day)');

% plots histogram on top
h1 = axes('Parent',fig,'Units','characters','Position',[10 47 65 6]);
bar(h1,oTimeAxis,BinTraceCount,'k')
set(h1,'Box','on','XAxisLocation','top','XTickLabel',[],'XTick',[],'TickDir','out')
axis(h1,[minOriginTime maxOriginTime 0 max(BinTraceCount)])
ylabel(h1,'Trace Count')
yticks = get(h1,'YTick');
set(h1,'YTick',yticks(2:end))
t1 = title(h1,'Radial RF');

% Make a quicky 1D plot
tmp = zeros(1,length(RRFTimeMatrix(:,1)));
[nx, ny] = size(nramps);
for i=1:nx
    if (~isnan(nramps(i,:)))
        tmp = tmp + nramps(i,:);
    end
end
% From trace edit gui to fill positive and negative:
PositiveIndices = find (tmp > 0);
NegativeIndices = find (tmp < 0);
TempAmps = reshape(tmp,[],1);
Pamps = zeros (size(TempAmps));
Pamps(PositiveIndices) = TempAmps(PositiveIndices);
Namps = zeros (size(TempAmps));
Namps(NegativeIndices) = TempAmps(NegativeIndices);
PFilledTrace = reshape(Pamps,size(tmp));
NFilledTrace = reshape(Namps,size(tmp));
PFilledTrace = [zeros(1,length(PFilledTrace)), PFilledTrace, zeros(1,length(PFilledTrace))];
NFilledTrace = [zeros(1,length(NFilledTrace)), NFilledTrace, zeros(1,length(NFilledTrace))];
TimeAxis = TIME;
TimeAxis = [ones(1,length(TimeAxis)) * TimeAxis(1), ...
    TimeAxis', ...
    ones(1,length(TimeAxis)) * TimeAxis(end)];
% % plotting
s3 = axes('Parent',fig,'Units','characters','Position',[85 5 30 42]);
p3 = plot(s3,tmp,TIME,'k');
hold on
vp = [PFilledTrace; TimeAxis];
vn = [NFilledTrace; TimeAxis];
idx = length(vp);
vvp = vp;
vvn = vn;
vvp(1,idx+1) = 0;
vvp(2,idx+1) = max(TimeAxis);
vvp(1,idx+2) = 0;
vvp(2,idx+2) = min(TimeAxis);
vvn(1,idx+1) = 0;
vvn(2,idx+1) = max(TimeAxis);
vvn(1,idx+2) = 0;
vvn(2,idx+2) = min(TimeAxis);
ff=length(vvp):-1:1;
patch('Faces',ff,'Vertices',vvp','FaceColor',[160/255 10/255 0],'EdgeColor','none','Tag','phandle');
patch('Faces',ff,'Vertices',vvn','FaceColor',[0 10/255 160/255],'EdgeColor','none','Tag','nhandle');
%patch(PFilledTrace',TimeAxis',[160/255 10/255 0],'EdgeColor','none');
%patch(NFilledTrace',TimeAxis',[0 10/255 160/255],'EdgeColor','none');
set(s3,'Box','on','Units','normalized','Color',[1 1 1],'YDir','reverse','TickDir','out','clipping','off');
t3 = title(s3,'Radial Receiver Gather');
axis(s3,[min(tmp),max(tmp),TimeMin,TimeMax])
set(s3,'Clipping','on')


% Repeating for transverse component
s2 = axes('Parent',fig,'Units','characters','Position',[120 5 65 42]);
% original position vector: [ 85 5 65 42 ]
% imagesc(oTimeAxis,TRFTime,ntamps','Parent',s2);
set(fig,'RendererMode','manual','Renderer','painters');
p2 = pcolor(s2,oTimeMatrix-(stepOriginTime/2),TRFTimeMatrix,ntamps');
set(p2,'LineStyle','none');
% shading interp
set(s2,'Box','on','Units','normalized','Color',[1 1 1],'YDir','reverse','TickDir','out','XTick',XTics,'YAxisLocation','right');
axis(s2,[minOriginTime maxOriginTime TimeMin TimeMax])
set(s2,'Clipping','on')
if FuncLabPreferences{20} == false
    cmap = cptcmap(FuncLabPreferences{19});
else
    cmap = cptcmap(FuncLabPreferences{19},'flip',true);
end
colormap(cmap);

% colormap(cmap);
caxis([-0.1 0.1])
%t2 = title(s2,'Transverse RF');
%t2pos = get(t2,'position');
%set(t2,'position',[t2pos(1) t2pos(2)-4 t2pos(3)]);
xl2 = xlabel(s2,'Origin Time (day)');

h2 = axes('Parent',fig,'Units','characters','Position',[120 47 65 6]);
% Original position vecotr: [85 47 65 6]
bar(h2,oTimeAxis,BinTraceCount,'k')
set(h2,'Box','on','XAxisLocation','top','XTickLabel',[],'XTick',[],'TickDir','out','YAxisLocation','right')
axis(h2,[minOriginTime maxOriginTime 0 max(BinTraceCount)])
yticks = get(h2,'YTick');
set(h2,'YTick',yticks(2:end))
t2 = title(h2,'Transverse RF');

c1 = colorbar('peer',s2);
set(c1,'Parent',fig,'Units','characters','Position',[200 5 2.5 48])
set(get(c1,'YLabel'),'String','Amplitude');

