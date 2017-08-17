% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% cross_validation on the KITTI benchmark
function GRAM_test(is_train, seq_idx_train, seq_idx_test,...
    continue_from_seq, use_hungarian, show_cropped_figs,...
    save_video, batch_size)

% set is_train to 0 if testing trained trackers only
if nargin<1
    is_train = 1;
end
if nargin<3
    % seq_idx_train = {[1:9, 16:24], [31:50]};
    % seq_idx_test = {[10:15, 25:30], [51:60]};
    
    % seq_idx_train = {[1, 2], [3]};
    % seq_idx_test = {[1, 2], [3]};
    
    seq_idx_train = {[3]};
    seq_idx_test = {[1]};
end
if nargin<4
    continue_from_seq = 0;
end
if nargin<5
    use_hungarian = 0;
end
if nargin<6
    show_cropped_figs = 0;
end
if nargin<7
    save_video = 0;
end
if nargin<7
    save_video = 0;
end
db_type = 2;
opt = globals();
seq_set_test = 'testing';
N = max([numel(seq_idx_train),numel(seq_idx_test)]);

if ~exist('datetime')
    log_fname = sprintf('%s/log.txt', opt.results_gram);
else
    log_fname = sprintf('%s/log_%s.txt', opt.results_gram,...
        char(datetime('now', 'Format','yyMMdd_HHmm')));
end

diary(log_fname);

if use_hungarian
    fprintf('Using Hungarian variant\n');
end

% for each training-testing pair
for i = 1:N
    % training
    if numel(seq_idx_train)<i
        idx_train = seq_idx_train{end};
        fprintf('Insufficient training indices %d provioded for testing idx %d\n',...
            numel(seq_idx_train), i);
        fprintf('Using the last index instead:\n');
        disp(idx_train);
    else
        idx_train = seq_idx_train{i};
    end
    
    tracker = [];
    if ~is_train || continue_from_seq
        % load tracker from file
        if continue_from_seq
            seq_idx = continue_from_seq;
        else
            seq_idx = idx_train(end);
        end
        seq_name = opt.gram_seqs{seq_idx};
        seq_n_frames = opt.gram_nums(seq_idx);
        seq_train_ratio = opt.gram_train_ratio(seq_idx);
        [train_start_idx, train_end_idx] = getSubSeqIdx(seq_train_ratio,...
            seq_n_frames);
        filename = sprintf('%s/gram_%s_%d_%d_tracker.mat',...
            opt.results_gram, seq_name, train_start_idx, train_end_idx);
        fprintf('loading tracker from file %s\n', filename);
        object = load(filename);
        tracker = object.tracker;
    end
    
    if is_train
        % number of training sequences
        num = numel(idx_train);
        % online training
        for j = 1:num
            fprintf('Online training on sequence: %s\n', opt.gram_seqs{idx_train(j)});
            tracker = MDP_train(idx_train(j), tracker, db_type);
        end
        fprintf('%d training examples after online training\n', size(tracker.f_occluded, 1));
    end
    
    % testing
    if numel(seq_idx_test)<i
        idx_test = seq_idx_test{end};
        fprintf('Insufficient testing indices %d provioded for training idx %d\n',...
            numel(seq_idx_test), i);
        fprintf('Using the last index instead:\n');
        disp(idx_test);
    else
        idx_test = seq_idx_test{i};
    end
    % number of testing sequences
    num = numel(idx_test);
    for j = 1:num
        fprintf('Testing on sequence: %s\n', opt.gram_seqs{idx_test(j)});
        if use_hungarian
            dres_track = MDP_test_hungarian(idx_test(j), seq_set_test,...
                tracker, db_type, 0);
        else
            dres_track = MDP_test(idx_test(j), seq_set_test, tracker, db_type,...
                0, show_cropped_figs, save_video);
        end
    end
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
    GRAM_evaluation_only(idx_test, 0);
end
