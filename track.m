function tracker = track(fr, dres_image, dres, tracker, opt)
% track a target

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