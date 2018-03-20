function fl_datainfo(varargin)
%FL_DATAINFO Compute dataset statistics
%   FL_DATAINFO(ProjectDirectory) computes statistics on the dataset in the
%   "Project" file and saves those to a variable in that file.

%   Author: Kevin C. Eagar
%   Date Created: 01/07/2008
%   Last Updated: 05/13/2010

switch nargin
    case 2
        ProjectDirectory = varargin{1};
        ProjectFile = varargin{2};
        load([varargin{1} varargin{2}],'RecordMetadataStrings','RecordMetadataDoubles');
        SetIndex = 1;
    case 4
        ProjectDirectory = varargin{1};
        ProjectFile = varargin{2};
        RecordMetadataStrings = varargin{3};
        RecordMetadataDoubles = varargin{4};
        SetIndex = evalin('base','CurrentSubsetIndex');
    case 5
        ProjectDirectory = varargin{1};
        ProjectFile = varargin{2};
        RecordMetadataStrings = varargin{3};
        RecordMetadataDoubles = varargin{4};
        SetIndex = varargin{5};
    otherwise
        error(['Incorrect number of inputs for ' mfilename '.'])
end
DataInfo = {...
    'Total Stations',...
    'Total Events',...
    'Total Event/Station Pairs',...
    'Active Stations',...
    'Active Events',...
    'Active Event/Station Pairs',...
    'Total Distance Min. (deg)',...
    'Total Distance Max. (deg)',...
    'Total Ray Parameter Min. (s/km)',...
    'Total Ray Parameter Max. (s/km)',...
    'Total Magnitude Min.',...
    'Total Magnitude Max.',...
    'Active Distance Min. (deg)',...
    'Active Distance Max. (deg)',...
    'Active Ray Parameter Min. (s/km)',...
    'Active Ray Parameter Max. (s/km)',...
    'Active Magnitude Min.',...
    'Active Magnitude Max.'...
    };
ActiveIn = find(RecordMetadataDoubles(:,2));
ActiveDoubles = RecordMetadataDoubles(ActiveIn,:);
ActiveStrings = RecordMetadataStrings(ActiveIn,:);
DataValue = cell(length(DataInfo),1);
DataValue{1} = length(unique(RecordMetadataStrings(:,2)));
DataValue{2} = length(unique(RecordMetadataStrings(:,3)));
DataValue{3} = size(RecordMetadataStrings,1);
DataValue{4} = length(unique(ActiveStrings(:,2)));
DataValue{5} = length(unique(ActiveStrings(:,3)));
DataValue{6} = size(ActiveStrings,1);
DataValue{7} = min(RecordMetadataDoubles(:,17));
DataValue{8} = max(RecordMetadataDoubles(:,17));
DataValue{9} = min(RecordMetadataDoubles(:,18));
DataValue{10} = max(RecordMetadataDoubles(:,18));
DataValue{11} = min(RecordMetadataDoubles(:,16));
DataValue{12} = max(RecordMetadataDoubles(:,16));
DataValue{13} = min(ActiveDoubles(:,17));
DataValue{14} = max(ActiveDoubles(:,17));
DataValue{15} = min(ActiveDoubles(:,18));
DataValue{16} = max(ActiveDoubles(:,18));
DataValue{17} = min(ActiveDoubles(:,16));
DataValue{18} = max(ActiveDoubles(:,16));

load([ProjectDirectory ProjectFile]);
if ~exist('Datastats','var')
    Datastats = cell(1,1);
end
if ~iscell(Datastats)
    tmp = Datastats;
    Datastats = cell(1,1);
    Datastats{1} = tmp;
end

Datastats{SetIndex} = [colvector(DataInfo) colvector(DataValue)];

save([ProjectDirectory ProjectFile],'Datastats','-append');

