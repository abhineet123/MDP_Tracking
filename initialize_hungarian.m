function tracker = initialize_hungarian(fr, dres_image, id, dres, ind, tracker)
% initialize a tracker
% dres: detections

if tracker.state ~= 1
    return;
else  % active

    % initialize_hungarian the LK tracker
    tracker = LK_initialize(tracker, fr, id, dres, ind, dres_image);
    tracker.state = 2;
    tracker.streak_occluded = 0;
    tracker.streak_tracked = 0;

    % build the dres structure
    dres_one.fr = dres.fr(ind);
    dres_one.id = tracker.target_id;
    dres_one.x = dres.x(ind);
    dres_one.y = dres.y(ind);
    dres_one.w = dres.w(ind);
    dres_one.h = dres.h(ind);
    dres_one.r = dres.r(ind);
    dres_one.state = tracker.state;
    if isfield(dres, 'type')
        dres_one.type = {dres.type{ind}};
    end        
    tracker.dres = dres_one;
end

% track a target
function tracker = track(fr, dres_image, dres, tracker, opt)

% tracked    
if tracker.state == 2
    tracker.streak_occluded = 0;
    tracker.streak_tracked = tracker.streak_tracked + 1;
    tracker = MDP_value(tracker, fr, dres_image, dres, []);

    % check if target outside image
    [~, ov] = calc_overlap(tracker.dres, numel(tracker.dres.fr), dres_image, fr);
    if ov < opt.exit_threshold
        if opt.is_text
            fprintf('target outside image by checking boarders\n');
        end
        tracker.state = 0;
    end    
end