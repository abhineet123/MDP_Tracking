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

benchmark_dir = fullfile(opt.gram, filesep);
seqs = opt.gram_seqs(seq_idx_list);
evaluateTrackingGRAM(seqs, opt.results_gram, benchmark_dir);