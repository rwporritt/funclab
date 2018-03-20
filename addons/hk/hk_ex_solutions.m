function hk_ex_solutions(cbo,eventdata,handles)
%HK_EX_SOLUTIONS Exports H-k stacking solutions
%   HK_EX_SOLUTIONS is a callback function that exports the H-k stacking
%   solutions for Moho depth, Vp/Vs, and Poisson Ratio.  The text fileis
%   formatted as follows:
%       "Station Longitude" "Station Latitude" "Station Elevation" "Station Name" "Moho Depth" "Moho Depth Error" "Vp/Vs" "Vp/Vs Error" "Poisson Ratio" "Poisson Ratio Error" "Number of RFs" "Assumed Vp" "Ps Weight" "PpPs Weight" "PsPs Weight" "Backazimuth Range" "Ray Parameter Range"

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
[FileName,Pathname] = uiputfile('hk_solutions.txt','Save H-k Solutions to File');
if FileName ~= 0
    WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
        'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
        'String','Please wait, exporting H-k stacking solutions to text file...',...
        'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
    drawnow
    fid = fopen([Pathname FileName],'w+');
    
    for n = 1:size(HkMetadataStrings,1)
        % Load H-k Table from the Project Directory
        %----------------------------------------------------------------------
        load([ProjectDirectory,filesep,HkMetadataStrings{n,1}])
        Indices = strmatch(HkMetadataStrings{n,2},RecordMetadataStrings(:,2));
        Index = Indices(1);
        StationLongitude = RecordMetadataDoubles(Index,11);
        StationLatitude = RecordMetadataDoubles(Index,10);
        StationElevation = RecordMetadataDoubles(Index,12);
        fprintf(fid,'%.3f %.3f %.0f %s %.3f %.3f %.4f %.4f %.4f %.4f %.0f %.3f %.2f %.2f %.2f %.0f-%.0f %.3f-%.3f\n',...
            StationLongitude,StationLatitude,StationElevation*1000,HkMetadataStrings{n,2},HkMetadataDoubles(n,15),HkMetadataDoubles(n,16),HkMetadataDoubles(n,17),...
            HkMetadataDoubles(n,18),HkMetadataDoubles(n,19),HkMetadataDoubles(n,20),HkMetadataDoubles(n,1),HkMetadataDoubles(n,14),HkMetadataDoubles(n,11),...
            HkMetadataDoubles(n,12),HkMetadataDoubles(n,13),HkMetadataDoubles(n,7),HkMetadataDoubles(n,8),HkMetadataDoubles(n,9),HkMetadataDoubles(n,10));
    end
    fclose(fid);
    close(WaitGui)
end