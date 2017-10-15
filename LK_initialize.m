% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% initialize the LK tracker
function tracker = LK_initialize(tracker, frame_id, target_id, dres, ind, dres_image)

x1 = dres.x(ind);
y1 = dres.y(ind);
x2 = dres.x(ind) + dres.w(ind) - 1;
y2 = dres.y(ind) + dres.h(ind) - 1;    

% template num
num = tracker.num;
tracker.target_id = target_id;
tracker.bb = zeros(4,1);

% initialize all the stored templates
% copy the main BB to all locations
bb = repmat([x1; y1; x2; y2], [1 num]);
% modify BB 2-5 to be shifted versions of the main BB - no idea why
% the remaining 5 BBs remain same as the first one
bb(:,2) = bb_shift_relative(bb(:,1), [-0.01 -0.01]);
bb(:,3) = bb_shift_relative(bb(:,1), [-0.01 0.01]);
bb(:,4) = bb_shift_relative(bb(:,1), [0.01 -0.01]);
bb(:,5) = bb_shift_relative(bb(:,1), [0.01 0.01]);

tracker.frame_ids = frame_id * int32(ones(num, 1));
tracker.x1 = bb(1,:)';
tracker.y1 = bb(2,:)';
tracker.x2 = bb(3,:)';
tracker.y2 = bb(4,:)';
tracker.anchor = 1;

% initialze the images for LK association
tracker.Is = cell(num, 1);
tracker.BBs = cell(num, 1);
for i = 1:num
    I = dres_image.Igray{tracker.frame_ids(i)};
    BB = [tracker.x1(i); tracker.y1(i); tracker.x2(i); tracker.y2(i)];
    
    % crop images and boxes
    [I_crop, BB_crop] = LK_crop_image_box(I, BB, tracker);
    tracker.Is{i} = I_crop;
    tracker.BBs{i} = BB_crop;
end

% initialize the patterns
img = dres_image.Igray{frame_id};
tracker.patterns = generate_pattern(img, bb, tracker.patchsize,...
    tracker.pause_for_debug);

% box overlap history
tracker.bb_overlaps = ones(num, 1);

% tracker resutls
tracker.bbs_orig = cell(num, 1);
tracker.bbs = cell(num, 1);
tracker.points = cell(num, 1);
tracker.std_points = cell(num, 1);
tracker.flags = ones(num, 1);
tracker.features = zeros(num, 6);
tracker.medFBs = zeros(num, 1);
tracker.medFBs_left = zeros(num, 1);
tracker.medFBs_right = zeros(num, 1);
tracker.medFBs_up = zeros(num, 1);
tracker.medFBs_down = zeros(num, 1);
tracker.medNCCs = zeros(num, 1);
tracker.overlaps = zeros(num, 1);
tracker.scores = zeros(num, 1);
tracker.indexes = zeros(num, 1);
tracker.nccs = zeros(num, 1);
tracker.angles = zeros(num, 1);
tracker.ratios = zeros(num, 1);

tracker.v = cell(num, 1);
tracker.centerI = cell(num, 1);
tracker.centerJ = cell(num, 1);
tracker.v_new = cell(num, 1);


% initialize features for occluded state
if isempty(tracker.w_occluded) == 1
    features = [ones(1, tracker.fnum_occluded); zeros(1, tracker.fnum_occluded)];
    labels = [+1; -1];
    tracker.f_occluded = features;
    tracker.l_occluded = labels;
    tracker.w_occluded = svmtrain(labels, features, '-c 1 -g 1 -b 1');
end
if tracker.pause_for_debug
    debugging = 1;
end