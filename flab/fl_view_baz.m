function fl_view_backazimuth(ProjectDirectory,CurrentRecords,TableName,FuncLabPreferences)
%FL_VIEW_BACKAZIMUTH Plot receiver functions vs. event backazimuth
%   FL_VIEW_BACKAZIMUTH (ProjectDirectory,CurrentRecords,TableName,
%   FuncLabPreferences) plots the radial and transverse receiver functions
%   in the input ensemble table ordered by event backazimuth.
%
%   Author: Kevin C. Eagar
%   Date Created: 04/19/2008
%   Last Updated: 05/15/2010

TimeMin = str2double(FuncLabPreferences{4});
TimeMax = str2double(FuncLabPreferences{5});
XInc = str2double(FuncLabPreferences{3});

% Sets the scaling on the wiggles. Ideally adjustable by user 
gain = 0.08;

BazMin = 0;
BazMax = 360;
count = 0;
for n = 1:size(CurrentRecords,1)
    if CurrentRecords{n,5} == 1
        count = count + 1;
        Baz(count) = CurrentRecords{n,22};
        if count > 1
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'eqr']);
            if length(TempAmps) ~= length(RRFAmps); RRFAmps(count,:) = interp1(TIME,TempAmps,RRFTime); else RRFAmps(count,:) = TempAmps; end
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'eqt']);
            if length(TempAmps) ~= length(TRFAmps); TRFAmps(count,:) = interp1(TIME,TempAmps,TRFTime); else TRFAmps(count,:) = TempAmps; end
        else
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'eqr']);
            RRFAmps(count,:) = TempAmps; RRFTime = TIME;
            [TempAmps,TIME] = fl_readseismograms([ProjectDirectory CurrentRecords{n,1} 'eqt']);
            TRFAmps(count,:) = TempAmps; TRFTime = TIME;
        end
    end
end

if count == 0; set(0,'userdata','Message: No active records in selected event.'); return; end
XTics = BazMin:XInc:BazMax;
Scale = (XTics(end) - XTics(1)) * gain;
RRFPos = zeros(size(RRFAmps,1),size(RRFAmps,2)+2);
RPosTime = [RRFTime(1);RRFTime;RRFTime(end)];
TRFPos = zeros(size(TRFAmps,1),size(TRFAmps,2)+2);
TPosTime = [TRFTime(1);TRFTime;TRFTime(end)];
for n = 1:count
    CPamp = max(RRFAmps(n,:));
    In = find(RRFAmps(n,:) >= 0);
    RRFPos(n,In+1) = RRFAmps(n,In);
    RRFPos(n,:) = Scale * RRFPos(n,:) / CPamp + Baz(n);
    RRFAmps(n,:) = Scale * RRFAmps(n,:) / CPamp + Baz(n);
    In = find(TRFAmps(n,:) >= 0);
    TRFPos(n,In+1) = TRFAmps(n,In);
    TRFPos(n,:) = Scale * TRFPos(n,:) / CPamp + Baz(n);
    TRFAmps(n,:) = Scale * TRFAmps(n,:) / CPamp + Baz(n);
end

fig = figure ('Name',[TableName ' - Receiver Functions'],'Units','characters','NumberTitle','off',...
    'WindowStyle','normal','MenuBar','figure','Position',[0 0 160 58],'Color',[1 1 1],'CreateFcn',{@movegui_kce,'center'});

s1 = axes('Parent',fig,'Units','characters','Position',[10 5 65 48]);
for n = 1:size(RRFPos,1)
     patch(RRFPos(n,:),RPosTime,[153/255 0 0],'EdgeColor','none')
    line(RRFAmps(n,:),RRFTime,'Parent',s1,'Color','k');
end
line(RRFAmps,RRFTime,'Parent',s1,'Color','k');
set(s1,'Box','on','Units','normalized','Color',[1 1 1],'YDir','reverse','TickDir','out','XTick',XTics);
axis(s1,[BazMin BazMax TimeMin TimeMax])
t1 = title(s1,'Radial RF');
yl = ylabel(s1,'Time (sec)');
xl1 = xlabel(s1,'Event Backazimuth (deg)');

s2 = axes('Parent',fig,'Units','characters','Position',[85 5 65 48]);
for n = 1:size(TRFPos,1) 
    patch(TRFPos(n,:),TPosTime,[153/255 0 0],'EdgeColor','none')
    line(TRFAmps(n,:),TRFTime,'Parent',s2,'Color','k');
end
line(TRFAmps,TRFTime,'Parent',s2,'Color','k');
set(s2,'Box','on','Units','normalized','Color',[1 1 1],'Ycolor',[1 1 1],'YDir','reverse','TickDir','out','XTick',XTics);
axis(s2,[BazMin BazMax TimeMin TimeMax])
t2 = title(s2,'Transverse RF');
xl2 = xlabel(s2,'Event Backazimuth (deg)');