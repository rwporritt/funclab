%INIT_GCCP Initiates the GCCP Add-on
%   INIT_GCCP sets up the GCCP Add-on GUI so that it can be used from
%   FuncLab.

%   Author: Kevin C. Eagar
%   Date Created: 05/15/2010
%   Last Updated: 05/15/2010

uimenu(MAddons,'Label','Gaussian-Weighted Common Conversion Point Stacking','Tag','gccp_m','Enable','off','Callback',{@gccp_Callback});