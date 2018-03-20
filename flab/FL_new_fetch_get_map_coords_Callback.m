%--------------------------------------------------------------------------
% %% Pop up a figure and allow the user to drag a rectangle on the figure
function FL_new_fetch_get_map_coords_Callback(cbo,eventdata,handles)

fullScreen = get(0,'ScreenSize');
coordinates = [1 1 1 1];
figHandles = figure('Tag','select_stations_figure');

%figPosition = [1 fullScreen(4)*2/3 fullScreen(3)/3 fullScreen(4)/3];
figPosition = [0.1 0.1 0.8 0.8];
%set(figHandles,'Position',figPosition,'Resize','on','Toolbar','Figure')
set(figHandles,'Units','Normalized','Position',figPosition,'Resize','on','Toolbar','Figure')

%h.panel(1) = uipanel('Parent',figHandles,'Units','Pixel','Position',[5 5 figPosition(3)*.8 figPosition(4)-10],...
%     'Title','Drag to create station rectangle','Tag','select_stations_panel');
h.panel(1) = uipanel('Parent',figHandles,'Units','Normalized','Position',[0.0 0.0 0.8 1],...
     'Title','Drag to create station rectangle','Tag','select_stations_panel');


load('FL_coasts.mat');
load('FL_stateBoundaries.mat');
load('FL_plates.mat');
ax = axes('Parent',h.panel(1),'Tag','station_finder_axes');
plot(ax,ncst(:,1),ncst(:,2),'k',stateBoundaries.longitude, stateBoundaries.latitude,'k', PBlong, PBlat, 'b');
axis([-180 180 -90 90]);
 



uicontrol('Parent',figHandles,'Units','Normalized',...
    'Position',[0.81 0.9 0.18 0.10],...
    'String','Confirm', 'Tag', 'confirm_station_select_button','Callback',{@confirm_station_select_button_Callback});
    
uicontrol('Parent',figHandles,'Units','Normalized',...
    'Position',[0.81 0.8 0.18 0.10],...
    'String','Clear', 'Tag', 'clear_station_select_button','Callback',@clear_station_select_button_Callback);

uicontrol('Parent',figHandles,'Units','Normalized',...
    'Position',[0.81 0.70 0.18 0.10],...
    'String','Cancel', 'Tag', 'cancel_station_select_button','Callback',@cancel_station_select_button_Callback);

uicontrol('Parent',figHandles,'Units','Normalized',...
    'Position',[0.81 0.6 0.18 0.10],...
    'String','New Rectangle', 'Tag', 'new_rectanglestation_select_button','Callback',@new_rectangle_station_select_button_Callback);


% rect = getrect(ax); % returns [xmin ymin width height]
% % rearrange to [lonmin lonmax latmin latmax]
% coordinates(3) = rect(1);
% coordinates(1) = rect(2);
% coordinates(4) = rect(1) + rect(3);
% coordinates(2) = rect(2) + rect(4);
% 
% 
% % now make a patch overlay
% patch([coordinates(3), coordinates(3), coordinates(4), coordinates(4), coordinates(3)],...
%       [coordinates(1), coordinates(2), coordinates(2), coordinates(1), coordinates(1)],...
%       [153 0 0]/255,'Tag','station_region_patch',...
%       'FaceAlpha',0.5, 'Parent',ax);
% 
% set(figHandles,'UserData',coordinates);
  
% uicontrol('Parent',figHandles,'Units','Pixel',...
%     'Position',[figPosition(3)*0.8+10 figPosition(4)*.85 figPosition(3)*0.17 figPosition(4)*.1],...
%     'String','Confirm', 'Tag', 'confirm_station_select_button','Callback',{@confirm_station_select_button_Callback});
%     
% uicontrol('Parent',figHandles,'Units','Pixel',...
%     'Position',[figPosition(3)*0.8+10 figPosition(4)*.75 figPosition(3)*0.17 figPosition(4)*.1],...
%     'String','Clear', 'Tag', 'clear_station_select_button','Callback',@clear_station_select_button_Callback);
% 
% uicontrol('Parent',figHandles,'Units','Pixel',...
%     'Position',[figPosition(3)*0.8+10 figPosition(4)*.65 figPosition(3)*0.17 figPosition(4)*.1],...
%     'String','Cancel', 'Tag', 'cancel_station_select_button','Callback',@cancel_station_select_button_Callback);
% 
% uicontrol('Parent',figHandles,'Units','Pixel',...
%     'Position',[figPosition(3)*0.8+10 figPosition(4)*.45 figPosition(3)*0.17 figPosition(4)*.1],...
%     'String','New Rectangle', 'Tag', 'new_rectanglestation_select_button','Callback',@new_rectangle_station_select_button_Callback);
%--------------------------------------------------------------------------


function new_rectangle_station_select_button_Callback(cbo, eventdata)

figHandles = findobj('Tag','select_stations_figure');
patchHdls = findobj('Tag','station_region_patch');
set(patchHdls,'Visible','off');

rect = getrect(figHandles); % returns [xmin ymin width height]
% rearrange to [lonmin lonmax latmin latmax]
coordinates(3) = rect(1);
coordinates(1) = rect(2);
coordinates(4) = rect(1) + rect(3);
coordinates(2) = rect(2) + rect(4);


% now make a patch overlay
patch([coordinates(3), coordinates(3), coordinates(4), coordinates(4), coordinates(3)],...
      [coordinates(1), coordinates(2), coordinates(2), coordinates(1), coordinates(1)],...
      [153 0 0]/255,'Tag','station_region_patch','Visible','on',...
      'FaceAlpha',0.5); 

set(figHandles,'UserData',coordinates);


  
  
function confirm_station_select_button_Callback(cbo,eventdata)
% Can I store this vector in the pushbutton userdata?
figHdls = findobj('Tag','select_stations_figure');
coordinates = get(figHdls,'UserData');
hdl = findobj('Tag','new_fetch_get_map_coords_pb');
set(hdl,'Userdata',coordinates);
% And set as the strings/userdata to my edit boxes
hdl = findobj('Tag','new_fetch_lon_min_e');
set(hdl,'String',coordinates(3),'Userdata',coordinates(3));
hdl = findobj('Tag','new_fetch_lon_max_e');
set(hdl,'String',coordinates(4),'Userdata',coordinates(4));
hdl = findobj('Tag','new_fetch_lat_min_e');
set(hdl,'String',coordinates(1),'Userdata',coordinates(1));
hdl = findobj('Tag','new_fetch_lat_max_e');
set(hdl,'String',coordinates(2),'Userdata',coordinates(2));
hdl = findobj('Tag','select_stations_figure');
close(hdl)


function cancel_station_select_button_Callback(cbo, eventdata, handles)
hdl = findobj('Tag','select_stations_figure');
close(hdl)


function clear_station_select_button_Callback(cbo, eventdata, handles)
patchHdls = findobj('Tag','station_region_patch');
set(patchHdls,'Visible','off');
figHandles = findobj('Tag','select_stations_figure');
%rect = getrect(figHandles); % returns [xmin ymin width height]
% rearrange to [lonmin lonmax latmin latmax]
%coordinates(3) = rect(1);
%coordinates(1) = rect(2);
%coordinates(4) = rect(1) + rect(3);
%coordinates(2) = rect(2) + rect(4);
%patch([coordinates(3), coordinates(3), coordinates(4), coordinates(4), coordinates(3)],...
%      [coordinates(1), coordinates(2), coordinates(2), coordinates(1), coordinates(1)],...
%      [153 0 0]/255,'Tag','station_region_patch','Visible','on',...
%      'FaceAlpha',0.5); 
coordinates(1) = 0;
coordinates(2) = 0;
coordinates(3) = 0;
coordinates(4) = 0;
set(figHandles,'UserData',coordinates);
hdl = findobj('Tag','new_fetch_get_map_coords_pb');
set(hdl,'Userdata',coordinates);
% And set as the strings/userdata to my edit boxes
hdl = findobj('Tag','new_fetch_lon_min_e');
set(hdl,'String',coordinates(3),'Userdata',coordinates(3));
hdl = findobj('Tag','new_fetch_lon_max_e');
set(hdl,'String',coordinates(4),'Userdata',coordinates(4));
hdl = findobj('Tag','new_fetch_lat_min_e');
set(hdl,'String',coordinates(1),'Userdata',coordinates(1));
hdl = findobj('Tag','new_fetch_lat_max_e');
set(hdl,'String',coordinates(2),'Userdata',coordinates(2));
%--------------------------------------------------------------------------

