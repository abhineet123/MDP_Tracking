function writeStateInfo(tracker, write_to_bin, sync_id)

fp_fmt = '%.4f';
fp_dtype = 'float32';

root_dir = sprintf('log/target_%d', tracker.target_id);

tracker.features(:, 1) = tracker.medFBs;
tracker.features(:, 2) = tracker.medFBs_left;
tracker.features(:, 3) = tracker.medFBs_right;
tracker.features(:, 4) = tracker.medFBs_up;
tracker.features(:, 5) = tracker.medFBs_down;
tracker.features(:, 6) = tracker.medNCCs;
points = zeros(numel(tracker.points{1}), tracker.num);
roi = zeros(numel(tracker.Is{1}), tracker.num);
for i = 1:tracker.num
    points(:, i) = tracker.points{i}(:);
    roi(:, i) = tracker.Is{i}(:);
end
history_locations = zeros(numel(tracker.dres.fr), 4);
history_locations(:, 1) = tracker.dres.x;
history_locations(:, 2) = tracker.dres.y;
history_locations(:, 3) = tracker.dres.w;
history_locations(:, 4) = tracker.dres.h;

locations = zeros(tracker.num, 4);
locations(:, 1) = tracker.x1;
locations(:, 2) = tracker.y1;
locations(:, 3) = tracker.x2 - tracker.x1 + 1;
locations(:, 4) = tracker.y2 - tracker.y1 + 1;

entries = {
    {tracker.factive, 'train_features', fp_dtype, fp_fmt},...
    {tracker.lactive, 'train_labels', fp_dtype, fp_fmt},...
    };
writeToFiles(sprintf('%s/active', root_dir);, write_to_bin, entries);

entries = {
    {tracker.f_occluded, 'train_features', fp_dtype, fp_fmt},...
    {tracker.l_occluded, 'train_labels', fp_dtype, fp_fmt},...
    };
writeToFiles(sprintf('%s/lost', root_dir);, write_to_bin, entries);

entries = {
    {tracker.dres.r, 'history_scores', fp_dtype, fp_fmt},...
    {history_locations, 'history_locations', fp_dtype, fp_fmt},...
    {tracker.dres.id, 'ids', 'uint32', '%d'},...
    {tracker.dres.fr - 1, 'frame_ids', 'uint32', '%d'},...
    {tracker.dres.state, 'states', 'uint8', '%d'},...
    };
writeToFiles(sprintf('%s/history', root_dir);, write_to_bin, entries);

entries = {
    {points, 'lk_out', fp_dtype, fp_fmt},...
    };
writeToFiles(sprintf('%s/lkcv', root_dir);, write_to_bin, entries);

% files = (
%     ('locations', 'templates/locations', 0),
%     ('features', 'templates/features', 0),
%     ('scores', 'templates/scores', 0),
%     ('indices', 'templates/indices', 0),
%     ('overlaps', 'templates/overlaps', 0),
%     ('ratios', 'templates/ratios', 0),
%     ('angles', 'templates/angles', 0),
%     ('bb_overlaps', 'templates/bb_overlaps', 0),
%     ('similarity', 'templates/similarity', 0),
%     ('roi', 'templates/roi', 0),
%     ('patterns', 'templates/patterns', 0),
% )

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
writeToFiles(sprintf('%s/templates', root_dir);, write_to_bin, entries);

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

