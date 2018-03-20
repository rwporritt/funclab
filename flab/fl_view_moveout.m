function fl_view_moveout(ProjectDirectory,CurrentRecords,TableName,FuncLabPreferences)
%FL_VIEW_MOVEOUT Plot receiver functions vs. ray parameter
%   FL_VIEW_MOVEOUT (ProjectDirectory,CurrentRecords,TableName,
%   FuncLabPreferences) plots the radial and transverse receiver functions
%   in the input ensemble table ordered by P-wave ray parameter.

%   Author: Kevin C. Eagar
%   Date Created: 04/19/2008
%   Last Updated: 08/09/2010

TimeMin = str2double(FuncLabPreferences{4});
TimeMax = str2double(FuncLabPreferences{5});
XInc = str2double(FuncLabPreferences{2});

% default gain used to scale wiggles. Ideally make this adjustable in the
% image
gain = 0.05;

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
XTics = RaypMin:XInc:RaypMax;
Scale = (XTics(end) - XTics(1)) * gain;
RRFPos = zeros(size(RRFAmps,1),size(RRFAmps,2)+2);
RPosTime = [RRFTime(1);RRFTime;RRFTime(end)];
TRFPos = zeros(size(TRFAmps,1),size(TRFAmps,2)+2);
TPosTime = [TRFTime(1);TRFTime;TRFTime(end)];
for n = 1:count
    CPamp = max(RRFAmps(n,:));
    In = find(RRFAmps(n,:) >= 0);
    RRFPos(n,In+1) = RRFAmps(n,In);
    RRFPos(n,:) = Scale * RRFPos(n,:) / CPamp + Rayp(n);
    RRFAmps(n,:) = Scale * RRFAmps(n,:) / CPamp + Rayp(n);
    In = find(TRFAmps(n,:) >= 0);
    TRFPos(n,In+1) = TRFAmps(n,In);
    TRFPos(n,:) = Scale * TRFPos(n,:) / CPamp + Rayp(n);
    TRFAmps(n,:) = Scale * TRFAmps(n,:) / CPamp + Rayp(n);
end

fig = figure ('Name',[TableName ' - Receiver Functions'],'Units','characters','NumberTitle','off',...
    'WindowStyle','normal','MenuBar','figure','Position',[0 0 160 58],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});

s1 = axes('Parent',fig,'Units','characters','Position',[10 5 65 48],'Box','on');
for n = 1:size(RRFPos,1)
    patch(RRFPos(n,:),RPosTime,[.4 .4 .4],'EdgeColor','none')
    line(RRFAmps(n,:),RRFTime,'Parent',s1,'Color','k');
end
%line(RRFAmps,RRFTime,'Parent',s1,'Color','k');

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

set(s1,'Box','on','Units','normalized','Color',[1 1 1],'YDir','reverse','TickDir','out','XTick',XTics);
axis(s1,[RaypMin RaypMax TimeMin TimeMax])
t1 = title(s1,'Radial RF');
yl = ylabel(s1,'Time (sec)');
xl1 = xlabel(s1,'Ray Parameter (sec/km)');

s2 = axes('Parent',fig,'Units','characters','Position',[85 5 65 48]);
for n = 1:size(TRFPos,1)
    patch(TRFPos(n,:),TPosTime,[.4 .4 .4],'EdgeColor','none')
    line(TRFAmps(n,:),TRFTime,'Parent',s2,'Color','k');
end
%line(TRFAmps,TRFTime,'Parent',s2,'Color','k');
set(s2,'Box','on','Units','normalized','Color',[1 1 1],'Ycolor',[1 1 1],'YDir','reverse','TickDir','out','XTick',XTics);
axis(s2,[RaypMin RaypMax TimeMin TimeMax])
t2 = title(s2,'Transverse RF');
xl2 = xlabel(s2,'Ray Parameter (sec/km)');