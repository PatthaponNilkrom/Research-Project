%    Propagator class
%    A hologram propagation class
%
%    This class is designed to perform the task of hologram reconstruction.
%    It mainly serves to abstract the hardware specific nature of
%    reconstructing on CPU's versus GPU's.
%
%    The object is initialized by specifying a GPU number to run on.  If
%    this number is invalid (i.e. 0), or the GPU can not be initialized,
%    the object defaults to using the CPU instead.  GPU usage can also be
%    switched off (even if using the GPU is possible), by setting the
%    should_gpu flag to false.  Note:  it is not possible to enable GPU
%    processing if the GPU check fails.
%
%    As this is mainly an abstraction layer, the only properties the object
%    has are related to the GPU's and whether or not it should be used.  At
%    this time, the class only supports processing on one GPU at a time.
%    Multiple GPU capability may be supported in the future.
%
%    Also note that this code currently only contains 4 hard coded
%    reconstruction processes.  Two CPU (single/double) and 2 GPU
%    (single/double).  The ability to use custom routines without editing
%    the main code is planned for a future release.
%
%    Methods:
%
%    preconstruct(Field)
%               This  initializes the reconstruction.  Reconstruction
%               involves taking the FFT of the field and propagating that
%               field to different distances.  Since the initial FFT is a
%               constant (for a given input field), we cache it and some
%               other useful properties.  For GPU enabled computers, this
%               structure is left on the GPU, significantly decreasing file
%               transfer overhead.
%
%               Calling this function stores the updated FPrepped structure
%               inside the parent object, treating it as an internal cache.
%                In the event that dx or dy is a function handle (e.g. a
%                system with magnification), only the parts of FPrepped
%                that do not change with dx and dy are stored, forcing the
%                remaining parts to be updated on the fly
%
%    fieldOut = slice(zs,[field])
%               This method performs the propagation and generates the
%               output field (single or double complex) at each z distance
%               specified in the vector zs.  If run on a GPU, the array is
%               left on the GPU along with FPrepped.  If a field is
%               specified, preconsruct is run before processing.
%
%    ims =      farconstruct([field])
%               A handy method that reconstructs the field out to 1e6 and
%               2e6 meters (far beyond where any particles should lie, and
%               calculates the mean and standard deviation of the
%               background.  These values can be used to set the baseline
%               for thresholding later in post processing.
%
%
%
%    Copyright (C) 2011 Matthew Beals
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
%
%    Version History
%    05/2011 -- Code developed by Matthew Beals at Michigan Tech University
%    whie visiting MPI-Chemistry, Mainz, Germany in association with Jacob
%    Fugal (MPI-Chemistry) as an extension of the HoloViewer package
%    developed by Jacob Fugal.  For information on HoloViewer prior to this
%    release, please see the HoloViewer release notes.
%
%    Propagation algorithms originally developed by Jacob Fugal for the
%    HoloViewer project.  Please see:
%
%    Fugal, J. P., T. J. Schulz, and R. A. Shaw, 2009: Practical methods
%    for automated reconstruction and characterization of particles in
%    digital inline holograms, Meas. Sci. Technol., 20, 075501,
%    doi:10.1088/0957-0233/20/7/075501.
%
%    For more information regarding the exact nature of the hologram
%    reconstruction technique.
%
%    Funding for development at Michigan Tech provided by the US National Science
%    Foundation Graudate Research Fellowship Program, and NASA's Earth
%    Science Fellowship Program. Funding for development at MPI-Chemistry,
%    provided by MPI-Chemistry, and the US-National Science Foundation.
%
%    Please address questions or bug reports to Matthew Beals at
%    mjbeals (at) mtu (dot) edu
%
%   Latest Revision:
%   $Author: mjbeals $
%   $LastChangedDate: 2012-03-05 11:22:18 -0500 (Mon, 05 Mar 2012) $
%   $Rev: 232 $


classdef Propagator < dynamicprops
   properties
      gpuD;
      numDevices;
   end
   
   properties  (SetObservable, AbortSet)
      dx =0;
      dy =0;
      lambda = 0;
      k;
      zMaxForRes = 0;
      should_cache  = true;
      should_gpu    = true;
      should_double = false;
      should_normalize = true;
      force_recache = false;
      config_handle;
      can_gpu    = false;
      can_double = false;
      gpuDeviceNum;
      meanim;
      stdim;
      
      freq_filter;
      FPrepped_FieldFFT;
      FPrepped_root;
      FPrepped_filter;
   end
   
   properties (GetAccess = public)
      listeners = cell(0);
      suppressed_warns = {'parallel:gpu:NoDriver' ...
         'parallel:gpu:InvalidDeviceID' ...
         'parallel:gpu:device:CouldNotLoadDriver' ...
         'parallel:gpu:device:DeviceCapability'};
   end
   
   events
      FieldFFT_update;
      Kernel_update;
      Base_update;
      newSlice_generated;
      UpdateValue;
   end
   
   %%%Constructor Method%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   methods
      function this = Propagator(GPU)
         if nargin > 0
            this.gpuDeviceNum = GPU;
         else
            this.gpuDeviceNum = 0;
         end
      
         this.registerListeners;
      end
      
       function loadobj(this)
          this.registerListeners;
          if this.should_gpu
              this.updateGPU;
              this.pushAll;
          end
              
       end

       function saveobj(this)
           this.unregisterListeners(this);
           this.pullAll;           
       end
       
      function registerListeners(this) 
         this.listeners.dx             = this.addlistener('dx','PostSet',@this.setPropEvent);
         this.listeners.dy             = this.addlistener('dy','PostSet',@this.setPropEvent);
         this.listeners.lambda         = this.addlistener('lambda','PostSet',@this.setPropEvent);
         this.listeners.zMaxForRes     = this.addlistener('zMaxForRes','PostSet',@this.setPropEvent);
         this.listeners.config_handle  = this.addlistener('config_handle','PostSet',@this.setPropEvent);
      end
      
      function unregisterListeners(this)
          names = fieldnames(this.listeners);
          for i= 1:numel(names)
              this.listeners.(names{i}).delete;
          end
      end
       
      function setPropEvent(this,src,evnt)
         notify(this,'UpdateValue',evnt);
         if ~isempty(this.FPrepped_FieldFFT)
            this.updateKernel;
         end
      end
      
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   methods
       
      function phi = phaseFactor(this,zs)
          phi = angle(exp(1j*this.k*zs));
      end
      %%%%%%%% method to reconstruct to a specified z position
      
      
      function fieldOut = slice(this, zs, field)
         %if we don't have a cached fft, calculate it on the fly
         if isempty(this.FPrepped_FieldFFT) || this.force_recache
            if nargin < 3, error('No cached fft.  Need a field to propagate');end
            this.preconstruct(field);
         end
         
         %if dx or dy is a function handle, we can't use the same cached
         %fprepped structure, but we can use pieces of it
         if isa(this.dx,'function_handle') || isa(this.dy,'function_handle')
            [Ny, Nx]    = size(this.FPrepped_FieldFFT);      % The field size
            
            %create the output array, in the correct format
            precision = 'single';
            if this.should_double && this.can_double, precision = 'double'; end
            
            if this.should_gpu
               fieldOut = gpuArray(nan([Ny Nx numel(zs)],precision));
            else
               fieldOut = nan([Ny Nx numel(zs)],precision);
            end
            
            %Since dx or dy change with z, we have to recompute them for
            %each slice which involves also remaking parts of FPrepped
            for cnt = 1:numel(zs)
               Dx = this.dx;
               Dy = this.dy;
               if isa(this.dx,'function_handle'), Dx = this.dx(zs(cnt)); end
               if isa(this.dy,'function_handle'), Dy = this.dy(zs(cnt)); end
               this.makeKernel(Dx, Dy);
               
               fieldOut(:,:,cnt) = this.HFFFTPropagate(zs(cnt));
            end
            
         else
            %if dx and dy are static... then just propagate the hologram
            fieldOut = this.HFFFTPropagate(zs);
         end
         
         if this.should_normalize
             for i=1:numel(zs)
              phi = this.phaseFactor(zs(i));
              fieldOut(:,:,i) = fieldOut(:,:,i).*exp(-1j*phi);
             end
         end
         
         if ~this.should_cache, this.clearCache; end
         
         notify(this, 'newSlice_generated');
         
      end
      
      
      %%%%%%%% Method to generate pre-reconstruted field for faster
      %%%%%%%% processing
      function preconstruct(this, Field)
         %determine if the new field is the same size as the old one (to
         %determine if we need to remake the kernel)
         if ~all(size(Field) == size(this.FPrepped_FieldFFT))
            remakeKernel = true;
         else
            remakeKernel = false;
         end
         
         this.updateFFT(Field);
         
         
         if remakeKernel
            this.updateKernel;
         else
            notify(this,'Base_update');
         end
         this.farconstruct;
      end
      

      %%%%%%%% This method reconstructs the field out a long way to gather
      %%%%%%%% information about the noise field
      function farconstruct(this,field)
         zs = 1e6 * ([1 2]);
         
         %propagate the field
         if nargin == 2
            field = this.slice(zs, field);
         else
            field = this.slice(zs);
         end
         
         
         %calculate the amplitude of the field
         field = abs(field);
         
         %calculate the mean and standard deviation for each slice
         meanim = ones(1,size(field,3));
         stdim  = meanim;
         
         for cnt = 1:size(field,3)
            meanim(cnt) = gather(mean(mean(field(:,:,cnt))));
            stdim(cnt)  = gather(sqrt(mean(mean( (field(:,:,cnt) - meanim(cnt)).^2))));
         end
         
         %Calculate the mean of the mean and the mean of the std
         this.meanim = mean(meanim);
         this.stdim = mean(stdim);
         
      end
      
      function varargout = ampThresholds(this)
         if isempty(this.stdim) || isempty(this.meanim)
             this.farconstruct;
         end
         
         high  = this.config_handle.ampHighThresh * this.stdim + this.meanim;
         low   = this.config_handle.ampLowThresh  * this.stdim + this.meanim;
         
         if nargout < 2
            varargout{1} = [low high];
         elseif nargout == 2
            varargout{1} = low;
            varargout{2} = high;
         end
      end
      
      function vals = ampStatThresholds(this,vals)
         if isempty(this.stdim) || isempty(this.meanim)
             this.farconstruct;
         end 
         vals = (vals - this.meanim)./this.stdim;
      end
      
      
      function alignMem(this)
         if this.should_gpu
            this.pushAll;
         else
            this.pullAll;
         end
         
         if this.should_double
            if isa(this.FPrepped_FieldFFT,'single'), this.FPrepped_FieldFFT = double(this.FPrepped_FieldFFT); end
            if isa(this.FPrepped_filter,'single'), this.FPrepped_filter     = double(this.FPrepped_filter); end
         else
            if isa(this.FPrepped_FieldFFT,'double'), this.FPrepped_FieldFFT = single(this.FPrepped_FieldFFT); end
            if isa(this.FPrepped_filter,'double'), this.FPrepped_filter     = single(this.FPrepped_filter); end
         end
      end
      
      function send2gpu(this,var)
         try
            tmp = this.(var);
            this.(var) = [];
            this.(var) = gpuArray(tmp);
         catch exception
            if ~strfind(exception.identifier,'parallel:gpu')
               rethrow(exception);
            end
         end
      end
      
      function yoink(this,var)
         tmp = gather(this.(var));
         this.(var) = [];
         this.(var) = tmp;
      end
      
      function pullAll(this)
         this.yoink('FPrepped_FieldFFT');
         this.yoink('FPrepped_root');
         this.yoink('FPrepped_filter');
      end
      
      function pushAll(this)
         if ~strcmp(class(this.FPrepped_FieldFFT),'parallel.gpu.GPUArray')
            this.send2gpu('FPrepped_FieldFFT');
         end
         
         if ~strcmp(class(this.FPrepped_root),'parallel.gpu.GPUArray')
            this.send2gpu('FPrepped_root');
         end
         
         if ~strcmp(class(this.FPrepped_filter),'parallel.gpu.GPUArray')
            this.send2gpu('FPrepped_filter');
         end
      end
      
      %%%%%%%% Clear the FPrepped struct
      function clearCache(this)
         this.FPrepped_FieldFFT = [];
         this.FPrepped_root     = [];
         this.FPrepped_filter   = [];
      end
      
      function clearKernel(this)
         this.FPrepped_root = [];
         this.FPrepped_filter =[];
      end
      
      
      %%%%%%%% Clear the force recache flag
      function clearTrigger(this)
         this.force_recache = false;
      end
      
      %%%%%%%% handle syncing dx and dy between this and the config file
      function set.dx(this,value)
         this.dx = value;
         this.pushToConfig('dx',value);
      end
      
      function set.dy(this,value)
         this.dy = value;
         this.pushToConfig('dy',value);
      end
      
      function set.lambda(this,value)
         this.lambda = value;
         this.pushToConfig('lambda',value);
      end
      
      function set.zMaxForRes(this,value)
         this.zMaxForRes = value;
         this.pushToConfig('zMaxForRes',value);
      end
      
      %%%%%%%% Function to copy the value set to any parameter to the copy
      %%%%%%%% stored in config (if a config_handle is present).  This
      %%%%%%%% keeps the config object in sync and lets it broadcast the
      %%%%%%%% notifier that the value has changed
      function pushToConfig(this,parameter,value)
         if ~isempty(this.config_handle)
            this.config_handle.(parameter) = value;
         end
      end
      
      %%%%%%%% Dx and Dy get methods.  These determine whether they should
      %%%%%%%% return the local copy or the config copy of the variable
      function value = get.dx(this)
         if ~isempty(this.config_handle)
            value = this.config_handle.dx;
         else
            value = this.dx;
         end
      end
      
      function value = get.dy(this)
         if ~isempty(this.config_handle)
            value = this.config_handle.dy;
         else
            value = this.dy;
         end
      end
      
      function value = get.lambda(this)
         if ~isempty(this.config_handle)
            value = this.config_handle.lambda;
         else
            value = this.lambda;
         end
      end
      
      function value = get.zMaxForRes(this)
         if ~isempty(this.config_handle)
            value = this.config_handle.zMaxForRes;
         else
            value = this.zMaxForRes;
         end
      end
      
      function value = get.k(this)
         value = 2*pi/this.lambda;
      end
      
      %%%%%%%% Update the should_cache variable and clear the cache if we
      %%%%%%%% are disabling caching.
      function set.should_cache(this, value)
         this.should_cache = value;
         if ~value, this.clearCache; end
      end
      
   end
   
   
   methods (Static)
      function bool = toBool(value)
         % This converts the floats to bool if
         %needed.  Note: 0 = false and any other number = 1
         if islogical(value)
            bool = value;
         elseif isnumeric(value)
            bool = value ~=0;
         else
            error('Invalid value. Must be logical');
         end
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   methods
      %%%%%%%% this method determines the GPU capability of the machine
      %%%%%%%% and sets the object parameters accordingly
      function updateGPU(this)
         %if the object is set to use a GPU, run the tests
         if ~this.isMultipleCall && this.should_gpu
            %try to query the GPUs to get their info.  If no GPUs are
            %present, this will throw an exception.  If any exceptions
            %are thrown during this process, we assume that GPU
            %processing is not supported and switch over to CPU only
            try
               this.numDevices = gpuDeviceCount;
               warning('off','parallel:gpu:device:DeviceCapability');
               this.gpuD = gpuDevice(this.gpuDeviceNum);
               warning('on','parallel:gpu:device:DeviceCapability');
               
               if str2double(this.gpuD.ComputeCapability) < 1.3, ...
                     throw(MException('parallel:gpu:device:DeviceCapability','Compute Capability must be 1.3 or higher')); end
               this.can_gpu = true;
               
               if this.gpuD.SupportsDouble == true
                  this.can_double = true;
               else
                  this.can_double = false;
               end
               
            catch exception
               if ~any(strcmp(exception.identifier,this.suppressed_warns)) && this.gpuDeviceNum ~= 0
                  warning(exception.message);
               end
               %if something goes wrong initializing the GPU's, disable them
               this.numDevices = 0;
               this.gpuDeviceNum = 0;
               this.should_gpu = false;
               this.can_gpu    = false;
               this.can_double = true;
               this.gpuD = [];
            end
            
         else
            this.gpuD = [];
         end
         
      end
      
   end
   
   
   
   %%%%% Set and Get methods %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   methods
      function set.should_gpu(this,value)
         %Whenever should_gpu is changed, run the GPU check to make sure
         %the change is possible.  Note: updateGPU only actually does the
         %checking if we are turning on the GPU's.  This prevents an
         %infinite loop from forming here.viceCount;
         this.should_gpu = this.toBool(value);
         this.updateGPU();
         %also move any gpuArrays to the CPU
         this.alignMem;
      end
      
      function set.gpuDeviceNum(this,value)
         this.pullAll;
         this.gpuDeviceNum = value;
         this.updateGPU;
         this.alignMem;
      end
      
      function set.should_double(this,value)
         this.should_double = value;
         this.alignMem;
      end
      
   end
   
   %%%%%% Propogation Methods.... these do the work %%%%%%%%%%%%%%%%%%%%%%%%
   methods
      %%%%%%%% Method to update the field FFT
      function updateFFT(this, Field)
         
         %resize the image to make it FFT friendly
         if mod(size(Field,2),2), Field = Field(:,1:end-1); end
         if mod(size(Field,1),2), Field = Field(1:end-1,:); end
         
         if this.should_double && this.can_double
            %if we are using double precision, then use it
            Field = double(Field);
         else
            Field = single(Field);
         end
         
         
         %if we are using gpu's
         if this.should_gpu
            this.FPrepped_FieldFFT = gpuArray(Field);
         else
            this.FPrepped_FieldFFT = Field;
            clear Field;
         end
         
         %Do the FFT
         try
            this.FPrepped_FieldFFT = fft2(this.FPrepped_FieldFFT);
         catch exception
            %Sometimes the FFT doesn't work the first time.  As a
            %workaround, try it again if we get an 'unknown error'
            if strcmp(exception.identifier, 'parallel:gpu:fft:ExecFailed')
               this.FPrepped_FieldFFT = fft2(this.FPrepped_FieldFFT);
               
               %if the error is due to the GPU memory being too small, do
               %the FFT locally and push it to the GPU
            elseif strcmp(exception.identifier,'parallel:gpu:fft:AllocFailed')
               this.FPrepped_FieldFFT = fft2(Field);
               
               %try and push to the GPU, if this fails, shut off GPU
               %ability and leave the FFT where it is on the CPU
               try
                  this.send2gpu('FPrepped_FieldFFT');
               catch exception2
                  this.should_gpu = false;
                  display('Warning: Could not push to GPU');
               end
               
            else
               rethrow(exception);
            end
         end
         
         notify(this,'FieldFFT_update')
         
      end
      
      
      function makeKernel(this,dx,dy)
         %verify we have a field to work with
         if isempty(this.FPrepped_FieldFFT)
            error('No Field Loaded');
         end
         
         % Find the point of nux and nuy at which the propagator becomes
         % undersampled at distance maxz. A little work will show this to be when
         % nuy = 0, nux = +/- (lambda * sqrt((2 maxz dnux)^2 + 1 ))^-1
         if nargin == 1
            dx = this.dx;
            dy = this.dy;
         end
         
         [Ny, Nx] = size(this.FPrepped_FieldFFT);      % The field size
         
         
         dnux  = 1/(dx*Nx);   % Frequency 'pixel width'
         dnuy  = 1/(dy*Ny);
         
         nuxwidth = 1/(this.lambda*sqrt(1 + (2*this.zMaxForRes*dnux)^2));
         nuywidth = 1/(this.lambda*sqrt(1 + (2*this.zMaxForRes*dnuy)^2));
         
         if this.should_gpu
            %try to create spatial frequency grid on gpu
            try
               x = gpuArray([0:Nx/2-1 -Nx/2:-1]);  % xs and ys
               y = gpuArray([0:Ny/2-1 -Ny/2:-1]);
            catch exception
               if strcmp(exception.identifier,'parallel:gpu:OOM')
                  warning('Propagator:GPU:noFreeMem', ...
                     'Not enough GPU memory, disabling');
                  %If they didn't fit on the GPU, then disable GPU
                  %processing and just make x and y on the CPU
                  this.should_gpu = false;
                  x = [0:Nx/2-1 -Nx/2:-1];  % xs and ys
                  y = [0:Ny/2-1 -Ny/2:-1];
               else
                  rethrow(exception);
               end
            end %end try
            
            %if we are just using the CPU
         else
            x = [0:Nx/2-1 -Nx/2:-1];  % xs and ys
            y = [0:Ny/2-1 -Ny/2:-1];
         end
         
         %%%
         try
            [xx,yy] = meshgrid(x,y);        % root in phase multiplier
         catch exception
            if strcmp(exception.identifier,'parallel:gpu:OOM')
               warning('Propagator:GPU:noFreeMem', ...
                  'Not enough GPU memory, disabling');
               %If this fails on the GPU, disable GPU processing and
               %repeat on the CPU
               this.should_gpu = false;
               x = [0:Nx/2-1 -Nx/2:-1];
               y = [0:Ny/2-1 -Ny/2:-1];
               [xx,yy] = meshgrid(x,y);
            else
               rethrow(exception);
            end
         end
         
         %%%
         
         clear('x', 'y');
         %Try and construct the phase kernel.  If we get a GPU memory
         %error, we will pull everything to the CPU and go from there
         try
            this.FPrepped_root = sqrt(1 - this.lambda^2*( (xx.*dnux).^2 + (yy.*dnuy).^2));
         catch exception
            if strcmp(exception.identifier,'parallel:gpu:OOM')
               warning('Propagator:GPU:noFreeMem', ...
                  'Not enough GPU memory, disabling');
               this.should_gpu = false;
               xx = gather(xx);
               yy = gather(yy);
               this.FPrepped_root = sqrt(1 - this.lambda^2*(xx.^2*dnux.^2 + yy.^2*dnuy.^2));
            else
               rethrow(exception);
            end
         end
         
         
         %Supergaussian cutoff filter
         % SG(x,y) = exp(-1/2*((x/sigmax)^2 + (y/sigmay)^2)^n )
         
         f        = .5;
         n        = 3;
         sigmax   = nuxwidth * log(1/f^2)^(-1/(2*n));
         sigmay   = nuywidth * log(1/f^2)^(-1/(2*n));
         
         %These may be CPU or GPU at this point
         if ~this.should_double
            xx = single(xx);
            yy = single(yy);
         end
         
         try
            this.FPrepped_filter = exp(-1/2*((xx*dnux/sigmax).^2+(yy*dnuy/sigmay).^2).^n);
         catch exception
            if strcmp(exception.identifier,'parallel:gpu:OOM')
               warning('Propagator:GPU:noFreeMem', ...
                  'Not enough GPU memory, moving filter to CPU');
               xx = gather(xx);
               yy = gather(yy);
               this.FPrepped_filter = exp(-1/2*((xx*dnux/sigmax).^2+(yy*dnuy/sigmay).^2).^n);
            else
               rethrow(exception);
            end
         end
      end
      
      
      %%%%
      function updateKernel(this)
         %if dx and dy are dynamic, there is no need to make the rest of
         %FPrepped, so skip it.
         if ~isa(this.dx,'function_handle') && ~isa(this.dy,'function_handle')
            this.makeKernel;
         end
         notify(this,'Base_update');
      end
      
      %%% Propagation methods %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      function fieldOut = HFFFTPropagate(this, zs)
         
         precision = 'single';
         if this.should_double && this.can_double, precision = 'double'; end
         
         %allocate memory to the reconstructed field
         if this.should_gpu
            %Try to allocate memory on the GPU for the reconstructed field
            try
               fieldOut = gpuArray(nan([size(this.FPrepped_FieldFFT) numel(zs)],precision));
            catch exception
               if strcmp(exception.identifier,'parallel:gpu:OOM')
                  fieldOut = nan([size(this.FPrepped_FieldFFT) numel(zs)],precision);
               else
                  rethrow(exception);
               end
            end
            
         else
            fieldOut = nan([size(this.FPrepped_FieldFFT) numel(zs)],precision);
         end
         
         %Compute each slice
         for cnt=1:numel(zs)
            thisz = zs(cnt);
            FieldFFT = this.makeTransform(thisz);
            
            if isa(this.freq_filter,'function_handle'), FieldFFT = this.freq_filter(FieldFFT,this.config_handle); end
            
            %if we have the field on the GPU, but are storing it on the CPU
            if strcmp(class(FieldFFT),'parallel.gpu.GPUArray') && ...
                  ~strcmp(class(fieldOut),'parallel.gpu.GPUArray')
               try
                  fieldOut(:,:,cnt) = gather(ifft2(FieldFFT));
               catch exception
                  if strcmp(exception.identifier,'parallel:gpu:fft:AllocFailed')
                     %if we can't do the ifft on the GPU...
                     fieldOut(:,:,cnt) = ifft2(gather(FieldFFT));
                  else
                     rethrow(exception);
                  end
               end
               
            elseif ~strcmp(class(FieldFFT),'parallel.gpu.GPUArray') && ...
                  strcmp(class(fieldOut),'parallel.gpu.GPUArray')
               %elseif the field is on the CPU, but we allocated space to
               %store it on the GPU (should never happen)
               fieldOut = gather(fieldOut);
               fieldOut(:,:,cnt) = ifft2(FieldFFT);
               
            else
               %Else we have either both input and output field on the GPU or
               %or on the CPU (not mixed)
               try fieldOut(:,:,cnt) = ifft2(FieldFFT);
               catch exception
                  if strcmp(exception.identifier,'parallel:gpu:fft:AllocFailed')
                     %if we don't have the room on the GPU then lets
                     %switch to storing the field on the CPU and try
                     %again
                     fieldOut = gather(fieldOut);
                     
                     try fieldOut(:,:,cnt) = gather(ifft2(FieldFFT));
                     catch exception2
                        if strcmp(exception.identifier,'parallel:gpu:fft:AllocFailed')
                           %if we still can't do the FFT, we'll have to
                           %do it locally
                           fieldOut(:,:,cnt) = ifft2(gather(FieldFFT));
                        else
                           rethrow(exception2);
                        end
                     end
                  else
                     rethrow(exception);
                  end
               end
            end
         end
         
      end
      
      function reconField = makeTransform(this,z)
         %Make the phase filter
         try
            %phase filter will be cast to the class of FPrepped root
            phaseFilter = exp(1j*this.k * z * this.FPrepped_root);
         catch exception
            if strcmp(exception.identifier,'parallel:gpu:OOM')
               %if there isn't enough memory to calculate the
               %exponential phase factor, do it on the cpu
               phaseFilter = exp(1j*this.k * z * gather(this.FPrepped_root));
               
               %and shut off the GPU
               this.should_gpu = false;
            else
               rethrow(exception);
            end
         end
         
         
         %Try and perform the propagaion
         try
            reconField = this.FPrepped_FieldFFT.* phaseFilter;
         catch exception
            if strcmp(exception.identifier,'parallel:gpu:OOM')
               %if performing the propagaion on the gpu exceeds memory,
               %pull it to the CPU and do it there
               reconField = gather(this.FPrepped_FieldFFT) .* gather(phaseFilter);
            else
               rethrow(exception);
            end
         end
         
         
         %if the low pass filter is not a GPU array, then yank the
         %reconstructed field to CPU for final filtering and processing
         
         if ~strcmp(class(this.FPrepped_filter),'parallel.gpu.GPUArray')
            reconField = gather(reconField) .* this.FPrepped_filter;
         else
            try
               reconField = reconField .* this.FPrepped_filter;
            catch exception
               if strcmp(exception.identifier,'parallel:gpu:OOM')
                  %if we don't have the memory to do this, pull it to the
                  %CPU and do it there
                  reconField = gather(reconField) .* gather(this.FPrepped_filter);
               end
            end
         end
         
      end
      
            % Function for one way reconstruction without affecting the cached data of
      % this propagator object. The dx, dy, lambda, and maxZForRes are used as
      % given in the config or propagator object already
      function outField = einWeg(this, inField, z)
         
         if numel(z) > 1
            error('Propagator.einWeg can only propagate inField to one particular ''z''');
         end
         
         if this.should_double && this.can_double
            %if we are using double precision, then use it
            inField = double(inField);
         else
            inField = single(inField);
         end
         
         %if we are using gpu's
         if this.should_gpu
            FPrepped_FieldFFT = gpuArray(inField);
         else
            FPrepped_FieldFFT = inField;
         end
         
         %Do the FFT
         FPrepped_FieldFFT = fft2(FPrepped_FieldFFT);
         
         % Find the point of nux and nuy at which the propagator becomes
         % undersampled at distance maxz. A little work will show this to be when
         % nuy = 0, nux = +/- (lambda * sqrt((2 maxz dnux)^2 + 1 ))^-1
         
         dx = this.dx;
         dy = this.dy;
         
         [Ny, Nx] = size(FPrepped_FieldFFT);      % The field size
         
         dnux  = 1/(dx*Nx);   % Frequency 'pixel width'
         dnuy  = 1/(dy*Ny);
         
         nuxwidth = 1/(this.lambda*sqrt(1 + (2*this.zMaxForRes*dnux)^2));
         nuywidth = 1/(this.lambda*sqrt(1 + (2*this.zMaxForRes*dnuy)^2));
         
         % If we're using the GPU
         if this.should_gpu
            x = gpuArray([0:Nx/2-1 -Nx/2:-1]);  % xs and ys
            y = gpuArray([0:Ny/2-1 -Ny/2:-1]);
            %if we are just using the CPU
         else
            x = [0:Nx/2-1 -Nx/2:-1];  % xs and ys
            y = [0:Ny/2-1 -Ny/2:-1];
         end
         
         [xx,yy] = meshgrid(x,y);        % root in phase multiplier
         
         % The root (phase) needs to be double in every case
         FPrepped_root = sqrt(1 - this.lambda^2*(xx.^2*dnux.^2 + yy.^2*dnuy.^2));
         
         %Supergaussian cutoff filter
         % SG(x,y) = exp(-1/2*((x/sigmax)^2 + (y/sigmay)^2)^n )
         f        = .5;
         n        = 3;
         sigmax   = nuxwidth * log(1/f^2)^(-1/(2*n));
         sigmay   = nuywidth * log(1/f^2)^(-1/(2*n));
         
         %These may be CPU or GPU at this point
         if ~this.should_double % But the filter can be single or double.
            xx = single(xx);
            yy = single(yy);
         end
         FPrepped_filter = exp(-1/2*((xx*dnux/sigmax).^2+(yy*dnuy/sigmay).^2).^n);
         
         % Make the phase filter
         outField = exp(1j*this.k * z * FPrepped_root);
         % Multiply in the FFT
         outField  = FPrepped_FieldFFT.* outField;
         % Multiply in the filter
         outField  = outField .* FPrepped_filter;
         % Take the ifft
         outField    = ifft2(outField);
         
         if this.should_normalize
            outField = outField.*exp(-1j*this.k*z);
         end
         
      end %End einWeg
      
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      function flag = isMultipleCall(this)
         flag = false;
         % Get the stack
         s = dbstack();
         if numel(s) <= 2
            % Stack too short for a multiple call
            return
         end
         
         % How many calls to the calling function are in the stack?
         names = {s(:).name};
         TF = strcmp(s(2).name,names);
         count = sum(TF);
         if count>1
            % More than 1
            flag = true;
         end
      end
   end
   
end
