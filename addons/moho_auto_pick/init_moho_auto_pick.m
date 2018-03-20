%INIT_MOHO_AUTO_PICK Initiates the Moho auto pick Add-on
%   INIT_MOHO_AUTO_PICK sets up the MOHO_AUTO_PICK Add-on GUI so that it can be used from
%   FuncLab.

%   Author: Robert W. Porritt
%   Date Created: 05/07/2015
%   Last Updated: 05/07/2015

uimenu(MAddons,'Label','Moho auto picking','Tag','moho_auto_pick_m','Enable','off','Callback',{@moho_auto_pick_Callback});