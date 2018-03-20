function moho_auto_pick_Callback(cbo,eventdata,handles)
%--------------------------------------------------------------------------
% moho_auto_pick_Callback
%
% This callback function is for initiating the MOHO_AUTO_PICK GUI from the FuncLab
% Add-on menu.
%--------------------------------------------------------------------------
h = guidata(gcbf);
moho_auto_pick(h)