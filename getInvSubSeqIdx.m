function [start_idx, end_idx] = getInvSubSeqIdx(sub_seq_ratio, n_frames,...
    start_offset)
if nargin < 3
    start_offset = 0;
end
if sub_seq_ratio < 0
    start_idx = int32(1 + start_offset);
    end_idx = int32(n_frames*(1 + sub_seq_ratio)) + start_offset - 1;
else
    start_idx = int32(n_frames * sub_seq_ratio) - start_offset + 1;
    end_idx = int32(n_frames - start_offset);
end
end
