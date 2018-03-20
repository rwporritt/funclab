function [Amps,Time] = fl_readseismograms(SacFile)
%FL_READSEISMOGRAMS reads seismograms from a SAC file
%   FL_READSEISMOGRAMS(SacFile) reads in a seismogram from a SAC file
%   specified by the pathname given as SacFile.  This function outputs
%   amplitude information into a vector AMPS and timing information into a
%   vector TIME.

%   Author: Kevin C. Eagar
%   Date Created: 04/19/2007
%   Last Updated: 09/10/2007

% Byte-order of the SAC file is checked
%--------------------------------------------------------------------------
fid = fopen(SacFile,'r','ieee-be');
fread(fid,70,'single');
fread(fid,6,'int32');
NVHDR = fread(fid,1,'int32');
fclose(fid);
if (NVHDR == 4 || NVHDR == 5)
    message = strcat('NVHDR = 4 or 5. File: "',SacFile,'" may be from an old version of SAC.');
    error(message)
elseif NVHDR ~= 6
    endian = 'ieee-le';
elseif NVHDR == 6
    endian = 'ieee-be';
end
fid = fopen(SacFile,'r',endian);

% Read in the header information to junk
%--------------------------------------------------------------------------
Delta = fread(fid,1,'single');
fread(fid,4,'single');
BeginTime = fread(fid,1,'single');
fread(fid,64,'single');
fread(fid,9,'int32');
NPoints = fread(fid,1,'int32');
fread(fid,25,'int32');
LEVEN = fread(fid,1,'int32');
fread(fid,4,'int32');
fread(fid,192,'char');

% Read in the amplitude information
%--------------------------------------------------------------------------
Amps = fread(fid,'single');

% Close the file
%--------------------------------------------------------------------------
fclose(fid);

% Calculate the end time from the delta, number of points, and the begin
% time.
%--------------------------------------------------------------------------
EndTime = (Delta * NPoints) + BeginTime - Delta;

% Create the timing vector
%--------------------------------------------------------------------------
if LEVEN == 1
    Time = linspace(BeginTime,EndTime,NPoints)';
else
    error('LEVEN must = 1; SAC file not evenly spaced')
end