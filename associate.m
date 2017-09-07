function tracker = associate(fr, dres_image, dres_associate, tracker, opt,...
    check_next_frame)
% associate a lost target

% Process a tracker that is in the occluded date in the current frame
% by first finding potentially associated detections among those
% that have been passed to this function and then trying to track
% this object from its last known location to all of these
% potentially associated detections
% finally, we also check if for the the location of this object
% after this tracking has been performed is outside the extents of the image

if tracker.state ~= 3
	error('Association can only be performed in the occluded state');
end

tracker.streak_occluded = tracker.streak_occluded + 1;
% find a set of detections for association
[dres_associate, index_det] = generate_association_index(tracker,...
    fr, dres_associate);
tracker = MDP_associate(tracker, fr, dres_image,...
dres_associate, index_det);
if tracker.state == 2
    tracker.streak_occluded = 0;
    if opt.is_text
        fprintf('target %d associated\n', tracker.target_id);
    end
else
    if opt.is_text
        fprintf('target %d not associated\n', tracker.target_id);
    end
end

if tracker.streak_occluded > opt.max_occlusion
    tracker.state = 0;
    if opt.is_text
        fprintf('target %d exits due to long time occlusion\n', tracker.target_id);
    end
end

% check if target outside image
% should be done only if the current state is tracked since the location is
% not updated in the lost state anyway
[~, ov] = calc_overlap(tracker.dres, numel(tracker.dres.fr), dres_image, fr);

if check_next_frame    
    % predict the new location
    ctrack = apply_motion_prediction(fr+1, tracker);
    dres_one.x = ctrack(1);
    dres_one.y = ctrack(2);
    dres_one.w = tracker.dres.w(end);
    dres_one.h = tracker.dres.h(end);
    [~, ov1] = calc_overlap(dres_one, 1, dres_image, fr);
else
    ov1 = 1;
end    
if ov < opt.exit_threshold || (ov1 < 0.05 && tracker.state == 3)
    if opt.is_text
        fprintf('target outside image by checking boarders\n');
    end
    tracker.state = 0;
end    
