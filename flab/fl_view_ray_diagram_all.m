function fl_view_ray_diagram_all(ProjectDirectory,FuncLabPreferences)
%% FL_VIEW_RAY_DIAGRAM
%   makes a scatter3 plot of the depth mapped radial RFs 
%   Created 05/06/2015. Rob Porritt

%% Check for backwards compability
if length(FuncLabPreferences) < 21
    FuncLabPreferences{19} = 'vel.cpt';
    FuncLabPreferences{20} = false;
    FuncLabPreferences{21} = '1.8.1';
end

if FuncLabPreferences{20} == false
    cmap = cptcmap(FuncLabPreferences{19});
else
    cmap = cptcmap(FuncLabPreferences{19},'flip',true);
end
colormap(cmap);

ProjectFile = evalin('base','ProjectFile');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
SetManagementCell = evalin('base','SetManagementCell');
RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');

CurrentIndices = 1:length(RecordMetadataDoubles);

%% find the ray data diagram
load([ProjectDirectory ProjectFile])
if ~exist('ThreeDRayInfoFile','var')
    disp('Error, receiver functions not mapped to depth.')
    return
end

%% Launch the figure window
fig = figure ('Name',['All Receiver Functions in depth'],'Units','characters','NumberTitle','off',...
    'WindowStyle','normal','MenuBar','figure','Position',[0 0 220 58],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'},...
    'Color','white');


%% Read the data
readBaseFlag = 0;
if iscell(ThreeDRayInfoFile)
    if ~isempty(ThreeDRayInfoFile{CurrentSubsetIndex})
        load(ThreeDRayInfoFile{CurrentSubsetIndex});
    else
        readBaseFlag = 1;
        load(ThreeDRayInfoFile{1});
    end
else
    readBaseFlag = 1;
    load(ThreeDRayInfoFile);
end
% Gets RayInfo. cell array nrays x 1.
% Each cell is a structure with:
%  Latitude vector
%  Longitude vector
%  Radius vector
%  AmpR vector
%  AmpT vector
%  RecordNumber

%% Find the rays to plot
Latitudes = zeros(length(CurrentIndices) * length(RayInfo{1}.Latitude),1);
Longitudes = zeros(length(CurrentIndices) * length(RayInfo{1}.Latitude),1);
Radius = zeros(length(CurrentIndices) * length(RayInfo{1}.Latitude),1);
AmpR = zeros(length(CurrentIndices) * length(RayInfo{1}.Latitude),1);
AmpT = zeros(length(CurrentIndices) * length(RayInfo{1}.Latitude),1);

nray = 0;
% Get from the ray info
if readBaseFlag == 0
    kdx=0;
    for idx=1:length(CurrentIndices)
        SearchIndex = CurrentIndices(idx);
        %if RecordMetadataDoubles(SearchIndex,19) >= 285 && RecordMetadataDoubles(SearchIndex,19) <= 345
            for jdx=1:length(RayInfo)
                if SearchIndex == RayInfo{jdx}.RecordNumber && RayInfo{jdx}.isActive == 1
                    for n=1:length(RayInfo{jdx}.Latitude)
                        kdx = kdx + 1;
                        Latitudes(kdx) = RayInfo{jdx}.Latitude(n);
                        Longitudes(kdx) = RayInfo{jdx}.Longitude(n);
                        Radius(kdx) = 6371-RayInfo{jdx}.Radius(n);
                        AmpR(kdx) = RayInfo{jdx}.AmpR(n);
                        AmpT(kdx) = RayInfo{jdx}.AmpT(n);
                    end
                    nray = nray + 1;

                    break
                end
            end
       % end
    end
else
    kdx=0;
    SetIndices = SetManagementCell{CurrentSubsetIndex,1};
    for idx=1:length(CurrentIndices)
        SearchIndex = SetIndices(CurrentIndices(idx));
        for jdx=1:length(RayInfo)
            if SearchIndex == RayInfo{jdx}.RecordNumber && RayInfo{jdx}.isActive == 1
                for n=1:length(RayInfo{jdx}.Latitude)
                    kdx = kdx + 1;
                    Latitudes(kdx) = RayInfo{jdx}.Latitude(n);
                    Longitudes(kdx) = RayInfo{jdx}.Longitude(n);
                    Radius(kdx) = 6371-RayInfo{jdx}.Radius(n);
                    AmpR(kdx) = RayInfo{jdx}.AmpR(n);
                    AmpT(kdx) = RayInfo{jdx}.AmpT(n);
                end
                nray = nray + 1;

                break
            end
        end
    end
end


for idx=length(CurrentIndices) * length(RayInfo{1}.Latitude):-1:1
    if Latitudes(idx) == 0
        Latitudes(idx) = [];
        Longitudes(idx) = [];
        Radius(idx) = [];
        AmpR(idx) = [];
        AmpT(idx) = [];
    end
end


%% Scatter plot
ax = axis;
% Change here to plot the T component instead
scatter3(Longitudes, Latitudes, Radius, 25, AmpR,'filled')

%fid = fopen('AllRayPoints.dat','w');
%for idx=1:length(AmpR)
%    fprintf(fid,'%f %f %f %f %f\n',Longitudes(idx), Latitudes(idx), 6371 - Radius(idx), AmpR(idx), AmpT(idx));
%end
%fclose(fid);

caxis([-.1 .1])
axis tight
title('Radial RF Ray Diagram')
xlabel('Longitude (deg, no projection)')
ylabel('Latitude (deg, no projection)')
zlabel('Depth (km)')
set(gca,'zdir','reverse')
colorbar


