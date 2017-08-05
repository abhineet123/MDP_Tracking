% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% find detections for association
function [dres_det, index_det, ctrack] = generate_association_index(tracker, frame_id, dres_det)
% Returns the detections that are close to the last known location of the object
% and whose height is very similar to the height of that last known object
% also augments the input structure containing all of the detections with 
% their distances and ratios from this last known location

% In other words it first obtains the predicted location of for this object
% in the current frame based on its last known location and the average velocity 
% computed from all of the successfully tracked frames in which this object
% has been present
% this predicted location of the bonding box is then compared with all of 
% the candidates detections that are passed to this function and the 
% indices all those that are similar to this predicted bounding box in size 
% and height, and optionally also the widths, are returned
% at the same time, the height ratio and the distances of all of these
% candidates bonding boxes from the predicted bonding box 
% are also computed and added on to the structure containing all of these
% candidate bonding boxes so that may be reused later

num_det = numel(dres_det.fr);
% centers of the detections
cdets = [dres_det.x + dres_det.w/2, dres_det.y + dres_det.h/2];
% centers of predicted locations of the tracked bounding boxes
ctrack = apply_motion_prediction(frame_id, tracker);

% compute distances and aspect ratios
distances = zeros(num_det, 1);
ratios = zeros(num_det, 1);
ratios_w = zeros(num_det, 1);
for i = 1:num_det
    % distance between the centre of this detection and the predicted location
    % of the tracked bonding box normalized by the width of the the last
    % bonding box stored in the history of the tracker
    distances(i) = norm(cdets(i,:) - ctrack) / tracker.dres.w(end);
    % Ratio of the object bonding box height in the last frame in which it
    % was successfully tracked and the height of this particular detection
    ratio = tracker.dres.h(end) / dres_det.h(i);
    % the ratio must always be between zero and one so if it is greater than
    % one then we take the minimum of this ratio and its reciprocal
    ratios(i) = min(ratio, 1/ratio);
    % The same thing is repeated for the height too
    ratio_w = tracker.dres.w(end) / dres_det.w(i);
    ratios_w(i) = min(ratio_w, 1/ratio_w);    
end

if isfield(tracker.dres, 'type') % type or category of object
    cls = tracker.dres.type{end};
    cls_index = strcmp(cls, dres_det.type);
    index_det = find(distances < tracker.threshold_dis & ratios > tracker.threshold_ratio & ...
        ratios_w > tracker.threshold_ratio & cls_index == 1);
else
    % All the detectins whose normalized Euclidean distance from the last
    % known location of the object is less than some threshold and whose 
    % ratio of heights is greater than another threshold where the latter, 
    % as should be remembered, is always between zero and one;
    % therefore higher threshold means that it is closer to one which means
    % that their heights are almost equal; for some reason we do not seem
    % to care about their widths being equal which seems to be a rather
    % arbitrary assumption;
    index_det = find(distances < tracker.threshold_dis & ratios > tracker.threshold_ratio);
end
% The structure containing the set of detections is also augmented with all
% of the computed ratios and distances so that they can presumably be reused later
dres_det.ratios = ratios;
dres_det.distances = distances;