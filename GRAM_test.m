% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% cross_validation on the KITTI benchmark
function GRAM_test

% set is_train to 0 if testing trained trackers only
is_train = 1;
db_type = 2;
opt = globals();

seq_idx_train = {[1:9;16:24], [31:50]};
seq_idx_test = {[10:15; 25:30], [51:60]};

% seq_idx_train = {[1:9]};
% seq_idx_test = {[10:15]};

seq_set_test = 'testing';
N = numel(seq_idx_train);

% for each training-testing pair
for i = 1:N
    % training
    idx_train = seq_idx_train{i};
    
    if is_train
        % number of training sequences
        num = numel(idx_train);
        tracker = [];
        
        % online training
        for j = 1:num
            fprintf('Online training on sequence: %s\n', opt.gram_seqs{idx_train(j)});
            tracker = MDP_train(idx_train(j), tracker, db_type);
        end
        fprintf('%d training examples after online training\n', size(tracker.f_occluded, 1));
        
    else
        % load tracker from file
        filename = sprintf('%s/gram_%s_tracker.mat',...
            opt.results_gram, opt.gram_seqs{idx_train(end)});
        object = load(filename);
        tracker = object.tracker;
        fprintf('load tracker from file %s\n', filename);
    end
    
    % testing
    idx_test = seq_idx_test{i};
    % number of testing sequences
    num = numel(idx_test);
    for j = 1:num
        fprintf('Testing on sequence: %s\n', opt.gram_seqs{idx_test(j)});
        MDP_test(idx_test(j), seq_set_test, tracker, db_type);
    end
end