% Sub-Gui of holoViewer, only intended to be used with holoViewer

%    Copyright (C) 2011 Matt Beals and Jacob P. Fugal
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

%    Version History
%
%    12/2011 Made an individual GUI accessible from the toolbar of
%    holoViewer --mjbeals

%   Latest Revision:
%   $Author: jpfugal $
%   $LastChangedDate: 2012-01-31 12:55:30 -0500 (Tue, 31 Jan 2012) $
%   $Rev: 212 $
function varargout = reconstructionSettings(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @reconstructionSettings_OpeningFcn, ...
                   'gui_OutputFcn',  @reconstructionSettings_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before reconstructionSettings is made visible.
function reconstructionSettings_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

handles.cfg               = varargin{1}.cfg;
handles.PropagationEngine = varargin{1}.PropagationEngine;
handles.originalImage     = varargin{1}.originalImage;
handles.Plot              = varargin{1}.Plot;
handles.m=1;            %Units
handles.mm=1e-3;
handles.um=1e-6;

handles = updatePanels(handles);
handles = updateResolution(handles);

handles.listeners{1} =  handles.cfg.addlistener('zMaxForRes','PostSet',@(obj,event)updateResolution(handles));
handles.listeners{2} =  handles.cfg.addlistener('dx','PostSet',@(obj,event)updateDX(handles));
handles.listeners{3} =  handles.cfg.addlistener('dy','PostSet',@(obj,event)updateDY(handles));
handles.listeners{4} =  handles.cfg.addlistener('lambda','PostSet',@(obj,event)updateWavelength(handles));
handles.listeners{5} =  handles.PropagationEngine.addlistener('gpuDeviceNum','PostSet',@(obj,event)updateGPU(handles));
handles.listeners{6} =  handles.cfg.addlistener('path','PostSet',@(obj,event)updatePath(handles));
handles.listeners{7} =  handles.PropagationEngine.addlistener('should_gpu','PostSet',@(obj,event)useGPU(handles));

guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = reconstructionSettings_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

function reconstructionSettings_CloseRequestFcn(hObject, eventdata, handles)
cellfun(@(object)object.delete,handles.listeners);
handles.listeners = {};
delete(hObject);


function handles = updatePanels(handles)
updateDX(handles);   
updateDY(handles);
updateWavelength(handles);
updateGPU(handles);
useGPU(handles);
updatePath(handles); 
   
function handles = updateResolution(handles)
minFeature = 2.44*handles.cfg.lambda*handles.PropagationEngine.zMaxForRes/...
                      sqrt(prod(handles.originalImage.size)*handles.cfg.DX*handles.cfg.DY);
                  
set(handles.minFeature,'String',sprintf('%6.4g ', minFeature/handles.um));        
set(handles.zmax,'String',sprintf('%6.4g ',handles.PropagationEngine.zMaxForRes/handles.mm));  



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
function dx_Callback(hObject, eventdata, handles)
num = get(hObject,'String');    
if regexp(num,'^@')
    string = num;
    handles.PropagationEngine.dx = str2func(string);
    display('Warning: disable image caching if using dynamic frequency domain filters');
else
    num = str2double(num);
    if (num >= 0) && isfinite(num)
        handles.PropagationEngine.dx = num*1e-6;
        string = sprintf('%6.4g ',num);
    end   
end
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function dx_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function updateDX(handles)
if isa(handles.cfg.dx,'function_handle')
   set(handles.dx, 'String',  ['@' func2str(handles.cfg.dx)]);  
else
   set(handles.dx, 'String',  sprintf('%6.4g ',handles.cfg.dx*1e6)); 
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
function dy_Callback(hObject, eventdata, handles)
num = get(hObject,'String');    
if regexp(num,'^@')
    string = num;
    handles.PropagationEngine.dy = str2func(string);
    display('Warning: disable image caching if using dynamic frequency domain filters');
else
    num = str2double(num);
    if (num >= 0) && isfinite(num)
        handles.PropagationEngine.dy = num*1e-6;
        string = sprintf('%6.4g ',num);
    end   
end
guidata(hObject,handles);


function dy_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function updateDY(handles)
if isa(handles.cfg.dy,'function_handle')
   set(handles.dy, 'String',  ['@' func2str(handles.cfg.dy)]);  
else
   set(handles.dy, 'String',  sprintf('%6.4g ',handles.cfg.dy*1e6)); 
end 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
function wavelength_Callback(hObject, eventdata, handles)
num = str2double(get(hObject,'String'));
if (num >= 0) && isfinite(num)
    handles.PropagationEngine.lambda = num*1e-9;
end
guidata(hObject,handles);

function wavelength_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function updateWavelength(handles)
set(handles.wavelength,'String',sprintf('%6.4g ',handles.cfg.lambda*1e9));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
function gpumenu_Callback(hObject, eventdata, handles)
handles.PropagationEngine.gpuDeviceNum = get(hObject,'Value');
guidata(hObject, handles);

function gpumenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function updateGPU(handles)
if handles.PropagationEngine.numDevices < 2
    set(handles.gpumenu,'Style','Text');
    set(handles.gpumenu,'String',handles.PropagationEngine.gpuDeviceNum);
else
    set(handles.gpumenu,'String',num2cell(1:handles.PropagationEngine.numDevices));
    set(handles.gpumenu,'Value',handles.PropagationEngine.gpuDeviceNum);
end


function useGPU(handles)
if handles.PropagationEngine.should_gpu
    set(handles.gpumenu,'Enable','on');
else
    set(handles.gpumenu,'Enable','off');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
function path_Callback(hObject, eventdata, handles)
p = get(hObject,'String'); 
if exist(p,'dir')
    handles.cfg = config(p);
    set(handles.path,'String',p);
end
guidata(hObject,handles);

function path_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function updatePath(handles)
set(handles.path,'String',handles.cfg.path);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
function openPath_Callback(hObject, eventdata, handles)
p = uigetdir;
if exist(p,'dir')
    handles.cfg = config(p);
    set(handles.path,'String',p);
end
guidata(hObject,handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
function zmax_Callback(hObject, eventdata, handles)
num = str2double(get(hObject,'String'));
if (num >= 0) && isfinite(num)
    handles.PropagationEngine.zMaxForRes = num*handles.mm;
end
guidata(hObject, handles);

function zmax_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function updateZmax(handles)
set(handles.zmax,'String',sprintf('%6.4g ',handles.cfg.zMaxForRes/handles.mm));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
function minFeature_Callback(hObject, eventdata, handles) %#ok<*INUSL,*DEFNU>
num = str2double(get(hObject,'String'));
if (num >= 0) && isfinite(num)
    minFeature = num*handles.um;
end
handles.PropagationEngine.zMaxForRes = minFeature*sqrt(prod(handles.originalImage.size)*handles.cfg.DX*handles.cfg.DY)/ ...
                                       (2.44*handles.cfg.lambda);
guidata(hObject, handles);

function minFeature_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function updateMinFeature(handles)
minFeature = 2.44*handles.cfg.lambda*handles.cfg.zMaxForRes/...
                      sqrt(prod(handles.originalImage.size)*handles.cfg.DX*handles.cfg.DY);
set(handles.minFeature,'String',sprintf('%6.4g ', minFeature/handles.um));

