function fl_view_baz_image(ProjectDirectory,CurrentRecords,TableName,FuncLabPreferences)
%FL_VIEW_BAZ_IMAGE Plot receiver functions vs. ray parameter
%   FL_VIEW_BAZ_IMAGE (ProjectDirectory,CurrentRecords,TableName,
%   FuncLabPreferences) plots the radial and transverse receiver functions
%   in the input ensemble table ordered by backazimuth.
%
%   Author: Kevin C. Eagar
%   Date Created: 04/09/2009
%   Last Updated: 05/15/2010

TimeMin = str2double(FuncLabPreferences{4});
TimeMax = str2double(FuncLabPreferences{5});
XInc = str2double(FuncLabPreferences{3});
if length(FuncLabPreferences) < 21
    FuncLabPreferences{19} = 'parula.cpt';
    FuncLabPreferences{20} = false;
    FuncLabPreferences{21} = '1.8.2';
end
ColorMapChoice = FuncLabPreferences{19};

BazMin = 0;
BazMax = 360;
count = 0;
for n = 1:size(CurrentRecords,1)
    if CurrentRecords{n,5} == 1
        count = count + 1;
        Baz(count) = CurrentRecords{n,22};
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
if count == 0; set(0,'userdata','Message: No active records in selected event.'); return; end

% Clear out nan or inf values
for n=count:-1:1
    if isnan(RRFAmps(n,1)) || isinf(RRFAmps(n,1)) || isnan(TRFAmps(n,1)) || isinf(TRFAmps(n,1))
        RRFAmps(n,:) = [];
        TRFAmps(n,:) = [];
        Baz(n) = [];
        count = count - 1;
    end
end

XTics = BazMin:XInc:BazMax;
for n = 1:count
    CPamp = max(RRFAmps(n,:));
    RRFAmps(n,:) = RRFAmps(n,:) / CPamp;
    TRFAmps(n,:) = TRFAmps(n,:) / CPamp;
end

% So weird to have these hard coded!
BazInc = 15;
BazInc = 10;
BazInc = XInc;


baxis = BazMin:BazInc:BazMax;
bmatrix = repmat(baxis,length(RRFTime),1);
RRFTimeMatrix = repmat(RRFTime,1,length(baxis));

TRFTimeMatrix = repmat(TRFTime,1,length(baxis));
nramps = NaN * zeros(length(baxis),length(RRFTime));
ntamps = NaN * zeros(length(baxis),length(TRFTime));

NumberOfBins = length(baxis);
BinMaximum = BazMax;
BinMinimum = BazMin;
BinWidth = (BinMaximum - BinMinimum)/NumberOfBins;
BinInformation = Baz;
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
        
fig = figure ('Name',[TableName ' - Receiver Functions'],'Units','characters','NumberTitle','off',...
    'WindowStyle','normal','MenuBar','figure','Position',[0 0 220 58],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});

s1 = axes('Parent',fig,'Units','characters','Position',[10 5 65 42]);
% imagesc(rpaxis,RRFTime,nramps','Parent',s1);
set(fig,'RendererMode','manual','Renderer','painters');
p1 = pcolor(s1,bmatrix-(BazInc/2),RRFTimeMatrix,nramps');
set(p1,'LineStyle','none')
% shading interp
set(s1,'Box','on','Units','normalized','Color',[1 1 1],'YDir','reverse','TickDir','out','XTick',XTics);
axis(s1,[BazMin BazMax TimeMin TimeMax])
set(s1,'Clipping','on')
% section edit out by RWP to allow user choice of color map
%a = makeColorMap([1 0 0], [1 1 1], [0 0 1]);
%a = makeColorMap([0 10/255 160/255],[1 1 1],[160/255 10/255 0]);
% cmap = colormap(grey);
% cmap = flipud(cmap);
% colormap(cmap);
% if strcmp(ColorMapChoice,'Blue to red')
%     a = makeColorMap([0 10/255 160/255],[1 1 1],[160/255 10/255 0]);
%     colormap(a)
% elseif strcmp(ColorMapChoice,'Red to blue')
%     a = makeColorMap([160/255 10/255 0], [1 1 1], [0 10/255 160/255]);
%     colormap(a)
% elseif strcmp(ColorMapChoice, 'Parula')
%     colormap('parula');
% elseif strcmp(ColorMapChoice,'Jet')
%     colormap('jet');
% end    %colormap(a);
%colormap('jet');
% Version using cptmap to allow user specified color maps in gmt style
if FuncLabPreferences{20} == false
    cmap = cptcmap(FuncLabPreferences{19});
else
    cmap = cptcmap(FuncLabPreferences{19},'flip',true);
end
colormap(cmap);

% Note to future editors - allow caxis to be adjusted!
caxis([-0.1 0.1])
t1 = title(s1,'Radial RF');
t1pos = get(t1,'position');
set(t1,'position',[t1pos(1) t1pos(2)-4 t1pos(3)]);
yl = ylabel(s1,'Time lag (sec)');
xl1 = xlabel(s1,'Event Backazimuth (deg)');

h1 = axes('Parent',fig,'Units','characters','Position',[10 47 65 6]);
bar(h1,baxis,BinTraceCount,'k')
set(h1,'Box','on','XAxisLocation','top','XTickLabel',[],'XTick',[],'TickDir','out')
axis(h1,[BazMin BazMax 0 max(BinTraceCount)])
ylabel(h1,'Trace Count')
yticks = get(h1,'YTick');
set(h1,'YTick',yticks(2:end))


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
p3 = plot(s3,tmp,RRFTime,'k');
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
axis(s3,[min(tmp),max(tmp),TimeMin, TimeMax])
set(s3,'Clipping','on')

% Repeats for tangential
s2 = axes('Parent',fig,'Units','characters','Position',[120 5 65 42]);
% imagesc(rpaxis,TRFTime,ntamps','Parent',s2);
set(fig,'RendererMode','manual','Renderer','painters');
p2 = pcolor(s2,bmatrix-(BazInc/2),TRFTimeMatrix,ntamps');
set(p2,'LineStyle','none');
% shading interp
set(s2,'Box','on','Units','normalized','Color',[1 1 1],'YDir','reverse','TickDir','out','XTick',XTics,'YAxisLocation','right');
axis(s2,[BazMin BazMax TimeMin TimeMax])
set(s2,'Clipping','on')
% if strcmp(ColorMapChoice,'Jet')
%     colormap('jet');
% elseif strcmp(ColorMapChoice, 'Parula')
%     colormap('parula');
% else
%     colormap(a);
% end
if FuncLabPreferences{20} == false
    cmap = cptcmap(FuncLabPreferences{19});
else
    cmap = cptcmap(FuncLabPreferences{19},'flip',true);
end
colormap(cmap);

%colormap('jet');
% colormap(cmap);
caxis([-0.1 0.1])
t2 = title(s2,'Transverse RF');
t2pos = get(t2,'position');
set(t2,'position',[t2pos(1) t2pos(2)-4 t2pos(3)]);
xl2 = xlabel(s2,'Event Backazimuth (deg)');

h2 = axes('Parent',fig,'Units','characters','Position',[120 47 65 6]);
bar(h2,baxis,BinTraceCount,'k')
set(h2,'Box','on','XAxisLocation','top','XTickLabel',[],'XTick',[],'TickDir','out','YAxisLocation','right')
axis(h2,[BazMin BazMax 0 max(BinTraceCount)])
yticks = get(h2,'YTick');
set(h2,'YTick',yticks(2:end))

% colorbar
c1 = colorbar('peer',s2);
set(c1,'Parent',fig,'Units','characters','Position',[200 5 2.5 48])
set(get(c1,'YLabel'),'String','Amplitude');
