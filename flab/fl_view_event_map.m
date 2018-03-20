function fl_view_event_map(ProjectDirectory,ProjectFile,RecordMetadataStrings,RecordMetadataDoubles,Record)
%FL_VIEW_EVENT_MAP View event map
%   FL_VIEW_EVENT_MAP(ProjectDirectory,ProjectFile,RecordMetadataStrings,
%   RecordMetadataDoubles) plots a global map of the events listed in the
%   input event table and centered on the stations in the input station
%   table.
%
%   Active events are gray, while inactive events are red.
%
%   NOTE: This map ONLY uses the crude-resolution coastlines OR low-res
%   (ETOPO2) topography no matter what the choice in the FuncLab
%   parameters.  This is done for speed.
%
%   REQUIRES MAPPING TOOLBOX INSTALLED

%   Author: Kevin C. Eagar
%   Date Created: 05/14/2010
%   Last Updated: 12/30/2010
% Updated by Rob Porritt to remove need for mapping toolbox
%   Versions 1.6.0 - 1.7.1 used a crude map without any projection
%   Versions 1.7.2+ use m_map from Rich Pawlowicz
%   Version 1.7.6 - fixed a bug where latitude and longitudes were
%   backwards in one of the m_line calls

tic
MapDataPath = regexprep(which('funclab'),'funclab.m','map_data/');

load([ProjectDirectory ProjectFile],'FuncLabPreferences')

% Set latitude and longitude center point
%--------------------------------------------------------------------------
CenterLat = str2double(FuncLabPreferences{17});
CenterLon = str2double(FuncLabPreferences{18});
NorthLat = str2double(FuncLabPreferences{13});
SouthLat = str2double(FuncLabPreferences{14});
WestLon = str2double(FuncLabPreferences{15});
EastLon = str2double(FuncLabPreferences{16});

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

% Set map projection
%--------------------------------------------------------------------------
MapProjection = FuncLabPreferences{11};
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

% Setup the global map using low-level functions (geoshow is giving me
% problems for some reason - keeps crashing and logging me out!)
%--------------------------------------------------------------------------
map = figure('Units','characters','NumberTitle','off','Name','Global Event Map','Units','characters',...
    'Position',[0 0 100 35],'WindowButtonDownFcn','disable_uimaptbx','CreateFcn',{@movegui_kce,'center'});

if license('test', 'MAP_Toolbox')
    % RWP - fear the below call will only work on azimuthal projections,
    % but cannot test currently
my_axes = axesm('MapProjection',MapProjectionID,'Origin',[CenterLat CenterLon 0],'Frame','on','Grid','on');
switch FuncLabPreferences{12}
    case 'Coastlines (low-res)'
        if ~exist([MapDataPath 'gshhs_c.b'])
            disp('No gshhs_c.b coastline data exists.  Please download at http://www.ngdc.noaa.gov/mgg/shorelines/data/gshhs/version2.1.1/gshhs_2.1.1.zip')
            %close
            %return
            load('FL_coasts.mat');
            coasts.Lon=ncst(:,1);
            coasts.Lat=ncst(:,2);
            linem([coasts.Lat],[coasts.Lon],'LineWidth',1,'Color',[0 0 0])
        else
            %end
            % Load in coastline data
            %------------------------------------------------------------------
            coasts = gshhs([MapDataPath 'gshhs_c.b']);
            linem([coasts.Lat],[coasts.Lon],'LineWidth',1,'Color',[0 0 0])
        end
    case 'Coastlines (medium-res)'
        if ~exist([MapDataPath 'gshhs_i.b'])
            disp('No gshhs_c.b coastline data exists.  Please download at http://www.ngdc.noaa.gov/mgg/shorelines/data/gshhs/version2.1.1/gshhs_2.1.1.zip')
            %close
            %return
            load('FL_coasts.mat');
            coasts.Lon=ncst(:,1);
            coasts.Lat=ncst(:,2);
            linem([coasts.Lat],[coasts.Lon],'LineWidth',1,'Color',[0 0 0])
        else
            % Load in coastline data
            %------------------------------------------------------------------
            coasts = gshhs([MapDataPath 'gshhs_i.b']);
        l   inem([coasts.Lat],[coasts.Lon],'LineWidth',1,'Color',[0 0 0])
        end
    case 'Coastlines (hi-res)'
        if ~exist([MapDataPath 'gshhs_h.b'])
            disp('No gshhs_c.b coastline data exists.  Please download at http://www.ngdc.noaa.gov/mgg/shorelines/data/gshhs/version2.1.1/gshhs_2.1.1.zip')
            %close
            %return
            load('FL_coasts.mat');
            coasts.Lon=ncst(:,1);
            coasts.Lat=ncst(:,2);
            linem([coasts.Lat],[coasts.Lon],'LineWidth',1,'Color',[0 0 0])
        else
            % Load in coastline data
            %------------------------------------------------------------------
            coasts = gshhs([MapDataPath 'gshhs_h.b']);
            linem([coasts.Lat],[coasts.Lon],'LineWidth',1,'Color',[0 0 0])
        end
    case 'Topography (low-res)'
        if ~exist([MapDataPath 'ETOPO2v2c_i2_MSB.bin'])
            disp('No ETOPO2v2c_i2_MSB.bin topography data exists.  Please download at http://www.ngdc.noaa.gov/mgg/global/relief/ETOPO2/ETOPO2v2-2006/ETOPO2v2c/raw_binary/ETOPO2v2c_i2_MSB.zip')
            %close
            %return
            lon=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lon');
            lat=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lat');
            z=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','z');
            lonlon = repmat(lon,1,181);
            latlat = repmat(lat,1,361);
            surfacem(latlat', lonlon, z)
            demcmap(z)
        else
            % Load in ETOPO2v2 Topography and Bathymatry data and plot
            %------------------------------------------------------------------
            [ETOPO,topo_refvec] = etopo([MapDataPath 'ETOPO2v2c_i2_MSB.bin'],10); % Updated ETOPO
            disp('Global event map made using updated ETOPO2v2c topography.')
            [topo_lat,topo_lon] = meshgrat([-90 90],[-180 180],size(ETOPO));
            surfacem(topo_lat,topo_lon,ETOPO);
            demcmap(ETOPO)
        end
    case 'Topography (medium-res)'
        if ~exist([MapDataPath 'ETOPO2v2c_i2_MSB.bin'])
            disp('No ETOPO2v2c_i2_MSB.bin topography data exists.  Please download at http://www.ngdc.noaa.gov/mgg/global/relief/ETOPO2/ETOPO2v2-2006/ETOPO2v2c/raw_binary/ETOPO2v2c_i2_MSB.zip')
            %close
            %return
            lon=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lon');
            lat=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lat');
            z=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','z');
            lonlon = repmat(lon,1,181);
            latlat = repmat(lat,1,361);
            surfacem(latlat', lonlon, z)
            demcmap(z)
        else
            % Load in ETOPO2v2 Topography and Bathymatry data and plot
            %------------------------------------------------------------------
            [ETOPO,topo_refvec] = etopo([MapDataPath 'ETOPO2v2c_i2_MSB.bin'],10); % Updated ETOPO
            disp('Global event map made using updated ETOPO2v2c topography.')
            [topo_lat,topo_lon] = meshgrat([-90 90],[-180 180],size(ETOPO));
            surfacem(topo_lat,topo_lon,ETOPO);
            demcmap(ETOPO)
        end
    case 'Topography (hi-res)'
        if ~exist([MapDataPath 'ETOPO2v2c_i2_MSB.bin'])
            disp('No ETOPO2v2c_i2_MSB.bin topography data exists.  Please download at http://www.ngdc.noaa.gov/mgg/global/relief/ETOPO2/ETOPO2v2-2006/ETOPO2v2c/raw_binary/ETOPO2v2c_i2_MSB.zip')
            %close
            %return
            lon=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lon');
            lat=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lat');
            z=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','z');
            lonlon = repmat(lon,1,181);
            latlat = repmat(lat,1,361);
            surfacem(latlat', lonlon, z)
            demcmap(z)
        else
            % Load in ETOPO2v2 Topography and Bathymatry data and plot
            %------------------------------------------------------------------
            [ETOPO,topo_refvec] = etopo([MapDataPath 'ETOPO2v2c_i2_MSB.bin'],10); % Updated ETOPO
            disp('Global event map made using updated ETOPO2v2c topography.')
            [topo_lat,topo_lon] = meshgrat([-90 90],[-180 180],size(ETOPO));
            surfacem(topo_lat,topo_lon,ETOPO);
            demcmap(ETOPO)
        end
end

OnColor = [.3 .3 .3];
OffColor = [1 .5 .5];
CurrentColor = [ 1 .7 0];
SetOnColor = SetManagementCell{CurrentSubsetIndex,6} / 255;
SetOffColor = abs(cross(SetOnColor,OnColor));
switch FuncLabPreferences{9}
    case 'All'
        % Get active event locations
        %------------------------------------------------------------------
        ActiveIn = find(RecordMetadataDoubles(:,2));
        ActiveDoubles = RecordMetadataDoubles(ActiveIn,:);
        ActiveStrings = RecordMetadataStrings(ActiveIn,:);
        [junk,indices,junk] = unique(ActiveStrings(:,3));
        ActiveEventLatitudes = ActiveDoubles(indices,13);
        ActiveEventLongitudes = ActiveDoubles(indices,14);
        % Get inactive event locations
        %------------------------------------------------------------------
        InactiveIn = find(RecordMetadataDoubles(:,2)==0);
        if ~isempty(InactiveIn)
            InactiveDoubles = RecordMetadataDoubles(InactiveIn,:);
            InactiveStrings = RecordMetadataStrings(InactiveIn,:);
            [junk,indices,junk] = unique(InactiveStrings(:,3));
            InactiveEventLatitudes = InactiveDoubles(indices,13);
            InactiveEventLongitudes = InactiveDoubles(indices,14);
            linem(InactiveEventLatitudes,InactiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OffColor)
        end
        linem(ActiveEventLatitudes,ActiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
        
        % Repeat for the current set
        ActiveIn = find(SetMetadataDoubles(:,2));
        ActiveDoubles = SetMetadataDoubles(ActiveIn,:);
        ActiveStrings = SetMetadataStrings(ActiveIn,:);
        [junk,indices,junk] = unique(ActiveStrings(:,3));
        ActiveEventLatitudes = ActiveDoubles(indices,13);
        ActiveEventLongitudes = ActiveDoubles(indices,14);
        % Get inactive event locations
        %------------------------------------------------------------------
        InactiveIn = find(SetMetadataDoubles(:,2)==0);
        if ~isempty(InactiveIn)
            InactiveDoubles = SetMetadataDoubles(InactiveIn,:);
            InactiveStrings = SetMetadataStrings(InactiveIn,:);
            [junk,indices,junk] = unique(InactiveStrings(:,3));
            InactiveEventLatitudes = InactiveDoubles(indices,13);
            InactiveEventLongitudes = InactiveDoubles(indices,14);
            linem(InactiveEventLatitudes,InactiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',SetOffColor)
        end
        linem(ActiveEventLatitudes,ActiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',SetOnColor)

    case 'Active'
        % Get only active event locations
        %------------------------------------------------------------------
        ActiveIn = find(RecordMetadataDoubles(:,2));
        ActiveDoubles = RecordMetadataDoubles(ActiveIn,:);
        ActiveStrings = RecordMetadataStrings(ActiveIn,:);
        [junk,indices,junk] = unique(ActiveStrings(:,3));
        ActiveEventLatitudes = ActiveDoubles(indices,13);
        ActiveEventLongitudes = ActiveDoubles(indices,14);
        linem(ActiveEventLatitudes,ActiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
        % Get only active event locations for this set
        %------------------------------------------------------------------
        ActiveIn = find(SetMetadataDoubles(:,2));
        ActiveDoubles = SetMetadataDoubles(ActiveIn,:);
        ActiveStrings = SetMetadataStrings(ActiveIn,:);
        [junk,indices,junk] = unique(ActiveStrings(:,3));
        ActiveEventLatitudes = ActiveDoubles(indices,13);
        ActiveEventLongitudes = ActiveDoubles(indices,14);
        linem(ActiveEventLatitudes,ActiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',SetOnColor)

    case 'Inactive'
        % Get only inactive event locations
        %------------------------------------------------------------------
        InactiveIn = find(RecordMetadataDoubles(:,2)==0);
        InactiveDoubles = RecordMetadataDoubles(InactiveIn,:);
        InactiveStrings = RecordMetadataStrings(InactiveIn,:);
        [junk,indices,junk] = unique(InactiveStrings(:,3));
        InactiveEventLatitudes = InactiveDoubles(indices,13);
        InactiveEventLongitudes = InactiveDoubles(indices,14);
        linem(InactiveEventLatitudes,InactiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
        % Get only inactive event locations for this event
        %------------------------------------------------------------------
        InactiveIn = find(SetMetadataDoubles(:,2)==0);
        InactiveDoubles = SetMetadataDoubles(InactiveIn,:);
        InactiveStrings = SetMetadataStrings(InactiveIn,:);
        [junk,indices,junk] = unique(InactiveStrings(:,3));
        InactiveEventLatitudes = InactiveDoubles(indices,13);
        InactiveEventLongitudes = InactiveDoubles(indices,14);
        linem(InactiveEventLatitudes,InactiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',SetOnColor)
end

for n=[30 95]
    H.radiusmenu(n) = uicontextmenu;
    [sc_lat,sc_lon] = scircle1(CenterLat,CenterLon,n);
    linem(sc_lat,sc_lon,'LineWidth',2,'Color',[1 1 1],'UIContextMenu',H.radiusmenu(n))
end
        linem(CurrentEventLatitude,CurrentEventLongitude,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',CurrentColor)

else
    % No mapping toolbox, but m_map
if strcmp(MapProjectionID,'Stereographic') || strcmp(MapProjectionID,'Orthographic') || strcmp(MapProjectionID,'Azimuthal Equal-area') || ...
        strcmp(MapProjectionID,'Azimuthal Equidistant') || strcmp(MapProjectionID,'Gnomonic') || strcmp(MapProjectionID,'Satellite')    
    m_proj(MapProjectionID,'latitude',(SouthLat + NorthLat)/2, 'longitude',(WestLon + EastLon) / 2,'radius',150);
else
    m_proj(MapProjectionID,'latitude',[-85 85],'longitude',[-180 180]);
end
   switch FuncLabPreferences{12}
    case 'Coastlines (low-res)'
        if ~exist([MapDataPath 'gshhs_c.b'])
            disp('No gshhs_c.b coastline data exists.  Please download at http://www.ngdc.noaa.gov/mgg/shorelines/data/gshhs/version2.1.1/gshhs_2.1.1.zip')
            %close
            %return
            %load('FL_coasts.mat');
            %coasts.Lon=ncst(:,1);
            %coasts.Lat=ncst(:,2);
            %linem([coasts.Lat],[coasts.Lon],'LineWidth',1,'Color',[0 0 0])
            m_gshhs_l('patch',[.9 .9 .9],'edgecolor','black');
            m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
        else
            %end
            % Load in coastline data
            %------------------------------------------------------------------
            m_gshhs_l('patch',[.9 .9 .9],'edgecolor','black');
            m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
        end
    case 'Coastlines (medium-res)'
        if ~exist([MapDataPath 'gshhs_i.b'])
            disp('No gshhs_c.b coastline data exists.  Please download at http://www.ngdc.noaa.gov/mgg/shorelines/data/gshhs/version2.1.1/gshhs_2.1.1.zip')
            %close
            %return
            %load('FL_coasts.mat');
            %coasts.Lon=ncst(:,1);
            %coasts.Lat=ncst(:,2);
            %linem([coasts.Lat],[coasts.Lon],'LineWidth',1,'Color',[0 0 0])
            m_gshhs_i('patch',[.9 .9 .9],'edgecolor','black');
            m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
        else
            % Load in coastline data
            %------------------------------------------------------------------
            m_gshhs_i('patch',[.9 .9 .9],'edgecolor','black');
            m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
        end
    case 'Coastlines (hi-res)'
        if ~exist([MapDataPath 'gshhs_h.b'])
            disp('No gshhs_c.b coastline data exists.  Please download at http://www.ngdc.noaa.gov/mgg/shorelines/data/gshhs/version2.1.1/gshhs_2.1.1.zip')
            %close
            %return
            %load('FL_coasts.mat');
            %coasts.Lon=ncst(:,1);
            %coasts.Lat=ncst(:,2);
            %linem([coasts.Lat],[coasts.Lon],'LineWidth',1,'Color',[0 0 0])
            m_gshhs_h('patch',[.9 .9 .9],'edgecolor','black');
            m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
        else
            % Load in coastline data
            %------------------------------------------------------------------
            %coasts = gshhs([MapDataPath 'gshhs_h.b']);
            %linem([coasts.Lat],[coasts.Lon],'LineWidth',1,'Color',[0 0 0])
            m_gshhs_h('patch',[.9 .9 .9],'edgecolor','black');
            m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
        end
    case 'Topography (low-res)'
        if ~exist([MapDataPath 'ETOPO2v2c_i2_MSB.bin'])
            disp('No ETOPO2v2c_i2_MSB.bin topography data exists.  Please download at http://www.ngdc.noaa.gov/mgg/global/relief/ETOPO2/ETOPO2v2-2006/ETOPO2v2c/raw_binary/ETOPO2v2c_i2_MSB.zip')
            m_gshhs_i('patch',[.9 .9 .9],'edgecolor','black');
            m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
            cptcmap('topography_rwp.cpt')
            m_elev;
            %close
            %return
            %lon=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lon');
            %lat=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lat');
            %z=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','z');
            %lonlon = repmat(lon,1,181);
            %latlat = repmat(lat,1,361);
            %surfacem(latlat', lonlon, z)
            %demcmap(z)
        else
            % Load in ETOPO2v2 Topography and Bathymatry data and plot
            %------------------------------------------------------------------
            %[ETOPO,topo_refvec] = etopo([MapDataPath 'ETOPO2v2c_i2_MSB.bin'],10); % Updated ETOPO
            %disp('Global event map made using updated ETOPO2v2c topography.')
            %[topo_lat,topo_lon] = meshgrat([-90 90],[-180 180],size(ETOPO));
            %surfacem(topo_lat,topo_lon,ETOPO);
            %demcmap(ETOPO)
            m_gshhs_i('patch',[.9 .9 .9],'edgecolor','black');
            m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
            cptcmap('topography_rwp.cpt')
            m_elev;
        end
    case 'Topography (medium-res)'
        if ~exist([MapDataPath 'ETOPO2v2c_i2_MSB.bin'])
            disp('No ETOPO2v2c_i2_MSB.bin topography data exists.  Please download at http://www.ngdc.noaa.gov/mgg/global/relief/ETOPO2/ETOPO2v2-2006/ETOPO2v2c/raw_binary/ETOPO2v2c_i2_MSB.zip')
            %close
            %return
            %lon=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lon');
            %lat=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lat');
            %z=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','z');
            %lonlon = repmat(lon,1,181);
            %latlat = repmat(lat,1,361);
            %surfacem(latlat', lonlon, z)
            %demcmap(z)
            m_gshhs_i('patch',[.9 .9 .9],'edgecolor','black');
            m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
            cptcmap('topography_rwp.cpt')
            m_elev;
        else
            % Load in ETOPO2v2 Topography and Bathymatry data and plot
            %------------------------------------------------------------------
            %[ETOPO,topo_refvec] = etopo([MapDataPath 'ETOPO2v2c_i2_MSB.bin'],10); % Updated ETOPO
            %disp('Global event map made using updated ETOPO2v2c topography.')
            %[topo_lat,topo_lon] = meshgrat([-90 90],[-180 180],size(ETOPO));
            %surfacem(topo_lat,topo_lon,ETOPO);
            %demcmap(ETOPO)
            m_gshhs_i('patch',[.9 .9 .9],'edgecolor','black');
            m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
            cptcmap('topography_rwp.cpt')
            m_elev;
        end
    case 'Topography (hi-res)'
        if ~exist([MapDataPath 'ETOPO2v2c_i2_MSB.bin'])
            disp('No ETOPO2v2c_i2_MSB.bin topography data exists.  Please download at http://www.ngdc.noaa.gov/mgg/global/relief/ETOPO2/ETOPO2v2-2006/ETOPO2v2c/raw_binary/ETOPO2v2c_i2_MSB.zip')
            %close
            %return
            %lon=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lon');
            %lat=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lat');
            %z=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','z');
            %lonlon = repmat(lon,1,181);
            %latlat = repmat(lat,1,361);
            %surfacem(latlat', lonlon, z)
            %demcmap(z)
            m_gshhs_i('patch',[.9 .9 .9],'edgecolor','black');
            m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
            cptcmap('topography_rwp.cpt')
            m_elev;
        else
            % Load in ETOPO2v2 Topography and Bathymatry data and plot
            %------------------------------------------------------------------
            %[ETOPO,topo_refvec] = etopo([MapDataPath 'ETOPO2v2c_i2_MSB.bin'],10); % Updated ETOPO
            %disp('Global event map made using updated ETOPO2v2c topography.')
            %[topo_lat,topo_lon] = meshgrat([-90 90],[-180 180],size(ETOPO));
            %surfacem(topo_lat,topo_lon,ETOPO);
            %demcmap(ETOPO)
            m_gshhs_i('patch',[.9 .9 .9],'edgecolor','black');
            m_grid('xtick',10,'tickdir','out','yaxislocation','left','fontsize',12,'box','on');
            cptcmap('topography_rwp.cpt')
            m_elev;
        end
end

OnColor = [.3 .3 .3];
OffColor = [1 .5 .5];
CurrentColor = [ 1 .7 0];
SetOnColor = SetManagementCell{CurrentSubsetIndex,6} / 255;
SetOffColor = abs(cross(SetOnColor,OnColor));

switch FuncLabPreferences{9}
    case 'All'
        % Get active event locations
        %------------------------------------------------------------------
        ActiveIn = find(RecordMetadataDoubles(:,2));
        ActiveDoubles = RecordMetadataDoubles(ActiveIn,:);
        ActiveStrings = RecordMetadataStrings(ActiveIn,:);
        [junk,indices,junk] = unique(ActiveStrings(:,3));
        ActiveEventLatitudes = ActiveDoubles(indices,13);
        ActiveEventLongitudes = ActiveDoubles(indices,14);
        % Get inactive event locations
        %------------------------------------------------------------------
        InactiveIn = find(RecordMetadataDoubles(:,2)==0);
        if ~isempty(InactiveIn)
            InactiveDoubles = RecordMetadataDoubles(InactiveIn,:);
            InactiveStrings = RecordMetadataStrings(InactiveIn,:);
            [junk,indices,junk] = unique(InactiveStrings(:,3));
            InactiveEventLatitudes = InactiveDoubles(indices,13);
            InactiveEventLongitudes = InactiveDoubles(indices,14);
            m_line(InactiveEventLongitudes,InactiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OffColor)
        end
        m_line(ActiveEventLongitudes,ActiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
        % Get active event locations for this set
        %------------------------------------------------------------------
        ActiveIn = find(SetMetadataDoubles(:,2));
        ActiveDoubles = SetMetadataDoubles(ActiveIn,:);
        ActiveStrings = SetMetadataStrings(ActiveIn,:);
        [junk,indices,junk] = unique(ActiveStrings(:,3));
        ActiveEventLatitudes = ActiveDoubles(indices,13);
        ActiveEventLongitudes = ActiveDoubles(indices,14);
        % Get inactive event locations
        %------------------------------------------------------------------
        InactiveIn = find(SetMetadataDoubles(:,2)==0);
        if ~isempty(InactiveIn)
            InactiveDoubles = SetMetadataDoubles(InactiveIn,:);
            InactiveStrings = SetMetadataStrings(InactiveIn,:);
            [junk,indices,junk] = unique(InactiveStrings(:,3));
            InactiveEventLatitudes = InactiveDoubles(indices,13);
            InactiveEventLongitudes = InactiveDoubles(indices,14);
            m_line(InactiveEventLongitudes,InactiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',SetOffColor)
        end
        m_line(ActiveEventLongitudes,ActiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',SetOnColor)

    case 'Active'
        % Get only active event locations
        %------------------------------------------------------------------
        ActiveIn = find(RecordMetadataDoubles(:,2));
        ActiveDoubles = RecordMetadataDoubles(ActiveIn,:);
        ActiveStrings = RecordMetadataStrings(ActiveIn,:);
        [junk,indices,junk] = unique(ActiveStrings(:,3));
        ActiveEventLatitudes = ActiveDoubles(indices,13);
        ActiveEventLongitudes = ActiveDoubles(indices,14);
        m_line(ActiveEventLongitudes,ActiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
        % Get only active event locations for this set
        %------------------------------------------------------------------
        ActiveIn = find(SetMetadataDoubles(:,2));
        ActiveDoubles = SetMetadataDoubles(ActiveIn,:);
        ActiveStrings = SetMetadataStrings(ActiveIn,:);
        [junk,indices,junk] = unique(ActiveStrings(:,3));
        ActiveEventLatitudes = ActiveDoubles(indices,13);
        ActiveEventLongitudes = ActiveDoubles(indices,14);
        m_line(ActiveEventLongitudes,ActiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',SetOnColor)

    case 'Inactive'
        % Get only inactive event locations
        %------------------------------------------------------------------
        InactiveIn = find(RecordMetadataDoubles(:,2)==0);
        InactiveDoubles = RecordMetadataDoubles(InactiveIn,:);
        InactiveStrings = RecordMetadataStrings(InactiveIn,:);
        [junk,indices,junk] = unique(InactiveStrings(:,3));
        InactiveEventLatitudes = InactiveDoubles(indices,13);
        InactiveEventLongitudes = InactiveDoubles(indices,14);
        m_line(InactiveEventLongitudes,InactiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
        % Get only inactive event locations for this set
        %------------------------------------------------------------------
        InactiveIn = find(SetMetadataDoubles(:,2)==0);
        InactiveDoubles = SetMetadataDoubles(InactiveIn,:);
        InactiveStrings = SetMetadataStrings(InactiveIn,:);
        [junk,indices,junk] = unique(InactiveStrings(:,3));
        InactiveEventLatitudes = InactiveDoubles(indices,13);
        InactiveEventLongitudes = InactiveDoubles(indices,14);
        m_line(InactiveEventLongitudes,InactiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',SetOnColor)
end

for n=[30 95]
    %H.radiusmenu(n) = uicontextmenu;
    m_range_ring(CenterLon, CenterLat, n*111.19);
    %[sc_lat,sc_lon] = scircle1(CenterLat,CenterLon,n*111.19);
    %m_line(sc_lat,sc_lon,'LineWidth',2,'Color',[1 1 1],'UIContextMenu',H.radiusmenu(n))
end 
    
    m_line(CurrentEventLongitude,CurrentEventLatitude,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',CurrentColor)

end
    
%% Version without m_map    
% % no mapping toolbox
% axes('XGrid','on','YGrid','on','XLim', [-180 180], 'YLim', [-90 90]);
% xlabel('Longitude (Degrees)')
% ylabel('Latitude (Degrees)')
% OnColor = [.3 .3 .3];
% OffColor = [1 .5 .5];
% lon=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lon');
% lat=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','lat');
% z=ncread('ETOPO1_Ice_g_gmt4_1deg.grd','z');
% lonlon = repmat(lon,1,181);
% latlat = repmat(lat,1,361);
% contourf(lonlon,latlat',z)
% cmap = cptcmap('topography_rwp.cpt');
% colormap(cmap);
% hold on
% load('FL_coasts.mat');
% load('FL_stateBoundaries.mat');
% load('FL_plates.mat');
% plot(ncst(:,1),ncst(:,2),'k',stateBoundaries.longitude, stateBoundaries.latitude,'k', PBlong, PBlat, 'b');
% switch FuncLabPreferences{9}
%     case 'All'
%         % Get active event locations
%         %------------------------------------------------------------------
%         ActiveIn = find(RecordMetadataDoubles(:,2));
%         ActiveDoubles = RecordMetadataDoubles(ActiveIn,:);
%         ActiveStrings = RecordMetadataStrings(ActiveIn,:);
%         [junk,indices,junk] = unique(ActiveStrings(:,3));
%         ActiveStationLatitudes = ActiveDoubles(indices,10);
%         ActiveStationLongitudes = ActiveDoubles(indices,11);
%         ActiveEventLatitudes = ActiveDoubles(indices,13);
%         ActiveEventLongitudes = ActiveDoubles(indices,14);
%         % Get inactive event locations
%         %------------------------------------------------------------------
%         InactiveIn = find(RecordMetadataDoubles(:,2)==0);
%         if ~isempty(InactiveIn)
%             InactiveDoubles = RecordMetadataDoubles(InactiveIn,:);
%             InactiveStrings = RecordMetadataStrings(InactiveIn,:);
%             [junk,indices,junk] = unique(InactiveStrings(:,3));
%             InactiveStationLatitudes = InactiveDoubles(indices,10);
%             InactiveStationLongitudes = InactiveDoubles(indices,11);
%             InactiveEventLatitudes = InactiveDoubles(indices,13);
%             InactiveEventLongitudes = InactiveDoubles(indices,14);
%             hold on
%             plot(InactiveEventLongitudes,InactiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OffColor)
%             plot(InactiveStationLongitudes,InactiveStationLatitudes,'LineStyle','none','Marker','^','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OffColor)
%             %linem(InactiveEventLatitudes,InactiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OffColor)
%         end
%         plot(ActiveStationLongitudes,ActiveStationLatitudes,'LineStyle','none','Marker','^','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
%         plot(ActiveEventLongitudes,ActiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
%         %linem(ActiveEventLatitudes,ActiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
%     case 'Active'
%         % Get only active event locations
%         %------------------------------------------------------------------
%         ActiveIn = find(RecordMetadataDoubles(:,2));
%         ActiveDoubles = RecordMetadataDoubles(ActiveIn,:);
%         ActiveStrings = RecordMetadataStrings(ActiveIn,:);
%         [junk,indices,junk] = unique(ActiveStrings(:,3));
%         ActiveStationLatitudes = ActiveDoubles(indices,10);
%         ActiveStationLongitudes = ActiveDoubles(indices,11);
%         ActiveEventLatitudes = ActiveDoubles(indices,13);
%         ActiveEventLongitudes = ActiveDoubles(indices,14);
%         plot(ActiveStationLongitudes,ActiveStationLatitudes,'LineStyle','none','Marker','^','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
%         plot(ActiveEventLongitudes,ActiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
%         %linem(ActiveEventLatitudes,ActiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
%     case 'Inactive'
%         % Get only inactive event locations
%         %------------------------------------------------------------------
%         InactiveIn = find(RecordMetadataDoubles(:,2)==0);
%         InactiveDoubles = RecordMetadataDoubles(InactiveIn,:);
%         InactiveStrings = RecordMetadataStrings(InactiveIn,:);
%         [junk,indices,junk] = unique(InactiveStrings(:,3));
%         InactiveStationLatitudes = InactiveDoubles(indices,10);
%         InactiveStationLongitudes = InactiveDoubles(indices,11);
%         InactiveEventLatitudes = InactiveDoubles(indices,13);
%         InactiveEventLongitudes = InactiveDoubles(indices,14);
%         plot(InactiveStationLongitudes,InactiveStationLatitudes,'LineStyle','none','Marker','^','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
%         plot(InactiveEventLongitudes,InactiveEventLatitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
%         %linem(InactiveEventLatitudes,InactiveEventLongitudes,'LineStyle','none','Marker','o','MarkerSize',8,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',OnColor)
% end
% end

t_temp = toc;
disp(['Mapping took ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).']);