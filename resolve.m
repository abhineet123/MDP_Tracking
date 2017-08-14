function trackers = resolve(trackers, dres_det, opt)
% resolve conflict between trackers

% This basically checks if multiple trackers are tracking the same object
% or at least they are tracking objects which are at roughly the same location
% in the scene so that one of them is occluded by the other

% collect dres from trackers
dres_track = [];
for i = 1:numel(trackers)
    tracker = trackers{i};
    % Get the last bounding box within the tracker which corresponds
    % to the last known location of this tracked object
    dres = sub(tracker.dres, numel(tracker.dres.fr));
    
    if tracker.state == 2
        if isempty(dres_track)
            dres_track = dres;
        else
            dres_track = concatenate_dres(dres_track, dres);
        end
    end
end

% compute overlaps
num_det = numel(dres_det.fr);
if isempty(dres_track)
    num_track = 0;
else
    num_track = numel(dres_track.fr);
end

flag = zeros(num_track, 1);
for i = 1:num_track
    % compute overlap of the current tracked bounding box with
    % all of the other tracked bounding boxes
    [~, o] = calc_overlap(dres_track, i, dres_track, 1:num_track);
    % Ignore the overlap of this bounding box with itself
    o(i) = 0;
    % Ignore trackers that have already been suppressed
    o(flag == 1) = 0;
    [mo, ind] = max(o);
    
    if isfield(dres_track, 'type')
        cls = dres_track.type{i};
        if strcmp(cls, 'Pedestrian') == 1 || strcmp(cls, 'Cyclist') == 1
            overlap_sup = opt.overlap_sup;
        elseif strcmp(cls, 'Car') == 1
            overlap_sup = 0.95;
        end
    else
        overlap_sup = opt.overlap_sup;
    end
    
    
    if mo > overlap_sup
        % Use the number of frames for which each of these objects
        % have been tracked as a measure of how reliable the current
        % bounding box locations of these objects are likely to be
        num1 = trackers{dres_track.id(i)}.streak_tracked;
        num2 = trackers{dres_track.id(ind)}.streak_tracked;
        if num1 > num2
            sup = ind;
        elseif num1 < num2
            sup = i;
        else
            % If the number of tracked frames are equal then we consider
            % the maximum overlap of these bounding boxes with all of the
            % detections to measure the reliability
            
            % max overlap between the current tracked bounding box and all
            % of the detections
            o1 = max(calc_overlap(dres_track, i, dres_det, 1:num_det));
            % max overlap between the tracked bounding box wit the maximum overlap
            % with the current one and all of the detections
            o2 = max(calc_overlap(dres_track, ind, dres_det, 1:num_det));
            if o1 > o2
                sup = ind;
            else
                sup = i;
            end
        end
        
        trackers{dres_track.id(sup)}.state = 3;
        trackers{dres_track.id(sup)}.dres.state(end) = 3;
        if opt.is_text
            fprintf('target %d suppressed\n', dres_track.id(sup));
        end
        flag(sup) = 1;
    end
end