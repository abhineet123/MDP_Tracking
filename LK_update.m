% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
function tracker = LK_update(frame_id, tracker, img, dres_det,...
    is_change_anchor)
% update the LK tracker

% mostly about adding the data from the latest tracked frame to the
% history;

medFBs = tracker.medFBs;
if is_change_anchor == 0
    % find the template with max FB error but not the anchor
    % this is the one that will presumably be replaced with the new one
    medFBs(tracker.anchor) = -inf;    
    [~, index] = max(medFBs);
else
    [~, index] = max(medFBs);
    tracker.anchor = index;    
end

% update
% evidently the det of stored frames are not in chronological order - even
% very old frames might remain there as long as the template therein
% continues to be tracked successfully in the latest frame
tracker.frame_ids(index) = frame_id;
tracker.x1(index) = tracker.bb(1);
tracker.y1(index) = tracker.bb(2);
tracker.x2(index) = tracker.bb(3);
tracker.y2(index) = tracker.bb(4);
% replace the old pattern with the new one – a pattern is just the the set
% of pixel values corresponding to the location all for this bounding box
% that has been subjected to some preliminary preprocessing like
% normalization and stuff
tracker.patterns(:,index) = generate_pattern(img, tracker.bb, tracker.patchsize);

% update images and boxes
BB = [tracker.x1(index); tracker.y1(index); tracker.x2(index); tracker.y2(index)];
[I_crop, BB_crop] = LK_crop_image_box(img, BB, tracker);
tracker.Is{index} = I_crop; 
tracker.BBs{index} = BB_crop;

% compute overlap
dres.x = tracker.bb(1);
dres.y = tracker.bb(2);
dres.w = tracker.bb(3) - tracker.bb(1);
dres.h = tracker.bb(4) - tracker.bb(2);
num_det = numel(dres_det.fr);
if isempty(dres_det.fr) == 0
    o = calc_overlap(dres, 1, dres_det, 1:num_det);
    tracker.bb_overlaps(index) = max(o);
else
    tracker.bb_overlaps(index) = 0;
end