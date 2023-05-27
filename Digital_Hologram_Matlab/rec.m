clear all
colormap gray;
% Image Definitions
imgsrc='IMG_9532.png';
imgw=1728;
imgh=1152;
pxpt=12.85e-6; % Pixel size in meters
% Scan for 1st order
scan_start=20.0;
scan_end=30.0;
scan_int=1;
% Full Frame
frame_xrange=1:imgw;
frame_yrange=1:imgh;
% 1st Order medium
%frame_xrange=800:1400;
%frame_yrange=400:800;
lambda=0.633e-6;
%ii=sqrt(-1);
% Load the image
im=imread(imgsrc);
imagesc(im)
im=double(im);
for z=scan_start:scan_int:scan_end;
    % Figure the transfer function from Schnars 2002
    del_x=pxpt; del_y=pxpt;  
    H=zeros(imgh,imgw);
    for m=1:imgh;
        for n=1:imgw;
            r2=((m-(imgh/2))*del_x)^2+((n-(imgw/2))*del_y)^2;
            H(m,n)=exp((-1i*pi/(z*lambda))*r2);
        end
    end   
    gam=fft2(im.*H);
    gam=ifftshift(gam);
    gg=gam.*conj(gam);
    %imagesc(log(1+gg(frame_yrange,frame_xrange)));
    imagesc(sqrt(1+gg(frame_yrange,frame_xrange)));
    %imagesc(gg(frame_yrange,frame_xrange));
     
text(10,10,strcat('\color{white}z=',sprintf('%3.0f%',z*1000),'mm'));
     
    drawnow;
end