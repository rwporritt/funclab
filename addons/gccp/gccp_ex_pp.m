function gccp_ex_pp(cbo,eventdata,handles)
%GCCP_EX_PP Exports piercing points at specified depths
%   GCCP_EX_PP is a callback function that exports receiver function
%   piercing points (taken from the 1D ray tracing) at a user-specified
%   depth.

%   Author: Kevin C. Eagar
%   Date Created: 04/23/2011
%   Last Updated: 04/24/2011

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
    GCCPDataDir = fullfile(ProjectDirectory, 'GCCPData');
    GCCPMatFile = fullfile(ProjectDirectory, 'GCCPData', 'GCCPData.mat');
    GCCPBinLead = ['GCCPData' filesep 'Bin_'];
else
    GCCPDataDir = fullfile(ProjectDirectory, 'GCCPData', SetName);
    GCCPMatFile = fullfile(ProjectDirectory, 'GCCPData', SetName, 'GCCPData.mat');
    GCCPBinLead = ['GCCPData' filesep SetName filesep 'Bin_'];
end


load(GCCPMatFile,'RayMatrix*','DepthAxis')
GCCPMetadataCell = evalin('base','GCCPMetadataCell');
GCCPMetadataStrings = GCCPMetadataCell{CurrentSubsetIndex,1};
GCCPMetadataDoubles = GCCPMetadataCell{CurrentSubsetIndex,2};
%GCCPMetadataStrings = evalin('base','GCCPMetadataStrings');
%GCCPMetadataDoubles = evalin('base','GCCPMetadataDoubles');
DepthIncrement = GCCPMetadataDoubles(1,1);
Depth = str2double(inputdlg('Enter Depth to Save Receiver Function Piercing Points'));    
% Open the text files (overwrite if it exists)
%--------------------------------------------------------------------------
[FileName,Pathname] = uiputfile(['gccp_piercepoints_' sprintf('%.0f',Depth) '.txt'],'Save Receiver Function Piercing Points to File');
if FileName ~= 0
    WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
        'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
        'String',['Please wait, exporting receiver function piercing points at depth ' sprintf('%.1f',Depth) ' to text file...'],...
        'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
    drawnow
    fid = fopen([Pathname FileName],'w+');
    RayNames = who('RayMatrix*');
    for n = 1:length(RayNames)
        Rays = eval(RayNames{n});
        for m = 1:size(Rays,2)
            Lon = interp1(DepthAxis,Rays(:,m,6),Depth);
            Lat = interp1(DepthAxis,Rays(:,m,5),Depth);
            fprintf(fid,'%.3f %.3f %.3f\n',Lon,Lat,Depth);
        end
    end
    fclose(fid);
    close(WaitGui)
end