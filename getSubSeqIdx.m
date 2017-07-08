function [start_idx, end_idx] = getSubSeqIdx( sub_seq_ratio, n_frames,...
    start_offset)
if nargin<3
    start_offset = 0;
end
if sub_seq_ratio < 0
    start_idx = int32(n_frames*(1 + sub_seq_ratio)) - start_offset;
    end_idx = n_frames - start_offset;
else
    start_idx = start_offset + 1;
    end_idx = int32(n_frames * sub_seq_ratio) + start_offset;
end
end

