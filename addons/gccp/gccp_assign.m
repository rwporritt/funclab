function gccp_assign(cbo,eventdata,handles)
%GCCP_ASSIGN Assign traces to GCCP bins
%   GCCP_ASSIGN is a callback function that creates the grid for GCCP
%   (Gaussian common conversion point) stacking.  The distance from each
%   piercing point to grid node is computed and stored in GCCPGrid for the 
%   weights applied in the GCCP stacking function (based on proximity to
%   the mid-point of the bin).

%   Author: Kevin C. Eagar
%   Date Created: 12/30/2010
%   Last Updated: 11/19/2011

%Time the runtime of this function.
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
    'String','Please wait, assigning traces to GCCP bins.',...
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
    GCCPMatFile = fullfile(ProjectDirectory, 'GCCPData', 'GCCPData.mat');
else
    GCCPMatFile = fullfile(ProjectDirectory, 'GCCPData', SetName, 'GCCPData.mat');
end

% Set parameters for the GCCP 3D grid
%--------------------------------------------------------------------------
LatMin = str2double(get(h.latmin_e,'string'));
LatMax = str2double(get(h.latmax_e,'string'));
LonMin = str2double(get(h.lonmin_e,'string'));
LonMax = str2double(get(h.lonmax_e,'string'));
BinSpacing = str2double(get(h.binspacing_e,'string'));
BinSize = str2double(get(h.binwidth_e,'string'));

% Compute the GCCP grid and store in a matrix
%--------------------------------------------------------------------------
GCCPGrid = gccp_setup_grid(LatMin,LatMax,LonMin,LonMax,BinSpacing,BinSize);

Rays = who('-file',GCCPMatFile,'RayMatrix*');
for n = 1:length(Rays) % Each RayMatrix
    load(GCCPMatFile,Rays{n})
    RayMatrix = eval(Rays{n});
    clear(Rays{n})
%     for m = 1:size(GCCPGrid,1) % Each Bin
%         for k = 1:size(RayMatrix,1) % Each Depth

            % Calculate distances from piercing point to bin node
            %--------------------------------------------------------------
%             lons = RayMatrix(k,:,4) * pi/180;
%             lats = RayMatrix(k,:,3) * pi/180;
%             tlon = GCCPGrid{m,2} * pi/180;
%             tlat = GCCPGrid{m,1} * pi/180;
%             dlon = lons - tlon;
%             dlat = lats - tlat;
%             a = (sin(dlat/2)).^2 + cos(lats) .* cos(tlat) .* (sin(dlon/2)).^2;
%             angles = 2 .* atan2(sqrt(a),sqrt(1-a));
%             dist = 6371 * angles;
            
            % 11/19/2011: DELETED LINE THAT THAT KEEPS ONLY RAYS THAT FALL
            % WITHIN THE CCP BIN
            %--------------------------------------------------------------
%             Temp{k,1} = RayMatrix(k,:,7); % Record IDs  11/19/2011: RECORD ALL IDS IN RAYMATRIX
%             TempDist{k,1} = dist; % 11/19/2011: RECORD ALL DISTANCES
%         end
%         GCCPGrid{m,4} = [GCCPGrid{m,4} RayMatrix(k,:,7)];
%         GCCPGrid{m,5} = [GCCPGrid{m,5} TempDist];
%     end
    GCCPGrid{1,4} = [GCCPGrid{1,4} RayMatrix(1,:,7)];
    clear RayMatrix
end
save(GCCPMatFile,'GCCPGrid','-append')

% Update the Log File
%--------------------------------------------------------------------------
LogFile = [ProjectDirectory 'Logfile.txt'];
CTime = clock;
NewLog{1} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - GCCP Stacking: Bin Assignment set %s',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6), SetName);
NewLog{2} = ['     1. Latitude range: ' num2str(LatMin) ' to ' num2str(LatMax)];
NewLog{3} = ['     2. Longitude range: ' num2str(LonMin) ' to ' num2str(LonMax)];
NewLog{4} = ['     3. Grid spacing: ' num2str(BinSpacing) ' km'];
NewLog{5} = ['     4. Bin size: ' num2str(BinSize) ' km radius'];
t_temp = toc;
NewLog{6} = ['     5. GCCP assignment took ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).'];
fl_edit_logfile(LogFile,NewLog)
close(WaitGui)
set(h.MainGui.message_t,'String',['Message: GCCP Stacking: Bin assignment took ' num2str(t_temp) ' seconds (or ' num2str((t_temp)/60) ' minutes).'])
set(h.bootresamples_e,'Enable','on')
set(h.bootpercent_e,'Enable','on')
set(h.raypmin_e,'Enable','on')
set(h.raypmax_e,'Enable','on')
set(h.bazmin_e,'Enable','on')
set(h.bazmax_e,'Enable','on')
set(h.vertoverlap_e,'Enable','off')
set(h.hitsmin_e,'Enable','on')
set(h.gccpstacking_b,'Enable','on')