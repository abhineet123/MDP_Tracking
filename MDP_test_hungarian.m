% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% testing MDP
function metrics = MDP_test_hungarian(seq_idx, seq_set, tracker, db_type)

if nargin < 4
    db_type = 0;
end

is_show = 0;
is_save = 1;
is_text = 0;
is_pause = 0;
save_images = 0;
check_next_frame = 1;

opt = globals();
opt.is_text = is_text;
opt.exit_threshold = 0.7;

if db_type == 1
    opt.max_occlusion = 20;
    opt.tracked = 10;
    opt.threshold_dis = 1;
    tracker.threshold_dis = opt.threshold_dis;
end

% if is_show
% %     close all;
% end

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
else
    % GRAM and IDOT
    if db_type == 2
        db_path = opt.gram;
        res_path = opt.results_gram;
        test_seqs = opt.gram_seqs;
        test_nums = opt.gram_nums;
        train_ratio = opt.gram_train_ratio;
        test_ratio = opt.gram_test_ratio;
    else
        db_path = opt.idot;
        res_path = opt.results_idot;
        test_seqs = opt.idot_seqs;
        test_nums = opt.idot_nums;
        train_ratio = opt.idot_train_ratio;
        test_ratio = opt.idot_test_ratio;
    end
    seq_name = test_seqs{seq_idx};
    seq_n_frames = test_nums(seq_idx);
    if test_ratio(seq_idx)<=0
        seq_train_ratio = train_ratio(seq_idx);
        [ test_start_idx, test_end_idx ] = getInvSubSeqIdx(seq_train_ratio,...
            seq_n_frames);
    else
        seq_test_ratio = test_ratio(seq_idx);
        [ test_start_idx, test_end_idx ] = getSubSeqIdx(seq_test_ratio,...
            seq_n_frames);
    end
    seq_num = test_end_idx - test_start_idx + 1;
    
    fprintf('Testing sequence %s from frame %d to %d\n',...
        seq_name, test_start_idx, test_end_idx);
    % build the dres structure for images
    filename = sprintf('%s/gram_%s_%d_%d_dres_image.mat',...
        res_path, seq_name, test_start_idx, test_end_idx);
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

%% perform tracking

% intialize tracker
I = dres_image.I{1};
tracker = MDP_initialize_test(tracker, size(I,2), size(I,1), dres_det, is_show);

% for each frame
trackers = [];
id = 0;
start_t = tic;
for fr = 1:seq_num
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
    
    % nms - non maximum suppression
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
    
    % if is_show
    %     figure(1);
    %
    %     % show ground truth
    %     if strcmp(seq_set, 'train') == 1
    %         subplot(2, 2, 1);
    %         show_dres(fr, dres_image.I{fr}, 'GT', dres_gt);
    %     end
    %
    %     % show detections
    % %         subplot(2, 2, 2);
    %     show_dres(fr, dres_image.I{fr}, 'Detections', dres);
    % end
    
    % separate trackers into the first and the second class
    
    % trackers that have been tracking successfully for more than
    % 10 frames are placed first and among these the trackers that
    % are currently in the tracked state are placed first followed by
    % the trackers in the occluded state
    % this is followed by trackers that have been tracking for less
    % than 10 frames which are again arranged in the same way
    % within themselves
    
    % This ensures that trackers that are currently in the tracked state
    % and have been tracked for more frames are processed first followed
    % by trackers that are either currently in occluded state or have been
    % tracked for fewer frames
    % this seems to be some attempt to process more reliable trackers first
    % followed by the less reliable ones
    % for some reason, the trackers within each of the two categories
    % are actually not sorted by the number of tracked frames rather
    % simply by whether they are currently in the tracked
    % state or in the occluded state
    [index1, index2] = sort_trackers_hgn(trackers);
    
    for k = 1:2
        % process trackers in the first class or the second class
        if k == 1
            index_track = index1;
        else
            index_track = index2;
        end
        
        num_track = numel(index_track);
        flags = zeros(num_track, 1);
        
        % process tracked targets
        for i = 1:num_track
            ind = index_track(i);
            if trackers{ind}.state == 0
                flags(i) = 1;
            elseif trackers{ind}.state == 2
                % track target
                trackers{ind} = track(fr, dres_image, dres, trackers{ind}, opt);
                % connect target
                if trackers{ind}.state == 3
                    % all trackers processed thus far
                    if k == 1
                        index_tmp = index_track(1:i-1);
                    else
                        index_tmp = [index_track(1:i-1); index1];
                    end
                    [dres_tmp, index] = generate_initial_index(trackers(index_tmp), dres);
                    dres_associate = sub(dres_tmp, index);
                    trackers{ind} = associate(fr, dres_image,...
                        dres_associate, trackers{ind}, opt, check_next_frame);
                end
                % trackers in tracked or inactive states
                if trackers{ind}.state == 2 || trackers{ind}.state == 0
                    flags(i) = 1;
                end
            end
        end
        
        % process lost targets
        
        if k == 1
            % All trackers processed thus far that were either tracked or lost
            index_tmp = index_track(flags == 1);
        else
            % Same as in the last case except that all of the trackers of
            % the previous index, that is, all trackers with the number of
            % tracked frames exceeding 10 are also included
            index_tmp = [index_track(flags == 1); index1];
        end
        % Remove detections corresponding to currently tracked or inactive targets
        [dres_tmp, index] = generate_initial_index(trackers(index_tmp), dres);
        dres_associate = sub(dres_tmp, index);
        num_det = numel(index);
        
        % compute distance matrix
        
        % Consider only those trackers in the current index
        % that were neither in the tracked state
        % nor in the inactive state, i.e. the occluded and active ones
        % where one may assume that there aren't any trackers in the active 
        % state because as soon as a tracker is initialized, it is
        % moved to the tracked state
        index_track = index_track(flags == 0);
        num_track = numel(index_track);
        dist = zeros(num_track, num_det);
        for i = 1:num_track
            % lost target
            ind = index_track(i);
            dist(i,:) = compute_distance(fr, dres_image, dres_associate, trackers{ind});
        end
        
        % Hungarian algorithm
        assignment = assignmentoptimal(dist);
        
        % process the assignment
        for i = 1:numel(assignment)
            det_id = assignment(i);
            ind = index_track(i);
            if det_id == 0
                % no association
                trackers{ind}.state = 3;
                dres_one = sub(trackers{ind}.dres, numel(trackers{ind}.dres.fr));
                dres_one.fr = fr;
                dres_one.id = trackers{ind}.target_id;
                dres_one.state = 3;
                
                if trackers{ind}.dres.fr(end) == fr
                    dres_tmp = trackers{ind}.dres;
                    index_tmp = 1:numel(dres_tmp.fr)-1;
                    trackers{ind}.dres = sub(dres_tmp, index_tmp);
                end
                trackers{ind}.dres = concatenate_dres(trackers{ind}.dres, dres_one);
            else
                % association
                dres_one = sub(dres_associate, det_id);
                trackers{ind} = LK_associate(fr, dres_image, dres_one, trackers{ind});
                
                trackers{ind}.state = 2;
                % build the dres structure
                dres_one = [];
                dres_one.fr = fr;
                dres_one.id = trackers{ind}.target_id;
                dres_one.x = trackers{ind}.bb(1);
                dres_one.y = trackers{ind}.bb(2);
                dres_one.w = trackers{ind}.bb(3) - trackers{ind}.bb(1);
                dres_one.h = trackers{ind}.bb(4) - trackers{ind}.bb(2);
                dres_one.r = 1;
                dres_one.state = 2;
                if isfield(trackers{ind}.dres, 'type')
                    dres_one.type = {trackers{ind}.dres.type{1}};
                end
                
                if trackers{ind}.dres.fr(end) == fr
                    dres_tmp = trackers{ind}.dres;
                    index_tmp = 1:numel(dres_tmp.fr)-1;
                    trackers{ind}.dres = sub(dres_tmp, index_tmp);
                end
                trackers{ind}.dres = interpolate_dres(trackers{ind}.dres, dres_one);
                % update LK tracker
                trackers{ind} = LK_update(fr, trackers{ind}, dres_image.Igray{fr}, dres_associate, 1);
            end
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
    % if is_show
    %     figure(2);
    %
    %     % show tracking results
    %     subplot(2, 2, 3);
    %     show_dres(fr, dres_image.I{fr}, 'Tracking', dres_track, 2);
    %
    %     % show lost targets
    %     subplot(2, 2, 4);
    %     figure(3);
    %     show_dres(fr, dres_image.I{fr}, 'Lost', dres_track, 3);
    %
    %     if is_pause
    %         pause();
    %     else
    %         pause(0.01);
    %     end
    % end
end
elapsed_time  = toc(start_t);
fprintf('\nTotal time taken: %.2f secs.\nAverage FPS: %.2f\n',...
    elapsed_time, double(seq_num)/double(elapsed_time));

%% write tracking results

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