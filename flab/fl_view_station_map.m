function fl_view_station_map(ProjectDirectory,ProjectFile,RecordMetadataStrings,RecordMetadataDoubles,Record)
%FL_VIEW_STATION_MAP View station map
%   FL_VIEW_STATION_MAP(ProjectDirectory,ProjectFile,RecordMetadataStrings,
%   RecordMetadataDoubles) plots a regional map of the stations.
%
%   Active events are gray, while inactive events are red, currently
%   selected is gold.
%
%   Note: The hi-res topography does not include bathymetry.
%
%   REQUIRES MAPPING TOOLBOX INSTALLED
%
%   Author: Kevin C. Eagar
%   Date Created: 05/15/2010
%   Last Updated: 12/30/2010
%
% Updated by Rob Porritt to remove need for mapping toolbox
%   Versions 1.6.0 - 1.7.1 used a crude map without any projection
%   Versions 1.7.2+ use m_map from Rich Pawlowicz

MapDataPath = regexprep(which('funclab'),'funclab.m','map_data/');

load([ProjectDirectory ProjectFile],'FuncLabPreferences')

% Set latitude and longitude limits
%--------------------------------------------------------------------------
NorthLat = str2double(FuncLabPreferences{13});
SouthLat = str2double(FuncLabPreferences{14});
WestLon = str2double(FuncLabPreferences{15});
EastLon = str2double(FuncLabPreferences{16});

% Get current record info
CurrentStationLatitude = Record{13};
CurrentStationLongitude = Record{14};
CurrentEventLatitude = Record{16};
CurrentEventLongitude = Record{17};

% RecordMetadataStrings and RecordMetadataDoubles appears to pull in the
% full set from the base set. Here we pull up the SetManagementCell to get
% the metadata for the currently active set.
SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
SetMetadataStrings = SetManagementCell{CurrentSubsetIndex,2};
SetMetadataDoubles = SetManagementCell{CurrentSubsetIndex,3};
RecordMetadataDoubles = SetManagementCell{1,3};
RecordMetadataStrings = SetManagementCell{1,2};

% For mapping toolbox, if you want to show rivers, change this to 1
showrivers = 0;
% Adjust the topo axis for your region. Getting the shoreline just right
% takes some tinkering
%topoaxis = [-11000 6000];
% Example, working for texas or Alaska:
topoaxis = [-11075 6000];
% Michigan
 %topoaxis = [-10575 6000];

% Set map projection
%--------------------------------------------------------------------------
MapProjection = FuncLabPreferences{10};

% Setup the global map using low-level functions (geoshow is giving me
% problems for some reason - keeps crashing and logging me out!)
%--------------------------------------------------------------------------
figure('Units','characters','NumberTitle','off','Name','Station Map','Units','characters',...
    'Position',[0 0 165 55],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});

% Set available projections
if license('test', 'MAP_Toolbox')
%     ProjectionListNames = maps('namelist');
%     ProjectionListIDs = maps('idlist');
    ProjectionListNames = {'Balthasart Cylindrical','Behrmann Cylindrical','Bolshoi Sovietskii Atlas Mira','Braun Perspective',...
        'Cassini Cylindrical', 'Cassini Cylindrical - Standard','Central Cylindrical','Equal-Area Cylindrical','Equidistance Cylindrical',...
        'Gall Isographic','Gall Orthographic','Gall Stereographic','Lambert Conformal Conic','Mercator','Miller Cylindrical',...
        'Plate Carree','Transverse Mercator','Trystan Edwards Cylindrical','Wetch Cylindrical','Albers Equal-Area Conic',...
        'Albers Equal-Area - Standard','Equidistance Conic','Equidistant Conic - Standard','Lambert Conformal Conic','Lamert Conformal Conic - Standard',...
        'Murdoch I Conic','Murdoch III Minimum Error Conic','Aitoff','Breusing Harmonic Mean','Briesemeister','Lambert Azimuthal Equal-Area',...
        'Equidistant Azimuthal','Gnomonic','Hammer','Orthographic','Stereographic','Vertical Perspective Azimuthal','Wiechel'};
    ProjectionListIDs = {'balthsrt','behrmann','bsam','braun','cassini','cassinistd','ccylin','eqacylin','eqdcylin',...
        'giso','gortho','gstereo','lambert','mercator','miller','pcarree','tranmerc','trystan','wetch','eqaconic','eqaconicstd',...
        'eqdconic','eqdconicstd','lambert','lambertstd','murdoch1','murdoch3','aitoff','breusing','bries','eqaazim','eqdazim',...
        'gnomonic','hammer','ortho','stereo','vperspec','wiechel'};
else
    ProjectionListNames = {'Stereographic','Orthographic','Azimuthal Equal-area','Azimuthal Equidistant','Gnomonic',...
        'Satellite','Albers Equal-Area Conic','Lambert Conformal Conic','Mercator','Miller Cylindrical','Equidistant Cylindrical',...
        'Transverse Mercator','Sinusoidal','Gall-Peters','Hammer-Aitoff','Mollweide','Robinson','UTM'};
    ProjectionListIDs = ProjectionListNames;
end
MapProjectionIDX = strmatch(MapProjection,ProjectionListNames,'exact');
MapProjectionID = ProjectionListIDs{MapProjectionIDX};

% Checks for existance of mapping toolkit
if license('test', 'MAP_Toolbox')

axesm('MapProjection',MapProjectionID,'MapLatLimit',[SouthLat NorthLat],'MapLonLimit',[WestLon EastLon],...
    'Frame','on','Grid','on','MeridianLabel','on','MLineLocation',1,'ParallelLabel','on','PLineLocation',1);
set(gca,'XColor',[1 1 1],'YColor',[1 1 1]);
get(gca,'position');
switch FuncLabPreferences{12}
    case 'Coastlines (low-res)'
        if ~exist([MapDataPath 'gshhg-bin' filesep 'gshhs_c.b'])
            disp('No gshhs_c.b coastline data exists.  Please download at https://www.ngdc.noaa.gov/mgg/shorelines/data/gshhs/latest/')
            %close
            %return
            load('FL_coasts.mat');
            coasts.long=ncst(:,1);
            coasts.lat=ncst(:,2);
            geoshow(coasts)
            linem([coasts.lat],[coasts.long],'LineWidth',1,'Color',[0 0 0])
        else
            % Load in coastline data
            %------------------------------------------------------------------
            coasts = gshhs([MapDataPath 'gshhg-bin' filesep  'gshhs_c.b'],[SouthLat NorthLat],[WestLon EastLon]);
            geoshow(coasts, 'FaceColor',[.6 .4 .3],'EdgeColor',[0 0 0])
            linem([coasts.Lat],[coasts.Lon],'LineWidth',1,'Color',[0 0 0])
            % load borders data
            borders = gshhs([MapDataPath filesep 'gshhg-bin' filesep 'wdb_borders_c.b'],[SouthLat NorthLat],[WestLon EastLon]);
            linem([borders.Lat],[borders.Lon],'LineWidth',1,'Color',[0 0 0]);
            if showrivers == 1
                rivers = gshhs([MapDataPath filesep 'gshhg-bin' filesep 'wdb_rivers_c.b'],[SouthLat NorthLat],[WestLon EastLon]);
                linem([rivers.Lat],[rivers.Lon],'LineWidth',1,'Color',[0 0 0]);
            end
        end
    case 'Coastlines (medium-res)'
        if ~exist([MapDataPath 'gshhg-bin' filesep  'gshhs_i.b'])
            disp('No gshhs_c.b coastline data exists.  Please download at https://www.ngdc.noaa.gov/mgg/shorelines/data/gshhs/latest/')
            %close
            %return
            load('FL_coasts.mat');
            coasts.long=ncst(:,1);
            coasts.lat=ncst(:,2);
            geoshow(coasts)
            linem([coasts.lat],[coasts.long],'LineWidth',1,'Color',[0 0 0])
        else
            % Load in coastline data
            %------------------------------------------------------------------
            coasts = gshhs([MapDataPath 'gshhg-bin' filesep  'gshhs_i.b'],[SouthLat NorthLat],[WestLon EastLon]);
            geoshow(coasts, 'FaceColor',[.6 .4 .3],'EdgeColor',[0 0 0])
            linem([coasts.Lat],[coasts.Lon],'LineWidth',1,'Color',[0 0 0])
            % load borders data
            borders = gshhs([MapDataPath 'gshhg-bin' filesep 'wdb_borders_i.b'],[SouthLat NorthLat],[WestLon EastLon]);
            linem([borders.Lat],[borders.Lon],'LineWidth',1,'Color',[0 0 0]);
            if showrivers == 1
                rivers = gshhs([MapDataPath filesep 'gshhg-bin' filesep 'wdb_rivers_i.b'],[SouthLat NorthLat],[WestLon EastLon]);
                linem([rivers.Lat],[rivers.Lon],'LineWidth',1,'Color',[0 0 0]);
            end
        end
    case 'Coastlines (hi-res)'
        if ~exist([MapDataPath 'gshhg-bin' filesep  'gshhs_h.b'])
            disp('No gshhs_c.b coastline data exists.  Please download at https://www.ngdc.noaa.gov/mgg/shorelines/data/gshhs/latest/')
            %close
            %return
            load('FL_coasts.mat');
            coasts.long=ncst(:,1);
            coasts.lat=ncst(:,2);
            geoshow(coasts)
            linem([coasts.lat],[coasts.long],'LineWidth',1,'Color',[0 0 0])
        else
            % Load in coastline data
            %------------------------------------------------------------------
            coasts = gshhs([MapDataPath 'gshhg-bin' filesep  'gshhs_h.b'],[SouthLat NorthLat],[WestLon EastLon]);
            geoshow(coasts, 'FaceColor',[.6 .4 .3],'EdgeColor',[0 0 0])
            linem([coasts.Lat],[coasts.Lon],'LineWidth',1,'Color',[0 0 0])
            % load borders data
            borders = gshhs([MapDataPath 'gshhg-bin' filesep 'wdb_borders_h.b'],[SouthLat NorthLat],[WestLon EastLon]);
            linem([borders.Lat],[borders.Lon],'LineWidth',1,'Color',[0 0 0]);
            if showrivers == 1
                rivers = gshhs([MapDataPath filesep 'gshhg-bin' filesep 'wdb_rivers_h.b'],[SouthLat NorthLat],[WestLon EastLon]);
                linem([rivers.Lat],[rivers.Lon],'LineWidth',1,'Color',[0 0 0]);
            end
        end
    case 'Topography (low-res)'
        if ~exist([MapDataPath 'etopo1_bed_c_i2.bin'])
            disp('No etopo1_bed_c_i2.bin topography data exists.  Please download at https://www.ngdc.noaa.gov/mgg/global/relief/ETOPO1/data/bedrock/cell_registered/binary/etopo1_bed_c_i2.zip')
            %close
            %return
            lon=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lon');
            lat=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lat');
            z=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','z');
            lonlon = repmat(lon,1,181);
            latlat = repmat(lat,1,361);
            surfacem(latlat', lonlon, z)
            %demcmap(z)
            cptcmap('topography_rwp.cpt');
            caxis(topoaxis);
        else
            % Load in ETOPO2v2 Topography and Bathymatry data and plot
            %------------------------------------------------------------------
            [TopoGrid,topo_refvec] = etopo([MapDataPath 'etopo1_bed_c_i2.bin'],10,[SouthLat NorthLat],[WestLon EastLon]); % Updated ETOPO
            disp('Station map made using updated etopo1_bed_c_i2.bin topography.')
            [topo_lat,topo_lon] = meshgrat([SouthLat NorthLat],[WestLon EastLon],size(TopoGrid));
            surfacem(topo_lat,topo_lon,TopoGrid);
            %demcmap(TopoGrid)
            cptcmap('topography_rwp.cpt');
            caxis(topoaxis);
            borders = gshhs([MapDataPath 'gshhg-bin' filesep 'wdb_borders_c.b'],[SouthLat NorthLat],[WestLon EastLon]);
            linem([borders.Lat],[borders.Lon],'LineWidth',1,'Color',[0 0 0]);
        end
        hold on
        if ~exist([MapDataPath 'gshhg-bin' filesep 'gshhs_c.b'])
            disp('No gshhs_c.b coastline data exists.  Please download at https://www.ngdc.noaa.gov/mgg/shorelines/data/gshhs/latest/')
            %close
            %return
            load('FL_coasts.mat');
            coasts.long=ncst(:,1);
            coasts.lat=ncst(:,2);
            geoshow(coasts)
            linem([coasts.lat],[coasts.long],'LineWidth',1,'Color',[0 0 0])
        else
            % Load in coastline data
            %------------------------------------------------------------------
            coasts = gshhs([MapDataPath 'gshhg-bin' filesep  'gshhs_c.b'],[SouthLat NorthLat],[WestLon EastLon]);
            %geoshow(coasts, 'FaceColor',[.6 .4 .3],'EdgeColor',[0 0 0])
            linem([coasts.Lat],[coasts.Lon],'LineWidth',1,'Color',[0 0 0])
            % load borders data
            borders = gshhs([MapDataPath filesep 'gshhg-bin' filesep 'wdb_borders_c.b'],[SouthLat NorthLat],[WestLon EastLon]);
            linem([borders.Lat],[borders.Lon],'LineWidth',1,'Color',[0 0 0]);
            if showrivers == 1
                rivers = gshhs([MapDataPath filesep 'gshhg-bin' filesep 'wdb_rivers_c.b'],[SouthLat NorthLat],[WestLon EastLon]);
                linem([rivers.Lat],[rivers.Lon],'LineWidth',1,'Color',[0 0 0]);
            end
        end
    case 'Topography (medium-res)'
        if ~exist([MapDataPath 'etopo1_bed_c_i2.bin'])
            disp('No etopo1_bed_c_i2.bin topography data exists.  Please download at https://www.ngdc.noaa.gov/mgg/global/relief/ETOPO1/data/bedrock/cell_registered/binary/etopo1_bed_c_i2.zip')
            %close
            %return
            lon=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lon');
            lat=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lat');
            z=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','z');
            lonlon = repmat(lon,1,181);
            latlat = repmat(lat,1,361);
            surfacem(latlat', lonlon, z)
            %demcmap(z)
            cptcmap('topography_rwp.cpt');
            caxis(topoaxis);
        else
            [TopoGrid,topo_refvec] = etopo([MapDataPath 'etopo1_bed_c_i2.bin'],5,[SouthLat NorthLat],[WestLon EastLon]);
            [topo_lat,topo_lon] = meshgrat([SouthLat NorthLat],[WestLon EastLon],size(TopoGrid));
            surfacem(topo_lat,topo_lon,TopoGrid);
            %demcmap(TopoGrid)
            cptcmap('topography_rwp.cpt');
            caxis(topoaxis);
            borders = gshhs([MapDataPath 'gshhg-bin' filesep 'wdb_borders_i.b'],[SouthLat NorthLat],[WestLon EastLon]);
            linem([borders.Lat],[borders.Lon],'LineWidth',1,'Color',[0 0 0]);
        end
        hold on
        if ~exist([MapDataPath 'gshhg-bin' filesep 'gshhs_i.b'])
            disp('No gshhs_i.b coastline data exists.  Please download at https://www.ngdc.noaa.gov/mgg/shorelines/data/gshhs/latest/')
            %close
            %return
            load('FL_coasts.mat');
            coasts.long=ncst(:,1);
            coasts.lat=ncst(:,2);
            geoshow(coasts)
            linem([coasts.lat],[coasts.long],'LineWidth',1,'Color',[0 0 0])
        else
            % Load in coastline data
            %------------------------------------------------------------------
            coasts = gshhs([MapDataPath 'gshhg-bin' filesep  'gshhs_i.b'],[SouthLat NorthLat],[WestLon EastLon]);
            %geoshow(coasts, 'FaceColor',[.6 .4 .3],'EdgeColor',[0 0 0])
            linem([coasts.Lat],[coasts.Lon],'LineWidth',1,'Color',[0 0 0])
            % load borders data
            borders = gshhs([MapDataPath filesep 'gshhg-bin' filesep 'wdb_borders_i.b'],[SouthLat NorthLat],[WestLon EastLon]);
            linem([borders.Lat],[borders.Lon],'LineWidth',1,'Color',[0 0 0]);
            if showrivers == 1
                rivers = gshhs([MapDataPath filesep 'gshhg-bin' filesep 'wdb_rivers_i.b'],[SouthLat NorthLat],[WestLon EastLon]);
                linem([rivers.Lat],[rivers.Lon],'LineWidth',1,'Color',[0 0 0]);
            end
        end
    case 'Topography (hi-res)'
        if ~exist([MapDataPath 'etopo1_bed_c_i2.bin'])
            disp('No etopo1_bed_c_i2.bin topography data exists.  Please download at https://www.ngdc.noaa.gov/mgg/global/relief/ETOPO1/data/bedrock/cell_registered/binary/etopo1_bed_c_i2.zip')
            %close
            %return
            lon=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lon');
            lat=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lat');
            z=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','z');
            lonlon = repmat(lon,1,181);
            latlat = repmat(lat,1,361);
            surfacem(latlat', lonlon, z)
            %demcmap(z)
            cptcmap('topography_rwp.cpt');
            caxis(topoaxis);
        else
            [TopoGrid,topo_refvec] = etopo([MapDataPath 'etopo1_bed_c_i2.bin'],1,[SouthLat NorthLat],[WestLon EastLon]);
            [topo_lat,topo_lon] = meshgrat([SouthLat NorthLat],[WestLon EastLon],size(TopoGrid));
            surfacem(topo_lat,topo_lon,TopoGrid);
            %demcmap(TopoGrid)
            cptcmap('topography_rwp.cpt');
            caxis(topoaxis);
            colorbar
            borders = gshhs([MapDataPath 'gshhg-bin' filesep 'wdb_borders_h.b'],[SouthLat NorthLat],[WestLon EastLon]);
            linem([borders.Lat],[borders.Lon],'LineWidth',1,'Color',[0 0 0]);
        end
        hold on
        if ~exist([MapDataPath 'gshhg-bin' filesep 'gshhs_h.b'])
            disp('No gshhs_h.b coastline data exists.  Please download at https://www.ngdc.noaa.gov/mgg/shorelines/data/gshhs/latest/')
            %close
            %return
            load('FL_coasts.mat');
            coasts.long=ncst(:,1);
            coasts.lat=ncst(:,2);
            geoshow(coasts)
            linem([coasts.lat],[coasts.long],'LineWidth',1,'Color',[0 0 0])
        else
            % Load in coastline data
            %------------------------------------------------------------------
            coasts = gshhs([MapDataPath 'gshhg-bin' filesep  'gshhs_h.b'],[SouthLat NorthLat],[WestLon EastLon]);
            %geoshow(coasts, 'FaceColor',[.6 .4 .3],'EdgeColor',[0 0 0])
            linem([coasts.Lat],[coasts.Lon],'LineWidth',1,'Color',[0 0 0])
            % load borders data
            borders = gshhs([MapDataPath filesep 'gshhg-bin' filesep 'wdb_borders_h.b'],[SouthLat NorthLat],[WestLon EastLon]);
            linem([borders.Lat],[borders.Lon],'LineWidth',1,'Color',[0 0 0]);
            if showrivers == 1
                rivers = gshhs([MapDataPath filesep 'gshhg-bin' filesep 'wdb_rivers_h.b'],[SouthLat NorthLat],[WestLon EastLon]);
                linem([rivers.Lat],[rivers.Lon],'LineWidth',1,'Color',[0 0 0]);
            end
        end
        % Original; RWP update to just load etopo at max resolution
%         globeFile = globedems([SouthLat NorthLat],[WestLon EastLon]);
%         for n = 1:length(globeFile)
%             if ~exist([MapDataPath '/GLOBE_DEM/' globeFile{n}])
%                 disp(['No ' globeFile{n} ' topography data exists.  Please download at http://www.ngdc.noaa.gov/mgg/topo/DATATILES/elev/all10g.zip'])
%                 close
%                 return
%             end
%         end
%         if ~exist([MapDataPath '/GLOBE_DEM/' globeFile{n}])
%             lon=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lon');
%             lat=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lat');
%             z=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','z');
%             lonlon = repmat(lon,1,181);
%             latlat = repmat(lat,1,361);
%             surfacem(latlat', lonlon, z)
%             demcmap(z)
%         else
%             for n = 1:length(globeFile)
%                 [TopoGrid,topo_refvec] = globedem([MapDataPath '/GLOBE_DEM/' globeFile{n}],10,[SouthLat NorthLat],[WestLon EastLon]);
%                 [topo_lat,topo_lon] = meshgrat([SouthLat NorthLat],[WestLon EastLon],size(TopoGrid));
%                 surfacem(topo_lat,topo_lon,TopoGrid);
%                 demcmap(TopoGrid)
%             end
%         end
end

OnColor = [.3 .3 .3];
OffColor = [1 .5 .5];
CurrentColor = [ 1 .7 0];
SetOnColor = SetManagementCell{CurrentSubsetIndex,6} / 255;
SetOffColor = abs(cross(SetOnColor,OnColor));
switch FuncLabPreferences{9}
    case 'All'
        % Get only active event locations
        %------------------------------------------------------------------
        ActiveIn = find(RecordMetadataDoubles(:,2));
        ActiveDoubles = RecordMetadataDoubles(ActiveIn,:);
        ActiveStrings = RecordMetadataStrings(ActiveIn,:);
        [junk,indices,junk] = unique(ActiveStrings(:,2));
        ActiveEventLatitudes = ActiveDoubles(indices,10);
        ActiveEventLongitudes = ActiveDoubles(indices,11);
        % Get only inactive event locations
        %------------------------------------------------------------------
        InactiveIn = find(RecordMetadataDoubles(:,2)==0);
        if ~isempty(InactiveIn)
            InactiveDoubles = RecordMetadataDoubles(InactiveIn,:);
            InactiveStrings = RecordMetadataStrings(InactiveIn,:);
            [junk,indices,junk] = unique(InactiveStrings(:,2));
            InactiveEventLatitudes = InactiveDoubles(indices,10);
            InactiveEventLongitudes = InactiveDoubles(indices,11);
            linem(InactiveEventLatitudes,InactiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OffColor)
        end
        linem(ActiveEventLatitudes,ActiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
        
        % Repeat for the active set and plot over them
        ActiveIn = find(SetMetadataDoubles(:,2));
        ActiveDoubles = SetMetadataDoubles(ActiveIn,:);
        ActiveStrings = SetMetadataStrings(ActiveIn,:);
        [junk,indices,junk] = unique(ActiveStrings(:,2));
        ActiveEventLatitudes = ActiveDoubles(indices,10);
        ActiveEventLongitudes = ActiveDoubles(indices,11);
        % Get only inactive event locations
        %------------------------------------------------------------------
        InactiveIn = find(SetMetadataDoubles(:,2)==0);
        if ~isempty(InactiveIn)
            InactiveDoubles = SetMetadataDoubles(InactiveIn,:);
            InactiveStrings = SetMetadataStrings(InactiveIn,:);
            [junk,indices,junk] = unique(InactiveStrings(:,2));
            InactiveEventLatitudes = InactiveDoubles(indices,10);
            InactiveEventLongitudes = InactiveDoubles(indices,11);
            linem(InactiveEventLatitudes,InactiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',SetOffColor)
        end
        linem(ActiveEventLatitudes,ActiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',SetOnColor)       
    case 'Active'
        % Get only active event locations
        %------------------------------------------------------------------
        ActiveIn = find(RecordMetadataDoubles(:,2));
        ActiveDoubles = RecordMetadataDoubles(ActiveIn,:);
        ActiveStrings = RecordMetadataStrings(ActiveIn,:);
        [junk,indices,junk] = unique(ActiveStrings(:,2));
        ActiveEventLatitudes = ActiveDoubles(indices,10);
        ActiveEventLongitudes = ActiveDoubles(indices,11);
        linem(ActiveEventLatitudes,ActiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
        % Get only active event locations for the subset
        %------------------------------------------------------------------
        ActiveIn = find(SetMetadataDoubles(:,2));
        ActiveDoubles = SetMetadataDoubles(ActiveIn,:);
        ActiveStrings = SetMetadataStrings(ActiveIn,:);
        [junk,indices,junk] = unique(ActiveStrings(:,2));
        ActiveEventLatitudes = ActiveDoubles(indices,10);
        ActiveEventLongitudes = ActiveDoubles(indices,11);
        linem(ActiveEventLatitudes,ActiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',SetOnColor)

    case 'Inactive'
        % Get only inactive event locations
        %------------------------------------------------------------------
        InactiveIn = find(RecordMetadataDoubles(:,2)==0);
        InactiveDoubles = RecordMetadataDoubles(InactiveIn,:);
        InactiveStrings = RecordMetadataStrings(InactiveIn,:);
        [junk,indices,junk] = unique(InactiveStrings(:,2));
        InactiveEventLatitudes = InactiveDoubles(indices,10);
        InactiveEventLongitudes = InactiveDoubles(indices,11);
        linem(InactiveEventLatitudes,InactiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
        % Get only inactive event locations for current set
        %------------------------------------------------------------------
        InactiveIn = find(SetMetadataDoubles(:,2)==0);
        InactiveDoubles = SetMetadataDoubles(InactiveIn,:);
        InactiveStrings = SetMetadataStrings(InactiveIn,:);
        [junk,indices,junk] = unique(InactiveStrings(:,2));
        InactiveEventLatitudes = InactiveDoubles(indices,10);
        InactiveEventLongitudes = InactiveDoubles(indices,11);
        linem(InactiveEventLatitudes,InactiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',SetOnColor)
end
    linem(CurrentStationLatitude, CurrentStationLongitude,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',CurrentColor)
% Use m_map
else
   
%axesm('MapProjection',MapProjection,'MapLatLimit',[SouthLat NorthLat],'MapLonLimit',[WestLon EastLon],...
%    'Frame','on','Grid','on','MeridianLabel','on','MLineLocation',1,'ParallelLabel','on','PLineLocation',1);
if strcmp(MapProjectionID,'Stereographic') || strcmp(MapProjectionID,'Orthographic') || strcmp(MapProjectionID,'Azimuthal Equal-area') || ...
        strcmp(MapProjectionID,'Azimuthal Equidistant') || strcmp(MapProjectionID,'Gnomonic') || strcmp(MapProjectionID,'Satellite')    
    [~, ~, xdeg] = distaz(SouthLat, WestLon, NorthLat, EastLon);
    m_proj(MapProjectionID,'latitude',(SouthLat + NorthLat)/2, 'longitude',(WestLon + EastLon) / 2,'radius',xdeg/2);
else
    m_proj(MapProjectionID,'latitude',[SouthLat NorthLat],'longitude',[WestLon EastLon]);
end
set(gca,'XColor',[1 1 1],'YColor',[1 1 1]);
get(gca,'position');
switch FuncLabPreferences{12}
    case 'Coastlines (low-res)'
        if ~exist([MapDataPath  filesep 'gshhg-bin' filesep 'gshhs_l.b']) && ~exist('gshhs_c.b')
            disp('No gshhs_c.b coastline data exists.  Please download at https://www.ngdc.noaa.gov/mgg/shorelines/data/gshhs/latest/')
            disp('m_map version does not support variable resolution coast lines or topography.')
            m_gshhs_l('patch',[.9 .9 .9],'edgecolor','black');
            m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
        else
            m_gshhs_l('patch',[.9 .9 .9],'edgecolor','black');
            m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
        end
    case 'Coastlines (medium-res)'
        disp('m_map version does not fully support variable resolution coast lines or topography.')
        %m_coast('patch',[.9 .9 .9],'edgecolor','black');
        m_gshhs_i('patch',[.9 .9 .9],'edgecolor','black');
        m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
    case 'Coastlines (hi-res)'
        disp('m_map version does not support variable resolution coast lines or topography.')
        %m_coast('patch',[.9 .9 .9],'edgecolor','black');
        m_gshhs_h('patch',[.9 .9 .9],'edgecolor','black');
        m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
    case 'Topography (low-res)'
        disp('m_map version does not fully support variable resolution coast lines or topography.')
        m_gshhs_l('patch',[.9 .9 .9],'edgecolor','black');
        m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
        cptcmap('topography_rwp.cpt')
        m_elev;
    case 'Topography (medium-res)'
        disp('m_map version does not fully support variable resolution coast lines or topography.')
        %m_coast('patch',[.9 .9 .9],'edgecolor','black');
        m_gshhs_i('patch',[.9 .9 .9],'edgecolor','black');
        m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
        cptcmap('topography_rwp.cpt')
        m_elev;
    case 'Topography (hi-res)'
        disp('m_map version does not fully support variable resolution coast lines or topography.')
        %m_coast('patch',[.9 .9 .9],'edgecolor','black');
        m_gshhs_h('patch',[.9 .9 .9],'edgecolor','black');
        m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
        cptcmap('topography_rwp.cpt')
        m_elev;
end
OnColor = [.3 .3 .3];
OffColor = [1 .5 .5];
CurrentColor = [ 1 .7 0];
SetOnColor = SetManagementCell{CurrentSubsetIndex,6} / 255;
SetOffColor = abs(cross(SetOnColor,OnColor));
switch FuncLabPreferences{9}
    case 'All'
        % Get only active station locations
        %------------------------------------------------------------------
        ActiveIn = find(RecordMetadataDoubles(:,2));
        ActiveDoubles = RecordMetadataDoubles(ActiveIn,:);
        ActiveStrings = RecordMetadataStrings(ActiveIn,:);
        [junk,indices,junk] = unique(ActiveStrings(:,2));
        ActiveEventLatitudes = ActiveDoubles(indices,10);
        ActiveEventLongitudes = ActiveDoubles(indices,11);
        % Get only inactive station locations
        %------------------------------------------------------------------
        InactiveIn = find(RecordMetadataDoubles(:,2)==0);
        if ~isempty(InactiveIn)
            InactiveDoubles = RecordMetadataDoubles(InactiveIn,:);
            InactiveStrings = RecordMetadataStrings(InactiveIn,:);
            [junk,indices,junk] = unique(InactiveStrings(:,2));
            InactiveEventLatitudes = InactiveDoubles(indices,10);
            InactiveEventLongitudes = InactiveDoubles(indices,11);
            m_line(InactiveEventLongitudes,InactiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OffColor)
        end
        m_line(ActiveEventLongitudes,ActiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
        % Get only active station locations for current set
        %------------------------------------------------------------------
        ActiveIn = find(SetMetadataDoubles(:,2));
        ActiveDoubles = SetMetadataDoubles(ActiveIn,:);
        ActiveStrings = SetMetadataStrings(ActiveIn,:);
        [junk,indices,junk] = unique(ActiveStrings(:,2));
        ActiveEventLatitudes = ActiveDoubles(indices,10);
        ActiveEventLongitudes = ActiveDoubles(indices,11);
        % Get only inactive station locations
        %------------------------------------------------------------------
        InactiveIn = find(SetMetadataDoubles(:,2)==0);
        if ~isempty(InactiveIn)
            InactiveDoubles = SetMetadataDoubles(InactiveIn,:);
            InactiveStrings = SetMetadataStrings(InactiveIn,:);
            [junk,indices,junk] = unique(InactiveStrings(:,2));
            InactiveEventLatitudes = InactiveDoubles(indices,10);
            InactiveEventLongitudes = InactiveDoubles(indices,11);
            m_line(InactiveEventLongitudes,InactiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',SetOffColor)
        end
        m_line(ActiveEventLongitudes,ActiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',SetOnColor)

    case 'Active'
        % Get only active station locations
        %------------------------------------------------------------------
        ActiveIn = find(RecordMetadataDoubles(:,2));
        ActiveDoubles = RecordMetadataDoubles(ActiveIn,:);
        ActiveStrings = RecordMetadataStrings(ActiveIn,:);
        [junk,indices,junk] = unique(ActiveStrings(:,2));
        ActiveEventLatitudes = ActiveDoubles(indices,10);
        ActiveEventLongitudes = ActiveDoubles(indices,11);
        m_line(ActiveEventLongitudes,ActiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
         % Get only active station locations for the current set
        %------------------------------------------------------------------
        ActiveIn = find(SetMetadataDoubles(:,2));
        ActiveDoubles = SetMetadataDoubles(ActiveIn,:);
        ActiveStrings = SetMetadataStrings(ActiveIn,:);
        [junk,indices,junk] = unique(ActiveStrings(:,2));
        ActiveEventLatitudes = ActiveDoubles(indices,10);
        ActiveEventLongitudes = ActiveDoubles(indices,11);
        m_line(ActiveEventLongitudes,ActiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',SetOnColor)

    case 'Inactive'
        % Get only inactive station locations
        %------------------------------------------------------------------
        InactiveIn = find(RecordMetadataDoubles(:,2)==0);
        InactiveDoubles = RecordMetadataDoubles(InactiveIn,:);
        InactiveStrings = RecordMetadataStrings(InactiveIn,:);
        [junk,indices,junk] = unique(InactiveStrings(:,2));
        InactiveEventLatitudes = InactiveDoubles(indices,10);
        InactiveEventLongitudes = InactiveDoubles(indices,11);
        m_line(InactiveEventLongitudes,InactiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
        % Get only inactive station locations for the current set
        %------------------------------------------------------------------
        InactiveIn = find(SetMetadataDoubles(:,2)==0);
        InactiveDoubles = SetMetadataDoubles(InactiveIn,:);
        InactiveStrings = SetMetadataStrings(InactiveIn,:);
        [junk,indices,junk] = unique(InactiveStrings(:,2));
        InactiveEventLatitudes = InactiveDoubles(indices,10);
        InactiveEventLongitudes = InactiveDoubles(indices,11);
        m_line(InactiveEventLongitudes,InactiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',SetOnColor)

end 
        m_line(CurrentStationLongitude, CurrentStationLatitude,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',CurrentColor) 
end





%% Case without m_map
% Otherwise draws a simple station map
% else
%     if WestLon > min(RecordMetadataDoubles(:,11))
%         if WestLon < 0
%             WestLon = min(RecordMetadataDoubles(:,11)) * 1.05;
%         else
%            WestLon = min(RecordMetadataDoubles(:,11)) * 0.95;
%         end
%     end
%     if EastLon < max(RecordMetadataDoubles(:,11))
%         if EastLon < 0
%            EastLon = max(RecordMetadataDoubles(:,11)) * 0.95;
%         else
%            EastLon = max(RecordMetadataDoubles(:,11)) * 1.05;
%         end
%     end
%     if SouthLat > min(RecordMetadataDoubles(:,10))
%         if SouthLat < 0
%             SouthLat = min(RecordMetadataDoubles(:,10)) * 1.05;
%         else
%            SouthLat = min(RecordMetadataDoubles(:,10)) * 0.95;
%         end
%     end
%     if NorthLat < max(RecordMetadataDoubles(:,10))
%         if NorthLat < 0
%            NorthLat = max(RecordMetadataDoubles(:,10)) * 0.95;
%         else
%            NorthLat = max(RecordMetadataDoubles(:,10)) * 1.05;
%         end
%     end
%     axes('XGrid','on','YGrid','on','XLim', [WestLon EastLon], 'YLim', [SouthLat NorthLat]);
%     %lon=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lon');
%     %lat=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lat');
%     %z=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','z');
%     %lonlon = repmat(lon,1,181);
%     %latlat = repmat(lat,1,361);
%     %contourf(lonlon,latlat',z)
%     hold on
%     load('FL_coasts.mat');
%     load('FL_stateBoundaries.mat');
%     load('FL_plates.mat');
%     plot(ncst(:,1),ncst(:,2),'k',stateBoundaries.longitude, stateBoundaries.latitude,'k', PBlong, PBlat, 'b');
%     %hold on
%     OnColor = [.3 .3 .3];
%     OffColor = [1 .5 .5];
%     switch FuncLabPreferences{9}
%         case 'All'
%             % Get only active event locations
%             %------------------------------------------------------------------
%             ActiveIn = find(RecordMetadataDoubles(:,2));
%             ActiveDoubles = RecordMetadataDoubles(ActiveIn,:);
%             ActiveStrings = RecordMetadataStrings(ActiveIn,:);
%             [junk,indices,junk] = unique(ActiveStrings(:,2));
%             ActiveEventLatitudes = ActiveDoubles(indices,10);
%             ActiveEventLongitudes = ActiveDoubles(indices,11);
%             % Get only inactive event locations
%             %------------------------------------------------------------------
%             InactiveIn = find(RecordMetadataDoubles(:,2)==0);
%             if ~isempty(InactiveIn)
%                 InactiveDoubles = RecordMetadataDoubles(InactiveIn,:);
%                 InactiveStrings = RecordMetadataStrings(InactiveIn,:);
%                 [junk,indices,junk] = unique(InactiveStrings(:,2));
%                 InactiveEventLatitudes = InactiveDoubles(indices,10);
%                 InactiveEventLongitudes = InactiveDoubles(indices,11);
%                 plot(InactiveEventLongitudes,InactiveEventLatitudes,'LineStyle','none','Marker','^','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OffColor)
%             %   linem(InactiveEventLatitudes,InactiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OffColor)
%             end
%             hold on
%             %linem(ActiveEventLatitudes,ActiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
%             plot(ActiveEventLongitudes,ActiveEventLatitudes,'LineStyle','none','Marker','^','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
%             xlabel('Longitude (Degrees)');
%             ylabel('Latitude (Degrees)');
%             axis([WestLon EastLon SouthLat NorthLat]);
%         case 'Active'
%             % Get only active event locations
%             %------------------------------------------------------------------
%             ActiveIn = find(RecordMetadataDoubles(:,2));
%             ActiveDoubles = RecordMetadataDoubles(ActiveIn,:);
%             ActiveStrings = RecordMetadataStrings(ActiveIn,:);
%             [junk,indices,junk] = unique(ActiveStrings(:,2));
%             ActiveEventLatitudes = ActiveDoubles(indices,10);
%             ActiveEventLongitudes = ActiveDoubles(indices,11);
%             plot(ActiveEventLatitudes,ActiveEventLongitudes,'LineStyle','none','Marker','^','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
%             %linem(ActiveEventLatitudes,ActiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
%         case 'Inactive'
%             % Get only inactive event locations
%             %------------------------------------------------------------------
%             InactiveIn = find(RecordMetadataDoubles(:,2)==0);
%             InactiveDoubles = RecordMetadataDoubles(InactiveIn,:);
%             InactiveStrings = RecordMetadataStrings(InactiveIn,:);
%             [junk,indices,junk] = unique(InactiveStrings(:,2));
%             InactiveEventLatitudes = InactiveDoubles(indices,10);
%             InactiveEventLongitudes = InactiveDoubles(indices,11);
%             plot(InactiveEventLatitudes,InactiveEventLongitudes,'LineStyle','none','Marker','^','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
%             %linem(InactiveEventLatitudes,InactiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
%     end
% end % the simple map
  
    
