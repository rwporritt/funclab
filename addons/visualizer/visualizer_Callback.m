function visualizer_Callback(cbo,eventdata,handles)
%--------------------------------------------------------------------------
% visualizer_Callback
%
% This callback function is for initiating the Visualizer GUI from the FuncLab
% Add-on menu.
%--------------------------------------------------------------------------
h = guidata(gcbf);
visualizer(h)