function ccpv2_do_ray_tracing_parallel_PtoS(params)
%% CCPV2_DO_RAY_TRACING_PARALLEL_PTOS
%    Does the ray tracing for the ccpv2
%    This version is designed for parallel computing of P to S converted
%    waves
%    
%    Input Parameters:
%    params.DepthIncrement
%    params.DepthMaximum;
%    params.oneDModel;
%    params.threeDModel;
%    params.NIterations; 
%    params.NWorkers;
%    params.IncidentPhase;
%
%    Author: Robert W. Porritt
%    Created: 05/01/2015
% Note that in the prototype phase parallel computing has not yet been
% implemented.

%timing
tic;

% So the user knows something is happening
%disp('Beginning ray tracing...')

% Get metadata from the project
ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');
%load([ProjectDirectory ProjectFile],'RecordMetadataDoubles','RecordMetadataStrings')
SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
RecordMetadataStrings = SetManagementCell{CurrentSubsetIndex,2};
RecordMetadataDoubles = SetManagementCell{CurrentSubsetIndex,3};
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


EARTH_RADIUS = 6371;

% Get the number of records
nrecords = size(RecordMetadataDoubles,1);

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

% Setup a worker pool
%WorkerPool = parpool(params.NWorkers);

% Setup the input cell arrays for mapPsSeis2depth_1d
AllSeisR = cell(nrecords,1);
AllSeisT = cell(nrecords,1);
AllTime = cell(nrecords,1);
AllP = zeros(nrecords,1);
AllBackaz = zeros(nrecords,1);
AllRecordNumbers = zeros(nrecords,1);

% Loop through the records dumping the amplitudes, times, ray params, and
% baz
jray = 0;
for iray = 1:nrecords
    % Prepare call to mapPsSeis2depth_1d from processRFmatlab
    % function [depths, epos, npos, seisout] = mapPsSeis2depth_1d( time, seis, p, backaz, dz, z, vp, vs )
    % Note that time and seis cell arrays and p and backaz are vectors.
    % subroutine loops through all input
    % So what we need to do is create a cell array for each record
    
    % First, work on only active traces
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
end

% Call to map to depth with a 1D model
[AllDepths, AllEpos, AllNpos, AllSeisOutR] = mapPsSeis2depth_1d(AllTime, AllSeisR, AllP, AllBackaz, ...
    params.DepthIncrement, oneDVel(:,1), oneDVel(:,2), oneDVel(:,3));

[~, ~, ~, AllSeisOutT] = mapPsSeis2depth_1d(AllTime, AllSeisT, AllP, AllBackaz, ...
    params.DepthIncrement, oneDVel(:,1), oneDVel(:,2), oneDVel(:,3));

% Interpolate the functions to the desired depth vector
%disp('Running interpolation')
wb=waitbar(0,'Please wait. Interpolating with depth.','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(wb,'canceling',0);

warning('off','MATLAB:interp1:NaNstrip')
InterpDepthVector = 0:params.DepthIncrement:params.DepthMaximum;
InterpEpos = cell(1,nActiveRecords);
InterpNpos = cell(1,nActiveRecords);
InterpSeisR = cell(1,nActiveRecords);
InterpSeisT = cell(1,nActiveRecords);
for iray=1:nActiveRecords
    InterpEpos{iray} = interp1(AllDepths{iray},AllEpos{iray},InterpDepthVector,'linear','extrap');
    InterpNpos{iray} = interp1(AllDepths{iray},AllNpos{iray},InterpDepthVector,'linear','extrap');
    InterpSeisR{iray} = interp1(AllDepths{iray},AllSeisOutR{iray},InterpDepthVector,'linear','extrap');
    InterpSeisT{iray} = interp1(AllDepths{iray},AllSeisOutT{iray},InterpDepthVector,'linear','extrap');
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
   
%  mapPsSeis2depth_1d provides coordinates relative to the station in km.
%  In order to translate this latitude, longitude, and radius, here we
%  convert to a cartesian box with 0,0,0 at the center of the earth
%  Could not get this to work quite right. The spherical formula gets the
%  baz correct, but this does not
    %function [x, y, z] = latlonel_to_cartesian(latitude, longitude, elevation)
%     [StationX,StationY,StationZ] = latlonel_to_cartesian(StationLatitude, StationLongitude, StationElevation);
%     for idepth=1:length(InterpDepthVector)
%         dx = TmpEpos(idepth);
%         dy = TmpNpos(idepth);
%         dz = sqrt(InterpDepthVector(idepth)^2 - dx^2 - dy^2);
%         [RayInfoCart{iray}.Latitude(idepth), RayInfoCart{iray}.Longitude(idepth), RayInfoCart{iray}.Radius(idepth)] = ...
%             cart_to_lat_lon_rad(StationX+dx, StationY+dy, StationZ-dz);
%     end
  
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
    outputFile = fullfile(ProjectDirectory, 'CCPV2', 'CCPV2.mat');
else
    outputFile = fullfile(ProjectDirectory, SetName, 'CCPV2', 'CCPV2.mat');
end
save(outputFile,'RayInfo','-append');


% Done with workers
%delete(WorkerPool)
















%     [StationX, StationY, StationZ] = latlonel_to_cartesian(StationLatitude, StationLongitude, StationElevation);
%     for idepth=1:length(InterpDepthVector)
%         [RayInfoCart{iray}.Latitude(idepth), RayInfoCart{iray}.Longitude(idepth), RayInfoCart{iray}.Radius(idepth)] = ...
%             cart_to_lat_lon_rad(StationX+TmpEpos(idepth), StationY+TmpNpos(idepth), StationZ-InterpDepthVector(idepth));
%     end
