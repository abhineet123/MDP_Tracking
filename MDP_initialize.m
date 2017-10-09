% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% initialization of the tracker
function tracker = MDP_initialize(I, dres_det, labels, opt)

image_width = size(I,2);
image_height = size(I,1);

% normalization factor for features
tracker.image_width = image_width;
tracker.image_height = image_height;
tracker.max_width = max(dres_det.w);
tracker.max_height = max(dres_det.h);
tracker.max_score = max(dres_det.r);
tracker.fb_factor = opt.fb_factor;

% active
tracker.fnum_active = 6;
factive = MDP_feature_active(tracker, dres_det);
% ignore detections whose FP/TP status is unknown
index = labels ~= 0;
tracker.factive = factive(index,:);
tracker.lactive = labels(index);
% disp(tracker.factive)

% seem to be trying to learn something about the relationship between the
% FP/TP nature of the detections from these basic features which seems very
% far fetched indeed - sec. 3.2.1
tracker.w_active = svmtrain(tracker.lactive, tracker.factive, '-c 1');

% initial state
tracker.prev_state = 1;
tracker.state = 1;

% association model
tracker.fnum_tracked = 2;
% number of features in the occluded state
tracker.fnum_occluded = 12;
tracker.w_occluded = [];
tracker.f_occluded = [];
tracker.l_occluded = [];
tracker.streak_occluded = 0;

% tracker parameters
tracker.num = opt.num;
tracker.threshold_ratio = opt.threshold_ratio;
tracker.threshold_dis = opt.threshold_dis;
tracker.threshold_box = opt.threshold_box;
tracker.std_box = opt.std_box;  % [width height]
tracker.margin_box = opt.margin_box;
tracker.enlarge_box = opt.enlarge_box;
tracker.level_track = opt.level_track;
tracker.level = opt.level;
tracker.max_ratio = opt.max_ratio;
tracker.min_vnorm = opt.min_vnorm;
tracker.overlap_box = opt.overlap_box;
tracker.patchsize = opt.patchsize;
tracker.weight_tracking = opt.weight_tracking;
tracker.weight_detection = opt.weight_detection;
tracker.weight_association = opt.weight_association;

% display results or not
tracker.is_show = opt.is_show;
tracker.pause_for_debug = 0;