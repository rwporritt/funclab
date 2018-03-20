function ccp_Callback(cbo,eventdata,handles)
%--------------------------------------------------------------------------
% ccp_Callback
%
% This callback function is for initiating the CCP GUI from the FuncLab
% Add-on menu.
%--------------------------------------------------------------------------
h = guidata(gcbf);
ccp(h)