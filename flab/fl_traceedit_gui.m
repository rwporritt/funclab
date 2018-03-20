function varargout = fl_traceedit_gui(ProjectDirectory,ProjectFile,CurrentRecords,CurrentIndices,Table,H)
%FL_TRACEEDIT_GUI Manual trace editing
%   FL_TRACEEDIT_GUI(ProjectDirectory,ProjectFile,CurrentRecords,
%   CurrentIndices,Table) starts a trace editing GUI which allows the user
%   to "turn on" and "turn off" seismic traces contained in the Ensemble.
%   The "TraceEditPreferences" input specifies the parameters that control
%   aspects of the GUI display.
%
%   NOTES:
%   1. Check boxes above each trace indicates on/off position.  A check
%   means that the trace is turned on.  An empty box means that the trace
%   will NOT be included in future processing.
%   2. The number of traces is set in the preferences.  The slidebar at the
%   bottom allows the user to move this window as they please.
%   3. The function displays each trace at a maximum of 1000 samples.  If
%   it is larger, then the traces are downsampled to meet this standard.
%   This is done to greatly speed up the graphics.
%   4. If the second input is a 2-element vector, this function treats it
%   as time axis limits.  If it is a 1-element vector, this function
%   treats it as the SNR cutoff for automatic trace editing.

%   Author: Kevin C. Eagar
%   Date Created: 01/26/2007
%   Last Updated: 04/30/2011

%   Edit: Rob Porritt
%   May 12th, 2015
%   Added option to sort by user chosen parameter
%   After an edit to change how the gui data is passed, the buttons on the
%   top for select/deselect all and sorting don't work.
%   Bug fixed, Oct 24th, 2017

% Wait message
%--------------------------------------------------------------------------
WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
    'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
uicontrol('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
    'String',['Please wait, waveforms for ' Table ' are being loaded in'],...
    'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);    % 04/30/2011: FIXED THE NAME OF THE TABLE BEING LOADED FOR TRACE EDITING
h = guihandles(WaitGui);
guidata(WaitGui,h);
drawnow;

% H = struct('figure',[],'cmenu',[],'plot',[],'turnon',[],'turnoff',[],'mag',[],'dist',[],'baz',[],'rayp',[],'radfit',[],'transfit',[],'phandle',[],'nhandle',[],'lhandle',[],...
%     'checkhandles',[],'sliderhandle',[],'closebutton',[],'cancelbutton',[],'sortbytext',[],'sortbypopup',[],'reversesorttext',[],'reversesortcheckbox',[],'sortbutton',[],...
%     'deselectAllButton',[],'selectAllButton',[]);

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% Initial Defaults
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
load([ProjectDirectory ProjectFile],'TraceEditPreferences')
switch TraceEditPreferences{1}
    case 'Radial'
        c_tail = 'eqr';
    case 'Transverse'
        c_tail = 'eqt';
    case 'Non-RF Vertical'
        c_tail = 'z';
    case 'Non-RF Radial'
        c_tail = 'r';
    case 'Non-RF Tangential'
        c_tail = 't';
end
YTickIncrement = str2double(TraceEditPreferences{4});
Gain = str2double(TraceEditPreferences{5});
WindowSize = str2double(TraceEditPreferences{6});
TimeWindowMin = str2double(TraceEditPreferences{7});
TimeWindowMax = str2double(TraceEditPreferences{8});
TimeInterpDelta = str2double(TraceEditPreferences{9});
NewTime = colvector(TimeWindowMin:TimeInterpDelta:TimeWindowMax);

% Define 4 colors for filled portion of traces. Also edit in the turnon_Callback, 
% plot_Callback, TraceEdit_callback, sort_trace_edit_callback below
unedittedPositiveColor = [.6 0 0];
unedittedNegativeColor = [.75 .4 .45];
edittedPositiveColor = [1 .7961 0];
edittedNegativeColor = [.7 .5573 .3];

% Originals:
% unedittedPositiveColor = [1 0 0];
% unedittedNegativeColor = [.86 .44 .58];
% edittedPositiveColor = [0 0 1];
% edittedNegativeColor = [.56 .56 .74];

% If you DO NOT want to load in the traces that are already turned "off"
% (this will save you processing time), then set the variable "LoadOff" to
% 0.  Otherwise, keep it set to 1 to load and show all of the traces.
% Showing all the traces is probably wise so that you can determine which
% traces should remain "off" and which should be turned "on".
%--------------------------------------------------------------------------
LoadOff = 1;

% Load the waveforms into MATLAB
%--------------------------------------------------------------------------
switch LoadOff
    case 1
        for n = 1:size(CurrentRecords,1)
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} c_tail]);
            AMPS(:,n) = interp1(TIME,TempAmps,NewTime);
            MAG(n) = CurrentRecords{n,19};
            BAZ(n) = CurrentRecords{n,22};
            RAY(n) = CurrentRecords{n,21};
        end
    case 0
        for n = 1:size(CurrentRecords,1)
%             if CurrentRecords{n,5} == 1
%             if CurrentRecords{n,21} >= 0.05 && CurrentRecords{n,21} <= 0.06
%                 [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} c_tail]);
            if CurrentRecords{n,22} >= 0 && CurrentRecords{n,22} <= 360
                [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} c_tail]);
                AMPS(:,n) = interp1(TIME,TempAmps,NewTime);
            else
                AMPS(:,n) = NaN * zeros(length(NewTime),1);
            end
            MAG(n) = CurrentRecords{n,19};
            BAZ(n) = CurrentRecords{n,22};
            RAY(n) = CurrentRecords{n,21};
        end
    otherwise
        error ('Variable ''LoadOff'' should either be set to 1 or 0.')
end
TIME = NewTime;
close(WaitGui)

NumberOfTraces = size(CurrentRecords,1);

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% GUI initiation
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% H.figure = figure('Name','Receiver Function Trace Editing GUI','NumberTitle','off','Units','pixels','Tag','figure','WindowStyle','normal',...
%     'Position',[0 0 1024 720],'Renderer','painters','BackingStore','off','MenuBar','none','Doublebuffer','on','CreateFcn',{@movegui_kce,'center'});
H.figure = findobj('Tag','TraceEditGui');

% Set the plotting area, x and y labels, and title
%--------------------------------------------------------------------------
set(gca,'Units','normalized','Position',[.1 .15 .85 .75],'Box','on','Color',[1 1 1],...
    'FontName','FixedWidth','FontSize',14,'TickDir','out','TickLength',[.01 .01],'YDir','reverse');
ylabel(gca,'Time (sec)','FontName','FixedWidth','FontSize',14);
xlabel(gca,'Trace Number','FontName','FixedWidth','FontSize',14);
TitleString = sprintf('%s',Table);
title(gca,TitleString,'Units','normalized','Position',[0.5 1.05],'HorizontalAlignment','center','FontWeight','bold');

% Set the y-axis ticks
%--------------------------------------------------------------------------
if rem(TimeWindowMin,YTickIncrement) == 1
    TimeWindowMin = floor(TimeWindowMin/YTickIncrement) * YTickIncrement;
end
if rem(TimeWindowMax,YTickIncrement) == 1
    TimeWindowMax = ceil(TimeWindowMax/YTickIncrement) * YTickIncrement;
end
YTicks = TimeWindowMin:YTickIncrement:TimeWindowMax;
set(gca,'YTick',YTicks);

% Make the "Zero"-line for reference
%--------------------------------------------------------------------------
line([0 NumberOfTraces+1],[0 0],'Color',[.2 .6 .8])

for n = NumberOfTraces:-1:1
    p(n) = CurrentRecords{n,21};
end

Phases = TraceEditPreferences{3};
if ~isempty(Phases)
    Phases = strread(Phases,'%s','delimiter',',');
    
    if isnan(str2double(Phases{1}(1)));

        VModel = TraceEditPreferences{2};
        Datapath = regexprep(which('funclab'),'funclab.m','VELMODELS/');
        Velocity1D = [Datapath VModel];
        VelocityModel = load(Velocity1D,'-ascii');
        Depths = VelocityModel(:,1);
        Vp = VelocityModel(:,2);
        Vs = VelocityModel(:,3);
        Vp = interp1(Depths,Vp,[0:1:Depths(end)])';
        Vs = interp1(Depths,Vs,[0:1:Depths(end)])';
        Depths = [0:1:Depths(end)]';
        dz = [0; diff(Depths)];
        R = 6371 - Depths;
       
        % Determine the name of the phase.  This only handles P primary phases
        % and first-order reverberation phases.
        for n = 1:length(Phases)
            FirstPhase = Phases{n}(1);
            if ~strcmp(FirstPhase,'P')
                disp('Phase name is not in the correct format.')
                disp('Phase moveout curve skipped.')
                break
            end
            k = 1;
            l = 0;
            while 1
                k = k + 1;
                l = l + 1;
                if isnan(str2double(Phases{n}(k)))
                    break
                end
                PhaseDepth(l) = Phases{n}(k);
            end
            if k == 2
                disp('Phase name is not in the correct format.')
                disp('Phase moveout curve skipped.')
                break
            end
            PhaseDepth = str2double(PhaseDepth);
            SecondPhase = Phases{n}(k:end);
            switch SecondPhase
                case 's'
                    for m = 1:length(p)
                        RayP = skm2srad (p(m));
                        temp(:,m) = cumsum((sqrt((R./Vs).^2 - RayP^2) - sqrt((R./Vp).^2 - RayP^2)) .* (dz./R));
                    end
                    if exist('Tps')
                        Tps(end+1,:) = temp(PhaseDepth+1,:);
                        TpsPhase{end+1} = Phases{n};
                    else
                        Tps(1,:) = temp(PhaseDepth+1,:);
                        TpsPhase{1} = Phases{n};
                    end
                    clear temp
                case 'pPs'
                    for m = 1:length(p)
                        RayP = skm2srad (p(m));
                        temp(:,m) = cumsum((sqrt((R./Vs).^2 - RayP^2) + sqrt((R./Vp).^2 - RayP^2)) .* (dz./R));
                    end
                    if exist('Tpp')
                        Tpp(end+1,:) = temp(PhaseDepth+1,:);
                        TppPhase{end+1} = Phases{n};
                    else
                        Tpp(1,:) = temp(PhaseDepth+1,:);
                        TppPhase{1} = Phases{n};
                    end
                    clear temp
                case 'pSs'
                    for m = 1:length(p)
                        RayP = skm2srad (p(m));
                        temp(:,m) = cumsum(sqrt((R./Vs).^2 - RayP^2) .* (2*dz./R));
                    end
                    if exist('Tss')
                        Tss(end+1,:) = temp(PhaseDepth+1,:);
                        TssPhase{end+1} = Phases{n};
                    else
                        Tss(1,:) = temp(PhaseDepth+1,:);
                        TssPhase{1} = Phases{n};
                    end
                    clear temp
                case 'sPs'
                    for m = 1:length(p)
                        RayP = skm2srad (p(m));
                        temp(:,m) = cumsum(sqrt((R./Vs).^2 - RayP^2) .* (2*dz./R));
                    end
                    if exist('Tss')
                        Tss(end+1,:) = temp(PhaseDepth+1,:);
                        TssPhase{end+1} = Phases{n};
                    else
                        Tss(1,:) = temp(PhaseDepth+1,:);
                        TssPhase{1} = Phases{n};
                    end
                    clear temp
                otherwise
                    disp('Phase name is not in the correct format.')
                    disp('Phase moveout curve skipped.')
                    break
            end
            clear temp FirstPhase PhaseDepth SecondPhase
        end
    else
        disp('Phase names are not in the correct format.')
        disp('No phase moveout curves plotted.')
    end

end


% Make the matrices for the normalized traces (Amplitudes), the filled part
% of the wiggle traces (FilledTrace), and the time axis for the wiggle
% traces (TimeAxis).
%--------------------------------------------------------------------------

if length(TraceEditPreferences) < 12
  tmp = cell(1,14);
  for idx=1:11
    tmp{idx} = TraceEditPreferences{idx};
  end
  tmp{12} = 0;
  tmp{13} = 0;
  tmp{14} = 0;
  TraceEditPreferences = tmp;
end

HighPass = str2double(TraceEditPreferences{12});
LowPass = str2double(TraceEditPreferences{13});
if HighPass > LowPass
    fprintf('High pass corner (%f) must be less than low pass corner (%f)\n',HighPass, LowPass);
    tmp = HighPass;
    HighPass = LowPass;
    LowPass = tmp;
end
FiltOrder = round(str2double(TraceEditPreferences{14}));
if HighPass == 0 && LowPass ~= 0
    FiltAmps = lowpassSeis(AMPS, TimeInterpDelta, LowPass,FiltOrder);
elseif LowPass == 0 && HighPass ~= 0
    FiltAmps = highpassSeis(AMPS, TimeInterpDelta, HighPass, FiltOrder);
elseif HighPass ~= 0 && LowPass ~= 0
    FiltAmps = bandpassSeis(AMPS, TimeInterpDelta, HighPass, LowPass, FiltOrder);
else
    FiltAmps = AMPS;
end
AMPS = FiltAmps;


XTicks = 0:NumberOfTraces+1;
XRange = XTicks(end) - XTicks(1);
AmplitudeFactor = XRange / NumberOfTraces;
MaximumAmplitude = max(abs(AMPS));
MaximumAmplitude = repmat(MaximumAmplitude,size(AMPS,1),1);
NormalizedAmplitudes = AMPS ./ MaximumAmplitude;
Amplitudes = NormalizedAmplitudes .* (AmplitudeFactor * Gain);
PositiveIndices = find (Amplitudes > 0);
NegativeIndices = find (Amplitudes < 0);
TempAmps = reshape(Amplitudes,[],1);
Pamps = zeros (size(TempAmps));
Pamps(PositiveIndices) = TempAmps(PositiveIndices);
Namps = zeros (size(TempAmps));
Namps(NegativeIndices) = TempAmps(NegativeIndices);
PFilledTrace = reshape(Pamps,size(Amplitudes));
NFilledTrace = reshape(Namps,size(Amplitudes));
TimeAxis = TIME;
PFilledTrace = [zeros(1,size(PFilledTrace,2)); PFilledTrace; zeros(1,size(PFilledTrace,2))];
NFilledTrace = [zeros(1,size(NFilledTrace,2)); NFilledTrace; zeros(1,size(NFilledTrace,2))];
TimeAxis = [ones(1,size(TimeAxis,2)) .* TimeAxis(1,:);
    TimeAxis;
    ones(1,size(TimeAxis,2)) .* TimeAxis(end,:)];

% Sometime the plots look messed up. As though the patch command is filling
% the wrong side.
% Section below does not actually work in all cases
% Need to avoid traces having amplitudes greater than 1 or less than
% negative 1
% 
% tmp = size(NFilledTrace);
% ntraces = tmp(2);
% ntime = tmp(1);
% for idx=1:ntraces
%     for idy = 1:ntime
%         if NFilledTrace(idy, idx) < -.9
%             NFilledTrace(idy, idx) = -.9;
%         end
%         if PFilledTrace(idy, idx) > .9
%             PFilledTrace(idy, idx) = .9;
%         end
%     end
% end
% idx = find(PFilledTrace > .99);
% idy = find(NFilledTrace < -.99);
% PFilledTrace(idx) = .99;
% NFilledTrace(idy) = -.99;

% Begin plotting each trace in the axes
%--------------------------------------------------------------------------
for n = NumberOfTraces:-1:1
    if CurrentRecords{n,5} == 1
        if CurrentRecords{n,4} == 0
            H.cmenu(n) = uicontextmenu;
            H.plot(n) = uimenu(H.cmenu(n),'Label','Plot Seismograms','Callback',{@plot_Callback});
            H.turnon(n) = uimenu(H.cmenu(n),'Label','Turn ''On"','Callback',{@turnon_Callback});
            H.turnoff(n) = uimenu(H.cmenu(n),'Label','Turn ''Off"','Callback',{@turnoff_Callback});
            H.mag(n) = uimenu(H.cmenu(n),'Label',['Magnitude = ' num2str(CurrentRecords{n,19},'%.2f')],'Separator','on','ForegroundColor',[.6 0 .2]);
            H.dist(n) = uimenu(H.cmenu(n),'Label',['Distance = ' num2str(CurrentRecords{n,20},'%.2f')],'ForegroundColor',[.6 0 .2]);
            H.baz(n) = uimenu(H.cmenu(n),'Label',['Backazimuth = ' num2str(CurrentRecords{n,22},'%.2f')],'ForegroundColor',[.6 0 .2]);
            H.rayp(n) = uimenu(H.cmenu(n),'Label',['Ray Parameter = ' num2str(CurrentRecords{n,21},'%.4f')],'ForegroundColor',[.6 0 .2]);
            H.radfit(n) = uimenu(H.cmenu(n),'Label',['Radial Fit = ' num2str(CurrentRecords{n,11},'%.1f')],'ForegroundColor',[.6 0 .2]);
            H.transfit(n) = uimenu(H.cmenu(n),'Label',['Transverse Fit = ' num2str(CurrentRecords{n,12},'%.1f')],'ForegroundColor',[.6 0 .2]);
            % Attempt to stop filling on the wrong side of the wiggle
            vp = [PFilledTrace(:,n)'+n; TimeAxis'];
            vn = [NFilledTrace(:,n)'+n; TimeAxis'];
            idx = length(vp);
            vvp = vp;
            vvn = vn;
            vvp(1,idx+1) = n;
            vvp(2,idx+1) = max(TimeAxis);
            vvp(1,idx+2) = n;
            vvp(2,idx+2) = min(TimeAxis);
            vvn(1,idx+1) = n;
            vvn(2,idx+1) = max(TimeAxis);
            vvn(1,idx+2) = n;
            vvn(2,idx+2) = min(TimeAxis);
            ff=length(vvp):-1:1;
            H.phandle(n) = patch('Faces',ff,'Vertices',vvp','FaceColor',unedittedPositiveColor,'EdgeColor','none','Tag','phandle');
            H.nhandle(n) = patch('Faces',ff,'Vertices',vvn','FaceColor',unedittedNegativeColor,'EdgeColor','none','Tag','nhandle');
            %H.phandle(n) = patch (PFilledTrace(:,n)' + n,TimeAxis',unedittedPositiveColor,'EdgeColor','none','Tag','phandle');
            %H.nhandle(n) = patch (NFilledTrace(:,n)' + n,TimeAxis',unedittedNegativeColor,'EdgeColor','none','Tag','nhandle');
            H.lhandle(n) = line((Amplitudes(:,n) + n),TIME,'Color',[0 0 0],'LineWidth',1,'Tag','lhandle','UIContextMenu',H.cmenu(n));
        else
            H.cmenu(n) = uicontextmenu;
            H.plot(n) = uimenu(H.cmenu(n),'Label','Plot Seismograms','Callback',{@plot_Callback});
            H.turnon(n) = uimenu(H.cmenu(n),'Label','Turn ''On"','Callback',{@turnon_Callback});
            H.turnoff(n) = uimenu(H.cmenu(n),'Label','Turn ''Off"','Callback',{@turnoff_Callback});
            H.mag(n) = uimenu(H.cmenu(n),'Label',['Magnitude = ' num2str(CurrentRecords{n,19},'%.2f')],'Separator','on','ForegroundColor',[.6 0 .2]);
            H.dist(n) = uimenu(H.cmenu(n),'Label',['Distance = ' num2str(CurrentRecords{n,20},'%.2f')],'ForegroundColor',[.6 0 .2]);
            H.baz(n) = uimenu(H.cmenu(n),'Label',['Backazimuth = ' num2str(CurrentRecords{n,22},'%.2f')],'ForegroundColor',[.6 0 .2]);
            H.rayp(n) = uimenu(H.cmenu(n),'Label',['Ray Parameter = ' num2str(CurrentRecords{n,21},'%.4f')],'ForegroundColor',[.6 0 .2]);
            H.radfit(n) = uimenu(H.cmenu(n),'Label',['Radial Fit = ' num2str(CurrentRecords{n,11},'%.1f')],'ForegroundColor',[.6 0 .2]);
            H.transfit(n) = uimenu(H.cmenu(n),'Label',['Transverse Fit = ' num2str(CurrentRecords{n,12},'%.1f')],'ForegroundColor',[.6 0 .2]);
            vp = [PFilledTrace(:,n)'+n; TimeAxis'];
            vn = [NFilledTrace(:,n)'+n; TimeAxis'];
            idx = length(vp);
            vvp = vp;
            vvn = vn;
            vvp(1,idx+1) = n;
            vvp(2,idx+1) = max(TimeAxis);
            vvp(1,idx+2) = n;
            vvp(2,idx+2) = min(TimeAxis);
            vvn(1,idx+1) = n;
            vvn(2,idx+1) = max(TimeAxis);
            vvn(1,idx+2) = n;
            vvn(2,idx+2) = min(TimeAxis);
            ff=length(vvp):-1:1;
            H.phandle(n) = patch('Faces',ff,'Vertices',vvp','FaceColor',edittedPositiveColor,'EdgeColor','none','Tag','phandle');
            H.nhandle(n) = patch('Faces',ff,'Vertices',vvn','FaceColor',edittedNegativeColor,'EdgeColor','none','Tag','nhandle');
            %H.phandle(n) = patch (PFilledTrace(:,n)' + n,TimeAxis',edittedPositiveColor,'EdgeColor','none','Tag','phandle');
            %H.nhandle(n) = patch (NFilledTrace(:,n)' + n,TimeAxis',edittedNegativeColor,'EdgeColor','none','Tag','nhandle');
            H.lhandle(n) = line((Amplitudes(:,n) + n),TIME,'Color',[0 0 0],'LineWidth',1,'Tag','lhandle','UIContextMenu',H.cmenu(n));
        end
    end
    if CurrentRecords{n,5} == 0
        H.cmenu(n) = uicontextmenu;
        H.plot(n) = uimenu(H.cmenu(n),'Label','Plot Seismograms','Callback',{@plot_Callback});
        H.turnon(n) = uimenu(H.cmenu(n),'Label','Turn ''On"','Callback',{@turnon_Callback});
        H.turnoff(n) = uimenu(H.cmenu(n),'Label','Turn ''Off"','Callback',{@turnoff_Callback});
        H.mag(n) = uimenu(H.cmenu(n),'Label',['Magnitude = ' num2str(CurrentRecords{n,19},'%.2f')],'Separator','on','ForegroundColor',[.6 0 .2]);
        H.dist(n) = uimenu(H.cmenu(n),'Label',['Distance = ' num2str(CurrentRecords{n,20},'%.2f')],'ForegroundColor',[.6 0 .2]);
        H.baz(n) = uimenu(H.cmenu(n),'Label',['Backazimuth = ' num2str(CurrentRecords{n,22},'%.2f')],'ForegroundColor',[.6 0 .2]);
        H.rayp(n) = uimenu(H.cmenu(n),'Label',['Ray Parameter = ' num2str(CurrentRecords{n,21},'%.4f')],'ForegroundColor',[.6 0 .2]);
        H.radfit(n) = uimenu(H.cmenu(n),'Label',['Radial Fit = ' num2str(CurrentRecords{n,11},'%.1f')],'ForegroundColor',[.6 0 .2]);
        H.transfit(n) = uimenu(H.cmenu(n),'Label',['Transverse Fit = ' num2str(CurrentRecords{n,12},'%.1f')],'ForegroundColor',[.6 0 .2]);
        vp = [PFilledTrace(:,n)'+n; TimeAxis'];
        vn = [NFilledTrace(:,n)'+n; TimeAxis'];
        idx = length(vp);
        vvp = vp;
        vvn = vn;
        vvp(1,idx+1) = n;
        vvp(2,idx+1) = max(TimeAxis);
        vvp(1,idx+2) = n;
        vvp(2,idx+2) = min(TimeAxis);
        vvn(1,idx+1) = n;
        vvn(2,idx+1) = max(TimeAxis);
        vvn(1,idx+2) = n;
        vvn(2,idx+2) = min(TimeAxis);
        ff=length(vvp):-1:1;
        H.phandle(n) = patch('Faces',ff,'Vertices',vvp','FaceColor',[.8 .8 .8],'EdgeColor','none','Tag','phandle');
        H.nhandle(n) = patch('Faces',ff,'Vertices',vvn','FaceColor',[.8 .8 .8],'EdgeColor','none','Tag','nhandle');
        %H.phandle(n) = patch (PFilledTrace(:,n)' + n,TimeAxis',[.8 .8 .8],'EdgeColor','none','Tag','phandle');
        %H.nhandle(n) = patch (NFilledTrace(:,n)' + n,TimeAxis',[.8 .8 .8],'EdgeColor','none','Tag','nhandle');
        H.lhandle(n) = line((Amplitudes(:,n) + n),TIME,'Color',[.5 .5 .5],'LineWidth',1,'Tag','lhandle','UIContextMenu',H.cmenu(n));
    end
    if strcmp(c_tail,'eqr') || strcmp(c_tail,'eqt')
        if exist('Tps')
            for m = 1:size(Tps,1)
                line([-0.5 0.5]+n,[Tps(m,n) Tps(m,n)],'Color',[0 0 0],'LineWidth',2);
            end
        end
        if exist('Tpp')
            for m = 1:size(Tpp,1)
                line([-0.5 0.5]+n,[Tpp(m,n) Tpp(m,n)],'Color',[0 0 0],'LineWidth',2);
            end
        end
        if exist('Tss')
            for m = 1:size(Tss,1)
                line([-0.5 0.5]+n,[Tss(m,n) Tss(m,n)],'Color',[0 0 0],'LineWidth',2);
            end
        end
    end
end
set(gca,'XLim',[0 WindowSize]);
set(gca,'YLim',[YTicks(1) YTicks(end)]);

% Set Trace On/Off Checkboxes
%--------------------------------------------------------------------------
for n = 1:NumberOfTraces
    XPosition = (0.1 + (.85/(WindowSize+3)) + ((n - 1) * (.85/WindowSize)));
    PositionVector = [XPosition 0.9 0.02 0.025];
    NewValue = CurrentRecords{n,5} == 1;
    H.checkhandles(n) = uicontrol ('Parent',H.figure,'Style','checkbox','Units','normalized','Tag','checkhandles','TooltipString',[CurrentRecords{n,2} ' ' CurrentRecords{n,3}],...
        'Position',PositionVector,'Value',NewValue,'Visible','off','CallBack',{@TraceEdit_Callback});
end
if length(H.checkhandles) < WindowSize
    set(H.checkhandles(:),'Visible','on');
else
    set(H.checkhandles(1:(WindowSize-1)),'Visible','on');
    AxisMax = NumberOfTraces+1-WindowSize;
    H.sliderhandle = uicontrol ('Parent',H.figure,'Style','slider','Units','normalized','Tag','sliderhandle','TooltipString','Move slider to control the plot window',...
        'Min',0,'Max',AxisMax,'SliderStep',[1/AxisMax floor(WindowSize-1)/AxisMax],'CallBack',@Slider_Callback);
    Pos = get(H.sliderhandle,'Position');
    set(H.sliderhandle,'Position',[.1 Pos(2) .85 Pos(4)]);
end

% Add the save and close button
%--------------------------------------------------------------------------
H.closebutton = uicontrol ('Parent',H.figure,'Style','pushbutton','Units','normalized','Tag','closebutton','String','Save Edits',...
    'Position',[0.025 0.95 0.1 0.03],'FontUnits','normalized','FontSize',0.5,'CallBack',{@CloseSave_Callback});

% Add the cancel button
%--------------------------------------------------------------------------
H.cancelbutton = uicontrol ('Parent',H.figure,'Style','pushbutton','Units','normalized','Tag','cancelbutton','String','Cancel',...
    'Position',[0.13 0.95 0.1 0.03],'FontUnits','normalized','FontSize',0.5,'CallBack',{@close_Callback});

% Add sorting options
%--------------------------------------------------------------------------
H.sortbytext = uicontrol('Parent',H.figure,'Style','Text','Units','Normalized','Tag','sortbytext','String','Sort by: ',...
    'Position',[0.61 0.945 0.08 0.03],'FontUnits','Normalized','FontSize',0.5);

% Allow the user to sort by most options in current records
% Mostly in order of the current records variable, but with ray parameter
% and backazimuth on top as those are most likely to be most used.
% Continuing in the style of having a variety of methods for passing
% information around the UI environment, this section uses the guidata to
% store information about the ui controls and then when the sort button is
% pressed, it looks up the current state of the other controls.
SortOptions = {'Rayparameter', 'Backazimuth','Active','Gaussian','Radial RF fit', 'Transverse RF fit','Station Latitude', 'Station Longitude','Station Elevation',...
    'Event Latitude', 'Event Longitude', 'Event Depth', 'Magnitude', 'Distance (deg)','Station Name','Event Origin'};
DefaultSortValue = 2; % Defaultin the popup menu to backazimuth
% Popup menu to choose sort options
H.sortbypopup = uicontrol('Parent',H.figure,'Style','Popupmenu','Units','Normalized','Tag','sortbypopup','String',SortOptions,...
    'Value',DefaultSortValue,'Position',[0.69 0.95 0.12 0.03],'FontUnits','Normalized','FontSize',0.5);

% Text to give option to reverse sorting
H.reversesorttext = uicontrol('Parent',H.figure,'Style','Text','Units','Normalized','Tag','reversesorttext','String','Reverse?: ',...
    'Position',[0.81 0.945 0.08 0.03],'FontUnits','Normalized','FontSize',0.5);

% Checkbox to reverse sorting
H.reversesortcheckbox = uicontrol('Parent',H.figure,'Style','Checkbox','Units','Normalized','Tag','reversesortcheckbox','Value',0,...
    'Position',[0.87 0.95 0.03 0.03]);

% Button to run sorting and re-draw
H.sortbutton = uicontrol('Parent',H.figure,'Style','Pushbutton','Units','Normalized','Tag','sortbutton','String','Sort',...
    'Position',[0.91 0.95 0.08 0.03],'FontUnits','Normalized','FontSize',0.5,'Callback',{@sort_trace_edit_callback});

% For Meghan, button to deselect all. Should fill out with a "deselect by"
% interface
H.deselectAllButton = uicontrol('Parent',H.figure,'Style','Pushbutton','Units','Normalized','Tag','deselectAllButton','String','Deselect all',...
    'Position',[0.3 0.95 0.075 0.03],'FontUnits','Normalized','FontSize',0.5,'Callback',{@deselect_all_traces_callback});

H.selectAllButton = uicontrol('Parent',H.figure,'Style','Pushbutton','Units','Normalized','Tag','selectAllButton','String','Select all',...
    'Position',[0.38 0.95 0.075 0.03],'FontUnits','Normalized','FontSize',0.5,'Callback',{@select_all_traces_callback});

% Set the GUI handles for use in callback functions
%--------------------------------------------------------------------------
Handles = guihandles;
Handles.projdir = ProjectDirectory;
Handles.projfile = ProjectFile;
Handles.windowsize = WindowSize;
Handles.timemin = TimeWindowMin;
Handles.timemax = TimeWindowMax;
Handles.newtime = NewTime;
Handles.timeaxis = TimeAxis;
Handles.pamps = PFilledTrace;
Handles.namps = NFilledTrace;
Handles.amps = Amplitudes;
Handles.component = TraceEditPreferences{1};
Handles.axes = gca;
Handles.traces = CurrentRecords;
Handles.indices = CurrentIndices;
Handles.cmenu = H.cmenu;
Handles.plot = H.plot;
Handles.turnon = H.turnon;
Handles.turnoff = H.turnoff;
Handles.mag = H.mag;
Handles.dist = H.dist;
Handles.baz = H.baz;
Handles.rayp = H.rayp;
Handles.radfit = H.radfit;
Handles.transfit = H.transfit;
Handles.name = Table;
guidata(H.figure,Handles);
H.figure.UserData.projdir = ProjectDirectory;
H.figure.UserData.projfile = ProjectFile;
H.figure.UserData.traces = CurrentRecords;
H.figure.UserData.indices = CurrentIndices;
H.figure.UserData.name = Table;
H.figure.UserData.turnon = H.turnon;
H.figure.UserData.turnoff = H.turnoff;
H.figure.UserData.checkhandles = H.checkhandles;
H.figure.UserData.phandle = H.phandle;
H.figure.UserData.nhandle = H.nhandle;
H.figure.UserData.lhandle = H.lhandle;
H.figure.UserData.amps = AMPS;
H.figure.UserData.reversesortcheckbox = H.reversesortcheckbox;
H.figure.UserData.sortbypopup = H.sortbypopup;
H.figure.UserData.newtime = TIME;
H.figure.UserData.sliderhandle = H.sliderhandle;
varargout{1} = Handles;


%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% SUBFUNCTION CALLBACKS
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% deselect_all_traces_callback
% This callback sets all traces to inactive
%--------------------------------------------------------------------------
function deselect_all_traces_callback(cbo, eventdata, handles)
%h = guidata(gcbf);
h = findobj('Tag','TraceEditGui');
ntraces = size(h.UserData.traces,1);

for idx=1:ntraces
    h.UserData.traces{idx,5} = 0;
    set(h.UserData.checkhandles(idx),'Value',0)
    set(h.UserData.phandle(idx),'FaceColor',[.8 .8 .8],'EdgeColor','none')
    set(h.UserData.nhandle(idx),'FaceColor',[.8 .8 .8],'EdgeColor','none')
    set(h.UserData.lhandle(idx),'Color',[.5 .5 .5],'LineWidth',1)
end


%guidata(gcbf,h);

%--------------------------------------------------------------------------
% select_all_traces_callback
% This callback sets all traces to inactive
%--------------------------------------------------------------------------
function select_all_traces_callback(cbo, eventdata, handles)
%h = guidata(gcbf);
h = findobj('Tag','TraceEditGui');

ntraces = size(h.UserData.traces,1);

for idx=1:ntraces
    h.UserData.traces{idx,5} = 1;
    set(h.UserData.checkhandles(idx),'Value',1)
    set(h.UserData.phandle(idx),'FaceColor',[1 .7961 0],'EdgeColor','none')
    set(h.UserData.nhandle(idx),'FaceColor',[.7 .5573 .3],'EdgeColor','none')
    set(h.UserData.lhandle(idx),'Color',[.5 .5 .5],'LineWidth',1)
end

%guidata(gcbf,h);

%--------------------------------------------------------------------------
% sort_trace_edit_callback
%
% This callback function sorts the traces in the trace editing UI by the
% user chosen parameter. 
%--------------------------------------------------------------------------
function sort_trace_edit_callback(cbo, eventdata, handles)

hdls = guidata(gcbf);
h = findobj('Tag','TraceEditGui');

% All of the metadata is stored in h.traces
% its in the form of an Ntraces X 22 cell array in which each entry is its
% own cell. Need to do a little magic to get the value we want into a
% sortable vector, run sort, and then use the new sorted indices to plot
% the data. Also, be sure to return these indices so the checkboxes
% continue to map to the right record.
unedittedPositiveColor = [.6 0 0];
unedittedNegativeColor = [.75 .4 .45];
edittedPositiveColor = [1 .7961 0];
edittedNegativeColor = [.7 .5573 .3];
CurrentRecords = h.UserData.traces;
AMPS = h.UserData.amps;

% EditWindowHandles = gcf;
% 
% % Wait gui so the user knows it is doing something
% WaitGui = dialog ('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
%     'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
% uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
%     'String','Please wait while sorting',...
%     'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
% h2 = guihandles(WaitGui);
% guidata(WaitGui,h2);
% drawnow


% First get the metadata about how we are going to sort
% Default is ascending order
switch h.UserData.reversesortcheckbox.Value
    case 0
        SortSenseFlag = 'ascend';
    case 1
        SortSenseFlag = 'descend';
end

% Sorting parameter
%SortOptions = {'Rayparameter', 'Backazimuth','Active','Gaussian','Radial RF fit', 'Transverse RF fit','Station Latitude', 'Station Longitude','Station Elevation',...
%    'Event Latitude', 'Event Longitude', 'Event Depth', 'Magnitude', 'Distance (deg)', 'Station Name', 'Event Origin'};
switch h.UserData.sortbypopup.Value
    case 1
        SortColumn = 21;
    case 2
        SortColumn = 22;
    case 3
        SortColumn = 5;
    case 4
        SortColumn = 10;
    case 5
        SortColumn = 11;
    case 6
        SortColumn = 12;
    case 7
        SortColumn = 13;
    case 8
        SortColumn = 14;
    case 9
        SortColumn = 15;   
    case 10
        SortColumn = 16;
    case 11
        SortColumn = 17;
    case 12
        SortColumn = 18; 
    case 13
        SortColumn = 19;
    case 14
        SortColumn = 20;
    case 15
        SortColumn = 2;
    case 16
        SortColumn = 3;
end

% get the metadata from the h.traces structure into a vector for sorting
if SortColumn ~= 2 && SortColumn ~= 3
    sortvector = zeros(size(h.UserData.traces,1),1);
    for idx=1:size(h.UserData.traces,1)
        tmp = h.UserData.traces(idx, SortColumn);
        sortvector(idx) = tmp{1};
    end
    
else
    sortvector = cell(size(h.UserData.traces,1),1);
    for idx=1:size(h.UserData.traces,1)
        sortvector{idx} = h.UserData.traces{idx, SortColumn};
    end
end

% Actual sort
if SortColumn ~= 2 && SortColumn ~= 3
    [~, SortIndices] = sort(sortvector,1,SortSenseFlag);
else
    [~, SortIndices] = sort(sortvector);
    if strcmp(SortSenseFlag,'descend')
        SortIndices = flipud(SortIndices);
    end
end
for idx=1:size(h.UserData.traces,1)
    CurrentRecords(idx,:) = h.UserData.traces(SortIndices(idx),:);
    AMPS(:,idx) = h.UserData.amps(:,SortIndices(idx));
end
h.UserData.amps = AMPS;
h.UserData.traces = CurrentRecords;
SortedIndices = h.UserData.indices(SortIndices);
h.UserData.indices = SortedIndices;

%close(WaitGui)
% Clears the current window so we can replot the traces
%figure(EditWindowHandles);
cla
% everything outside the main window is still there. Need to redraw the
% traces and reset the check boxes
load([h.UserData.projdir h.UserData.projfile],'TraceEditPreferences')
switch TraceEditPreferences{1}
    case 'Radial'
        c_tail = 'eqr';
    case 'Transverse'
        c_tail = 'eqt';
    case 'Non-RF Vertical'
        c_tail = 'z';
    case 'Non-RF Radial'
        c_tail = 'r';
    case 'Non-RF Tangential'
        c_tail = 't';
end
YTickIncrement = str2double(TraceEditPreferences{4});
Gain = str2double(TraceEditPreferences{5});
WindowSize = str2double(TraceEditPreferences{6});
TimeWindowMin = str2double(TraceEditPreferences{7});
TimeWindowMax = str2double(TraceEditPreferences{8});
TimeInterpDelta = str2double(TraceEditPreferences{9});
NewTime = colvector(TimeWindowMin:TimeInterpDelta:TimeWindowMax);

% Set the y-axis ticks
%--------------------------------------------------------------------------
if rem(TimeWindowMin,YTickIncrement) == 1
    TimeWindowMin = floor(TimeWindowMin/YTickIncrement) * YTickIncrement;
end
if rem(TimeWindowMax,YTickIncrement) == 1
    TimeWindowMax = ceil(TimeWindowMax/YTickIncrement) * YTickIncrement;
end
YTicks = TimeWindowMin:YTickIncrement:TimeWindowMax;
set(gca,'YTick',YTicks);

NumberOfTraces = size(h.UserData.traces,1);

% Make the "Zero"-line for reference
%--------------------------------------------------------------------------
line([0 NumberOfTraces+1],[0 0],'Color',[.2 .6 .8])

for n = NumberOfTraces:-1:1
    p(n) = CurrentRecords{n,21};
end

Phases = TraceEditPreferences{3};
if ~isempty(Phases)
    Phases = strread(Phases,'%s','delimiter',',');
    
    if isnan(str2double(Phases{1}(1)));

        VModel = TraceEditPreferences{2};
        Datapath = regexprep(which('funclab'),'funclab.m','VELMODELS/');
        Velocity1D = [Datapath VModel];
        VelocityModel = load(Velocity1D,'-ascii');
        Depths = VelocityModel(:,1);
        Vp = VelocityModel(:,2);
        Vs = VelocityModel(:,3);
        Vp = interp1(Depths,Vp,[0:1:Depths(end)])';
        Vs = interp1(Depths,Vs,[0:1:Depths(end)])';
        Depths = [0:1:Depths(end)]';
        dz = [0; diff(Depths)];
        R = 6371 - Depths;
       
        % Determine the name of the phase.  This only handles P primary phases
        % and first-order reverberation phases.
        for n = 1:length(Phases)
            FirstPhase = Phases{n}(1);
            if ~strcmp(FirstPhase,'P')
                disp('Phase name is not in the correct format.')
                disp('Phase moveout curve skipped.')
                break
            end
            k = 1;
            l = 0;
            while 1
                k = k + 1;
                l = l + 1;
                if isnan(str2double(Phases{n}(k)))
                    break
                end
                PhaseDepth(l) = Phases{n}(k);
            end
            if k == 2
                disp('Phase name is not in the correct format.')
                disp('Phase moveout curve skipped.')
                break
            end
            PhaseDepth = str2double(PhaseDepth);
            SecondPhase = Phases{n}(k:end);
            switch SecondPhase
                case 's'
                    for m = 1:length(p)
                        RayP = skm2srad (p(m));
                        temp(:,m) = cumsum((sqrt((R./Vs).^2 - RayP^2) - sqrt((R./Vp).^2 - RayP^2)) .* (dz./R));
                    end
                    if exist('Tps')
                        Tps(end+1,:) = temp(PhaseDepth+1,:);
                        TpsPhase{end+1} = Phases{n};
                    else
                        Tps(1,:) = temp(PhaseDepth+1,:);
                        TpsPhase{1} = Phases{n};
                    end
                    clear temp
                case 'pPs'
                    for m = 1:length(p)
                        RayP = skm2srad (p(m));
                        temp(:,m) = cumsum((sqrt((R./Vs).^2 - RayP^2) + sqrt((R./Vp).^2 - RayP^2)) .* (dz./R));
                    end
                    if exist('Tpp')
                        Tpp(end+1,:) = temp(PhaseDepth+1,:);
                        TppPhase{end+1} = Phases{n};
                    else
                        Tpp(1,:) = temp(PhaseDepth+1,:);
                        TppPhase{1} = Phases{n};
                    end
                    clear temp
                case 'pSs'
                    for m = 1:length(p)
                        RayP = skm2srad (p(m));
                        temp(:,m) = cumsum(sqrt((R./Vs).^2 - RayP^2) .* (2*dz./R));
                    end
                    if exist('Tss')
                        Tss(end+1,:) = temp(PhaseDepth+1,:);
                        TssPhase{end+1} = Phases{n};
                    else
                        Tss(1,:) = temp(PhaseDepth+1,:);
                        TssPhase{1} = Phases{n};
                    end
                    clear temp
                case 'sPs'
                    for m = 1:length(p)
                        RayP = skm2srad (p(m));
                        temp(:,m) = cumsum(sqrt((R./Vs).^2 - RayP^2) .* (2*dz./R));
                    end
                    if exist('Tss')
                        Tss(end+1,:) = temp(PhaseDepth+1,:);
                        TssPhase{end+1} = Phases{n};
                    else
                        Tss(1,:) = temp(PhaseDepth+1,:);
                        TssPhase{1} = Phases{n};
                    end
                    clear temp
                otherwise
                    disp('Phase name is not in the correct format.')
                    disp('Phase moveout curve skipped.')
                    break
            end
            clear temp FirstPhase PhaseDepth SecondPhase
        end
    else
        disp('Phase names are not in the correct format.')
        disp('No phase moveout curves plotted.')
    end

end

% WaitGui = dialog ('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
%     'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
% uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
%     'String','Please wait while sorting',...
%     'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
% h2 = guihandles(WaitGui);
% guidata(WaitGui,h2);
% drawnow


% Make the matrices for the normalized traces (Amplitudes), the filled part
% of the wiggle traces (FilledTrace), and the time axis for the wiggle
% traces (TimeAxis).
%--------------------------------------------------------------------------
TIME = h.UserData.newtime;
XTicks = 0:NumberOfTraces+1;
XRange = XTicks(end) - XTicks(1);
AmplitudeFactor = XRange / NumberOfTraces;
MaximumAmplitude = max(abs(AMPS));
MaximumAmplitude = repmat(MaximumAmplitude,size(AMPS,1),1);
NormalizedAmplitudes = AMPS ./ MaximumAmplitude;
Amplitudes = NormalizedAmplitudes .* (AmplitudeFactor * Gain);
PositiveIndices = find (Amplitudes > 0);
NegativeIndices = find (Amplitudes < 0);
TempAmps = reshape(Amplitudes,[],1);
Pamps = zeros (size(TempAmps));
Pamps(PositiveIndices) = TempAmps(PositiveIndices);
Namps = zeros (size(TempAmps));
Namps(NegativeIndices) = TempAmps(NegativeIndices);
PFilledTrace = reshape(Pamps,size(Amplitudes));
NFilledTrace = reshape(Namps,size(Amplitudes));
TimeAxis = TIME;
PFilledTrace = [zeros(1,size(PFilledTrace,2)); PFilledTrace; zeros(1,size(PFilledTrace,2))];
NFilledTrace = [zeros(1,size(NFilledTrace,2)); NFilledTrace; zeros(1,size(NFilledTrace,2))];
TimeAxis = [ones(1,size(TimeAxis,2)) .* TimeAxis(1,:);
    TimeAxis;
    ones(1,size(TimeAxis,2)) .* TimeAxis(end,:)];

% Begin plotting each trace in the axes
%--------------------------------------------------------------------------
for n = NumberOfTraces:-1:1
    if CurrentRecords{n,5} == 1
        if CurrentRecords{n,4} == 0
            hdls.cmenu(n) = uicontextmenu;
            hdls.plot(n) = uimenu(hdls.cmenu(n),'Label','Plot Seismograms','Callback',{@plot_Callback});
            hdls.turnon(n) = uimenu(hdls.cmenu(n),'Label','Turn ''On"','Callback',{@turnon_Callback});
            hdls.turnoff(n) = uimenu(hdls.cmenu(n),'Label','Turn ''Off"','Callback',{@turnoff_Callback});
            hdls.mag(n) = uimenu(hdls.cmenu(n),'Label',['Magnitude = ' num2str(CurrentRecords{n,19},'%.2f')],'Separator','on','ForegroundColor',[.6 0 .2]);
            hdls.dist(n) = uimenu(hdls.cmenu(n),'Label',['Distance = ' num2str(CurrentRecords{n,20},'%.2f')],'ForegroundColor',[.6 0 .2]);
            hdls.baz(n) = uimenu(hdls.cmenu(n),'Label',['Backazimuth = ' num2str(CurrentRecords{n,22},'%.2f')],'ForegroundColor',[.6 0 .2]);
            hdls.rayp(n) = uimenu(hdls.cmenu(n),'Label',['Ray Parameter = ' num2str(CurrentRecords{n,21},'%.4f')],'ForegroundColor',[.6 0 .2]);
            hdls.radfit(n) = uimenu(hdls.cmenu(n),'Label',['Radial Fit = ' num2str(CurrentRecords{n,11},'%.1f')],'ForegroundColor',[.6 0 .2]);
            hdls.transfit(n) = uimenu(hdls.cmenu(n),'Label',['Transverse Fit = ' num2str(CurrentRecords{n,12},'%.1f')],'ForegroundColor',[.6 0 .2]);
            vp = [PFilledTrace(:,n)'+n; TimeAxis'];
            vn = [NFilledTrace(:,n)'+n; TimeAxis'];
            idx = length(vp);
            vvp = vp;
            vvn = vn;
            vvp(1,idx+1) = n;
            vvp(2,idx+1) = max(TimeAxis);
            vvp(1,idx+2) = n;
            vvp(2,idx+2) = min(TimeAxis);
            vvn(1,idx+1) = n;
            vvn(2,idx+1) = max(TimeAxis);
            vvn(1,idx+2) = n;
            vvn(2,idx+2) = min(TimeAxis);
            ff=length(vvp):-1:1;
            hdls.phandle(n) = patch('Faces',ff,'Vertices',vvp','FaceColor',unedittedPositiveColor,'EdgeColor','none','Tag','phandle');
            hdls.nhandle(n) = patch('Faces',ff,'Vertices',vvn','FaceColor',unedittedNegativeColor,'EdgeColor','none','Tag','nhandle');
            %h.phandle(n) = patch (PFilledTrace(:,n)' + n,TimeAxis',unedittedPositiveColor,'EdgeColor','none','Tag','phandle');
            %h.nhandle(n) = patch (NFilledTrace(:,n)' + n,TimeAxis',unedittedNegativeColor,'EdgeColor','none','Tag','nhandle');
            hdls.lhandle(n) = line((Amplitudes(:,n) + n),TIME,'Color',[0 0 0],'LineWidth',1,'Tag','lhandle','UIContextMenu',hdls.cmenu(n));
        else
            hdls.cmenu(n) = uicontextmenu;
            hdls.plot(n) = uimenu(hdls.cmenu(n),'Label','Plot Seismograms','Callback',{@plot_Callback});
            hdls.turnon(n) = uimenu(hdls.cmenu(n),'Label','Turn ''On"','Callback',{@turnon_Callback});
            hdls.turnoff(n) = uimenu(hdls.cmenu(n),'Label','Turn ''Off"','Callback',{@turnoff_Callback});
            hdls.mag(n) = uimenu(hdls.cmenu(n),'Label',['Magnitude = ' num2str(CurrentRecords{n,19},'%.2f')],'Separator','on','ForegroundColor',[.6 0 .2]);
            hdls.dist(n) = uimenu(hdls.cmenu(n),'Label',['Distance = ' num2str(CurrentRecords{n,20},'%.2f')],'ForegroundColor',[.6 0 .2]);
            hdls.baz(n) = uimenu(hdls.cmenu(n),'Label',['Backazimuth = ' num2str(CurrentRecords{n,22},'%.2f')],'ForegroundColor',[.6 0 .2]);
            hdls.rayp(n) = uimenu(hdls.cmenu(n),'Label',['Ray Parameter = ' num2str(CurrentRecords{n,21},'%.4f')],'ForegroundColor',[.6 0 .2]);
            hdls.radfit(n) = uimenu(hdls.cmenu(n),'Label',['Radial Fit = ' num2str(CurrentRecords{n,11},'%.1f')],'ForegroundColor',[.6 0 .2]);
            hdls.transfit(n) = uimenu(hdls.cmenu(n),'Label',['Transverse Fit = ' num2str(CurrentRecords{n,12},'%.1f')],'ForegroundColor',[.6 0 .2]);
            vp = [PFilledTrace(:,n)'+n; TimeAxis'];
            vn = [NFilledTrace(:,n)'+n; TimeAxis'];
            idx = length(vp);
            vvp = vp;
            vvn = vn;
            vvp(1,idx+1) = n;
            vvp(2,idx+1) = max(TimeAxis);
            vvp(1,idx+2) = n;
            vvp(2,idx+2) = min(TimeAxis);
            vvn(1,idx+1) = n;
            vvn(2,idx+1) = max(TimeAxis);
            vvn(1,idx+2) = n;
            vvn(2,idx+2) = min(TimeAxis);
            ff=length(vvp):-1:1;
            hdls.phandle(n) = patch('Faces',ff,'Vertices',vvp','FaceColor',edittedPositiveColor,'EdgeColor','none','Tag','phandle');
            hdls.nhandle(n) = patch('Faces',ff,'Vertices',vvn','FaceColor',edittedNegativeColor,'EdgeColor','none','Tag','nhandle');
            %h.phandle(n) = patch (PFilledTrace(:,n)' + n,TimeAxis',edittedPositiveColor,'EdgeColor','none','Tag','phandle');
            %h.nhandle(n) = patch (NFilledTrace(:,n)' + n,TimeAxis',edittedNegativeColor,'EdgeColor','none','Tag','nhandle');
            hdls.lhandle(n) = line((Amplitudes(:,n) + n),TIME,'Color',[0 0 0],'LineWidth',1,'Tag','lhandle','UIContextMenu',hdls.cmenu(n));
        end
    end
    if CurrentRecords{n,5} == 0
        hdls.cmenu(n) = uicontextmenu;
        hdls.plot(n) = uimenu(hdls.cmenu(n),'Label','Plot Seismograms','Callback',{@plot_Callback});
        hdls.turnon(n) = uimenu(hdls.cmenu(n),'Label','Turn ''On"','Callback',{@turnon_Callback});
        hdls.turnoff(n) = uimenu(hdls.cmenu(n),'Label','Turn ''Off"','Callback',{@turnoff_Callback});
        hdls.mag(n) = uimenu(hdls.cmenu(n),'Label',['Magnitude = ' num2str(CurrentRecords{n,19},'%.2f')],'Separator','on','ForegroundColor',[.6 0 .2]);
        hdls.dist(n) = uimenu(hdls.cmenu(n),'Label',['Distance = ' num2str(CurrentRecords{n,20},'%.2f')],'ForegroundColor',[.6 0 .2]);
        hdls.baz(n) = uimenu(hdls.cmenu(n),'Label',['Backazimuth = ' num2str(CurrentRecords{n,22},'%.2f')],'ForegroundColor',[.6 0 .2]);
        hdls.rayp(n) = uimenu(hdls.cmenu(n),'Label',['Ray Parameter = ' num2str(CurrentRecords{n,21},'%.4f')],'ForegroundColor',[.6 0 .2]);
        hdls.radfit(n) = uimenu(hdls.cmenu(n),'Label',['Radial Fit = ' num2str(CurrentRecords{n,11},'%.1f')],'ForegroundColor',[.6 0 .2]);
        hdls.transfit(n) = uimenu(hdls.cmenu(n),'Label',['Transverse Fit = ' num2str(CurrentRecords{n,12},'%.1f')],'ForegroundColor',[.6 0 .2]);
        vp = [PFilledTrace(:,n)'+n; TimeAxis'];
        vn = [NFilledTrace(:,n)'+n; TimeAxis'];
        idx = length(vp);
        vvp = vp;
        vvn = vn;
        vvp(1,idx+1) = n;
        vvp(2,idx+1) = max(TimeAxis);
        vvp(1,idx+2) = n;
        vvp(2,idx+2) = min(TimeAxis);
        vvn(1,idx+1) = n;
        vvn(2,idx+1) = max(TimeAxis);
        vvn(1,idx+2) = n;
        vvn(2,idx+2) = min(TimeAxis);
        ff=length(vvp):-1:1;
        hdls.phandle(n) = patch('Faces',ff,'Vertices',vvp','FaceColor',[.8 .8 .8],'EdgeColor','none','Tag','phandle');
        hdls.nhandle(n) = patch('Faces',ff,'Vertices',vvn','FaceColor',[.8 .8 .8],'EdgeColor','none','Tag','nhandle');
        %h.phandle(n) = patch (PFilledTrace(:,n)' + n,TimeAxis',[.8 .8 .8],'EdgeColor','none','Tag','phandle');
        %h.nhandle(n) = patch (NFilledTrace(:,n)' + n,TimeAxis',[.8 .8 .8],'EdgeColor','none','Tag','nhandle');
        hdls.lhandle(n) = line((Amplitudes(:,n) + n),TIME,'Color',[.5 .5 .5],'LineWidth',1,'Tag','lhandle','UIContextMenu',hdls.cmenu(n));
    end
    if strcmp(c_tail,'eqr') || strcmp(c_tail, 'eqt')
        if exist('Tps')
            for m = 1:size(Tps,1)
                line([-0.5 0.5]+n,[Tps(m,n) Tps(m,n)],'Color',[0 0 0],'LineWidth',2);
            end
        end
        if exist('Tpp')
            for m = 1:size(Tpp,1)
                line([-0.5 0.5]+n,[Tpp(m,n) Tpp(m,n)],'Color',[0 0 0],'LineWidth',2);
            end
        end
        if exist('Tss')
            for m = 1:size(Tss,1)
                line([-0.5 0.5]+n,[Tss(m,n) Tss(m,n)],'Color',[0 0 0],'LineWidth',2);
            end
        end
    end
end
set(gca,'XLim',[0 WindowSize]);
set(gca,'YLim',[YTicks(1) YTicks(end)]);


% Set Trace On/Off Checkboxes
%--------------------------------------------------------------------------
checks = fliplr(h.UserData.checkhandles);
for n = NumberOfTraces:-1:1
    XPosition = (0.1 + (.85/(WindowSize+3)) + ((n - 1) * (.85/WindowSize)));
    PositionVector = [XPosition 0.9 0.02 0.025];
    set(checks(n),'Position',PositionVector);
    set(checks(n),'TooltipString',[CurrentRecords{n,2} ' ' CurrentRecords{n,3}])
    if h.UserData.traces{n,5} == 1
        set(checks(n),'Value',1)
    else
        set(checks(n),'Value',0)
    end
end
h.UserData.checkhandles = fliplr(checks);
hdls.checkhandles = fliplr(checks);


% Initialize the slider back to the 0 point
%--------------------------------------------------------------------------
if WindowSize < size(h.UserData.traces,1)
    StartValue = 0;
    EndValue = WindowSize;
    set(gca,'xlim',[StartValue EndValue]);
    %set(h.checkhandles(:),'Visible','off');
    %h.checkhandles = fliplr(h.checkhandles);
    count = 0-StartValue;
    for n = 1:length(checks)
        count = count + 1;
        PositionVector = [(0.1 + (.85/(WindowSize+3)) + ((count - 1) * (.85/WindowSize))) 0.9 0.02 0.025];
        set(checks(n),'Position',PositionVector)
    end
    set(checks(floor(StartValue+1):ceil(EndValue-1)),'Visible','on');
    h.UserData.checkhandles = fliplr(checks);
    hdls.checkhandles = fliplr(checks);
    set(h.UserData.sliderhandle,'Value',0);
    set(hdls.sliderhandle,'Value',0);
end

%close(WaitGui);

% Repack the guidata
guidata(gcbf,hdls);

%--------------------------------------------------------------------------
% Slider_Callback
%
% This callback function moves the plots and the checkboxes as you move the
% slider left or right.
%--------------------------------------------------------------------------
function Slider_Callback (cbo,eventdata,handles)
h = guidata(gcbf);
WindowSize = h.windowsize;
StartValue = get(gcbo,'value');
EndValue = get(gcbo,'value') + WindowSize;
set(gca,'xlim',[StartValue EndValue]);
set(h.checkhandles(:),'Visible','off');
h.checkhandles = fliplr(h.checkhandles);
count = 0-StartValue;
for n = 1:length(h.checkhandles)
    count = count + 1;
    PositionVector = [(0.1 + (.85/(WindowSize+3)) + ((count - 1) * (.85/WindowSize))) 0.9 0.02 0.025];
    set(h.checkhandles(n),'Position',PositionVector)
end
set(h.checkhandles(floor(StartValue+1):ceil(EndValue-1)),'Visible','on');

%--------------------------------------------------------------------------
% TraceEdit_Callback
%
% This callback function sets the STATUS field in each trace and "fades"
% the plot of the traces that are turned "off".
%--------------------------------------------------------------------------
function TraceEdit_Callback (cbo,eventdata,handles)
h = guidata(gcbf);
checks = fliplr(h.checkhandles);
n = find(checks == cbo);
h2 = findobj('Tag','TraceEditGui');
CurrentRecords = h2.UserData.traces;
CheckVector = get(gcbo,'Value');

% Define 4 colors for editted and uneditted positive and negatives
unedittedPositiveColor = [.6 0 0];
unedittedNegativeColor = [.75 .4 .45];
edittedPositiveColor = [1 .7961 0];
edittedNegativeColor = [.7 .5573 .3];

switch CheckVector
    case 1
        CurrentRecords{n,5} = 1;
        if CurrentRecords{n,4} == 0
            set(h.phandle(n),'FaceColor',unedittedPositiveColor,'EdgeColor','none')
            set(h.nhandle(n),'FaceColor',unedittedNegativeColor,'EdgeColor','none')
            set(h.lhandle(n),'Color',[0 0 0],'LineWidth',1)
        else
            set(h.phandle(n),'FaceColor',edittedPositiveColor,'EdgeColor','none')
            set(h.nhandle(n),'FaceColor',edittedNegativeColor,'EdgeColor','none')
            set(h.lhandle(n),'Color',[0 0 0],'LineWidth',1)
        end
    case 0
        CurrentRecords{n,5} = 0;
        set(h.phandle(n),'FaceColor',[.8 .8 .8],'EdgeColor','none')
        set(h.nhandle(n),'FaceColor',[.8 .8 .8],'EdgeColor','none')
        set(h.lhandle(n),'Color',[.5 .5 .5],'LineWidth',1)
end
h2.UserData.traces = CurrentRecords;
guidata(gcbf,h);

%--------------------------------------------------------------------------
% plot_Callback
%
% This callback function plots the vertical, radial, and transverse
% seismograms associated with the receiver function.
%--------------------------------------------------------------------------
function plot_Callback (cbo,eventdata,handles)
h = guidata(gcbf);
ProjectDirectory = h.projdir;
n = find(h.plot == cbo);
CurrentRecords = h.traces;
Record = CurrentRecords(n,:);
PatchTime = h.timeaxis;
NewTime = h.newtime;
RFPos = h.pamps(:,n);
RFNeg = h.namps(:,n);
RFAmps = h.amps(:,n);

% Define 4 colors for manualPositive, manualNegative, autoPositive,
% autoNegative
unedittedPositiveColor = [.6 0 0];
unedittedNegativeColor = [.75 .4 .45];
edittedPositiveColor = [1 .7961 0];
edittedNegativeColor = [.7 .5573 .3];

switch h.component
    case 'Radial'
        RFName = 'Radial RF';
    case 'Transverse'
        RFName = 'Transverse RF';
end

if Record{5} == 1
    ViewHandles = te_view_record(ProjectDirectory,Record,h.timemin,h.timemax,1,PatchTime,RFPos,RFNeg,NewTime,RFAmps,RFName);
else
    ViewHandles = te_view_record(ProjectDirectory,Record,h.timemin,h.timemax,0,PatchTime,RFPos,RFNeg,NewTime,RFAmps,RFName);
end
uiwait(ViewHandles.dialogbox);
NewStatus = get(0,'userdata');
switch NewStatus
    case 1
        CurrentRecords{n,5} = 1;
        if CurrentRecords{n,4} == 0;
            set(h.phandle(n),'FaceColor',unedittedPositiveColor,'EdgeColor','none')
            set(h.nhandle(n),'FaceColor',unedittedNegativeColor,'EdgeColor','none')
            set(h.lhandle(n),'Color',[0 0 0],'LineWidth',1)
        else
            set(h.phandle(n),'FaceColor',edittedPositiveColor,'EdgeColor','none')
            set(h.nhandle(n),'FaceColor',edittedNegativeColor,'EdgeColor','none')
            set(h.lhandle(n),'Color',[0 0 0],'LineWidth',1)
        end
    case 0
        CurrentRecords{n,5} = 0;
        set(h.phandle(n),'FaceColor',[.8 .8 .8],'EdgeColor','none')
        set(h.nhandle(n),'FaceColor',[.8 .8 .8],'EdgeColor','none')
        set(h.lhandle(n),'Color',[.5 .5 .5],'LineWidth',1)
end
set(h.checkhandles(end - n + 1),'Value',NewStatus)
h.traces = CurrentRecords;
guidata(gcbf,h);

%--------------------------------------------------------------------------
% turnon_Callback
%
% This callback function sets the STATUS field to "ON" using the context
% menu.
%--------------------------------------------------------------------------
function turnon_Callback (cbo,eventdata,handles)
h = guidata(gcbf);
n = find(h.UserData.turnon == cbo);
CurrentRecords = h.UserData.traces;
CurrentRecords{n,5} = 1;

% Define 4 colors for editted and uneditted positive and negatives
unedittedPositiveColor = [.6 0 0];
unedittedNegativeColor = [.75 .4 .45];
edittedPositiveColor = [1 .7961 0];
edittedNegativeColor = [.7 .5573 .3];

if CurrentRecords{n,4} == 0;
    set(h.phandle(n),'FaceColor',unedittedPositiveColor,'EdgeColor','none')
    set(h.nhandle(n),'FaceColor',unedittedNegativeColor,'EdgeColor','none')
    set(h.lhandle(n),'Color',[0 0 0],'LineWidth',1)
else
    set(h.phandle(n),'FaceColor',edittedPositiveColor,'EdgeColor','none')
    set(h.nhandle(n),'FaceColor',edittedNegativeColor,'EdgeColor','none')
    set(h.lhandle(n),'Color',[0 0 0],'LineWidth',1)
end
n = find(fliplr(h.UserData.turnon) == cbo);
set(h.checkhandles(n),'Value',1)
h.UserData.traces = CurrentRecords;
guidata(gcbf,h);

%--------------------------------------------------------------------------
% turnoff_Callback
%
% This callback function sets the STATUS field to "OFF" using the context
% menu.
%--------------------------------------------------------------------------
function turnoff_Callback (cbo,eventdata,handles)
h = guidata(gcbf);
n = find(h.UserData.turnoff == cbo);
CurrentRecords = h.UserData.traces;
CurrentRecords{n,5} = 0;
set(h.phandle(n),'FaceColor',[.8 .8 .8],'EdgeColor','none')
set(h.nhandle(n),'FaceColor',[.8 .8 .8],'EdgeColor','none')
set(h.lhandle(n),'Color',[.5 .5 .5],'LineWidth',1)
n = find(fliplr(h.UserData.turnoff) == cbo);
set(h.checkhandles(n),'Value',0)
h.UserData.traces = CurrentRecords;
guidata(gcbf,h);

%--------------------------------------------------------------------------
% CloseSave_Callback
%
% Close the window and save the status settings
%--------------------------------------------------------------------------
function CloseSave_Callback (cbo,eventdata,handles)
%h = guidata(gcbf);
h = findobj('Tag','TraceEditGui');
WaitGui = dialog ('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
    'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
    'String',['Please wait, saving edits in ' h.UserData.name],...
    'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
h2 = guihandles(WaitGui);
guidata(WaitGui,h2);
drawnow
ProjectDirectory = h.UserData.projdir;
ProjectFile = h.UserData.projfile;
CurrentRecords = h.UserData.traces;
CurrentIndices = h.UserData.indices;
SetManagementCell = evalin('base','SetManagementCell');
CurrentSubsetIndex = evalin('base','CurrentSubsetIndex');
RecordMetadataStrings = SetManagementCell{CurrentSubsetIndex,2};
RecordMetadataDoubles = SetManagementCell{CurrentSubsetIndex,3};
%RecordMetadataStrings = evalin('base','RecordMetadataStrings');
%RecordMetadataDoubles = evalin('base','RecordMetadataDoubles');
for n = 1:size(CurrentRecords,1)
    CurrentRecords{n,4} = 1;
    RecordMetadataDoubles(CurrentIndices(n),1) = 1;
    RecordMetadataDoubles(CurrentIndices(n),2) = CurrentRecords{n,5};
end
assignin('base','CurrentRecords',CurrentRecords);
assignin('base','RecordMetadataDoubles',RecordMetadataDoubles);
assignin('base','RecordMetadataStrings',RecordMetadataStrings);
SetManagementCell{CurrentSubsetIndex, 3} = RecordMetadataDoubles;
assignin('base','SetManagementCell',SetManagementCell);
save([ProjectDirectory ProjectFile],'RecordMetadataDoubles','RecordMetadataStrings','SetManagementCell','-append')
fl_datainfo(ProjectDirectory,ProjectFile,RecordMetadataStrings,RecordMetadataDoubles, CurrentSubsetIndex)
close(WaitGui)
LogFile = [ProjectDirectory 'Logfile.txt'];
CTime = clock;
NewLog{1} = sprintf('Using set %s\n',SetManagementCell{CurrentSubsetIndex,5});
NewLog{2} = sprintf('%02.0f/%02.0f/%04.0f %02.0f:%02.0f:%02.0f - Manual Trace Editing: %s',CTime(2),CTime(3),CTime(1),CTime(4),CTime(5),CTime(6),h.UserData.name);
fl_edit_logfile(LogFile,NewLog)
Message = ['Message: Manually trace edited ' h.UserData.name '.'];
set(0,'userdata',Message);
close(h);

%--------------------------------------------------------------------------
% close_Callback
%
% This callback function closes the trace editing GUI without saving.
%--------------------------------------------------------------------------
function close_Callback (cbo,eventdata,handles)
%h = guidata(gcbf);
h = findobj('Tag','TraceEditGui');
Message = 'Cancelled';
set(0,'userdata',Message);
close(h);