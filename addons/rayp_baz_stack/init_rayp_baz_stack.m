%INIT_RAYP_BAZ_STACK Initiates the ray parameter and back azimuth Stacking Add-on
%    INIT_RAYP_BAZ_STACK sets up the RAYP_BAZ Stacking Add-on GUI so that it can be used
%    from FuncLab.

%    Author: Robert W. Porritt
%    Date Created: Oct. 7th, 2014

uimenu(MAddons,'Label','Ray parameter and Back Azimuth Stacking','Tag','rayp_baz_stack_m','Enable','off','Callback',{@rayp_baz_stack_Callback});