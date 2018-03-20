function gccp_ex_volume(cbo,eventdata,handles)
%GCCP_EX_VOLUME Exports GCCP volume
%   GCCP_EX_VOLUME is a callback function that exports the GCCP stacks in
%   each bin into a text file with each separated by a header row and
%   followed by depth and amplitude information.  Formatting of the text
%   file is as follows:
%       "Bin Longitude" "Bin Latitude" "Depth" "Bin Radius" "Radial Amplitude" "Radial Bootstrap" "Transverse Amplitude" "Transverse Bootstrap"

%   Author: Kevin C. Eagar
%   Date Created: 04/23/2011
%   Last Updated: 04/24/2011
%   Editor: Robert W. Porritt
%   Last Edit: 04/05/2015
%   Added matfile export of a simple 3D format


ProjectDirectory = evalin('base','ProjectDirectory');
SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');

GCCPMetadataCell = evalin('base','GCCPMetadataCell');
GCCPMetadataStrings = GCCPMetadataCell{CurrentSubsetIndex,1};
GCCPMetadataDoubles = GCCPMetadataCell{CurrentSubsetIndex,2};
%GCCPMetadataStrings = evalin('base','GCCPMetadataStrings');
%GCCPMetadataDoubles = evalin('base','GCCPMetadataDoubles');

% Open the text files (overwrite if it exists)
%--------------------------------------------------------------------------
[FileName,Pathname] = uiputfile('*.txt','Save GCCP Volume to File',[ProjectDirectory filesep 'gccp_volume.txt']);
if FileName ~= 0
    WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
        'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
        'String','Please wait, exporting GCCP volume to text file...',...
        'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
    drawnow
    fid = fopen([Pathname FileName],'w+');
    
    for n = 1:size(GCCPMetadataStrings,1)
        % Load GCCP Table from the Project Directory
        %----------------------------------------------------------------------
        load([ProjectDirectory,filesep,GCCPMetadataStrings{n,1}])
        for m = 1:length(BootAxis)
            fprintf(fid,'%.3f %.3f %.5f %.2f %.5f %.5f %.5f %.5f\n',GCCPMetadataDoubles(n,11),GCCPMetadataDoubles(n,10),BootAxis(m),GCCPMetadataDoubles(n,12),RRFBootMean(m),RRFBootSigma(m),TRFBootMean(m),TRFBootSigma(m));
        end
    end
    fclose(fid);
    close(WaitGui)
end


[FileName,Pathname] = uiputfile('*.mat','Save GCCP Volume to File',[ProjectDirectory filesep 'gccp_volume.mat']);
outputFile = fullfile(Pathname, FileName);
if FileName ~= 0
    WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
        'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
        'String','Please wait, exporting GCCP volume to mat file...',...
        'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
    drawnow
    %fid = fopen([Pathname FileName],'w+');
    Longitudes = zeros(size(GCCPMetadataStrings,1)*length(GCCPMetadataStrings{1,4}),1);
    Latitudes = zeros(size(GCCPMetadataStrings,1)*length(GCCPMetadataStrings{1,4}),1);
    Depths = zeros(size(GCCPMetadataStrings,1)*length(GCCPMetadataStrings{1,4}),1);
    RRFAmpMean = zeros(size(GCCPMetadataStrings,1)*length(GCCPMetadataStrings{1,4}),1);
    RRFAmpSigma = zeros(size(GCCPMetadataStrings,1)*length(GCCPMetadataStrings{1,4}),1);
    TRFAmpMean = zeros(size(GCCPMetadataStrings,1)*length(GCCPMetadataStrings{1,4}),1);
    TRFAmpSigma = zeros(size(GCCPMetadataStrings,1)*length(GCCPMetadataStrings{1,4}),1);
    jdx=1;
    for n = 1:size(GCCPMetadataStrings,1)
        % Load GCCP Table from the Project Directory
        %----------------------------------------------------------------------
        load([ProjectDirectory,filesep,GCCPMetadataStrings{n,1}])
        for idx=1:length(BootAxis)
           Longitudes(jdx) = GCCPMetadataDoubles(n,11);
           Latitudes(jdx) = GCCPMetadataDoubles(n,10);
           Depths(jdx) = BootAxis(idx);
           RRFAmpMean(jdx) = RRFBootMean(idx);
           RRFAmpSigma(jdx) = RRFBootSigma(idx);
           TRFAmpMean(jdx) = TRFBootMean(idx);
           TRFAmpSigma(jdx) = TRFBootSigma(idx);
           jdx = jdx+1;
        end
    %    for m = 1:length(BootAxis)
    %        fprintf(fid,'%.3f %.3f %.5f %.2f %.5f %.5f %.5f %.5f\n',GCCPMetadataDoubles(n,11),GCCPMetadataDoubles(n,10),BootAxis(m),GCCPMetadataDoubles(n,12),RRFBootMean(m),RRFBootSigma(m),TRFBootMean(m),TRFBootSigma(m));
    %    end
    end
    %fclose(fid);
    save(outputFile,'Longitudes','Latitudes','Depths','RRFAmpMean','RRFAmpSigma','TRFAmpMean','TRFAmpSigma')
    close(WaitGui)
end

