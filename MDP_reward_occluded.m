% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% compute reward in tracked state
function [reward, label, f, is_end] = MDP_reward_occluded(fr, f, dres_image, dres_gt, ...
    dres, index_det, tracker, opt, is_text)

% This function is only called the tracker was in the occluded
% state in the last frame

% Possible scenarios:
% detected - good match between GT and one of the detections
%     tracked/associated
%         correctly
%             reward = 1;
%             label = 0;
%         incorrectly     
%             reward = -1;
%             label = -1;
%             feature from max probability detection associated with the tracker
%     not tracked/associated
%         visible/uncovered
%             all templates failed to track
%                 reward = 0;
%                 label = 0;
%             at least one template tracked
%                 reward = -1;                
%                 label = 1;
%                 feature from max overlapping detection with GT
%         covered/not visible
%             reward = 1;
%             label = 0;
% not detected - no match between GT and any of the detections
%     not tracked/associated
%         reward = 1;
%         label = 0;
%     tracked/associated
%         tracked or detected location does not match GT at all
%             reward = -1;
%             label = -1;
%             feature from max probability detection associated with the tracker
%         otherwise
%             reward = 0;
%             label = 0;

% The reward is set to negative or -1 when the predicted decision does not
% match the ground truth
% the label is set to -1 when the association between the tracker location
% or the ground truth and the corresponding detection is correct and it is
% set to -1 when this association is incorrect
% in fact it is set to +1 in only one case and in that case the feature
% is replaced with the one extracted by using the ground truth with the
% maximally overlapping detection
% therefore it is obvious that a +1 label corresponds to correct association
% while -1 corresponds to incorrect association

% The label is set to 0 in all cases where the reward is nonnegative, that is,
% it is +1 or  0
% this seems to indicate that in all the cases where the association was
% definitely correct when compared with the ground truth or in cases where 
% it was on indecisive, we are ignoring those cases as far as retraining 
% the SVM is concerned

 % Seems to be getting set to 1 whenever the reward is -1
is_end = 0;

label = 0;
% check if any detection overlap with gt

% get the location of the object in the current frame
index = find(dres_gt.fr == fr);
% Calculate the overlap of all of the possibly associated detections with
% the ground truth bounding box in the current frame;
if isempty(index) == 1
    overlap = 0;
else
    if dres_gt.covered(index) > opt.overlap_occ
        % If the ground truth bounding box itself is covered by another object's ground
        % truth box in this particular frame, then its overlap from the detection
        % bounding boxes is apparently not of any significance so we set it to zero;
        overlap = 0;
    else
        overlap = calc_overlap(dres_gt, index, dres, index_det);
    end
end
if is_text
    fprintf('max overlap in association %.2f\n', max(overlap));
end
if max(overlap) > opt.overlap_pos % 0.5
    % This means that the detector was able to detect the current object in the
    % current frame since its overlap with the ground truth location of
    % this object exceeds the threshold
    % this in turn means that the detector was successful in this frame
    % as far as the current object is concerned
    if tracker.state == 2
        % if the association is correct
        
        % Compute the overlap between the object location from the ground truth
        % and the last known location of the object in the tracker
        % which is the tracked location of the object in the current frame;      
        ov = calc_overlap(dres_gt, index, tracker.dres, numel(tracker.dres.fr));
        % so basically we are here comparing the result of the tracking
        % with the ground truth to see if it is correct and
        % therefore decide what the reward should be;
        if ov > opt.overlap_pos % 0.5
            % Both the detector and the tracker were successful with respect 
            % to this object in this frame
            reward = 1;
        else
            % Detector was successful but tracker was unsuccessful
            % The tracker did associate but with the wrong detection
            reward = -1;
            label = -1;
            is_end = 1;
            if is_text
                fprintf('associated to wrong target (%.2f, %.2f)! Game over\n', max(overlap), ov);
            end
        end
    else  % target not associated  
        
        % Tracker remained in the occluded estate as it was not able
        % to associate with any of the detections
        
        % detector was able to detect this object in the current frame
        % but tracker was unable to track it successfully
        % so there is a disagreement between the
        % tracker and the detector
        if dres_gt.covered(index) == 0
            % Object is visible in this scene
            
            % This is the only case where the tracker is even given a chance
            % to associate since, in the other case, the potential detections
            % are discarded before calling MDP_associate
            
            % find if any of the stored templates were tracked
            % successfully in this frame
            if isempty(find(tracker.flags ~= 2, 1)) == 1
                % None of the stored templates were tracked successfully
               
                % detector was successful but the tracker was not 
                reward = 0;  % no update
            else
                % detector was successful and at least
                % one of the stored templates were tracked successfully
                % But the overall association was still incorrect since the 
                % tracker remained in the occluded state therefore this
                % must be regarded as a failure               
                reward = -1;   % no association
                
                % but the corresponding feature is regarded as a positive
                % training sample for some reason 
                label = 1;
                
                % extract features
                
                % The feature is changed to be the one that is obtained by
                % trying to track this object from its last known location
                % to the detection that has the maximum overlap with
                % the ground truth
                
                % Find the detection that has the maximum overlap with the
                % ground truth bounding box
                [~, ind] = max(overlap);
                dres_one = sub(dres, index_det(ind));
                f = MDP_feature_occluded(fr, dres_image, dres_one, tracker);
                if is_text
                    fprintf('Missed association!\n');
                end
                is_end = 1;
            end
        else
            % We know from MDP_train that the tracker can only associate
            % successfully if the object is completely uncovered
            % therefore in this particular case the tracker was not even
            % given a chance to associate with any of the detections and
            % hence its reward will remain 1 since it obviously did not fail
            
            % Detector was able to find an object in this scene but
            % the ground truth says that the object is covered
            % therefore, since the tracker was also unable to track
            % this object in the scene, the tracker agrees with the ground
            % truth even though it disagrees with the detector
            % so in this case the detector is at fault but the
            % tracker is fine so it's reward remains positive as
            % there is no need to change it
            reward = 1;
        end
    end
else
    % detector was unable to detect the current object
    % in the current frame
    if tracker.state == 3
        % Detector was unsuccessful in finding the object in this frame
        % and the tracker also decided that the object was occluded
        % because it too could not track it successfully
        % so the two are in agreement and the tracker has not failed        
        reward = 1;
    else
        % Detector was unable to find this object in the current frame
        % but the tracker was able to track it since its current state
        % is tracked therefore the tracker must have associated with
        % the wrong detection and hence it is at fault and needs
        % to be given negative or maybe null reward  to correct it
        
        % Find the overlap between the ground truth location of the object
        % and the tracked location of the object
        ov = calc_overlap(dres_gt, index, tracker.dres, numel(tracker.dres.fr));
        if ov < opt.overlap_neg || max(overlap) < opt.overlap_neg % 0.2
            % If either the overlap of the tracked location or the best matching
            % detector location with the ground truth location is less than
            % the threshold of 0.2, then we conclude that there was an
            % incorrect association and give it a negative reward
            reward = -1;
            label = -1;
            is_end = 1;
            if is_text
                fprintf('associated to wrong target! Game over\n');
            end
        else
            % if both the tracker location and the best matching detector location
            % exceed a minimum threshold of 0.2 in terms of their overlap with
            % the ground truth location of the bounding box, then we give it
            % a null reward assuming that the tracker was neither
            % successful nor particularly unsuccessful
            
            % And its label also remains zero
            % so, along with the reward, the label itself can also be 0, +1 and -1
            % depending on exactly how the tracker either succeeded or failed
            % though probably not all combinations of reward and label are possible
            reward = 0;
        end
    end
end
if is_text
    fprintf('reward %.1f\n', reward);
end