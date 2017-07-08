% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% testing MDP
function metrics = MDP_test(seq_idx, seq_set, tracker, db_type)

if nargin < 4
    db_type = 0;
end

is_show = 0;   % set is_show to 1 to show tracking results in testing
is_save = 1;   % set is_save to 1 to save tracking result
is_text = 0;   % set is_text to 1 to display detailed info
is_pause = 0;  % set is_pause to 1 to debug
save_images = 0;

opt = globals();
opt.is_text = is_text;

if db_type == 1
    opt.exit_threshold = 0.5;
    opt.max_occlusion = 20;
    opt.tracked = 5;
else
    opt.exit_threshold = 0.7;
end

if db_type == 0
    db_name = 'MOT2015';
    db_path = opt.mot;
elseif db_type == 1
    db_name = 'KITTI';
    db_path = opt.kitti;
elseif db_type == 2
    db_name = 'GRAM';
    db_path = opt.gram;
else
    db_name = 'IDOT';
    db_path = opt.idot;
end

if is_show
    close all;
end

if db_type == 0
    if strcmp(seq_set, 'train') == 1
        seq_name = opt.mot2d_train_seqs{seq_idx};
        seq_num = opt.mot2d_train_nums(seq_idx);
    else
        seq_name = opt.mot2d_test_seqs{seq_idx};
        seq_num = opt.mot2d_test_nums(seq_idx);
    end

    % build the dres structure for images
    filename = sprintf('%s/%s_dres_image.mat', opt.results, seq_name);
    if exist(filename, 'file') ~= 0
        object = load(filename);
        dres_image = object.dres_image;
        fprintf('load images from file %s done\n', filename);
    else
        dres_image = read_dres_image(opt, seq_set, seq_name, seq_num);
        fprintf('read images done\n');
		if save_images
			save(filename, 'dres_image', '-v7.3');
		end
    end

    % read detections
    filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'det', 'det.txt');
    dres_det = read_mot2dres(filename);

    if strcmp(seq_set, 'train') == 1
        % read ground truth
        filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'gt', 'gt.txt');
        dres_gt = read_mot2dres(filename);
        dres_gt = fix_groundtruth(seq_name, dres_gt);
    end
    test_start_idx = 1;
    test_end_idx = seq_num;
elseif db_type == 1
    if strcmp(seq_set, 'training') == 1
        seq_name = opt.kitti_train_seqs{seq_idx};
        seq_num = opt.kitti_train_nums(seq_idx);
    else
        seq_name = opt.kitti_test_seqs{seq_idx};
        seq_num = opt.kitti_test_nums(seq_idx);
    end

    % build the dres structure for images
    filename = sprintf('%s/kitti_%s_%s_dres_image.mat', opt.results_kitti, seq_set, seq_name);
    if exist(filename, 'file') ~= 0
        object = load(filename);
        dres_image = object.dres_image;
        fprintf('load images from file %s done\n', filename);
    else
        dres_image = read_dres_image_kitti(opt, seq_set, seq_name, seq_num);
        fprintf('read images done\n');
		if save_images
			save(filename, 'dres_image', '-v7.3');
		end
    end

    % read detections
    filename = fullfile(opt.kitti, seq_set, 'det_02', [seq_name '.txt']);
    dres_det = read_kitti2dres(filename);    

    if strcmp(seq_set, 'training') == 1
        % read ground truth
        filename = fullfile(opt.kitti, seq_set, 'label_02', [seq_name '.txt']);
        dres_gt = read_kitti2dres(filename);
    end
    test_start_idx = 1;
    test_end_idx = seq_num;
else
    % GRAM
    seq_name = opt.gram_seqs{seq_idx};
    seq_n_frames = opt.gram_nums(seq_idx);
	if isempty(opt.gram_test_ratio)
		seq_train_ratio = opt.gram_train_ratio(seq_idx);
        [ test_start_idx, test_end_idx ] = getInvSubSeqIdx(seq_train_ratio,...
            seq_n_frames);	
	else
		seq_test_ratio = opt.gram_test_ratio(seq_idx);
        [ test_start_idx, test_end_idx ] = getSubSeqIdx(seq_test_ratio,...
            seq_n_frames);
	end
    seq_num = seq_n_frames;

    fprintf('Testing sequence %s from frame %d to %d\n',...
        seq_name, test_start_idx, test_end_idx);
    % build the dres structure for images
    filename = sprintf('%s/gram_%s_%d_%d_dres_image.mat',...
        opt.results_gram, seq_name, test_start_idx, test_end_idx);
    if exist(filename, 'file') ~= 0
        object = load(filename);
        dres_image = object.dres_image;
        fprintf('load images from file %s done\n', filename);
    else
        fprintf('reading images....\n');
        dres_image = read_dres_image_gram(db_path, seq_name,...
            test_start_idx, test_end_idx);
        fprintf('done\n');
		if save_images
			save(filename, 'dres_image', '-v7.3');
		end
    end

    % read detections
    filename = fullfile(db_path, 'Detections', [seq_name '.txt']);
    dres_det = read_gram2dres(filename, test_start_idx, test_end_idx);    

    if strcmp(seq_set, 'training') == 1
        % read ground truth
        filename = fullfile(db_path, 'Annotations', [seq_name '.txt']);
        dres_gt = read_gram2dres(filename, test_start_idx, test_end_idx);
    end
end

% load the trained model
if nargin < 3
    object = load('tracker.mat');
    tracker = object.tracker;
end

% intialize tracker
I = dres_image.I{test_start_idx};
tracker = MDP_initialize_test(tracker, size(I,2), size(I,1), dres_det, is_show);

% for each frame
trackers = [];
id = 0;
for fr = test_start_idx:test_end_idx
    if is_text
        fprintf('frame %d\n', fr);
    else
        fprintf('.');
        if mod(fr, 100) == 0
            fprintf('\n');
        end        
    end
    
    % extract detection
    index = find(dres_det.fr == fr);
    dres = sub(dres_det, index);
    
    % nms
    if db_type==1
        boxes = [dres.x dres.y dres.x+dres.w dres.y+dres.h dres.r];
        index = nms_new(boxes, 0.6);
        dres = sub(dres, index);
        
        % only keep cars and pedestrians
        ind = strcmp('Car', dres.type) | strcmp('Pedestrian', dres.type);
        index = find(ind == 1);
        dres = sub(dres, index);        
    end
    
    dres = MDP_crop_image_box(dres, dres_image.Igray{fr}, tracker);
    
    if is_show
        figure(1);
        
        % show ground truth
        if strcmp(seq_set, 'train') == 1 || strcmp(seq_set, 'training') == 1
            subplot(2, 2, 1);
            show_dres(fr, dres_image.I{fr}, 'GT', dres_gt);
        end

        % show detections
        subplot(2, 2, 2);
        show_dres(fr, dres_image.I{fr}, 'Detections', dres);
    end
    
    % sort trackers
    if db_type == 1
        index_track = sort_trackers_kitti(fr, trackers, dres, opt);        
    else
        index_track = sort_trackers(trackers);
    end
    
    % process trackers
    for i = 1:numel(index_track)
        ind = index_track(i);
        
        if trackers{ind}.state == 2
            % track target
            trackers{ind} = track(fr, dres_image, dres, trackers{ind}, opt);
            % connect target
            if trackers{ind}.state == 3
                [dres_tmp, index] = generate_initial_index(trackers(index_track(1:i-1)), dres);
                dres_associate = sub(dres_tmp, index);
                trackers{ind} = associate(fr, dres_image,  dres_associate, trackers{ind}, opt);
            end
        elseif trackers{ind}.state == 3
            % associate target
            [dres_tmp, index] = generate_initial_index(trackers(index_track(1:i-1)), dres);
            dres_associate = sub(dres_tmp, index);    
            trackers{ind} = associate(fr, dres_image, dres_associate, trackers{ind}, opt);
        end
    end
    
    % find detections for initialization
    [dres, index] = generate_initial_index(trackers, dres);
    for i = 1:numel(index)
        % extract features
        dres_one = sub(dres, index(i));
        f = MDP_feature_active(tracker, dres_one);
        % prediction
        label = svmpredict(1, f, tracker.w_active, '-q');
        % make a decision
        if label < 0
            continue;
        end
        
        % reset tracker
        tracker.prev_state = 1;
        tracker.state = 1;            
        id = id + 1;
        
        trackers{end+1} = initialize(fr, dres_image, id, dres, index(i), tracker);
    end
    
    % resolve tracker conflict
    trackers = resolve(trackers, dres, opt);    
    
    dres_track = generate_results(trackers);
    if is_show
        figure(1);

        % show tracking results
        subplot(2, 2, 3);
        show_dres(fr, dres_image.I{fr}, 'Tracking', dres_track, 2);

        % show lost targets
        subplot(2, 2, 4);
        show_dres(fr, dres_image.I{fr}, 'Lost', dres_track, 3);

        if is_pause
            pause();
        else
            pause(0.01);
        end
    end  
end

% write tracking results
if db_type == 0
    filename = sprintf('%s/%s.txt', opt.results, seq_name);
    fprintf('write results: %s\n', filename);
    write_tracking_results(filename, dres_track, opt.tracked);

    % evaluation
    if strcmp(seq_set, 'train') == 1
        benchmark_dir = fullfile(opt.mot, opt.mot2d, seq_set, filesep);
        metrics = evaluateTracking({seq_name}, opt.results, benchmark_dir);
    else
        metrics = [];
    end

    % save results
    if is_save
        filename = sprintf('%s/%s_results.mat', opt.results, seq_name);
        save(filename, 'dres_track', 'metrics');
    end
elseif db_type == 1
    filename = sprintf('%s/%s.txt', opt.results_kitti, seq_name);
    fprintf('write results: %s\n', filename);
    write_tracking_results_kitti(filename, dres_track, opt.tracked);
    
    % evaluation
    if strcmp(seq_set, 'training') == 1
        % write a temporal seqmap file
        filename = sprintf('%s/evaluate_tracking.seqmap', opt.results_kitti);
        fid = fopen(filename, 'w');
        fprintf(fid, '%s empty %06d %06d\n', seq_name, 0, seq_num);
        fclose(fid);
        system('python evaluate_tracking_kitti.py results_kitti');
    end
    
    % save results
    if is_save
        filename = sprintf('%s/kitti_%s_%s_results.mat', opt.results_kitti, seq_set, seq_name);
        save(filename, 'dres_track');
    end   
else
    filename = sprintf('%s/%s_%d_%d.txt', opt.results_gram, seq_name,...
        test_start_idx, test_end_idx);
    fprintf('writing results to: %s\n', filename);
    write_tracking_results(filename, dres_track, opt.tracked);

    % save results
    if is_save
        filename = sprintf('%s/%s_%d_%d_results.mat', opt.results,...
            seq_name, test_start_idx, test_end_idx);
        save(filename, 'dres_track');
    end 
end

% sort trackers according to number of tracked frames
function index = sort_trackers(trackers)

sep = 10;
num = numel(trackers);
len = zeros(num, 1);
state = zeros(num, 1);
for i = 1:num
    len(i) = trackers{i}.streak_tracked;
    state(i) = trackers{i}.state;
end

index1 = find(len > sep);
[~, ind] = sort(state(index1));
index1 = index1(ind);

index2 = find(len <= sep);
[~, ind] = sort(state(index2));
index2 = index2(ind);
index = [index1; index2];


% sort trackers according to number of tracked frames
function index = sort_trackers_kitti(fr, trackers, dres, opt)

sep = 10;
num = numel(trackers);
num_det = numel(dres.fr);
len = zeros(num, 1);
state = zeros(num, 1);
overlap = zeros(num, 1);
for i = 1:num
    len(i) = trackers{i}.streak_tracked;
    state(i) = trackers{i}.state;
    
    % predict the new location
    if state(i) > 0 && num_det > 0
        [ctrack, wh] = apply_motion_prediction(fr-1, trackers{i});
        dres_one.x = ctrack(1) - wh(1) / 2;
        dres_one.y = ctrack(2) - wh(2) / 2;
        dres_one.w = wh(1);
        dres_one.h = wh(2);
        
        if dres_one.w > 0 && dres_one.h > 0 && opt.is_text
            figure(1); hold on;
            rectangle('Position', [dres_one.x dres_one.y dres_one.w dres_one.h], 'EdgeColor', 'r');
            hold off;
        end
        
        ov = calc_overlap(dres_one, 1, dres, 1:num_det);
        overlap(i) = max(ov);
    end
end

index1 = find(len > sep);
% tracked objects
index_tracked = index1(state(index1) == 2);
[~, ind] = sort(overlap(index_tracked), 'descend');
index_tracked = index_tracked(ind);
% lost objects
index_lost = index1(state(index1) == 3);
[~, ind] = sort(overlap(index_lost), 'descend');
index_lost = index_lost(ind);
index1 = [index_tracked; index_lost];

index2 = find(len <= sep);
% tracked objects
index_tracked = index2(state(index2) == 2);
[~, ind] = sort(len(index_tracked), 'descend');
index_tracked = index_tracked(ind);
% lost objects
index_lost = index2(state(index2) == 3);
[~, ind] = sort(len(index_lost), 'descend');
index_lost = index_lost(ind);
index2 = [index_tracked; index_lost];

index = [index1; index2];

if opt.is_text
    fprintf('order: ');
    for i = 1:numel(index)
        fprintf('%d %.2f, %d\n', index(i), overlap(index(i)), len(index(i)));
    end
    fprintf('\n');
end


% initialize a tracker
% dres: detections
function tracker = initialize(fr, dres_image, id, dres, ind, tracker)

if tracker.state ~= 1
    return;
else  % active

    % initialize the LK tracker
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


% associate a lost target
function tracker = associate(fr, dres_image, dres_associate, tracker, opt)

% occluded
if tracker.state == 3
    tracker.streak_occluded = tracker.streak_occluded + 1;
    % find a set of detections for association
    [dres_associate, index_det] = generate_association_index(tracker, fr, dres_associate);
    tracker = MDP_value(tracker, fr, dres_image, dres_associate, index_det);
    if tracker.state == 2
        tracker.streak_occluded = 0;
        if opt.is_text
            fprintf('target %d associated\n', tracker.target_id);
        end
    else
        if opt.is_text
            fprintf('target %d not associated\n', tracker.target_id);
        end
    end

    if tracker.streak_occluded > opt.max_occlusion
        tracker.state = 0;
        if opt.is_text
            fprintf('target %d exits due to long time occlusion\n', tracker.target_id);
        end
    end
    
    % check if target outside image
    [~, ov] = calc_overlap(tracker.dres, numel(tracker.dres.fr), dres_image, fr);
    
    % predict the new location
    ctrack = apply_motion_prediction(fr+1, tracker);
    dres_one.x = ctrack(1);
    dres_one.y = ctrack(2);
    dres_one.w = tracker.dres.w(end);
    dres_one.h = tracker.dres.h(end);
    [~, ov1] = calc_overlap(dres_one, 1, dres_image, fr);
    
    if ov < opt.exit_threshold || (ov1 < 0.05 && tracker.state == 3)
        if opt.is_text
            fprintf('target outside image by checking boarders\n');
        end
        tracker.state = 0;
    end    
end


% resolve conflict between trackers
function trackers = resolve(trackers, dres_det, opt)

% collect dres from trackers
dres_track = [];
for i = 1:numel(trackers)
    tracker = trackers{i};
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
    [~, o] = calc_overlap(dres_track, i, dres_track, 1:num_track);
    o(i) = 0;
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
        num1 = trackers{dres_track.id(i)}.streak_tracked;
        num2 = trackers{dres_track.id(ind)}.streak_tracked;
        o1 = max(calc_overlap(dres_track, i, dres_det, 1:num_det));
        o2 = max(calc_overlap(dres_track, ind, dres_det, 1:num_det));
        
        if num1 > num2
            sup = ind;
        elseif num1 < num2
            sup = i;
        else
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