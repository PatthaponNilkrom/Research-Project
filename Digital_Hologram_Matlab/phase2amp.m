function image = phase2amp(image,props)
    image = angle(image);
    image =  image - mean(image(:));
    image = mod(image + pi,2*pi) - pi;

    %Rescale to 0:1
    image  = (image + pi) ./(2*pi);
    image = image - min(image(:));
    image = image ./ max(image(:));
    image = image .*255;
 end