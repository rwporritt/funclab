function gccp_stacking(cbo,eventdata,handles)
%GCCP_STACKING Common conversion point stacking
%   GCCP_STACKING is a callback function that takes each depth interval in
%   the depth axis created by the time-to-depth migration for the project,
%   and computes GCCP (common conversion point) stacks for bins.  Piercing
%   points are computed for each record and binned based on proximity to
%   the mid-point of the bin.  These traces are stacked.
%
%   10/17/2008
%   I added the discontinuity peak picks from each bootstrap iteration and
%   put them into the gccp table.
%
%   10/20/2008
%   I added the output of the amplitudes associated with each depth pick.
%   These are temporarily placed into the "P410sDepthError" and
%   "P660sDepthError" fields until I change these headers to the
%   appropriate title.
%
%   10/26/3008
%   Fixed a glich to include the backazimuth and ray parameter ranges when
%   picking records to include in the stacks.

%   Author: Kevin C. Eagar
%   Date Created: 09/13/2007
%   Last Updated: 11/21/2011

%Time the runtime of this function.
%--------------------------------------------------------------------------
tic

% Get the handles of the FuncLab GUI
%--------------------------------------------------------------------------
h = guidata(gcbf);

% Wait message
%--------------------------------------------------------------------------
WaitGui = dialog ('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
    'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
    'String','Please wait, computing Gaussian-weighted common-conversion-point stacks.',...
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
if CurrentSubsetIndex == 1
    GCCPMatFile = fullfile(ProjectDirectory, 'GCCPData', 'GCCPData.mat');
    GCCPBinLead = ['GCCPData' filesep 'Bin_'];
else
    GCCPMatFile = fullfile(ProjectDirectory, 'GCCPData', SetName, 'GCCPData.mat');
    GCCPBinLead = ['GCCPData' filesep SetName filesep 'Bin_'];
end

% Set initial values
%--------------------------------------------------------------------------
RayParameterMin = str2double(get(h.raypmin_e,'string'));
RayParameterMax = str2double(get(h.raypmax_e,'string'));
BackazimuthMin = str2double(get(h.bazmin_e,'string'));
BackazimuthMax = str2double(get(h.bazmax_e,'string'));
ResampleNumber = str2double(get(h.bootresamples_e,'string'));
RandomSelectionCount = str2double(get(h.bootpercent_e,'string'))/100;
DepthIncrement = str2num(get(h.depthinc_e,'string'));
DepthMax = str2num(get(h.depthmax_e,'string'));
Gaussian = evalin('base','RecordMetadataDoubles(1,7)');
TRFStack = get(h.trf_p,'string');

load(GCCPMatFile,'DepthAxis','GCCPGrid')
Rays = who('-file',GCCPMatFile,'RayMatrix*');

% 11/19/2011: SWITCHED THE FOR LOOP SO THAT YOU ARE FIRST LOOPING THROUGH
% THE RAY MATRICES TO GET THINGSS LOADED IN, THEN LOOPING THROUGH THE GCCP
% NODES TO STACK THE RFS
for n = 1:size(GCCPGrid,1) % For each bin
    tic
    for m = 1:length(Rays)
        load(GCCPMatFile,Rays{m})
        RayMatrix = eval(Rays{m});
        clear(Rays{m})
        Ids = GCCPGrid{1,4}{m}; % 11/19/2011: REFER TO THE MTH RAYMATRIX IN THE GCCPGRID
        
        % 11/19/2011: DELETED CALCULATION OF MAXHITS FOR THE BINS
        
        % Build 3 matrices with size(RayMatrix,1) columns and length(DepthAxis) rows
        %------------------------------------------------------------------
        Rtemp = NaN * ones(length(DepthAxis),size(RayMatrix,2)); % 11/19/2011: CHANGED THE SIZE OF THE PRE-MADE MATRIX TO LENGTH OF DEPTHAXIS AND LENGTH OF THE RAYMATRIX INSTEAD OF MAXHITS
        Ttemp = NaN * ones(length(DepthAxis),size(RayMatrix,2)); % 11/19/2011: CHANGED THE SIZE OF THE PRE-MADE MATRIX TO LENGTH OF DEPTHAXIS AND LENGTH OF THE RAYMATRIX INSTEAD OF MAXHITS
        Wtemp = NaN * ones(length(DepthAxis),size(RayMatrix,2)); % 11/19/2011: CHANGED THE SIZE OF THE PRE-MADE MATRIX TO LENGTH OF DEPTHAXIS AND LENGTH OF THE RAYMATRIX INSTEAD OF MAXHITS

        % Add the value in the RayMatrix using the RF indices to the
        % matrices we just built.
        for k = 1:length(DepthAxis) % 11/19/2011: CHANGED TO LOOP OVER THE DEPTHAXIS
            % 11/19/2011: CALCULATE DISTANCES FROM PIERCING POINT TO BIN NODE
            %--------------------------------------------------------------
            lons = RayMatrix(k,:,4) * pi/180;
            lats = RayMatrix(k,:,3) * pi/180;
            tlon = GCCPGrid{n,2} * pi/180;
            tlat = GCCPGrid{n,1} * pi/180;
            dlon = lons - tlon;
            dlat = lats - tlat;
            a = (sin(dlat/2)).^2 + cos(lats) .* cos(tlat) .* (sin(dlon/2)).^2;
            angles = 2 .* atan2(sqrt(a),sqrt(1-a));
            Dist = 6371 * angles;
            for l = 1:length(Ids)
%                 temp = find(RayMatrix(k,:,7) == Ids(l));
%                 if ~isempty(temp)   % 06/15/2011: ADDED IF STATEMENT TO CHECK IF THE RECORD IDS EXIST IN THIS MATRIX
                    Rtemp(k,l) = RayMatrix(k,l,1);
                    Ttemp(k,l) = RayMatrix(k,l,2);
                    Wtemp(k,l) = exp(-(Dist(l)).^2./(2.*GCCPGrid{n,3}.^2));
%                 end
            end
        end
        
        if exist('RRFAmps','var')
            RRFAmps = [RRFAmps Rtemp];
            TRFAmps = [TRFAmps Ttemp];
            Weights = [Weights Wtemp];
        else
            RRFAmps = Rtemp;
            TRFAmps = Ttemp;
            Weights = Wtemp;
        end
        
        clear RayMatrix*
    end
    
    if exist('RRFAmps','var')
        if ResampleNumber==1 % 11/20/2011: ADDED AN ?IF? STATEMENT FOR STRAIGHT LINEAR STACKING WITHOUT BOOTSTRAPPING
            RRFWeights = Weights .* RRFAmps;
            RRFBootSigma = NaN * ones(length(DepthAxis),1);
            TRFBootSigma = NaN * ones(length(DepthAxis),1);
            Check1 = isnan(RRFAmps);
            Check2 = 0;
            for m = 1:size(RRFAmps,1)
                if (any(Check1(m,:)) && ~all(Check1(m,:))); Check2 = 1; break; end
            end
            if Check2 == 0
                RRFBootMean = sum(RRFWeights,2)./sum(Weights,2);
            else
                RRFBootMean = ignoreNaN(RRFWeights,@sum,2)./ignoreNaN(Weights,@sum,2);
            end
            for k = 1:size(RRFAmps,1)
                TraceCount(k) = length(find(~isnan(RRFAmps(k,:))));
            end
            if strcmp(TRFStack,'On') % 11/20/2011: ADDED AN ?IF? STATEMENT TO CHECK IF TRANSVERSE RFS SHOULD BE STACKED
                TRFWeights = Weights .* TRFAmps;
                Check1 = isnan(TRFAmps);
                Check2 = 0;
                for m = 1:size(TRFAmps,1)
                    if (any(Check1(m,:)) && ~all(Check1(m,:))); Check2 = 1; break; end
                end
                if Check2 == 0
                    TRFBootMean = sum(TRFWeights,2)./sum(Weights,2);
                else
                    TRFBootMean = ignoreNaN(TRFWeights,@sum,2)./ignoreNaN(Weights,@sum,2);
                end
            else
                TRFBootMean = NaN * ones(length(DepthAxis),1);
            end
        else
            [RRFBootMean,RRFBootSigma,Peaks410,Peaks660,Amps410,Amps660] = gccp_bootstrap(RRFAmps,Weights,DepthAxis,ResampleNumber,round(size(RRFAmps,2)*RandomSelectionCount));
            if strcmp(TRFStack,'On') % 11/20/2011: ADDED AN ?IF? STATEMENT TO CHECK IF TRANSVERSE RFS SHOULD BE STACKED
                [TRFBootMean,TRFBootSigma,junk,junk,junk,junk] = gccp_bootstrap(TRFAmps,Weights,DepthAxis,ResampleNumber,round(size(TRFAmps,2)*RandomSelectionCount));
            else
                TRFBootMean = NaN * ones(length(DepthAxis),1);
                TRFBootSigma = NaN * ones(length(DepthAxis),1);
            end
            for k = 1:size(RRFAmps,1)
                TraceCount(k) = length(find(~isnan(RRFAmps(k,:))));
            end
        end
    else
        RRFBootMean = NaN * ones(length(DepthAxis),1);
        RRFBootSigma = NaN * ones(length(DepthAxis),1);
        TRFBootMean = NaN * ones(length(DepthAxis),1);
        TRFBootSigma = NaN * ones(length(DepthAxis),1);
        Peaks410 = NaN * ones(1,ResampleNumber);
        Peaks660 = NaN * ones(1,ResampleNumber);
        Amps410 = NaN * ones(1,ResampleNumber);
        Amps660 = NaN * ones(1,ResampleNumber);
        TraceCount = zeros(1,length(DepthAxis));
    end
    GCCPPath = [GCCPBinLead num2str(sprintf('%0.0f',n)) '_' num2str(BackazimuthMin,'%03.0f') ...
        num2str(BackazimuthMax,'%03.0f') '_' num2str(RayParameterMin*1000,'%03.0f') num2str(RayParameterMax*1000,'%03.0f') '.mat'];
    TableName = ['Baz=' num2str(BackazimuthMin,'%.0f') '-' num2str(BackazimuthMax,'%.0f') ...
        ' Rayp=' num2str(RayParameterMin,'%.3f') '-' num2str(RayParameterMax,'%.3f')];
    BinName = n;
    BootAxis = DepthAxis;    
    
    
    %%%%%%%%%%%%
    %%%%%%%%%%%%
    
    %if evalin('base',['exist(''GCCPMetadataStrings'',''var'')'])
    if evalin('base',['exist(''GCCPMetadataCell'',''var'')'])
        GCCPMetadataCell = evalin('base','GCCPMetadataCell');
        if isempty(GCCPMetadataCell{CurrentSubsetIndex, 1})
            % Populate the MetadataStrings
            %----------------------------------------------------------------------
            GCCPMetadataStrings(1,:) = {GCCPPath,TableName,BinName,TraceCount};
            % Populate the MetadataDoubles
            %----------------------------------------------------------------------
            GCCPMetadataDoubles(1,:) = [DepthIncrement,length(RRFBootMean),0,DepthMax,Gaussian,...
                BackazimuthMin,BackazimuthMax,RayParameterMin,RayParameterMax,...
                GCCPGrid{n,1},GCCPGrid{n,2},GCCPGrid{n,3}];
            GCCPMetadataCell = cell(size(SetManagementCell,1),2);
            GCCPMetadataCell{CurrentSubsetIndex,1} = GCCPMetadataStrings;
            GCCPMetadataCell{CurrentSubsetIndex,2} = GCCPMetadataDoubles;
        else
            if size(GCCPMetadataCell,1) < size(SetManagementCell,1);
                tmp = cell(size(SetManagementCell,1),2);
                for idx=1:size(GCCPMetadataCell,1)
                    tmp{idx,1} = GCCPMetadataCell{idx,1};
                    tmp{idx,2} = GCCPMetadataCell{idx,2};
                end
                GCCPMetadataCell = tmp;
            end
            if isempty(GCCPMetadataCell{CurrentSubsetIndex, 1})
                % Populate the MetadataStrings
                %----------------------------------------------------------------------
                GCCPMetadataStrings(1,:) = {GCCPPath,TableName,BinName,TraceCount};
                % Populate the MetadataDoubles
                %----------------------------------------------------------------------
                GCCPMetadataDoubles(1,:) = [DepthIncrement,length(RRFBootMean),0,DepthMax,Gaussian,...
                    BackazimuthMin,BackazimuthMax,RayParameterMin,RayParameterMax,...
                    GCCPGrid{n,1},GCCPGrid{n,2},GCCPGrid{n,3}];
                GCCPMetadataCell = cell(size(SetManagementCell,1),2);
                GCCPMetadataCell{CurrentSubsetIndex,1} = GCCPMetadataStrings;
                GCCPMetadataCell{CurrentSubsetIndex,2} = GCCPMetadataDoubles;
            end
            GCCPMetadataStrings = GCCPMetadataCell{CurrentSubsetIndex,1};
            GCCPMetadataDoubles = GCCPMetadataCell{CurrentSubsetIndex,2};
            %GCCPMetadataStrings = evalin('base','GCCPMetadataStrings');
            %GCCPMetadataDoubles = evalin('base','GCCPMetadataDoubles');
            % Check to make sure the record DOES NOT exist
            %----------------------------------------------------------------------
            if isempty(strmatch(GCCPPath,GCCPMetadataStrings(:,1)));
                % If it DOES NOT, add it to the end
                %------------------------------------------------------------------
                GCCPMetadataStrings(end+1,:) = {GCCPPath,TableName,BinName,TraceCount};
                GCCPMetadataDoubles(end+1,:) = [DepthIncrement,length(RRFBootMean),0,DepthMax,Gaussian,...
                    BackazimuthMin,BackazimuthMax,RayParameterMin,RayParameterMax,...
                    GCCPGrid{n,1},GCCPGrid{n,2},GCCPGrid{n,3}];
            else
                % If it DOES, replace it
                %------------------------------------------------------------------
                In = strmatch(GCCPPath,GCCPMetadataStrings(:,1));
                GCCPMetadataStrings(In,:) = {GCCPPath,TableName,BinName,TraceCount};
                GCCPMetadataDoubles(In,:) = [DepthIncrement,length(RRFBootMean),0,DepthMax,Gaussian,...
                    BackazimuthMin,BackazimuthMax,RayParameterMin,RayParameterMax,...
                    GCCPGrid{n,1},GCCPGrid{n,2},GCCPGrid{n,3}];
            end
        end
    else
        % Populate the MetadataStrings
        %----------------------------------------------------------------------
        GCCPMetadataStrings(1,:) = {GCCPPath,TableName,BinName,TraceCount};
        % Populate the MetadataDoubles
        %----------------------------------------------------------------------
        GCCPMetadataDoubles(1,:) = [DepthIncrement,length(RRFBootMean),0,DepthMax,Gaussian,...
            BackazimuthMin,BackazimuthMax,RayParameterMin,RayParameterMax,...
            GCCPGrid{n,1},GCCPGrid{n,2},GCCPGrid{n,3}];
        GCCPMetadataCell = cell(size(SetManagementCell,1),2);
        GCCPMetadataCell{CurrentSubsetIndex,1} = GCCPMetadataStrings;
        GCCPMetadataCell{CurrentSubsetIndex,2} = GCCPMetadataDoubles;
    end
    GCCPMetadataCell{CurrentSubsetIndex,1} = GCCPMetadataStrings;
    GCCPMetadataCell{CurrentSubsetIndex,2} = GCCPMetadataDoubles;
    assignin('base','GCCPMetadataStrings',GCCPMetadataStrings)
    assignin('base','GCCPMetadataDoubles',GCCPMetadataDoubles)
    assignin('base','GCCPMetadataCell',GCCPMetadataCell)
    save([ProjectDirectory GCCPPath],'RRFBootMean','RRFBootSigma','TRFBootMean','TRFBootSigma','BootAxis');
    clear TraceCount RRFAmps TRFAmps Rtemp Ttemp
    toc
end

% Save GCCPMetadata tables to the project file
%--------------------------------------------------------------------------
GCCPMetadataCell{CurrentSubsetIndex,1} = GCCPMetadataStrings;
GCCPMetadataCell{CurrentSubsetIndex,2} = GCCPMetadataDoubles;
save([ProjectDirectory ProjectFile],'GCCPMetadataStrings','GCCPMetadataDoubles','GCCPMetadataCell','-append')
assignin('base','GCCPMetadataStrings',GCCPMetadataStrings)
assignin('base','GCCPMetadataDoubles',GCCPMetadataDoubles)
assignin('base','GCCPMetadataCell',GCCPMetadataCell)

% Edit the Project file so that GCCP tables can be viewed in FuncLab
%--------------------------------------------------------------------------
%load([ProjectDirectory ProjectFile],'Tablemenu')
% if isempty(strmatch('GCCPMetadata',Tablemenu(:,2)))
%     Tablemenu = vertcat(Tablemenu,{'GCCP Tables','GCCPMetadata',2,3,'Stacks: ','Records (Listed by Bins)','Bins: ','gccp_record_fields','double'});
%     save([ProjectDirectory ProjectFile],'Tablemenu','-append')
%     assignin('base','Tablemenu',Tablemenu)
% end
Tablemenu = SetManagementCell{CurrentSubsetIndex,4};
if isempty(strmatch('GCCPMetadata',Tablemenu(:,2)))
    Tablemenu = vertcat(Tablemenu,{'GCCP Tables','GCCPMetadata',2,3,'Stacks: ','Records (Listed by Bins)','Bins: ','ccp_record_fields','double'});
    SetManagementCell{CurrentSubsetIndex, 4} = Tablemenu;
    save([ProjectDirectory ProjectFile],'Tablemenu','SetManagementCell','-append')
    assignin('base','Tablemenu',Tablemenu)
    assignin('base','SetManagementCell',SetManagementCell);
end


%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%

set(h.binmap_m,'Enable','on')   % 06/15/2011: ADDED COMMAND TO ENABLE THE BIN MAP AND THE BIN STACK PLOTTING FUNCTIONS
set(h.binstack_m,'Enable','on')
set(h.ex_pp_m,'Enable','on')
set(h.ex_volume_m,'Enable','on')

% Save the data to one file
[FileName,Pathname] = uiputfile('*.mat','Save GCCP Volume to File',[ProjectDirectory filesep 'gccp_volume.mat']);
if FileName ~= 0
    TmpWaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
        'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',TmpWaitGui,'Style','text','Units','characters','Tag','message_t',...
        'String','Please wait, exporting GCCP volume to mat file...',...
        'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
    drawnow
    %fid = fopen([Pathname FileName],'w+');
    Longitudes = zeros(size(GCCPMetadataStrings,1)*length(GCCPMetadataStrings{1,4}),1);
    Latitudes = zeros(size(GCCPMetadataStrings,1)*length(GCCPMetadataStrings{1,4}),1);
    Depths = zeros(size(GCCPMetadataStrings,1)*length(GCCPMetadataStrings{1,4}),1);
    RRFAmpMean = zeros(size(GCCPMetadataStrings,1)*length(GCCPMetadataStrings{1,4}),1);
    RRFAmpSigma = zeros(size(GCCPMetadataStrings,1)*length(GCCPMetadataStrings{1,4}),1);
    TRFAmpMean = zeros(size(GCCPMetadataStrings,1)*length(GCCPMetadataStrings{1,4}),1);
    TRFAmpSigma = zeros(size(GCCPMetadataStrings,1)*length(GCCPMetadataStrings{1,4}),1);
    jdx=1;
    for n = 1:size(GCCPMetadataStrings,1)
        % Load GCCP Table from the Project Directory
        %----------------------------------------------------------------------
        load([ProjectDirectory,filesep,GCCPMetadataStrings{n,1}])
        for idx=1:length(BootAxis)
           Longitudes(jdx) = GCCPMetadataDoubles(n,11);
           Latitudes(jdx) = GCCPMetadataDoubles(n,10);
           Depths(jdx) = BootAxis(idx);
           RRFAmpMean(jdx) = RRFBootMean(idx);
           RRFAmpSigma(jdx) = RRFBootSigma(idx);
           TRFAmpMean(jdx) = TRFBootMean(idx);
           TRFAmpSigma(jdx) = TRFBootSigma(idx);
           jdx = jdx+1;
        end
    %    for m = 1:length(BootAxis)
    %        fprintf(fid,'%.3f %.3f %.5f %.2f %.5f %.5f %.5f %.5f\n',GCCPMetadataDoubles(n,11),GCCPMetadataDoubles(n,10),BootAxis(m),GCCPMetadataDoubles(n,12),RRFBootMean(m),RRFBootSigma(m),TRFBootMean(m),TRFBootSigma(m));
    %    end
    end
    %fclose(fid);
    save([Pathname filesep FileName],'Longitudes','Latitudes','Depths','RRFAmpMean','RRFAmpSigma','TRFAmpMean','TRFAmpSigma')
    close(TmpWaitGui)
end



% Update the Log File
%--------------------------------------------------------------------------
LogFile = [ProjectDirectory 'Logfile.txt'];
CTime = clock;
NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - GCCP Stacking Set %s',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6), SetName);
NewLog{2} = ['     1. Bootstrap resamples: ' num2str(ResampleNumber) ' times'];
NewLog{3} = ['     2. Bootstrap selection percentage: ' num2str(RandomSelectionCount) '%'];
NewLog{4} = ['     3. Ray parameter range: ' num2str(RayParameterMin) ' to ' num2str(RayParameterMax) ' s/km'];
NewLog{5} = ['     4. Backazimuth range: ' num2str(BackazimuthMin) ' to ' num2str(BackazimuthMax) ' s/km'];
NewLog{6} = ['     5. ' num2str(DepthIncrement) ' km depth increment'];
NewLog{7} = ['     6. ' num2str(DepthMax) ' km imaging depth'];
t_temp = toc;
NewLog{8} = ['     7. GCCP stacking took ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).'];
fl_edit_logfile(LogFile,NewLog)
close(WaitGui)
set(h.MainGui.message_t,'String',['Message: GCCP Stacking: Stacking took ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).'])
set(h.MainGui.tablemenu_pu,'String',Tablemenu(:,1))
