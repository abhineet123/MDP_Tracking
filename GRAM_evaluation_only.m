clear all;
opt = globals();
% start_idx = 51;
% end_idx = 60;
seq_idx_list = [1];
% seq_idx_list = [10:15];
% seq_idx_list = [25:30];
% seq_idx_list = [51:60];
% seq_idx_list = [10:15, 25:30];
% seq_idx_list = [10:15, 25:30, 51:60];
n_seq_idx = numel(seq_idx_list);
start_idx_list = zeros(n_seq_idx, 1);
end_idx_list = zeros(n_seq_idx, 1);
id = 1;
for seq_idx = seq_idx_list
    seq_n_frames = opt.gram_nums(seq_idx);
	if isempty(opt.gram_test_ratio)
		seq_train_ratio = opt.gram_train_ratio(seq_idx);
        [start_idx, end_idx] = getInvSubSeqIdx(seq_train_ratio,...
            seq_n_frames);	
	else
		seq_test_ratio = opt.gram_test_ratio(seq_idx);
        [start_idx, end_idx] = getSubSeqIdx(seq_test_ratio,...
            seq_n_frames);
	end
    start_idx_list(id) = start_idx;
    end_idx_list(id) = end_idx;
    id = id + 1;    
end
benchmark_dir = fullfile(opt.gram, filesep);
seqs = opt.gram_seqs(seq_idx_list);
evaluateTrackingGRAM(seqs, opt.results_gram, benchmark_dir,...
    start_idx_list, end_idx_list);