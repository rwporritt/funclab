function hk_Callback(cbo,eventdata,handles)
%--------------------------------------------------------------------------
% hk_Callback
%
% This callback function is for initiating the H-k GUI from the FuncLab
% Add-on menu.
%--------------------------------------------------------------------------
h = guidata(gcbf);
hk(h)