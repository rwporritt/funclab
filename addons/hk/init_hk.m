%INIT_HK Initiates the H-k Stacking Add-on
%    INIT_HK sets up the H-k Stacking Add-on GUI so that it can be used
%    from FuncLab.

%    Author: Kevin C. Eagar
%    Date Created: 01/09/2009
%    Last Updated: 05/17/2010

uimenu(MAddons,'Label','H-k Stacking Analysis','Tag','hk_m','Enable','off','Callback',{@hk_Callback});