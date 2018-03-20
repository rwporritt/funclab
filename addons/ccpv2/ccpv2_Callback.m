function ccpv2_Callback(cbo,eventdata,handles)
%--------------------------------------------------------------------------
% ccpv2_Callback
%
% This callback function is for initiating the CCPV2 GUI from the FuncLab
% Add-on menu.
%--------------------------------------------------------------------------
h = guidata(gcbf);
ccpv2(h)