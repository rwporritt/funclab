%INIT_CCP Initiates the CCP Add-on
%   INIT_CCP sets up the CCP Add-on GUI so that it can be used from
%   FuncLab.

%   Author: Kevin C. Eagar
%   Date Created: 05/07/2008
%   Last Updated: 05/17/2010

uimenu(MAddons,'Label','Common Conversion Point Stacking','Tag','ccp_m','Enable','off','Callback',{@ccp_Callback});