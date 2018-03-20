function moho_manual_pick_Callback(cbo,eventdata,handles)
%--------------------------------------------------------------------------
% moho_manual_pick_Callback
%
% This callback function is for initiating the MOHO_MANUAL_PICK GUI from the FuncLab
% Add-on menu.
%--------------------------------------------------------------------------
h = guidata(gcbf);
moho_manual_pick(h)