function fl_moho_auto_pick_MAP_Toolbox_view_scatter(x,y,z,SouthLat,NorthLat,WestLon,EastLon,cptfile,cptflip,projection, CoastPref,TitleString)
%% fl_moho_auto_pick_MAP_Toolbox_view_scatter()
%   Function to make a map with the mapping toolbox based on output from
%   moho_auto_pick. 
%   Be sure to check for existence of the mapping toolbox
%     but we can check here and return an error if it's missing

%   Author: Rob Porritt
%   Date Created: 05/08/2015
%   Last Updated: 05/08/2015

if ~license('test', 'MAP_Toolbox')
    disp('Missing mapping toolbox. This error should have been avoided.')
    disp('Is Batman actually a hero?')
    return
end

% For mapping toolbox, if you want to show rivers, change this to 1
showrivers = 0;
% Adjust the topo axis for your region. Getting the shoreline just right
% takes some tinkering
topoaxis = [-11000 6000];
% Example, working for texas or Alaska:
%topoaxis = [-11575 6000];
% Michigan
% topoaxis = [-10575 6000];

MapDataPath = regexprep(which('funclab'),'funclab.m','map_data/');

figure('Units','characters','NumberTitle','off','Name','Moho Map','Units','characters',...
    'Position',[0 0 165 55],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'},'color','white');

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

MapProjectionIDX = strmatch(projection,ProjectionListNames,'exact');
MapProjectionID = ProjectionListIDs{MapProjectionIDX};

if cptflip == true
    cptcmap(cptfile,'flip',true)
else
    cptcmap(cptfile);
end

% Known bug
%  If the projection is an equidistant map, then we need to set the map
%  limits based on a central location and min/max radius. RWP has this
%  working for m_map, but with all the projections available in the mapping
%  toolbox and no access to the toolbox, RWP didn't feel like making a
%  check for it.
axesm('MapProjection',MapProjectionID,'MapLatLimit',[SouthLat NorthLat],'MapLonLimit',[WestLon EastLon],...
    'Frame','on','Grid','on','MeridianLabel','on','MLineLocation',1,'ParallelLabel','on','PLineLocation',1);

set(gca,'XColor',[1 1 1],'YColor',[1 1 1]);
get(gca,'position');
switch CoastPref
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
end

% Cull out nan values
for idx=size(z,1):-1:1
    if isnan(z(idx))
        y(idx) = [];
        x(idx) = [];
        z(idx) = [];
    end
end
hold on
% call scatterm and cross your fingers
scatterm(y,x,50,z,'filled');
title(TitleString)
colorbar
% Any more frills can be added by a future editor with the mapping toolbox
% :)




