function hk_allstack(cbo,eventdata,handles)
%HK_ALLSTACK H-k Stacking Analysis for All Stations
%   HK_ALLSTACK is a callback function that computes the 1D ray
%   tracing matrix for every event-station pair in the project dataset.
%   This saves us from having to do this for velocity corrections and CCP
%   stacking.

%   Author: Kevin C. Eagar
%   Date Created: 01/09/2009
%   Last Updated: 05/07/2015
%   RWP Update: Found if you loaded seismgrams with nan's it would crash.
%   Now nan values are check against and removed.
%   Added option to allow manual determination of Ps arrival window.

% Time the runtime of this function.
%--------------------------------------------------------------------------
tic
doPlot = 0;

% Get the handles of the FuncLab GUI
%--------------------------------------------------------------------------
h = guidata(gcbf);

% Wait message
%--------------------------------------------------------------------------
WaitGui = dialog ('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
    'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
    'String','Please wait, performing H-k stacking for the selected stations in the dataset.',...
    'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
drawnow;
H = guihandles(WaitGui);
guidata(WaitGui,H);

ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
% Sets the name of the set. Removes white spaces and capitalizes between
% words
if CurrentSubsetIndex ~= 1
    SetName = SetManagementCell{CurrentSubsetIndex,5};
    % Remove spaces because they make filesystems go a little haywire
    % sometimes
    SpaceIDX = isspace(SetName);
    for idx=2:length(SetName)
        if isspace(SetName(idx-1))
            SetName(idx) = upper(SetName(idx));
        end
    end
    SetName = SetName(~SpaceIDX);
else
    SetName = 'Base';
end

if ~exist([ProjectDirectory 'HKDATA'],'dir')
    mkdir([ProjectDirectory 'HKDATA'])
end
if CurrentSubsetIndex ~= 1
    if ~exist([ProjectDirectory 'HKDATA' filesep SetName],'dir')
        mkdir([ProjectDirectory 'HKDATA' filesep SetName])
    end
end


% Get the Station Table to perform stacking
%--------------------------------------------------------------------------
RecordMetadataStrings = SetManagementCell{CurrentSubsetIndex, 2};
RecordMetadataDoubles = SetManagementCell{CurrentSubsetIndex, 3};
%RecordMetadataStrings = evalin('base','RecordMetadataStrings');
%RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
StationList = sort(unique(RecordMetadataStrings(:,2)));
load([ProjectDirectory ProjectFile],'FuncLabPreferences')
ColorMapChoice = FuncLabPreferences{19};

% Set initial values
%----------------------------------------------------------------------
ResampleNumber = str2double(get(h.bootresamples_e,'string'));
RandomSelectionCount = str2double(get(h.bootpercent_e,'string'))/100;
RayParameterMin = str2double(get(h.raypmin_e,'string'));
RayParameterMax = str2double(get(h.raypmax_e,'string'));
BackazimuthMin = str2double(get(h.bazmin_e,'string'));
BackazimuthMax = str2double(get(h.bazmax_e,'string'));
TimeMin = str2double(get(h.timemin_e,'string'));
TimeMax = str2double(get(h.timemax_e,'string'));
TimeDelta = str2double(get(h.timedelta_e,'string'));
AssumedVp = str2double(get(h.vp_e,'string'));
HMin = str2double(get(h.hmin_e,'string'));
HMax = str2double(get(h.hmax_e,'string'));
HDelta = str2double(get(h.hdelta_e,'string'));
kMin = str2double(get(h.kmin_e,'string'));
kMax = str2double(get(h.kmax_e,'string'));
kDelta = str2double(get(h.kdelta_e,'string'));
w1 = str2double(get(h.w1_e,'string'));
w2 = str2double(get(h.w2_e,'string'));
w3 = str2double(get(h.w3_e,'string'));
Error = get(h.error_p,'value');

ManualTimeFlag = get(h.manual_time_all_cb,'Value');

% Get the Station Table to perform stacking
%--------------------------------------------------------------------------
cr=0;
for n = 1:length(StationList)

    % Adjust the time and H if user has selected to manually adjust the
    % time limits
    % Warning, this obviously will greatly slow down processing by forcing
    % the user to evaluate every station!
    if ManualTimeFlag
        [TimeMin, TimeMax] = hk_stacked_records_get_time_index(n);
        HMin = 9 * TimeMin;
        HMax = 11 * TimeMax;
    end
    NewTime = colvector(TimeMin:TimeDelta:TimeMax);
    HAxis = colvector(HMin:HDelta:HMax);
    kAxis = colvector(kMin:kDelta:kMax);

    % Find the precision of the TimeDelta for future roundoff calculations
    %----------------------------------------------------------------------
    Pcount = -1;
    while 1
        Pcount = Pcount + 1;
        NewDelta = TimeDelta * 10^Pcount;
        Check = rem(NewDelta,1);
        if Check == 0; break; end
    end
    NewTime = round(NewTime*10^Pcount)/10^Pcount;

    in = strmatch(StationList{n},RecordMetadataStrings(:,2),'exact');
    fprintf('H-k stacking %s\n',StationList{n});
    CurrentRecords = [RecordMetadataStrings(in,:) num2cell(RecordMetadataDoubles(in,:))];
    [CurrentRecords,ind] = sortrows(CurrentRecords,3);
    CurrentIndices = in(ind);
    Gaussian = CurrentRecords{1,10};

    cr=cr+1;
    
    % Make the "amplitude" matrix of all the traces
    %----------------------------------------------------------------------
    count = 0;
    HkEventList = cell(0,1);
    for m = 1:size(CurrentRecords,1)
        if CurrentRecords{m,5} == 1 && ...
                CurrentRecords{m,21} >= RayParameterMin && CurrentRecords{m,21} <= RayParameterMax && ...
                CurrentRecords{m,22} >= BackazimuthMin && CurrentRecords{m,22} <= BackazimuthMax
            count = count + 1;
            HkEventList{count} = RecordMetadataStrings{CurrentIndices(m),3};
            [TempAmps,Time] = fl_readseismograms([ProjectDirectory CurrentRecords{m,1} 'eqr']);
            % Set NaN or inf values to some near 0 value
            for idx=1:length(TempAmps)
                if isnan(TempAmps(idx)) || isinf(TempAmps(idx))
                    TempAmps(idx) = 0.00001;
                end
            end
            % Normalize
            if isequal(max(TempAmps),0)
                fprintf('Nearly divided by 0! n: %d m: %d\n',n,m);
                return
            end
            TempAmps = TempAmps/max(TempAmps);
            Amps(:,count) = interp1(Time,TempAmps,NewTime);
            SphereRayp(count,1) = skm2srad(CurrentRecords{m,21});
            Baz(count,1) = CurrentRecords{m,22};
        end
    end
    
    % Avoid if count is 0
    if count > 0
    
        % Perform a double loop through H-k space to compute the times and make the
        % time and amplitude cubes over the H-k space
        %--------------------------------------------------------------------------
        hcount = 0;
        for l = HMin:HDelta:HMax
            hcount = hcount + 1;
            R = 6371 - l;
            kcount = 0;
            for m = kMin:kDelta:kMax
                kcount = kcount + 1;
                tps = (sqrt((R./(AssumedVp/m)).^2 - SphereRayp.^2) - sqrt((R./AssumedVp).^2 - SphereRayp.^2)) .* (l./R);
                tpp = (sqrt((R./(AssumedVp/m)).^2 - SphereRayp.^2) + sqrt((R./AssumedVp).^2 - SphereRayp.^2)) .* (l./R);
                tss = 2 .* (l./R) .* sqrt((R./(AssumedVp/m)).^2 - SphereRayp.^2);
                tps = round((tps*10^Pcount)/(TimeDelta*10^Pcount))*(TimeDelta*10^Pcount)/10^Pcount;
                tpp = round((tpp*10^Pcount)/(TimeDelta*10^Pcount))*(TimeDelta*10^Pcount)/10^Pcount;
                tss = round((tss*10^Pcount)/(TimeDelta*10^Pcount))*(TimeDelta*10^Pcount)/10^Pcount;
                [~,ips] = ismember(tps,NewTime);
                [~,ipp] = ismember(tpp,NewTime);
                [~,iss] = ismember(tss,NewTime);
                try
                    Atps(:,hcount,kcount) = Amps(ips);
                catch
                    for k = 1:length(ips)
                        if ips(k) ~= 0
                            Atps(k,hcount,kcount) = Amps(ips(k));
                        else
                            Atps(k,hcount,kcount) = NaN;
                        end
                    end
                end
                try
                    Atpp(:,hcount,kcount) = Amps(ipp);
                catch
                    for k = 1:length(ipp)
                        if ipp(k) ~= 0
                            Atpp(k,hcount,kcount) = Amps(ipp(k));
                        else
                            Atpp(k,hcount,kcount) = NaN;
                        end
                    end
                end
                try
                    Atss(:,hcount,kcount) = Amps(iss);
                catch
                    for k = 1:length(iss)
                        if iss(k) ~= 0
                            Atss(k,hcount,kcount) = Amps(iss(k));
                        else
                            Atss(k,hcount,kcount) = NaN;
                        end
                    end
                end
            end
        end

        % H-k Stacking Based on Choice of Error Analysis
        %--------------------------------------------------------------------------
        if Error == 1

            % Init the random number generator
            rng('shuffle','twister')

            % Sum the amplitudes of the receiver functions at the predicted times
            %--------------------------------------------------------------------------
            for m = 1:ResampleNumber

                %Pick out the m number of random traces (they can repeat)
                %----------------------------------------------------------------------
                %rand('state',sum(100*clock))
                BootstrapIndices = ceil(count.*rand(round(count*RandomSelectionCount),1));

                % Semblance weighting
                %         Temp(1,:,:) = w1.*ignoreNaN(Atps(BootstrapIndices,:,:),@mean,1).*ignoreNaN(Atps(BootstrapIndices,:,:),@mean,1).^2./ignoreNaN(Atps(BootstrapIndices,:,:).^2,@mean,1);
                %         Temp(2,:,:) = w2.*ignoreNaN(Atpp(BootstrapIndices,:,:),@mean,1).*ignoreNaN(Atpp(BootstrapIndices,:,:),@mean,1).^2./ignoreNaN(Atpp(BootstrapIndices,:,:).^2,@mean,1);
                %         Temp(3,:,:) = -w3.*ignoreNaN(Atss(BootstrapIndices,:,:),@mean,1).*ignoreNaN(Atss(BootstrapIndices,:,:),@mean,1).^2./ignoreNaN(Atss(BootstrapIndices,:,:).^2,@mean,1);
                %         Temp(1,:,:) = w1.*mean(Atps(BootstrapIndices,:,:),1).*mean(Atps(BootstrapIndices,:,:),1).^2./mean(Atps(BootstrapIndices,:,:).^2,1);
                %         Temp(2,:,:) = w2.*mean(Atpp(BootstrapIndices,:,:),1).*mean(Atpp(BootstrapIndices,:,:),1).^2./mean(Atpp(BootstrapIndices,:,:).^2,1);
                %         Temp(3,:,:) = -w3.*mean(Atss(BootstrapIndices,:,:),1).*mean(Atss(BootstrapIndices,:,:),1).^2./mean(Atss(BootstrapIndices,:,:).^2,1);

                % No semblance weighting
                Temp(1,:,:) = w1.*ignoreNaN(Atps(BootstrapIndices,:,:),@mean,1);
                Temp(2,:,:) = w2.*ignoreNaN(Atpp(BootstrapIndices,:,:),@mean,1);
                Temp(3,:,:) = -w3.*ignoreNaN(Atss(BootstrapIndices,:,:),@mean,1);
                %     Temp(1,:,:) = w1.*mean(Atps(BootstrapIndices,:,:),1);
                %     Temp(2,:,:) = w2.*mean(Atpp(BootstrapIndices,:,:),1);
                %     Temp(3,:,:) = -w3.*mean(Atss(BootstrapIndices,:,:),1);

                HKAmps = ignoreNaN(Temp,@sum,1);
                %     HKAmps = sum(Temp,1);
                HKAmps = reshape(HKAmps,size(HKAmps,2),[]);
                HKAmps = HKAmps - min(min(HKAmps));
                HKAmps = HKAmps./max(max(HKAmps));
                [junk,MaxHI] = max(HKAmps,[],1);
                [~,MaxkI] = max(junk); MaxHI = MaxHI(MaxkI);
                MaxH = HAxis(MaxHI); Maxk = kAxis(MaxkI);
                TempHKAmps(m,:,:) = HKAmps;
                TempMaxH(m,1) = MaxH;
                TempMaxk(m,1) = Maxk;
            end

            HKAmps = ignoreNaN(TempHKAmps,@mean,1);
            % HKAmps = mean(TempHKAmps,1);
            HKAmps = reshape(HKAmps,size(HKAmps,2),[]);
            HKAmps = HKAmps - min(min(HKAmps));
            HKAmps = HKAmps./max(max(HKAmps));
            HKSigma = ignoreNaN(TempHKAmps,@std,1);
            % HKSigma = std(TempHKAmps,1);
            HKSigma = reshape(HKSigma,size(HKSigma,2),[]);
            MaxH = mean(TempMaxH);
            MaxHsig = std(TempMaxH) * 1.96;
            Maxk = mean(TempMaxk);
            Maxksig = std(TempMaxk) * 1.96;

        elseif Error == 2

            Temp(1,:,:) = w1.*ignoreNaN(Atps,@mean,1);
            Temp(2,:,:) = w2.*ignoreNaN(Atpp,@mean,1);
            Temp(3,:,:) = -w3.*ignoreNaN(Atss,@mean,1);

            HKAmps = ignoreNaN(Temp,@sum,1);

            HKAmps = reshape(HKAmps,size(HKAmps,2),[]);
            HKAmps = HKAmps - min(min(HKAmps));
            HKAmps = HKAmps./max(max(HKAmps));
            [junk,MaxHI] = max(HKAmps,[],1);
            [~,MaxkI] = max(junk); MaxHI = MaxHI(MaxkI);
            MaxH = HAxis(MaxHI); Maxk = kAxis(MaxkI);

            cvalue = 1 - std(reshape(HKAmps,1,numel(HKAmps)))/sqrt(length(HkEventList));
            c = contourc(kAxis,HAxis,HKAmps,[cvalue cvalue]);

            % Determine how many contour circles we have
            NumContours = find(c(1,:) == cvalue);
            if length(NumContours) == 1
                Maxksig = (max(c(1,2:end)) - min(c(1,2:end)))/2;
                MaxHsig = (max(c(2,2:end)) - min(c(2,2:end)))/2;
            else
                [~,IndexOfMaxk]=min(abs(c(1,:) - Maxk));
                RightContour = find(NumContours < IndexOfMaxk,1,'last');
                if RightContour ~= length(NumContours)
                    Maxksig = (max(c(1,NumContours(RightContour)+1:NumContours(RightContour+1)-1)) - min(c(1,NumContours(RightContour)+1:NumContours(RightContour+1)-1)))/2;
                    MaxHsig = (max(c(2,NumContours(RightContour)+1:NumContours(RightContour+1)-1)) - min(c(2,NumContours(RightContour)+1:NumContours(RightContour+1)-1)))/2;
                else
                    Maxksig = (max(c(1,NumContours(RightContour)+1:end)) - min(c(1,NumContours(RightContour)+1:end)))/2;
                    MaxHsig = (max(c(2,NumContours(RightContour)+1:end)) - min(c(2,NumContours(RightContour)+1:end)))/2;
                end
            end

        end
        if CurrentSubsetIndex == 1
            HkPath = ['HKDATA' filesep strrep(StationList{n},'-','_') '_'...
                num2str(BackazimuthMin,'%03.0f') num2str(BackazimuthMax,'%03.0f') '_'...
                num2str(RayParameterMin*1000,'%03.0f') num2str(RayParameterMax*1000,'%03.0f') '.mat'];
        else
            HkPath = ['HKDATA' filesep SetName filesep strrep(StationList{n},'-','_') '_'...
                num2str(BackazimuthMin,'%03.0f') num2str(BackazimuthMax,'%03.0f') '_'...
                num2str(RayParameterMin*1000,'%03.0f') num2str(RayParameterMax*1000,'%03.0f') '.mat'];
        end
        HkTableName = ['Baz: ' num2str(BackazimuthMin,'%.0f') '-' num2str(BackazimuthMax,'%.0f') ...
            ' Rayp: ' num2str(RayParameterMin,'%.3f') '-' num2str(RayParameterMax,'%.3f')];
        PoissonRatio = 0.5 .* (1 - (1 ./ (Maxk.^2 - 1)));
        PoissonRatioError = (0.5 .* (1 - (1 ./ ((Maxk+Maxksig).^2 - 1)))) - PoissonRatio;

        if evalin('base',['exist(''HkMetadataCell'',''var'')'])
            HkMetadataCell = evalin('base','HkMetadataCell');
            if size(HkMetadataCell,1) < size(SetManagementCell,1)
                tmp = cell(size(SetManagementCell,1),2);
                for idx=1:size(HkMetadataCell,1)
                    tmp{idx,1} = HkMetadataCell{idx,1};
                    tmp{idx,2} = HkMetadataCell{idx,2};
                end
            end
            if ~isempty(HkMetadataCell{CurrentSubsetIndex,1})
                HkMetadataStrings = HkMetadataCell{CurrentSubsetIndex,1};
                HkMetadataDoubles = HkMetadataCell{CurrentSubsetIndex,2};
            
                % Check to make sure the record DOES NOT exist
                %----------------------------------------------------------------------
                if isempty(strmatch(HkPath,HkMetadataStrings(:,1)));
                    % If it DOES NOT, add it to the end
                    %------------------------------------------------------------------
                    HkMetadataStrings(end+1,:) = {HkPath,StationList{n},HkTableName};
                    HkMetadataDoubles(end+1,:) = [length(HkEventList),TimeDelta,size(Amps,1),TimeMin,TimeMax,Gaussian,...
                        BackazimuthMin,BackazimuthMax,RayParameterMin,RayParameterMax,w1,w2,w3,AssumedVp,MaxH,MaxHsig,...
                        Maxk,Maxksig,PoissonRatio,PoissonRatioError];
                else
                    % If it DOES, replace it
                    %--------------------------------------------------------------
                    In = strmatch(HkPath,HkMetadataStrings(:,1));
                    HkMetadataStrings(In,:) = {HkPath,StationList{n},HkTableName};
                    HkMetadataDoubles(In,:) = [length(HkEventList),TimeDelta,size(Amps,1),TimeMin,TimeMax,Gaussian,...
                        BackazimuthMin,BackazimuthMax,RayParameterMin,RayParameterMax,w1,w2,w3,AssumedVp,MaxH,MaxHsig,...
                        Maxk,Maxksig,PoissonRatio,PoissonRatioError];
                end
            else
                % Populate the HkMetadataStrings
                %------------------------------------------------------------------
                HkMetadataStrings(1,:) = {HkPath,StationList{n},HkTableName};
                % Populate the HkMetadataDoubles
                %------------------------------------------------------------------
                HkMetadataDoubles(1,:) = [length(HkEventList),TimeDelta,size(Amps,1),TimeMin,TimeMax,Gaussian,...
                    BackazimuthMin,BackazimuthMax,RayParameterMin,RayParameterMax,w1,w2,w3,AssumedVp,MaxH,MaxHsig,...
                    Maxk,Maxksig,PoissonRatio,PoissonRatioError];
            end
        else
            % Populate the HkMetadataStrings
            %------------------------------------------------------------------
            HkMetadataStrings(1,:) = {HkPath,StationList{n},HkTableName};
            % Populate the HkMetadataDoubles
            %------------------------------------------------------------------
            HkMetadataDoubles(1,:) = [length(HkEventList),TimeDelta,size(Amps,1),TimeMin,TimeMax,Gaussian,...
                BackazimuthMin,BackazimuthMax,RayParameterMin,RayParameterMax,w1,w2,w3,AssumedVp,MaxH,MaxHsig,...
                Maxk,Maxksig,PoissonRatio,PoissonRatioError];
            HkMetadataCell = cell(size(SetManagementCell,1),2);
        end
        HkMetadataCell{CurrentSubsetIndex,1} = HkMetadataStrings;
        HkMetadataCell{CurrentSubsetIndex,2} = HkMetadataDoubles;
        save([ProjectDirectory HkPath],'HKAmps','HAxis','kAxis','HkEventList');
        assignin('base','HkMetadataStrings',HkMetadataStrings)
        assignin('base','HkMetadataDoubles',HkMetadataDoubles)
        assignin('base','HkMetadataCell',HkMetadataCell)

        % Compute the Ps, PpPs, and PpSs+PsPs curves for the depth and Vp/Vs
        %----------------------------------------------------------------------
        tps = (sqrt((R./(AssumedVp./Maxk)).^2 - SphereRayp(1).^2) - sqrt((R./AssumedVp).^2 - SphereRayp(1).^2)) .* (MaxH./R);
        tpp = (sqrt((R./(AssumedVp./Maxk)).^2 - SphereRayp(1).^2) + sqrt((R./AssumedVp).^2 - SphereRayp(1).^2)) .* (MaxH./R);
        tss = 2 .* (MaxH./R) .* sqrt((R./(AssumedVp./Maxk)).^2 - SphereRayp(1).^2);
        k = kMin:kDelta:kMax;
        Hps = 1./(sqrt((R./(AssumedVp./k)).^2 - SphereRayp(1).^2) - sqrt((R./AssumedVp).^2 - SphereRayp(1).^2)) .* (tps.*R);
        Hpp = 1./(sqrt((R./(AssumedVp./k)).^2 - SphereRayp(1).^2) + sqrt((R./AssumedVp).^2 - SphereRayp(1).^2)) .* (tpp.*R);
        Hss = (tss.*R) ./ (2 .* sqrt((R./(AssumedVp./k)).^2 - SphereRayp(1).^2));


        %---------------------------------------------------------------------%
        %                                                                     %
        %                                                                     %
        % Plot the H-k stacking results for this station                      %
        %                                                                     %
        %                                                                     %
        %---------------------------------------------------------------------%
        if doPlot == 1
            fig1 = figure ('NumberTitle','off','Units','characters','Resize','off','Name',['H-k Stack: ' StationList{n}],...
                'Position',[0 0 110 45],'PaperPositionMode','auto','Color',[1 1 1],'Visible','on','CreateFcn',{@movegui_kce,'center'});
            uicontrol('Parent',fig1,'Style','text','Units','normalized','String',['Station: ' StationList{n}],...
                'Position',[.1 .94 .8 .05],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',14);
            axes ('Units','normalized','Clipping','off','Box','on','Layer','top','TickDir','out','Position',[.1 .1 .8 .8]);
            colormap('gray');
            cmap = colormap;
            cmap = flipdim(cmap,1);
            colormap(cmap)
            imagesc(kAxis,HAxis,HKAmps);
            line(Maxk,MaxH,'marker','o','markeredgecolor',[1 1 1],'markerfacecolor',[1 1 1]);
            ylabel('Depth (km)');
            xlabel('Vp/Vs');
            title(['Moho = ' num2str(MaxH,'%.1f') ' \pm ' num2str(MaxHsig,'%.1f')  ' km'...
                ', Vp/Vs = ' num2str(Maxk,'%.2f') ' \pm ' num2str(Maxksig,'%.2f')...
                ', Poisson''s Ratio = ' num2str(PoissonRatio,'%.3f') ' \pm ' num2str(PoissonRatioError,'%.3f')])
            caxis([0.67 1])
            colorbar('ylim',[0 1]);
            if Error == 2
                if length(NumContours) == 1
                    line(c(1,2:end),c(2,2:end),'Color',[1 1 1])
                else
                    for m = 1:length(NumContours)
                        if m == 1
                            line(c(1,2:NumContours(m+1)-1),c(2,2:NumContours(m+1)-1),'Color',[1 1 1])
                        elseif m == length(NumContours)
                            line(c(1,NumContours(m)+1:end),c(2,NumContours(m)+1:end),'Color',[1 1 1])
                        else
                            line(c(1,NumContours(m)+1:NumContours(m+1)-1),c(2,NumContours(m)+1:NumContours(m+1)-1),'Color',[1 1 1])
                        end
                    end
                end
            end
            line(k,Hps,'Color',[1 0 0])
            line(k,Hpp,'Color',[0 0 1])
            line(k,Hss,'Color',[0 0 1])
            if Hps(1) > HMax
                if ~isempty(find(Hps<=HMax,1))
                    text(k(find(Hps>=HMax,1)),HMax,'Ps','Color',[1 0 0])
                end
            else
                text(k(1),Hps(1),'Ps','Color',[1 0 0])
            end
            if Hpp(1) > HMax
                if ~isempty(find(Hpp<=HMax,1))
                    text(k(find(Hpp<=HMax,1)),HMax,'Ps','Color',[1 0 0])
                end
            else
                text(k(1),Hpp(1),'PpPs','Color',[0 0 1])
            end
            if Hss(1) > HMax
                if ~isempty(find(Hss<=HMax,1))
                    text(k(find(Hss<=HMax,1)),HMax,'Ps','Color',[1 0 0])
                end
            else
                text(k(1),Hss(1),'PsPs','Color',[0 0 1])
            end
            FigDirectory = [ProjectDirectory 'FIGURES' filesep];
            if ~exist(FigDirectory,'dir')
                mkdir(FigDirectory)
            end
            FigDirectory = [FigDirectory 'hk' filesep];
            if ~exist(FigDirectory,'dir')
                mkdir(FigDirectory)
            end
            if CurrentSubsetIndex ~= 1
                FigDirectory = [FigDirectory SetName filesep];
                if ~exist(FigDirectory,'dir')
                    mkdir(FigDirectory)
                end
            end
            print(fig1,'-depsc2',[FigDirectory strrep(StationList{n},'-','_') '_hkgrid.eps']);        close(fig1)
            clear cvalue NumContours IndexOfMaxk RightContour

            %---------------------------------------------------------------------%
            %                                                                     %
            %                                                                     %
            % Plot the receiver function stacks for this station                  %
            %                                                                     %
            %                                                                     %
            %---------------------------------------------------------------------%
            TimeInc = str2double(FuncLabPreferences{1});
            TimeMin = str2double(FuncLabPreferences{4});
            TimeMax = str2double(FuncLabPreferences{5});
            ColorMapChoice = FuncLabPreferences{19};

            xlimits = [TimeMin TimeMax];
            xtics = [TimeMin:TimeInc:TimeMin+(TimeInc*10)];

            % Load in the seismograms from this table and gather into separate
            % matrices 
            %----------------------------------------------------------------------
            count = 0;
            for m = 1:size(CurrentRecords,1)
                if CurrentRecords{m,5} == 1 && ...
                        CurrentRecords{m,21} >= RayParameterMin && CurrentRecords{m,21} <= RayParameterMax && ...
                        CurrentRecords{m,22} >= BackazimuthMin && CurrentRecords{m,22} <= BackazimuthMax
                    count = count + 1;
                    Rayp(count) = CurrentRecords{m,21};
                    Baz(count) = CurrentRecords{m,22};
                    if count > 1
                        [TempAmps,Time] = fl_readseismograms([ProjectDirectory CurrentRecords{m,1} 'eqr']);
                        % Set NaN or inf values to some near 0 value
                        for idx=1:length(TempAmps)
                            if isnan(TempAmps(idx)) || isinf(TempAmps(idx))
                                TempAmps(idx) = 0.00001;
                            end
                        end
                        if length(TempAmps) ~= length(RRFAmps); RRFAmps(count,:) = interp1(Time,TempAmps,RRFTime); else; RRFAmps(count,:) = TempAmps; end
                        [TempAmps,Time] = fl_readseismograms([ProjectDirectory CurrentRecords{m,1} 'eqt']);
                        % Set NaN or inf values to some near 0 value
                        for idx=1:length(TempAmps)
                            if isnan(TempAmps(idx)) || isinf(TempAmps(idx))
                                TempAmps(idx) = 0.00001;
                            end
                        end
                        if length(TempAmps) ~= length(TRFAmps); TRFAmps(count,:) = interp1(Time,TempAmps,TRFTime); else TRFAmps(count,:) = TempAmps; end
                    else
                        [TempAmps,Time] = fl_readseismograms([ProjectDirectory CurrentRecords{m,1} 'eqr']);
                        % Set NaN or inf values to some near 0 value
                        for idx=1:length(TempAmps)
                            if isnan(TempAmps(idx)) || isinf(TempAmps(idx))
                                TempAmps(idx) = 0.00001;
                            end
                        end
                        RRFAmps(count,:) = TempAmps; RRFTime = Time;
                        [TempAmps,Time] = fl_readseismograms([ProjectDirectory CurrentRecords{m,1} 'eqt']);
                        % Set NaN or inf values to some near 0 value
                        for idx=1:length(TempAmps)
                            if isnan(TempAmps(idx)) || isinf(TempAmps(idx))
                                TempAmps(idx) = 0.00001;
                            end
                        end
                        TRFAmps(count,:) = TempAmps; TRFTime = Time;
                    end
                end
            end

            % Normalize the waveforms
            %----------------------------------------------------------------------
            for m = 1:count
                RRFAmps(m,:) = RRFAmps(m,:) / max(abs(RRFAmps(m,:)));
                TRFAmps(m,:) = TRFAmps(m,:) / max(abs(RRFAmps(m,:)));
            end

            % Compute the predicted arrivals of Ps, PpPs, and PpSs+PsPs from
            % 1-layer crustal model (Vp = 6.5; dz = 35;)
            %----------------------------------------------------------------------
            R = 6371;
            MoveRayP = skm2srad(0.06);
            Vp = 6.5;
            Vp = AssumedVp;
            dz = 35;
            dz = MaxH;

            VpVs1 = 1.7;
            tps1 = (sqrt((R./(Vp./VpVs1)).^2 - MoveRayP.^2) - sqrt((R./Vp).^2 - MoveRayP.^2)) .* (dz./R);
            tpp1 = (sqrt((R./(Vp./VpVs1)).^2 - MoveRayP.^2) + sqrt((R./Vp).^2 - MoveRayP.^2)) .* (dz./R);
            tss1 = sqrt((R./(Vp./VpVs1)).^2 - MoveRayP.^2) .* (2.*(dz./R));
            VpVs2 = 1.8;
            tps2 = (sqrt((R./(Vp./VpVs2)).^2 - MoveRayP.^2) - sqrt((R./Vp).^2 - MoveRayP.^2)) .* (dz./R);
            tpp2 = (sqrt((R./(Vp./VpVs2)).^2 - MoveRayP.^2) + sqrt((R./Vp).^2 - MoveRayP.^2)) .* (dz./R);
            tss2 = sqrt((R./(Vp./VpVs2)).^2 - MoveRayP.^2) .* (2.*(dz./R));
            VpVs3 = 1.9;
            tps3 = (sqrt((R./(Vp./VpVs3)).^2 - MoveRayP.^2) - sqrt((R./Vp).^2 - MoveRayP.^2)) .* (dz./R);
            tpp3 = (sqrt((R./(Vp./VpVs3)).^2 - MoveRayP.^2) + sqrt((R./Vp).^2 - MoveRayP.^2)) .* (dz./R);
            tss3 = sqrt((R./(Vp./VpVs3)).^2 - MoveRayP.^2) .* (2.*(dz./R));

            aps = max(max(((sum(RRFAmps,1)./size(RRFAmps,1))+max(max(RRFAmps)))));
            app = max(max(((sum(RRFAmps,1)./size(RRFAmps,1))+max(max(RRFAmps)))));
            ass = max(max(((sum(RRFAmps,1)./size(RRFAmps,1))+max(max(RRFAmps)))));
            % aps = 1;
            % app = 1;
            % ass = 1;

            fig2 = figure ('Units','characters','NumberTitle','off','WindowStyle','normal','MenuBar','figure',...
                'Position',[0 0 150 40],'PaperPositionMode','auto','Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});

            % Radial Receiver Functions
            %----------------------------------------------------------------------
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
            if isnan(max(max(((sum(RRFAmps,1)./size(RRFAmps,1))))))
                ymax = 1;
            else
                ymax = max(max(((sum(RRFAmps,1)./size(RRFAmps,1))+max(max(RRFAmps)))));
            end
            set(s4,'Box','off','Units','normalized','Color',[1 1 1],'TickDir','out','FontSize',10,'YLim',ylimits,'YTick',ytics,'XLim',xlimits,'XTick',xtics);
            set(s4,'YLim',[min(min(RRFAmps)) ymax]);
            t4 = uicontrol('Parent',fig2,'Style','text','Units','normalized','String','Rad. RFs','Position',[.88 .5 .1 .025],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',10);
            xl5 = xlabel(s4,'Time (sec)','FontName','FixedWidth','FontSize',10);
            tt = uicontrol('Parent',fig2,'Style','text','Units','normalized','String',['Station: ' StationList{n}],...
                'Position',[.1 .9 .8 .05],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',14);
            LegendLabels = {[num2str(dz,'%.0f') ' km crust'];
                ['Assumed Vp = ' num2str(Vp,'%.1f') ' km/s']
                'Vp/Vs for Symbols';
                ['Circle = ' num2str(VpVs1,'%.2f')];
                ['Diamond = ' num2str(VpVs2,'%.2f')];
                ['Square = ' num2str(VpVs3,'%.2f')];};

            uicontrol('Parent',fig2,'Style','text','Units','normalized','String',LegendLabels,...
                'Position',[.75 .7 .2 .24],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontUnits','normalized','FontSize',0.1);

            set(fig2,'Name',[StationList{n} ' - Stacked Records']);
            set(s4,'Units','normalized'); set(s4,'FontUnits','normalized');
            set(t4,'Units','normalized'); set(t4,'FontUnits','normalized');
            set(xl5,'Units','normalized'); set(xl5,'FontUnits','normalized');
            set(tt,'Units','normalized'); set(tt,'FontUnits','normalized');
            print(fig2,'-depsc2',[FigDirectory strrep(StationList{n},'-','_') '_rfstacks.eps']);
            close(fig2)

            %---------------------------------------------------------------------%
            %                                                                     %
            %                                                                     %
            % Plot the receiver function moveout for this station                 %
            %                                                                     %
            %                                                                     %
            %---------------------------------------------------------------------%
            ytics = TimeMin:TimeInc:TimeMin+(TimeInc*10);

            RaypMin = str2double(get(h.raypmin_e,'string'));
            RaypMax = str2double(get(h.raypmax_e,'string'));
            RaypInc = str2double(FuncLabPreferences{2});
            ColorMapChoice = FuncLabPreferences{19};

            % RaypMin = 0.04;
            % RaypMax = 0.08;
            % RaypInc = 0.005;
            rpaxis = RaypMin:RaypInc:RaypMax;

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
            for m = 1:NumberOfBins
                BinLowCutoff = BinMinimum + ((m-1) * BinWidth);
                BinHighCutoff = BinMinimum + (m * BinWidth);
                BinIndices = find (BinInformation > BinLowCutoff & BinInformation <= BinHighCutoff);
                BinTraceCount(m) = length(BinIndices);
                count = 0;
                if BinTraceCount(m) > 0
                    TempRRFAmps = RRFAmps(BinIndices,:)./max(RRFAmps(BinIndices,:),2);
                    TempTRFAmps = TRFAmps(BinIndices,:)./max(RRFAmps(BinIndices,:),2);
                    nramps(m,:) = mean(TempRRFAmps,1);
                    ntamps(m,:) = mean(TempTRFAmps,1);
                end
            end

            Depths = MaxH;
            Vp = AssumedVp;
            VpVs = Maxk;
            Vs = Vp ./ VpVs;
            dz = Depths;
            R = 6371 - Depths';
            p = [0.035:0.001:0.085]; % ray parameters (s/km)

            for m = 1:length(p)
                MoveRayP = skm2srad (p(m));
                Tps(1,m) = cumsum((sqrt((R./Vs).^2 - MoveRayP^2) - sqrt((R./Vp).^2 - MoveRayP^2)) .* (dz./R));
                Tpp(1,m) = cumsum((sqrt((R./Vs).^2 - MoveRayP^2) + sqrt((R./Vp).^2 - MoveRayP^2)) .* (dz./R));
                Tss(1,m) = cumsum(sqrt((R./Vs).^2 - MoveRayP^2) .* (2*dz./R));
            end

            fig3 = figure ('Name',[StationList{n} ' - Receiver Functions'],'Units','characters','NumberTitle','off','PaperPositionMode','auto',...
                'WindowStyle','normal','MenuBar','figure','Position',[0 0 180 58],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});
            uicontrol('Parent',fig3,'Style','text','Units','normalized','String',['Station: ' StationList{n}],...
                'Position',[.1 .94 .8 .05],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',14);

            s1 = axes('Parent',fig3,'Units','characters','Position',[10 5 65 42]);
            set(fig3,'RendererMode','manual','Renderer','painters');
            p1 = pcolor(s1,rpmatrix-(RaypInc/2),RRFTimeMatrix,nramps');
            set(p1,'LineStyle','none')

            line(p,Tps,'Parent',s1,'Color','k','LineWidth',2);
            line(p,Tpp,'Parent',s1,'Color','k','LineStyle',':','LineWidth',2);
            line(p,Tss,'Parent',s1,'Color','k','LineStyle',':','LineWidth',2);
            text(RaypMax+0.001,Tps(end),'Ps','Parent',s1)
            text(RaypMax+0.001,Tpp(end),'PpPs','Parent',s1)
            text(RaypMax+0.001,Tss(end),{'PsPs','+','PpSs'},'Parent',s1)

            set(s1,'Box','on','Units','normalized','Color',[1 1 1],'YDir','reverse','TickDir','out','XTick',rpaxis,'YTick',ytics,'clipping','off');
            axis(s1,[RaypMin RaypMax TimeMin TimeMax])
            set(s1,'clipping','on');
            %a = makeColorMap([1 0 0],[1 1 1],[0 0 1]);
            %a = makeColorMap([0 10/255 160/255], [1 1 1], [160/255 10/255 0]);
            %colormap(a);
            if FuncLabPreferences{20} == false
                cmap = cptcmap(FuncLabPreferences{19});
            else
                cmap = cptcmap(FuncLabPreferences{19},'flip',true);
            end
            colormap(cmap);

            caxis([-0.1 0.1])
    %         t1 = title(s1,'Radial RF');
    %         t1pos = get(t1,'position');
    %         set(t1,'position',[t1pos(1) t1pos(2)-5 t1pos(3)]);
            ylabel(s1,'Time (sec)');
            xlabel(s1,'Ray Parameter (sec/km)');

            h1 = axes('Parent',fig3,'Units','characters','Position',[10 47 65 6]);
            bar(h1,rpaxis,BinTraceCount,'k')
            set(h1,'Box','on','XAxisLocation','top','XTickLabel',[],'XTick',[],'TickDir','out')
            axis(h1,[RaypMin RaypMax 0 max(BinTraceCount)])
            ylabel(h1,'Trace Count')
            yticks = get(h1,'YTick');
            set(h1,'YTick',yticks(2:end),'Units','normalized')
            t1=title(h1,'Radial RF');

            s2 = axes('Parent',fig3,'Units','characters','Position',[85 5 65 42]);
            set(fig3,'RendererMode','manual','Renderer','painters');
            p2 = pcolor(s2,rpmatrix-(RaypInc/2),TRFTimeMatrix,ntamps');
            set(p2,'LineStyle','none');
            set(s2,'Box','on','Units','normalized','Color',[1 1 1],'YDir','reverse','TickDir','out','XTick',rpaxis,'YTick',ytics,'YAxisLocation','right');
            axis(s2,[RaypMin RaypMax TimeMin TimeMax])
            %colormap(a);
            if FuncLabPreferences{20} == false
                cmap = cptcmap(FuncLabPreferences{19});
            else
                cmap = cptcmap(FuncLabPreferences{19},'flip',true);
            end
            colormap(cmap);

            caxis([-0.1 0.1])
    %         t2 = title(s2,'Transverse RF');
    %         t2pos = get(t2,'position');
    %         set(t2,'position',[t2pos(1) t2pos(2)-5 t2pos(3)]);
            xlabel(s2,'Ray Parameter (sec/km)');

            h2 = axes('Parent',fig3,'Units','characters','Position',[85 47 65 6]);
            bar(h2,rpaxis,BinTraceCount,'k')
            set(h2,'Box','on','XAxisLocation','top','XTickLabel',[],'XTick',[],'TickDir','out','YAxisLocation','right')
            axis(h2,[RaypMin RaypMax 0 max(BinTraceCount)])
            yticks = get(h2,'YTick');
            set(h2,'YTick',yticks(2:end),'Units','normalized')
            t2=title(h2,'Transverse RF');

            c1 = colorbar('peer',s2);
            set(c1,'Parent',fig3,'Units','characters','Position',[160 5 2.5 48])
            set(get(c1,'YLabel'),'String','Amplitude');
            print(fig3,'-depsc2',[FigDirectory strrep(StationList{n},'-','_') '_rfmoveout.eps']);
            close(fig3)

            %---------------------------------------------------------------------%
            %                                                                     %
            %                                                                     %
            % Plot the receiver function backazimuth plot for this station        %
            %                                                                     %
            %                                                                     %
            %---------------------------------------------------------------------%
            BazMin = str2double(get(h.bazmin_e,'string'));
            BazMax = str2double(get(h.bazmax_e,'string'));
            BazInc = str2double(FuncLabPreferences{3});
            ColorMapChoice = FuncLabPreferences{19};

            % BazMin = 0;
            % BazMax = 360;
            % BazInc = 45;
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
            BinTraceCount = [];
            for m = 1:NumberOfBins
                BinLowCutoff = BinMinimum + ((m-1) * BinWidth);
                BinHighCutoff = BinMinimum + (m * BinWidth);
                BinIndices = find (BinInformation > BinLowCutoff & BinInformation <= BinHighCutoff);
                BinTraceCount(m) = length(BinIndices);
                count = 0;
                if BinTraceCount(m) > 0
                    TempRRFAmps = RRFAmps(BinIndices,:)./max(RRFAmps(BinIndices,:),2);
                    TempTRFAmps = TRFAmps(BinIndices,:)./max(RRFAmps(BinIndices,:),2);
                    nramps(m,:) = mean(TempRRFAmps,1);
                    ntamps(m,:) = mean(TempTRFAmps,1);
                end
            end

            fig4 = figure ('Name',[StationList{n} ' - Receiver Functions Backazimuth Image'],'Units','characters','NumberTitle','off','PaperPositionMode','auto',...
                'WindowStyle','normal','MenuBar','figure','Position',[0 0 180 58],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});
            uicontrol('Parent',fig4,'Style','text','Units','normalized','String',['Station: ' StationList{n}],...
                'Position',[.1 .94 .8 .05],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',14);

            s1 = axes('Parent',fig4,'Units','characters','Position',[10 5 65 42]);
            set(fig4,'RendererMode','manual','Renderer','painters');
            p1 = pcolor(s1,bmatrix-(BazInc/2),RRFTimeMatrix,nramps');
            set(p1,'LineStyle','none')
            set(s1,'Box','on','Units','normalized','Color',[1 1 1],'YDir','reverse','TickDir','out','XTick',baxis,'YTick',ytics);
            axis(s1,[BazMin BazMax TimeMin TimeMax])
            set(s1,'Clipping','on')
            %a = makeColorMap([1 0 0],[1 1 1],[0 0 1]);
            %a = makeColorMap([0 10/255 160/255], [1 1 1], [160/255 10/255 0]);
            %colormap(a);
            if FuncLabPreferences{20} == false
                cmap = cptcmap(FuncLabPreferences{19});
            else
                cmap = cptcmap(FuncLabPreferences{19},'flip',true);
            end
            colormap(cmap);

            caxis([-0.1 0.1])
    %         t1 = title(s1,'Radial RF');
    %         t1pos = get(t1,'position');
    %         set(t1,'position',[t1pos(1) t1pos(2)-5 t1pos(3)]);
            ylabel(s1,'Time (sec)');
            xlabel(s1,'Event Backazimuth (deg)');

            line([0 360],[Tps(find(p >= 0.06,1)) Tps(find(p >= 0.06,1))],'Parent',s1,'Color','k','LineWidth',2);
            line([0 360],[Tpp(find(p >= 0.06,1)) Tpp(find(p >= 0.06,1))],'Parent',s1,'Color','k','LineStyle',':','LineWidth',2);
            line([0 360],[Tss(find(p >= 0.06,1)) Tss(find(p >= 0.06,1))],'Parent',s1,'Color','k','LineStyle',':','LineWidth',2);
            text(375,Tps(end),'Ps','Parent',s1)
            text(375,Tpp(end),'PpPs','Parent',s1)
            text(375,Tss(end),{'PsPs','+','PpSs'},'Parent',s1)

            h1 = axes('Parent',fig4,'Units','characters','Position',[10 47 65 6]);
            bar(h1,baxis,BinTraceCount,'k')
            set(h1,'Box','on','XAxisLocation','top','XTickLabel',[],'XTick',[],'TickDir','out')
            axis(h1,[BazMin BazMax 0 max(BinTraceCount)])
            ylabel(h1,'Trace Count')
            yticks = get(h1,'YTick');
            set(h1,'YTick',yticks(2:end),'Units','normalized')
            t1=title(h1,'Radial RF');


            s2 = axes('Parent',fig4,'Units','characters','Position',[85 5 65 42]);
            set(fig4,'RendererMode','manual','Renderer','painters');
            p2 = pcolor(s2,bmatrix-(BazInc/2),TRFTimeMatrix,ntamps');
            set(p2,'LineStyle','none');
            set(s2,'Box','on','Units','normalized','Color',[1 1 1],'YDir','reverse','TickDir','out','XTick',baxis,'YTick',ytics,'YAxisLocation','right');
            axis(s2,[BazMin BazMax TimeMin TimeMax])
            if FuncLabPreferences{20} == false
                cmap = cptcmap(FuncLabPreferences{19});
            else
                cmap = cptcmap(FuncLabPreferences{19},'flip',true);
            end
            colormap(cmap);

            caxis([-0.1 0.1])
    %         t2 = title(s2,'Transverse RF');
    %         t2pos = get(t2,'position');
    %         set(t2,'position',[t2pos(1) t2pos(2)-5 t2pos(3)]);
            xlabel(s2,'Event Backazimuth (deg)');

            line([0 360],[Tps(find(p >= 0.06,1)) Tps(find(p >= 0.06,1))],'Parent',s2,'Color','k','LineWidth',2);
            line([0 360],[Tpp(find(p >= 0.06,1)) Tpp(find(p >= 0.06,1))],'Parent',s2,'Color','k','LineStyle',':','LineWidth',2);
            line([0 360],[Tss(find(p >= 0.06,1)) Tss(find(p >= 0.06,1))],'Parent',s2,'Color','k','LineStyle',':','LineWidth',2);

            h2 = axes('Parent',fig4,'Units','characters','Position',[85 47 65 6]);
            bar(h2,baxis,BinTraceCount,'k')
            set(h2,'Box','on','XAxisLocation','top','XTickLabel',[],'XTick',[],'TickDir','out','YAxisLocation','right')
            axis(h2,[BazMin BazMax 0 max(BinTraceCount)])
            yticks = get(h2,'YTick');
            set(h2,'YTick',yticks(2:end),'Units','normalized')
            t1=title(h2,'Transverse RF');

            c1 = colorbar('peer',s2);
            set(c1,'Parent',fig4,'Units','characters','Position',[160 5 2.5 48])
            set(get(c1,'YLabel'),'String','Amplitude');
            print(fig4,'-depsc2',[FigDirectory strrep(StationList{n},'-','_') '_rfbaz.eps']);
            close(fig4)
        else
            fprintf('HK stacking results for %s. H: %3.1f +/- %3.1f. k: %3.2f +/- %3.2f\n',StationList{n}, MaxH, MaxHsig, Maxk, Maxksig)
        end
        
        if n ~= length(StationList)
            ClearVariables = who;
            KeepVariables = {'FuncLabPreferences','H','ProjectDirectory','ProjectFile',...
                'RecordMetadataDoubles','RecordMetadataStrings','StationList','WaitGui',...
                'cbo','cr','eventdata','h','n','ColorMapChoice','ResampleNumber','RandomSelectionCount',...
                'RayParameterMin','RayParameterMax','BackazimuthMin','BackazimuthMax','TimeMin','TimeMax',...
                'TimeDelta','AssumedVp','HMin','HMax','HDelta','kMax','kMin','kDelta','w1','w2','w3','Error',...
                'ManualTimeFlag','CurrentSubsetIndex','SetManagementCell','SetName','doPlot'};
            ClearVariables(ismember(ClearVariables,KeepVariables)) = [];
            clear(ClearVariables{:},'KeepVariables','ClearVariables')
        end
    end
end

% Save H-k table to the project file (WARNING: THIS OVERWRITES EXISTING HK)
%--------------------------------------------------------------------------
save([ProjectDirectory ProjectFile],'HkMetadataStrings','HkMetadataDoubles','HkMetadataCell','-append');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Edit the Project file so that H-k tables can be viewed in FuncLab
%--------------------------------------------------------------------------
%load([ProjectDirectory ProjectFile],'Tablemenu')
Tablemenu = SetManagementCell{CurrentSubsetIndex,4};
if isempty(strmatch('HkMetadata',Tablemenu(:,2)))
    Tablemenu = vertcat(Tablemenu,{'H-k Tables','HkMetadata',3,2,'Tables: ','Records (Listed by Station)','Stations: ','hk_record_fields'});
    save([ProjectDirectory ProjectFile],'Tablemenu','-append')
    assignin('base','Tablemenu',Tablemenu)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




% Allow the results to be exported via the main menu
hdls = findobj('Tag','ex_hk_res_m');
set(hdls,'Enable','on');

% Update the Log File
%--------------------------------------------------------------------------
LogFile = [ProjectDirectory 'Logfile.txt'];
CTime = clock;
NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - H-k Stacking Set: %s',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6),SetName);
NewLog{2} = ['     1. Bootstrap resamples: ' num2str(ResampleNumber) ' times'];
NewLog{3} = ['     2. Bootstrap selection percentage: ' num2str(RandomSelectionCount) '%'];
NewLog{4} = ['     3. H max: ' num2str(HMax) ' km'];
NewLog{5} = ['     4. H min: ' num2str(HMin) ' km'];
NewLog{6} = ['     5. k max: ' num2str(kMax)];
NewLog{7} = ['     6. k min: ' num2str(kMin)];
NewLog{8} = ['     7. Weight 1 (Ps): ' num2str(w1)];
NewLog{9} = ['     8. Weight 2 (PpPs): ' num2str(w2)];
NewLog{10} = ['     9. Weight 3 (PpSs+PsPs): ' num2str(w3)];
NewLog{11} = ['     10. Assumed Vp: ' num2str(AssumedVp) ' km/s'];
NewLog{12} = ['     11. Ray parameter range: ' num2str(RayParameterMin) ' to ' num2str(RayParameterMax) ' s/km'];
NewLog{13} = ['     12. Backazimuth range: ' num2str(BackazimuthMin) ' to ' num2str(BackazimuthMax) ' s/km'];
t_temp = toc;
NewLog{14} = ['     13. H-k stacking took ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).'];
fl_edit_logfile(LogFile,NewLog)
close(WaitGui)
set(h.MainGui.message_t,'String',['Message: H-k Stacking: Stacking took ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).'])
set(h.MainGui.tablemenu_pu,'String',Tablemenu(:,1))