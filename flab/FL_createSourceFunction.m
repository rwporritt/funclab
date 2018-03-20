function [sourceAmp, sourceHeader, arrivalTimes, ierr] = FL_createSourceFunction(FL_rfOpt, rawTracesFileNames, ievent, nstations, ProjectDirectory)
%% Function to align a set of traces about an arrival via a multi-channel
%  cross correlation and then stack the
%  aligned traces for an empical source function
%  Also returns the relative delay times required for the alignment
%  See FL_processAndWriteRFS for format of FL_rfOpt

if strcmp(FL_rfOpt.processingIncidentPhase,'P') || strcmp(FL_rfOpt.processingIncidentPhase,'PKP')
    minDelay = -5;
    maxDelay = 5;
end

if strcmp(FL_rfOpt.processingIncidentPhase,'S') || strcmp(FL_rfOpt.processingIncidentPhase,'SKS')
    minDelay = -15;
    maxDelay = 15;
end

% From the top layer of iasp91...
Vp = 5.8;
Vs = 3.36;

% rough quality control
minSNR = 0;

% Counter to keep track of traces that estimate the source
j=0;
jdx=zeros(1,nstations);
latitudes = zeros(1,nstations);
longitudes = zeros(1,nstations);

% And an array to hold them
allSources = zeros(nstations, length(minDelay:FL_rfOpt.sampleRate:maxDelay)-1);


% Make sure to setup an event directory
% seisFiles = strsplit(rawTracesFileNames{ievent,1});
% [eseis, nseis, zseis, hdr] = read3seis(seisFiles{1}, ...
% 					   seisFiles{2}, ...
% 					   seisFiles{3} );
%         
% % Get timing
% year = hdr.event.nzyear;
% jday = hdr.event.nzjday;
% hour = hdr.event.nzhour;
% minute = hdr.event.nzmin;
% sec = hdr.event.nzsec;
% EventDir = sprintf('Event_%04d_%03d_%02d_%02d_%02d',year,jday,hour,minute,sec);



%% Loop for all stations
for istation = 1:nstations
    if ~isempty(rawTracesFileNames{ievent,istation})
        seisFiles = strsplit(rawTracesFileNames{ievent,istation});
        
        %% Try to read the seismograms from sac files
        [eseis, nseis, zseis, hdr] = read3seis(seisFiles{1}, ...
					   seisFiles{2}, ...
					   seisFiles{3} );
        
        % Get timing
        year = hdr.event.nzyear;
        jday = hdr.event.nzjday;
        hour = hdr.event.nzhour;
        minute = hdr.event.nzmin;
        sec = hdr.event.nzsec;
        EventDir = sprintf('Event_%04d_%03d_%02d_%02d_%02d',year,jday,hour,minute,sec);
        
        %% Check arrival is there

        % get arrival times 
        [~, ~, atimes, labels] = getTimes( hdr );
        predictedArrivalTime = getArrTime( FL_rfOpt.processingIncidentPhase, atimes, labels );
        if( isnan( predictedArrivalTime ) ),
            fprintf('Time of %s arrival not found in header. \n...Skipping\n', ...
                FL_rfOpt.processingIncidentPhase);
            % Skip to next
            continue;
        end
        
         %% check depth units
        hdr.event.evdp = checkDepthUnits( hdr.event.evdp, 'km');
        
        %% Pack into n x 3 array
        traceTimeInput = linspace(hdr.times.b, hdr.times.e, hdr.trcLen);
        threeCompSeis = zeros(hdr.trcLen,3);
        threeCompSeis(:,1) = eseis;
        threeCompSeis(:,2) = nseis;
        threeCompSeis(:,3) = zseis;       
        
        %% Choose proper ray parameter
        if strcmp(FL_rfOpt.processingIncidentPhase,'P') 
            rayp = hdr.user(1).data;
        elseif strcmp(FL_rfOpt.processingIncidentPhase,'PKP') 
            rayp = hdr.user(2).data;
        elseif strcmp(FL_rfOpt.processingIncidentPhase,'S') 
            rayp = hdr.user(3).data;
        elseif strcmp(FL_rfOpt.processingIncidentPhase,'SKS') 
            rayp = hdr.user(4).data;
        end
                 
        %% Rotate to the denominator's reference frame
        if strcmp(FL_rfOpt.processingDenominator, 'Vertical') || strcmp(FL_rfOpt.processingDenominator, 'Radial') || strcmp(FL_rfOpt.processingDenominator, 'Tangential/SH')
            [rotatedSeis, ~] = rotateSeisENZtoTRZ( threeCompSeis , hdr.evsta.baz );            
        elseif strcmp(FL_rfOpt.processingDenominator, 'P') || strcmp(FL_rfOpt.processingDenominator, 'SV')
            [tmpSeis, ~] = rotateSeisENZtoTRZ( threeCompSeis , hdr.evsta.baz );
            [rotatedSeis, ~] = rotateSeisTRZtoPSVSH( tmpSeis, rayp, Vp, Vs);
        else
            disp('Warning, component not set!');
        end
        
        %% Get the source seis from the rotated array
        if strcmp(FL_rfOpt.processingDenominator, 'Vertical')
            sourceSeis = rotatedSeis(:,3);
        elseif strcmp(FL_rfOpt.processingDenominator,'Radial')
            sourceSeis = rotatedSeis(:,2);
        elseif strcmp(FL_rfOpt.processingDenominator, 'Tangential/SH')
            sourceSeis = rotatedSeis(:,1);
        elseif strcmp(FL_rfOpt.processingDenominator, 'P')
            sourceSeis = rotatedSeis(:,1);
        elseif strcmp(FL_rfOpt.processingDenominator, 'SV')
            sourceSeis = rotatedSeis(:,2);
        end
        
        %% Get SNR estimate
        [snr, rmsn] = estimateSNR(sourceSeis, traceTimeInput, predictedArrivalTime+minDelay, predictedArrivalTime+maxDelay, predictedArrivalTime+minDelay-(maxDelay-minDelay),predictedArrivalTime+minDelay );
%        snr = minSNR+1;     
        %% Chop about the predicted time
        if snr > minSNR
            [choppedSeis, choppedTime] = chopSeis(sourceSeis, traceTimeInput, predictedArrivalTime+minDelay, predictedArrivalTime+maxDelay);
       
            % Errors occuring that choppedSeis and allsources have
            % different sizes.
            %postChopTimeArray=linspace(predictedArrivalTime+minDelay,predictedArrivalTime+maxDelay,length(choppedTime));
            %choppedSeis = interp1(choppedTime,choppedSeis,postChopTimeArray,'linear','extrap');
            
            
            %% on the first good station, get the timing info so we can make the event directory into a string variable
            if j==0
                year = hdr.event.nzyear;
                jday = hdr.event.nzjday;
                hour = hdr.event.nzhour;
                minute = hdr.event.nzmin;
                sec = hdr.event.nzsec;
                EventDir = sprintf('Event_%04d_%03d_%02d_%02d_%02d',year,jday,hour,minute,sec);
            end
            
            %% increment the counter
            j=j+1;
            jdx(j) = istation;
            latitudes(j) = hdr.station.stla;
            longitudes(j) = hdr.station.stlo;
        
            % Lets just try growinging choppedSeis by padding 0's. This
            % should not change the output as we are looking at pegging
            % this to 0 anyway
            while length(choppedSeis) < length(allSources(j,:))
                choppedSeis(end+1) = 0;
            end
            
            %% Save temporarily. Once all stations are chopped we can xcor them and stack
            allSources(j,:) = choppedSeis(1:length(allSources(j,:)));
            
        end % end SNR loop

    end  % Check for empty stations
    
end  % Loop over each station

%% Run multi-channel cross correlation
delays = FL_mccc(allSources,FL_rfOpt.sampleRate);

% Only keep non-zero indices
jdx(jdx==0) = [];
latitudes(latitudes==0) = [];
longitudes(longitudes==0) = [];
centerLatitude = mean(latitudes);
centerLongitude = mean(longitudes);

% Prepare a file to write the relative delays to
delayFileName = sprintf('delays_%s.txt',FL_rfOpt.processingIncidentPhase);
outdir = fullfile(ProjectDirectory, 'RAWTRACES', EventDir);
mkdir(outdir);
outputFileName = fullfile(ProjectDirectory, 'RAWTRACES', EventDir, delayFileName);
outputFile = fopen(outputFileName,'w');

% array to hold the source
stackedSourceSeis = zeros(1,length(allSources(1,:)));

%% main loop to re-read files, align, chop, and stack 
j=1;
for istation=jdx
    % Read files
    seisFiles = strsplit(rawTracesFileNames{ievent,istation});
    [eseis, nseis, zseis, hdr] = read3seis(seisFiles{1}, ...
					   seisFiles{2}, ...
					   seisFiles{3} );
    % get arrival times               
    [~, ~, atimes, labels] = getTimes( hdr );
    predictedArrivalTime = getArrTime( FL_rfOpt.processingIncidentPhase, atimes, labels );
    % get relative arrival time
    correlatedArrivalTime = predictedArrivalTime+delays(j);
    
    % write delay time information:
    fprintf(outputFile,'%f %f %f %f %f %f %f %f %f %f %f\n',...
        hdr.station.stlo, hdr.station.stla, hdr.station.stel, ...
        hdr.event.evlo, hdr.event.evla, hdr.event.evdp,...
        hdr.evsta.az, hdr.evsta.baz, hdr.evsta.gcarc,...
        correlatedArrivalTime, delays(j));
    
    % Pack into n x 3 array
    traceTimeInput = linspace(hdr.times.b, hdr.times.e, hdr.trcLen);
    threeCompSeis = zeros(hdr.trcLen,3);
    threeCompSeis(:,1) = eseis;
    threeCompSeis(:,2) = nseis;
    threeCompSeis(:,3) = zseis;       
   
    %% Choose proper ray parameter
    if strcmp(FL_rfOpt.processingIncidentPhase,'P') 
        rayp = hdr.user(1).data;
    elseif strcmp(FL_rfOpt.processingIncidentPhase,'PKP') 
        rayp = hdr.user(2).data;
    elseif strcmp(FL_rfOpt.processingIncidentPhase,'S') 
        rayp = hdr.user(3).data;
    elseif strcmp(FL_rfOpt.processingIncidentPhase,'SKS') 
        rayp = hdr.user(4).data;
    end
                 
    %% Rotate to the denominator's reference frame
    if strcmp(FL_rfOpt.processingDenominator, 'Vertical') || strcmp(FL_rfOpt.processingDenominator, 'Radial') || strcmp(FL_rfOpt.processingDenominator, 'Tangential/SH')
        [rotatedSeis, ~] = rotateSeisENZtoTRZ( threeCompSeis , hdr.evsta.baz );            
    elseif strcmp(FL_rfOpt.processingDenominator, 'P') || strcmp(FL_rfOpt.processingDenominator, 'SV')
        [tmpSeis, ~] = rotateSeisENZtoTRZ( threeCompSeis , hdr.evsta.baz );
        [rotatedSeis, ~] = rotateSeisTRZtoPSVSH( tmpSeis, rayp, Vp, Vs);
    else
        disp('Warning, component not set!');
    end
        
    %% Get the source seis from the rotated array
    if strcmp(FL_rfOpt.processingDenominator, 'Vertical')
        sourceSeis = rotatedSeis(:,3);
    elseif strcmp(FL_rfOpt.processingDenominator,'Radial')
        sourceSeis = rotatedSeis(:,2);
    elseif strcmp(FL_rfOpt.processingDenominator, 'Tangential/SH')
        sourceSeis = rotatedSeis(:,1);
    elseif strcmp(FL_rfOpt.processingDenominator, 'P')
        sourceSeis = rotatedSeis(:,1);
    elseif strcmp(FL_rfOpt.processingDenominator, 'SV')
        sourceSeis = rotatedSeis(:,2);
    end
    
    % Chop about the new arrival
    [choppedSeis, choppedTime] = chopSeis(sourceSeis, traceTimeInput, correlatedArrivalTime+minDelay, correlatedArrivalTime+maxDelay);
    %postChopTimeArray=linspace(correlatedArrivalTime+minDelay,correlatedArrivalTime+maxDelay,length(choppedTime));
    %choppedSeis = interp1(choppedTime,choppedSeis,postChopTimeArray,'linear','extrap');
    while length(choppedSeis) < length(stackedSourceSeis)
        choppedSeis(end+1) = 0;
    end
    
    
    % linearly stack the chopped seismograms (chopping ensures all on the
    % same time axis)
    stackedSourceSeis = stackedSourceSeis  + choppedSeis(1:length(stackedSourceSeis))';
    
    j=j+1;

end

fclose(outputFile);


%% Write stacked file in sac format
%  first taper the source function to avoid hard transitions
switch FL_rfOpt.processingTaper
    case ' 5% Hann'
        taperedData = FL_applyHannTaper(stackedSourceSeis, 5);
    case '10% Hann'
        taperedData = FL_applyHannTaper(stackedSourceSeis, 10);
    case ' 5% Hamming'
        taperedData = FL_applyHammingTaper(stackedSourceSeis, 5);
    case '10% Hamming'
        taperedData = FL_applyHammingTaper(stackedSourceSeis, 10);
    case 'No Taper'
        taperedData = stackedSourceSeis;
    otherwise
        taperedData = stackedSourceSeis;
end

%% The start of the source window is at 0, but we'll start the trace at 
%  FL_rfOpt.processingPrePhaseCut and end at FL_rfOpt.processingPostPhaseCut 
stackedTimeArray=linspace(0, correlatedArrivalTime+maxDelay-(correlatedArrivalTime+minDelay), length(taperedData));
outputSourceTime=-FL_rfOpt.processingPrePhaseCut:FL_rfOpt.sampleRate:FL_rfOpt.processingPostPhaseCut;
% interpolation and this will assumably make 0's at the fringes and a
% smooth transition on the sides of the phase arrival due to the taper
%stackedSourceData = interp1(stackedTimeArray, taperedData, outputSourceTime,'linear','extrap');
if strcmp(FL_rfOpt.processingIncidentPhase,'P') || strcmp(FL_rfOpt.processingIncidentPhase,'PKP')
    addSourceSample = round((minDelay + FL_rfOpt.processingPrePhaseCut)/FL_rfOpt.sampleRate);
elseif strcmp(FL_rfOpt.processingIncidentPhase,'S') || strcmp(FL_rfOpt.processingIncidentPhase,'SKS')
    addSourceSample = -1*round((-FL_rfOpt.processingPostPhaseCut-minDelay) / FL_rfOpt.sampleRate);
end
endSourceSample = addSourceSample + length(taperedData);
stackedSourceData=zeros(1,length(outputSourceTime));
if addSourceSample < 1
    addSourceSample = 1;
end
if endSourceSample > length(stackedSourceData)
    endSourceSample = length(stackedSourceData);
end
stackedSourceData(addSourceSample:endSourceSample-1) = taperedData(1:(endSourceSample-addSourceSample));


% much of the header can be reused, but some need to be updated
hdr.station.stla = centerLatitude;
hdr.station.stlo = centerLongitude;
hdr.station.kstnm = 'SOURCE';
hdr.station.knetwk = 'SS';
hdr.times.b = -FL_rfOpt.processingPrePhaseCut;
hdr.times.e = FL_rfOpt.processingPostPhaseCut;

sfile = sprintf('empirical_source_%s.SAC',FL_rfOpt.processingIncidentPhase);
outputSacFileName = fullfile(ProjectDirectory, 'RAWTRACES', EventDir, sfile);

writeSAC(outputSacFileName, hdr, stackedSourceData);

arrivalTimes = delays;
sourceAmp = stackedSourceData;
sourceHeader = hdr;
ierr = 0;



