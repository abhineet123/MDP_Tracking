% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% crop canonical image and bounding box
function [I_crop, BB_crop, bb_crop, s] = LK_crop_image_box(I, BB, tracker)
addpath('./mexopencv-2.4.11/')

s = [tracker.std_box(1)/bb_width(BB), tracker.std_box(2)/bb_height(BB)];
bb_scale = round([BB(1)*s(1); BB(2)*s(2); BB(3)*s(1); BB(4)*s(2)]);
bb_scale(3) = bb_scale(1) + tracker.std_box(1) - 1;
bb_scale(4) = bb_scale(2) + tracker.std_box(2) - 1;    
I_scale = cv.resize(I, round([size(I,2)*s(1), size(I,1)*s(2)]), 'Interpolation', 'Linear');
% imsize = round([size(I,1)*s(2), size(I,2)*s(1)]);
% I_scale = imResample(I, imsize, 'bilinear');
bb_crop = bb_rescale_relative(bb_scale, tracker.enlarge_box);
[I_crop, smin, smax, cmin, cmax] = im_crop(I_scale, bb_crop);
BB_crop = bb_shift_absolute(bb_scale, [-bb_crop(1) -bb_crop(2)]);
nazio = 1;

% BB_crop
% bb_crop
% bb_scale_size = bb_scale(3:4) - bb_scale(1:2)

% bb_scale: location of BB in the resized image

% bb_crop: enlarged version of bb_scale with constant width/height borders
% added arund the latter; this is the location from where the patch is 
% extracted from within the resized image

% BB_crop: negatively shifted version of bb_scale where the shidt amount is
% equal to the top left corner of bb_crop; this corresponds to the location
% of for bb_scale within the cropped patch image
