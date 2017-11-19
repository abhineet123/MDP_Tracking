function GRAM_evaluation_only(seq_idx_list, start_offset,...
    one_at_a_time, record_diary)

tic;

opt = globals();

arg_id = 1;
if nargin < arg_id
    seq_idx_list = opt.seq_idx_eval;
end
arg_id = arg_id + 1;
if nargin < arg_id
    start_offset = opt.eval_start_offset;
end
arg_id = arg_id + 1;
if nargin < arg_id
    one_at_a_time = opt.eval_one_at_a_time;
end
arg_id = arg_id + 1;
if nargin < arg_id
    record_diary = opt.record_diary;
end

n_seq_idx = numel(seq_idx_list);
start_idx_list = zeros(n_seq_idx, 1);
end_idx_list = zeros(n_seq_idx, 1);

if record_diary
    if ~exist('datetime')
        log_fname = sprintf('%s/log_eval.txt', opt.results_gram);
    else
        log_fname = sprintf('%s/log_eval_%s.txt', opt.results_gram,...
            char(datetime('now', 'Format','yyMMdd_HHmm')));
    end
    fprintf('Recording output to: %s\n', log_fname);
    diary(log_fname);
end

id = 1;
for seq_idx = seq_idx_list
    seq_n_frames = opt.gram_nums(seq_idx);
	if opt.gram_test_ratio(seq_idx) <= 0
		seq_train_ratio = opt.gram_train_ratio(seq_idx);
        [start_idx, end_idx] = getInvSubSeqIdx(seq_train_ratio,...
            seq_n_frames, start_offset);	
	else
		seq_test_ratio = opt.gram_test_ratio(seq_idx);
        [start_idx, end_idx] = getSubSeqIdx(seq_test_ratio,...
            seq_n_frames, start_offset);
	end
    start_idx_list(id) = start_idx;
    end_idx_list(id) = end_idx;
    id = id + 1;    
end

benchmark_dir = fullfile(opt.gram, filesep);


if one_at_a_time
    id = 1;
    for seq_idx = seq_idx_list
        seq = opt.gram_seqs(seq_idx);
        evaluateTrackingGRAM(seq, opt.results_gram,...
            benchmark_dir, [start_idx_list(id)], [end_idx_list(id)]);
        id = id + 1;
    end
else
    seqs = opt.gram_seqs(seq_idx_list);
    evaluateTrackingGRAM(seqs, opt.results_gram, benchmark_dir,...
        start_idx_list, end_idx_list);
end

t = toc;
fprintf('Time taken: %f secs\n', t);