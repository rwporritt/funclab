%INIT_CCPV2 Initiates the CCPV2 Add-on
%   INIT_CCPV2 sets up the CCPV2 Add-on GUI so that it can be used from
%   FuncLab.

%   Author: Rob Porritt
%   Date Created: 04/29/2015
%   Last Updated: 04/29/2015

uimenu(MAddons,'Label','Common Conversion Point Stacking V2','Tag','ccpv2_m','Enable','off','Callback',{@ccpv2_Callback});