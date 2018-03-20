function hk_saveparams(cbo,eventdata,handles)
% HK_SAVEPARAMS
% Saves the parameters input by the user to a structure variable saved with
% the project files. Allows the user to tweak the parameters once and then
% quickly reloaded them on the next call to hk

% Get the handles of the FuncLab GUI
%--------------------------------------------------------------------------
h = guidata(gcbf);


% Wait message
%--------------------------------------------------------------------------
WaitGui = dialog('Resize','off','NumberTitle','off','Tag','dialogbox','Units','characters','WindowStyle','modal',...
    'Position',[0 0 70 5],'CreateFcn',{@movegui_kce,'center'});
uicontrol ('Parent',WaitGui,'Style','text','Units','characters','Tag','message_t',...
    'String','Saving H-k parameters for next call to hk.',...
    'Position',[2 1.25 66 2.5],'FontUnits','normalized','FontSize',0.4);
drawnow;
H = guihandles(WaitGui);
guidata(WaitGui,H);

ProjectDirectory = evalin('base','ProjectDirectory');
ProjectFile = evalin('base','ProjectFile');

% Get set values and pack into output
%--------------------------------------------------------------------------
HKParams.ResampleNumber = str2double(get(h.bootresamples_e,'string'));
HKParams.RandomSelectionCount = str2double(get(h.bootpercent_e,'string'))/100;
HKParams.RayParameterMin = str2double(get(h.raypmin_e,'string'));
HKParams.RayParameterMax = str2double(get(h.raypmax_e,'string'));
HKParams.BackazimuthMin = str2double(get(h.bazmin_e,'string'));
HKParams.BackazimuthMax = str2double(get(h.bazmax_e,'string'));
HKParams.TimeMin = str2double(get(h.timemin_e,'string'));
HKParams.TimeMax = str2double(get(h.timemax_e,'string'));
HKParams.TimeDelta = str2double(get(h.timedelta_e,'string'));
HKParams.AssumedVp = str2double(get(h.vp_e,'string'));
HKParams.HMin = str2double(get(h.hmin_e,'string'));
HKParams.HMax = str2double(get(h.hmax_e,'string'));
HKParams.HDelta = str2double(get(h.hdelta_e,'string'));
HKParams.kMin = str2double(get(h.kmin_e,'string'));
HKParams.kMax = str2double(get(h.kmax_e,'string'));
HKParams.kDelta = str2double(get(h.kdelta_e,'string'));
HKParams.w1 = str2double(get(h.w1_e,'string'));
HKParams.w2 = str2double(get(h.w2_e,'string'));
HKParams.w3 = str2double(get(h.w3_e,'string'));
HKParams.Error = get(h.error_p,'value');

% Save to project file
save([ProjectDirectory ProjectFile],'HKParams','-append');

close(WaitGui)

