function [outputTraces, ierr] = FL_writeFetchedTraces(fetchedTraces, BaseDir, TraceDir, responseChoice, eventInfo, ievent)
%% prepares file names and sac headers, then calls writeSAC.m from
% processRFmatlab/inout to write sac files.
% Sac files will take the form: NN.SSSS.LL.CCC.Q.YYYY,JJJ,HH:MN:SS.SAC
% Note that this output format is that of mseed2sac1.0-1.8 whereas
% msseed2sac2.0 has moved to a different format which is harder to parse
% out the minute and second. This may be a bad decision is naming
% conventions stick with mseed2sac2.0, but RWP feels that not having a
% delimiter between minutes and seconds is also a bad decision.
% Where the time information refers to the earthquake origin time (stored
% in the header as o).



%% Error checks - really should NEVER happen if used properly!
% Require 3 component data
if length(fetchedTraces) ~= 3
    fprintf('Error, FL_writeFetchedTraces given non-three component data!\n');
    ierr = 1;
    return
end

% Require 1 vertical component
ivertical = 0;
nvertical = 0;
for i=1:3
    if fetchedTraces{i}.dip ~= 0
        ivertical = i;
        nvertical = nvertical + 1;
    end
end
if nvertical ~= 1
    fprintf('Error, FL_writeFetchedTraces given more than or less than 1 vertical channel!\n');
    ierr = 2;
    return
end

% Copy the input cell arry to the output
outputTraces = fetchedTraces;

%% Build up the channel code
% Lets start by piecing together the channel code
% For the sake of sanity, we're going to assume only velocity instruments
% (middle character H)
% See: http://www.fdsn.org/seed_manual/SEEDManual_V2.4_Appendix-A.pdf
firstChannelChar = 'B';  % default and fits most pre-coded sample rates
if outputTraces{1}.sampleRate >= 80
    firstChannelChar = 'H';
elseif outputTraces{1}.sampleRate >= 10
    firstChannelChar = 'B';
elseif outputTraces{1}.sampleRate == 1
    firstChannelChar = 'L';
elseif outputTraces{1}.sampleRate >= 0.1
    firstChannelChar = 'V';
elseif outputTraces{1}.sampleRate >= 0.01
    firstChannelChar = 'U';
end  % other channel rates exist, but would be poor choices for most splitting analyses

% here is hard code to high gain broadband
secondChannelChar = 'H';

% stupidly complicated and in most cases redundant, but need to be sure
% that we have the right channel code in the structure
for itrace=1:3
    if outputTraces{itrace}.dip ~= 0
        % vertical
        channelCode = sprintf('%s%sZ',firstChannelChar, secondChannelChar);
        outputTraces{itrace}.channel = channelCode;
    else
        if outputTraces{itrace}.azimuth == 0
            % north
            channelCode = sprintf('%s%sN',firstChannelChar, secondChannelChar);
            outputTraces{itrace}.channel = channelCode;
        else
            %east
            channelCode = sprintf('%s%sE',firstChannelChar, secondChannelChar);
            outputTraces{itrace}.channel = channelCode;
        end
    end
end

%% Force a non-null network code
if strcmp(outputTraces{1}.network,'')
    for i=1:3
        outputTraces{i}.network = sprintf('00');
    end
end

%% Create the file name for each sac file
tmp = datevec(eventInfo.OriginTime{ievent});  % uses the matlab built-in
jday = dayofyear(tmp(1), tmp(2), tmp(3));    % sub-function included with funclab
FileNameConvention = 'mseed2sac_alldots';
for itrace = 1:3
    % Allows future editors to switch the output format....
    switch FileNameConvention
        case 'mseed2sac_alldots'
            outputTraces{itrace}.sacFileName = sprintf('%s.%s.%s.%s.%s.%04d.%03d.%02d.%02d.%02.0f.SAC',...
                outputTraces{itrace}.network,outputTraces{itrace}.station, outputTraces{itrace}.location,...
                outputTraces{itrace}.channel, outputTraces{itrace}.quality,...
                tmp(1), jday, tmp(4), tmp(5), tmp(6));
        case 'RDSEED'
            % RDSEED format '1993.159.23.15.09.7760.IU.KEV..BHN.D.SAC'
            outputTraces{itrace}.sacFileName = sprintf('%04d.%03d.%02d.%02d.%07.4f.%s.%s.%s.%s.%s.SAC',...
                tmp(1), jday, tmp(4), tmp(5), tmp(6),...
                outputTraces{itrace}.network,outputTraces{itrace}.station, outputTraces{itrace}.location,...
                outputTraces{itrace}.channel, outputTraces{itrace}.quality);
        case 'mseed2sac1'
            outputTraces{itrace}.sacFileName = sprintf('%s.%s.%s.%s.%s.%04d,%03d,%02d:%02d:%02.0f.SAC',...
                outputTraces{itrace}.network,outputTraces{itrace}.station, outputTraces{itrace}.location,...
                outputTraces{itrace}.channel, outputTraces{itrace}.quality,...
                tmp(1), jday, tmp(4), tmp(5), tmp(6));

        case 'mseed2sac2'
            outputTraces{itrace}.sacFileName = sprintf('%s.%s.%s.%s.%s.%04d.%03d.%02d%02d%02.0f.SAC',...
                outputTraces{itrace}.network,outputTraces{itrace}.station, outputTraces{itrace}.location,...
                outputTraces{itrace}.channel, outputTraces{itrace}.quality,...
                tmp(1), jday, tmp(4), tmp(5), tmp(6));
        case 'SEISAN'
            % SEISAN format '2003-05-26-0947-20S.HOR___003_HORN__BHZ__SAC'
            outputTraces{itrace}.sacFileName = sprintf('%04d-%02d-%02d-%02d%02d-%02.0fS.%s___%s_%s__%s__SAC',...
                tmp(1), tmp(2),tmp(3), tmp(4), tmp(5), tmp(6),...
                outputTraces{itrace}.network, outputTraces{itrace}.location,...
                outputTraces{itrace}.station, outputTraces{itrace}.channel);
        case 'YYYY.JJJ.hh.mm.ss.stn.sac.e'
            %  Format: 1999.136.15.25.00.ATD.sac.z
            outputTraces{itrace}.sacFileName = sprintf('%04d.%03d.%02d.%02d.%02.0f.%s.sac.%s',tmp(1), jday, tmp(4), tmp(5), tmp(6),...
                outputTraces{itrace}.station, lower(outputTraces{itrace}.channel(end)));
        case 'YYYY.MM.DD-hh.mm.ss.stn.sac.e';
            % Format: 2003.10.07-05.07.15.DALA.sac.z
            outputTraces{itrace}.sacFileName = sprintf('%04d.%02d.%02d-%02d.%02d.%02.0f.%s.sac.%s',tmp(1), tmp(2), tmp(3), tmp(4), tmp(5), tmp(6),...
                outputTraces{itrace}.station, lower(outputTraces{itrace}.channel(end)));
        case 'YYYY_MM_DD_hhmm_stnn.sac.e';
            % Format: 2005_03_02_1155_pptl.sac (LDG/CEA data)
            outputTraces{itrace}.sacFileName = sprintf('%04d_%02d_%02d_%02d%02d_%s.sac.%s',tmp(1), tmp(2), tmp(3), tmp(4), tmp(5),...
                outputTraces{itrace}.station, lower(outputTraces{itrace}.channel(end)));
        case 'stn.YYMMDD.hhmmss.e'
            % Format: fp2.030723.213056.X (BroadBand OBS data)
            outputTraces{itrace}.sacFileName = sprintf('%s.%02d%02d%02d.%02d%02d%02.0f.%s',outputTraces{itrace}.station,...
                tmp(1)-2000,tmp(2),tmp(3),tmp(4),tmp(5),tmp(6),lower(outputTraces{itrace}.channel(end)));
        case '*.e; *.n; *.z'
            % free format - choose mseed2sac1 because RWP likes it best,
            % but append .e, .n, or.z
            outputTraces{itrace}.sacFileName = sprintf('%s.%s.%s.%s.%s.%04d,%03d,%02d:%02d:%02.0f.SAC.%s',...
                outputTraces{itrace}.network,outputTraces{itrace}.station, outputTraces{itrace}.location,...
                outputTraces{itrace}.channel, outputTraces{itrace}.quality,...
                tmp(1), jday, tmp(4), tmp(5), tmp(6),lower(outputTraces{itrace}.channel(end)));
    end
end
% Need to add in event_year_jjj...
eventDir = sprintf('Event_%04d_%03d_%02d_%02d_%02d',tmp(1),jday,tmp(4),tmp(5),round(tmp(6)));
str = fullfile(BaseDir, TraceDir, eventDir);
[~,~,~] = mkdir(str);
% full file name
for itrace = 1:3
   outputTraces{itrace}.fullSacFileName = fullfile(BaseDir, TraceDir, eventDir, outputTraces{itrace}.sacFileName);
end


% Begin to create header
traceOriginTime = 0; %o
traceBeginTime = 24*60*60*(outputTraces{1}.startTime - irisTimeStringToEpoch(eventInfo.OriginTime{ievent}));  %b - seconds since the origin
traceEndTime   = 24*60*60*(outputTraces{1}.endTime - irisTimeStringToEpoch(eventInfo.OriginTime{ievent})); %e

% determines the independent variable based on the response decision
switch responseChoice
    case 'No Removal'
        idep = 5;
    case 'Scalar Only'
        idep = 5;
    case 'Pole-Zero to Displacement'
        idep = 6;
    case 'Pole-Zero to Velocity'
        idep = 7;
    case 'Pole-Zero to Acceleration'
        idep = 8;
end

%% Building the header up
hdr.times.delta = 1.0/outputTraces{1}.sampleRate;
hdr.scale = -12345;
hdr.times.b = traceBeginTime;
hdr.times.e = traceEndTime;
hdr.times.o = traceOriginTime;
hdr.times.a = -12345;
for i=1:10
    hdr.times.atimes(i).t = -12345;
end
hdr.response=-12345*ones(1,10);
hdr.station.stla = outputTraces{1}.latitude;
hdr.station.stlo = outputTraces{1}.longitude;
hdr.station.stel = outputTraces{1}.elevation;
hdr.station.stdp = outputTraces{1}.depth;
hdr.event.evla = eventInfo.OriginLatitude{ievent}; % event info
hdr.event.evlo = eventInfo.OriginLongitude{ievent};
hdr.event.evel = 0; % No airquakes please!
hdr.event.evdp = eventInfo.OriginDepth{ievent}; % event depth
hdr.event.mag = eventInfo.OriginMagnitude{ievent};
for i=1:10
    hdr.user(i).data=-12345;
end
[dist, bazi, xdeg] = distaz(hdr.station.stla, hdr.station.stlo, hdr.event.evla, hdr.event.evlo);
[~, azi, ~] = distaz(hdr.event.evla, hdr.event.evlo,hdr.station.stla, hdr.station.stlo);
hdr.evsta.dist = dist;
hdr.evsta.az = azi;
hdr.evsta.baz = bazi;
hdr.evsta.gcarc = xdeg;
hdr.event.nzyear = tmp(1);
hdr.event.nzjday = jday;
hdr.event.nzhour = tmp(4);
hdr.event.nzmin = tmp(5);
hdr.event.nzsec = tmp(6);
tt=sscanf(eventInfo.OriginTime{ievent},'%d-%d-%d %d:%d:%d.%d');
hdr.event.nzmsec = tt(7);
hdr.llnl.nwfid = -12345;
hdr.descrip.idep = idep;
hdr.descrip.iztype = 09;
tmpstr = [outputTraces{1}.station '-' outputTraces{1}.location];
hdr.station.kstnm = sprintf('%-8s',tmpstr);
if length(eventInfo.OriginName{ievent}) >= 16
    hdr.event.kevnm = sprintf('%-16s',eventInfo.OriginName{ievent}(1:16));
else
    hdr.event.kevnm = sprintf('%-16s',eventInfo.OriginName{ievent});
end
hdr.times.k0 = sprintf('%-8s','-12345');
hdr.times.ka = sprintf('%-8s','-12345');
for i=1:10
    hdr.times.atimes(i).label=sprintf('%-8s','-12345');
end
for i=1:3
    hdr.user(i).label = sprintf('%-8s','-12345');
end
hdr.station.knetwk = sprintf('%-8s',outputTraces{1}.network);

% Get predicted P, PKP, S, and SKS arrival times and ray parameters (if available)
predictedTravelTimes = taupTime([],eventInfo.OriginDepth{ievent},'P,PKP,S,SKS','deg',xdeg);
for i=1:length(predictedTravelTimes)
    if strcmp(predictedTravelTimes(i).phaseName,'P')
        hdr.times.atimes(1).label = sprintf('P');
        hdr.times.atimes(1).t =  predictedTravelTimes(i).time;
        hdr.user(1).data = predictedTravelTimes(i).rayParam * (pi/180) / 111.19;
        hdr.user(1).label = sprintf('p (P)');
    elseif strcmp(predictedTravelTimes(i).phaseName,'PKP')
        hdr.times.atimes(2).label = sprintf('PKP');
        hdr.times.atimes(2).t =  predictedTravelTimes(i).time;
        hdr.user(2).data = predictedTravelTimes(i).rayParam * (pi/180) / 111.19;
        hdr.user(2).label = sprintf('p (PKP)');        
    elseif strcmp(predictedTravelTimes(i).phaseName,'S')
        hdr.times.atimes(3).label = sprintf('S');
        hdr.times.atimes(3).t =  predictedTravelTimes(i).time;
        hdr.user(3).data = predictedTravelTimes(i).rayParam * (pi/180) / 111.19;
        hdr.user(3).label = sprintf('p (S)');
    elseif strcmp(predictedTravelTimes(i).phaseName,'SKS')
        hdr.times.atimes(4).label = sprintf('SKS');
        hdr.times.atimes(4).t =  predictedTravelTimes(i).time;
        hdr.user(4).data = predictedTravelTimes(i).rayParam * (pi/180) / 111.19;
        hdr.user(4).label = sprintf('p (SKS)');
    end    
end


% Finish with component based headers and write the traces
for itrace = 1:3
    hdr.station.cmpaz = outputTraces{itrace}.azimuth;
    hdr.station.cmpinc = outputTraces{itrace}.dip+90;
    hdr.station.kcmpnm = outputTraces{itrace}.channel;
    writeSAC(outputTraces{itrace}.fullSacFileName, hdr, outputTraces{itrace}.data)
    fprintf('Wrote sac file: %s\n',outputTraces{itrace}.fullSacFileName);
end

ierr=0;


