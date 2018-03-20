function rayp_baz_view_hit_chart(cbo,eventdata,handles)
% RAYP_BAZ_VIEW_HIT_CHART Plot ray-parameter and backazimuth bins
%   Plots a polar diagram of backazimuth on the theta axis and ray
%   parameter on the radial axis
%   Colors bin centers by hit count
%   Does not use mapping toolbox
%   
%   Author: Robert W. Porritt
%   Date Created: Oct. 7th, 2014


% Get the handles of the FuncLab GUI
%--------------------------------------------------------------------------
h = guidata(gcbf);


% Get the Station Table to perform stacking
%--------------------------------------------------------------------------
Value = get(h.MainGui.tablemenu_pu,'Value');
CurrentRecords = evalin('base','CurrentRecords');
RecordMetadataStrings = evalin('base','RecordMetadataStrings');
RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
if Value ~= 1
    Tablemenu = evalin('base','Tablemenu');
    if strcmp('RaypBazMetadata',Tablemenu{Value,2})
        RecordIndex = get(h.MainGui.records_ls,'Value');
        Station = CurrentRecords{RecordIndex,2};
        % Get all records for this selected station and redo
        % CurrentRecords and CurrentIndices
        in = strcmp(Station,RecordMetadataStrings(:,2));
        CurrentRecords = [RecordMetadataStrings(in,:) num2cell(RecordMetadataDoubles(in,:))];
    else
        TableIndex = get(h.MainGui.tables_ls,'Value');
        TableList = get(h.MainGui.tables_ls,'String');
        TableName = TableList{TableIndex};
        disp(['Not the right table: ' TableName])
        return
    end
else
    Station = CurrentRecords{1,2};
end

% Get the parameters from the GUI to define the grid
minRayP = sscanf(get(h.min_rayp_e,'String'),'%f');
maxRayP = sscanf(get(h.max_rayp_e,'String'),'%f');
incRayP = sscanf(get(h.inc_rayp_e,'String'),'%f');

minBaz = sscanf(get(h.min_baz_e,'String'),'%f');
maxBaz = sscanf(get(h.max_baz_e,'String'),'%f');
incBaz = sscanf(get(h.inc_baz_e,'String'),'%f');

activeOrAllFlag = get(h.active_or_all_records_pd,'Value'); % 1 = Active only, 2 = all records
stationsToShowFlag = get(h.stations_to_stack_pd,'Value'); % 1 = Active station, 2 = all stations


% Switch between all stations or single station
if stationsToShowFlag == 1

% Create a new figure window and plot lines of constant ray parameter
figure()
hold on
axis([-maxRayP maxRayP -maxRayP maxRayP])
for i=minRayP:incRayP:maxRayP
     plot(i*cos(0:0.1:2.1*pi),i*sin(0:0.1:2.1*pi),'k--')
end

% Init the search space
RayP = minRayP:incRayP:maxRayP;
nrayP = length(RayP);
Baz = minBaz:incBaz:maxBaz;
nBaz = length(Baz);

% Init the plotables
pltXvector = zeros(1,nrayP*nBaz);
pltYvector = zeros(1,nrayP*nBaz);
pltCvector = zeros(1,nrayP*nBaz);

% Convert the desired parameters from the cell array to simple vectors
tmp = size(CurrentRecords);
nRecords = tmp(1);
currentRayP = zeros(1,nRecords);
currentBaz = zeros(1,nRecords);
currentActives = zeros(1,nRecords);
for i=1:nRecords
    currentRayP(i) = CurrentRecords{i,21};
    currentBaz(i) = CurrentRecords{i,22};
    currentActives(i) = CurrentRecords{i,5};
end

% For pcolor
r=RayP;
theta=pi/180*(90-Baz-incBaz/2);
X=r'*cos(theta);
Y=r'*sin(theta);
hitsStructure = zeros(nrayP, nBaz);


% Now find the hit count in each backazimuth and rayp bin
i=1;
for irayp=1:nrayP
    tmpRayP = irayp * incRayP + minRayP; 
    for ibaz=1:nBaz
        clear iHits;
        tmpBaz = ibaz * incBaz + minBaz;
        pltXvector(i) = tmpRayP*cos((90-tmpBaz)*pi/180);
        pltYvector(i) = tmpRayP*sin((90-tmpBaz)*pi/180);
        tmpMinRayP = tmpRayP - incRayP / 2;
        tmpMaxRayP = tmpRayP + incRayP / 2;
        tmpMinBaz = tmpBaz - incBaz / 2;
        tmpMaxBaz = tmpBaz + incBaz / 2;
        if activeOrAllFlag == 1
            iHits = find(currentActives == 1 & currentRayP >= tmpMinRayP & currentRayP <= tmpMaxRayP & currentBaz >= tmpMinBaz & currentBaz <= tmpMaxBaz );
        else
            iHits = find(currentRayP >= tmpMinRayP & currentRayP <= tmpMaxRayP & currentBaz >= tmpMinBaz & currentBaz <= tmpMaxBaz );
        end
        if ~isempty(iHits)
            pltCvector(i) = length(iHits);
            hitsStructure(irayp,ibaz) = length(iHits);
        end  % if there are hits in this bin
        i = i+1;
    end % backazimuth bin
end % rayp bins

% Actually plotting the overlay - use this block to plot circles
%scatter(pltXvector, pltYvector, 100, pltCvector,'filled')
%plot(0,0,'rV','MarkerSize',10,'MarkerFaceColor','r');
%caxis([0 max(pltCvector)/5])
%colorbar;

pcolor(X,Y,hitsStructure)
plot(0,0,'rV','MarkerSize',10,'MarkerFaceColor','r');
caxis([0 max(pltCvector)/5])
xlabel('Slowness east (s/km)')
ylabel('Slowness north (s/km)')
colorbar;


else % Plot all stations
   
    % Create a new figure window and plot lines of constant ray parameter
figure()
hold on
axis([-maxRayP maxRayP -maxRayP maxRayP])
for i=minRayP:incRayP:maxRayP
     plot(i*cos(0:0.1:2.1*pi),i*sin(0:0.1:2.1*pi),'k--')
end

% Init the search space
RayP = minRayP:incRayP:maxRayP;
nrayP = length(RayP);
Baz = minBaz:incBaz:maxBaz;
nBaz = length(Baz); 
    
% Init the plotables
pltXvector = zeros(1,nrayP*nBaz);
pltYvector = zeros(1,nrayP*nBaz);
pltCvector = zeros(1,nrayP*nBaz);

% For pcolor
r=RayP;
theta=pi/180*(90-Baz-incBaz/2);
X=r'*cos(theta);
Y=r'*sin(theta);
hitsStructure = zeros(nrayP, nBaz);

% Main change from above is to plot RecordMetadataDoubles. (n,2) has
% on/off, (n,18) has rayp, (n,19) has baz
tmp = size(RecordMetadataDoubles);
nRecords = tmp(1);

RecordRayP = zeros(1,nRecords);
RecordBaz = zeros(1,nRecords);
RecordActives = zeros(1,nRecords);
for i=1:nRecords
    RecordRayP(i) = RecordMetadataDoubles(i,18);
    RecordBaz(i) = RecordMetadataDoubles(i,19);
    RecordActives(i) = RecordMetadataDoubles(i,2);
end

% Now find the hit count in each backazimuth and rayp bin
i=1;
for irayp=1:nrayP
    tmpRayP = irayp * incRayP + minRayP; 
    for ibaz=1:nBaz
        clear iHits;
        tmpBaz = ibaz * incBaz + minBaz;
        pltXvector(i) = tmpRayP*cos((90-tmpBaz)*pi/180);
        pltYvector(i) = tmpRayP*sin((90-tmpBaz)*pi/180);
        tmpMinRayP = tmpRayP - incRayP / 2;
        tmpMaxRayP = tmpRayP + incRayP / 2;
        tmpMinBaz = tmpBaz - incBaz / 2;
        tmpMaxBaz = tmpBaz + incBaz / 2;
        if activeOrAllFlag == 1
            iHits = find(RecordActives == 1 & RecordRayP >= tmpMinRayP & RecordRayP <= tmpMaxRayP & RecordBaz >= tmpMinBaz & RecordBaz <= tmpMaxBaz );
        else
            iHits = find(RecordRayP >= tmpMinRayP & RecordRayP <= tmpMaxRayP & RecordBaz >= tmpMinBaz & RecordBaz <= tmpMaxBaz );
        end
        if ~isempty(iHits)
            pltCvector(i) = length(iHits);
            hitsStructure(irayp,ibaz) = length(iHits);
        end  % if there are hits in this bin
        i = i+1;
    end % backazimuth bin
end % rayp bins

% Actually plotting the overlay
% scatter(pltXvector, pltYvector, 100, pltCvector,'filled')
% plot(0,0,'rV','MarkerSize',10,'MarkerFaceColor','r');
% caxis([0 max(pltCvector)/10])
% colorbar;

pcolor(X,Y,hitsStructure)
plot(0,0,'rV','MarkerSize',10,'MarkerFaceColor','r');
caxis([0 max(pltCvector)/10])
xlabel('Slowness east (s/km)')
ylabel('Slowness north (s/km)')
colorbar;
    
end

    
