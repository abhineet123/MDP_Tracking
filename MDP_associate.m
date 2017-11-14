% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% MDP value function
function [tracker, qscore, f] = MDP_associate(tracker, frame_id, dres_image,...
    dres_det, index_det, opt)
if tracker.state ~= 3
	error('Association can only be performed in the occluded state');
end

tracker.det_ratios = dres_det.ratios;
tracker.det_distances = dres_det.distances;
    
% association
if isempty(index_det) == 1
	% This occurs if the bounding box of this object is not completely
	% uncovered, that is, its coverage is not equal to zero
	% since the label now becomes -1, this is evidently like a negative 
	% training sample probably
	qscore = 0;
	label = -1;
	f = [];
    tracker.f_test_occluded = [];
    tracker.l_test_occluded = [];
    tracker.probs_occluded = [];
    tracker.J_crops = [];
    ind = -1;
    
    if tracker.pause_for_debug 
        debugging=1;
    end 
else
	% extract features with LK association
	% Get features for all the detections that are likely to correspond to
	% this particular object based on some preliminary thresholding that was
	% performed during association to obtain the indices in index_det
	dres = sub(dres_det, index_det);
	[features, flag, J_crops] = MDP_feature_occluded(frame_id, dres_image, dres,...
		tracker);
    tracker.J_crops = J_crops;
	% Use the existing SVM to get labels for all of these features for
	% the potentially associated detections
	% along with labels we also get the probabilities
	% next we choose the detection that the maximum probability
	% and pass only this to the LK_associate function to check the
	% degree of agreeability of all of the stored templates with
	% this detection by tracking all of these templates into
	% a small region of interest around this detection and then
	% computing the overlap of the resultant bounding box with this
	% detection and extracting a bunch of other appearance-based features
	% as well as features to do with the success of the optical flow process
	m = size(features, 1);
	% Initialize all labels with negative
	labels = -1 * ones(m, 1);
    svm_options = '-b 1';
    if ~tracker.verbose_svm
        svm_options = strcat(svm_options, ' -q');
    end
	[labels, acc, probs] = svmpredict(labels, features, tracker.w_occluded,...
        svm_options);

	probs(flag == 0, 1) = 0;
	probs(flag == 0, 2) = 1;
	labels(flag == 0) = -1;
    
    tracker.f_test_occluded = features;
    tracker.l_test_occluded = labels;
    tracker.probs_occluded = probs;
    
	% find the detection with the maximum probability and use only its
	% label and features
	[qscore, ind] = max(probs(:,1));
	label = labels(ind);
	f = features(ind,:);
    
    if tracker.pause_for_debug 
        debugging=1;
    end 

	dres_one = sub(dres_det, index_det(ind));
	tracker = LK_associate(frame_id, dres_image, dres_one, tracker);
    
    if tracker.pause_for_debug 
        debugging=1;
    end 
end

% make a decision
tracker.prev_state = tracker.state;
if label > 0
    if opt.is_text
        fprintf('target %d associated to detection %d\n',...
            tracker.target_id, ind);
    end
	% association was successful so the object moves from lost to 
	% tracked state
	tracker.state = 2;
	% build the dres structure for the BB corresponding to the tracking
	% result on the ROI around the most probable detection given by SVM
	dres_one = [];
	dres_one.fr = frame_id;
	dres_one.id = tracker.target_id;
	dres_one.x = tracker.bb(1);
	dres_one.y = tracker.bb(2);
    % yet another instance of the horrible annoying insidious bug
	dres_one.w = tracker.bb(3) - tracker.bb(1) + 1;
	dres_one.h = tracker.bb(4) - tracker.bb(2) + 1;
	dres_one.r = 1;
	dres_one.state = 2;
	
	if isfield(tracker.dres, 'type')
		dres_one.type = tracker.dres.type{1};
	end        
	% if the current frame is already in the history, remove it and replace
	% its status with the new one; this happens during training when the
	% tracker has just been lost and we try to reconnect it using
	% association with the detections
	if tracker.dres.fr(end) == frame_id
		dres = tracker.dres;
		index = 1:numel(dres.fr)-1;
		tracker.dres = sub(dres, index);            
	end
	% If the frame in which the bject was last tracked successfully
	% and the frame in which this most likely detection was found,
	% that is, the current frame, differ by more than one frame
	% and less than five frames, then all of the intermediate frames
	% between them, that is, 1 to 4 frames, are filled in by using
	% interpolation or rather using linear interpolation between
	% the bounding box corresponding to the final location of the object
	% in the current frame and the last known location of the object
	% in the tracker itself
	% so presumably these are the frames where the object was occluded
	% or otherwise went out of view of the camera
	% so we estimate the location of the object in these
	% frames by using linear interpolation between the two frames
	% in which it was visible or at least where we were able to track it
	tracker.dres = interpolate_dres(tracker.dres, dres_one, tracker.pause_for_debug);
	% update LK tracker
	tracker = LK_update(frame_id, tracker, dres_image.Igray{frame_id}, dres_det, 1);           
else
    if opt.is_text
        fprintf('target %d not associated\n', tracker.target_id);
        if ind>0
            fprintf('\t best matching detection: %d\n', ind);
        end
    end
	% no association
	tracker.state = 3;
	% Extract the last bounding box that is present in the history
	% of tracked bounding boxes within the tracker and modify
	% frame ID to be the current frame ID and also its target ID
	% to be the current one and its state to be occluded
    % note, however, that its location is not modified so we are still
    % assuming the object to be in its erstwhile location
	dres_one = sub(tracker.dres, numel(tracker.dres.fr));
	dres_one.fr = frame_id;
	dres_one.id = tracker.target_id;
	dres_one.state = 3;
	% if the last entry in history of tracked objects has a frame ID 
    % equal to that
	% of the current one, then this is removed from this history before
	% adding the new one
	if tracker.dres.fr(end) == frame_id
		dres = tracker.dres;
		index = 1:numel(dres.fr)-1;
		tracker.dres = sub(dres, index);
	end    
	% finally this new bounding box which was constructed by extracting the
	% last bounding box from within the tracker and modifying its frame ID
	% and target ID and state is appended at the end of the
	% history of the tracker
	tracker.dres = concatenate_dres(tracker.dres, dres_one);  
    if tracker.pause_for_debug 
        debugging=1;
    end 
end
if tracker.pause_for_debug 
    debugging=1;
end 