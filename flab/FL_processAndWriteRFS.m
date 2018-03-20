function FL_processAndWriteRFS(FL_rfOpt, rawTracesFileNames, ievent, nstations, ProjectDirectory, endString,primaryOrSecondaryFlag, otherRFinfo)
%% Process waveforms from RAWTRACES directory to data ready for analysis in funclab
%  Draws sac file names from rawTracesFileNames
%    rawTracesFileNames is a nevent x nstation cell array and each entry is
%    either an empty matrix or the three sac file names separated by spaces
%
% FL_rfOpt structure:
% FL_rfOpt.processingTaper              - 5% or 10% Hann or Hamming taper
% applied symmetrically.
% FL_rfOpt.processingFilterHp           - high corner frequency for
% butterworth 2 pass filter
% FL_rfOpt.processingFilterLp           - low corner frequency for
% butterworth 2 pass filter
% FL_rfOpt.processingFilterOrder        - order of the filter
% FL_rfOpt.processingPrePhaseCut        - seconds before the incident phase
% to keep. Used both for the deconvolution and final trace output
% FL_rfOpt.processingPostPhaseCut       - seconds after the incident phase
% to keep
% FL_rfOpt.processingNumerator          - component of motion for the
% numerator in the deconvolution. Converted phases appear on this component
% FL_rfOpt.processingDenominator        - component of motion for the
% denominator. The source phase should appear on this component
% FL_rfOpt.processingDenominatorMethod  - decision between the standard
% deconvolution method of removing the P or S observed at a station from
% the converted phases at the same station or developing an array wide
% source function and using that as the denominator. This case funclab will
% compute cross-correlated arrival times and stack a short wavelet for the
% source
% FL_rfOpt.processingGaussian           - gaussian filter for rf
% computation. Larger values are better for crust/shallow features and
% reflect a narrower pulse.
% FL_rfOpt.processingDeconvolution      - Choice between waterlevel
% deconvolution and iterative time domain deconvolution. Waterlevel is
% slightly faster and always works, but the results are often more "ringy".
% FL_rfOpt.processingWaterlevel         - Low amplitude spectral values to
% fill in to avoid division by 0
% FL_rfOpt.processingMaxIterations      - maximum iterations in the time
% domain deconvolution. This effectively maps to the number of bumps in the
% final receiver function 
% FL_rfOpt.processingMinError           - minimum error allowed in the
% iterative deconvolution
% FL_rfOpt.processingIncidentPhase      - text description of the choice
% for the incident phase. This must match an available phase in taup.
% FL_rfOpt.sampleRate                   - sample rate in seconds per sample
% 
% Processing flow:
% Prepare opt structures for processRFmatlab commands:
%   processENZseis
%   processRFwater/processRFiter
% 
% If the user asks for an array wide source function, then generate it
% for the incident phase
% 
% set each component sac file (fileCell = strsplit(rawTraceFileName{ievent,istation})
% Follow script01a_processPrfns.m

%% Set parameters for processing.
%  note that most of these are dealt with earlier in the processing and are
%  just designed to make sure the seismograms are in the right distance
%  window for the phase arrival
opt.MINZ = 1; % min eqk depth
opt.MAXZ = 700; % max eqk depth
opt.DELMIN = 0; % min eqk distance
opt.DELMAX = 180; % max eqk distance
opt.PHASENM = FL_rfOpt.processingIncidentPhase; % phase to aim for
opt.TBEFORE = FL_rfOpt.processingPrePhaseCut*3; % time before to cut (for initial processing, final cut window is set in rfOpt.T0 and rfOpt.T1)
opt.TAFTER = FL_rfOpt.processingPostPhaseCut*1.8; % time after to cut
if strcmp(FL_rfOpt.processingTaper,'No Taper')
    opt.TAPERW = 0.00;
    opt.taperTypeFlag = 0;
elseif strcmp(FL_rfOpt.processingTaper,' 5% Hann')
    opt.TAPERW = 0.05;
    opt.taperTypeFlag = 1; % for Hann taper
elseif strcmp(FL_rfOpt.processingTaper,'10% Hann')
    opt.TAPERW = 0.10;
    opt.taperTypeFlag = 1;
elseif strcmp(FL_rfOpt.processingTaper,' 5% Hamming')
    opt.TAPERW = 0.05;
    opt.taperTypeFlag = 2;
elseif strcmp(FL_rfOpt.processingTaper,'10% Hamming')
    opt.TAPERW = 0.10;
    opt.taperTypeFlag = 2;
else
    opt.TAPERW = 0.05;
    opt.taperTypeFlag = 1;
    fprintf('Taper choice default: 5%% Hann\n');
    disp('');
end    
%opt.TAPERW = 0.05; % proportion of seis to taper
opt.FLP = FL_rfOpt.processingFilterLp; % low pass
opt.FHP = FL_rfOpt.processingFilterHp; % high pass
opt.FORDER = FL_rfOpt.processingFilterOrder; % order of filter
opt.DTOUT = FL_rfOpt.sampleRate; % desired sample interval
opt.MAGMIN = 0.1; % minimum magnitude to include
opt.MAGMAX = 12.4; % minimum magnitude to include

if strcmp(FL_rfOpt.processingIncidentPhase,'S') || strcmp(FL_rfOpt.processingIncidentPhase,'SKS')
    rfOpt.T0 = -FL_rfOpt.processingPostPhaseCut;
    rfOpt.T1 =  FL_rfOpt.processingPrePhaseCut;
else
    rfOpt.T0 = -FL_rfOpt.processingPrePhaseCut; % time limits for receiver function
    rfOpt.T1 =  FL_rfOpt.processingPostPhaseCut;
end
rfOpt.F0 = FL_rfOpt.processingGaussian; % gaussian width for filtering rfns
%rfOpt.F0 = 1.0; % gaussian width for filtering rfns
rfOpt.WLEVEL = FL_rfOpt.processingWaterlevel; % water level for rfn processing
rfOpt.ITERMAX = FL_rfOpt.processingMaxIterations; %  max number of iterations in deconvolution
rfOpt.MINDERR = FL_rfOpt.processingMinError; % min allowed change in RF fit for deconvolution

%% make a taper for removing some of the signal (SRF)
phaseerr = 2; % number of seconds phase pick may be wrong
taperlen = round(5.0/opt.DTOUT);
taper=fl_hann(2*taperlen);
taper = taper(1:0.5*numel(taper));

% From the top layer of iasp91...
Vp = 5.8;
Vs = 3.36;
% Values used by Pascal Audet:
% Vp = 6.0;
% Vs = 3.6;


%% Call sub to make source function for the event
if strcmp(FL_rfOpt.processingDenominatorMethod,'Array based by event')
    [sourceFunction, sourceHeader, arrivalTimes, ierr] = FL_createSourceFunction(FL_rfOpt, rawTracesFileNames, ievent, nstations, ProjectDirectory);
end

%% Begin main loop to create the receiver functions for each station
for istation = 1:nstations
    if ~isempty(rawTracesFileNames{ievent,istation})
        seisFiles = strsplit(rawTracesFileNames{ievent,istation});
        
        %% Try to read the seismograms from sac files
        [eseis, nseis, zseis, hdr] = read3seis(seisFiles{1}, ...
					   seisFiles{2}, ...
					   seisFiles{3} );
                
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

        % process and rotate
        [zseis, rseis, tseis, hdr, ierr] = processENZseis( eseis, nseis, zseis, ...
						 hdr, opt );
        if ierr == 0

            %% Pack into n x 3 array
            traceTimeInput = linspace(hdr.times.b, hdr.times.e, hdr.trcLen);
            threeCompSeis = zeros(hdr.trcLen,3);
            threeCompSeis(:,1) = tseis;
            threeCompSeis(:,2) = rseis;
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

            %% Rotate to the P-SV-SH reference frame
            [psvshSeis, ~] = rotateSeisTRZtoPSVSH( threeCompSeis, rayp, Vp, Vs);
            pseis = psvshSeis(:,1);
            svseis = psvshSeis(:,2);
            shseis = psvshSeis(:,3);
            % P, SV, SH is out order; T,R,Z is in order

            %% choose the numerator and denominator for the deconvolution
            switch FL_rfOpt.processingNumerator 
                case 'Vertical'
                    numer = zseis;
                case 'P'
                    numer = pseis;
                case 'Radial'
                    numer = rseis;
                case 'SV'
                    numer = svseis;
                case 'Tangential/SH'
                    numer = tseis;
            end
            if strcmp(FL_rfOpt.processingDenominatorMethod,'Array based on event')
                denom = sourceFunction;
            else
                switch FL_rfOpt.processingDenominator
                    case 'Vertical'
                        denom = zseis;
                    case 'P'
                        denom = pseis;
                    case 'Radial'
                        denom = rseis;
                    case 'SV'
                        denom = svseis;
                    case 'Tangential/SH'
                        denom = tseis;
                end
            end


            %% get rid of denominator signal before the S arrival for S/SKS rf
            if strcmp(FL_rfOpt.processingIncidentPhase,'S') || strcmp(FL_rfOpt.processingIncidentPhase,'SKS')
                [t, dt, times, labels] = getTimes( hdr );
                ts = getArrTime( opt.PHASENM, times, labels );
                ntpre = numel( t(t<=(ts-phaseerr)) );
                denom(1:ntpre-taperlen) = 0.0;
                denom(ntpre-taperlen+1:ntpre) = taper.*denom(ntpre-taperlen+1:ntpre)';
            end


            %% Switch between waterlevel and iterative decon
            switch FL_rfOpt.processingDeconvolution
                case 'Iterative'
                    [rftime, rfseis, rfhdr, ierr] = processRFiter(numer, denom, hdr, rfOpt , false);
                    deconType = sprintf('iterative_%03d',rfOpt.ITERMAX);
                    if ierr == 1
                        fprintf('Error, rms array empty for %s\n',strtrim(hdr.station.kstnm))
                        continue
                    end
                case 'Waterlevel'
                    [rftime, rfseis, rfhdr] = processRFwater(numer, denom, hdr, rfOpt , false);
                    deconType = sprintf('waterlevel_%4.5g',rfOpt.WLEVEL);
            end

            %% If SRF flip time and amplitude
            if strcmp(FL_rfOpt.processingIncidentPhase,'S') || strcmp(FL_rfOpt.processingIncidentPhase,'SKS')
                rfseis = -1 * fliplr(rfseis);
                rfhdr.times.b = -FL_rfOpt.processingPrePhaseCut;
                rfhdr.times.e = FL_rfOpt.processingPostPhaseCut;
                fprintf('Flipping (phase %s)\n',FL_rfOpt.processingIncidentPhase)
            end

            %% Write the receiver function trace in raw data
            % Need gaussian in user0
            % Need ray parameter in s/radian in user1
            % Need user8 to default on/off (make it on - 1)
            % user9 gives a fit estimate
            % output file name doesn't really matter except that it ends in
            % .eqr or .eqt and the raw traces end in .t, .r, and .z
            % skm2srad to convert from rayparam in user0 in s/km to s/rad
            %rfhdr.user(1) = P ray param
            %rfhdr.user(2) = PKP ray param
            %rfhdr.user(3) = S ray param
            %rfhdr.user(4).data = SKS ray param
            %rfhdr.user(4).label = BHZ
            %rfhdr.user(5) = network
            %rfhdr.user(6) = gaussian
            %rfhdr.user(7) = RMS
            %rfhdr.user(8) = max iterations
            % 9 and 10 are blank
            rmsfit = 100 - (100 * rfhdr.user(7).data);
            raypRad = skm2srad(rayp);
            rfhdr.user(1).data = rfOpt.F0;
            rfhdr.user(2).data = raypRad;
            rfhdr.user(9).data = 1;
            rfhdr.user(10).data = rmsfit;

            % Prepare the output file name
            eventDir = sprintf('Event_%04d_%03d_%02d_%02d_%02d',hdr.event.nzyear, hdr.event.nzjday, hdr.event.nzhour, hdr.event.nzmin, hdr.event.nzsec);
            outputDir = [ProjectDirectory filesep 'RAWTRACES' filesep eventDir];
            [~, ~, ~] = mkdir(outputDir);
            %BK.GASB..BHZ.Q.2009,313,10:44:55.SAC
            network = strtrim(hdr.station.knetwk);
            station = strtrim(hdr.station.kstnm);
            if primaryOrSecondaryFlag == 1
                switch FL_rfOpt.processingDenominator
                    case 'Vertical'
                        denomName = 'OV';
                    case 'P'
                        denomName = 'OP';
                    case 'Radial'
                        denomName = 'OR';
                    case 'SV'
                        denomName = 'OSV';
                    case 'Tangential/SH'
                        denomName = 'OT';
                end
                switch FL_rfOpt.processingNumerator
                    case 'Vertical'
                        channel = 'EQV';
                    case 'P'
                        channel = 'EQP';
                    case 'Radial'
                        channel = 'EQR';
                    case 'SV'
                        channel = 'EQSV';
                    case 'Tangential/SH'
                        channel = 'EQT';
                end
                if strcmp(FL_rfOpt.processingDenominatorMethod,'Array based by event')
                    deconMethod = 'Array_decon';
                else
                    deconMethod = 'Station_decon';
                end
                sfilename = sprintf('%s.%s.%s.%s.%s.%s.%2.1f.%s',network,station,channel,denomName,deconType,deconMethod,rfOpt.F0,endString);
                fullOutFileName = fullfile(outputDir, sfilename);
                writeSAC(fullOutFileName, rfhdr, rfseis);

                % now write the t, r, z, p, sv components
                sfilename = sprintf('%s.%s.%s.%s.%s.%s.%2.1f.z',network,station,channel,denomName,deconType,deconMethod,rfOpt.F0);
                fullOutFileName = fullfile(outputDir, sfilename);
                writeSAC(fullOutFileName, hdr, zseis);

                sfilename = sprintf('%s.%s.%s.%s.%s.%s.%2.1f.r',network,station,channel,denomName,deconType,deconMethod,rfOpt.F0);
                fullOutFileName = fullfile(outputDir, sfilename);
                writeSAC(fullOutFileName, hdr, rseis);

                sfilename = sprintf('%s.%s.%s.%s.%s.%s.%2.1f.t',network,station,channel,denomName,deconType,deconMethod,rfOpt.F0);
                fullOutFileName = fullfile(outputDir, sfilename);
                writeSAC(fullOutFileName, hdr, tseis);

                sfilename = sprintf('%s.%s.%s.%s.%s.%s.%2.1f.p',network,station,channel,denomName,deconType,deconMethod,rfOpt.F0);
                fullOutFileName = fullfile(outputDir, sfilename);
                writeSAC(fullOutFileName, hdr, pseis);

                sfilename = sprintf('%s.%s.%s.%s.%s.%s.%2.1f.sv',network,station,channel,denomName,deconType,deconMethod,rfOpt.F0);
                fullOutFileName = fullfile(outputDir, sfilename);
                writeSAC(fullOutFileName, hdr, svseis);
            else
                switch otherRFinfo.processingDeconvolution
                    case 'Iterative'
                        deconType = sprintf('iterative_%03d',otherRFinfo.processingMaxIterations);
                    case 'Waterlevel'
                        deconType = sprintf('waterlevel_%4.5g',otherRFinfo.processingWaterlevel);
                end
                switch otherRFinfo.processingDenominator
                    case 'Vertical'
                        denomName = 'OV';
                    case 'P'
                        denomName = 'OP';
                    case 'Radial'
                        denomName = 'OR';
                    case 'SV'
                        denomName = 'OSV';
                    case 'Tangential/SH'
                        denomName = 'OT';
                end
                switch otherRFinfo.processingNumerator
                    case 'Vertical'
                        channel = 'EQV';
                    case 'P'
                        channel = 'EQP';
                    case 'Radial'
                        channel = 'EQR';
                    case 'SV'
                        channel = 'EQSV';
                    case 'Tangential/SH'
                        channel = 'EQT';
                end
                if strcmp(otherRFinfo.processingDenominatorMethod,'Array based by event')
                    deconMethod = 'Array_decon';
                else
                    deconMethod = 'Station_decon';
                end
                sfilename = sprintf('%s.%s.%s.%s.%s.%s.%2.1f.%s',network,station,channel,denomName,deconType,deconMethod,otherRFinfo.processingGaussian,endString);
                fullOutFileName = fullfile(outputDir, sfilename);
                writeSAC(fullOutFileName, rfhdr, rfseis);
            end
        end % if ierr==0 from processENZ seis
    end % if files exist
end % station loop





