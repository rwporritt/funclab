function FL_call_new_RF_computation_gui(h, WaitGui)
%% FL_call_new_RF_computation_gui
%    launches a new gui to set RF parameter computations
%    Requires existing waveform data in the standard
%       Event_YYYY_JJJ_HH_MM_SS 
%    directory format. Waveforms are expected in sac file format with
%    filenames based on some chosen standard format:
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
% h is just the guidata
%
% Note that the code uses the term eqr or radial and eqt or tangential, but
% they really just refer to two different types of reciever functions.
% Funclab projects assume two types of RFs and the usage here is fluid
% enough for the user to adjust want those two types actually are, but for
% simplicity of coding, we'll keep the names of eqr and eqt.
%
%  Created: 05/04/2015. Rob Porritt

MainPos = [0 0 80 25];
ParamTitlePos = [2 MainPos(4)-2 80 1.5];
ParamTextPos1 = [1 0 34 1.75];
ParamOptionPos1 = [36 0 20 1.75];
ParamTextPos2 = [60 0 18 2.25];
ParamOptionPos2 = [72 0 15 1.75];
ParamTextPos3 = [90 0 20 1.75];
ParamOptionPos3 = [113 0 15 1.75];
ProcTitlePos = [80 MainPos(4)-2 50 1.25];
ProcButtonPos = [60 2 18 3];
CloseButtonPos = [90 3 30 3];

% Setting font sizes
TextFontSize = 0.6; % ORIGINAL
EditFontSize = 0.5;
AccentColor = [.6 0 0];

NewRFsFigure = figure('Name','New RFs Params','Units','Characters','Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white','DockControls','off','MenuBar','none','NumberTitle','off');


% Set default values for processing
NewRFsFigure.UserData.EQRDeconType = 'Waterlevel';
NewRFsFigure.UserData.EQTDeconType = 'Waterlevel';
NewRFsFigure.UserData.InputDataDir = '';
NewRFsFigure.UserData.OutputDataDir = '';
NewRFsFigure.UserData.FileNameConvention = 'FuncLabFetch';

% Setting default RF parameters - after script01a_processPrfns.m
NewRFsFigure.UserData.EQRRawParams.PHASENM = 'P';
NewRFsFigure.UserData.EQRRawParams.TBEFORE = 30;
NewRFsFigure.UserData.EQRRawParams.TAFTER = 180;
NewRFsFigure.UserData.EQRRawParams.TAPERW = 0.05; % proportion of seis to taper
NewRFsFigure.UserData.EQRRawParams.taperTypeFlag = 1;
NewRFsFigure.UserData.EQRRawParams.FLP = 2.0; % low pass
NewRFsFigure.UserData.EQRRawParams.FHP = 0.02; % high pass
NewRFsFigure.UserData.EQRRawParams.FORDER = 3; % order of filter
NewRFsFigure.UserData.EQRRawParams.DTOUT = 0.1; % desired sample interval

NewRFsFigure.UserData.EQRRFParams.T0 = -10;
NewRFsFigure.UserData.EQRRFParams.T1 = 90;
NewRFsFigure.UserData.EQRRFParams.F0 = 2.5;
NewRFsFigure.UserData.EQRRFParams.DAMP = 0.01;
NewRFsFigure.UserData.EQRRFParams.WLEVEL = 0.01;
NewRFsFigure.UserData.EQRRFParams.WLNoiseOrDenomFlag = 'Max noise';
NewRFsFigure.UserData.EQRRFParams.ITERMAX = 200;
NewRFsFigure.UserData.EQRRFParams.MINDERR = 1e-5;
NewRFsFigure.UserData.EQRRFParams.Numerator = 'R';
NewRFsFigure.UserData.EQRRFParams.Denominator = 'Z';
NewRFsFigure.UserData.EQRRFParams.Edited = 0;

% Repeat for eqt
NewRFsFigure.UserData.EQTRawParams.PHASENM = 'P';
NewRFsFigure.UserData.EQTRawParams.TBEFORE = 30;
NewRFsFigure.UserData.EQTRawParams.TAFTER = 180;
NewRFsFigure.UserData.EQTRawParams.TAPERW = 0.05; % proportion of seis to taper
NewRFsFigure.UserData.EQTRawParams.taperTypeFlag = 1;
NewRFsFigure.UserData.EQTRawParams.FLP = 2.0; % low pass
NewRFsFigure.UserData.EQTRawParams.FHP = 0.02; % high pass
NewRFsFigure.UserData.EQTRawParams.FORDER = 3; % order of filter
NewRFsFigure.UserData.EQTRawParams.DTOUT = 0.1; % desired sample interval

NewRFsFigure.UserData.EQTRFParams.T0 = -10;
NewRFsFigure.UserData.EQTRFParams.T1 = 90;
NewRFsFigure.UserData.EQTRFParams.F0 = 2.5;
NewRFsFigure.UserData.EQTRFParams.DAMP = 0.01;
NewRFsFigure.UserData.EQTRFParams.WLEVEL = 0.01;
NewRFsFigure.UserData.EQTRFParams.WLNoiseOrDenomFlag = 'Max noise';
NewRFsFigure.UserData.EQTRFParams.ITERMAX = 200;
NewRFsFigure.UserData.EQTRFParams.MINDERR = 1e-5;
NewRFsFigure.UserData.EQTRFParams.Numerator = 'T';
NewRFsFigure.UserData.EQTRFParams.Denominator = 'Z';
NewRFsFigure.UserData.EQTRFParams.Edited = 0;


%Title
uicontrol ('Parent',NewRFsFigure,'Style','text','Units','characters','Tag','title_t','String','New RFs',...
    'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.85,'HorizontalAlignment','left','BackgroundColor','white');

% What we need here:
%   Type of RF (EQR) -> do a popup menu to choose, then have a button to
%   the right to launch a parameter gui
%   Type of RF (EQT) -> do a popup menu to choose, then have a button to
%   the right to launch a parameter gui
%   Base directory containing Event directories with raw sac files inside
%   (button opens a uiget menu and puts output to non-editable text box)
%   New Project output directory (same as choosing where the raw data is)
%   File name convention for sac files (popup menu)
% Lets do this as a far left column text labels, far right action buttons,
% and center for displaying the chosen directories
%   Cancel and next buttons near the bottom

% popup menu for EQR RFs by waterlevel, iterative, or damped and then
% button for parameter setting ui
ParamTextPos1(2) = 20;
ParamOptionPos1(2) = 20;
ParamTextPos2(2) = 20;
uicontrol ('Parent',NewRFsFigure,'Style','text','Units','characters','Tag','eqr_rf_type','String','Primary RF Deconvolution:',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
AvailableDeconvolutions = {'Waterlevel','Iterative','Damped'};
uicontrol ('Parent',NewRFsFigure,'Style','Popupmenu','Units','characters','Tag','eqr_rf_type_pu','String',AvailableDeconvolutions,...
    'Value',1,'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','vec = get(gcf,''UserData''); v = get(gcbo,''Value''); deconType = get(gcbo,''String''); vec.EQRDeconType = deconType{v}; set(gcf,''UserData'',vec);')
uicontrol('Parent',NewRFsFigure,'Style','Pushbutton','Units','characters','Tag','set_eqr_params_button','String','Set Params',...
    'Position',ParamTextPos2,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@set_rf_params,NewRFsFigure, 1});


ParamTextPos1(2) = 17;
ParamOptionPos1(2) = 17;
ParamTextPos2(2) = 17;
uicontrol ('Parent',NewRFsFigure,'Style','text','Units','characters','Tag','eqt_rf_type','String','Secondary RF Deconvolution:',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',NewRFsFigure,'Style','Popupmenu','Units','characters','Tag','eqt_rf_type_pu','String',AvailableDeconvolutions,...
    'Value',1,'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
    'Callback','vec = get(gcf,''UserData''); v = get(gcbo,''Value''); deconType = get(gcbo,''String''); vec.EQTDeconType = deconType{v}; set(gcf,''UserData'',vec);')
uicontrol('Parent',NewRFsFigure,'Style','Pushbutton','Units','characters','Tag','set_eqt_params_button','String','Set Params',...
    'Position',ParamTextPos2,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@set_rf_params,NewRFsFigure, 2});

ParamTextPos1(2) = 14;
ParamOptionPos1(2) = 14;
ParamTextPos2(2) = 14;
uicontrol ('Parent',NewRFsFigure,'Style','text','Units','characters','Tag','input_data_dir','String','Raw waveform dir:',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
inputDataEdit = uicontrol ('Parent',NewRFsFigure,'Style','Edit','Units','characters','Tag','input_data_dir_set_t','String','',...
    'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
    'Callback','vec=get(gcf,''UserData'');inputDir=get(gcbo,''String'');vec.InputDataDir=inputDir;set(gcf,''UserData'',vec);');
uicontrol('Parent',NewRFsFigure,'Style','Pushbutton','Units','characters','Tag','choose_data_dir_pb','String','Data Dir',...
    'Position',ParamTextPos2,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@set_input_data_directory,NewRFsFigure,inputDataEdit});


ParamTextPos1(2) = 11;
ParamOptionPos1(2) = 11;
AvailableSacFileNameConventions = {'FuncLabFetch','mseed2sacV1','mseed2sacV2','RDSEED','SEISAN YYYY-MM-DD-HHMM-DDS.XXX___XXX_SSS__CCC__SAC', 'SEISAN YYYY-MM-DD-HHMM-DDS.SSS_XXX_SSS_BB_C_SAC','YYYY.JJJ.hh.mm.ss.stn.sac.e','YYYY.MM.DD-hh.mm.ss.stn.sac.e','YYYY_MM_DD_hhmm_stnn.sac.e','stn.YYMMDD.hhmmss.e'};
uicontrol ('Parent',NewRFsFigure,'Style','text','Units','characters','Tag','','String','SAC Filenames:',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
uicontrol ('Parent',NewRFsFigure,'Style','Popupmenu','Units','characters','Tag','sac_file_convention_pu','String',AvailableSacFileNameConventions,...
    'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
    'Callback','vec=get(gcf,''UserData'');v=get(gcbo,''Value''); convention=get(gcbo,''String''); vec.FileNameConvention=convention{v};set(gcf,''UserData'',vec);')


ParamTextPos1(2) = 8;
ParamOptionPos1(2) = 8;
ParamTextPos2(2) = 8;
uicontrol ('Parent',NewRFsFigure,'Style','text','Units','characters','Tag','output_data_dir','String','New project dir:',...
    'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
outputDataEdit = uicontrol ('Parent',NewRFsFigure,'Style','Edit','Units','characters','Tag','output_data_dir_set_t','String','',...
    'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
    'Callback','vec=get(gcf,''UserData'');outputDir=get(gcbo,''String'');vec.OutputDataDir=outputDir;set(gcf,''UserData'',vec);');
uicontrol('Parent',NewRFsFigure,'Style','Pushbutton','Units','characters','Tag','new_project_dir_pb','String','Project Dir',...
    'Position',ParamTextPos2,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@set_output_data_directory,NewRFsFigure,outputDataEdit});


% Add buttons for "compute RFs" and "Cancel"
uicontrol('Parent',NewRFsFigure,'Style','Pushbutton','Units','characters','Tag','save_and_do_new_rfs_pb','String','Confirm',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@create_new_rfs_Callback,NewRFsFigure,h,WaitGui});

ProcButtonPos(1) = 40;
uicontrol('Parent',NewRFsFigure,'Style','Pushbutton','Units','characters','Tag','cancel_pb','String','Cancel',...
    'Position',ProcButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
    'Callback',{@cancelnew_rfs_Callback,WaitGui});

end


% The params setting sub-gui will vary for each RF type.
% Note to RWP - include an option for multi-channel cross-correlation option
% to align the RFs

% If confirm, create as a new project. turning off old visibles and
% starting new

% If cancel return to calling state
function cancelnew_rfs_Callback(cbo, eventdata, WaitGui)
    close(WaitGui);    
    close(gcbf);   
end

% Start a ui to get the input data directory
function set_input_data_directory(cbo, eventdata, hdls, editbox)
    datadir = uigetdir('','Please select the input data directory');
    if datadir ~= 0
        hdls.UserData.InputDataDir = datadir;
        set(editbox,'String',datadir);
    else
        disp('Input data directory not set.')
        set(editbox,'String','Not set');
    end
end

% Start a ui to get the output data directory
function set_output_data_directory(cbo, eventdata, hdls, editbox)
    outputdir = uigetdir('','Please select the output data directory');
    if outputdir ~= 0
        hdls.UserData.OutputDataDir = outputdir;
        set(editbox,'String',outputdir);
    else
        disp('Output data directory not set.')
        set(editbox,'String','Not set');
    end
end



% start a new gui to get the parameters for computing the receiver
% functions
% PrimaryOrSecondaryFlag is 1 or 2 to determine the output.
% hdls contains the parameter hdls.UserData.EQRDeconType which determines
% which parameter gui is launched.
function set_rf_params(cbo, eventdata, hdls, PrimaryOrSecondaryFlag)
    
    % Some common parameters we'll need
    % Incident phase
    % Pre-arrival window (time)
    % Post-arrival window (time)
    % Proportion of the seismogram to taper
    % Taper type (Hann vs. Hamming)
    % Low pass filter
    % High pass filter
    % Filter order
    % Desired sample rate
    % Time limit before 0 RF
    % Time limit after 0 RF
    % Gaussian pulse width
    % Numerator component
    % Denominator component
    
    % Iterative needs:
    %   max iterations
    % Waterlevel needs
    %   waterlevel
    %   relative to max denominator or relative to max noise PSD
    % Damped needs:
    %   damping
   

    MainPos = [0 0 80 60];
    ParamTitlePos = [2 MainPos(4)-2 80 1.5];
    ParamTextPos1 = [4 0 36 1.75];
    ParamOptionPos1 = [42 0 36 1.75];
    ProcTitlePos = [80 MainPos(4)-2 50 1.25];
    ConfirmButtonPos = [41 3 30 3];
    CloseButtonPos = [9 3 30 3];

    % Setting font sizes
    TextFontSize = 0.6; % ORIGINAL
    EditFontSize = 0.5;
    AccentColor = [.6 0 0];

    ParamsFigure = figure('Name','Set RF Params','Units','Characters','Position',MainPos,'CreateFcn',{@movegui_kce,'center'},'Color','white','DockControls','off','MenuBar','none','NumberTitle','off');
    AvailablePhases = {'P','PKP','S','SKS'};
    TaperOptions = {'0.05', '0.10'};
    TaperTypeOptions = {'None', 'Hann', 'Hamming'};
    FilterOrderOptions = {'1','2','3','4','5','6','7','8','9','10'};
    NumeratorOptions = {'Z','R','T','P','SV'};
    DenominatorOptions = {'Z','R','T','P','SV'};
    WaterLevelOptions = {'Max denominator','Max noise'};

    %Title
    if PrimaryOrSecondaryFlag == 1
        str = sprintf('Primary RF Params:');
        flag = 1;
        DefaultPhaseID = strmatch(hdls.UserData.EQRRawParams.PHASENM,AvailablePhases,'exact');
        tt = sprintf('%1.2f',hdls.UserData.EQRRawParams.TAPERW);
        DefaultTaperID = strmatch(tt,TaperOptions,'exact');
        tt=sprintf('%1.0f',hdls.UserData.EQRRawParams.FORDER);
        DefaultFilterOrder = strmatch(tt,FilterOrderOptions,'exact');
        DefaultTaperTypeID = hdls.UserData.EQRRawParams.taperTypeFlag+1;
        DefaultPrePhaseCut = sprintf('%3.1f',hdls.UserData.EQRRawParams.TBEFORE);
        DefaultPostPhaseCut = sprintf('%3.1f',hdls.UserData.EQRRawParams.TAFTER);
        DefaultHighPassFilter = sprintf('%3.2f',hdls.UserData.EQRRawParams.FHP);
        DefaultLowPassFilter = sprintf('%3.2f',hdls.UserData.EQRRawParams.FLP);
        DefaultDT = sprintf('%3.1f',hdls.UserData.EQRRawParams.DTOUT);
        DefaultMinRFTime = sprintf('%3.1f',hdls.UserData.EQRRFParams.T0);
        DefaultMaxRFTime = sprintf('%3.1f',hdls.UserData.EQRRFParams.T1);
        DefaultGaussian = sprintf('%3.1f',hdls.UserData.EQRRFParams.F0);
        DefaultNumerator = strmatch(hdls.UserData.EQRRFParams.Numerator,NumeratorOptions,'exact');
        DefaultDenominator = strmatch(hdls.UserData.EQRRFParams.Denominator,DenominatorOptions,'exact');
        DefaultWaterLevelOption = strmatch(hdls.UserData.EQRRFParams.WLNoiseOrDenomFlag,WaterLevelOptions,'exact');
        DefaultWaterLevelPercentage = sprintf('%3.2f',hdls.UserData.EQRRFParams.WLEVEL*100);
        DefaultIterations = sprintf('%3.0f',hdls.UserData.EQRRFParams.ITERMAX);
        DefaultMINDERR = sprintf('%3.5f',hdls.UserData.EQRRFParams.MINDERR);
        DefaultDamping = sprintf('%3.3f',hdls.UserData.EQRRFParams.DAMP);
    else
        str = sprintf('Secondary RF Params:');
        flag = 2;
        DefaultPhaseID = strmatch(hdls.UserData.EQTRawParams.PHASENM,AvailablePhases,'exact');
        tt = sprintf('%1.2f',hdls.UserData.EQTRawParams.TAPERW);
        DefaultTaperID = strmatch(tt,TaperOptions,'exact');
        tt=sprintf('%1.0f',hdls.UserData.EQTRawParams.FORDER);
        DefaultFilterOrder = strmatch(tt,FilterOrderOptions,'exact');
        DefaultTaperTypeID = hdls.UserData.EQTRawParams.taperTypeFlag+1;
        DefaultPrePhaseCut = sprintf('%3.1f',hdls.UserData.EQTRawParams.TBEFORE);
        DefaultPostPhaseCut = sprintf('%3.1f',hdls.UserData.EQTRawParams.TAFTER);
        DefaultHighPassFilter = sprintf('%3.2f',hdls.UserData.EQTRawParams.FHP);
        DefaultLowPassFilter = sprintf('%3.2f',hdls.UserData.EQTRawParams.FLP);
        DefaultDT = sprintf('%3.1f',hdls.UserData.EQTRawParams.DTOUT);
        DefaultMinRFTime = sprintf('%3.1f',hdls.UserData.EQTRFParams.T0);
        DefaultMaxRFTime = sprintf('%3.1f',hdls.UserData.EQTRFParams.T1);
        DefaultGaussian = sprintf('%3.1f',hdls.UserData.EQTRFParams.F0);
        DefaultNumerator = strmatch(hdls.UserData.EQTRFParams.Numerator,NumeratorOptions,'exact');
        DefaultDenominator = strmatch(hdls.UserData.EQTRFParams.Denominator,DenominatorOptions,'exact');
        DefaultWaterLevelOption = strmatch(hdls.UserData.EQTRFParams.WLNoiseOrDenomFlag,WaterLevelOptions,'exact');
        DefaultWaterLevelPercentage = sprintf('%3.2f',hdls.UserData.EQTRFParams.WLEVEL*100);
        DefaultIterations = sprintf('%3.0f',hdls.UserData.EQTRFParams.ITERMAX);
        DefaultMINDERR = sprintf('%3.5f',hdls.UserData.EQTRFParams.MINDERR);
        DefaultDamping = sprintf('%3.3f',hdls.UserData.EQTRFParams.DAMP);
    end
        
    uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','title_t','String',str,...
        'Position',ParamTitlePos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.85,'HorizontalAlignment','left','BackgroundColor','white');

    ParamTextPos1(2) = 54;
    ParamOptionPos1(2) = 54;
    uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','incident_phase_t','String','Incident Phase:',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',ParamsFigure,'Style','Popupmenu','Units','characters','Tag','incident_phase_pu','String',AvailablePhases,...
        'Value',DefaultPhaseID,'Position',ParamOptionPos1,'BackgroundColor',[1 1 1],'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','Enable','on',...
        'Callback',{@set_primary_eqr_incident_phase,hdls,flag})

    ParamTextPos1(2) = 51;
    ParamOptionPos1(2) = 51;
    uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','prephase_cut_text','String','Pre-phase cut (sec):',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',ParamsFigure,'Style','Edit','Units','characters','Tag','prephase_cut_edit','String',DefaultPrePhaseCut,...
        'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
        'Callback',{@set_primary_eqr_pre_phase_cut,hdls,flag});

    ParamTextPos1(2) = 48;
    ParamOptionPos1(2) = 48;
    uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','postphase_cut_text','String','Post-phase cut (sec):',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',ParamsFigure,'Style','Edit','Units','characters','Tag','postphase_cut_edit','String',DefaultPostPhaseCut,...
        'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
        'Callback',{@set_primary_eqr_post_phase_cut,hdls,flag});

    ParamTextPos1(2) = 45;
    ParamOptionPos1(2) = 45;
    uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','taper_length_t','String','Proportion to taper:',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',ParamsFigure,'Style','Popup','Units','characters','Tag','taper_length_pu','String',TaperOptions,'Value',DefaultTaperID,...
        'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
        'Callback',{@set_primary_eqr_taper_length,hdls,flag});

    ParamTextPos1(2) = 42;
    ParamOptionPos1(2) = 42;
    uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','taper_type_t','String','Taper type:',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',ParamsFigure,'Style','Popup','Units','characters','Tag','taper_type_pu','String',TaperTypeOptions,'Value',DefaultTaperTypeID,...
        'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
        'Callback',{@set_primary_eqr_taper_type,hdls,flag});

    ParamTextPos1(2) = 39;
    ParamOptionPos1(2) = 39;
    uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','low_pass_filter_text','String','Low pass filter (Hz):',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',ParamsFigure,'Style','Edit','Units','characters','Tag','low_pass_filter_edit','String',DefaultLowPassFilter,...
        'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
        'Callback',{@set_primary_eqr_low_pass_filter,hdls,flag});

    ParamTextPos1(2) = 36;
    ParamOptionPos1(2) = 36;
    uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','high_pass_filter_text','String','High pass filter (Hz):',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',ParamsFigure,'Style','Edit','Units','characters','Tag','high_pass_filter_edit','String',DefaultHighPassFilter,...
        'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
        'Callback',{@set_primary_eqr_high_pass_filter,hdls,flag});

    ParamTextPos1(2) = 33;
    ParamOptionPos1(2) = 33;
    uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','filter_order_t','String','Filter order:',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',ParamsFigure,'Style','Popup','Units','characters','Tag','filter_order_pu','String',FilterOrderOptions,'Value',DefaultFilterOrder,...
        'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
        'Callback',{@set_primary_eqr_filter_order,hdls,flag});

    ParamTextPos1(2) = 30;
    ParamOptionPos1(2) = 30;
    uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','rf_dtout_text','String','RF sample rate (sec):',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',ParamsFigure,'Style','Edit','Units','characters','Tag','rf_dtout_edit','String',DefaultDT,...
        'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
        'Callback',{@set_primary_eqr_rf_delta,hdls,flag});

    ParamTextPos1(2) = 27;
    ParamOptionPos1(2) = 27;
    uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','rf_mintime_text','String','Min time in RF (sec):',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',ParamsFigure,'Style','Edit','Units','characters','Tag','rf_mintime_edit','String',DefaultMinRFTime,...
        'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
        'Callback',{@set_primary_eqr_min_rf_time,hdls,flag});

    ParamTextPos1(2) = 24;
    ParamOptionPos1(2) = 24;
    uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','rf_maxtime_text','String','Max time in RF (sec):',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',ParamsFigure,'Style','Edit','Units','characters','Tag','rf_maxtime_edit','String',DefaultMaxRFTime,...
        'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
        'Callback',{@set_primary_eqr_max_rf_time,hdls,flag});
    
    ParamTextPos1(2) = 21;
    ParamOptionPos1(2) = 21;
    uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','rf_gaussian_text','String','Gaussian width:',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',ParamsFigure,'Style','Edit','Units','characters','Tag','rf_guassian_edit','String',DefaultGaussian,...
        'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
        'Callback',{@set_primary_eqr_gaussian,hdls,flag});
    
    ParamTextPos1(2) = 18;
    ParamOptionPos1(2) = 18;
    uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','numerator_t','String','Numerator:',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',ParamsFigure,'Style','Popup','Units','characters','Tag','numerator_pu','String',NumeratorOptions,'Value',DefaultNumerator,...
        'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
        'Callback',{@set_primary_eqr_numerator,hdls,flag});

    ParamTextPos1(2) = 15;
    ParamOptionPos1(2) = 15;
    uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','denominator_t','String','Denominator:',...
        'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
    uicontrol ('Parent',ParamsFigure,'Style','Popup','Units','characters','Tag','denominator_pu','String',DenominatorOptions,'Value',DefaultDenominator,...
        'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
        'Callback',{@set_primary_eqr_denominator,hdls,flag});
 
    
    %AvailableDeconvolutions = {'Waterlevel','Iterative','Damped'};
    if flag == 1
        DeconType = hdls.UserData.EQRDeconType;
    else
        DeconType = hdls.UserData.EQTDeconType;
    end
    switch DeconType
        case 'Waterlevel'
            ParamTextPos1(2) = 12;
            ParamOptionPos1(2) = 12;
            uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','wl_reference_t','String','Waterlevel Reference:',...
                'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
            uicontrol ('Parent',ParamsFigure,'Style','Popup','Units','characters','Tag','denominator_pu','String',WaterLevelOptions,'Value',DefaultWaterLevelOption,...
                'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
                'Callback',{@set_primary_eqr_water_level_reference,hdls,flag});
            
            ParamTextPos1(2) = 9;
            ParamOptionPos1(2) = 9;
            uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','wl_percentage_t','String','Waterlevel Percentage:',...
                'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
            uicontrol ('Parent',ParamsFigure,'Style','Edit','Units','characters','Tag','wl_percentage_edit','String',DefaultWaterLevelPercentage,...
                'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
                'Callback',{@set_primary_eqr_water_level_percentage,hdls,flag});
            
        case 'Iterative'
            ParamTextPos1(2) = 12;
            ParamOptionPos1(2) = 12;
            uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','max_iterations_t','String','Max Iterations:',...
                'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
            uicontrol ('Parent',ParamsFigure,'Style','Edit','Units','characters','Tag','max_iterations_e','String',DefaultIterations,...
                'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
                'Callback',{@set_primary_eqr_max_iterations,hdls,flag});
            
            ParamTextPos1(2) = 9;
            ParamOptionPos1(2) = 9;
            uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','iterative_minderr_t','String','Min change in RF:',...
                'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
            uicontrol ('Parent',ParamsFigure,'Style','Edit','Units','characters','Tag','iterative_minderr_e','String',DefaultMINDERR,...
                'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
                'Callback',{@set_primary_eqr_min_error_iterative,hdls,flag});
            
        case 'Damped'
            ParamTextPos1(2) = 12;
            ParamOptionPos1(2) = 12;
            uicontrol ('Parent',ParamsFigure,'Style','text','Units','characters','Tag','damping_t','String','Damping:',...
                'Position',ParamTextPos1,'FontUnits','normalized','FontSize',TextFontSize,'HorizontalAlignment','left','BackgroundColor','white');
            uicontrol ('Parent',ParamsFigure,'Style','Edit','Units','characters','Tag','damping_e','String',DefaultDamping,...
                'Position',ParamOptionPos1,'FontUnits','normalized','FontSize',EditFontSize,'HorizontalAlignment','left','BackgroundColor',[1 1 1],...
                'Callback',{@set_primary_eqr_damping,hdls,flag});
    end
    
    
    uicontrol('Parent',ParamsFigure,'Style','Pushbutton','Units','characters','Tag','cancel_pb','String','Clear/Cancel',...
        'Position',CloseButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
        'Callback',{@revert_to_defaults_and_close,hdls,flag});
    
    uicontrol('Parent',ParamsFigure,'Style','Pushbutton','Units','characters','Tag','confirm_pb','String','Confirm',...
        'Position',ConfirmButtonPos,'ForegroundColor',AccentColor,'FontUnits','normalized','FontSize',0.3,'FontWeight','bold',...
        'Callback',{@confirm_and_close,hdls,flag});

    
end

function set_primary_eqr_incident_phase(cbo, eventdata, hdls,flag)
    vec = get(hdls,'UserData');
    v = get(cbo,'Value');
    Phases = get(cbo,'String');
    IncidentPhase = Phases{v};
    if flag == 1
        vec.EQRRawParams.PHASENM = IncidentPhase;
    else
        vec.EQTRawParams.PHASENM = IncidentPhase;
    end
    set(hdls,'UserData',vec);
end

function set_primary_eqr_pre_phase_cut(cbo, eventdata, hdls,flag)
    vec = get(hdls,'UserData');
    PrePhaseCut = str2double(get(cbo,'String'));
    if flag == 1
        vec.EQRRawParams.TBEFORE = PrePhaseCut;
    else
        vec.EQTRawParams.TBEFORE = PrePhaseCut;
    end
    set(hdls,'UserData',vec);
end

function set_primary_eqr_post_phase_cut(cbo, eventdata, hdls,flag)
    vec = get(hdls,'UserData');
    PostPhaseCut = str2double(get(cbo,'String'));
    if flag == 1
        vec.EQRRawParams.TAFTER = PostPhaseCut;
    else
        vec.EQTRawParams.TAFTER = PostPhaseCut;
    end
    set(hdls,'UserData',vec);
end

function set_primary_eqr_taper_length(cbo, eventdata, hdls,flag)
    vec = get(hdls,'UserData');
    v = get(cbo,'Value');
    TaperLength = get(cbo,'String');
    TaperLengthChoice = TaperLength{v};
    if flag == 1
        vec.EQRRawParams.TAPERW = TaperLengthChoice;
    else
        vec.EQTRawParams.TAPERW = TaperLengthChoice;
    end
    set(hdls,'UserData',vec);
end

function set_primary_eqr_taper_type(cbo, eventdata, hdls,flag)
    vec = get(hdls,'UserData');
    v = get(cbo,'Value');
    TaperType = get(cbo,'String');
    TaperTypeChoice = TaperType{v};
    if flag == 1
        vec.EQRRawParams.taperTypeFlag = v-1;
    else
        vec.EQTRawParams.taperTypeFlag = v-1;
    end
    set(hdls,'UserData',vec);
end

function set_primary_eqr_high_pass_filter(cbo, eventdata, hdls,flag)
    vec = get(hdls,'UserData');
    highPassFilter = str2double(get(cbo,'String'));
    if flag == 1
        vec.EQRRawParams.FHP = highPassFilter;
    else
        vec.EQTRawParams.FHP = highPassFilter;
    end
    set(hdls,'UserData',vec);
end

function set_primary_eqr_low_pass_filter(cbo, eventdata, hdls,flag)
    vec = get(hdls,'UserData');
    lowPassFilter = str2double(get(cbo,'String'));
    if flag == 1
        vec.EQRRawParams.FLP = lowPassFilter;
    else
        vec.EQTRawParams.FLP = lowPassFilter;
    end
    set(hdls,'UserData',vec);
end

function set_primary_eqr_filter_order(cbo, eventdata, hdls,flag)
    vec = get(hdls,'UserData');
    v = get(cbo,'Value');
    FilterOrderChoices = get(cbo,'String');
    FilterOrder = FilterOrderChoices{v};
    if flag == 1
        vec.EQRRawParams.FORDER = str2double(FilterOrder);
    else
        vec.EQTRawParams.FORDER = str2double(FilterOrder);
    end
    set(hdls,'UserData',vec);
end

function set_primary_eqr_rf_delta(cbo, eventdata, hdls,flag)
    vec = get(hdls,'UserData');
    dt = str2double(get(cbo,'String'));
    if flag == 1
        vec.EQRRawParams.DTOUT = dt;
    else
        vec.EQTRawParams.DTOUT = dt;
    end
    set(hdls,'UserData',vec);
end


%%%%%%%%%%%%%% change to the RF params
function set_primary_eqr_min_rf_time(cbo, eventdata, hdls,flag)
    vec = get(hdls,'UserData');
    mintime = str2double(get(cbo,'String'));
    if flag == 1
        vec.EQRRFParams.T0 = mintime;
    else
        vec.EQTRFParams.T0 = mintime;
    end
    set(hdls,'UserData',vec);
end

function set_primary_eqr_max_rf_time(cbo, eventdata, hdls,flag)
    vec = get(hdls,'UserData');
    maxtime = str2double(get(cbo,'String'));
    if flag == 1
        vec.EQRRFParams.T1 = maxtime;
    else
        vec.EQTRFParams.T1 = maxtime;
    end
    set(hdls,'UserData',vec);
end

function set_primary_eqr_gaussian(cbo, eventdata, hdls, flag)
    vec = get(hdls,'UserData');
    gaussian = str2double(get(cbo,'String'));
    if flag == 1
        vec.EQRRFParams.F0 = gaussian;
    else
        vec.EQTRFParams.F0 = gaussian;
    end
    set(hdls,'UserData',vec);
end

function set_primary_eqr_numerator(cbo, eventdata, hdls, flag)
    vec = get(hdls,'UserData');
    v = get(cbo,'Value');
    NumeratorChoices = get(cbo,'String');
    Numerator = NumeratorChoices{v};
    if flag == 1
        vec.EQRRFParams.Numerator = Numerator;
    else
        vec.EQTRFParams.Numerator = Numerator;
    end
    set(hdls,'UserData',vec);
end

function set_primary_eqr_denominator(cbo, eventdata, hdls, flag)
    vec = get(hdls,'UserData');
    v = get(cbo,'Value');
    DenominatorChoices = get(cbo,'String');
    Denominator = DenominatorChoices{v};
    if flag == 1
        vec.EQRRFParams.Denominator = Denominator;
    else
        vec.EQTRFParams.Denominator = Denominator;
    end
    set(hdls,'UserData',vec);
end

function set_primary_eqr_water_level_reference(cbo, eventdata, hdls, flag)
    vec = get(hdls,'UserData');
    v = get(cbo,'Value');
    WaterLevelChoices = get(cbo,'String');
    WaterLevel = WaterLevelChoices{v};
    if flag == 1
        vec.EQRRFParams.WLNoiseOrDenomFlag = WaterLevel;
    else
        vec.EQTRFParams.WLNoiseOrDenomFlag = WaterLevel;
    end
    set(hdls,'UserData',vec);
end

function set_primary_eqr_water_level_percentage(cbo, eventdata, hdls, flag)
    vec = get(hdls,'UserData');
    perc = str2double(get(cbo,'String'));
    if flag == 1
        vec.EQRRFParams.WLEVEL = perc/100;
    else
        vec.EQTRFParams.WLEVEL = perc/100;
    end
    set(hdls,'UserData',vec);
end

function set_primary_eqr_max_iterations(cbo, eventdata, hdls, flag)
    vec = get(hdls,'UserData');
    itermax = str2double(get(cbo,'String'));
    if flag == 1
        vec.EQRRFParams.ITERMAX = itermax;
    else
        vec.EQTRFParams.ITERMAX = itermax;
    end
    set(hdls,'UserData',vec);
end

function set_primary_eqr_min_error_iterative(cbo, eventdata, hdls, flag)
    vec = get(hdls,'UserData');
    minderr = str2double(get(cbo,'String'));
    if flag == 1
        vec.EQRRFParams.MINDERR = minderr;
    else
        vec.EQTRFParams.MINDERR = minderr;
    end
    set(hdls,'UserData',vec);
end

function set_primary_eqr_damping(cbo, eventdata, hdls, flag)
    vec = get(hdls,'UserData');
    damping = str2double(get(cbo,'String'));
    if flag == 1
        vec.EQRRFParams.DAMP = damping;
    else
        vec.EQTRFParams.DAMP = damping;
    end
    set(hdls,'UserData',vec);
end

% Don't really need to do much. The above callbacks set the parameters into
% the main figure handles. This just sets an edited flag to 1 and closes
% the figure.
function confirm_and_close(cbo, eventdata, hdls, flag)
    vec = get(hdls,'UserData');
    if flag == 1
        vec.EQRRFParams.Edited = 1;
    else
        vec.EQTRFParams.Edited = 1;
    end
    set(hdls,'UserData',vec);
    close(gcbf)
end

% resets the parameters to defaults and closes the gui
function revert_to_defaults_and_close(cbo, eventdata, hdls, flag, WaitGui)
    vec = get(hdls,'UserData');
    if flag == 1
        % Setting default RF parameters - after script01a_processPrfns.m
        vec.EQRRawParams.PHASENM = 'P';
        vec.EQRRawParams.TBEFORE = 30;
        vec.EQRRawParams.TAFTER = 180;
        vec.EQRRawParams.TAPERW = 0.05; % proportion of seis to taper
        vec.EQRRawParams.taperTypeFlag = 1;
        vec.EQRRawParams.FLP = 2.0; % low pass
        vec.EQRRawParams.FHP = 0.02; % high pass
        vec.EQRRawParams.FORDER = 3; % order of filter
        vec.EQRRawParams.DTOUT = 0.1; % desired sample interval

        vec.EQRRFParams.T0 = -10;
        vec.EQRRFParams.T1 = 90;
        vec.EQRRFParams.F0 = 2.5;
        vec.EQRRFParams.DAMP = 0.01;
        vec.EQRRFParams.WLEVEL = 0.01;
        vec.EQRRFParams.WLNoiseOrDenomFlag = 'Max noise';
        vec.EQRRFParams.ITERMAX = 200;
        vec.EQRRFParams.MINDERR = 1e-5;
        vec.EQRRFParams.Numerator = 'R';
        vec.EQRRFParams.Denominator = 'Z';
        vec.EQRRFParams.Edited = 0;
    else
        vec.EQTRawParams.PHASENM = 'P';
        vec.EQTRawParams.TBEFORE = 30;
        vec.EQTRawParams.TAFTER = 180;
        vec.EQTRawParams.TAPERW = 0.05; % proportion of seis to taper
        vec.EQTRawParams.taperTypeFlag = 1;
        vec.EQTRawParams.FLP = 2.0; % low pass
        vec.EQTRawParams.FHP = 0.02; % high pass
        vec.EQTRawParams.FORDER = 3; % order of filter
        vec.EQTRawParams.DTOUT = 0.1; % desired sample interval

        vec.EQTRFParams.T0 = -10;
        vec.EQTRFParams.T1 = 90;
        vec.EQTRFParams.F0 = 2.5;
        vec.EQTRFParams.DAMP = 0.01;
        vec.EQTRFParams.WLEVEL = 0.01;
        vec.EQTRFParams.WLNoiseOrDenomFlag = 'Max noise';
        vec.EQTRFParams.ITERMAX = 200;
        vec.EQTRFParams.MINDERR = 1e-5;
        vec.EQTRFParams.Numerator = 'T';
        vec.EQTRFParams.Denominator = 'Z';
        vec.EQTRFParams.Edited = 0;
    end

    set(hdls,'UserData',vec);
    close(gcbf)
    close(WaitGui)
end


% Create new RFs
function create_new_rfs_Callback(cbo, eventdata, hdls,h,WaitGui)

    % Get parameters from user
    params = get(hdls,'UserData');
    
    % Another matlab function to do all the computations
    FL_compute_new_rfs(params,h, WaitGui);
        
end





