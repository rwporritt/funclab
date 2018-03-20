function gccp_Callback(cbo,eventdata,handles)
%--------------------------------------------------------------------------
% gccp_Callback
%
% This callback function is for initiating the GCCP GUI from the FuncLab
% Add-on menu.
%--------------------------------------------------------------------------
h = guidata(gcbf);
gccp(h)