function gccp_1D_raytracing(cbo,eventdata,handles)
%GCCP_1D_RAYTRACING 1D ray tracing
%   GCCP_1D_RAYTRACING is a callback function that computes the 1D ray
%   tracing matrix for every event-station pair in the project dataset.
%   This saves us from having to do this for velocity corrections and GCCP
%   stacking.

%   Author: Kevin C. Eagar
%   Date Created: 12/30/2010
%   Last Updated: 06/15/2011

% Time the runtime of this function.
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
    'String','Please wait, performing 1D ray tracing for ACTIVE records in the dataset.',...
    'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
drawnow;
H = guihandles(WaitGui);
guidata(WaitGui,H);

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
    GCCPDataDir = fullfile(ProjectDirectory, 'GCCPData');
    GCCPMatFile = fullfile(ProjectDirectory, 'GCCPData', 'GCCPData.mat');
else
    GCCPDataDir = fullfile(ProjectDirectory, SetName, 'GCCPData');
    GCCPMatFile = fullfile(ProjectDirectory, 'GCCPData', SetName, 'GCCPData.mat');
end

% Set initial values
%--------------------------------------------------------------------------
DepthIncrement = str2double(get(h.depthinc_e,'string'));
DepthMax = str2double(get(h.depthmax_e,'string'));
VModel = get(h.velocity_p,'string');
VModel = VModel{get(h.velocity_p,'value')};
YAxisRange = 0:(DepthIncrement/2):DepthMax;
MagicNumber = 15000;    % 06/15/2011 CHANGED MAX NUMBER OF ARRAY ELEMENTS FROM 25,000 T0 15,000 TO AVOID OUT OF MEMORY ERRORS
Datapath = regexprep(which('funclab'),'funclab.m','VELMODELS/');
Velocity1D = [Datapath VModel];
VelocityModel = load(Velocity1D,'-ascii');

if ~exist(GCCPDataDir,'dir')
    [~, ~, ~] = mkdir(GCCPDataDir);
end

RecordMetadataStrings = SetManagementCell{CurrentSubsetIndex, 2};
RecordMetadataDoubles = SetManagementCell{CurrentSubsetIndex, 3};

%RecordMetadataStrings = evalin('base','RecordMetadataStrings');
%RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');

% Only proceed for the traces that are turned on
%--------------------------------------------------------------------------
ActiveIndices = find(RecordMetadataDoubles(:,2));
ActiveDoubles = RecordMetadataDoubles(ActiveIndices,:);
ActiveStrings = RecordMetadataStrings(ActiveIndices,:);

% Depths
%--------------------------------------------------------------------------
Depths = VelocityModel(:,1);

% Velocities
%--------------------------------------------------------------------------
Vp = VelocityModel(:,2);
Vs = VelocityModel(:,3);

% Interpolate velocity model to match depth range and increments
%--------------------------------------------------------------------------
Vp = interp1(Depths,Vp,YAxisRange)';
Vs = interp1(Depths,Vs,YAxisRange)';
Depths = YAxisRange';

% Depth intervals
%--------------------------------------------------------------------------
dz = [0; diff(Depths)];

% Radial shells
%--------------------------------------------------------------------------
R = 6371 - Depths;

Record = 0;
SwitchCount = 0;
for n = 1:size(ActiveStrings,1)
    
    Record = Record + 1;
    
    RayTracingMatrix(:,Record,:) = NaN*ones(length(YAxisRange),8);
    
    % 1D ray tracing
    %----------------------------------------------------------------------
    slat = ActiveDoubles(n,10);
    slon = ActiveDoubles(n,11);
    baz = ActiveDoubles(n,19);
    rayp = skm2srad(ActiveDoubles(n,18));
    x_s = cumsum((dz./R) ./ sqrt((1./(rayp^2.* (R./Vs).^-2)) - 1));
    raylength_s = (dz.*R) ./  (sqrt(((R./Vs).^2) - (rayp^2)).* Vs);
    x_p = cumsum((dz./R) ./ sqrt((1./(rayp^2.* (R./Vp).^-2)) - 1));
    raylength_p = (dz.*R) ./  (sqrt(((R./Vp).^2) - (rayp^2)).* Vp);
    
    % Search for imaginary values in the distance calculations of the
    % P-wave
    %----------------------------------------------------------------------
    StopIndex = find(imag(x_p),1);
    if ~isempty(StopIndex)
        x_p(StopIndex:end) = NaN * ones(length(x_p)-StopIndex+1,1);
        x_s(StopIndex:end) = NaN * ones(length(x_s)-StopIndex+1,1);
    end
    
    % convert distance in km to distance in degrees along a Great Circle
    % path
    %----------------------------------------------------------------------
    gcarc_dist_s = rad2deg(x_s);
    gcarc_dist_p = rad2deg(x_p);
    
    % Find latitude of piercing points using law of cosines
    %----------------------------------------------------------------------
    pplat_s = asind((sind(slat) .* cosd(gcarc_dist_s)) + (cosd(slat) .* sind(gcarc_dist_s) .* cosd(baz)));
    pplat_p = asind((sind(slat) .* cosd(gcarc_dist_p)) + (cosd(slat) .* sind(gcarc_dist_p) .* cosd(baz)));
    
    % Do trig calculations
    %----------------------------------------------------------------------
    c1 = cosd(gcarc_dist_s);
    c2 = cosd(90 - slat);
    c3 = cosd(90 - pplat_s);
    c4 = sind(gcarc_dist_s);
    c5 = sind(baz);
    c6 = cosd(pplat_s);
    c7 = cosd(gcarc_dist_p);
    c8 = cosd(90 - pplat_p);
    c9 = sind(gcarc_dist_p);
    c10 = cosd(pplat_p);
    
    for k = 1:length(gcarc_dist_s)
        
        % Find longitude of piercing points using law of sines
        %------------------------------------------------------------------
        if isnan(gcarc_dist_s(k))
            pplon_p = NaN;
            pplon_s = NaN;
            raylength_p(k) = NaN;
            raylength_s(k) = NaN;
        else
            if ( c1(k) >= (c2 .* c3(k)))
                pplon_s = slon + asind(c4(k) .* c5 ./ c6(k));
            else
                pplon_s = slon + asind(c4(k) .* c5 ./ c6(k)) + 180;
            end
            if ( c7(k) >= (c2 .* c8(k)))
                pplon_p = slon + asind(c9(k) .* c5 ./ c10(k));
            else
                pplon_p = slon + asind(c9(k) .* c5 ./ c10(k)) + 180;
            end
        end
        RayTracingMatrix(k,Record,2) = pplat_s(k);
        RayTracingMatrix(k,Record,3) = pplon_s;
        RayTracingMatrix(k,Record,4) = raylength_s(k);
        RayTracingMatrix(k,Record,5) = pplat_p(k);
        RayTracingMatrix(k,Record,6) = pplon_p;
        RayTracingMatrix(k,Record,7) = raylength_p(k);
        RayTracingMatrix(k,Record,8) = ActiveIndices(n);
    end
    if Record >= MagicNumber
        Record = 0;
        SwitchCount = SwitchCount + 1;
        NewName1 = sprintf('RayMatrix_%02.0f',SwitchCount);
        NewName2 = sprintf('MidPoints_%02.0f',SwitchCount);
        % Make the MidPoint Matrix where the columns are S -
        % lon,lat,raylength and P - lon,lat,raylength.  Each of these
        % rays are referenced to the bottom depth of the segment.
        count = 0;
        for k = 2:2:size(RayTracingMatrix,1)-1
            count = count + 1;
            MidPoints(count,:,:) = RayTracingMatrix(k,:,(2:end));
            seglength_s = RayTracingMatrix(k,:,4) + RayTracingMatrix(k+1,:,4);
            seglength_p = RayTracingMatrix(k,:,7) + RayTracingMatrix(k+1,:,7);
            MidPoints(count,:,3) = seglength_s;
            MidPoints(count,:,6) = seglength_p;
        end
        
        % Make the ray piercing point matrix where the columns are
        % RRF,TRF Amplitudes, S - lon,lat, P - lon,lat.
        count = 0;
        for k = 1:2:size(RayTracingMatrix,1)
            count = count + 1;
            RayMatrix(count,:,:) = RayTracingMatrix(k,:,[1 1 2 3 5 6 8]);
        end
        eval([NewName1 '= RayMatrix;'])
        eval([NewName2 '= MidPoints;'])
        if ~exist(GCCPMatFile,'file')
            save(GCCPMatFile,NewName1,NewName2);
        else
            save(GCCPMatFile,NewName1,NewName2,'-append');
        end
        clear MidPoints RayMatrix RayTracingMatrix RayRecords
        clear(NewName1)
        clear(NewName2)  % 06/15/2011 DELETED EXTRA CLEAR COMMAND FROM LINE 197
    end
end

if SwitchCount == 0
    % Make the MidPoint Matrix where the columns are S - lon,lat,raylength
    % and P - lon,lat,raylength.  Each of these rays are referenced to the
    % bottom depth of the segment.
    count = 0;
    for n = 2:2:size(RayTracingMatrix,1)-1
        count = count + 1;
        MidPoints_01(count,:,:) = RayTracingMatrix(n,:,(2:end));
        seglength_s = RayTracingMatrix(n,:,4) + RayTracingMatrix(n+1,:,4);
        seglength_p = RayTracingMatrix(n,:,7) + RayTracingMatrix(n+1,:,7);
        MidPoints_01(count,:,3) = seglength_s;
        MidPoints_01(count,:,6) = seglength_p;
    end

    % Make the ray piercing point matrix where the columns are RRF,TRF
    % Amplitudes, S - lat,lon, and P - lat,lon.
    count = 0;
    for n = 1:2:size(RayTracingMatrix,1)
        count = count + 1;
        RayMatrix_01(count,:,:) = RayTracingMatrix(n,:,[1 1 2 3 5 6 8]);
    end
    save(GCCPMatFile,'RayMatrix_01','MidPoints_01');
    SwitchCount = 1;
else    % 06/15/2011    ADDED ELSE STATEMENT TO SAVE LAST MATRIX
    % Finish off the last matrix with the left over records.
    SwitchCount = SwitchCount + 1;
    NewName1 = sprintf('RayMatrix_%02.0f',SwitchCount);
    NewName2 = sprintf('MidPoints_%02.0f',SwitchCount);
    % Make the MidPoint Matrix where the columns are S -
    % lon,lat,raylength and P - lon,lat,raylength.  Each of these
    % rays are referenced to the bottom depth of the segment.
    count = 0;
    for k = 2:2:size(RayTracingMatrix,1)-1
        count = count + 1;
        MidPoints(count,:,:) = RayTracingMatrix(k,:,(2:end));
        seglength_s = RayTracingMatrix(k,:,4) + RayTracingMatrix(k+1,:,4);
        seglength_p = RayTracingMatrix(k,:,7) + RayTracingMatrix(k+1,:,7);
        MidPoints(count,:,3) = seglength_s;
        MidPoints(count,:,6) = seglength_p;
    end
    
    % Make the ray piercing point matrix where the columns are
    % RRF,TRF Amplitudes, S - lon,lat, P - lon,lat.
    count = 0;
    for k = 1:2:size(RayTracingMatrix,1)
        count = count + 1;
        RayMatrix(count,:,:) = RayTracingMatrix(k,:,[1 1 2 3 5 6 8]);
    end
    eval([NewName1 '= RayMatrix;'])
    eval([NewName2 '= MidPoints;'])
    if ~exist(GCCPMatFile,'file')
        save(GCCPMatFile,NewName1,NewName2);
    else
        save(GCCPMatFile,NewName1,NewName2,'-append');
    end
    clear MidPoints RayMatrix RayTracingMatrix RayRecords
    clear(NewName1)
    clear(NewName2)
end

% Update the Log File
%--------------------------------------------------------------------------
LogFile = [ProjectDirectory 'Logfile.txt'];
CTime = clock;
NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - GCCP Stacking: 1D Ray Tracing Set %s',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6), SetName);
NewLog{2} = ['     1. ' VModel ' velocity model'];
NewLog{3} = ['     2. ' num2str(DepthIncrement) ' km depth increment'];
NewLog{4} = ['     3. ' num2str(DepthMax) ' km imaging depth'];
NewLog{5} = ['     4. ' num2str(SwitchCount) ' matrices were computed for all the records.'];
t_temp = toc;
NewLog{6} = ['     5. Ray tracing took ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).'];
fl_edit_logfile(LogFile,NewLog)
close(WaitGui)
set(h.MainGui.message_t,'String',['Message: GCCP Stacking: 1D ray tracing took ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).'])
set(h.corrections_b,'Enable','on')
set(h.migration_b,'Enable','on')
set(h.tomo_p,'Enable','on')