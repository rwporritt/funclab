function AMPS = ccp_readamps(SacFile)
%CCP_READAMPS reads seismogram amplitudes from a SAC file
%   CCP_READAMPS(SacFile) reads in a seismogram from a SAC file specified
%   by the pathname given as SacFile.  This function outputs amplitude
%   information into a vector AMPS .

%   Author: Kevin C. Eagar
%   Date Created: 09/10/2007
%   Last Updated: 05/17/2010

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
fread(fid,70,'single');
fread(fid,35,'int32');
LEVEN = fread(fid,1,'int32');
fread(fid,4,'int32');
fread(fid,192,'char');

% Read in the amplitude information
%--------------------------------------------------------------------------
AMPS = fread(fid,'single');

% Close the file
%--------------------------------------------------------------------------
fclose(fid);

% Create the timing vector
%--------------------------------------------------------------------------
if LEVEN ~= 1
    error('LEVEN must = 1; SAC file not evenly spaced')
end