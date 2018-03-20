function ccp_ex_stacks(cbo,eventdata,handles)
%CCP_EX_STACKS Exports CCP stacks
%   CCP_EX_STACKS is a callback function that exports the CCP stacks in
%   each bin into a text file with each separated by a header row and
%   followed by depth and amplitude information.  Formatting of the text
%   file is as follows:
%       > "Bin Longitude" "Bin Latitude" "Bin Radius"
%       "Depth" "Radial Amplitude" "Radial Bootstrap" "Transverse Amplitude" "Transverse Bootstrap"

%   Author: Kevin C. Eagar
%   Date Created: 04/23/2011
%   Last Updated: 04/24/2011

ProjectDirectory = evalin('base','ProjectDirectory');

SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');

CCPMetadataCell = evalin('base','CCPMetadataCell');
CCPMetadataStrings = CCPMetadataCell{CurrentSubsetIndex,1};
CCPMetadataDoubles = CCPMetadataCell{CurrentSubsetIndex,2};
%CCPMetadataStrings = evalin('base','CCPMetadataStrings');
%CCPMetadataDoubles = evalin('base','CCPMetadataDoubles');
if CurrentSubsetIndex == 1
    CCPMatFile = fullfile(ProjectDirectory, 'CCPData', 'CCPData.mat');
    CCPBinLead = ['CCPData' filesep 'Bin_'];
else
    CCPMatFile = fullfile(ProjectDirectory, 'CCPData', SetName, 'CCPData.mat');
    CCPBinLead = ['CCPData' filesep SetName filesep 'Bin_'];
end
load(CCPMatFile,'DepthAxis','CCPGrid')

% Open the text files (overwrite if it exists)
%--------------------------------------------------------------------------
[FileName,Pathname] = uiputfile('*.txt','Save CCP Stacks to File',[ProjectDirectory filesep 'ccp_stacks.txt']);
if FileName ~= 0
    WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
        'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
        'String','Please wait, exporting CCP stacks to text file...',...
        'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
    drawnow
    fid = fopen([Pathname FileName],'w+');
    
    for n = 1:size(CCPMetadataStrings,1)
        % Load CCP Table from the Project Directory
        %----------------------------------------------------------------------
        load([ProjectDirectory, filesep ,CCPMetadataStrings{n,1}])
        %fprintf(fid,'> %.3f %.3f %.2f\n',CCPMetadataDoubles(n,11),CCPMetadataDoubles(n,10),CCPMetadataDoubles(n,12));
        %for m = 1:length(BootAxis)
        %    fprintf(fid,'%.5f %.5f %.5f %.5f %.5f\n',BootAxis(m),RRFBootMean(m),RRFBootSigma(m),TRFBootMean(m),TRFBootSigma(m));
        %end
        binwidth = cell2mat(CCPGrid{n,3});
        hits = cell2mat(CCPGrid{n,6});
        avgrp = CCPGrid{n,7};
        
        %gridlons = cell2mat(temp)
        %gridlats = CCPGrid(:,1);
        %fprintf(fid,'> %.3f %.3f %.2f\n',CCPMetadataDoubles(n,11),CCPMetadataDoubles(n,10),CCPMetadataDoubles(n,12));
        
        
        for m = 1:length(BootAxis)
            %if hits(m) >= minhits
                fprintf(fid,'%.3f %.3f %.0f %.5f %.5f %.5f %.5f %.5f %.3f %.0f %0.3f\n',CCPMetadataDoubles(n,11),CCPMetadataDoubles(n,10),0,BootAxis(m),RRFBootMean(m),RRFBootSigma(m),TRFBootMean(m),TRFBootSigma(m),binwidth(m),hits(m),avgrp);
            %end
        end
    end
    fclose(fid);
    close(WaitGui)
end


[FileName,Pathname] = uiputfile('*.mat','Save CCP Volume to File',[ProjectDirectory filesep 'ccp_stacks.mat']);
outputFile = fullfile(Pathname, FileName);
if FileName ~= 0
    WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
        'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
        'String','Please wait, exporting CCP volume to mat file...',...
        'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
    drawnow
    %fid = fopen([Pathname FileName],'w+');
    Longitudes = zeros(size(CCPMetadataStrings,1)*length(CCPMetadataStrings{1,4}),1);
    Latitudes = zeros(size(CCPMetadataStrings,1)*length(CCPMetadataStrings{1,4}),1);
    Depths = zeros(size(CCPMetadataStrings,1)*length(CCPMetadataStrings{1,4}),1);
    RRFAmpMean = zeros(size(CCPMetadataStrings,1)*length(CCPMetadataStrings{1,4}),1);
    RRFAmpSigma = zeros(size(CCPMetadataStrings,1)*length(CCPMetadataStrings{1,4}),1);
    TRFAmpMean = zeros(size(CCPMetadataStrings,1)*length(CCPMetadataStrings{1,4}),1);
    TRFAmpSigma = zeros(size(CCPMetadataStrings,1)*length(CCPMetadataStrings{1,4}),1);
    jdx=1;
    for n = 1:size(CCPMetadataStrings,1)
        % Load CCP Table from the Project Directory
        %----------------------------------------------------------------------
        load([ProjectDirectory,filesep,CCPMetadataStrings{n,1}])
        for idx=1:length(BootAxis)
           Longitudes(jdx) = CCPMetadataDoubles(n,11);
           Latitudes(jdx) = CCPMetadataDoubles(n,10);
           Depths(jdx) = BootAxis(idx);
           RRFAmpMean(jdx) = RRFBootMean(idx);
           RRFAmpSigma(jdx) = RRFBootSigma(idx);
           TRFAmpMean(jdx) = TRFBootMean(idx);
           TRFAmpSigma(jdx) = TRFBootSigma(idx);
           jdx = jdx+1;
        end
    %    for m = 1:length(BootAxis)
    %        fprintf(fid,'%.3f %.3f %.5f %.2f %.5f %.5f %.5f %.5f\n',CCPMetadataDoubles(n,11),CCPMetadataDoubles(n,10),BootAxis(m),CCPMetadataDoubles(n,12),RRFBootMean(m),RRFBootSigma(m),TRFBootMean(m),TRFBootSigma(m));
    %    end
    end
    %fclose(fid);
    save(outputFile,'Longitudes','Latitudes','Depths','RRFAmpMean','RRFAmpSigma','TRFAmpMean','TRFAmpSigma')
    close(WaitGui)
end
