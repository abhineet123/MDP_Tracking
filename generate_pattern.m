% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function pattern = generate_pattern(img, bb, patchsize,...
    pause_for_debug)
% get patch under bounding box (bb), normalize it size, reshape to a column
% vector and normalize to zero mean and unit variance (ZMUV)
if nargin <4
    pause_for_debug = 0;
end
% initialize output variable
nBB = size(bb,2);
pattern = zeros(prod(patchsize),nBB);
% for every bounding box
for i = 1:nBB
    % sample patch
    patch = img_patch(img, bb(:,i), pause_for_debug);
    
    % normalize size to 'patchsize' and nomalize intensities to ZMUV
    pattern(:,i) = tldPatch2Pattern(patch,patchsize, pause_for_debug);
    if pause_for_debug
        debugging=1;
    end
end

function pattern = tldPatch2Pattern(patch, patchsize, pause_for_debug)
addpath('mexopencv-2.4.11');
% resized_patch   = imresize(patch, patchsize); % 'bilinear' is faster
resized_patch   = cv.resize(patch, [patchsize(2), patchsize(1)]); 
pattern = double(resized_patch(:));
pattern = pattern - mean(pattern);
if pause_for_debug
    debugging=1;
end