function hk_ex_grids(cbo,eventdata,handles)
%HK_EX_GRIDS Exports H-k stacking grids
%   HK_EX_GRIDS is a callback function that exports the H-k grid of stacked
%   receiver function amplitdes at the given depth range and Vp/Vs range.
%   Each grid is output into a text file separated by a header row and 
%   followed by depth, Vp/Vs, Poisson Ratio, and amplitude information.
%   Formatting of the text file is as follows:
%       > "Station Longitude" "Station Latitude" "Station Elevation" "Station Name" "Moho Depth" "Moho Depth Error" "Vp/Vs" "Vp/Vs Error" "Poisson Ratio" "Poisson Ratio Error" "Number of RFs" "Assumed Vp" "Ps Weight" "PpPs Weight" "PsPs Weight" "Backazimuth Range" "Ray Parameter Range"
%       "Depth" "Vp/Vs" "Poisson Ratio" "Stacked Amplitude"

%   Author: Kevin C. Eagar
%   Date Created: 04/24/2011
%   Last Updated: 04/24/2011

ProjectDirectory = evalin('base','ProjectDirectory');
RecordMetadataStrings = evalin('base','RecordMetadataStrings');
RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
HkMetadataStrings = evalin('base','HkMetadataStrings');
HkMetadataDoubles = evalin('base','HkMetadataDoubles');

% Open the text files (overwrite if it exists)
%--------------------------------------------------------------------------
[FileName,Pathname] = uiputfile('hk_grids.txt','Save H-k Grids to File');
if FileName ~= 0
    WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
        'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
        'String','Please wait, exporting H-k stacking grids to text file...',...
        'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
    drawnow
    fid = fopen([Pathname FileName],'w+');
    
    for n = 1:size(HkMetadataStrings,1)
        % Load H-k Table from the Project Directory
        %----------------------------------------------------------------------
        load([ProjectDirectory,'/',HkMetadataStrings{n,1}])
        Indices = strmatch(HkMetadataStrings{n,2},RecordMetadataStrings(:,2));
        Index = Indices(1);
        StationLongitude = RecordMetadataDoubles(Index,11);
        StationLatitude = RecordMetadataDoubles(Index,10);
        StationElevation = RecordMetadataDoubles(Index,12);
        fprintf(fid,'> %.3f %.3f %.0f %s %.3f %.3f %.4f %.4f %.4f %.4f %.0f %.3f %.2f %.2f %.2f %.0f-%.0f %.3f-%.3f\n',...
            StationLongitude,StationLatitude,StationElevation*1000,HkMetadataStrings{n,2},HkMetadataDoubles(n,15),HkMetadataDoubles(n,16),HkMetadataDoubles(n,17),...
            HkMetadataDoubles(n,18),HkMetadataDoubles(n,19),HkMetadataDoubles(n,20),HkMetadataDoubles(n,1),HkMetadataDoubles(n,14),HkMetadataDoubles(n,11),...
            HkMetadataDoubles(n,12),HkMetadataDoubles(n,13),HkMetadataDoubles(n,7),HkMetadataDoubles(n,8),HkMetadataDoubles(n,9),HkMetadataDoubles(n,10));
        for m = 1:length(HAxis)
            for k = 1:length(kAxis)
                fprintf(fid,'%.5f %.5f %.5f %.5f\n',HAxis(m),kAxis(k),(0.5*(1-(1/(kAxis(k)^2-1)))),HKAmps(m,k));
            end
        end
    end
    fclose(fid);
    close(WaitGui)
end