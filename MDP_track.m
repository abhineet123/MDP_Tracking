% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% MDP value function
function [tracker, qscore, f] = MDP_track(tracker, frame_id, dres_image,...
    dres_det, fig_ids, colors_rgb)
if tracker.state ~= 2
	error('Tracking can only be performed in the tracked state');
end
if nargin<5
    fig_ids = [];
end
if nargin<6
    colors_rgb = {};
end
% extract features with LK tracking
[tracker, f] = MDP_feature_tracked(frame_id, dres_image, dres_det,...
    tracker, fig_ids, colors_rgb);

tracker.f_tracked = f;

% build the dres structure
if bb_isdef(tracker.bb)
	dres_one.fr = frame_id;
	dres_one.id = tracker.target_id;
	dres_one.x = tracker.bb(1);
	dres_one.y = tracker.bb(2);
    % yet another instance of the annoying horrible insidious bug where the
    % +1 is simply ignored
	dres_one.w = tracker.bb(3) - tracker.bb(1) + 1;
	dres_one.h = tracker.bb(4) - tracker.bb(2) + 1;
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
	tracker = LK_update(frame_id, tracker, dres_image.Igray{frame_id},...
        dres_det, 0);
else
	% transfer to occluded
	tracker.state = 3;
	dres_one.state = 3;
	tracker.dres = concatenate_dres(tracker.dres, dres_one);        
end
tracker.prev_state = 2;
if tracker.pause_for_debug
    debugging = 1;
end
