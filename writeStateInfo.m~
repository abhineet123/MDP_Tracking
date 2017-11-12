function writeStateInfo(tracker, write_to_bin, sync_id, is_test)

fp_fmt = '%.4f';
fp_dtype = 'float32';

root_dir = sprintf('log/target_%d', tracker.target_id);

tracker.features(:, 1) = tracker.medFBs;
tracker.features(:, 2) = tracker.medFBs_left;
tracker.features(:, 3) = tracker.medFBs_right;
tracker.features(:, 4) = tracker.medFBs_up;
tracker.features(:, 5) = tracker.medFBs_down;
tracker.features(:, 6) = tracker.medNCCs;
roi = zeros(numel(tracker.Is{1}), tracker.num);
for i = 1:tracker.num
    roi(:, i) = tracker.Is{i}(:);
end

locations = zeros(tracker.num, 4);
locations(:, 1) = tracker.x1;
locations(:, 2) = tracker.y1;
locations(:, 3) = tracker.x2 - tracker.x1 + 1;
locations(:, 4) = tracker.y2 - tracker.y1 + 1;

entries = {
    {locations, 'locations', fp_dtype, fp_fmt},...
    {tracker.overlaps, 'overlaps', fp_dtype, fp_fmt},...
    {tracker.angles, 'angles', fp_dtype, fp_fmt},...
    {tracker.ratios, 'ratios', fp_dtype, fp_fmt},...
    {tracker.bb_overlaps, 'bb_overlaps', fp_dtype, fp_fmt},...
    {tracker.nccs, 'similarity', fp_dtype, fp_fmt},...
    {tracker.scores, 'scores', fp_dtype, fp_fmt},...
    {tracker.patterns, 'patterns', fp_dtype, fp_fmt},...
    {tracker.features, 'features', fp_dtype, fp_fmt},...
    {roi, 'roi', 'uint8', '%d'},...
    {tracker.indexes - 1, 'indices', 'uint32', '%d'},...
    {tracker.flags, 'flags', 'uint8', '%d'},...
    };
writeToFiles(sprintf('%s/templates', root_dir), write_to_bin, entries);

history_locations = zeros(numel(tracker.dres.fr), 4);
history_locations(:, 1) = tracker.dres.x;
history_locations(:, 2) = tracker.dres.y;
history_locations(:, 3) = tracker.dres.w;
history_locations(:, 4) = tracker.dres.h;

entries = {
    {tracker.dres.r, 'scores', fp_dtype, fp_fmt},...
    {history_locations, 'locations', fp_dtype, fp_fmt},...
    {tracker.dres.id, 'ids', 'uint32', '%d'},...
    {tracker.dres.fr - 1, 'frame_ids', 'uint32', '%d'},...
    {tracker.dres.state, 'states', 'uint8', '%d'},...
    };
writeToFiles(sprintf('%s/history', root_dir), write_to_bin, entries);

if tracker.prev_state == 1
    entries = {
        {tracker.factive, 'train_features', fp_dtype, fp_fmt},...
        {tracker.lactive, 'train_labels', fp_dtype, fp_fmt},...
        };
        if ~isempty(tracker.f_test_active) 
            entries{end + 1} = {tracker.f_test_active, 'features',...
                fp_dtype, fp_fmt};
        end
    writeToFiles(sprintf('%s/active', root_dir), write_to_bin, entries);
else
    points = zeros(numel(tracker.points{1}), tracker.num);
    lk_locations = zeros(tracker.num, 4);
    valid_lk_locations = 1;
    for i = 1:tracker.num
        if isempty(tracker.bbs_orig{i})
            valid_lk_locations = 0;
            break;
        end
        lk_locations(i, :) = tracker.bbs_orig{i}(:);
        points(:, i) = tracker.points{i}(:);        
    end
    if valid_lk_locations
        lk_locations(:, 3:4) = lk_locations(:, 3:4) - lk_locations(:, 1:2) + 1;
        entries = {
            {points, 'lk_out', fp_dtype, fp_fmt},...
            {lk_locations, 'locations', fp_dtype, fp_fmt},...
            %{tracker.shifts, 'shifts', fp_dtype, fp_fmt},...
            };
        writeToFiles(sprintf('%s/lkcv', root_dir), write_to_bin, entries);
    end
    if tracker.prev_state == 2
        tracked_locations = zeros(tracker.num, 4);
        for i = 1:tracker.num
            tracked_locations(i, :) = tracker.bbs{i}(:);
        end
        tracked_locations(:, 3:4) = tracked_locations(:, 3:4) - tracked_locations(:, 1:2) + 1;
        entries = {
            {tracker.f_tracked', 'features', fp_dtype, fp_fmt},...
            {tracked_locations, 'locations', fp_dtype, fp_fmt},...
            {tracker.J_crop, 'roi', 'uint8', '%d'},...
            };
        writeToFiles(sprintf('%s/tracked', root_dir), write_to_bin, entries);    
    elseif tracker.prev_state == 3
        entries = {};
        trunc_idx = 1:tracker.fnum_occluded;
        trunc_idx(8) = [];
        if ~is_test
            f_occluded_trunc = tracker.f_occluded(:, trunc_idx); 
            entries{end + 1} =  {f_occluded_trunc, 'train_features', fp_dtype, fp_fmt};
            entries{end + 1} =  {tracker.l_occluded, 'train_labels', fp_dtype, fp_fmt};
        end           
        if ~isempty(tracker.J_crops) 
            n_det = numel(tracker.J_crops);
            occ_roi = zeros(n_det, numel(tracker.J_crops{1}));
            for i = 1:n_det
                occ_roi(i, :) = tracker.J_crops{i}(:);
            end
            entries{end + 1} = {occ_roi, 'roi', 'uint8', '%d'};
        end
        if ~isempty(tracker.f_test_occluded)
            f_test_occluded_trunc = tracker.f_test_occluded(:, trunc_idx); 
            entries{end + 1} = {f_test_occluded_trunc, 'features', fp_dtype, fp_fmt};
        end
        if ~isempty(tracker.l_test_occluded)
            entries{end + 1} = {tracker.l_test_occluded, 'labels', fp_dtype, fp_fmt};
        end
        if ~isempty(tracker.probs_occluded)
            entries{end + 1} = {tracker.probs_occluded, 'probabilities', fp_dtype, fp_fmt};
        end
        writeToFiles(sprintf('%s/lost', root_dir), write_to_bin, entries);
    end
end
    

if sync_id > 0
    sync_w_fname = sprintf('%s/write_%d.sync', root_dir, sync_id);
    fclose(fopen(sync_w_fname, 'w'));
    sync_r_fname = sprintf('%s/read_%d.sync', root_dir, sync_id);
    fprintf('Waiting for %s...',sync_r_fname);
    pause('on')
    iter_id = 0;
    max_iters = 10;
    while ~exist(sync_r_fname, 'file')
        pause(0.5);
        iter_id = iter_id + 1;
        if iter_id == max_iters
            % pause for debugging after 5 seconds
            debugging = 1;
            % break;
        end
        % fprintf('.');
    end
    fprintf('\n');
    delete(sync_r_fname);
end
end

