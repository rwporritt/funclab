function setup_funclab
%SETUP_FUNCLAB Add paths for FuncLab m-files.
%   SETUP_FUNCLAB adds the paths for the funclab m-files in the top
%   directory and subdirectories "addons", "custom", "flab", "TOMOMODELS",
%   "utilities", and "VELMODELS".  The matlab search path should contain
%   the following directories:
%      funclabX.X/
%      funclabX.X/flab
%      funclabX.X/addons
%      funclabX.X/custom
%      funclabX.X/utilities
%      funclabX.X/TOMOMODELS
%      funclabX.X/VELMODELS
%
%   Since version 1.6.0 Rob Porritt has added a number of packages which
%   are distributed by other authors. Please thank them for releasing these
%   codes and buy them a beer if you ever meet them.
%      funclabX.X.X/cptcmap - allows the reading of GMT color palettes into
%      matlab (Kelly Kearney)
%      funclabX.X.X/m_map - a free replacement for the mapping toolbox
%      (Rich Pawlowicz)
%      funclabX.X.X/matTaup - TauP for calculating arrival information and
%      raypaths; originally by Crotwell and Owens, wrapped for Matlab by
%      Qin Li
%      funclabX.X.X/processRFmatlab - codes for the processing of receiver
%      functions from Iain Bailey
%      funclabX.X.X/IRIS-WS-2.0.18.jar - allows retrieval of data from
%      webservice enabled dataservers
%      
%
%   Any "Add-on" packages under the "addon" directory are added to the
%   paths as well.  FuncLab comes packaged with 3 add-ons preload.  These
%   are "hk" (for H-k stacking), "ccp" (for common conversion point
%   stacking), and "gccp" (for Gaussian-weighted common conversion point
%   stacking).  The search path should include the following directories as
%   well:
%      funclabX.X/addons/ccp
%      funclabX.X/addons/gccp
%      funclabX.X/addons/hk
%      funclabX.X/addons/ccpv2
%      funclabX.X/addons/rayp_baz_stack
%      funclabX.X/addons/visualizer
%      funclabX.X/addons/moho_manual_pick
%      funclabX.X/addons/moho_auto_pick
%
%   FuncLab preferences are added to the Matlab environment for GUI and
%   figure positions, fonts, and others.
%
%   This setup checks to see if you have the Mapping Toolbox, the Signal
%   Processing Toolbox, and Parallel Computing Toolbox installed in your version of Matlab.  If you do,
%   then you can take full advantage of all the functionality within the
%   FuncLab package.  If not, all of the processing functions will work,
%   but some of the graphics and other functions may not be available to
%   you.  FuncLab will then add the subdirectory "map_utilities" to
%   provide our home-grown m-files for use in any geographical%   applications.  The search path should then also contain the following
%   directory:
%      funclabX.X/map_utilities

%   Author: Kevin C. Eagar
%   Date Created: 05/06/2010
%   Last Updated: 11/12/2011 (KCE)
%   Last Updated: 10/02/2012 (MJF)(included check for newer matlab versions - read statement changed)
%   Last Updated: 07/18/2014  Rob Porritt - added Iain Baily's
%   processRFmatlab and matTaup
%[FuncLabPath,junk,junk,junk] = fileparts(mfilename('fullpath'));
%   Last updated: Oct 17th, 2014 (RWP)
%     toolboxes are no longer stored in lib where the mattaup and iris-ws
%     jar files were originally referenced. Now we'll make those
%     directories and copy the jar files there
%     If you are unable to write to the system files due to lack of admin
%     priviledges, you may be able to find a file in your home that is
%     something like ~/.Matlab{version}/classpath.txt
%     If this file does not exist, create it and put the full path to the
%     matTaup.jar and IRIS-WS-version.jar files
% Last update Dec 26th, 2016 - RWP
%     Updated version to 1.8.0. This includes substantial updates including a citations menu, moho manual picking, and cross section tools.2016

v = version;
%v = '7.1.0'
disp(['Your current Matlab version ' version])
if str2double(v(1:3)) < 7.0
    disp('Matlab Version 7.0 or greater is required for FuncLab to work properly. Sorry...')
    disp(' ')
    return
end

if str2double(v(1:3)) < 8.4
    disp('Warning, Matlab graphics changed after version R2014b, so visuals may be buggy.')
    disp('Continuing...')
end


%added to test for version 10/02/2012 MJF
if str2double(v(1:4)) < 7.12
    [FuncLabPath,junk,junk,junk] = fileparts(mfilename('fullpath'));
else
    [FuncLabPath,junk,junk] = fileparts(mfilename('fullpath'));
end
MapToolbox = ~license('test','map_toolbox');
SignalToolbox = ~license('test','signal_toolbox');
ParallelToolbox = ~license('test','distrib_computing_toolbox');

disp('----------------------------------------------------------------------')
%disp('FUNCLAB Version 1.5.3')  %11/12/2011: UPDATED VERSION NUMBER FROM 1.5.2 TO 1.5.3
%disp('FUNCLAB Version 1.5.4')  %10/02/2012: UPDATED VERSION NUMBER FROM 1.5.3 TO 1.5.4
%disp('FUNCLAB Version 1.7.0')  %07/18/2014: UPDATED VERSION NUMBER FROM 1.5.4 TO 1.6.0
%disp('FUNCLAB Version 1.7.1')  %04/07/2015: UPDATED VERSION NUMBER FROM 1.7.0 TO 1.7.1. Includes new add-on, Visualizer and more extensive colormap options
%disp('FuncLab Version 1.7.3') % 04/24/2015: Added GyPSuM model and m_map replacement of mapping toolbox
%disp('FuncLab Version 1.7.3') % 05/01/2015: m_map more fully implemented. Fix implemented in conversion of ray parameter. Compute menu option to fix current ray parameters. Matlab 8.5+ seems to use javaclasspath.txt rather than simply classpath.txt. Not necessary just yet, but check for parallel computing toolbox
%disp('FuncLab Version 1.7.4') % 5/02/2015: Finished a prototype CCPV2 for more intuitive CCP Stacking.
%disp('FuncLab Version 1.7.5') % 5/06/2015: CCPV2 finished. Depth mapping and 3D ray diagram implemented. New RFS can now be computed fully within Funclab. plus bug fixes
%disp('FuncLab Version 1.7.6') % 5/12/2015: Added sorting options in manual trace editing
%disp('Funclab Version 1.7.7') % 6/26/2015: Slew of updates
%disp('Funclab Version 1.7.8') % 6/23/2016: Adjustments to manual trace editing
%disp('Funclab Version 1.7.9') % 10/19/2016: New RF cross section tools under the view menu
%disp('Funclab Version 1.7.10') % 11/4/2016: Added manual moho picking addon
%disp('Funclab Version 1.8.0') % 12/26/2016: Added citations menu
%disp('Funclab Version 1.8.1') % 10/24/2017: Fixed bug in sorting trace edits and manual moho picking
disp('Funclab Version 1.8.2') % 9/19/2018: Fixed bugs in data downloading, hann taper, and nwus model

disp(' ')
%disp('Adding FuncLab1.5.3 receiver function seismic tools to your MATLAB paths')  %11/12/2011: UPDATED VERSION NUMBER FROM 1.5.2 TO 1.5.3
%disp('Adding FuncLab1.5.4 receiver function seismic tools to your MATLAB paths')  %10/02/2012: UPDATED VERSION NUMBER FROM 1.5.3 TO 1.5.4
%disp('Adding FuncLab1.7.0 receiver function seismic tools to your MATLAB paths')  %07/18/2014 UPDATED VERSION NUMBER FROM 1.5.4 to 1.6
%disp('Adding FuncLab1.7.7 receiver function seismic tools to your MATLAB paths') % 05/12/2015
%disp('Adding FuncLab1.7.8 receiver function seismic tools to your MATLAB paths') % 06/23/2016
%disp('Adding FuncLab1.7.9 receiver function seismic tools to your MATLAB paths') % 10/19/2016
%disp('Adding FuncLab1.7.10 receiver function seismic tools to your MATLAB paths') % 11/04/2016
%disp('Adding FuncLab1.8.0 receiver function seismic tools to your MATLAB paths') % 12/26/2016
%disp('Adding FuncLab1.8.1 receiver function seismic tools to your MATLAB paths') % 10/24/2017
disp('Adding FuncLab1.8.2 receiver function seismic tools to your MATLAB paths') % 9/19/2018

disp(' ')

if any([MapToolbox SignalToolbox ParallelToolbox])
    % 08/03/2011: ADDED PATHSEP AND FILESEP COMMAND TO WORK WITH MULTIPLE PLATFORMS
    addpath ( ['',...
        [FuncLabPath, filesep, 'map_utilities', pathsep],...
        ''] );
    v=ver;
    toolboxes = upper(char({v.Name}));
    disp('You do not have the Mapping Toolbox or Signal Processing Toolbox or Parallel Computing Toolbox,')
    disp('which are recommended for FuncLab.  Processing tools in FuncLab are still')
    disp('functional, but not all graphics will be ideal.  We have added our')
    disp('home-grown m-files to use in geographical applications within this package.')
    disp('As of version 1.7.3, we have added support for m_map, but without the high')
    disp('resolution coastlines and topography.')
    disp('Parallel computing is only added for use with the new CCPV2 add-on and is not required')
    disp(' ')
    disp('Your Matlab License has access to the following toolboxes:')
    disp(toolboxes)
else
    license('checkout','map_toolbox');
    license('checkout','signal_toolbox');
    license('checkout','distrib_computing_toolbox');
    disp('You have the Mapping, Signal Processing Toolbox, and Parallel computing toolboxes, which provide full')
    disp('access to all the functionality of the FuncLab package.')
end

% Add my custom matlab tools for i/o, signal correction, seismic structure
% array manipulation, plotting, basic utilities, and receiver function
% processing.
%--------------------------------------------------------------------------
% 08/03/2011: ADDED PATHSEP AND FILESEP COMMAND TO WORK WITH MULTIPLE PLATFORMS
addpath ( ['',...
    [FuncLabPath, pathsep],...
    [FuncLabPath, filesep, 'flab', pathsep],...
    [FuncLabPath, filesep, 'addons', pathsep],...
    [FuncLabPath, filesep, 'custom', pathsep],...
    [FuncLabPath, filesep, 'map_utilities', pathsep],...
    [FuncLabPath, filesep, 'map_data', pathsep],...
    [FuncLabPath, filesep, 'utilities', pathsep],...
    [FuncLabPath, filesep, 'TOMOMODELS', pathsep],...
    [FuncLabPath, filesep, 'VELMODELS', pathsep],...
    [FuncLabPath, filesep, 'processRFmatlab', pathsep],...
    [FuncLabPath, filesep, 'processRFmatlab', filesep, 'deconvolution', pathsep],...
    [FuncLabPath, filesep, 'processRFmatlab', filesep, 'depthmapping', pathsep],...
    [FuncLabPath, filesep, 'processRFmatlab', filesep, 'getinfo', pathsep],...
    [FuncLabPath, filesep, 'processRFmatlab', filesep, 'inout', pathsep],...
    [FuncLabPath, filesep, 'processRFmatlab', filesep, 'signalprocessing', pathsep],...
    [FuncLabPath, filesep, 'processRFmatlab', filesep, 'velmodels1D', pathsep],...
    [FuncLabPath, filesep, 'matTaup', filesep, 'matTaup',pathsep],...
    [FuncLabPath, filesep, 'cptcmap', pathsep],...
    [FuncLabPath, filesep, 'cptcmap',filesep,'cptfiles', pathsep],...
    [FuncLabPath, filesep, 'm_map', pathsep],...
    ''] );


%% Here we have a switch to determine how to add jar files to your matlab java path
%  This is great because Matlab is built on Java to be cross platform
%  However it is stupidly complex.
%  We need to set both the static and dynamic paths. Setting the dynamic
%  path will allow funclab to work immediately while setting the static
%  path allows the user to use funclab again without setting the dynamic
%  path.
%  Setting the dynamic path is easy, just use javaaddpath.
%  Setting the static path can be done in multiple ways. If the user has
%  admin control, they could do a system-wide setup, but generally we can't
%  rely on that. Therefore we'll use the preference directory (typically
%  ~/.matlab/R{year}{a/b}) and add the jar files to the file
%  javaclasspath.txt.

jarinstallmethod = 1;
if jarinstallmethod == 1
    % First update dynamic path
    javaaddpath([FuncLabPath, filesep, 'matTaup',filesep, 'matTaup', filesep, 'lib', filesep, 'matTaup.jar'],'-end');
    javaaddpath([FuncLabPath, filesep, 'matTaup',filesep, 'matTaup', filesep, 'lib', filesep, 'matTaup.jar'],'-end');
    javaaddpath([FuncLabPath, filesep, 'IRIS-WS-2.0.18.jar'],'-end');
    % Now add path to prefdir/javaclasspath.txt
    fid = fopen([prefdir, filesep, 'javaclasspath.txt'],'a+');
    fprintf(fid,'%s\n',[FuncLabPath, filesep, 'matTaup',filesep, 'matTaup', filesep, 'lib', filesep, 'matTaup.jar']);
    fprintf(fid,'%s\n',[FuncLabPath, filesep, 'matTaup',filesep, 'matTaup', filesep, 'lib', filesep, 'matTaupClasses.jar']);
    fprintf(fid,'%s\n',[FuncLabPath, filesep, 'IRIS-WS-2.0.18.jar']);
    fclose(fid);
    % Some version may have sourced just classpath.txt, so we'll add that
    % here too for good measure
    fid = fopen([prefdir, filesep, 'classpath.txt'],'a+');
    fprintf(fid,'%s\n',[FuncLabPath, filesep, 'matTaup',filesep, 'matTaup', filesep, 'lib', filesep, 'matTaup.jar']);
    fprintf(fid,'%s\n',[FuncLabPath, filesep, 'matTaup',filesep, 'matTaup', filesep, 'lib', filesep, 'matTaupClasses.jar']);
    fprintf(fid,'%s\n',[FuncLabPath, filesep], 'IRIS-WS-2.0.18.jar');
    fclose(fid);
    
elseif jarinstallmethod == 2
% matTaup
    matpath      = [matlabroot filesep 'toolbox' filesep 'matTaup' filesep ];
    %javaClasspath = textread(which('classpath.txt'),'%s','delimiter','\n','whitespace','');% eqivalent to  javaclasspath('-static')
%    if str2double(v(1:3)) >= 8.5
%        javaClasspathFile = which('javaclasspath.txt');
%    else
        javaClasspathFile = which('classpath.txt');
%    end
    javaClasspathFid = fopen(javaClasspathFile,'r');
    javaClassPathCell = textscan(javaClasspathFid,'%s');
    fclose(javaClasspathFid);
    javaClasspath = javaClassPathCell{1};
    isMatTaup     = strfind(javaClasspath,'matTaup');
    if all (cellfun('isempty',isMatTaup))
        installMatTaup  = 1;
    else
        installMatTaup=0;
    end
    matpath = strrep(matpath, [filesep 'matTaup'], '');%will be added from the .zip file
    isIrisWS = strfind(javaClasspath,'IRIS-WS');
    if all (cellfun('isempty',isIrisWS))
        installIrisWS = 1;
    else
        installIrisWS = 0;
    end
    
    

    if all([installMatTaup, ~(exist(matpath,'dir')==7)])
        linenumber = find (cellfun('isempty',isMatTaup));
        mkdir(matpath)
        disp(matpath)
    end
if installMatTaup
    disp('*******************************************')
    disp(' ')
    addpath(matpath, '-end');
    savepath
    disp('Updating static java classpath')
    disp('*******************************************')
    %clpath=which('classpath.txt');
%    if str2double(v(1:3)) >= 8.5
%        clpath = which('javaclasspath.txt');
%    else
        clpath = which('classpath.txt');
%    end
    disp(clpath)
    if ~(matpath(end)==filesep)
        matpath=[matpath filesep];
    end
    jfile = [matpath 'lib' filesep 'matTaup.jar'];
    jfiledir = [matpath 'lib' filesep];
    [success,~,~] = mkdir(jfiledir);
    if success == 0
        fprintf('Unable to create directory %s\nPlease add matTaup.jar and IRIS-WS jar file to your local path and update your classpath.txt file.\n',jfiledir)
        fprintf('Typically on a networked unix/linux/mac system: go to ~/.matlab/{version} and create a file called classpath.txt. Add the paths to this file and enjoy.\n');
        fprintf('Alternatively, you can setup a startup.m file in your home to add the java jar files at matlab startup.\n')
    else
        includedJarFile = ['matTaup' filesep 'matTaup' filesep 'lib' filesep 'matTaup.jar'];
        copyfile(includedJarFile,jfiledir);
        fid   = fopen(clpath,'a+');
        if fid==-1
            commandwindow
            error('FuncLab:Install',['Opening of classpath.txt failed.\n',...
                ' You need Root/Administrator privileges to change this file. \n',...
                ' Please contact your system administrator to add following line to \n',...
                ' ', strrep(clpath,'\','\\'), ':\n',...
                strrep(jfile,'\','\\') ])
        else
            fseek  (fid, 0, 'eof'); %go to end of file
            fprintf(fid,'%s\n',jfile);
            fclose(fid);
            disp('*******************************************')
        end
    end
end

if installIrisWS
    disp('*******************************************')
    disp(' ')
    addpath(matpath, '-end');
    savepath
    disp('Updating static java classpath')
    disp('*******************************************')
    %clpath=which('classpath.txt');
%    if str2double(v(1:3)) >= 8.5
%        clpath = which('javaclasspath.txt');
%    else
        clpath = which('classpath.txt');
%    end
    disp(clpath)
    if ~(matpath(end)==filesep)
        matpath=[matpath filesep];
    end
    jfile = [matpath 'lib' filesep 'IRIS-WS-2.0.18.jar'];
    jfiledir = [matpath 'lib' filesep];
    [success,~,~] = mkdir(jfiledir);
    if success == 0
        fprintf('Unable to create directory %s\nPlease add matTaup.jar and IRIS-WS jar file to your local path and update your classpath.txt file.\n',jfiledir)
    else
        copyfile('IRIS-WS-2.0.18.jar',jfiledir);
        fid   = fopen(clpath,'a+');
        if fid==-1
            commandwindow
            error('FuncLab:Install',['Opening of classpath.txt failed.\n',...
                ' You need Root/Administrator privileges to change this file. \n',...
                ' Please contact your system administrator to add following line to \n',...
                ' ', strrep(clpath,'\','\\'), ':\n',...
                strrep(jfile,'\','\\') ])
        else
            fseek  (fid, 0, 'eof'); %go to end of file
            fprintf(fid,'%s\n',jfile);
            fclose(fid);
            disp('*******************************************')
        end
    end
end

else
    
    disp('Please set jarinstallmethod flag to 1 or 2')
    keyboard
    
end

AddonPaths = dir([FuncLabPath, filesep, 'addons']); % 08/03/2011: ADDED FILESEP COMMAND TO WORK WITH MULTIPLE PLATFORMS
AddonNames = sortrows({AddonPaths(3:end).name}');
% AddonNames(strmatch('.DS_Store',AddonNames,'exact')) = []; % THIS IS A FIX FOR MAC SYSTEMS
AddonNames(strmatch('.DS_Store',AddonNames)) = []; % THIS IS A FIX FOR MAC SYSTEMS
if ~isempty(AddonNames)
    for n = 1:length(AddonNames)
        addpath(['',[FuncLabPath, filesep, 'addons', filesep ,AddonNames{n}, pathsep],'']); % 08/03/2011: ADDED PATHSEP AND FILESEP COMMAND TO WORK WITH MULTIPLE PLATFORMS
    end
end


% Pop up a wait message informing the user of the extra packages
tmpfig = figure('Name','Acknowledgements','Units','Pixels','Position',[560 300 560 600],'Color','white');
str1 = sprintf('The original package for database management of receiver functions was built by Kevin Eagar and Matt Fouch.\n\n');
str2 = sprintf('This updated version was modified by Rob Porritt to incorporate several community packages:\n\n');
str3 = sprintf('processRFmatlab - this package is for the computation of receiver functions built by Iain Baily and hosted on Github.\n\n');
str4 = sprintf('irisFetch.m and IRISWS.jar - these tools allow access to webservices hosted by various institutions. It was created and is hosted by the IRIS DMS\n\n');
str5 = sprintf('cptcmap.m - this code allows the user to load GMT color palette files into matlab. This code was written by Kelly Kearney and updated by Rob Porritt for GMT5 style .cpt files\n\n');
str6 = sprintf('matTaup - this java library allows the usage of TauP commands from within Matlab. The Matlab version is written by Qin Li as a wrapper to the original by Phillip Crotwell.\n\n');
str7 = sprintf('m_map - a free distribution for mapping from Rich Pawlowicz\n');
str8 = sprintf('TOMOMODELS - GyPSuM from Nate Simmons and colleagues');
str = [str1,str2,'1.',str3,'2.',str4,'3.',str5,'4.',str6, '5.', str7, '6.', str8];
uicontrol('Style','Edit','Parent',tmpfig,'Units','Normalized','Position',[0.2 0.2 0.6 0.7],'String',str,'FontSize',12,'BackgroundColor',[1 1 1],'Max',100,'Min',1);
waitbutton = uicontrol('Style','Pushbutton','Parent',tmpfig,'Units','Normalized','Position',[0.3 0.05 0.4 0.1],'String','Thanks!','FontSize',12,'Callback','gcbf.UserData=1; close');
waitfor(waitbutton,'Userdata');



set(0,'DefaultFigurePosition',[0 0 520 380])
set(0,'DefaultFigureCreateFcn',{@movegui_kce,'center'})
set(0,'DefaultAxesFontName','FixedWidth')
set(0,'DefaultAxesFontSize',14)
savepath
disp('----------------------------------------------------------------------')
