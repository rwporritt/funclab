function rayp_baz_Callback(cbo,eventdata,handles)
%--------------------------------------------------------------------------
% rayp_baz_Callback
%
% This callback function is for initiating the rayp_baz GUI from the FuncLab
% Add-on menu.
%--------------------------------------------------------------------------
h = guidata(gcbf);
rayp_baz_stack(h)