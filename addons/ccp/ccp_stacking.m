function ccp_stacking(cbo,eventdata,handles)
%CCP_STACKING Common conversion point stacking
%   CCP_STACKING is a callback function that takes each depth interval in
%   the depth axis created by the time-to-depth migration for the project,
%   and computes CCP (common conversion point) stacks for bins.  Piercing
%   points are computed for each record and binned based on proximity to
%   the mid-point of the bin.  These traces are stacked.
%
%   10/17/2008
%   I added the discontinuity peak picks from each bootstrap iteration and
%   put them into the ccp table.
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
%   Last Updated: 06/12/2012

% Need to add a clear function to clear out a prior ccp stack!

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
%     'String','Please wait, computing common-conversion-point stacks.',...
%     'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
% drawnow;
% H = guihandles(WaitGui);
% guidata(WaitGui,H);
WaitGui = waitbar(0,'Please wait, computing common-conversion-point stacks.');

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
RPs = evalin('base','RecordMetadataDoubles(:,18)');
minhits = str2double(get(h.hitsmin_e,'string'));


if CurrentSubsetIndex == 1
    CCPMatFile = fullfile(ProjectDirectory, 'CCPData', 'CCPData.mat');
    CCPBinLead = ['CCPData' filesep 'Bin_'];
else
    CCPMatFile = fullfile(ProjectDirectory, 'CCPData', SetName, 'CCPData.mat');
    CCPBinLead = ['CCPData' filesep SetName filesep 'Bin_'];
end

load(CCPMatFile,'DepthAxis','CCPGrid')
Rays = who('-file',CCPMatFile,'RayMatrix*');


for n = 1:size(CCPGrid,1) % For each bin
    for m = 1:length(Rays)
        load(CCPMatFile,Rays{m})
        RayMatrix = eval(Rays{m});
        clear(Rays{m})
        
        % Get the maximum number of bin hits in a column
        MaxHits = 0;
        for k = 1:length(CCPGrid{n,4})
            temp(k) = length(CCPGrid{n,6}{k});  % Always equals 1!
        end
        MaxHits = max(temp);
        clear temp
        
        
        if MaxHits > 0
            % Build 2 matrices with MaxHits # columns and length(DepthAxis) rows
            Rtemp = NaN * ones(length(CCPGrid{n,4}),MaxHits);
            Ttemp = NaN * ones(length(CCPGrid{n,4}),MaxHits);
            Wtemp = NaN * ones(length(CCPGrid{n,4}),MaxHits);

            % Add the value in the RayMatrix using the RF indices to the
            % matrices we just built.
            for k = 1:length(CCPGrid{n,4})
                Ids = CCPGrid{n,4}{k};
%                 Dist = CCPGrid{n,4}{k};
                if ~isempty(Ids)
                    if k == 1
                        CCPGrid{n,7} = mean(RPs(Ids));
                        %CCPGrid{n,7} = mean(RayMatrix(1,Ids,8));   %get avg RayP
                    end
                    for l = 1:length(Ids)
                        temp = find(RayMatrix(k,:,7) == Ids(l));
                        if ~isempty(temp)   % 06/12/2011: ADDED IF STATEMENT TO CHECK IF THE RECORD IDS EXIST IN THIS MATRIX
                            Rtemp(k,l) = RayMatrix(k,temp,1);
                            Ttemp(k,l) = RayMatrix(k,temp,2);
                            %                         Wtemp(k,l) = exp(-(Dist(l)).^2./(2.*CCPGrid{n,3}.^2));
                            Wtemp(k,l) = 1;
                        end
                    end
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
        end
              
        clear RayMatrix*
    end
    
    if exist('RRFAmps','var')
        [RRFBootMean,RRFBootSigma,Peaks410,Peaks660,Amps410,Amps660] = ccp_bootstrap(RRFAmps,Weights,DepthAxis,ResampleNumber,round(size(RRFAmps,2)*RandomSelectionCount));
        [TRFBootMean,TRFBootSigma,junk,junk,junk,junk] = ccp_bootstrap(TRFAmps,Weights,DepthAxis,ResampleNumber,round(size(TRFAmps,2)*RandomSelectionCount));
        for k = 1:size(RRFAmps,1)
            TraceCount(k) = length(find(~isnan(RRFAmps(k,:))));
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
    CCPPath = [CCPBinLead num2str(sprintf('%0.0f',n)) '_' num2str(BackazimuthMin,'%03.0f') ...
        num2str(BackazimuthMax,'%03.0f') '_' num2str(RayParameterMin*1000,'%03.0f') num2str(RayParameterMax*1000,'%03.0f') '.mat'];
    TableName = ['Baz=' num2str(BackazimuthMin,'%.0f') '-' num2str(BackazimuthMax,'%.0f') ...
        ' Rayp=' num2str(RayParameterMin,'%.3f') '-' num2str(RayParameterMax,'%.3f')];
%     BinName = ['Bin - ' num2str(sprintf('%0.0f',n))];
    BinName = n;
    BootAxis = DepthAxis; 
    if evalin('base',['exist(''CCPMetadataCell'',''var'')'])
        CCPMetadataCell = evalin('base','CCPMetadataCell');
        if isempty(CCPMetadataCell{CurrentSubsetIndex, 1})
            % Populate the MetadataStrings
            %----------------------------------------------------------------------
            CCPMetadataStrings(1,:) = {CCPPath,TableName,BinName,TraceCount};
            % Populate the MetadataDoubles
            %----------------------------------------------------------------------
            CCPMetadataDoubles(1,:) = [DepthIncrement,length(RRFBootMean),0,DepthMax,Gaussian,...
                BackazimuthMin,BackazimuthMax,RayParameterMin,RayParameterMax,...
                CCPGrid{n,1},CCPGrid{n,2}];
            CCPMetadataCell = cell(size(SetManagementCell,1),2);
            CCPMetadataCell{CurrentSubsetIndex,1} = CCPMetadataStrings;
            CCPMetadataCell{CurrentSubsetIndex,2} = CCPMetadataDoubles;
        else
            if size(CCPMetadataCell,1) < size(SetManagementCell,1);
                tmp = cell(size(SetManagementCell,1),2);
                for idx=1:size(CCPMetadataCell,1)
                    tmp{idx,1} = CCPMetadataCell{idx,1};
                    tmp{idx,2} = CCPMetadataCell{idx,2};
                end
                CCPMetadataCell = tmp;
            end
            CCPMetadataStrings = CCPMetadataCell{CurrentSubsetIndex,1};
            CCPMetadataDoubles = CCPMetadataCell{CurrentSubsetIndex,2};
            %CCPMetadataStrings = evalin('base','CCPMetadataStrings');
            %CCPMetadataDoubles = evalin('base','CCPMetadataDoubles');
            % Check to make sure the record DOES NOT exist
            %----------------------------------------------------------------------
            if isempty(strmatch(CCPPath,CCPMetadataStrings(:,1)));
                % If it DOES NOT, add it to the end
                %------------------------------------------------------------------
                CCPMetadataStrings(end+1,:) = {CCPPath,TableName,BinName,TraceCount};
                CCPMetadataDoubles(end+1,:) = [DepthIncrement,length(RRFBootMean),0,DepthMax,Gaussian,...
                    BackazimuthMin,BackazimuthMax,RayParameterMin,RayParameterMax,...
                    CCPGrid{n,1},CCPGrid{n,2}];
            else
                % If it DOES, replace it
                %------------------------------------------------------------------
                In = strmatch(CCPPath,CCPMetadataStrings(:,1));
                CCPMetadataStrings(In,:) = {CCPPath,TableName,BinName,TraceCount};
                CCPMetadataDoubles(In,:) = [DepthIncrement,length(RRFBootMean),0,DepthMax,Gaussian,...
                    BackazimuthMin,BackazimuthMax,RayParameterMin,RayParameterMax,...
                    CCPGrid{n,1},CCPGrid{n,2}];
            end
        end
    else
        % Populate the CCPMetadataStrings
        %----------------------------------------------------------------------
        CCPMetadataStrings(1,:) = {CCPPath,TableName,BinName,TraceCount};
        % Populate the CCPMetadataDoubles
        %----------------------------------------------------------------------
        CCPMetadataDoubles(1,:) = [DepthIncrement,length(RRFBootMean),0,DepthMax,Gaussian,...
            BackazimuthMin,BackazimuthMax,RayParameterMin,RayParameterMax,...
            CCPGrid{n,1},CCPGrid{n,2},CCPGrid{n,3}];
        CCPMetadataCell = cell(size(SetManagementCell,1),2);
        CCPMetadataCell{CurrentSubsetIndex,1} = CCPMetadataStrings;
        CCPMetadataCell{CurrentSubsetIndex,2} = CCPMetadataDoubles;
    end

%     P410sDepth = Peaks410;
%     P660sDepth = Peaks660;
%     P410sDepthError = Amps410;
%     P660sDepthError = Amps660;

    CCPMetadataCell{CurrentSubsetIndex, 1} = CCPMetadataStrings;
    CCPMetadataCell{CurrentSubsetIndex, 2} = CCPMetadataDoubles;
    assignin('base','CCPMetadataCell',CCPMetadataCell)
    assignin('base','CCPMetadataStrings',CCPMetadataStrings)
    assignin('base','CCPMetadataDoubles',CCPMetadataDoubles)
    save([ProjectDirectory CCPPath],'RRFBootMean','RRFBootSigma','TRFBootMean','TRFBootSigma','BootAxis');
    clear TraceCount RRFAmps TRFAmps Rtemp Ttemp
    waitbar(n/size(CCPGrid,1),WaitGui);
end

% Save CCPMetadata tables to the project file
%--------------------------------------------------------------------------
CCPMetadataCell{CurrentSubsetIndex, 1} = CCPMetadataStrings;
CCPMetadataCell{CurrentSubsetIndex, 2} = CCPMetadataDoubles;
save([ProjectDirectory ProjectFile],'CCPMetadataStrings','CCPMetadataDoubles','CCPMetadataCell','-append')
assignin('base','CCPMetadataStrings',CCPMetadataStrings)
assignin('base','CCPMetadataDoubles',CCPMetadataDoubles)
assignin('base','CCPMetadataCell',CCPMetadataCell)

% Edit the Project file so that CCP tables can be viewed in FuncLab
%--------------------------------------------------------------------------
%load([ProjectDirectory ProjectFile],'Tablemenu')
Tablemenu = SetManagementCell{CurrentSubsetIndex,4};
if isempty(strmatch('CCPMetadata',Tablemenu(:,2)))
    Tablemenu = vertcat(Tablemenu,{'CCP Tables','CCPMetadata',2,3,'Stacks: ','Records (Listed by Bins)','Bins: ','ccp_record_fields','double'});
    SetManagementCell{CurrentSubsetIndex, 4} = Tablemenu;
    save([ProjectDirectory ProjectFile],'Tablemenu','SetManagementCell','-append')
    assignin('base','Tablemenu',Tablemenu)
    assignin('base','SetManagementCell',SetManagementCell);
end

set(h.binmap_m,'Enable','on')   % 06/12/2011: ADDED COMMAND TO ENABLE THE BIN MAP AND THE BIN STACK PLOTTING FUNCTIONS
set(h.binstack_m,'Enable','on')
set(h.ex_pp_m,'Enable','on')
set(h.ex_stacks_m,'Enable','on')

% Save the data to one file
[FileName,Pathname] = uiputfile('*.mat','Save CCP Volume to File',[ProjectDirectory filesep 'ccp_stacks.mat']);
if FileName ~= 0
    TmpWaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
        'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',TmpWaitGui,'Style','text','Units','characters','Tag','message_t',...
        'String','Please wait, exporting CCP volume to mat file...',...
        'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
    drawnow
    %fid = fopen([Pathname FileName],'w+');
    Longitudes = zeros(size(CCPMetadataStrings,1)*length(CCPMetadataStrings{1,4}),1);
    Latitudes = zeros(size(CCPMetadataStrings,1)*length(CCPMetadataStrings{1,4}),1);
    Depths = zeros(size(CCPMetadataStrings,1)*length(CCPMetadataStrings{1,4}),1);
    RRFAmpMean = zeros(size(CCPMetadataStrings,1)*length(CCPMetadataStrings{1,4}),1);
    RRFAmpSigma = zeros(size(CCPMetadataStrings,1)*length(CCPMetadataStrings{1,4}),1);
    TRFAmpMean = zeros(size(CCPMetadataStrings,1)*length(CCPMetadataStrings{1,4}),1);
    TRFAmpSigma = zeros(size(CCPMetadataStrings,1)*length(CCPMetadataStrings{1,4}),1);
    jdx=1;
    for n = 1:size(CCPMetadataStrings,1)
        % Load GCCP Table from the Project Directory
        %----------------------------------------------------------------------
        load([ProjectDirectory,filesep,CCPMetadataStrings{n,1}])
        for idx=1:length(BootAxis)
           Longitudes(jdx) = CCPMetadataDoubles(n,11);
           Latitudes(jdx) = CCPMetadataDoubles(n,10);
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
NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - CCP Stacking Set %s',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6),SetName);
NewLog{2} = ['     1. Bootstrap resamples: ' num2str(ResampleNumber) ' times'];
NewLog{3} = ['     2. Bootstrap selection percentage: ' num2str(RandomSelectionCount) '%'];
NewLog{4} = ['     3. Ray parameter range: ' num2str(RayParameterMin) ' to ' num2str(RayParameterMax) ' s/km'];
NewLog{5} = ['     4. Backazimuth range: ' num2str(BackazimuthMin) ' to ' num2str(BackazimuthMax) ' s/km'];
NewLog{6} = ['     5. ' num2str(DepthIncrement) ' km depth increment'];
NewLog{7} = ['     6. ' num2str(DepthMax) ' km imaging depth'];
t_temp = toc;
NewLog{8} = ['     7. CCP stacking took ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).'];
fl_edit_logfile(LogFile,NewLog)
delete(WaitGui)
set(h.MainGui.message_t,'String',['Message: CCP Stacking: Stacking took ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).'])
set(h.MainGui.tablemenu_pu,'String',Tablemenu(:,1))
