function FL_compute_new_rfs(params,h,WaitGui)
%% FL_compute_new_rfs(params)
%   Main driver code to compute new receiver functions from ENZ files on
%   disk.
%   Parameters (params) are set in the main calling code:
%   FL_call_new_RF_computation_gui.m
%     Params is a structure containing several variables
%     EQRDeconType: 'Waterlevel', 'Iterative', or 'Damped' 
%     EQTDeconType: 'Waterlevel', 'Iterative', or 'Damped'
%     InputDataDir: A string variable containing a directory in which we expect to find sub-directories labeled:
%       Event_YYYY_JJJ_HH_MM_SS
%       and 3 component sac files as set by FileNameConvention
%     OutputDataDir: A data directory in which to create a new funclab
%       project. The five components (.z, .r, .t, .eqr, and .eqt) will be
%       placed in this Directory/RAWTRACES
%     FileNameConvention: String variable used to define how the files are
%       named within the event directories. Some examples are provided, but
%       users can either rename their data to fit these conventions or add
%       their own.
%     EQRRawParams.  Parameters for the waveforms on the primary RFs
%       PHASENM: String for the incident phase
%       TBEFORE: Seconds before the incident phase to begin cut
%       TAFTER: Seconds after the incident phase to end cut
%       TAPERW: Proportion of the seismogram to taper
%       taperTypeFlag: Switch between no taper (0), Hann taper (1), or
%         Hammig (2)
%       FLP: Low Pass filter (Hz)
%       FHP: High Pass Filter (Hz)
%       FORDER: Filter order
%       DTOUT: Sample rate of receiver function
%     EQTRawParams.  (same as EQRRawParams)
%     EQRRFParams. Parameters for the actual receiver functions
%       T0: Initial time on the receiver functions relative to the direct arrival
%       T1: Final time on the receiver functions
%       F0: Gaussian pulse width
%       DAMP: If EQRDeconType is "Damped", adds this to the RF denominator
%         before deconvolution.
%       WLEVEL: If EQRDeconType is "Waterlevel", sets the minimum
%         denominator to be this much higher than the reference
%       WLNoiseOrDenomFlag: Decides if the waterlevel should be referenced
%         to the peak noise power spectra or the max denominator
%       ITERMAX: Max number of bumps in a iterative deconvolution
%       MINDERR: If the iterative decon RF changes less than this in one
%         iteration, the deconvolution is finished.
%       Numerator: component containing converted phases
%       Denominator: component containing source phase
%       Edited: 0 if taking the default parameters, 1 if not. 
%    EQTRFParams. (same as EQRRFParams)
%
%    h is the guidata for updating the main gui
%
%    File name conventions:
%      mseed2sac1: QT.ANIL.00.HHZ.D.2012,321,18:00:00.SAC
%      mseed2sac2: IU.HRV.00.BH1.M.2011.246.044859.SAC
%      FuncLabFetch: IU.HRV.00.BH1.M.2011.246.04.48.59.SAC
%      RDSEED: 1993.159.23.15.09.7760.IU.KEV..BHN.D.SAC
%      SEISAN: 2003-05-26-0947-20S.HOR___003_HORN__BHZ__SAC
%      YYYY.JJJ.hh.mm.ss.stn.sac.e
%      YYYY.MM.DD-hh.mm.ss.stn.sac.e
%      YYYY_MM_DD_hhmm_stnn.sac.e
%      stn.YYMMDD.hhmmss.e
%   (See Splitlab/Tools/getFileAndEQseconds.m)
%
%
%
%
%  Created 05/05/2015. Rob Porritt
%

%% Error checking
%   Users given free edit boxes for a handful of parameters
%   TBEFORE < TAFTER
%   T0 < T1
%   FHP < FLP
ErrorPosition = [0 0 80 10];
% Setting font sizes
TextFontSize = 0.6; % ORIGINAL
EditFontSize = 0.5;
AccentColor = [.6 0 0];

ParamTextPos1 = [20 7 80 1.75];
ParamOptionPos1 = [25 1 30 4];

% Defaulting to turn RFs on/off based on rms misfit. Higher value means
% less RFs will be turned on by default (-100 to 100)
minrmsfit = 80.0;

if params.EQRRawParams.TBEFORE > params.EQRRawParams.TAFTER
    errordlg = dialog('WindowStyle','Normal','Name','Error Dialog','Units','Characters','Position',ErrorPosition,'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',errordlg,'Style','text','Units','characters','String','Error, EQR TBEFORE > EQR TAFTER',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
    uicontrol('Parent',errordlg,'Style','Pushbutton','Units','Characters','String','Ok','Position',ParamOptionPos1,...
        'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','center','ForegroundColor',AccentColor,'FontWeight','Bold',...
        'Callback','close(gcf)');
    return
end

if params.EQTRawParams.TBEFORE > params.EQTRawParams.TAFTER
    errordlg = dialog('WindowStyle','Normal','Name','Error Dialog','Units','Characters','Position',ErrorPosition,'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',errordlg,'Style','text','Units','characters','String','Error, EQT TBEFORE > EQT TAFTER',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
    uicontrol('Parent',errordlg,'Style','Pushbutton','Units','Characters','String','Ok','Position',ParamOptionPos1,...
        'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','center','ForegroundColor',AccentColor,'FontWeight','Bold',...
        'Callback','close(gcf)');
    return
end

if params.EQRRFParams.T0 > params.EQRRFParams.T1
    errordlg = dialog('WindowStyle','Normal','Name','Error Dialog','Units','Characters','Position',ErrorPosition,'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',errordlg,'Style','text','Units','characters','String','Error, EQR T0 > EQR T1',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
    uicontrol('Parent',errordlg,'Style','Pushbutton','Units','Characters','String','Ok','Position',ParamOptionPos1,...
        'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','center','ForegroundColor',AccentColor,'FontWeight','Bold',...
        'Callback','close(gcf)');
    return
end

if params.EQTRFParams.T0 > params.EQTRFParams.T1
    errordlg = dialog('WindowStyle','Normal','Name','Error Dialog','Units','Characters','Position',ErrorPosition,'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',errordlg,'Style','text','Units','characters','String','Error, EQT T0 > EQT T1',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
    uicontrol('Parent',errordlg,'Style','Pushbutton','Units','Characters','String','Ok','Position',ParamOptionPos1,...
        'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','center','ForegroundColor',AccentColor,'FontWeight','Bold',...
        'Callback','close(gcf)');
    return
end

if params.EQRRawParams.FHP > params.EQRRawParams.FLP
    errordlg = dialog('WindowStyle','Normal','Name','Error Dialog','Units','Characters','Position',ErrorPosition,'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',errordlg,'Style','text','Units','characters','String','Error, EQR FHP > EQR FLP',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
    uicontrol('Parent',errordlg,'Style','Pushbutton','Units','Characters','String','Ok','Position',ParamOptionPos1,...
        'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','center','ForegroundColor',AccentColor,'FontWeight','Bold',...
        'Callback','close(gcf)');
    return
end

if params.EQTRawParams.FHP > params.EQTRawParams.FLP
    errordlg = dialog('WindowStyle','Normal','Name','Error Dialog','Units','Characters','Position',ErrorPosition,'CreateFcn',{@movegui_kce,'center'});
    uicontrol ('Parent',errordlg,'Style','text','Units','characters','String','Error, EQT FHP > EQT FLP',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left');
    uicontrol('Parent',errordlg,'Style','Pushbutton','Units','Characters','String','Ok','Position',ParamOptionPos1,...
        'FontUnits','Normalized','FontSize',EditFontSize,'HorizontalAlignment','center','ForegroundColor',AccentColor,'FontWeight','Bold',...
        'Callback','close(gcf)');
    return
end

% Wait bar
wb=waitbar(0,'Please wait, loading data info.','CreateCancelBtn','setappdata(gcf,''canceling'',1)');
setappdata(wb,'canceling',0);

%% Input data
%    Evaluate directories pointed at
str = [params.InputDataDir, filesep, 'Event_*'];
DataDirs = dir(str);

% Loop through all event directories
% Builds a variable "DataStructure" which contains all the information
% about the files need to read in a common format. After this, the file
% name convention becomes irrelevant.
for idir=1:size(DataDirs,1)
    ThisDir = [params.InputDataDir filesep DataDirs(idir).name filesep];
    DataStructure(idir).InputDir = ThisDir;
    
    % Create the output directory
    OutputEventDir = [params.OutputDataDir filesep 'RAWDATA' filesep DataDirs(idir).name filesep];
    [~, ~, ~] = mkdir(OutputEventDir);
    DataStructure(idir).OutputDir = OutputEventDir;
    DataStructure(idir).EventName = DataDirs(idir).name;
    
    
    % SAC files - switch for convention
    % dir([params.InputDataDir filesep DataDirs(1).name filesep '*.SAC'])
    % AvailableSacFileNameConventions = {'FuncLabFetch','mseed2sacV1','mseed2sacV2','RDSEED','SEISAN','YYYY.JJJ.hh.mm.ss.stn.sac.e','YYYY.MM.DD-hh.mm.ss.stn.sac.e','YYYY_MM_DD_hhmm_stnn.sac.e','stn.YYMMDD.hhmmss.e'};
    switch params.FileNameConvention
        case 'FuncLabFetch'
            % IU.HRV.00.BH1.M.2011.246.04.48.59.SAC
            SACFiles = dir([ThisDir '*SAC']);
            Stations = cell(size(SACFiles,1),1);
            for isf = 1:size(SACFiles,1)
                dots = strfind(SACFiles(isf).name,'.');
                Stations{isf} = SACFiles(isf).name(dots(1)+1:dots(2)-1);
            end
            Stations = unique(Stations);
            DataStructure(idir).Stations = Stations;
            
            for isf = 1:size(Stations,1)
                StationName = Stations{isf};
                EastSacFile = dir([ThisDir '*' StationName '*HE.*.SAC']);
                NorthSacFile = dir([ThisDir '*' StationName '*HN.*.SAC']);
                VerticalSacFile = dir([ThisDir '*' StationName '*HZ.*.SAC']);
                DataStructure(idir).EastFiles(isf).files = cell(length(EastSacFile),1);
                DataStructure(idir).NorthFiles(isf).files = cell(length(NorthSacFile),1);
                
                if isempty(EastSacFile)
                    fprintf('Warning, 0 east sac files found. FL_compute_new_rfs.m assumes horizontal components are named ?HE and ?HN, not ?H1 and ?H2\n');
                end
                
                DataStructure(idir).VerticalFiles(isf).files = cell(length(VerticalSacFile),1);
                for ie = 1:length(EastSacFile)
                    DataStructure(idir).EastFiles(isf).files{ie} = [ThisDir EastSacFile(ie).name];
                end
                for in = 1:length(NorthSacFile)
                    DataStructure(idir).NorthFiles(isf).files{in} = [ThisDir NorthSacFile(in).name];
                end
                for iz = 1:length(VerticalSacFile)
                    DataStructure(idir).VerticalFiles(isf).files{iz} = [ThisDir VerticalSacFile(iz).name];
                end               
            end

        case 'mseed2sacV1'
            % QT.ANIL.00.HHZ.D.2012,321,18:00:00.SAC
            SACFiles = dir([ThisDir '*SAC']);
            Stations = cell(size(SACFiles,1),1);
            for isf = 1:size(SACFiles,1)
                dots = strfind(SACFiles(isf).name,'.');
                Stations{isf} = SACFiles(isf).name(dots(1)+1:dots(2)-1);
            end
            Stations = unique(Stations);
            DataStructure(idir).Stations = Stations;
            
            for isf = 1:size(Stations,1)
                StationName = Stations{isf};
                EastSacFile = dir([ThisDir '*' StationName '*HE.*.SAC']);
                NorthSacFile = dir([ThisDir '*' StationName '*HN.*.SAC']);
                VerticalSacFile = dir([ThisDir '*' StationName '*HZ.*.SAC']);
                
                if isempty(EastSacFile)
                    fprintf('Warning, 0 east sac files found. FL_compute_new_rfs.m assumes horizontal components are named ?HE and ?HN, not ?H1 and ?H2\n');
                end
                
                DataStructure(idir).EastFiles(isf).files = cell(length(EastSacFile),1);
                DataStructure(idir).NorthFiles(isf).files = cell(length(NorthSacFile),1);
                DataStructure(idir).VerticalFiles(isf).files = cell(length(VerticalSacFile),1);
                for ie = 1:length(EastSacFile)
                    DataStructure(idir).EastFiles(isf).files{ie} = [ThisDir EastSacFile(ie).name];
                end
                for in = 1:length(NorthSacFile)
                    DataStructure(idir).NorthFiles(isf).files{in} = [ThisDir NorthSacFile(in).name];
                end
                for iz = 1:length(VerticalSacFile)
                    DataStructure(idir).VerticalFiles(isf).files{iz} = [ThisDir VerticalSacFile(iz).name];
                end               
            end

        case 'mseed2sacV2'
            % IU.HRV.00.BH1.M.2011.246.044859.SAC
            SACFiles = dir([ThisDir '*SAC']);
            Stations = cell(size(SACFiles,1),1);
            for isf = 1:size(SACFiles,1)
                dots = strfind(SACFiles(isf).name,'.');
                Stations{isf} = SACFiles(isf).name(dots(1)+1:dots(2)-1);
            end
            Stations = unique(Stations);
            DataStructure(idir).Stations = Stations;
            
            for isf = 1:size(Stations,1)
                StationName = Stations{isf};
                EastSacFile = dir([ThisDir '*' StationName '*HE.*.SAC']);
                NorthSacFile = dir([ThisDir '*' StationName '*HN.*.SAC']);
                VerticalSacFile = dir([ThisDir '*' StationName '*HZ.*.SAC']);
                
                %if isempty(EastSacFile)
                %    EastSacFile = dir([ThisDir '*' StationName '*H2.*.SAC']);
                %end
                %if isempty(NorthSacFile)
                %    NorthSacFile = dir([ThisDir '*' StationName '*H1.*.SAC']);
                %end
                
                if isempty(EastSacFile)
                    %fprintf('Warning, 0 east sac files found. FL_compute_new_rfs.m assumes horizontal components are named ?HE and ?HN, not ?H1 and ?H2\n');
                end
                
                DataStructure(idir).EastFiles(isf).files = cell(length(EastSacFile),1);
                DataStructure(idir).NorthFiles(isf).files = cell(length(NorthSacFile),1);
                DataStructure(idir).VerticalFiles(isf).files = cell(length(VerticalSacFile),1);
                for ie = 1:length(EastSacFile)
                    DataStructure(idir).EastFiles(isf).files{ie} = [ThisDir EastSacFile(ie).name];
                end
                for in = 1:length(NorthSacFile)
                    DataStructure(idir).NorthFiles(isf).files{in} = [ThisDir NorthSacFile(in).name];
                end
                for iz = 1:length(VerticalSacFile)
                    DataStructure(idir).VerticalFiles(isf).files{iz} = [ThisDir VerticalSacFile(iz).name];
                end               
            end

            
        case 'RDSEED'
            % 1993.159.23.15.09.7760.IU.KEV..BHN.D.SAC
            SACFiles = dir([ThisDir '*SAC']);
            Stations = cell(size(SACFiles,1),1);
            for isf = 1:size(SACFiles,1)
                dots = strfind(SACFiles(isf).name,'.');
                Stations{isf} = SACFiles(isf).name(dots(7)+1:dots(8)-1);
            end
            Stations = unique(Stations);
            DataStructure(idir).Stations = Stations;
            
            for isf = 1:size(Stations,1)
                StationName = Stations{isf};
                EastSacFile = dir([ThisDir '*' StationName '*HE.*.SAC']);
                NorthSacFile = dir([ThisDir '*' StationName '*HN.*.SAC']);
                VerticalSacFile = dir([ThisDir '*' StationName '*HZ.*.SAC']);
                
                if isempty(EastSacFile)
                    fprintf('Warning, 0 east sac files found. FL_compute_new_rfs.m assumes horizontal components are named ?HE and ?HN, not ?H1 and ?H2\n');
                end
                
                DataStructure(idir).EastFiles(isf).files = cell(length(EastSacFile),1);
                DataStructure(idir).NorthFiles(isf).files = cell(length(NorthSacFile),1);
                DataStructure(idir).VerticalFiles(isf).files = cell(length(VerticalSacFile),1);
                for ie = 1:length(EastSacFile)
                    DataStructure(idir).EastFiles(isf).files{ie} = [ThisDir EastSacFile(ie).name];
                end
                for in = 1:length(NorthSacFile)
                    DataStructure(idir).NorthFiles(isf).files{in} = [ThisDir NorthSacFile(in).name];
                end
                for iz = 1:length(VerticalSacFile)
                    DataStructure(idir).VerticalFiles(isf).files{iz} = [ThisDir VerticalSacFile(iz).name];
                end               
            end
            
% RWP's note:
% I've coded up the below to match the available names in SplitLab, but I
% have not fully tested them. I highly suggest reformatting your data to
% one of the file name conventions above.
        case 'SEISAN YYYY-MM-DD-HHMM-DDS.XXX___XXX_SSS__CCC__SAC'
            %  2003-05-26-0947-20S.HOR___003_HORN__BHZ__SAC
            SACFiles = dir([ThisDir '*SAC']);
            Stations = cell(size(SACFiles,1),1);
            for isf = 1:size(SACFiles,1)
                dots = strfind(SACFiles(isf).name,'_');
                Stations{isf} = SACFiles(isf).name(dots(4)+1:dots(5)-1);
            end
            Stations = unique(Stations);
            DataStructure(idir).Stations = Stations;
            
            for isf = 1:size(Stations,1)
                StationName = Stations{isf};
                EastSacFile = dir([ThisDir '*' StationName '*HE_*_SAC']);
                NorthSacFile = dir([ThisDir '*' StationName '*HN_*_SAC']);
                VerticalSacFile = dir([ThisDir '*' StationName '*HZ_*_SAC']);
                
                if isempty(EastSacFile)
                    fprintf('Warning, 0 east sac files found. FL_compute_new_rfs.m assumes horizontal components are named ?HE and ?HN, not ?H1 and ?H2\n');
                end
                
                DataStructure(idir).EastFiles(isf).files = cell(length(EastSacFile),1);
                DataStructure(idir).NorthFiles(isf).files = cell(length(NorthSacFile),1);
                DataStructure(idir).VerticalFiles(isf).files = cell(length(VerticalSacFile),1);
                for ie = 1:length(EastSacFile)
                    DataStructure(idir).EastFiles(isf).files{ie} = [ThisDir EastSacFile(ie).name];
                end
                for in = 1:length(NorthSacFile)
                    DataStructure(idir).NorthFiles(isf).files{in} = [ThisDir NorthSacFile(in).name];
                end
                for iz = 1:length(VerticalSacFile)
                    DataStructure(idir).VerticalFiles(isf).files{iz} = [ThisDir VerticalSacFile(iz).name];
                end               
            end

            case 'SEISAN YYYY-MM-DD-HHMM-DDS.SSS_XXX_SSS_BB_C_SAC'
            %  2011-04-01-1328-45S.NSN_003_BNB_BB_Z_SAC
            SACFiles = dir([ThisDir '*SAC']);
            Stations = cell(size(SACFiles,1),1);
            for isf = 1:size(SACFiles,1)
                dots = strfind(SACFiles(isf).name,'_');
                Stations{isf} = SACFiles(isf).name(dots(2)+1:dots(3)-1);
            end
            Stations = unique(Stations);
            DataStructure(idir).Stations = Stations;
            
            for isf = 1:size(Stations,1)
                StationName = Stations{isf};
                EastSacFile = dir([ThisDir '*' StationName '*E_SAC']);
                NorthSacFile = dir([ThisDir '*' StationName '*N_SAC']);
                VerticalSacFile = dir([ThisDir '*' StationName '*Z_SAC']);
                
                if isempty(EastSacFile)
                    fprintf('Warning, 0 east sac files found. FL_compute_new_rfs.m assumes horizontal components are named ?HE and ?HN, not ?H1 and ?H2\n');
                end
                
                DataStructure(idir).EastFiles(isf).files = cell(length(EastSacFile),1);
                DataStructure(idir).NorthFiles(isf).files = cell(length(NorthSacFile),1);
                DataStructure(idir).VerticalFiles(isf).files = cell(length(VerticalSacFile),1);
                for ie = 1:length(EastSacFile)
                    DataStructure(idir).EastFiles(isf).files{ie} = [ThisDir EastSacFile(ie).name];
                end
                for in = 1:length(NorthSacFile)
                    DataStructure(idir).NorthFiles(isf).files{in} = [ThisDir NorthSacFile(in).name];
                end
                for iz = 1:length(VerticalSacFile)
                    DataStructure(idir).VerticalFiles(isf).files{iz} = [ThisDir VerticalSacFile(iz).name];
                end               
            end

            
        case 'YYYY.JJJ.hh.mm.ss.stn.sac.e'
            SACFiles = dir([ThisDir '*.sac.*']);
            Stations = cell(size(SACFiles,1),1);
            for isf = 1:size(SACFiles,1)
                dots = strfind(SACFiles(isf).name,'.');
                Stations{isf} = SACFiles(isf).name(dots(5)+1:dots(6)-1);
            end
            Stations = unique(Stations);
            DataStructure(idir).Stations = Stations;
            
            for isf = 1:size(Stations,1)
                StationName = Stations{isf};
                EastSacFile = dir([ThisDir '*' StationName '.sac.e']);
                NorthSacFile = dir([ThisDir '*' StationName '.sac.n']);
                VerticalSacFile = dir([ThisDir '*' StationName '.sac.z']);
                
                if isempty(EastSacFile)
                    fprintf('Warning, 0 east sac files found. FL_compute_new_rfs.m assumes horizontal components are named .e and .n, not .1 and .2\n');
                end
                
                DataStructure(idir).EastFiles(isf).files = cell(length(EastSacFile),1);
                DataStructure(idir).NorthFiles(isf).files = cell(length(NorthSacFile),1);
                DataStructure(idir).VerticalFiles(isf).files = cell(length(VerticalSacFile),1);
                for ie = 1:length(EastSacFile)
                    DataStructure(idir).EastFiles(isf).files{ie} = [ThisDir EastSacFile(ie).name];
                end
                for in = 1:length(NorthSacFile)
                    DataStructure(idir).NorthFiles(isf).files{in} = [ThisDir NorthSacFile(in).name];
                end
                for iz = 1:length(VerticalSacFile)
                    DataStructure(idir).VerticalFiles(isf).files{iz} = [ThisDir VerticalSacFile(iz).name];
                end               
            end
            
        case 'YYYY.MM.DD-hh.mm.ss.stn.sac.e'
            SACFiles = dir([ThisDir '*.sac.*']);
            Stations = cell(size(SACFiles,1),1);
            for isf = 1:size(SACFiles,1)
                dots = strfind(SACFiles(isf).name,'.');
                Stations{isf} = SACFiles(isf).name(dots(5)+1:dots(6)-1);
            end
            Stations = unique(Stations);
            DataStructure(idir).Stations = Stations;
            
            for isf = 1:size(Stations,1)
                StationName = Stations{isf};
                EastSacFile = dir([ThisDir '*' StationName '.sac.e']);
                NorthSacFile = dir([ThisDir '*' StationName '.sac.n']);
                VerticalSacFile = dir([ThisDir '*' StationName '.sac.z']);
                
                if isempty(EastSacFile)
                    fprintf('Warning, 0 east sac files found. FL_compute_new_rfs.m assumes horizontal components are named .e and .n, not .1 and .2\n');
                end
                
                DataStructure(idir).EastFiles(isf).files = cell(length(EastSacFile),1);
                DataStructure(idir).NorthFiles(isf).files = cell(length(NorthSacFile),1);
                DataStructure(idir).VerticalFiles(isf).files = cell(length(VerticalSacFile),1);
                for ie = 1:length(EastSacFile)
                    DataStructure(idir).EastFiles(isf).files{ie} = [ThisDir EastSacFile(ie).name];
                end
                for in = 1:length(NorthSacFile)
                    DataStructure(idir).NorthFiles(isf).files{in} = [ThisDir NorthSacFile(in).name];
                end
                for iz = 1:length(VerticalSacFile)
                    DataStructure(idir).VerticalFiles(isf).files{iz} = [ThisDir VerticalSacFile(iz).name];
                end               
            end
            
        case 'YYYY_MM_DD_hhmm_stnn.sac.e'
            SACFiles = dir([ThisDir '*.sac.*']);
            Stations = cell(size(SACFiles,1),1);
            for isf = 1:size(SACFiles,1)
                dots = strfind(SACFiles(isf).name,'.');
                dashes = strfind(SACFiles(isf).name,'_');
                Stations{isf} = SACFiles(isf).name(dashes(4)+1:dots(1)-1);
            end
            Stations = unique(Stations);
            DataStructure(idir).Stations = Stations;
            
            for isf = 1:size(Stations,1)
                StationName = Stations{isf};
                EastSacFile = dir([ThisDir '*' StationName '.sac.e']);
                NorthSacFile = dir([ThisDir '*' StationName '.sac.n']);
                VerticalSacFile = dir([ThisDir '*' StationName '.sac.z']);
                
                if isempty(EastSacFile)
                    fprintf('Warning, 0 east sac files found. FL_compute_new_rfs.m assumes horizontal components are named .e and .n, not .1 and .2\n');
                end
                
                DataStructure(idir).EastFiles(isf).files = cell(length(EastSacFile),1);
                DataStructure(idir).NorthFiles(isf).files = cell(length(NorthSacFile),1);
                DataStructure(idir).VerticalFiles(isf).files = cell(length(VerticalSacFile),1);
                for ie = 1:length(EastSacFile)
                    DataStructure(idir).EastFiles(isf).files{ie} = [ThisDir EastSacFile(ie).name];
                end
                for in = 1:length(NorthSacFile)
                    DataStructure(idir).NorthFiles(isf).files{in} = [ThisDir NorthSacFile(in).name];
                end
                for iz = 1:length(VerticalSacFile)
                    DataStructure(idir).VerticalFiles(isf).files{iz} = [ThisDir VerticalSacFile(iz).name];
                end               
            end
            
        case 'stn.YYMMDD.hhmmss.e'
            SACFiles = dir([ThisDir '*']);
            Stations = cell(size(SACFiles,1),1);
            for isf = 1:size(SACFiles,1)
                dots = strfind(SACFiles(isf).name,'.');
                Stations{isf} = SACFiles(isf).name(1:dots(1)-1);
            end
            Stations = unique(Stations);
            DataStructure(idir).Stations = Stations;
            
            for isf = 1:size(Stations,1)
                StationName = Stations{isf};
                EastSacFile = dir([ThisDir StationName '*.e']);
                NorthSacFile = dir([ThisDir StationName '*.n']);
                VerticalSacFile = dir([ThisDir StationName '*.z']);
                
                if isempty(EastSacFile)
                    fprintf('Warning, 0 east sac files found. FL_compute_new_rfs.m assumes horizontal components are named .e and .n, not .1 and .2\n');
                end
                
                DataStructure(idir).EastFiles(isf).files = cell(length(EastSacFile),1);
                DataStructure(idir).NorthFiles(isf).files = cell(length(NorthSacFile),1);
                DataStructure(idir).VerticalFiles(isf).files = cell(length(VerticalSacFile),1);
                for ie = 1:length(EastSacFile)
                    DataStructure(idir).EastFiles(isf).files{ie} = [ThisDir EastSacFile(ie).name];
                end
                for in = 1:length(NorthSacFile)
                    DataStructure(idir).NorthFiles(isf).files{in} = [ThisDir NorthSacFile(in).name];
                end
                for iz = 1:length(VerticalSacFile)
                    DataStructure(idir).VerticalFiles(isf).files{iz} = [ThisDir VerticalSacFile(iz).name];
                end               
            end
            
    end
    if getappdata(wb,'canceling')
        delete(wb);
        disp('Canceled during loading')
        return
    end
    
    waitbar(idir/size(DataDirs,1),wb);    
end
delete(wb);

% Set the RF options as in script01a_processPrfns.m and
% FL_processAndWriteRFS.m
%  note that most of these are dealt with earlier in the processing and are
%  just designed to make sure the seismograms are in the right distance
%  window for the phase arrival
optR.MINZ = 1; % min eqk depth
optR.MAXZ = 700; % max eqk depth
optR.DELMIN = 0; % min eqk distance
optR.DELMAX = 180; % max eqk distance
optR.PHASENM = params.EQRRawParams.PHASENM; % phase to aim for
optR.TBEFORE = params.EQRRawParams.TBEFORE; % time before to cut (for initial processing, final cut window is set in rfOpt.T0 and rfOpt.T1)
optR.TAFTER = params.EQRRawParams.TAFTER; % time after to cut
optR.TAPERW = params.EQRRawParams.TAPERW;
optR.taperTypeFlag = params.EQRRawParams.taperTypeFlag;
optR.FLP = params.EQRRawParams.FLP; % low pass
optR.FHP = params.EQRRawParams.FHP; % high pass
optR.FORDER = params.EQRRawParams.FORDER; % order of filter
optR.DTOUT = params.EQRRawParams.DTOUT; % desired sample interval
optR.MAGMIN = 0.1; % minimum magnitude to include
optR.MAGMAX = 12.4; % minimum magnitude to include

rfOptR.T0 =  params.EQRRFParams.T0;
rfOptR.T1 =  params.EQRRFParams.T1;
rfOptR.F0 = params.EQRRFParams.F0; % gaussian width for filtering rfns
rfOptR.WLEVEL = params.EQRRFParams.WLEVEL; % water level for rfn processing
rfOptR.ITERMAX = params.EQRRFParams.ITERMAX; %  max number of iterations in deconvolution
rfOptR.MINDERR = params.EQRRFParams.MINDERR; % min allowed change in RF fit for deconvolution
rfOptR.DAMP = params.EQRRFParams.DAMP;

% Repeat for tangential
optT.MINZ = 1; % min eqk depth
optT.MAXZ = 700; % max eqk depth
optT.DELMIN = 0; % min eqk distance
optT.DELMAX = 180; % max eqk distance
optT.PHASENM = params.EQTRawParams.PHASENM; % phase to aim for
optT.TBEFORE = params.EQTRawParams.TBEFORE; % time before to cut (for initial processing, final cut window is set in rfOpt.T0 and rfOpt.T1)
optT.TAFTER = params.EQTRawParams.TAFTER; % time after to cut
optT.TAPERW = params.EQTRawParams.TAPERW;
optT.taperTypeFlag = params.EQTRawParams.taperTypeFlag;
optT.FLP = params.EQTRawParams.FLP; % low pass
optT.FHP = params.EQTRawParams.FHP; % high pass
optT.FORDER = params.EQTRawParams.FORDER; % order of filter
optT.DTOUT = params.EQTRawParams.DTOUT; % desired sample interval
optT.MAGMIN = 0.1; % minimum magnitude to include
optT.MAGMAX = 12.4; % minimum magnitude to include

rfOptT.T0 =  params.EQTRFParams.T0;
rfOptT.T1 =  params.EQTRFParams.T1;
rfOptT.F0 = params.EQTRFParams.F0; % gaussian width for filtering rfns
rfOptT.WLEVEL = params.EQTRFParams.WLEVEL; % water level for rfn processing
rfOptT.ITERMAX = params.EQTRFParams.ITERMAX; %  max number of iterations in deconvolution
rfOptT.MINDERR = params.EQTRFParams.MINDERR; % min allowed change in RF fit for deconvolution
rfOptT.DAMP = params.EQTRFParams.DAMP;

%% make a taper for removing some of the signal (SRF)
phaseerr = 2; % number of seconds phase pick may be wrong
taperlenR = round(5.0/optR.DTOUT);
taperR=fl_hann(2*taperlenR);
taperR = taperR(1:0.5*numel(taperR));
taperlenT = round(5.0/optT.DTOUT);
taperT=fl_hann(2*taperlenT);
taperT = taperT(1:0.5*numel(taperT));

% From the top layer of iasp91...
Vp = 5.8;
Vs = 3.36;
% Values used by Pascal Audet:
% Vp = 6.0;
% Vs = 3.6;


% Wait bar for actual RF calculations
%wb=waitbar(0,'Please wait, calculating RFs.','CreateCancelBtn','setappdata(gcf,''canceling'',1)');
%setappdata(wb,'canceling',0);

%% Computes the RFS.
% Read the 3 component sac files
% pre-process them with rmean, rtrend, taper, filter
% rotate into desired RTZ or P-SV-SH
% Cut to time window
% Compute RF
% Write to output directory
for idir=1:size(DataDirs,1)
    outputDir = DataStructure(idir).OutputDir;
    
    % Let the user know the progress
    fprintf('***** Working on %s *****\n', DataStructure(idir).EventName);
    
    for istation=1:length(DataStructure(idir).Stations)
            
        % First run for the EQR
        % Try to read the seismograms from sac files
        %fprintf('%s %s %s\n',DataStructure(idir).EastFiles(istation).files{1}, DataStructure(idir).NorthFiles(istation).files{1}, DataStructure(idir).VerticalFiles(istation).files{1} );
        [eseis, nseis, zseis, hdr] = read3seis(DataStructure(idir).EastFiles(istation).files{1}, ...
                                                DataStructure(idir).NorthFiles(istation).files{1}, ...
                                                DataStructure(idir).VerticalFiles(istation).files{1} );
        
        % check depth units
        hdr.event.evdp = checkDepthUnits( hdr.event.evdp, 'km');

        % Get arrival times with taup
        tt = taupTime('ak135',hdr.event.evdp,optR.PHASENM,'deg',hdr.evsta.gcarc);
        if ~isempty(tt)
            hdr.times.atimes(1).t = tt(1).time;
            hdr.times.atimes(1).label = optR.PHASENM;
            hdr.user(1).data = tt(1).rayParam/6371;
        end
            
        tt = taupTime('ak135',hdr.event.evdp,optT.PHASENM,'deg',hdr.evsta.gcarc);
        if ~isempty(tt)
            hdr.times.atimes(2).t = tt(1).time;
            hdr.times.atimes(2).label = optT.PHASENM;
            hdr.user(2).data = tt(1).rayParam/6371;
        end
        
        % Check if they made it to the header
        skipFlagR = 0;
        [~, ~, atimes, labels] = getTimes( hdr );
        predictedArrivalTimeR = getArrTime( optR.PHASENM, atimes, labels );
        if( isnan( predictedArrivalTimeR ) )
            fprintf('Time of %s arrival not found in header. \n...Skipping\n', ...
                optR.PHASENM);
            % Skip to next
            skipFlagR = 1;
        end
        
        skipFlagT = 0;
        predictedArrivalTimeT = getArrTime( optT.PHASENM, atimes, labels );
        if( isnan( predictedArrivalTimeT ) )
            fprintf('Time of %s arrival not found in header. \n...Skipping\n', ...
                optT.PHASENM);
            % Skip to next
            skipFlagT = 1;
        end

        
        % process and rotate
        if skipFlagR == 0
            [zseisR, rseisR, tseisR, hdrR, ierr] = processENZseis( eseis, nseis, zseis, ...
						 hdr, optR );
            if ierr == 0
                % no error, so continue
                % Pack into n x 3 array
                traceTimeInput = linspace(hdrR.times.b, hdrR.times.e, hdrR.trcLen);
                threeCompSeis = zeros(hdrR.trcLen,3);
                threeCompSeis(:,1) = tseisR;
                threeCompSeis(:,2) = rseisR;
                threeCompSeis(:,3) = zseisR;  
                
                % Set the ray parameter
                rayp = hdrR.user(1).data;
                
                % Rotate to the P-SV-SH reference frame
                [psvshSeis, ~] = rotateSeisTRZtoPSVSH( threeCompSeis, rayp, Vp, Vs);
                pseisR = psvshSeis(:,1);
                svseisR = psvshSeis(:,2);
                shseisR = psvshSeis(:,3);
                
                % choose the numerator and denominator for the deconvolution
                switch params.EQRRFParams.Numerator 
                    case 'Z'
                        numer = zseisR;
                    case 'P'
                        numer = pseisR;
                    case 'R'
                        numer = rseisR;
                    case 'SV'
                        numer = svseisR;
                    case 'T'
                        numer = tseisR;
                end
                switch params.EQRRFParams.Denominator 
                    case 'Z'
                        denom = zseisR;
                    case 'P'
                        denom = pseisR;
                    case 'R'
                        denom = rseisR;
                    case 'SV'
                        denom = svseisR;
                    case 'T'
                        denom = tseisR;
                end
                % get rid of denominator signal before the S arrival for S/SKS rf
                if strcmp(optR.PHASENM,'S') || strcmp(optR.PHASENM,'SKS')
                    [t, dt, times, labels] = getTimes( hdrR );
                    ts = getArrTime( optR.PHASENM, times, labels );
                    ntpre = numel( t(t<=(ts-phaseerr)) );
                    denom(1:ntpre-taperlenR) = 0.0;
                    denom(ntpre-taperlenR+1:ntpre) = taperR.*denom(ntpre-taperlenR+1:ntpre)';
                end
                % Switch between waterlevel, damped, and iterative decon
                switch params.EQRDeconType
                    case 'Iterative'
                        [rftime, rfseis, rfhdr, ierr] = processRFiter(numer, denom, hdrR, rfOptR , false);
                        %deconType = sprintf('iterative_%03d',rfOpt.ITERMAX);
                        if ierr == 1
                            fprintf('Error, rms array empty for %s\n',strtrim(hdrR.station.kstnm))
                            %continue
                        end
                        deconType = 'i';
                    case 'Waterlevel'
                        switch params.EQRRFParams.WLNoiseOrDenomFlag
                            case 'Max denominator'
                                [rftime, rfseis, rfhdr] = processRFwater(numer, denom, hdrR, rfOptR , false);
                            case 'Max noise'
                                [rftime, rfseis, rfhdr] = processRFwaterNoise(numer, denom, hdrR, rfOptR , false);
                        end
                        deconType = 'w';
                        %deconType = sprintf('waterlevel_%4.5g',rfOpt.WLEVEL);
                    case 'Damped'
                        [rftime, rfseis, rfhdr] = processRFdamp(numer, denom, hdrR, rfOptR, false);
                        deconType = 'd';
                        
                end
                % If SRF flip time and amplitude
                if strcmp(optR.PHASENM,'S') || strcmp(optR.PHASENM,'SKS')
                    rfseis = -1 * fliplr(rfseis);
                    rfhdr.times.b = rfOptR.T0;
                    rfhdr.times.e = rfOptR.T1;
                    fprintf('Flipping (phase %s)\n',optR.PHASENM)
                end
                
                % Write the receiver function trace in raw data
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
                rfhdr.user(1).data = rfOptR.F0;
                rfhdr.user(2).data = raypRad;
                if rmsfit > minrmsfit
                    rfhdr.user(9).data = 1;
                else
                    rfhdr.user(9).data = 0;
                end
                if isnan(rfseis(1)) || isinf(rfseis(1))
                    rfhdr.user(9).data = 0;
                end
                rfhdr.user(10).data = rmsfit;
                network = deblank(strtrim(hdrR.station.knetwk));
                station = deblank(strtrim(hdrR.station.kstnm));
                
                % Setting up the sacfile name
                %DataStructure(idir).OutputDir
                %fprintf('%s_%s_%1.1f.%s.',network, station, rfOptR.F0, deconType);
                eqrfilelead = sprintf('%s_%s_%1.1f.%s.',network, station, rfOptR.F0, deconType);
                eqrfilename = sprintf('%seqr',eqrfilelead);
                zfilename = sprintf('%sz',eqrfilelead);
                tfilename = sprintf('%st',eqrfilelead);
                rfilename = sprintf('%sr',eqrfilelead);
                DataStructure(idir).EQRLead(istation).name = eqrfilelead;
                if skipFlagT == 1
                    eqtfilename = sprintf('%seqt',eqrfilelead); % need to write a dead trace if the other RF is missed
                    fullOutFileName = fullfile(outputDir, eqtfilename);
                    writeSAC(fullOutFileName, rfhdr, 0*rfseis);
                    DataStructure(idir).EQTFiles(istation).name = eqtfilename;
                end
                fullOutFileName = fullfile(outputDir, eqrfilename);
                writeSAC(fullOutFileName,rfhdr, rfseis);
                DataStructure(idir).EQRFiles(istation).name = eqrfilename;
                
                if strcmp(params.EQRRFParams.Numerator,'Z') || strcmp(params.EQRRFParams.Denominator,'Z')
                    fullOutFileName = fullfile(outputDir, zfilename);
                    writeSAC(fullOutFileName, hdrR, zseisR);
                else
                    fullOutFileName = fullfile(outputDir, zfilename);
                    writeSAC(fullOutFileName, hdrR, pseisR);
                end
                DataStructure(idir).ZFiles(istation).name = zfilename;
                
                if strcmp(params.EQRRFParams.Numerator,'R') || strcmp(params.EQRRFParams.Denominator,'R')
                    fullOutFileName = fullfile(outputDir, rfilename);
                    writeSAC(fullOutFileName, hdrR, rseisR);
                else
                    fullOutFileName = fullfile(outputDir, rfilename);
                    writeSAC(fullOutFileName, hdrR, svseisR);
                end
                DataStructure(idir).RFiles(istation).name = rfilename;
                
                fullOutFileName = fullfile(outputDir, tfilename);
                writeSAC(fullOutFileName, hdrR, tseisR);
                DataStructure(idir).TFiles(istation).name = tfilename;
                
            end
        end
           
        if skipFlagT == 0
            [zseisT, rseisT, tseisT, hdrT, ierrT] = processENZseis( eseis, nseis, zseis, ...
						 hdr, optT );  
            if ierrT == 0
                traceTimeInput = linspace(hdrT.times.b, hdrT.times.e, hdrT.trcLen);
                threeCompSeis = zeros(hdrT.trcLen,3);
                threeCompSeis(:,1) = tseisT;
                threeCompSeis(:,2) = rseisT;
                threeCompSeis(:,3) = zseisT;  
                
                % set the ray parameter
                rayp = hdrT.user(2).data;
                
                % Rotate to the P-SV-SH reference frame
                [psvshSeis, ~] = rotateSeisTRZtoPSVSH( threeCompSeis, rayp, Vp, Vs);
                pseisT = psvshSeis(:,1);
                svseisT = psvshSeis(:,2);
                shseisT = psvshSeis(:,3);
                          
                % choose the numerator and denominator for the deconvolution
                switch params.EQTRFParams.Numerator 
                    case 'Z'
                        numer = zseisT;
                    case 'P'
                        numer = pseisT;
                    case 'R'
                        numer = rseisT;
                    case 'SV'
                        numer = svseisT;
                    case 'T'
                        numer = tseisT;
                end
                switch params.EQTRFParams.Denominator 
                    case 'Z'
                        denom = zseisT;
                    case 'P'
                        denom = pseisT;
                    case 'R'
                        denom = rseisT;
                    case 'SV'
                        denom = svseisT;
                    case 'T'
                        denom = tseisT;
                end
                % get rid of denominator signal before the S arrival for S/SKS rf
                if strcmp(optT.PHASENM,'S') || strcmp(optT.PHASENM,'SKS')
                    [t, dt, times, labels] = getTimes( hdrT );
                    ts = getArrTime( optT.PHASENM, times, labels );
                    ntpre = numel( t(t<=(ts-phaseerr)) );
                    denom(1:ntpre-taperlenT) = 0.0;
                    denom(ntpre-taperlenT+1:ntpre) = taperT.*denom(ntpre-taperlenT+1:ntpre)';
                end
                % Switch between waterlevel, damped, and iterative decon
                switch params.EQTDeconType
                    case 'Iterative'
                        [rftime, rfseis, rfhdr, ierr] = processRFiter(numer, denom, hdrT, rfOptT , false);
                        %deconType = sprintf('iterative_%03d',rfOpt.ITERMAX);
                        if ierr == 1
                            fprintf('Error, rms array empty for %s\n',strtrim(hdrT.station.kstnm))
                            %continue
                        end
                        if skipFlagR == 1
                            deconType = 'i';
                        end
                    case 'Waterlevel'
                        switch params.EQTRFParams.WLNoiseOrDenomFlag
                            case 'Max denominator'
                                [rftime, rfseis, rfhdr] = processRFwater(numer, denom, hdrT, rfOptT , false);
                            case 'Max noise'
                                [rftime, rfseis, rfhdr] = processRFwaterNoise(numer, denom, hdrT, rfOptT , false);
                        end
                        if skipFlagR == 1
                            deconType = 'w';
                        end
                        %deconType = sprintf('waterlevel_%4.5g',rfOpt.WLEVEL);
                    case 'Damped'
                        [rftime, rfseis, rfhdr] = processRFdamp(numer, denom, hdrT, rfOptT, false);
                        if skipFlagR == 1
                            deconType = 'd';
                        end
                end
                % If SRF flip time and amplitude
                if strcmp(optT.PHASENM,'S') || strcmp(optT.PHASENM,'SKS')
                    rfseis = -1 * fliplr(rfseis);
                    rfhdr.times.b = rfOptT.T0;
                    rfhdr.times.e = rfOptT.T1;
                    fprintf('Flipping (phase %s)\n',optT.PHASENM)
                end
                
                rmsfit = 100 - (100 * rfhdr.user(7).data);
                raypRad = skm2srad(rayp);
                rfhdr.user(1).data = rfOptT.F0;
                rfhdr.user(2).data = raypRad;
                if rmsfit > minrmsfit
                    rfhdr.user(9).data = 1;
                else
                    rfhdr.user(9).data = 0;
                end
                rfhdr.user(10).data = rmsfit;
                network = deblank(strtrim(hdrT.station.knetwk));
                station = deblank(strtrim(hdrT.station.kstnm));
                
                % Setting up the sacfile name
                %DataStructure(idir).OutputDir
                %eqtfilelead = sprintf('%s_%s_%1.1f.%s.',network, station, rfOptT.F0, deconType);
                % Funclab needs 5 components of data with the same lead to
                % the file name. So we need to use the EQR gaussian here.
                eqtfilelead = sprintf('%s_%s_%1.1f.%s.',network, station, rfOptR.F0, deconType);
                eqtfilename = sprintf('%seqt',eqtfilelead);
                zfilename = sprintf('%sz',eqtfilelead);
                tfilename = sprintf('%st',eqtfilelead);
                rfilename = sprintf('%sr',eqtfilelead);
                DataStructure(idir).EQTLead(istation).name = eqtfilelead;
                if skipFlagR == 1
                    eqrfilename = sprintf('%seqr',eqtfilelead); % need to write a dead trace if the other RF is missed
                    fullOutFileName = fullfile(outputDir, eqrfilename);
                    writeSAC(fullOutFileName, rfhdr, 0*rfseis);
                    DataStructure(idir).EQRFiles(istation).name = eqrfilename;
                end
                fullOutFileName = fullfile(outputDir, eqtfilename);
                writeSAC(fullOutFileName,rfhdr, rfseis);
                DataStructure(idir).EQTFiles(istation).name = eqtfilename;
                
                if strcmp(params.EQTRFParams.Numerator,'Z') || strcmp(params.EQTRFParams.Denominator,'Z')
                    fullOutFileName = fullfile(outputDir, zfilename);
                    writeSAC(fullOutFileName, hdrT, zseisT);
                else
                    fullOutFileName = fullfile(outputDir, zfilename);
                    writeSAC(fullOutFileName, hdrT, pseisT);
                end
                DataStructure(idir).ZFiles(istation).name = zfilename;
                
                if strcmp(params.EQTRFParams.Numerator,'R') || strcmp(params.EQTRFParams.Denominator,'R')
                    fullOutFileName = fullfile(outputDir, rfilename);
                    writeSAC(fullOutFileName, hdrT, rseisT);
                else
                    fullOutFileName = fullfile(outputDir, rfilename);
                    writeSAC(fullOutFileName, hdrT, svseisT);
                end
                DataStructure(idir).RFiles(istation).name = rfilename;
                
                fullOutFileName = fullfile(outputDir, tfilename);
                writeSAC(fullOutFileName, hdrT, tseisT);
                DataStructure(idir).TFiles(istation).name = tfilename;
                
            end
        end
    
        %if getappdata(wb,'canceling')
        %    delete(wb);
        %    disp('Canceled during RFs')
        %    return
        %end

    end
        
    %waitbar(idir/size(DataDirs,1),wb);
        
end
%delete(wb);

assignin('base','DataStructure',DataStructure);

close(gcbf)

[RecordMetadataStrings, RecordMetadataDoubles] = fl_add_newly_computed_rfs(params.OutputDataDir, 'Project.mat',DataStructure, h,WaitGui);

return


function [RecordMetadataStrings,RecordMetadataDoubles] = fl_add_newly_computed_rfs(ProjectDirectory,ProjectFile,DataStructure, h,WaitGui)
%FL_ADD_NEWLY_COMPUTED_RFS Create new station tables
%   FL_ADD_NEWLY_COMPUTED_RFS(ProjectDirectory,ProjectFile,DataDirectory) 
%   Loads the project information from the newly computed receiver
%   functions. Creates a new project in the directory pointed to by the
%   user. Based on fl_add_new_data.m

% Author: Rob Porritt
% 05/06/2015

% Now we clear the base to create a new project
evalin('base','clear CurrentIndices CurrentRecords ProjectDirectory ProjectFile RecordMetadataDoubles RecordMetadataStrings Tablemenu');
evalin('base','clear GCCPMetadataStrings GCCPMetadataDoubles CCPMetadataStrings CCPMetadataDoubles TraceEditPreferences FuncLabPreferences CCPV2MetadataStrings HkMetadataStrings');
evalin('base','clear HkMetadataDoubles ThreeDRayInfoFile Datastats');

ProjectDirectory = [ProjectDirectory filesep];

tStart=tic;

% Count the total records
NEvents = size(DataStructure,2);
%NEvents = 1;
count = 0;
for idx=1:NEvents
    count = count + size(DataStructure(idx).Stations,1);
end

% Init the metadata
RecordMetadataStrings = cell(count,3);
RecordMetadataDoubles = NaN .* ones(count,19);
LastID = 0;

% for the init log 
DataDir = cell(length(DataStructure),1);
for idx=1:length(DataStructure)
    DataDir{idx} = DataStructure(idx).EventName; 
end

% Wait bar for making the project
wb=waitbar(0,'Please wait, Creating the new project.','CreateCancelBtn','setappdata(gcf,''canceling'',1)');
setappdata(wb,'canceling',0);


% Load in each file at a time and populate the Event tables
%--------------------------------------------------------------------------
WarningCount = 0;
FoundEvents = NEvents;
for n = 1:NEvents
    %RFs = dir([FullDataDirectory filesep Events{n} filesep '*.eqr']);
    jrf = 0;
    clear RFs
    RFs.name = '';
    RFs(2).name = '';
    for irf=1:length(DataStructure(n).EQRFiles)
        if ~isempty(DataStructure(n).EQRFiles(irf).name)
            jrf = jrf+1;
            RFs(jrf).name = DataStructure(n).EQRFiles(irf).name;
        end
    end
    if isempty(RFs)
        display('No receiver functions for this event.')
        FoundEvents = FoundEvents-1;
        DataDir{n} = 'Removed';
        % 04/30/2011: FIXED ERROR IN SYNTAX AND ADDED ERROR CHECKING TO
        % SCRIPT
        [status, message] = rmdir(DataStructure(n).OutputDir,'s');
        if status==0
            display(message)
            display(['Cannot remove directory ' DataStructure(n).OutputDir])
        else
            display(['Removed directory ' DataStructure(n).OutputDir])
        end
    else
        % Here is where the event origin time is parsed from the event
        % directory file name
        [junk,YYYY,JJJ,HH,MM,SS] = strread(DataStructure(n).EventName,'%s %04.0f %03.0f %02.0f %02.0f %02.0f','delimiter','_');
        EventOriginTime = [num2str(YYYY,'%04.0f ') filesep num2str(JJJ,'%03.0f') filesep...
            num2str(HH,'%02.0f') ':' num2str(MM,'%02.0f') ':' num2str(SS,'%02.0f')];
        RFs = sortrows({RFs.name}');
        for m = 1:length(RFs)
            if ~isempty(RFs{m})
                NewID = LastID + 1;
                sacfile = RFs{m};
                RecordMetadataStrings{NewID,1} = ['RAWDATA' filesep DataStructure(n).EventName filesep sacfile(1:end-3)];
                RecordMetadataStrings{NewID,3} = EventOriginTime;
                RecordMetadataDoubles(NewID,1) = 0;

                % Check the byte-order of the sac file - unnecessary. File's
                % are written natively with writeSAC
                %--------------------------------------------------------------
                %fid = fopen([FullDataDirectory filesep Events{n} filesep sacfile],'r','ieee-be');
    %             fid = fopen([DataStructure(n).OutputDir DataStructure(n).EQRFiles(m).name],'r','ieee-be');
    %             fread(fid,70,'single');
    %             fread(fid,6,'int32');
    %             NVHDR = fread(fid,1,'int32');
    %             fclose(fid);
    %             if (NVHDR == 4 || NVHDR == 5)
    %                 tElapsed=toc(tStart);
    %                 message = strcat('NVHDR = 4 or 5. File: "',sacfile,'" may be from an old version of SAC.  Time elapsed before error = ',tElapsed,' sec.');
    %                 error(message)
    %             elseif NVHDR ~= 6
    %                 endian = 'ieee-le';
    %             elseif NVHDR == 6
    %                 endian = 'ieee-be';
    %             end

                % open sac file and add header information
                %--------------------------------------------------------------
                %fid = fopen([FullDataDirectory filesep Events{n} filesep sacfile],'r',endian);
                fid = fopen([DataStructure(n).OutputDir sacfile],'r');
                filename = [DataStructure(n).OutputDir sacfile];
                TimeDelta = fread(fid,1,'single');
                RecordMetadataDoubles(NewID,3) = TimeDelta;
                fread(fid,4,'single');
                BeginTime = fread(fid,1,'single');
                RecordMetadataDoubles(NewID,5) = BeginTime;
                fread(fid,1,'single');
                fread(fid,24,'single');
                RecordMetadataDoubles(NewID,10) = fread(fid,1,'single'); %StaLat
                RecordMetadataDoubles(NewID,11) = fread(fid,1,'single'); %StaLon
                RecordMetadataDoubles(NewID,12) = fread(fid,1,'single') / 1000; %StaElev (km)
                % Check that station metadata is properly loaded. Send a warning to the command window if missing information
                if RecordMetadataDoubles(NewID,10) < -1000   % Note that the sacnull value is -12345
                    fprintf('Error, station (%s) latitude given: %f \n',sacfile, RecordMetadataDoubles(NewID,10) );
                end
                if RecordMetadataDoubles(NewID,10) < -1000
                    fprintf('Error, station (%s) longitude given: %f \n',sacfile, RecordMetadataDoubles(NewID,11) );
                end
                fread(fid,1,'single');
                RecordMetadataDoubles(NewID,13) = fread(fid,1,'single'); %EvLat
                RecordMetadataDoubles(NewID,14) = fread(fid,1,'single'); %EvLon
                if RecordMetadataDoubles(NewID,10) < -1000   % Note that the sacnull value is -12345
                    fprintf('Error, event (%s) latitude given: %f \n',sacfile, RecordMetadataDoubles(NewID,13) );
                end
                if RecordMetadataDoubles(NewID,10) < -1000
                    fprintf('Error, event (%s) longitude given: %f \n',sacfile, RecordMetadataDoubles(NewID,14) );
                end
                fread(fid,1,'single');
                RecordMetadataDoubles(NewID,15) = fread(fid,1,'single') /1000; %EvDepth (km)
                if RecordMetadataDoubles(NewID,15) < 1   %  Assume very shallow are actually in meters
                    RecordMetadataDoubles(NewID,15) = RecordMetadataDoubles(NewID,15) * 1000;
                end
                if RecordMetadataDoubles(NewID,15) > 1000   % Assumes very deep events are in megameters
                    RecordMetadataDoubles(NewID,15) = RecordMetadataDoubles(NewID,15) / 1000;
                end
                RecordMetadataDoubles(NewID,16) = fread(fid,1,'single'); %EvMag
                RecordMetadataDoubles(NewID,7) = fread(fid,1,'single'); %Gauss - aka user0
                RecordMetadataDoubles(NewID,18) = srad2skm(fread(fid,1,'single')); %RayP - aka user1
                if RecordMetadataDoubles(NewID,18) < 0 || RecordMetadataDoubles(NewID,18) > 1
                    fprintf('Warning, record ray parameter for %s is negative or big (%f)\n',sacfile, RecordMetadataDoubles(NewID,18));
                    fprintf('Computing for assumed direct P via taup');
                    % Check for invalid station or event parameters. If one of
                    % the 5 is not in the sac header, assigns a ray parameter
                    % of 0.001
                    if RecordMetadataDoubles(NewID,10) < -90  ||  RecordMetadataDoubles(NewID,10) > 90  || ...
                       RecordMetadataDoubles(NewID,11) < -180 ||  RecordMetadataDoubles(NewID,11) > 360 || ...
                       RecordMetadataDoubles(NewID,13) < -90  ||  RecordMetadataDoubles(NewID,13) > 90  || ...
                       RecordMetadataDoubles(NewID,14) < -180 ||  RecordMetadataDoubles(NewID,14) > 360 || ...
                       RecordMetadataDoubles(NewID,15) < 0    ||  RecordMetadataDoubles(NewID,15) > 1000

                            tt = taupTime([], RecordMetadataDoubles(NewID,15), 'P','sta',[RecordMetadataDoubles(NewID,10), RecordMetadataDoubles(NewID,11)],'evt',[RecordMetadataDoubles(NewID,13), RecordMetadataDoubles(NewID,14)]);
                            RecordMetadataDoubles(NewID,18) = srad2skm(tt.rayParam);
                    else
                        RecordMetadataDoubles(NewID,18) = 0.001;
                    end

                end
                fread(fid,6,'single');
                PreStatus = fread(fid,1,'single'); %USER8 (Predetermined Status within SAC file)
                if PreStatus == 1 || PreStatus == 0
                    RecordMetadataDoubles(NewID,2) = PreStatus;
                else
                    RecordMetadataDoubles(NewID,2) = 1;
                end
                if RecordMetadataDoubles(NewID,10) == -12345 || RecordMetadataDoubles(NewID,11) == -12345 || RecordMetadataDoubles(NewID,13) == -12345 || RecordMetadataDoubles(NewID,14) == -12345  || RecordMetadataDoubles(NewID,17) == -12345 || RecordMetadataDoubles(NewID,19) == -12345
                    if WarningCount == 0
                        disp('WARNING: At least one record has incorrect Ray Parameter information in the SAC file.  These records will automatically be turned off for future analysis.')
                    end
                    RecordMetadataDoubles(NewID,2) = 0;
                end
                RadFit = fread(fid,1,'single'); %USER9
                if RadFit == -12345
                    RadFit = NaN;
                end
                RecordMetadataDoubles(NewID,8) = RadFit;
                fread(fid,1,'single');
                fread(fid,1,'single');
                RecordMetadataDoubles(NewID,19) = fread(fid,1,'single'); %Baz
                RecordMetadataDoubles(NewID,17) = fread(fid,1,'single'); %DistDeg
                if RecordMetadataDoubles(NewID,19) == -12345 || RecordMetadataDoubles(NewID,17) == -12345
                    [~, azi, xdeg] = distaz(RecordMetadataDoubles(NewID,10), RecordMetadataDoubles(NewID,11), RecordMetadataDoubles(NewID,13), RecordMetadataDoubles(NewID,14));
                    RecordMetadataDoubles(NewID,17) = xdeg;
                    RecordMetadataDoubles(NewID,19) = azi;
                end
                fread(fid,5,'single');
                fread(fid,20,'int32');
                SampleCount = fread(fid,1,'int32');
                RecordMetadataDoubles(NewID,4) = SampleCount;
                fread(fid,30,'int32');

                % read character header variables
                %--------------------------------------------------------------
                StationName = deblank(char(fread(fid,8,'char')'));
                fread(fid,1,'char',151);
                fread(fid,8,'char');
                NetworkName = deblank(char(fread(fid,8,'char')'));

                % close SAC file
                %--------------------------------------------------------------
                fclose(fid);
                Station = [NetworkName '-' StationName];
                RecordMetadataStrings{NewID,2} = Station;

                % Check to make sure this record is NOT in our metadata.  If it
                % IS, then delete the "new" one and skip it.
                % Un-used as this callback only works on a NEW projects
                %--------------------------------------------------------------
    %             OldMetadata = RecordMetadataStrings(1:NewID-1,:);
    %             if ~isempty(intersect(strmatch(EventOriginTime,OldMetadata(:,3),'exact'),strmatch(Station,OldMetadata(:,2),'exact')))
    %                 display(['Record for event ' EventOriginTime ' and station ' Station ' already exists in the metadata.'])
    %                 display('No new record was added.')
    %                 RecordMetadataStrings(NewID,:) = [];
    %                 RecordMetadataDoubles(NewID,:) = [];
    %                 delete([FullDataDirectory filesep Events{n} filesep sacfile])
    %                 sacfile = sacfile(1:end-3);  % here is where its basically a set file name and the end is appended .eqt, .r, .t, or .z
    %                 if exist([FullDataDirectory filesep Events{n} filesep sacfile 'eqt'],'file')
    %                     delete([FullDataDirectory filesep Events{n} filesep sacfile 'eqt'])
    %                 end
    %                 if exist([FullDataDirectory filesep Events{n} filesep sacfile 'r'],'file')
    %                     delete([FullDataDirectory filesep Events{n} filesep sacfile 'r'])
    %                 end
    %                 if exist([FullDataDirectory filesep Events{n} filesep sacfile 't'],'file')
    %                     delete([FullDataDirectory filesep Events{n} filesep sacfile 't'])
    %                 end
    %                 if exist([FullDataDirectory filesep Events{n} filesep sacfile 'z'],'file')
    %                     delete([FullDataDirectory filesep Events{n} filesep sacfile 'z'])
    %                 end
    %                 continue
    %             end

                % read the transverse receiver function for the TransFit (if
                % the transverse receiver function exists)
                %--------------------------------------------------------------
                sacfile(end) = 't';
                if exist([DataStructure(n).OutputDir sacfile],'file')
                    fid = fopen([DataStructure(n).OutputDir sacfile],'r');
                    fread(fid,70,'single');
                    fread(fid,6,'int32');
                    NVHDR = fread(fid,1,'int32');
                    fclose(fid);
                    if (NVHDR == 4 || NVHDR == 5)
                        tElapsed=toc(tStart);
                        message = strcat('NVHDR = 4 or 5. File: "',sacfile,'" may be from an old version of SAC.  Time elapsed before error = ',tElapsed,' sec.');
                        error(message)
                    elseif NVHDR ~= 6
                        endian = 'ieee-le';
                    elseif NVHDR == 6
                        endian = 'ieee-be';
                    end
                    %fid = fopen([FullDataDirectory filesep Events{n} filesep sacfile],filesep,endian);
    %                 fid = fopen([DataStructure(n).OutputDir sacfile],'r',endian);
    %                 fread(fid,49,'single');
    %                 TransFit = fread(fid,1,'single'); %USER9
    %                 if TransFit == -12345
    %                     TransFit = NaN;
    %                 end
    %                 fclose(fid);
                    [head1, head2, head3] = sac([DataStructure(n).OutputDir sacfile]);
                    hdr = sachdr(head1, head2, head3);
                    TransFit = hdr.user(10).data;
                else
                    TransFit = NaN;
                end
                RecordMetadataDoubles(NewID,9) = TransFit;

                % Calculate the end time from the delta, number of points, and
                % the begin time.
                %--------------------------------------------------------------
                RecordMetadataDoubles(NewID,6) = (TimeDelta * SampleCount) + BeginTime - TimeDelta;

                LastID = NewID;
            end
        end
        Files = dir(DataStructure(n).OutputDir);
        Files = Files(cat(1,Files.isdir)==0);
        if isempty(Files)
            rmdir(DataStructure(n).OutputDir)
        end
    end
    waitbar(n/NEvents,wb); % Be careful with how frequent waitbar updates...
    if getappdata(wb,'canceling')
        delete(wb);
        disp('Canceled while making project')
        return
    end
end

delete(wb);

% Clear out empties from the metadata
tmpStrings=RecordMetadataStrings;
tmpDoubles=RecordMetadataDoubles;
clear RecordMetadataStrings RecordMetadataDoubles
count = 0;
for idx=1:size(tmpDoubles,1)
    if ~isempty(tmpStrings{idx,1})
        count = count + 1;
    end
end
RecordMetadataStrings = cell(count,3);
RecordMetadataDoubles = NaN .* ones(count,19);
for idx=1:count
    RecordMetadataStrings{idx,1} = tmpStrings{idx,1};
    RecordMetadataStrings{idx,2} = tmpStrings{idx,2};
    RecordMetadataStrings{idx,3} = tmpStrings{idx,3};
    RecordMetadataDoubles(idx,:) = tmpDoubles(idx,:);
end


% Forcing it to make a new project
% if exist([ProjectDirectory ProjectFile],'file')
%     save([ProjectDirectory ProjectFile],'RecordMetadataStrings','RecordMetadataDoubles','-append')
% else
% end
assignin('base','RecordMetadataStrings',RecordMetadataStrings);
assignin('base','RecordMetadataDoubles',RecordMetadataDoubles);
assignin('base','ProjectDirectory',ProjectDirectory);
assignin('base','ProjectFile',ProjectFile)
save([ProjectDirectory ProjectFile],'RecordMetadataStrings','RecordMetadataDoubles')
FuncLabPreferences = fl_default_prefs(RecordMetadataDoubles);
assignin('base','FuncLabPreferences',FuncLabPreferences);

te_default_prefs;
assignin('base','TraceEditPreferences',TraceEditPreferences);

Tablemenu = {'Station Tables','RecordMetadata',2,3,'Stations: ','Records (Listed by Event)','Events: ','fl_record_fields','string';
    'Event Tables','RecordMetadata',3,2,'Events: ','Records (Listed by Station)','Stations: ','fl_record_fields','string'};
assignin('base','Tablemenu',Tablemenu);

save([ProjectDirectory ProjectFile],'TraceEditPreferences','FuncLabPreferences','Tablemenu','-append')

SetManagementCell = cell(1,6);
SetManagementCell{1,1} = 1:size(RecordMetadataDoubles,1);
SetManagementCell{1,2} = RecordMetadataStrings;
SetManagementCell{1,3} = RecordMetadataDoubles;
SetManagementCell{1,4} = Tablemenu;
SetManagementCell{1,5} = 'Base';
SetManagementCell{1,6} = [0.6 0 0];
assignin('base','SetManagementCell',SetManagementCell);
save([ProjectDirectory 'Project.mat'],'SetManagementCell','-append');
assignin('base','CurrentSubsetIndex',1);

fl_init_logfile_new_rf([ProjectDirectory 'Logfile.txt'], DataDir)
fl_datainfo(ProjectDirectory,ProjectFile,RecordMetadataStrings,RecordMetadataDoubles)

fl_turn_on_main_gui(h,WaitGui);

