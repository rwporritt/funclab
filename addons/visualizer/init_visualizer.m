%INIT_VISUALIZER Initiates the Visualizer Add-on
%   INIT_VISUALIZER sets up the Visualizer Add-on GUI so that it can be used from
%   FuncLab.

%   Author: Robert W. Porritt
%   Date Created: 04/05/2015
%   Last Updated: 04/05/2015

uimenu(MAddons,'Label','Visualizer','Tag','visualizer_m','Enable','off','Callback',{@visualizer_Callback});