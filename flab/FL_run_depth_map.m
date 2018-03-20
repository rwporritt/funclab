function FL_run_depth_map(params)
%% FL_run_depth_map
%    uses the params setup in the gui to run the depth mapping
%    Puts the output into a mat file with a structure variable called
%    RayInfo which is a cell array over each ray
%    Created: 05/04/2015 Rob Porritt 
%
%    Parameters passed in as params: 
%     OneDParams.DepthIncrement = hdls.UserData.depthinc;
%     OneDParams.DepthMaximum = hdls.UserData.depthmax;
%     OneDParams.oneDModel = hdls.UserData.oneDModel;
%     OneDParams.threeDModel = hdls.UserData.threeDModel;
%     OneDParams.NIterations = hdls.UserData.NIterations; 
%     %OneDParams.CurrentOrAllChoice = hdls.UserData.CurrentOrAllChoice;
%     OneDParams.ActiveOrAllChoice = hdls.UserData.ActiveOrAllChoice;
%     %OneDParams.StationsOrEvents = hdls.UserData.StationsOrEvents;
%     %OneDParams.CurrentRecords = hdls.UserData.CurrentRecords;
%     %OneDParams.CurrentIndices = hdls.UserData.CurrentIndices;
%     %OneDParams.Station = hdls.UserData.Station;
%     %OneDParams.Event = hdls.UserData.Event;
%
%  Original attempted to allow sub-selection of events and stations. Those
%  attempts are commented out here to simply map all traces.
%
%  Use the subsetting tool to create a selection by station/event etc... to
%  map.

tic

% Get project info
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');

% Check for existance of a depth mapping file output
load([ProjectDirectory ProjectFile])
if ~exist('ThreeDRayInfoFile','var')
    ThreeDRayInfoFile = cell(size(SetManagementCell,1),1);
end
% For older projects before subsetting was introduced
if ~iscell(ThreeDRayInfoFile)
    tmp = ThreeDRayInfoFile;
    ThreeDRayInfoFile = cell(size(SetManagementCell,1),1);
    ThreeDRayInfoFile{1} = tmp;
end

SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
RecordMetadataStrings = SetManagementCell{CurrentSubsetIndex, 2};
RecordMetadataDoubles = SetManagementCell{CurrentSubsetIndex, 3};

% Allows switching between writing the output as sac files or not
% Change to 1 to write the depth mapped files as sac files
writeSacFilesFlag = 0;


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
end

%RecordMetadataStrings = evalin('base','RecordMetadataStrings');
%RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');

EARTH_RADIUS = 6371;

% Get the number of records
% if strcmp(params.CurrentOrAllChoice,'Current')
%     nrecords = size(params.CurrentIndices,1);
% else
nrecords = size(RecordMetadataDoubles,1);
% end

% Get the 1D velocity model
oneDVel = load(params.oneDModel,'-ascii');

% Get the 3D model
threeDModel = load(params.threeDModel);

% If the threeDModel is in perturbation, convert to absolute velocity
nx = size(threeDModel.ModelP,1);
ny = size(threeDModel.ModelP,2);
nz = size(threeDModel.ModelP,3);
ModelP = zeros(nx,ny,nz);
ModelS = zeros(nx,ny,nz);
if strcmp(threeDModel.TomoType,'perturbation')
    for idz=1:size(threeDModel.ModelP,3)
        % Get the 1D Velocity at this point
        Vp = interp1(oneDVel(:,1),oneDVel(:,2),threeDModel.Depths(1,1,idz));
        Vs = interp1(oneDVel(:,1),oneDVel(:,3),threeDModel.Depths(1,1,idz));
        for idx=1:size(threeDModel.ModelP,1)
            for idy=1:size(threeDModel.ModelP,2)
                % V = V0 * (1+dV/100); 
                ModelP(idx,idy,idz) = Vp * (1+threeDModel.ModelP(idx,idy,idz)/100);
                ModelS(idx,idy,idz) = Vs * (1+threeDModel.ModelS(idx,idy,idz)/100);
            end
        end
    end
else
    ModelP = threeDModel.ModelP;
    ModelS = threeDModel.ModelS;
end

% Setup a waitbar to help the user track
wb=waitbar(0,'Please wait. Loading active records.','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(wb,'canceling',0);

% Setup the input cell arrays for mapPsSeis2depth_1d
AllSeisR = cell(nrecords,1);
AllSeisT = cell(nrecords,1);
AllTime = cell(nrecords,1);
AllP = zeros(nrecords,1);
AllBackaz = zeros(nrecords,1);
AllRecordNumbers = zeros(nrecords,1);
isActive = zeros(nrecords,1);

% Loop through the records dumping the amplitudes, times, ray params, and
% baz
jray = 0;
for iray = 1:nrecords
    % Prepare call to mapPsSeis2depth_1d from processRFmatlab
    % function [depths, epos, npos, seisout] = mapPsSeis2depth_1d( time, seis, p, backaz, dz, z, vp, vs )
    % Note that time and seis cell arrays and p and backaz are vectors.
    % subroutine loops through all input
    % So what we need to do is create a cell array for each record
    
    % i,j, and k (ray) are just different ways to track over rays
%     if strcmp(params.CurrentOrAllChoice,'Current')
%         iray = params.CurrentIndices(kray);
%     else
%         iray = kray;
%     end
    
    
    % First, work on only active traces or all traces
    if strcmp(params.ActiveOrAllChoice,'Active')
        
        if RecordMetadataDoubles(iray, 2) == 1
            % jray counts the active records
            jray = jray + 1;
            
            % Get the file for this record
            EQRFile = sprintf('%seqr',RecordMetadataStrings{iray,1});
            EQTFile = sprintf('%seqt',RecordMetadataStrings{iray,1});
            [EQRAmpTime, EQRTime] = fl_readseismograms([ProjectDirectory EQRFile]);
            [EQTAmpTime, ~] = fl_readseismograms([ProjectDirectory EQTFile]);
        
            % Dump
            AllSeisR{jray} = EQRAmpTime;
            AllSeisT{jray} = EQTAmpTime;
            AllTime{jray} = EQRTime;
            AllP(jray) = RecordMetadataDoubles(iray,18);
            AllBackaz(jray) = RecordMetadataDoubles(iray,19);
            AllRecordNumbers(jray) = iray;
            isActive(jray) = RecordMetadataDoubles(iray, 2);
        end
    else
        % jray counts the active records
        jray = jray + 1;

        % Get the file for this record
        EQRFile = sprintf('%seqr',RecordMetadataStrings{iray,1});
        EQTFile = sprintf('%seqt',RecordMetadataStrings{iray,1});
        [EQRAmpTime, EQRTime] = fl_readseismograms([ProjectDirectory EQRFile]);
        if exist([ProjectDirectory EQTFile],'file')
            [EQTAmpTime, ~] = fl_readseismograms([ProjectDirectory EQTFile]);
        else
            fprintf('File %s missing.\n',[ProjectDirectory EQTFile]);
            EQTAmpTime = zeros(length(EQRAmpTime),1);
        end
        % Dump
        AllSeisR{jray} = EQRAmpTime;
        AllSeisT{jray} = EQTAmpTime;
        AllTime{jray} = EQRTime;
        AllP(jray) = RecordMetadataDoubles(iray,18);
        AllBackaz(jray) = RecordMetadataDoubles(iray,19);
        AllRecordNumbers(jray) = iray;
        isActive(jray) = RecordMetadataDoubles(iray, 2);
    end
    
    if getappdata(wb,'canceling')
        delete(wb);
        disp('Canceled during loading')
        return
    end
    if mod(iray,1000) == 0
        waitbar(iray/nrecords,wb);
    end
    
end
delete(wb);

% The records that counted - ie the active records
nActiveRecords = jray;

% Cut out the inactive records
for idx=nrecords:-1:nActiveRecords+1
   AllSeisR(idx) = [];
   AllSeisT(idx) = [];
   AllTime(idx) = [];
   AllP(idx) = [];
   AllBackaz(idx) = [];
   AllRecordNumbers(idx) = [];
   isActive(idx) = [];
end

% Call to map to depth with a 1D model
[AllDepths, AllEpos, AllNpos, AllSeisOutR] = mapPsSeis2depth_1d(AllTime, AllSeisR, AllP, AllBackaz, ...
    params.DepthIncrement, oneDVel(:,1), oneDVel(:,2), oneDVel(:,3));

[~, ~, ~, AllSeisOutT] = mapPsSeis2depth_1d(AllTime, AllSeisT, AllP, AllBackaz, ...
    params.DepthIncrement, oneDVel(:,1), oneDVel(:,2), oneDVel(:,3));

% Interpolate the functions to the desired depth vector
disp('Running interpolation')
wb=waitbar(0,'Please wait. Interpolating with depth.','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(wb,'canceling',0);

warning('off','MATLAB:interp1:NaNstrip')
InterpDepthVector = 0:params.DepthIncrement:params.DepthMaximum;
InterpEpos = cell(1,nActiveRecords);
InterpNpos = cell(1,nActiveRecords);
InterpSeisR = cell(1,nActiveRecords);
InterpSeisT = cell(1,nActiveRecords);
for iray=1:nActiveRecords
    if length(AllDepths{iray}) > 1
        InterpEpos{iray} = interp1(AllDepths{iray},AllEpos{iray},InterpDepthVector,'linear','extrap');
        InterpNpos{iray} = interp1(AllDepths{iray},AllNpos{iray},InterpDepthVector,'linear','extrap');
        InterpSeisR{iray} = interp1(AllDepths{iray},AllSeisOutR{iray},InterpDepthVector,'linear','extrap');
        InterpSeisT{iray} = interp1(AllDepths{iray},AllSeisOutT{iray},InterpDepthVector,'linear','extrap');
    else
        InterpEpos{iray} = zeros(1,length(InterpDepthVector));
        InterpNpos{iray} = zeros(1,length(InterpDepthVector));
        InterpSeisR{iray} = zeros(1,length(InterpDepthVector));
        InterpSeisT{iray} = zeros(1,length(InterpDepthVector));
    end
    if getappdata(wb,'canceling')
        delete(wb);
        disp('Canceled during interpolation')
        return
    end
    if mod(iray,1000) == 0
        waitbar(iray/nActiveRecords,wb);
    end        
end

delete(wb);

RayInfo = cell(nActiveRecords,1);
for idx=1:nActiveRecords
    RayInfo{idx}.Latitude = zeros(length(InterpDepthVector),1);
    RayInfo{idx}.Longitude = zeros(length(InterpDepthVector),1);
    RayInfo{idx}.Radius = zeros(length(InterpDepthVector),1);
    RayInfo{idx}.AmpR = zeros(length(InterpDepthVector),1);
    RayInfo{idx}.AmpT = zeros(length(InterpDepthVector),1);
    RayInfo{idx}.RecordNumber = AllRecordNumbers(idx);
    RayInfo{idx}.isActive = isActive(idx);
end
%RayInfoCart = RayInfo;    
    
% 1D ray tracing
wb=waitbar(0,'Please wait. Geographic mapping.','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(wb,'canceling',0);

% Convert from km away from the station to lat/long/depth
% Also figure out the min/max latitude/longitude for reducing the 3D model
minLat = 9001;
maxLat = -9001;
minLon = 9001;
maxLon = -9001;
%disp('Mapping to geographic with 1D velocity model')
for iray=1:nActiveRecords
   CurrentRecordID = AllRecordNumbers(iray);
   StationLatitude = RecordMetadataDoubles(CurrentRecordID,10);
   StationLongitude = RecordMetadataDoubles(CurrentRecordID,11);
   StationElevation = RecordMetadataDoubles(CurrentRecordID,12);
   
   % vectors accounting for the lateral moveout
   TmpNpos = InterpNpos{iray};
   TmpEpos = InterpEpos{iray};
   
%  Using spherical coordinates...   
   if params.NIterations == 0
       for idepth = 1:length(InterpDepthVector)
           CurrentRadius = EARTH_RADIUS - InterpDepthVector(idepth) + StationElevation;
           CurrentToDeg = 180 / (pi*CurrentRadius);
           RayInfo{iray}.Latitude(idepth) = StationLatitude + TmpNpos(idepth) * CurrentToDeg;
           RayInfo{iray}.Longitude(idepth) = StationLongitude + TmpEpos(idepth) * CurrentToDeg;
           RayInfo{iray}.Radius(idepth) = CurrentRadius;
       end
   else
       for idepth = 1:length(InterpDepthVector)
           CurrentRadius = EARTH_RADIUS - InterpDepthVector(idepth) + StationElevation;
           CurrentToDeg = 180 / (pi*CurrentRadius);
           RayInfo{iray}.Latitude(idepth) = StationLatitude + TmpNpos(idepth) * CurrentToDeg;
           RayInfo{iray}.Longitude(idepth) = StationLongitude + TmpEpos(idepth) * CurrentToDeg;
           RayInfo{iray}.Radius(idepth) = CurrentRadius;
       end
       if (RayInfo{iray}.Latitude(idepth) < minLat) 
            minLat = RayInfo{iray}.Latitude(idepth);
       end
       if (RayInfo{iray}.Latitude(idepth) > maxLat) 
           maxLat = RayInfo{iray}.Latitude(idepth);
       end
       if (RayInfo{iray}.Longitude(idepth) < minLon) 
           minLon = RayInfo{iray}.Longitude(idepth);
       end
       if (RayInfo{iray}.Longitude(idepth) > maxLon) 
           maxLon = RayInfo{iray}.Longitude(idepth);
       end
   end
   
   % Drop the amplitudes to the ray info
   RayInfo{iray}.AmpR = InterpSeisR{iray}';
   RayInfo{iray}.AmpT = InterpSeisT{iray}';
   
    if getappdata(wb,'canceling')
        delete(wb);
        disp('Canceled during geographic mapping')
        return
    end
    if mod(iray,1000) == 0
        waitbar(iray/nActiveRecords,wb);
    end        

end

tend = toc;
delete(wb);

fprintf('Elapsed time for 1D Ray tracing: %s seconds (%s minutes).\n',num2str(tend), num2str((tend)/60));

%disp('Beginning iterative 3D ray tracing')

% Need to re-arrange for the mesh grid format
tmpdep = permute(threeDModel.Depths,[2,1,3]);
tmplat = permute(threeDModel.Lats,[2,1,3]);
tmplon = permute(threeDModel.Lons,[2,1,3]);
tmpvp = permute(ModelP,[2,1,3]);
tmpvs = permute(ModelS,[2,1,3]);        

% Cut down the model to only include the region sampled after the first run
% plus a little buffer space
if params.NIterations > 0
    DeltaLongitude = abs(tmplon(1,2,1) - tmplon(1,1,1));
    DeltaLatitude = abs(tmplat(2,1,1) - tmplat(1,1,1));
    DeltaDepth = abs(tmpdep(1,1,2) - tmpdep(1,1,1));
    % If you use a very fine resolution model, you may need to increase
    % this buff multiplier
    bufferMultiplier = 3;
    MinLongitude = floor(minLon - bufferMultiplier*DeltaLongitude);
    MaxLongitude = ceil(maxLon + bufferMultiplier*DeltaLongitude);
    MinLatitude = floor(minLat - bufferMultiplier*DeltaLatitude);
    MaxLatitude = ceil(maxLat + bufferMultiplier*DeltaLatitude);
    
    % Check for outside of global limits
    % Had to make a choice here; models should be able to be defined from
    % longitude -180 to 180 or 0 to 360...
    if MinLongitude < -180
        MinLongitude = -180;
    end
    if MaxLongitude > 360
        MaxLongitude = 360;
    end
    if MinLatitude < -90
        MinLatitude = -90;
    end
    if MaxLatitude > 90
        MaxLatitude = 90;
    end
    
    % Prepare to remesh
    tmptmplat = MinLatitude:DeltaLatitude:MaxLatitude;
    tmptmplon = MinLongitude:DeltaLongitude:MaxLongitude;
    tmptmpdep = 0:params.DepthIncrement:params.DepthMaximum;
    
    [xmesh, ymesh, zmesh] = meshgrid(tmptmplon, tmptmplat, tmptmpdep);
    
    % Get the model space over the appropriate sample region
    tmptmpvp = interp3(tmplon, tmplat, tmpdep, tmpvp, double(xmesh), double(ymesh), zmesh);
    tmptmpvs = interp3(tmplon, tmplat, tmpdep, tmpvs, double(xmesh), double(ymesh), zmesh);
    
    % Recast
    tmplon = double(xmesh);
    tmplat = double(ymesh);
    tmpdep = zmesh;
    tmpvp = tmptmpvp;
    tmpvs = tmptmpvs;
    
end

% 1D ray tracing
wb=waitbar(0,'Please wait. 3D ray tracing.','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(wb,'canceling',0);

% Now for the iterative tracing if desired
TmpSeis=cell(2,1);
TmpTime=cell(1,1);
for iter = 1:params.NIterations
    tic
    for iray=1:nActiveRecords
        % Get the seismograms for mapPsSeis2depth_1d( time, seis, p, backaz, dz, z, vp, vs )
        TmpSeis{1} = AllSeisR{iray};
        TmpSeis{2} = AllSeisT{iray};
        TmpTime{1} = AllTime{iray};
        TmpTime{2} = AllTime{iray};
        
        % Get P and backaz
        rayparam(1) = AllP(iray);
        rayparam(2) = AllP(iray);
        backaz(1) = AllBackaz(iray);
        backaz(2) = backaz(1);
        
        % Get z, vp, and vz along the ray from the previous iteration
        % Calls interp3 for a 1D vp and vs
        vp = interp3(tmplon, tmplat, tmpdep, tmpvp, RayInfo{iray}.Longitude, RayInfo{iray}.Latitude, 6371 - RayInfo{iray}.Radius,'nearest',-1);        
        vs = interp3(tmplon, tmplat, tmpdep, tmpvs, RayInfo{iray}.Longitude, RayInfo{iray}.Latitude, 6371 - RayInfo{iray}.Radius,'nearest',-1);
        
        % Checks for -1 values in the Vp or Vs and replaces them with the
        % 1D model at that depth. Throws warning to command window
        for idepth=1:length(vp)
            if vp(idepth) == -1
                %disp('Warning, ray point outside the 3D model coverage.')
                vp(idepth) = interp1(oneDVel(:,1),oneDVel(:,2),6371 - RayInfo{iray}.Radius(idepth),'linear','extrap');
                vs(idepth) = interp1(oneDVel(:,1),oneDVel(:,3),6371 - RayInfo{iray}.Radius(idepth),'linear','extrap');
            end
        end
        
        % Run depth mapping with new velocity model
        [deps, epos, npos, seisout] = mapPsSeis2depth_1d(TmpTime, TmpSeis, rayparam, backaz, ...
            params.DepthIncrement, 6371 - RayInfo{iray}.Radius , vp, vs);
        
        CurrentRecordID = AllRecordNumbers(iray);
        StationLatitude = RecordMetadataDoubles(CurrentRecordID,10);
        StationLongitude = RecordMetadataDoubles(CurrentRecordID,11);
        StationElevation = RecordMetadataDoubles(CurrentRecordID,12);
        interpEposition = interp1(deps{1},epos{1},InterpDepthVector,'linear','extrap');
        interpNposition = interp1(deps{1},npos{1},InterpDepthVector,'linear','extrap');
        interpSeisRadial = interp1(deps{1},seisout{1},InterpDepthVector,'linear','extrap');
        interpSeisTangential = interp1(deps{1},seisout{2},InterpDepthVector,'linear','extrap');

        for idepth = 1:length(InterpDepthVector)
            CurrentRadius = EARTH_RADIUS - InterpDepthVector(idepth) + StationElevation;
            CurrentToDeg = 180 / (pi*CurrentRadius);
            RayInfo{iray}.Latitude(idepth) = StationLatitude + interpNposition(idepth) * CurrentToDeg;
            RayInfo{iray}.Longitude(idepth) = StationLongitude + interpEposition(idepth) * CurrentToDeg;
            RayInfo{iray}.Radius(idepth) = CurrentRadius;
        end
   
        % Drop the amplitudes to the ray info
        RayInfo{iray}.AmpR = interpSeisRadial';
        RayInfo{iray}.AmpT = interpSeisTangential';
        if getappdata(wb,'canceling')
            delete(wb);
            disp('Canceled during 3D ray tracing')
            return
        end
        if mod(iray,100) == 0
            waitbar(iray/nActiveRecords,wb);
        end   
    end
    tend = toc;
    fprintf('Elapsed time for iteration %d 3D Ray tracing: %s seconds (%s minutes).\n',iter, num2str(tend), num2str((tend)/60));
end
delete(wb);

% Save the rays to the matrix
if CurrentSubsetIndex == 1
    outputFile = fullfile(ProjectDirectory, 'DepthTraces', 'DepthTracesRayInfo.mat');
else
    outputFile = fullfile(ProjectDirectory, 'DepthTraces', SetName, 'DepthTracesRayInfo.mat');
end
if exist(outputFile,'file')
    save(outputFile,'RayInfo','-append');
else
    save(outputFile,'RayInfo')
end

% Reference it in the project file
%ThreeDRayInfoFile = outputFile;
ThreeDRayInfoFile{CurrentSubsetIndex} = outputFile;
save([ProjectDirectory ProjectFile],'ThreeDRayInfoFile','-append');
assignin('base','ThreeDRayInfoFile',ThreeDRayInfoFile)

% Save the depth mapped to sac files
if writeSacFilesFlag == 1
    wb=waitbar(0,'Please wait. Writing depth mapped sac files.');
    for iray=1:nActiveRecords
        % Record number
        CurrentRecord = AllRecordNumbers(iray);

        % Get the original sac files
        EQRFile = sprintf('%seqr',RecordMetadataStrings{CurrentRecord,1});
        EQTFile = sprintf('%seqt',RecordMetadataStrings{CurrentRecord,1});

        %output appends a .d before the .eqr and .eqt
        %EQRFileD = sprintf('%sd.eqr',RecordMetadataStrings{CurrentRecord,1});
        %EQTFileD = sprintf('%sd.eqt',RecordMetadataStrings{CurrentRecord,1});
        % Read the original eqr file; update header for depth mapped and write

        [head1, head2, head3, ~] = sac([ProjectDirectory EQRFile]);
        hdr = sachdr(head1, head2, head3);
        hdr.times.b=0;
        hdr.times.o=0;
        hdr.times.a=0;
        hdr.times.atimes(1).t = 0;
        hdr.times.e=params.DepthMaximum;
        hdr.times.delta = params.DepthIncrement;
        % Get output file name based on sac parameters
        % Fetched format: TA.P54A-.EQR.OV.iterative_200.Station_decon.2.5.eqr
        % original funclab: P54A_5.0.i.eqr
        % Get the event info from the recordmetadatastrings
        EventName = RecordMetadataStrings{CurrentRecord,3};
        yyyy = EventName(1:4);
        jjj = EventName(6:8);
        hh = EventName(10:11);
        mm = EventName(13:14);
        ss = EventName(16:17);
        dirname = sprintf('Event_%s_%s_%s_%s_%s',yyyy,jjj,hh,mm,ss);
        if CurrentSubsetIndex == 1
            [~, ~, ~] = mkdir([ProjectDirectory 'DepthTraces' filesep],dirname);
        else
            [~, ~, ~] = mkdir([ProjectDirectory 'DepthTraces' filesep SetName filesep],dirname);
        end
        fname = sprintf('%s_%3.1f.i.d.eqr',deblank(hdr.station.kstnm),hdr.user(1).data);
        if CurrentSubsetIndex == 1
            EQRFileD = fullfile('DepthTraces', dirname, fname);
        else
            EQRFileD = fullfile('DepthTraces', SetName, dirname, fname);
        end
        writeSAC([ProjectDirectory EQRFileD], hdr, RayInfo{iray}.AmpR);


        if exist([ProjectDirectory EQTFile],'file')
            [head1, head2, head3, ~] = sac([ProjectDirectory EQTFile]);
            hdr = sachdr(head1, head2, head3);
            hdr.times.b=0;
            hdr.times.o=0;
            hdr.times.a=0;
            hdr.times.atimes(1).t = 0;
            hdr.times.e=params.DepthMaximum;
            hdr.times.delta = params.DepthIncrement;
            fname = sprintf('%s_%3.1f.i.d.eqt',deblank(hdr.station.kstnm),hdr.user(1).data);
            if CurrentSubsetIndex == 1
                EQTFileD = fullfile('DepthTraces', dirname, fname);
            else
                EQTFileD = fullfile('DepthTraces', SetName, dirname, fname);
            end
            writeSAC([ProjectDirectory EQTFileD], hdr, RayInfo{iray}.AmpT);
        end

        if mod(iray,1000) == 0
            waitbar(iray/nActiveRecords,wb);
        end

        %RecordMetadataStrings{CurrentRecord,4} = EQRFileD;
        %RecordMetadataStrings{CurrentRecord,5} = EQTFileD;

    end
    delete(wb);
end
% Save to the project file
%assignin('base','RecordMetadataStrings',RecordMetadataStrings);
%save([ProjectDirectory ProjectFile],'RecordMetadataStrings','-append');

% Update the log
%--------------------------------------------------------------------------
if CurrentSubsetIndex == 1
    SetName = 'Base';
end
LogFile = [ProjectDirectory 'Logfile.txt'];
CTime = clock;
NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - Depth mapping done for set %s',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6), SetName);
fl_edit_logfile(LogFile,NewLog)


end


