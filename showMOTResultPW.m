function showMOTResultPW()
increment_test_start_offset = 0;
seq_idx_list = [81];
test_start_offset = 0;
vid_start_offset = 0;
n_frames = 500;
while showMOTResult(seq_idx_list, test_start_offset, vid_start_offset, n_frames)
    if increment_test_start_offset
        test_start_offset = test_start_offset + n_frames;
    else
        vid_start_offset = vid_start_offset + n_frames;
    end
end

