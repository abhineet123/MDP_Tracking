function tracker = associate_hungarian(fr, dres_image, dres_associate, tracker, opt)
% associate_hungarian a lost target

% occluded
if tracker.state == 3
    tracker.streak_occluded = tracker.streak_occluded + 1;
    % find a set of detections for association
    [dres_associate, index_det] = generate_association_index(tracker, fr, dres_associate);
    tracker = MDP_associate(tracker, fr, dres_image,...
	dres_associate, index_det);
    if tracker.state == 2
        tracker.streak_occluded = 0;
    end

    if tracker.streak_occluded > opt.max_occlusion
        tracker.state = 0;
        if opt.is_text
            fprintf('target %d exits due to long time occlusion\n', tracker.target_id);
        end
    end
    
    % check if target outside image
    [~, ov] = calc_overlap(tracker.dres, numel(tracker.dres.fr), dres_image, fr);
    
    % This is the part where this function is different from its counterpart
    % used in the non Hungarian variant of MDP_test
    % the other version also computes the predicted location of this object
    % in the next frame and the compares it with a threshold of 0.05
    % and uses that as another condition for declaring this object
    % to be outside the image extents provided that it is also occluded
    % in the current frame
    % this means that the object can either be outside the image extents
    % in the current frame or if it is occluded here then it might be
    % outside the image in its predicted location in the next frame
    % both of these conditions are enough to decide that this object
    % is no longer available in the scene
    
    % In this version, however, only the object's location in the current
    % frame is considered as the metric for deciding if it is not present
    % in the scene anymore
    if ov < opt.exit_threshold
        if opt.is_text
            fprintf('target outside image by checking boarders\n');
        end
        tracker.state = 0;
    end    
end