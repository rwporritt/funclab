function ccpv2_stacking(cbo, eventdata)
%% Function ccpv2_stacking(cbo, eventdata)
%  Does the actual stacking for ccpv2
%  Applies the amplitudes stored in RayInfo onto the geometry stored in CCPV2Geometry
%  Guided by the file CCPV2/CCPV2.mat stored in the project directory,
%  although this should be something the user determines.
%
%  Author: Rob Porritt
%  Created: 05/01/2015
%

tic

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

% Save the rays to the matrix
if CurrentSubsetIndex == 1
    InputFile = fullfile(ProjectDirectory, 'CCPV2', 'CCPV2.mat');
else
    InputFile = fullfile(ProjectDirectory, 'CCPV2', SetName, 'CCPV2.mat');
end

%InputFile = fullfile(ProjectDirectory, 'CCPV2', 'CCPV2.mat');
if ~exist(InputFile,'file')
    disp('Error, file CCPV2.mat not found!')
    return
end
load(InputFile)
CCPV2MetadataStrings{1} = InputFile;

%% Setup vectors for the stack, one vector for the hit count and one for the actual stacked amplitude
WestLongitude = CCPV2Geometry.LongitudeMinimum;
EastLongitude = CCPV2Geometry.LongitudeMaximum;
StepLongitude = CCPV2Geometry.LongitudeIncrement;
SouthLatitude = CCPV2Geometry.LatitudeMinimum;
NorthLatitude = CCPV2Geometry.LatitudeMaximum;
StepLatitude = CCPV2Geometry.LatitudeIncrement;
ShallowDepth = CCPV2Geometry.DepthMinimum;
DeepDepth = CCPV2Geometry.DepthMaximum;
StepDepth = CCPV2Geometry.DepthIncrement;

xvector = WestLongitude:StepLongitude:EastLongitude;
yvector = SouthLatitude:StepLatitude:NorthLatitude;
zvector = ShallowDepth:StepDepth:DeepDepth;
nx = length(xvector);
ny = length(yvector);
nz = length(zvector);


%% For the frequency, need the measurement period and velocity model
MeasurementPeriod = CCPV2Geometry.Period;
VelMod = load(CCPV2RayTraceParams.oneDModel,'-ascii');
vmod.z = VelMod(:,1);
vmod.a = VelMod(:,2);
vmod.b = VelMod(:,3);
%[vmod.z,~,vmod.a,vmod.b,~,~] = ak135('cont');
% This will only work if all rays are defined on the same depth axis!
%RayDepthVector = RayInfo.SSKSRFRays(1).Depths;
% Instead, this is the vector we will interpolate onto
RayDepthVector = ShallowDepth:StepDepth:DeepDepth;
% Deal with discontinuities in the velocity model
idisc = find( vmod.z(1:end-1) == vmod.z(2:end) );
vmod.z(idisc) = vmod.z(idisc) - 1e-6;
KernelShearVelocityVector = interp1(vmod.z, vmod.b, RayDepthVector,'pchip','extrap');
KernelCompressionalVelocityVector = interp1(vmod.z, vmod.a, RayDepthVector,'pchip','extrap');
WavelengthVector = (pi/180) * 2 * sqrt(KernelShearVelocityVector .* MeasurementPeriod);

% defines the axially symmetric kernel form with a gaussian
RadialVector = 1:30;
RecordMetadataDoubles = SetManagementCell{CurrentSubsetIndex,3};
gaussWidth = RecordMetadataDoubles(1,7); % assume constant for all project
tmp=fl_gausswin(length(RadialVector),gaussWidth); 
KernelRadialVector = tmp(round(length(tmp)/2):end);

% Array of angles to define the disc for the kernel
ThetaVector = 0:30:360;

%...I hope this is obvious in km
EARTH_RADIUS = 6371;

%% This array contains the independent variable for the kernel scaled for each depth
KernelDistanceMatrix = zeros(length(RayDepthVector), length(RadialVector));
for i=1:length(RayDepthVector)
    KernelDistanceMatrix(i,1:length(RadialVector)) = linspace(0,WavelengthVector(i), length(RadialVector));
end

% This array contains the full set of offsets in latitude and longitude
DeltaLatLonMatrix = zeros(length(RayDepthVector), length(RadialVector), length(ThetaVector),2);
for idepth = 1:length(RayDepthVector)
    for irad = 1:length(RadialVector)
        for itheta=1:length(ThetaVector)
            DeltaLatLonMatrix(idepth, irad, itheta,1) = KernelDistanceMatrix(idepth,irad) * cosd(ThetaVector(itheta));
            DeltaLatLonMatrix(idepth, irad, itheta,2) = KernelDistanceMatrix(idepth,irad) * sind(ThetaVector(itheta));
        end
    end
end

%% Prepare the output matrices
CCPStackR = zeros(nx,ny,nz);
CCPStackT = zeros(nx,ny,nz);
CCPHits = zeros(nx,ny,nz);
CCPStackKernelR = zeros(nx,ny,nz);
CCPStackKernelT = zeros(nx,ny,nz);
CCPHitsKernel = zeros(nx,ny,nz);


%% Run through the rays stacking
wb = waitbar(0,'CCP Stacking...','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(wb,'canceling',0);

nrays = length(RayInfo);
for iray=1:nrays
    
    % Downsample the rays based on the desired geometry
    interpLats = interp1(6371-RayInfo{iray}.Radius, RayInfo{iray}.Latitude,RayDepthVector);
    interpLons = interp1(6371-RayInfo{iray}.Radius, RayInfo{iray}.Longitude,RayDepthVector);
    interpAmpsR = interp1(6371-RayInfo{iray}.Radius, RayInfo{iray}.AmpR,RayDepthVector);
    interpAmpsT = interp1(6371-RayInfo{iray}.Radius, RayInfo{iray}.AmpT,RayDepthVector);

    
    % Go through each independent point
    for idepth = 1:length(RayDepthVector)
        
        % Get the ray location from the database
        tmpDepth = RayDepthVector(idepth);
        tmpLat = interpLats(idepth);
        tmpLong = interpLons(idepth);
        tmpAmpR = interpAmpsR(idepth);
        tmpAmpT = interpAmpsT(idepth);

        % Convert to indices
        ix = floor((tmpLong - WestLongitude) / StepLongitude+0.5);
        iy = floor((tmpLat - SouthLatitude) / StepLatitude+0.5);
        iz = floor((tmpDepth - ShallowDepth) / StepDepth+0.5);
        
        % Here we drop just the ray theory based CCP info
        if (ix > 0 && ix <= nx && iy > 0 && iy <= ny && iz >0 && iz <= nz)
            CCPStackR(ix, iy, iz) = CCPStackR(ix, iy, iz) + tmpAmpR;
            CCPStackT(ix, iy, iz) = CCPStackT(ix, iy, iz) + tmpAmpT;
            CCPHits(ix, iy, iz)  = CCPHits(ix, iy, iz) + 1;
        end
        
        % To use the finite frequency sensitivity, define an annulus about
        % this point and multiply the sensitivity by the amplitude and add
        % to the stack at the proper ccp bin. 
        
        % Define the disk
        for itheta = 1:length(ThetaVector)
            for irad = 1:length(KernelRadialVector)
               kernelAmp = KernelRadialVector(irad);
               %DistanceFromRay = KernelDistanceMatrix(idepth, irad);
               
               % Now to convert the distance from the ray point to offset
               % in latitude and longitude
               tmpLat2 = tmpLat + DeltaLatLonMatrix(idepth,irad,itheta,2);% + (sind(ThetaVector(itheta)) * WavelengthVector(irad));
               tmpLong2 = tmpLong + DeltaLatLonMatrix(idepth,irad,itheta,1);% + (cosd(ThetaVector(itheta)) * WavelengthVector(irad));
               tmpDepth2 = tmpDepth;
               
               ix = floor((tmpLong2 - WestLongitude) / StepLongitude+0.5);
               iy = floor((tmpLat2 - SouthLatitude) / StepLatitude+0.5);
               iz = floor((tmpDepth2 - ShallowDepth) / StepDepth+0.5);
               if (ix > 0 && ix <= nx && iy > 0 && iy <= ny && iz >0 && iz <= nz)
                   CCPStackKernelR(ix, iy, iz) = CCPStackKernelR(ix, iy, iz) + tmpAmpR * kernelAmp;
                   CCPStackKernelT(ix, iy, iz) = CCPStackKernelT(ix, iy, iz) + tmpAmpT * kernelAmp;
                   CCPHitsKernel(ix, iy, iz)  = CCPHitsKernel(ix, iy, iz) + abs(kernelAmp);                   
               end
            end
        end
        
        
    end
    
    % User message for progress
    if mod(iray, 100) == 0
        waitbar(iray/nrays,wb);
    end
    if getappdata(wb,'canceling')
        delete(wb);
        disp('Canceled during CCP Stacking :(')
        return
    end
    
end

delete(wb);

tend = toc;
fprintf('Elapsed time to do CCP Stacking: %f seconds (%f minutes)\n',num2str(tend), num2str((tend)/60));

% Has user output volume to a mat file
if CurrentSubsetIndex == 1
    OutputFile = fullfile(ProjectDirectory, 'CCPV2', 'CCPV2_Volume.mat');
else
    OutputFile = fullfile(ProjectDirectory, 'CCPV2', SetName, 'CCPV2_Volume.mat');
end
[FileName,Pathname] = uiputfile('*.mat','Save CCP Volume to Mat File',OutputFile);
outputFile = fullfile(Pathname, FileName);
CCPV2MetadataStrings{2} = outputFile; 
if FileName ~= 0
    save(outputFile,'CCPStackR','CCPStackT','CCPHits','CCPStackKernelR','CCPStackKernelT','CCPHitsKernel','xvector','yvector','zvector');
end

% has the user output to a text file
%OutputFile = fullfile(ProjectDirectory, 'CCPV2', 'CCPV2_Volume.txt');
if CurrentSubsetIndex == 1
    OutputFile = fullfile(ProjectDirectory, 'CCPV2', 'CCPV2_Volume.txt');
else
    OutputFile = fullfile(ProjectDirectory, 'CCPV2', SetName, 'CCPV2_Volume.txt');
end

[FileName,Pathname] = uiputfile('*.txt','Save CCP Volume to TXT File',OutputFile);
outputFile = fullfile(Pathname, FileName);

wb = waitbar(0,'Exporting...');

if FileName ~= 0
    fid = fopen(outputFile,'w');
    
    for idx=1:length(xvector)
        for idy=1:length(yvector)
            for idz=1:length(zvector)
                fprintf(fid,'%f %f %f %f %f %f %f %f %f\n',xvector(idx), yvector(idy), zvector(idz), CCPStackR(idx,idy,idz), CCPStackT(idx,idy,idz), CCPHits(idx,idy,idz),...
                    CCPStackKernelR(idx,idy,idz),CCPStackKernelT(idx,idy,idz),CCPHitsKernel(idx,idy,idz));
            end
        end
        waitbar(idx / length(xvector),wb)
    end
    fclose(fid);
end
delete(wb);
% Add to the funclab project
if evalin('base','exist(''CCPV2MetadataCell'',''var'')')
    CCPV2MetadataCell = evalin('base','CCPV2MetadataCell');
    if size(CCPV2MetadataCell,1) < size(SetManagementCell,1)
        tmp = cell(size(SetManagementCell,1));
        for idx=1:size(CCPV2MetadataCell,1)
            tmp{idx} = CCPV2MetadataCell{idx};
        end
        CCV2PMetadataCell = tmp;
    end
    CCPV2MetadataCell{CurrentSubsetIndex} = CCPV2MetadataStrings;
else
    CCPV2MetadataCell = cell(size(SetManagementCell,1),1);
    CCPV2MetadataCell{CurrentSubsetIndex,1} = CCPV2MetadataStrings;
end
save([ProjectDirectory ProjectFile],'CCPV2MetadataCell','CCPV2MetadataStrings','-append');
assignin('base','CCPV2MetadataCell',CCPV2MetadataCell)
assignin('base','CCPV2MetadataStrings',CCPV2MetadataStrings);

close(gcbf)

