function ccp_assign(cbo,eventdata,handles)
%CCP_ASSIGN Assign traces to CCP bins
%   CCP_ASSIGN is a callback function that assigns each trace to the
%   appropriate CCP (common conversion point) bin at each depth.  Piercing
%   points are computed for each record and binned based on proximity to
%   the mid-point of the bin.

%   Author: Kevin C. Eagar
%   Date Created: 05/10/2007
%   Last Updated: 05/18/2010

%Time the runtime of this function.
%--------------------------------------------------------------------------
tic

% Get the handles of the FuncLab GUI
%--------------------------------------------------------------------------
h = guidata(gcbf);

% Wait message
%--------------------------------------------------------------------------
% WaitGui = dialog ('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
%     'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
% uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
%     'String','Please wait, assigning traces to CCP bins.',...
%     'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
% drawnow;
% H = guihandles(WaitGui);
% guidata(WaitGui,H);
WaitGui = waitbar(0,'Please wait, assigning traces to CCP bins.');


ProjectDirectory = evalin('base','ProjectDirectory');
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
if CurrentSubsetIndex == 1
    CCPMatFile = fullfile(ProjectDirectory, 'CCPData', 'CCPData.mat');
else
    CCPMatFile = fullfile(ProjectDirectory, 'CCPData', SetName, 'CCPData.mat');
end



% Set parameters for the CCP 3D grid
%--------------------------------------------------------------------------
LatMin = str2double(get(h.latmin_e,'string'));
LatMax = str2double(get(h.latmax_e,'string'));
LonMin = str2double(get(h.lonmin_e,'string'));
LonMax = str2double(get(h.lonmax_e,'string'));
BinSpacing = str2double(get(h.binspacing_e,'string'));
MinBinWidth = str2double(get(h.minbinwidth_e,'string'));
MaxBinWidth = str2double(get(h.maxbinwidth_e,'string'));
minhits = str2double(get(h.hitsmin_e,'string'));

BinSize = str2double(get(h.minbinwidth_e,'string'));

% Compute the CCP grid and store in a matrix
%--------------------------------------------------------------------------
CCPGrid = ccp_setup_grid(LatMin,LatMax,LonMin,LonMax,BinSpacing,MinBinWidth);

Rays = who('-file',CCPMatFile,'RayMatrix*');
for n = 1:length(Rays) % Each RayMatrix (one per 15,000 rays)
    load(CCPMatFile,Rays{n})
    RayMatrix = eval(Rays{n});
    clear(Rays{n})
    kk=0;
    nptsTotal = size(CCPGrid,1) * size(RayMatrix,1);
    nptsUpdate = floor(nptsTotal / 100);
    for m = 1:size(CCPGrid,1) % Each Bin
        for k = 1:size(RayMatrix,1) % Each Depth
            lons = RayMatrix(k,:,4) * pi/180;
            lats = RayMatrix(k,:,3) * pi/180;
            tlon = CCPGrid{m,2} * pi/180;
            tlat = CCPGrid{m,1} * pi/180;
            dlon = lons - tlon;
            dlat = lats - tlat;
            a = (sin(dlat/2)).^2 + cos(lats) .* cos(tlat) .* (sin(dlon/2)).^2;
            angles = 2 .* atan2(sqrt(a),sqrt(1-a));
            dist = 6371 * angles;
            
            
            
            % This sections causes bin to dilatate to depth to fit a
            % minimum number of hits in the CCP Grid
            %--------------------------------------------------------------
            
            
            kmperdeg = 2*pi*6371*sind(90-CCPGrid{m,1})/360;
            %MinBinWidth = CCPGrid{m,3};
            MinBinR = MinBinWidth/2; % Bin radius
            MaxBinR = MaxBinWidth/2;
            Indx = find(dist <= MinBinWidth*kmperdeg); % This ONLY takes RFs falling into the bin
            %initBinR = MinBinWidth/2;
            dBinR = 0.05;   % Increases bin width 0.1 degree per search
            inbin = length(Indx);
            Hits = inbin;
            %CCPGrid{m,6} = inbin;
            for dR = MinBinR+dBinR:dBinR:MaxBinR   % goes in incs of 0.05 degs radius to max R
                if inbin < minhits
                    dr = dR * kmperdeg;
                    Indx = find(dist <= dr); % This ONLY takes RFs falling into the bin
                    inbin1 = length(Indx);
                    %CCPGrid{m,6} = inbin1;
                    Hits = inbin1;
                    if inbin1 >= minhits
                        Diam = dR*2; % Bin diameter
                        Hits = inbin1;
                        %CCPGrid{m,3} = dR*2; % Bin diameter
                        break
                    else
                        Diam = dR*2; % Bin diameter
                        %Hits = 0;
                    end
                elseif inbin >= minhits
                    Diam = MinBinR*2; % Bin diameter
                    Hits = inbin;
                    %CCPGrid{m,3} = MinBinR*2; % Bin diameter
                %else
                    %TempDiam{k,1} = NaN;
                    %CCPGrid{m,3} = NaN;                    
                end
            end
            
            TempDiam{k,1} = Diam;
            Temphits{k,1} = Hits; 
            %Indx = find(dist <= CCPGrid{m,3}); % This ONLY takes RFs falling into the bin
            Temp{k,1} = RayMatrix(k,Indx,7); % Record IDs
            TempDist{k,1} = dist(Indx);
            if ~isempty(Indx)
                disp('')
            end
        
            
            kk=kk+1;
            if mod(kk,nptsUpdate)
                waitbar(kk/nptsTotal,WaitGui)
            end
        end
        CCPGrid{m,3} = [CCPGrid{m,3} TempDiam];
        CCPGrid{m,4} = [CCPGrid{m,4} Temp];
        CCPGrid{m,5} = [CCPGrid{m,5} TempDist];
        CCPGrid{m,6} = [CCPGrid{m,6} Temphits];
    end
    clear RayMatrix
end
save(CCPMatFile,'CCPGrid','-append')

% Update the Log File
%--------------------------------------------------------------------------
LogFile = [ProjectDirectory 'Logfile.txt'];
CTime = clock;
NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - CCP Stacking: Bin Assignment. Set %s',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6),SetName);
NewLog{2} = ['     1. Latitude range: ' num2str(LatMin) ' to ' num2str(LatMax)];
NewLog{3} = ['     2. Longitude range: ' num2str(LonMin) ' to ' num2str(LonMax)];
NewLog{4} = ['     3. Grid spacing: ' num2str(BinSpacing) ' km'];
NewLog{5} = ['     4. Bin size: ' num2str(BinSize) ' km radius'];
t_temp = toc;
NewLog{6} = ['     5. CCP assignment took ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).'];
fl_edit_logfile(LogFile,NewLog)
delete(WaitGui)
set(h.MainGui.message_t,'String',['Message: CCP Stacking: Bin assignment took ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).'])
set(h.bootresamples_e,'Enable','on')
set(h.bootpercent_e,'Enable','on')
set(h.raypmin_e,'Enable','on')
set(h.raypmax_e,'Enable','on')
set(h.bazmin_e,'Enable','on')
set(h.bazmax_e,'Enable','on')
set(h.vertoverlap_e,'Enable','off')
set(h.hitsmin_e,'Enable','on')
set(h.ccpstacking_b,'Enable','on')