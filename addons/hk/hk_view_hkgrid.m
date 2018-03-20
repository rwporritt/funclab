function hk_view_hkgrid(cbo,eventdata,handles)
%HK_VIEW_HKGRID Plot H-k grid
%   HK_VIEW_HKGRID plots the H-k gridsearch area, the point of maximum
%   amplitude, as well as the values and errors from the bootstrapping.

%   Author: Kevin C. Eagar
%   Date Created: 02/27/2008
%   Last Updated: 04/24/2011

% Get the handles of the FuncLab GUI
%--------------------------------------------------------------------------
h = guidata(gcbf);
ProjectDirectory = evalin('base','ProjectDirectory');
CurrentRecords = evalin('base','CurrentRecords');
TableIndex = get(h.MainGui.tables_ls,'Value');
TableList = get(h.MainGui.tables_ls,'String');
Table = TableList{TableIndex};
RecordIndex = get(h.MainGui.records_ls,'Value');
Station = CurrentRecords{RecordIndex,2};

% Get the Station Table to perform stacking
%--------------------------------------------------------------------------
List = get(h.MainGui.tablemenu_pu,'String');
Value = get(h.MainGui.tablemenu_pu,'Value');
TableType = List{Value};
if isempty(strmatch(TableType,'H-k Tables'))
    disp(['Not the right table type: ' TableType])
    return
end
load([ProjectDirectory CurrentRecords{RecordIndex,1}])

% Assign necessary parameters to variables for curve computation
%--------------------------------------------------------------------------
AssumedVp = CurrentRecords{RecordIndex,17};
SphereRayp = 382.26; % s/rad for 0.06 s/km
R = 6371;
MaxH = CurrentRecords{RecordIndex,18};
MaxHsig = CurrentRecords{RecordIndex,19};
Maxk = CurrentRecords{RecordIndex,20};
Maxksig = CurrentRecords{RecordIndex,21};
MaxP = CurrentRecords{RecordIndex,22};
MaxPsig = CurrentRecords{RecordIndex,23};
RecordCount = CurrentRecords{RecordIndex,4};

% Set initial values
%--------------------------------------------------------------------------
HMax = max(HAxis);

% Compute the Ps, PpPs, and PpSs+PsPs curves for the depth and Vp/Vs
%----------------------------------------------------------------------
tps = (sqrt((R./(AssumedVp./Maxk)).^2 - SphereRayp(1).^2) - sqrt((R./AssumedVp).^2 - SphereRayp(1).^2)) .* (MaxH./R);
tpp = (sqrt((R./(AssumedVp./Maxk)).^2 - SphereRayp(1).^2) + sqrt((R./AssumedVp).^2 - SphereRayp(1).^2)) .* (MaxH./R);
tss = 2 .* (MaxH./R) .* sqrt((R./(AssumedVp./Maxk)).^2 - SphereRayp(1).^2);
k = kAxis;
Hps = 1./(sqrt((R./(AssumedVp./k)).^2 - SphereRayp(1).^2) - sqrt((R./AssumedVp).^2 - SphereRayp(1).^2)) .* (tps.*R);
Hpp = 1./(sqrt((R./(AssumedVp./k)).^2 - SphereRayp(1).^2) + sqrt((R./AssumedVp).^2 - SphereRayp(1).^2)) .* (tpp.*R);
Hss = (tss.*R) ./ (2 .* sqrt((R./(AssumedVp./k)).^2 - SphereRayp(1).^2));

fig = figure('NumberTitle','off','Units','characters','Resize','off','Name',['H-k Stack: ' Station],...
    'Position',[0 0 100 45],'PaperPosition',[2 3 4.5 4],'Color',[1 1 1],'Visible','on','CreateFcn',{@movegui_kce,'center'});
uicontrol('Parent',fig,'Style','text','Units','normalized','String',['Station: ' Station],...
    'Position',[.1 .94 .8 .05],'BackgroundColor',[1 1 1],'FontWeight','Bold','FontSize',14);
axes('Units','normalized','Clipping','off','Box','on','Layer','top','TickDir','out','Position',[.1 .1 .8 .8]);
colormap('gray');
cmap = colormap;
cmap = flipdim(cmap,1);
colormap(cmap)
imagesc(kAxis,HAxis,HKAmps);
line(Maxk,MaxH,'marker','o','markeredgecolor',[1 1 1],'markerfacecolor',[1 1 1]);
cvalue = 1 - std(reshape(HKAmps,1,numel(HKAmps)))/sqrt(RecordCount);
c = contourc(kAxis,HAxis,HKAmps,[cvalue cvalue]);
NumContours = find(c(1,:) == cvalue);
if length(NumContours) == 1
    line(c(1,2:end),c(2,2:end),'Color',[1 1 1])
else
    for m = 1:length(NumContours)
        if m == 1
            line(c(1,2:NumContours(m+1)-1),c(2,2:NumContours(m+1)-1),'Color',[1 1 1])
        elseif m == length(NumContours)
            line(c(1,NumContours(m)+1:end),c(2,NumContours(m)+1:end),'Color',[1 1 1])
        else
            line(c(1,NumContours(m)+1:NumContours(m+1)-1),c(2,NumContours(m)+1:NumContours(m+1)-1),'Color',[1 1 1])
        end
    end
end
ylabel('Depth (km)');
xlabel('Vp/Vs');
title(['Moho = ' num2str(MaxH,'%.1f') ' \pm ' num2str(MaxHsig,'%.1f')  ' km'...
    ', Vp/Vs = ' num2str(Maxk,'%.2f') ' \pm ' num2str(Maxksig,'%.2f')...
    ', Poisson''s Ratio = ' num2str(MaxP,'%.3f') ' \pm ' num2str(MaxPsig,'%.3f')],'FontSize',10)
caxis([0.67 1])
colorbar('ylim',[0 1]);
line(k,Hps,'Color',[1 0 0])
line(k,Hpp,'Color',[0 0 1])
line(k,Hss,'Color',[0 0 1])
if Hps(1) > HMax
    if ~isempty(find(Hps<=HMax,1))
        text(k(find(Hps>=HMax,1)),HMax,'Ps','Color',[1 0 0])
    end
else
    text(k(1),Hps(1),'Ps','Color',[1 0 0])
end
if Hpp(1) > HMax
    if ~isempty(find(Hpp<=HMax,1))
        text(k(find(Hpp<=HMax,1)),HMax,'Ps','Color',[1 0 0])
    end
else
    text(k(1),Hpp(1),'PpPs','Color',[0 0 1])
end
if Hss(1) > HMax
    if ~isempty(find(Hss<=HMax,1))
        text(k(find(Hss<=HMax,1)),HMax,'Ps','Color',[1 0 0])
    end
else
    text(k(1),Hss(1),'PsPs','Color',[0 0 1])
end