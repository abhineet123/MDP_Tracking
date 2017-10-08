% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% extract features for occluded state
function [feature, flag] = MDP_feature_occluded(frame_id, dres_image, dres, tracker)

f = zeros(1, tracker.fnum_occluded);
% Number of candidate bounding boxes with respect to which these occluded 
% features have to be computed
% the lengths of dres.fr does not mean that we have multiple frames, it only 
% means that we have multiple objects - all of which might actually be present
% in the same frame so that dres.fr actually contains all of the same values
% but this is still an array because there must be one value for each object
% since each object is associated with a particular frame
n_detections = numel(dres.fr);
% Features are computed with respect to each candidate bounding box so that the
% feature array has number of rows equal to the number of candidate bounding boxes
% and the number of columns is equal to the dimensionality of the of occlusion 
% feature which is 12
feature = zeros(n_detections, tracker.fnum_occluded);
flag = zeros(n_detections, 1);

for i = 1:n_detections
    % The features for each of the potentially associated detections
    % are obtained by first trying to track each one of the stored
    % templates into the region of interest around that detection and then
    % comparing the result of this tracking or optical flow with
    % the detection itself
    % if a particular detection corresponds to the true location of
    % the object in that frame then many of the stored templates will, on being
    % tracked, give a bounding box which agrees very well with this detection
    % after these features are passed to SVM to obtain their labels
    % and probabilities, the detection with the maximum probability is
    % considered to be the most likely detection to correspond to
    % the true location of the object and all of the stored templates
    % are again tracked with respect to this particular detection again
    % therefore the tracking of all of the stored templates with respect
    % to this particular detection's ROI is performed twice and
    % this is at least one place. Some computation can be reduced
    % by separately storing the result of all of these optical flow
    % computations for each of one of the potential associated detections
    dres_one = sub(dres, i);
    tracker = LK_associate(frame_id, dres_image, dres_one, tracker);
    
    % design features
    % all stored templates for which the tracking/OF succeeded;
    index = find(tracker.flags ~= 2);
    if isempty(index) == 0
        % mean of features over non-tracked (presumably occluded) frames
        f(1) = mean(exp(-tracker.medFBs(index) / tracker.fb_factor));
        f(2) = mean(exp(-tracker.medFBs_left(index) / tracker.fb_factor));
        f(3) = mean(exp(-tracker.medFBs_right(index) / tracker.fb_factor));
        f(4) = mean(exp(-tracker.medFBs_up(index) / tracker.fb_factor));
        f(5) = mean(exp(-tracker.medFBs_down(index) / tracker.fb_factor));
        f(6) = mean(tracker.medNCCs(index));
        f(7) = mean(tracker.overlaps(index));
        f(8) = mean(tracker.nccs(index));
        f(9) = mean(tracker.ratios(index));
        % for some reason, only the first value is used in the following
        % instead of the mean
        f(10) = tracker.scores(1) / tracker.max_score;
        f(11) = dres_one.ratios(1);
        f(12) = exp(-dres_one.distances(1));
    else
        f = zeros(1, tracker.fnum_occluded);
    end
    
    feature(i,:) = f;
    
     % not clear why this is repeated here when its result has already been
     % computed into index 
    if isempty(find(tracker.flags ~= 2, 1)) == 1
        % Indicates which of the occluded features are valid 
        % and which are just zeros due to the corresponding patches having 
        % failed to be tracked;
        flag(i) = 0;
    else
        flag(i) = 1;
    end
    debugging = 1;
end