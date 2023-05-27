%    HoloViewer, a MATLAB GUI program to reconstruct and view
%    reconstructions of digital holograms.
%
%    The intended use is to start holoViewer in a directory or pointing it
%    to a directory with a series of hologram files. Such as:
%
%    >> cd c:/hologram_directory
%    >> holoViewer
%
%    or simply call 
%
%    >> holoViewer('c:/hologram_directory')
%
%    One can also call for the included .png file is:
%
%    holoViewer('dx',4.65e-6,'dy',4.65e-6,'wavelength',532e-9,'imagepath','./two_particles.png')
%
%    Where the pixel size (sample spacing) of the image is 4.65 um, and
%    the wavelength is 532 nm. One can also call with an image variable:
%
%    im = imread('./two_particles.png');
%    holoViewer('dx',4.65e-6,'dy',4.65e-6,'wavelength',532e-9,'image',im)
%

%    Copyright (C) 2011 Jacob P. Fugal and Matt Beals
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%    When using this program as part of research that results in
%    publication, acknowledgement is appreciated. The following citation is
%    appropriate to include: 
%
%    Fugal, J. P., T. J. Schulz, and R. A. Shaw, 2009: Practical methods
%    for automated reconstruction and characterization of particles in
%    digital inline holograms, Meas. Sci. Technol., 20, 075501,
%    doi:10.1088/0957-0233/20/7/075501.  
%
%    Funding for development of holoViewer at Michigan Tech (Houghton,
%    Michigan, USA) provided by the US National Science Foundation (US-NSF)
%    Graduate Research Fellowship Program, and NASA's Earth Science
%    Fellowship Program. Funding for development at the National Center for
%    Atmospheric Research (NCAR, Boulder, Colorado, USA) provided by the
%    US-NSF. Funding for development at the Max Planck Institute for
%    Chemistry (MPI-Chemistry, Mainz, Germany) and the Johannes Gutenberg
%    University of Mainz (Uni-Mainz, Mainz, Germany), provided by
%    MPI-Chemistry, the US-NSF, and the Deutsche Forschungsgesellschaft
%    (DFG, the German Science Foundation). 
%
%    Please address questions or bug reports to Jacob Fugal or to Matthew
%    Beals at fugalscientific (at) gmail (dot) com or mjbeals (at) mtu
%    (dot) edu respectively
%
%    Version History
%    04/2005--holoViewer written by Jacob Fugal at Michigan Tech University,
%    Physics Department.
%    10/2006--Features added to find particles inside the holograms
%    reconstructions again by Jacob Fugal at MTU. 
%    05/2007--Final features added to look at gradients in the
%    reconstructions to test for ice particle image sharpness, by Jacob
%    Fugal at MTU.
%    
%    01/2011--Layout and program completely redone to clean up, simplify the code and
%    make it more user friendly and more carefully commented, and have GPU
%    computation capability, by Jacob Fugal at MPI-Chemistry, Mainz, Germany.
%
%    05/2011--Framework reworked to abstract reconstruction and filtering
%    making HoloViewer a wrapper for a pluggable hologram reconstruction
%    package.  Added enhanced functionality to store and restore present
%    state by means of config files and made program file system aware, and
%    able to step through series of holograms located on disk. -- mjbeals
%
%    12/2011--GUI and functional layout redone to put most of the
%    functionality in a toolbar and popup guis. Bigger screen leftover for
%    results. --mjbeals
%
%   Latest Revision:
%   $Author: mjbeals $
%   $LastChangedDate: 2012-02-26 13:46:54 -0500 (Sun, 26 Feb 2012) $
%   $Rev: 218 $

function varargout = holoViewer(varargin)
% HOLOVIEWER MATLAB code for holoViewer.fig
%      HOLOVIEWER, by itself, creates a new HOLOVIEWER or raises the existing
%      singleton*.
%
%      H = HOLOVIEWER returns the handle to a new HOLOVIEWER or the handle to
%      the existing singleton*.
%
%      HOLOVIEWER('CALLBACK',hObject,~,handles,...) calls the local
%      function named CALLBACK in HOLOVIEWER.M with the given input arguments.
%
%      HOLOVIEWER('Property','Value',...) creates a new HOLOVIEWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before holoViewer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to holoViewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help holoViewer

% Last Modified by GUIDE v2.5 26-Feb-2012 12:40:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @holoViewer_OpeningFcn, ...
                   'gui_OutputFcn',  @holoViewer_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1}) && ~any(regexp(varargin{1},'\\|/|\:'))
   gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before holoViewer is made visible.
function holoViewer_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% ~  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to holoViewer (see VARARGIN)

%initialze the object to hold our images
handles.originalImage = img();
handles.originalImage.filter_handle = 'prefilters';

handles.reconImage = img();
handles.reconImage.filter_handle = 'postfilters';


handles.Plot = showimage(handles.reconImage);
handles.Plot.image_mode    = 'amplitude';
handles.Plot.figure_handle = handles.figure1;

%initialize our Propagation Engine
handles.PropagationEngine = Propagator(1);

%If we are only passing one (or less) args, then see if it is a config
if isempty(varargin)
    handles.cfg = config();
    if ~isempty(handles.cfg.current_holo)
        handles.originalImage.raw_image = handles.cfg.full_holo_path;
    else
        error('An ''imagePath'' or ''image'' argument is required.')
    end
elseif exist(varargin{1},'file')
   handles.cfg = config(varargin{1});
   if ~isempty(handles.cfg.current_holo)
        handles.originalImage.raw_image = handles.cfg.full_holo_path;
    else
        error('An ''imagePath'' or ''image'' argument is required.')
    end
else
   %Create blank config object
   handles.cfg = config();
    
       %Get the necessary arguments, chiefly the image
        index   = find(strcmpi(varargin,'imagePath')); % From a specified path
        if (index+1 <= length(varargin))
            %Tear apart the path to get the pieces
            [path filename extension] = fileparts(varargin{index+1});
            handles.cfg.path = path;
            handles.cfg.current_holo = [filename extension];
            handles.originalImage.raw_image = handles.cfg.full_holo_path;
        else                                            % Or from an image variable
            index   = find(strcmpi(varargin,'image'));
            if (index+1 <= length(varargin))
               handles.originalImage.raw_image = varargin{index+1};
            else
                error('An ''imagePath'' or ''image'' argument is required.')
            end
        end
end

 %Allow an image to be loaded along with a config file
 index   = find(strcmpi(varargin,'imagePath')); % From a specified path
 if (index+1 <= length(varargin))
            %Tear apart the path to get the pieces
            [path filename extension] = fileparts(varargin{index+1});
            handles.cfg.path = path;
            handles.cfg.current_holo  = [filename extension];
            handles.originalImage.raw_image = handles.cfg.full_holo_path;
 end

index   = find(strcmpi(varargin,'image'));
if (index+1 <= length(varargin))
    handles.originalImage.raw_image = varargin{index+1};
end


%give the image objects a reference to the new config object
handles.originalImage.config_handle     = handles.cfg;
handles.reconImage.config_handle        = handles.cfg;
handles.PropagationEngine.config_handle = handles.cfg;

%Allow setting other parameters via the command line
%Get the wavelength
index   = find(strcmpi(varargin,'wavelength'));
if (index+1 <= length(varargin))
    handles.cfg.lambda  = varargin{index+1};
    set(handles.wavelengthEdit, 'String', sprintf('%6.4g ',handles.cfg.lambda));
end

%Get the X and Y pixel pitch
index   = find(strcmpi(varargin,'dx'));
if(index+1 <= length(varargin))
    handles.cfg.dx  = varargin{index+1};
    set(handles.dxWidthEdit, 'String', sprintf('%6.4g ',handles.cfg.dx));
end

index   = find(strcmpi(varargin,'dy'));
if(index+1 <= length(varargin))
    handles.cfg.dy  = varargin{index+1};
    set(handles.dyWidthEdit, 'String', sprintf('%6.4g ',handles.cfg.dy));
end

index   = find(strcmpi(varargin,'GPU Device Num'));
if(index+1 <= length(varargin))
    handles.gpuDeviceNum  = varargin{index+1};
end

% Now go and initialize the panels and other variables if not done yet
if ~isfield(handles,'initializedOnce') || handles.initializedOnce
handles = initializeFirstTime(handles);
% End if initiated once
else % Or with a new image, initialize the variables that change image to image
    %[handles.Ny, handles.Nx] = handles.originalImage.size;
end % End if initiating after a new image

handles.reconImage.should_notify = false;

if handles.shouldApplyAutocontrast
    handles.reconImage.autoContrast;
end
handles.reconImage.should_notify = true;



if handles.cfg.zPos == 0
    handles.cfg.zPos = handles.cfg.zMin; 
else
updateRecon(handles);
end

% Refresh the handles
guidata(hObject,handles);


function handles = initializeFirstTime(handles)
handles.Panels = struct();
%----------------------------------------------
if isa(handles.cfg.dx,'function_handle') || isa(handles.cfg.dy,'function_handle')
    handles.originalImage.should_cache = false;
end

%----------------------------------------------
% Test for GPU presence and capability and if the GPU Device Number exists if given
if handles.PropagationEngine.should_gpu
   setGPUbutton(handles,'enable');
   setGPUbutton(handles,'on');
else
   setGPUbutton(handles,'disable');
   setGPUbutton(handles,'off');
end

%Initialize the image and some useful variables
handles.m=1;            %Units
handles.mm=1e-3;
handles.um=1e-6;

% handles.cfg.dz       = 1*handles.mm;
% handles.cfg.zPos        = 0*handles.mm;
handles             = updateZSlider(handles); %Update the ZSlider and edit boxes
handles.shouldBeep  = true;
handles.shouldApplyAutocontrast = false;
handles.initiatedOnce = true;


%-----------------------------
% Set up the hologram selection panel
handles = updateHoloList(handles);

%Advanced Features
handles.show_timing = false;

%set(handles.blacklistToggle,'Min',0,'Max',1);
handles.advancedPanels = struct();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Configure the listeners
%
%  The GUI acts as a front end to the underlying objects.  These listeners
%  listen for changes to be made to the objects, then call callback
%  functions accordingly.  Listener handles are divided by object name for
%  ease of access for future expansion
%

% config
% listen for the current Z position to change and update the needed parts
handles.listeners.config{1} = handles.cfg.addlistener('zPos','PostSet',@(obj,event)updateRecon(handles));
handles.listeners.config{2} = handles.cfg.addlistener('zPos','PostSet',@(obj,event)updateZSlider(handles));
handles.listeners.config{3} = handles.cfg.addlistener('path','PostSet',@(obj,event)updateHoloList(handles));

% original image
%no thresholding, enhancement or dilation is done on the input image, so we
%only need to listen for changes to the raw or filtered image
handles.listeners.originalImage{1} = handles.originalImage.addlistener('UpdateImage',...
                                     @(obj,event)updatePrecon(handles));
                                 
% Propagator
%listen for the generation of a new kernel and update the reconstuction
%when it happens
handles.listeners.propagator{1}  = handles.PropagationEngine.addlistener('Base_update', ...
                                     @(obj,event)updateRecon(handles));
                                 
                          
                                 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Outputs from this function are returned to the command line.
function varargout = holoViewer_OutputFcn(~, ~, handles)  
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% ~  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout = {handles};


function holoViewer_CloseFcn(~, ~, handles)  %#ok<*DEFNU>
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
                     ['Close ' get(handles.figure1,'Name') '...'],...
                     'Close and Save Config','Close and Discard Config','No','Close and Save Config');
if strcmp(selection,'No')
    return;
elseif strcmp(selection, 'Close and Save Config')
    handles.cfg.writefile;
end

panels = fields(handles.Panels);
for i=1:numel(panels)
    if ishandle(handles.Panels.(panels{i})), close(handles.Panels.(panels{i})); end
end


closereq;

function SaveConfig_callback(~,~,handles) 
    handles.cfg.writefile;
      
    
% --- Executes when figure1 is resized.
% The function enforces a minimum figure size, and adjusts the imagePlot
% field to fill the rest of the holoViewer figure
function holoViewer_ResizeFcn(~, ~, handles) 
set(handles.figure1,'Units','pixels');
% Get the positions
if isfield(handles,'Plot')
    figure_handle = handles.Plot.figure_handle;
    axes_handle   = handles.Plot.axes_handle;
else
    figure_handle = handles.figure1;
    axes_handle   = handles.imagePlot;
end

set(figure_handle,'Units','pixels');
figPos      = get(figure_handle, 'Position'); % of the whole holoViewer figure
axesPos     = get(axes_handle, 'Position'); % of the imagePLot

%Grab the positions of all of the controls
panelSPanel     = get(handles.zAxisPanel, 'Position');

% Find and set the new size of figure
minWidth    = panelSPanel(1) + panelSPanel(3);
minHeight   = panelSPanel(2) + panelSPanel(4)*4;
figPos      = [figPos(1:2) max(minWidth, figPos(3)) max(minHeight, figPos(4))];
set(figure_handle,'Position', figPos);

% Figure and set the new size of the imagePlot
axesPos(1)  = 60;
axesPos(2)  = panelSPanel(2) + panelSPanel(4) + 40;
newWidth    = figPos(3) - axesPos(1) - 10;
newHeight   = figPos(4) - axesPos(2) - 10;
axesPos     = [axesPos(1:2) newWidth newHeight];
set(axes_handle,'Position', axesPos);  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Z-Axis Panel Functions
%
%

% --- Executes on slider movement.
function zSlider_Callback(hObject, ~, handles) 
num = get(handles.zSlider, 'Value');
if isfinite(num)
    handles.cfg.zPos    = round(num/handles.cfg.dz)*handles.cfg.dz;
end
if handles.shouldBeep
    beep
end
guidata(hObject, handles);



function zMinEdit_Callback(hObject, ~, handles) 
num = str2double(get(hObject,'String'));
if isfinite(num) && num*handles.mm < handles.cfg.zMax;
    handles.cfg.zMin = num*handles.mm;
end
handles     = updateZSlider(handles);
guidata(hObject,handles);


function zMaxEdit_Callback(hObject, ~, handles) 
num = str2double(get(hObject,'String'));
if isfinite(num) && num*handles.mm > handles.cfg.zMin;
    handles.cfg.zMax = num*handles.mm;
end
handles     = updateZSlider(handles);
guidata(hObject,handles);


function zStepEdit_Callback(hObject, ~, handles) 
num = str2double(get(hObject,'String'));
if (num >= 0) && isfinite(num)
    handles.cfg.dz = num*handles.mm;
end
handles     = updateZSlider(handles);
guidata(hObject,handles);


function zPosEdit_Callback(hObject, ~, handles) 
num = str2double(get(hObject,'String'));
if isfinite(num)
    handles.cfg.zPos = num*handles.mm;
end
if handles.shouldBeep
    beep
end
handles = updateZSlider(handles);
guidata(hObject,handles);

function handles = updateZSlider(handles)
handles.cfg.dz = min(handles.cfg.dz, handles.cfg.zMax);
set(handles.zMinEdit,'String',sprintf('%6.4g ',handles.cfg.zMin/handles.mm));
set(handles.zMaxEdit,'String',sprintf('%6.4g ',handles.cfg.zMax/handles.mm));
set(handles.zPosEdit,'String',sprintf('%6.4g ',handles.cfg.zPos/handles.mm));
set(handles.zStepEdit,'String', sprintf('%6.4g ',handles.cfg.dz/handles.mm));
steps = get(handles.zSlider,'SliderStep');
steps(1) = handles.cfg.dz/abs(diff([handles.cfg.zMax handles.cfg.zMin]));
set(handles.zSlider, 'SliderStep', steps);
set(handles.zSlider, 'Min', handles.cfg.zMin, 'Max', handles.cfg.zMax);
set(handles.zSlider, 'Value', max(min(handles.cfg.zPos,handles.cfg.zMax), handles.cfg.zMin));


%%% Create Functions for Z-Axis Panel
function editBoxCreateFcn(hObject)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function zMaxResEdit_CreateFcn(hObject, ~, ~) 
editBoxCreateFcn(hObject);
function zMinEdit_CreateFcn(hObject, ~, ~) 
editBoxCreateFcn(hObject);
function zSlider_CreateFcn(hObject, ~, ~) 
editBoxCreateFcn(hObject);
function zMaxEdit_CreateFcn(hObject, ~, ~) 
editBoxCreateFcn(hObject);
function zStepEdit_CreateFcn(hObject, ~, ~) 
editBoxCreateFcn(hObject);
function zPosEdit_CreateFcn(hObject, ~, ~) 
editBoxCreateFcn(hObject);
function zMinResFeatText_CreateFcn(hObject, ~, ~) 
editBoxCreateFcn(hObject);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Hologram slider

% function handles = updateHoloSlider(handles)
% set(handles.holoslider, 'Min', 1);
% set(handles.holoslider, 'Value', handles.cfg.file_index);
% max = length(handles.cfg.hologram_list);
% 
% if max > 1
%     set(handles.holoslider, 'Max', max);
%     steps = [1 5] ./ (max -1);
%     set(handles.holoslider, 'SliderStep', steps);
% else
%     set(handles.holoslider, 'Max', 2);
%     enabled = get(handles.holoslider,'Enable');
%     if strcmp(enabled,'on'),set(handles.holoslider,'Enable','off');end
% end

function handles = updateHoloList(handles)
    if ~any(regexp(handles.cfg.path,'\.seq')) 
        set(handles.hologramList,'String',handles.cfg.pretty_file_list);
        set(handles.hologramList,'Value',handles.cfg.file_index);
        %set(handles.shouldBlacklist,'Value',handles.cfg.should_blacklist);
       % handles = updateHoloSlider(handles);
    end


% --------------------------------------------------------------------
% Menu Callback sets
% --------------------------------------------------------------------

% --------------------------------------------------------------------
function zStepPlus_Callback(~, ~, handles)
handles.cfg.zPos    = round(handles.cfg.zPos/handles.cfg.dz)*handles.cfg.dz +handles.cfg.dz;
handles     = updateZSlider(handles);
if handles.shouldBeep
    beep
end

% --------------------------------------------------------------------
function zStepMinus_Callback(~, ~, handles)
handles.cfg.zPos    = round(handles.cfg.zPos/handles.cfg.dz)*handles.cfg.dz -handles.cfg.dz;
handles         = updateZSlider(handles);
if handles.shouldBeep
    beep
end

% --------------------------------------------------------------------
function zStepInc_Callback(hObject, ~, handles)
expon   = floor(log10(handles.cfg.dz));
man     = log10(handles.cfg.dz) - expon;
possibilities   = log10([0.5 1 2 5 10 20]);
man     = interp1(possibilities, possibilities, man, 'nearest');
[~, ind]    = intersect(possibilities, man);
handles.cfg.dz   = 10^(possibilities(ind+1)+expon);
handles     = updateZSlider(handles);
guidata(hObject, handles);

% --------------------------------------------------------------------
function zStepDec_Callback(hObject, ~, handles)
expon   = floor(log10(handles.cfg.dz));
man     = log10(handles.cfg.dz) - expon;
possibilities   = log10([0.5 1 2 5 10 20]);
man     = interp1(possibilities, possibilities, man, 'nearest');
[~, ind]    = intersect(possibilities, man);
handles.cfg.dz   = 10^(possibilities(ind-1)+expon);
handles     = updateZSlider(handles);
guidata(hObject, handles);

% --------------------------------------------------------------------
function Open_Callback(~, ~, handles)
temp=pwd;
cd(handles.imageDir);
[file, path] = uigetfile({'*.png', 'PNG Image Files'; '*.*', 'All Files'},'Select a hologram');
cd(temp);
if ~isequal(file, 0)
    handles.cfg.path=path;
    handles.cfg.current_holo = file;
    handles.originalImage = img(fullfile(handles.cfg.path,handles.cfg.current_holo));
    %updateRecon(handles);
end

% --------------------------------------------------------------------
function Save_Callback(~, ~, handles)
[file, path] = uiputfile('*.png','Save image as...');
if file ~= 0
    imwrite(handles.reconImage.ampEnhanced, strcat(path,file));
end

function timing_callback(hObject, ~, handles)
    state = get(hObject,'Checked');
    if strcmpi(state,'on')
        set(hObject,'Checked','off');
        handles.show_timing = false;
    else
        set(hObject,'Checked','on');
        handles.show_timing = true;
    end
    guidata(hObject, handles);

% --------------------------------------------------------------------
function Print_Callback(~, ~, handles)
printdlg(handles.Plot.figure_handle)

% --------------------------------------------------------------------
function Close_Callback(~, ~, handles)
delete(handles.Plot.figure_handle)

% --------------------------------------------------------------------
function About_Callback(~, ~, ~)
msgbox(['' ...
    'Copyright (C) 2011 Jacob P. Fugal'...
    '                                                                '... 
    'This program is free software: you can redistribute it and/or modify '...
    'it under the terms of the GNU General Public License as published by '...
    'the Free Software Foundation, either version 3 of the License, or '...
    '(at your option) any later version.'...
    '                                                                '...
    'This program is distributed in the hope that it will be useful, '...
    'but WITHOUT ANY WARRANTY; without even the implied warranty of '...
    'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the '...
    'GNU General Public License for more details.'...
    '                                                                '...
    'You should have received a copy of the GNU General Public License '...
    'along with this program.  If not, see <http://www.gnu.org/licenses/>. '...
    '                                                                '...
    'When using this program as part of research that results in '...
    'publication, acknowledgement is appreciated. The following citation is '...
    'appropriate to include: '...
    '                                                                '...
    'Fugal, J. P., T. J. Schulz, and R. A. Shaw, 2009: Practical methods '...
    'for automated reconstruction and characterization of particles in '...
    'digital inline holograms, Meas. Sci. Technol., 20, 075501,'...
    'doi:10.1088/0957-0233/20/7/075501.'],'About . . . ');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%       Image Update and auxilliary functions
%

%---------------------
% Function called to update the current reconstruction of the hologram
%---------------------
function handles = updatePrecon(handles)
    handles.PropagationEngine.preconstruct(handles.originalImage.ampFiltered);
    handles.reconImage.ampMean = handles.PropagationEngine.meanim;
    handles.reconImage.ampSTD  = handles.PropagationEngine.stdim;
     
function handles = updateRecon(handles)
   
try
    if isempty(handles.PropagationEngine.FPrepped_FieldFFT)
        %if no reconstruction kernel exists, update it and exit.  The
        %update will trigger this callback to compute the slice.
        handles = updatePrecon(handles);
    else
        handles.reconImage.raw_image = handles.PropagationEngine.slice(handles.cfg.zPos);
    end
catch exception
    if strcmp(exception.identifier,'MATLAB:nomem')
        display('I''m giving her all she''s got sir.  Making room for the fft');
        %if we are out of memory, then clear out EVERYTHING we don't need
        handles.originalImage.should_cache = false;
        priorState = handles.reconImage.should_notify;
        handles.reconImage.should_notify = false;
        handles.reconImage.raw_image = [];
        handles.reconImage.should_notify = priorState;
        
        %Now try the reconstruction again
        try 
            if isempty(handles.PropagationEngine.FPrepped_FieldFFT)
                handles.reconImage.raw_image = handles.PropagationEngine.slice(handles.cfg.zPos,handles.originalImage.ampFiltered);
            else
                handles.reconImage.raw_image = handles.PropagationEngine.slice(handles.cfg.zPos);
            end
        catch exception2
           if strcmp(exception2.identifier,'MATLAB:nomem')
               display('I don''t have enough power Captain');
           end
           %rethrow(exception2);
        end
        
        %Now restore things.
        handles.originalImage.should_cache = true;
    else
        rethrow(exception);
    end
end   

% --- Executes on selection change in hologramList.
function hologramList_Callback(hObject, ~, handles)
new_hologram = get(hObject,'Value');
handles.cfg.current_holo = handles.cfg.findByIndex(new_hologram);
handles.PropagationEngine.clearCache;

handles.originalImage.raw_image = handles.cfg.full_holo_path;

if handles.shouldApplyAutocontrast
    handles.reconImage.autoContrast;
end
if handles.shouldBeep
    beep
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function hologramList_CreateFcn(hObject, ~, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on slider movement.
function holoSlider_Callback(hObject, ~, handles)
num = get(hObject, 'Value');
newholo = get(handles.hologramList,'Value');
if num < 0, newholo= newholo+1; else newholo= newholo-1; end
set(hObject, 'Value', 0);
set(handles.hologramList,'Value',newholo);
hologramList_Callback(handles.hologramList, [], handles);

function holoSlider_CreateFcn(hObject, ~, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in shouldBlacklist.
% function shouldBlacklist_Callback(hObject, ~, handles)
%   
% if (get(hObject, 'Value') == 1)
%     handles.cfg.should_blacklist = 1; 
% else
%     handles.cfg.should_blacklist = 0;
% end
% set(handles.hologramList,'String',handles.cfg.pretty_file_list);
% set(handles.hologramList,'Value',handles.cfg.file_index);
% guidata(hObject, handles);
 


% --- Executes on button press in blacklistToggle.
% function blacklistToggle_Callback(hObject, ~, handles) 
%     newValue = get(handles.blacklistToggle,'Value');
%     current_index = handles.cfg.file_index;
%     handles.cfg.blacklist = handles.cfg.updateBlacklist(handles.cfg.current_holo,newValue);
%     
%     %if blacklisting is enabled, we obvioulsy have to load a different
%     %hologram
%     if handles.cfg.should_blacklist == 1
%        num_holograms = length(handles.cfg.hologram_list);
%        if current_index > num_holograms, current_index = num_holograms;end
%        handles.cfg.current_holo = handles.cfg.findByIndex(current_index);
%        handles.originalImage.raw_image = handles.cfg.full_holo_path;
%        handles = updateHoloSlider(handles);     
%     end    
%     handles = updateHoloList(handles);
%     guidata(hObject, handles);

% --------------------------------------------------------------------
function Crop_Callback(hObject, ~, handles) %#ok<*INUSD>
    handles.PropagationEngine.clearCache;
    x = xlim; 
    y = ylim;
    
    [Nx Ny] = handles.originalImage.size;
    
    xx = handles.cfg.xx(Nx)/handles.um;
    yy = handles.cfg.yy(Ny)/handles.um;
    
    x_low = find(xx >= x(1), 1, 'first');
    x_high = find(xx <= x(2), 1, 'last');
                
    y_low = find(yy >= y(1), 1, 'first');
    y_high = find(yy <= y(2), 1, 'last');
    
    if ~mod(x_high-x_low,2)
        if x_low > 1, x_low = x_low - 1;else x_low = x_low +1; end
    end
    
    if ~mod(y_high-y_low,2)
        if y_low > 1, y_low = y_low - 1;else y_low = y_low +1; end
    end
    
    handles.originalImage.raw_image = handles.originalImage.raw_image(x_low:x_high, y_low:y_high);
   
   % handles.Plot.zoom.x = [0 1];
%     handles.Plot.zoom.y = [0 1];
    guidata(hObject,handles);
    

% --------------------------------------------------------------------
function crop_Callback(hObject, ~, handles)
handles.PropagationEngine.clearCache;
x = xlim;
y = ylim;

[Nx Ny] = handles.originalImage.size;

xx = handles.cfg.xx(Nx)/handles.um;
yy = handles.cfg.yy(Ny)/handles.um;

x_low = find(xx >= x(1), 1, 'first');
x_high = find(xx <= x(2), 1, 'last');

y_low = find(yy >= y(1), 1, 'first');
y_high = find(yy <= y(2), 1, 'last');

if ~mod(x_high-x_low,2)
    if x_low > 1, x_low = x_low - 1;else x_low = x_low +1; end
end

if ~mod(y_high-y_low,2)
    if y_low > 1, y_low = y_low - 1;else y_low = y_low +1; end
end

handles.originalImage.raw_image = handles.originalImage.raw_image(x_low:x_high, y_low:y_high);
guidata(hObject,handles);


% --------------------------------------------------------------------
function ImageMods_Callback(hObject, ~, handles)
% hObject    handle to ImageMods (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function uncrop_Callback(hObject, ~, handles)
handles.PropagationEngine.clearCache;
handles.originalImage.raw_image = handles.cfg.full_holo_path;
guidata(hObject,handles);


% --------------------------------------------------------------------
function advFilterPanel_Callback(hObject, ~, handles)
if ~isfield(handles.advancedPanels,'preimage') || ~ishandle(handles.advancedPanels.preimage.figure1)
    handles.advancedPanels.preimage = imagePanel(handles.originalImage);
end

if ~isfield(handles.advancedPanels,'postimage') || ~ishandle(handles.advancedPanels.postimage.figure1)
    handles.advancedPanels.postimage = imagePanel(handles.reconImage);
end
guidata(hObject, handles);


% --------------------------------------------------------------------
function  hologramMarking_ClickedCallback(hObject, ~, handles)
handles.advancedPanels.markers = marksPanel(handles.cfg);
guidata(hObject, handles);

% --------------------------------------------------------------------
function ParticleSelection_ClickedCallback(hObject, ~, handles)
handles.Panels.thresholdPanel = thresholds(handles);
guidata(hObject, handles);

% --------------------------------------------------------------------
function addDistanceTool_ClickedCallback(hObject, ~, handles)
handles.Plot.addDistance;
guidata(hObject, handles);

% --------------------------------------------------------------------
function filters_ClickedCallback(hObject, ~, handles)
handles.Panels.filtering = basicFiltering(handles);
guidata(hObject, handles);

% --------------------------------------------------------------------
function histogram_ClickedCallback(hObject, ~, handles)
 if ishandle(handles.Plot.histogram_figure)
    handles.Plot.histogram_figure = false;
else
    handles.Plot.histogram_figure = round(rand(1).*100);
end  
 guidata(hObject,handles);
 
% --------------------------------------------------------------------
function gpuToggle_OffCallback(hObject, ~, handles)
handles.PropagationEngine.should_gpu = 0;
guidata(hObject, handles);

% --------------------------------------------------------------------
function gpuToggle_OnCallback(hObject, ~, handles)
handles.PropagationEngine.should_gpu = 1;
guidata(hObject, handles);

function setGPUbutton(handles,state)
    %find the gpu button
    c = get(handles.toolbar,'Children');
    idx = arrayfun(@(h)strcmp(get(h,'Tag'),'gpuToggle'),c);
    handle = c(idx);
    
    if strcmpi(state,'enable')
        set(handle,'Enable','on');
    elseif strcmpi(state,'disable')
        set(handle,'Enable','off');
    elseif strcmpi(state,'on')
        set(handle,'State','on');
    elseif strcmpi(state,'off')
        set(handle,'State','off');
    end

% --------------------------------------------------------------------
function Reconstruction_ClickedCallback(hObject, ~, handles)
handles.Panels.reconstructionSettings = reconstructionSettings(handles);
guidata(hObject, handles);


% --------------------------------------------------------------------
function Beep_Callback(hObject, ~, handles)
if strcmpi(get(hObject,'Checked'),'on');
    handles.shouldBeep = false;
    set(hObject,'Checked','off');
else
    handles.shouldBeep = true;
    set(hObject,'Checked','on');    
end
guidata(hObject, handles);


function rotate_ClickedCallback(hObject, ~, handles)
    handles.Plot.rotate = ~handles.Plot.rotate;
guidata(hObject, handles);


% --------------------------------------------------------------------
function applyAutocontrast_Callback(hObject, ~, handles)
if strcmpi(get(hObject,'Checked'),'on');
    handles.shouldAutocontrast = false;
    set(hObject,'Checked','off');
else
    handles.shouldAutocontrast = true;
    set(hObject,'Checked','on');    
end
guidata(hObject, handles);


% --------------------------------------------------------------------
function amp_phase_hist_stats_Callback(~, ~, handles)
%amplitude
im    = handles.reconImage.ampEnhanced;
mnA   = mean(im(:));
stA   = std(im(:));
binsA = linspace(-15*stA,15*stA,1000)' +mnA;
nA = histc(im(:),binsA);

%phase
im    = handles.reconImage.phaseEnhanced;
mnP   = mean(im(:));
stP   = std(im(:));
binsP = linspace(-15*stP,15*stP,1000)' +mnP;
nP    = histc(im(:),binsP);
clear im;


function profiles_ClickedCallback(~,~, handles)
if ishandle(handles.Plot.profile_figure)
    handles.Plot.profile_figure = false;
else
    handles.Plot.profile_figure = 2;
end

