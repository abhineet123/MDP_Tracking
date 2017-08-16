% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% testing MDP
function metrics = MDP_test(seq_idx, seq_set, tracker, db_type,...
    show_cropped_figs)
global pause_exec

pause_exec = 1;

if nargin < 4
    db_type = 0;
end
if nargin < 5
    show_cropped_figs = 0;
end
is_show = 0;   % set is_show to 1 to show tracking results in testing
is_save = 1;   % set is_save to 1 to save tracking result
is_text = 0;   % set is_text to 1 to display detailed info
is_pause = 0;  % set is_pause to 1 to debug
save_images = 0;

fig_ids = [];
fig_ids_track = [];
colors_rgb = {};
if show_cropped_figs
    fig_ids(1) = figure;
    fig_ids(2) = figure;
    set(fig_ids(1),'WindowButtonDownFcn',@ButtonDown);
    set(fig_ids(2),'WindowButtonDownFcn',@ButtonDown);
    
    fig_ids_track(1) = figure;
    fig_ids_track(2) = figure;  
    % fig_ids_track(3) = figure;   
    set(fig_ids_track(1),'WindowButtonDownFcn',@ButtonDown);
    set(fig_ids_track(2),'WindowButtonDownFcn',@ButtonDown);
    
    colRGBDefs;
    colors={
        'blue',...%1
        'red',...%2
        'green',...%3
        'cyan',...%4
        'magenta',...%5
        'yellow',...%6
        'forest_green',...%7
        'slate_gray',...%8
        'peach_puff_3',...%9
        'maroon',...%10
        'purple',...%11
        'orange',...%12
        'gold'...%13
        };
    n_cols = length(colors);
    colors_rgb = cell(n_cols, 1);
    for i = 1:n_cols
        colors_rgb{i} = col_rgb{strcmp(col_names,colors{i})};
    end
end

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
    db_path = opt.mot;
    res_path = opt.results_gram;
    if strcmp(seq_set, 'train') == 1
        test_seqs = opt.mot2d_train_seqs{seq_idx};
        test_nums = opt.mot2d_train_nums(seq_idx);
    else
        test_seqs = opt.mot2d_test_seqs{seq_idx};
        test_nums = opt.mot2d_test_nums(seq_idx);
    end
elseif db_type == 1    
    db_path = opt.kitti;
    res_path = opt.results_gram;
    if strcmp(seq_set, 'training') == 1
        test_seqs = opt.kitti_train_seqs{seq_idx};
        test_nums = opt.kitti_train_nums(seq_idx);
    else
        test_seqs = opt.kitti_test_seqs{seq_idx};
        test_nums = opt.kitti_test_nums(seq_idx);
    end
elseif db_type == 2
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
% Reset that trained tracker fields corresponding to the input images and 
% the detections such as the size of the input image and the maximum size
% and score of the detections
tracker = MDP_initialize_test(tracker, size(I,2), size(I,1),...
    dres_det, is_show);

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
    
    % get all the detections in this frame    
    index = find(dres_det.fr == fr);
    dres = sub(dres_det, index);
    
    % nms
    if db_type == 1
        boxes = [dres.x dres.y dres.x+dres.w dres.y+dres.h dres.r];
        index = nms_new(boxes, 0.6);
        dres = sub(dres, index);
        
        % only keep cars and pedestrians
        ind = strcmp('Car', dres.type) | strcmp('Pedestrian', dres.type);
        index = find(ind == 1);
        dres = sub(dres, index);        
    end
    
    % Extract an image patch around each of the detections so that
    % the optical flow might be carried out from the last known
    % location of the tracked object to all of these patches
    % to see which one is easiest to track and therefore
    % most likely to correspond to the tracked object    
    dres = MDP_crop_image_box(dres, dres_image.Igray{fr}, tracker,...
        fig_ids, colors_rgb);
    
    % if is_show
    %     figure(1);
    %
    %     % show ground truth
    %     if strcmp(seq_set, 'train') == 1 || strcmp(seq_set, 'training') == 1
    %         subplot(2, 2, 1);
    %         show_dres(fr, dres_image.I{fr}, 'GT', dres_gt);
    %     end
    %
    %     % show detections
    %     subplot(2, 2, 2);
    %     show_dres(fr, dres_image.I{fr}, 'Detections', dres);
    % end

    % sort trackers by no. of tracked frames
    
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
            trackers{ind} = track(fr, dres_image, dres, trackers{ind}, opt,...
                fig_ids_track, colors_rgb);
            % connect target
            % Check if the tracking failure can be fixed by using the detections
            if trackers{ind}.state == 3
                % Remove detections corresponding to tracker bounding boxes that
                % have already been tracked
                [dres_tmp, index] = generate_initial_index(trackers(index_track(1:i-1)),...
                    dres);
                dres_associate = sub(dres_tmp, index);
                % Of the remaining detections, find those that are close to
                % the predicted location of this object based on its last
                % known location and its velocity in all of the frames that
                % it has been tracked in so far
                % next, we check if trying to track this object from this last
                % known location to any of these matched detections can work
                trackers{ind} = associate(fr, dres_image,  dres_associate,...
                    trackers{ind}, opt, 1);
            end
        elseif trackers{ind}.state == 3
            % associate target
            
            % Repeat the same steps as were performed when the tracker was first
            % found to be in the occluded state except that now they are
            % performed in the new frame after we failed to associate the lost
            % tracker with any of the detections in the frame
            % where it was first found to be occluded
            [dres_tmp, index] = generate_initial_index(trackers(index_track(1:i-1)), dres);
            dres_associate = sub(dres_tmp, index);    
            trackers{ind} = associate(fr, dres_image, dres_associate, trackers{ind}, opt, 1);
        end
        if show_cropped_figs
            if pause_exec
                k = waitforbuttonpress;
            else
                pause(0.0001);
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
        % Check if this detection is a true positive for a false positive
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
    
    % Check for multiple trackers tracking the same object or
    % the objects tracked by different trackers being present
    % in roughly the same location within the scene so that
    % one of them is occluded by the other
    % if that is the case, then we use some heuristics based on
    % the number of frames for which these objects have been
    % tracked as well as the maximum overlap of these objects
    % with the detections to decide which one of the two
    % will be suppressed
    % by suppressed to be mean that it is marked as occluded
    trackers = resolve(trackers, dres, opt);    
    % Concatenates the bounding boxes of all of the trackers to
    % gather in the same structure for writing out to the
    % output file
    dres_track = generate_results(trackers);
    % if is_show
    %     figure(1);
    %
    %     % show tracking results
    %     subplot(2, 2, 3);
    %     show_dres(fr, dres_image.I{fr}, 'Tracking', dres_track, 2);
    %
    %     % show lost targets
    %     subplot(2, 2, 4);
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
end

function ButtonDown(hObject, eventdata)
    global pause_exec
    pause_exec = 1 - pause_exec;
end
