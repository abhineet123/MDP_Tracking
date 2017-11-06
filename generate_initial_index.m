% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% find detections for initialization
function [dres_det, index_det] = generate_initial_index(trackers, dres_det,...
    pause_for_debug)

if isempty(dres_det) == 1
    index_det = [];
    return;
end

% collect dres from trackers
dres_track = [];
for i = 1:numel(trackers)
    tracker = trackers{i};
    % Extract the last bounding box within the tracker which is simply
    % the last known location of the tracked object
    dres = sub(tracker.dres, numel(tracker.dres.fr));
    % Add it to the list of bounding boxes from all the trackers only if
    % this tracker is in the tracked state
    if tracker.state == 2
        if isempty(dres_track)
            dres_track = dres;
        else
            dres_track = concatenate_dres(dres_track, dres);
        end
    end
end

% nms
% bbox = [dres_det.x dres_det.y dres_det.x+dres_det.w dres_det.y+dres_det.h dres_det.r];
% index_nms = nms(bbox, 0.5);
% dres_det = sub(dres_det, index_nms);

% compute overlaps
num_det = numel(dres_det.fr);
if isempty(dres_track)
    num_track = 0;
else
    num_track = numel(dres_track.fr);
end
if num_track
    % find detections that do not have any significant overlap with any of
    % the existing tracked bounding boxes
    o1 = zeros(num_det, 1);
    o2 = zeros(num_det, 1);
    o3 = zeros(num_det, 1);
    for i = 1:num_det
        [o, oo] = calc_overlap(dres_det, i, dres_track, 1:num_track);
        o1(i) = max(o);
        o2(i) = sum(oo);
        o3(i) = max(oo);
    end
    
    if isfield(dres_det, 'type')
        type = dres_det.type;
        index_det_people = find(o1 < 0.6 & o3 < 0.6 & ...
            (strcmp(type, 'Pedestrian') | strcmp(type, 'Cyclist')));
        index_det_car = find(o1 < 0.6 & o3 < 0.95 & ...
            strcmp(type, 'Car'));
        index_det = sort([index_det_people; index_det_car]);
    else
        index_det = find(o1 < 0.5 & o2 < 0.5);
    end
else
    index_det = 1:num_det;
end
if pause_for_debug
    debugging = 1;
end