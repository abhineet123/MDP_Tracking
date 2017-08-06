% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% MDP value function
function [tracker, qscore, f] = MDP_value(tracker, frame_id, dres_image, dres_det, index_det)

% tracked, decide to tracked or occluded
if tracker.state == 2
    % extract features with LK tracking
    [tracker, f] = MDP_feature_tracked(frame_id, dres_image, dres_det, tracker);
    
    % build the dres structure
    if bb_isdef(tracker.bb)
        dres_one.fr = frame_id;
        dres_one.id = tracker.target_id;
        dres_one.x = tracker.bb(1);
        dres_one.y = tracker.bb(2);
        dres_one.w = tracker.bb(3) - tracker.bb(1);
        dres_one.h = tracker.bb(4) - tracker.bb(2);
        dres_one.r = 1;
    else
        dres_one = sub(tracker.dres, numel(tracker.dres.fr));
        dres_one.fr = frame_id;
        dres_one.id = tracker.target_id;
    end
    
    if isfield(tracker.dres, 'type')
        dres_one.type = tracker.dres.type{1};
    end
    
    % compute qscore
    qscore = 0;
    if f(1) == 1 && f(2) > tracker.threshold_box % 0.8
        % tracking of the main template was successful and object is visible
        % in the current frame as the average overlap of BBs of all stored
        % frames is pretty high too so that most of them were presumably 
        % successfully tracked too        % 
        label = 1;
    else
        label = -1;
    end

    % make a decision
    if label > 0
        % tracking was successful so the current state remains tracked
        tracker.state = 2;
        dres_one.state = 2;
        % tracker.dres basically contains the set of all the final locations
        % of the corresponding object in all the frames in which it has been
        % successfully tracked so far
        % as far as I can see, it continues to get added on to without any filtering
        % so it doesn't really seem to have anything to do with the history itself
        % the history is stored in different structures called Is and BBs
        % while dres basically just stores the complete set of all the
        % locations this particular object has been in
        % since each object in any given scenario will presumably be in the
        % scene for only a few frames, this should not be a big problem
        % but potentially if a particular object remains there forever then this restructure will grow out of bounds very quickly indeed
        tracker.dres = concatenate_dres(tracker.dres, dres_one);
        % update LK tracker
        tracker = LK_update(frame_id, tracker, dres_image.Igray{frame_id}, dres_det, 0);
    else
        % transfer to occluded
        tracker.state = 3;
        dres_one.state = 3;
        tracker.dres = concatenate_dres(tracker.dres, dres_one);        
    end
    tracker.prev_state = 2;

% occluded, decide to tracked or occluded
elseif tracker.state == 3
    % association
    if isempty(index_det) == 1
        % This occurs if the bounding box of this object is not completely
        % uncovered, that is, its coverage is not equal to zero
        % since the label now becomes -1, this is evidently like a negative 
        % training sample probably
        qscore = 0;
        label = -1;
        f = [];
    else
        % extract features with LK association
        % Get features for all the detections that are likely to correspond to
        % this particular object based on some preliminary thresholding that was
        % performed during association to obtain the indices in index_det
        dres = sub(dres_det, index_det);
        [features, flag] = MDP_feature_occluded(frame_id, dres_image, dres,...
            tracker);
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
        [labels, ~, probs] = svmpredict(labels, features, tracker.w_occluded, '-b 1 -q');

        probs(flag == 0, 1) = 0;
        probs(flag == 0, 2) = 1;
        labels(flag == 0) = -1;
        % find the detection with the maximum probability and use only its
        % label and features
        [qscore, ind] = max(probs(:,1));
        label = labels(ind);
        f = features(ind,:);

        dres_one = sub(dres_det, index_det(ind));
        tracker = LK_associate(frame_id, dres_image, dres_one, tracker);
    end

    % make a decision
    tracker.prev_state = tracker.state;
    if label > 0
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
        dres_one.w = tracker.bb(3) - tracker.bb(1);
        dres_one.h = tracker.bb(4) - tracker.bb(2);
        dres_one.r = 1;
        dres_one.state = 2;
        
        if isfield(tracker.dres, 'type')
            dres_one.type = tracker.dres.type{1};
        end        
        
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
        tracker.dres = interpolate_dres(tracker.dres, dres_one);
        % update LK tracker
        tracker = LK_update(frame_id, tracker, dres_image.Igray{frame_id}, dres_det, 1);           
    else
        % no association
        tracker.state = 3;
        % Extract the last bonding box that is present in the history
        % of tracked bounding boxes within the tracker and modify
        % frame ID to be the current frame ID and also its target ID
        % to be the current one and its state to be 3 or occluded
        dres_one = sub(tracker.dres, numel(tracker.dres.fr));
        dres_one.fr = frame_id;
        dres_one.id = tracker.target_id;
        dres_one.state = 3;
        % if the history of tracked objects within the tracker
        % already contains a bounding box whose frame ID is equal to that
        % of the current one, then this particular bounding box is
        % removed from this history
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
    end
end

% if tracker.is_show
%     fprintf('qscore %.2f\n', qscore);
% end