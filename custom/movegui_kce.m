function movegui_kce(varargin)
%MOVEGUI  Move gui figure to specified part of screen.
%    MOVEGUI(H, POSITION) moves the figure associated with handle H to
%    the specified part of the screen, preserving its size.
%
%    H can be the handle to a figure, or to any object within a figure
%    (for example, allowing a pushbutton uicontrol to move the figure
%    which contains it, from the pushbutton's function-handle
%    Callback.)
%
%    The POSITION argument can be any one of the strings:
%     'north'     - top center edge of screen
%     'south'     - bottom center edge of screen
%     'east'      - right center edge of screen
%     'west'      - left center edge of screen
%     'northeast' - top right corner of screen
%     'northwest' - top left corner of screen
%     'southeast' - bottom right corner of screen
%     'southwest' - bottom left corner of screen
%     'center'    - center of screen
%     'onscreen'  - nearest onscreen location to current position.
%
%    The POSITION argument can also be a two-element vector [H V],
%    where depending on sign, H specifies the figure's offset from the
%    left or right edge of the screen, and V specifies the figure's
%    offset from the top or bottom of the screen, in pixels:
%     H (for h >= 0) offset of left side from left edge of screen
%     H (for h < 0)  offset of right side from right edge of screen
%     V (for v >= 0) offset of bottom edge from bottom of screen
%     V (for v < 0)  offset of top edge from top of screen
%
%    MOVEGUI(POSITION) moves the GCBF or GCF to the specified
%    position.
%
%    MOVEGUI(H) moves the specified figure 'onscreen'.
%
%    MOVEGUI moves the GCBF or GCF 'onscreen' (useful as a
%    string-based CreateFcn callback for a saved figure, to ensure it
%    will appear onscreen when reloaded, regardless of its saved
%    position)
%
%    MOVEGUI(H, <event data>)
%    MOVEGUI(H, <event data>, POSITION) when used as a function-handle
%    callback, moves the specified figure to the default position, or
%    to the specified position, safely ignoring the automatically
%    passed-in event data struct.
%
%    Example:
%    This example demonstrates MOVEGUIs usefulness as a means of
%    ensuring that a saved GUI will appear onscreen when reloaded,
%    regardless of differences between screen sizes and resolutions
%    between the machines on which it was saved and reloaded.  It
%    creates a figure off the screen, assigns MOVEGUI as its CreateFcn
%    callback, then saves and reloads the figure:
%
%    	f=figure('position', [10000, 10000, 400, 300]);
%    	set(f, 'CreateFcn', 'movegui')
%    	hgsave(f, 'onscreenfig')
%    	close(f)
%    	f2 = hgload('onscreenfig')
%
%    The following are a few variations on ways MOVEGUI can be
%    assigned as the CreateFcn, using both string and function-handle
%    callbacks, with and without extra arguments, to achieve a variety
%    of behaviors:
%
%    	set(gcf, 'CreateFcn', 'movegui center')
%    	set(gcf, 'CreateFcn', @movegui)
%    	set(gcf, 'CreateFcn', {@movegui, 'northeast'})
%    	set(gcf, 'CreateFcn', {@movegui, [-100 -50]})
%
%    See also OPENFIG, GUIHANDLES, GUIDATA, GUIDE.

%   09/08/2007
%   This was modified from the original Matlab function to fit the needs of
%   the FuncLab package.  (Kevin C. Eagar)

%   Damian T. Packer 2-5-2000
%   Copyright 1984-2004 The MathWorks, Inc.
%   $Revision: 1.14.4.3 $  $Date: 2004/08/16 01:52:51 $

POSITIONS = {'north','south','east','west',...
        'northeast','southeast','northwest','southwest',...
        'center','onscreen'};

%error(nargchk(0, 3, nargin));
narginchk(0,3);
position = '';
fig = [];

for i=1:nargin
    numel = prod(size(varargin{i}));
    if ishandle(varargin{i}) & numel == 1
        fig = get_parent_fig(varargin{i});
        if isempty(fig)
            error('handle of figure or descendant required');
        end
    elseif isstr(varargin{i})
        position = varargin{i};
        if isempty(strmatch(position,POSITIONS,'exact'))
            error('unrecognized position');
        end
    elseif isnumeric(varargin{i}) & numel == 2
        position = varargin{i};
    elseif ~isempty(gcbo) & i==2
        continue; % skip past the event data struct, if in a callback
    else
        error('unrecognized input argument');
    end
end

if isempty(fig)
    fig = gcbf;
    if(isempty(fig))
        fig = gcf;
    end
end

if isempty(position)
    position = 'onscreen';
end

drawnow
%oldposmode = get(fig,'activepositionproperty');
oldfunits = get(fig, 'units');
set(fig, 'units', 'pixels');

wfudge = 0;
hfudge = 0;
oldpos = get(fig, 'outerposition');

if isunix
    oldpos = get(fig, 'position');
    if ~strcmp(get(fig,'XDisplay'),'nodisplay')
        % on unix, we can't rely on outerposition to place the figure
        % correctly.  use reasonable defaults and place using regular
        % position.  i call it fudge because it's just a guess. 
        wfudge =  6;
        hfudge = 24;

        if ~isempty(findall(fig,'type','uimenu'))
            hfudge = hfudge + 32;
        end

        numtoolbars = length(findall(fig,'type','uitoolbar'));
        if numtoolbars > 0
            hfudge = hfudge + 24 * numtoolbars;
        end
        
        oldpos(3) = oldpos(3) + wfudge;
        oldpos(4) = oldpos(4) + hfudge;
    end
end

fleft   = oldpos(1);
fbottom = oldpos(2);
fwidth  = oldpos(3);
fheight = oldpos(4);

old0units = get(0, 'units');
set(0, 'units', 'pixels');

% MODIFIED BY KEVIN EAGAR %
% To include the possibility of dual monitors
screensize = get(0, 'MonitorPosition');
switch size(screensize,1)
    case 1
        xadd = screensize(1);
        yadd = screensize(2);
        
        swidth = screensize(3);
        sheight = screensize(4);
        % make sure the figure is not bigger than the screen size
        fwidth = min(fwidth, swidth);
        fheight = min(fheight, sheight);

        % swidth - fwidth == remaining width
        rwidth  = swidth-fwidth;

        % sheight - fheight == remaining height
        rheight = sheight-fheight;
    case 2
        % Plots show up centered on Monitor 2
        xadd = screensize(2,1);
        yadd = screensize(1,2);
        
        swidth = screensize(2,3);
        sheight = screensize(2,4);
        % make sure the figure is not bigger than the screen size
        fwidth = min(fwidth, swidth);
        fheight = min(fheight, sheight);

        % swidth - fwidth == remaining width
        rwidth  = swidth-fwidth;

        % sheight - fheight == remaining height
        rheight = sheight-fheight;
    otherwise
        error ('More than 2 monitors detected.  Change this function in order to display')
end
% END MODIFICATION % 

set(0, 'units', old0units);

if isnumeric(position)
    newpos = position;
    if(newpos(1) < 0)	newpos(1) = rwidth + newpos(1); end
    if(newpos(2) < 0)	newpos(2) = rheight + newpos(2); end
else
    switch position
        case 'north',	newpos = [xadd+(rwidth/2), rheight]; % MODIFIED BY KEVIN EAGAR %
        case 'south',	newpos = [xadd+(rwidth/2), 0]; % MODIFIED BY KEVIN EAGAR %
        case 'east',	newpos = [xadd+rwidth, rheight/2]; % MODIFIED BY KEVIN EAGAR %
        case 'west',	newpos = [xadd, rheight/2]; % MODIFIED BY KEVIN EAGAR %
        case 'northeast',  newpos = [xadd+rwidth, rheight]; % MODIFIED BY KEVIN EAGAR %
        case 'southeast',  newpos = [xadd+rwidth, 0]; % MODIFIED BY KEVIN EAGAR %
        case 'northwest',  newpos = [xadd, rheight]; % MODIFIED BY KEVIN EAGAR %
        case 'southwest',  newpos = [xadd, 0]; % MODIFIED BY KEVIN EAGAR %
        case 'center',	newpos = [xadd+(rwidth/2), rheight/2]; % MODIFIED BY KEVIN EAGAR %
        case 'onscreen'
            % minimum edge margin
            margin = 30;

            if fleft < margin
                fleft = margin;
            end
            if fbottom < margin
                fbottom = margin;
            end
            if fleft > rwidth
                fleft = rwidth - margin;
            end
            if fbottom > rheight
                fbottom = rheight - margin;
            end
            newpos = [fleft, fbottom];
    end
end

newpos(3:4) = [fwidth, fheight];

if isunix
    % remove width and height adjustments added above
    newpos(3) = newpos(3) - wfudge;
    newpos(4) = newpos(4) - hfudge;
    set(fig, 'position', newpos);
else
    set(fig, 'outerposition', newpos);
end
set(fig, 'units', oldfunits);
% setting outposition on a figure sets the activepositionproperty
% to 'outerposition'. It needs to be reset here.
%set(fig, 'position', oldposmode);

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% Subfunctions
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% get_parent_fig
%
% This function gets the parent of the graphics object h.
%--------------------------------------------------------------------------
function h = get_parent_fig(h)
while ~isempty(h) & ~strcmp(get(h,'type'), 'figure')
    h = get(h, 'parent');
end