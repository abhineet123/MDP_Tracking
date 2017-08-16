function tracker = track(fr, dres_image, dres, tracker, opt,...
   fig_ids, colors_rgb)
if tracker.state ~= 2
	error('Tracking can only be performed in the tracked state');
end
if nargin<6
    fig_ids = [];
end
if nargin<7
    colors_rgb = {};
end

% track a target
tracker.streak_occluded = 0;
tracker.streak_tracked = tracker.streak_tracked + 1;
tracker = MDP_track(tracker, fr, dres_image, dres,...
    fig_ids, colors_rgb);

% check if target outside image
[~, ov] = calc_overlap(tracker.dres, numel(tracker.dres.fr), dres_image, fr);

if ov < opt.exit_threshold
    if opt.is_text
        fprintf('target outside image by checking boarders\n');
    end
    tracker.state = 0;
end    

