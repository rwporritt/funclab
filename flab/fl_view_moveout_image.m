function fl_view_moveout_image(ProjectDirectory,CurrentRecords,TableName,FuncLabPreferences)
%FL_VIEW_MOVEOUT_IMAGE Plot receiver functions vs. ray parameter
%   FL_VIEW_MOVEOUT_IMAGE (ProjectDirectory,CurrentRecords,TableName,
%   FuncLabPreferences) plots the radial and transverse receiver functions
%   in the input ensemble table ordered by P-wave ray parameter.
%
%   Author: Kevin C. Eagar
%   Date Created: 01/19/2008
%   Last Updated: 08/09/2010

TimeMin = str2double(FuncLabPreferences{4});
TimeMax = str2double(FuncLabPreferences{5});
XInc = str2double(FuncLabPreferences{2});
if length(FuncLabPreferences) < 21
    FuncLabPreferences{19} = 'vel.cpt';
    FuncLabPreferences{20} = false;
    FuncLabPreferences{21} = '1.8.2';
end


fig = figure ('Name',[TableName ' - Receiver Functions'],'Units','characters','NumberTitle','off',...
    'WindowStyle','normal','MenuBar','figure','Position',[0 0 220 58],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});

Phases = FuncLabPreferences{7};
if ~isempty(Phases)
    Phases = strread(Phases,'%s','delimiter',',');
    
    if isnan(str2double(Phases{1}(1)));

        VModel = FuncLabPreferences{8};
        Datapath = regexprep(which('funclab'),'funclab.m','VELMODELS/');
        Velocity1D = [Datapath VModel];
        VelocityModel = load(Velocity1D,'-ascii');
        Depths = VelocityModel(:,1);
        Vp = VelocityModel(:,2);
        Vs = VelocityModel(:,3);
        Vp = interp1(Depths,Vp,[0:1:Depths(end)])';
        Vs = interp1(Depths,Vs,[0:1:Depths(end)])';
        Depths = [0:1:Depths(end)]';
        dz = [0; diff(Depths)];
        R = 6371 - Depths;
        p = [0.035:0.001:0.085]; % ray parameters (s/km)
        
        % Determine the name of the phase.  This only handles P primary phases
        % and first-order reverberation phases.
        for n = 1:length(Phases)
            FirstPhase = Phases{n}(1);
            if ~strcmp(FirstPhase,'P')
                disp('Phase name is not in the correct format.')
                disp('Phase moveout curve skipped.')
                break
            end
            k = 1;
            l = 0;
            while 1
                k = k + 1;
                l = l + 1;
                if isnan(str2double(Phases{n}(k)))
                    break
                end
                PhaseDepth(l) = Phases{n}(k);
            end
            if k == 2
                disp('Phase name is not in the correct format.')
                disp('Phase moveout curve skipped.')
                break
            end
            PhaseDepth = str2double(PhaseDepth);
            SecondPhase = Phases{n}(k:end);
            switch SecondPhase
                case 's'
                    for m = 1:length(p)
                        RayP = skm2srad (p(m));
                        temp(:,m) = cumsum((sqrt((R./Vs).^2 - RayP^2) - sqrt((R./Vp).^2 - RayP^2)) .* (dz./R));
                    end
                    if exist('Tps')
                        Tps(end+1,:) = temp(PhaseDepth+1,:);
                        TpsPhase{end+1} = Phases{n};
                    else
                        Tps(1,:) = temp(PhaseDepth+1,:);
                        TpsPhase{1} = Phases{n};
                    end
                    clear temp
                case 'pPs'
                    for m = 1:length(p)
                        RayP = skm2srad (p(m));
                        temp(:,m) = cumsum((sqrt((R./Vs).^2 - RayP^2) + sqrt((R./Vp).^2 - RayP^2)) .* (dz./R));
                    end
                    if exist('Tpp')
                        Tpp(end+1,:) = temp(PhaseDepth+1,:);
                        TppPhase{end+1} = Phases{n};
                    else
                        Tpp(1,:) = temp(PhaseDepth+1,:);
                        TppPhase{1} = Phases{n};
                    end
                    clear temp
                case 'pSs'
                    for m = 1:length(p)
                        RayP = skm2srad (p(m));
                        temp(:,m) = cumsum(sqrt((R./Vs).^2 - RayP^2) .* (2*dz./R));
                    end
                    if exist('Tss')
                        Tss(end+1,:) = temp(PhaseDepth+1,:);
                        TssPhase{end+1} = Phases{n};
                    else
                        Tss(1,:) = temp(PhaseDepth+1,:);
                        TssPhase{1} = Phases{n};
                    end
                    clear temp
                case 'sPs'
                    for m = 1:length(p)
                        RayP = skm2srad (p(m));
                        temp(:,m) = cumsum(sqrt((R./Vs).^2 - RayP^2) .* (2*dz./R));
                    end
                    if exist('Tss')
                        Tss(end+1,:) = temp(PhaseDepth+1,:);
                        TssPhase{end+1} = Phases{n};
                    else
                        Tss(1,:) = temp(PhaseDepth+1,:);
                        TssPhase{1} = Phases{n};
                    end
                    clear temp
                otherwise
                    disp('Phase name is not in the correct format.')
                    disp('Phase moveout curve skipped.')
                    break
            end
            clear temp FirstPhase PhaseDepth SecondPhase
        end
    else
        disp('Phase names are not in the correct format.')
        disp('No phase moveout curves plotted.')
    end

end

% Here the original authors set static values for the extremes (original is
% 0.04 to 0.08 for PRF. Reasonable for SRF is 0.08 to 0.13. PRF inc
% originally set to 0.001. RWP edit uses user's input increment and
% determines min/max from data
% RaypMin = 0.04;
% RaypMax = 0.08;
% RayPInc = 0.001;
RayPInc = str2double(FuncLabPreferences{2});
% Stupidly inefficient method of getting min/max ray parameter from current
% records
RaypMin = 1.0;
RaypMax = 0.0;
for n=1:size(CurrentRecords,1) % Loop through all records
    if CurrentRecords{n,5} == 1 % only extract active records
        if CurrentRecords{n,21} < RaypMin
            RaypMin = CurrentRecords{n,21};
        end
        if CurrentRecords{n,21} > RaypMax
            RaypMax = CurrentRecords{n,21};
        end
    end
end
% round off to neat and clean. Normal ray parameters are between 0.04 and
% 0.13 so using the 100 values in the rounding should be ok.
RaypMax = ceil(RaypMax * 100) / 100.0;
RaypMin = floor(RaypMin * 100) / 100.0;

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
if count == 0; set(0,'userdata','Message: No active records in selected event.'); return; end
% Clear out nan or inf values
for n=count:-1:1
    if isnan(RRFAmps(n,1)) || isinf(RRFAmps(n,1)) || isnan(TRFAmps(n,1)) || isinf(TRFAmps(n,1))
        RRFAmps(n,:) = [];
        TRFAmps(n,:) = [];
        Rayp(n) = [];
        count = count - 1;
    end
end

XTics = RaypMin:XInc:RaypMax;
for n = 1:count
    CPamp = max(RRFAmps(n,:));
    RRFAmps(n,:) = RRFAmps(n,:) / CPamp;
    TRFAmps(n,:) = TRFAmps(n,:) / CPamp;
end

rpaxis = RaypMin:RayPInc:RaypMax;
rpmatrix = repmat(rpaxis,length(RRFTime),1);
% rpmatrix = rpmatrix - (RayPInc/2);
% rpmatrix = horzcat(rpmatrix,(rpmatrix(:,end) + RayPInc));
% rpmatrix = vertcat(rpmatrix,rpmatrix(end,:));
RRFTimeMatrix = repmat(RRFTime,1,length(rpaxis));

TRFTimeMatrix = repmat(TRFTime,1,length(rpaxis));
nramps = NaN * zeros(length(rpaxis),length(RRFTime));
ntamps = NaN * zeros(length(rpaxis),length(TRFTime));

NumberOfBins = length(rpaxis);
BinMaximum = RaypMax;
BinMinimum = RaypMin;
BinWidth = (BinMaximum - BinMinimum)/NumberOfBins;
BinInformation = Rayp;
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
% imagesc(rpaxis,RRFTime,nramps','Parent',s1);
set(fig,'RendererMode','manual','Renderer','painters');
%nramps=smooth_nxm_matrix(nramps,3,3);
p1 = pcolor(s1,rpmatrix-(RayPInc/2),RRFTimeMatrix,nramps');
set(p1,'LineStyle','none')
%shading interp % - creates an interpolated appearance rather than the
% default boxy appearance.

% RWP commented out for SRF
if exist('Tps')
    for n = 1:size(Tps,1)
        line(p,Tps(n,:),'Parent',s1,'Color','k','LineWidth',2);
        text(RaypMax+0.001,Tps(n,end),TpsPhase{n},'Parent',s1)
    end
end
if exist('Tpp')
    for n = 1:size(Tpp,1)
        line(p,Tpp(n,:),'Parent',s1,'Color','k','LineStyle',':','LineWidth',2);
        text(RaypMax+0.001,Tpp(n,end),TppPhase{n},'Parent',s1)
    end
end
if exist('Tss')
    for n = 1:size(Tss,1)
        line(p,Tss(n,:),'Parent',s1,'Color','k','LineStyle',':','LineWidth',2);
        text(RaypMax+0.001,Tss(n,end),TssPhase{n},'Parent',s1)
    end
end
set(s1,'Box','on','Units','normalized','Color',[1 1 1],'YDir','reverse','TickDir','out','XTick',XTics,'clipping','off');
axis(s1,[RaypMin RaypMax TimeMin TimeMax])
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
t1 = title(s1,'Radial RF');
t1pos = get(t1,'position');
set(t1,'position',[t1pos(1) t1pos(2)-4 t1pos(3)]);
yl = ylabel(s1,'Time (sec)');
%yl = ylabel(s1,'Depth (km)');
xl1 = xlabel(s1,'Ray Parameter (sec/km)');

% plots histogram on top
h1 = axes('Parent',fig,'Units','characters','Position',[10 47 65 6]);
bar(h1,rpaxis,BinTraceCount,'k')
set(h1,'Box','on','XAxisLocation','top','XTickLabel',[],'XTick',[],'TickDir','out')
axis(h1,[RaypMin RaypMax 0 max(BinTraceCount)])
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
% imagesc(rpaxis,TRFTime,ntamps','Parent',s2);
set(fig,'RendererMode','manual','Renderer','painters');
p2 = pcolor(s2,rpmatrix-(RayPInc/2),TRFTimeMatrix,ntamps');
set(p2,'LineStyle','none');
% shading interp
set(s2,'Box','on','Units','normalized','Color',[1 1 1],'YDir','reverse','TickDir','out','XTick',XTics,'YAxisLocation','right');
axis(s2,[RaypMin RaypMax TimeMin TimeMax])
set(s2,'Clipping','on')
if FuncLabPreferences{20} == false
    cmap = cptcmap(FuncLabPreferences{19});
else
    cmap = cptcmap(FuncLabPreferences{19},'flip',true);
end
colormap(cmap);

% colormap(cmap);
caxis([-0.1 0.1])
t2 = title(s2,'Transverse RF');
t2pos = get(t2,'position');
set(t2,'position',[t2pos(1) t2pos(2)-4 t2pos(3)]);
xl2 = xlabel(s2,'Ray Parameter (sec/km)');

h2 = axes('Parent',fig,'Units','characters','Position',[120 47 65 6]);
% Original position vecotr: [85 47 65 6]
bar(h2,rpaxis,BinTraceCount,'k')
set(h2,'Box','on','XAxisLocation','top','XTickLabel',[],'XTick',[],'TickDir','out','YAxisLocation','right')
axis(h2,[RaypMin RaypMax 0 max(BinTraceCount)])
yticks = get(h2,'YTick');
set(h2,'YTick',yticks(2:end))

c1 = colorbar('peer',s2);
set(c1,'Parent',fig,'Units','characters','Position',[200 5 2.5 48])
set(get(c1,'YLabel'),'String','Amplitude');
