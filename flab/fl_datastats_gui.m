function fl_datastats_gui(Datastats)
%FL_DATASTATS_GUI Display dataset statistics
%   FL_DATASTATS_GUI(Datastats)  displays the dataset statistics in a
%   figure window.  This text is not editable.

%   Author: Kevin C. Eagar
%   Date Created: 01/22/2008
%   Last Updated: 02/05/2008

DataGui = dialog ('Name','Dataset Statistics','Resize','off','NumberTitle','off','Units','characters','WindowStyle','modal',...
    'Position',[0 0 120 50],'CreateFcn',{@movegui_kce,'center'});
uicontrol ('Parent',DataGui,'Style','listbox','Units','characters','String',Datastats,...
    'Position',[1 4 118 45],'BackgroundColor',[1 1 1],'FontName','FixedWidth','FontUnits','normalized','FontSize',0.0225);
uicontrol ('Parent',DataGui,'Style','pushbutton','Units','characters','String','Ok',...
    'Position',[50 1 20 2.25],'BackgroundColor',[1 1 1],'FontName','Times','FontUnits','normalized','FontSize',0.4,'Callback','close(gcf)');
