function fl_view_data_coverage(RecordMetadataDoubles)
%FL_VIEW_DATA_COVERAGE  View data coverage diagram
%   FL_VIEW_DATA_COVERAGE(RecordMetadataDoubles) plots a polar diagram of
%   event/station pairs in ray parameter vs. backazimuth space.

%   Kevin C. Eagar
%   Date Created: 04/12/2008
%   Last Updated: 05/14/2010


% Edited to work with subsets. Plots the full project as grey and the
% current set by the set color
d1 = figure('Units','characters','NumberTitle','off','Name','Data Coverage',...
    'Position',[0 0 100 35],'CreateFcn',{@movegui_kce,'center'});

SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
RecordMetadataDoubles = SetManagementCell{1,3};

ActiveIn = find(cat(1,RecordMetadataDoubles(:,2)));
mmpolar(RecordMetadataDoubles(ActiveIn,19)*pi/180,RecordMetadataDoubles(ActiveIn,18),'Style','Compass','TTickValue',[0:15:360],...
    'RLimit',[0 0.08],'RTickValue',[0.02:0.02:0.08])
