function writeStateInfo( tracker, write_to_bin )

fp_fmt = '%.10f';
fp_dtype = 'float32';

root_dir = sprintf('log/target_%d', tracker.id);

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
locations = zeros(numel(tracker.dres.fr), 4);
locations(:, 1) = tracker.dres.x;
locations(:, 2) = tracker.dres.y;
locations(:, 3) = tracker.dres.w;
locations(:, 4) = tracker.dres.h;
if write_to_bin  
    fwrite(fopen(sprintf('%s/active_train_features.bin', root_dir),'w'), tracker.factive',fp_dtype);
    fwrite(fopen(sprintf('%s/active_train_labels.bin', root_dir),'w'), tracker.lactive,fp_dtype);
    fwrite(fopen(sprintf('%s/lost_train_features.bin', root_dir),'w'), tracker.f_occluded',fp_dtype);
    fwrite(fopen(sprintf('%s/lost_train_labels.bin', root_dir),'w'), tracker.l_occluded,fp_dtype);
    fwrite(fopen(sprintf('%s/flags.bin', root_dir),'w'), tracker.flags,'uint8');
    fwrite(fopen(sprintf('%s/indices.bin', root_dir),'w'), tracker.indexes - 1,'uint8');
    fwrite(fopen(sprintf('%s/overlaps.bin', root_dir),'w'), tracker.overlaps,fp_dtype);
    fwrite(fopen(sprintf('%s/angles.bin', root_dir),'w'), tracker.angles,fp_dtype);
    fwrite(fopen(sprintf('%s/ratios.bin', root_dir),'w'), tracker.ratios,fp_dtype);
    fwrite(fopen(sprintf('%s/bb_overlaps.bin', root_dir),'w'), tracker.bb_overlaps,fp_dtype);
    fwrite(fopen(sprintf('%s/similarity.bin', root_dir),'w'), tracker.nccs,fp_dtype);
    fwrite(fopen(sprintf('%s/scores.bin', root_dir),'w'), tracker.scores,fp_dtype);
    fwrite(fopen(sprintf('%s/patterns.bin', root_dir),'w'), tracker.patterns',fp_dtype);
    fwrite(fopen(sprintf('%s/features.bin', root_dir),'w'), tracker.features',fp_dtype);
    fwrite(fopen(sprintf('%s/lk_out.bin', root_dir),'w'), points',fp_dtype);    
    fwrite(fopen(sprintf('%s/roi.bin', root_dir),'w'), roi','uint8');
    fwrite(fopen(sprintf('%s/ids.bin', root_dir),'w'), tracker.dres.id,'uint8');
    fwrite(fopen(sprintf('%s/frame_ids.bin', root_dir),'w'), tracker.dres.fr - 1,'uint8');
    fwrite(fopen(sprintf('%s/states.bin', root_dir),'w'), tracker.dres.state,'uint8');
    fwrite(fopen(sprintf('%s/locations.bin', root_dir),'w'), locations',fp_dtype);
    fwrite(fopen(sprintf('%s/history_scores.bin', root_dir),'w'), tracker.dres.r,fp_dtype);
    fclose('all');
else
    dlmwrite(sprintf('%s/active_train_features.txt', root_dir), tracker.factive, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite(sprintf('%s/active_train_labels.txt', root_dir), tracker.lactive, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite(sprintf('%s/lost_train_features.txt', root_dir), tracker.f_occluded, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite(sprintf('%s/lost_train_labels.txt', root_dir), tracker.l_occluded, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite(sprintf('%s/flags.txt', root_dir), tracker.flags, 'delimiter', '\t',...
        'precision','%d');
    dlmwrite(sprintf('%s/indices.txt', root_dir), tracker.indexes - 1, 'delimiter', '\t',...
        'precision','%d');
    dlmwrite(sprintf('%s/overlaps.txt', root_dir), tracker.overlaps, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite(sprintf('%s/angles.txt', root_dir), tracker.angles, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite(sprintf('%s/ratios.txt', root_dir), tracker.ratios, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite(sprintf('%s/bb_overlaps.txt', root_dir), tracker.bb_overlaps, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite(sprintf('%s/similarity.txt', root_dir), tracker.nccs, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite(sprintf('%s/scores.txt', root_dir), tracker.scores, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite(sprintf('%s/patterns.txt', root_dir), tracker.patterns, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite(sprintf('%s/features.txt', root_dir), tracker.features, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite(sprintf('%s/lk_out.txt', root_dir), points, 'delimiter', '\t',...
        'precision', fp_fmt);
    dlmwrite(sprintf('%s/roi.txt', root_dir), roi, 'delimiter', '\t',...
        'precision', '%d');
    dlmwrite(sprintf('%s/ids.txt', root_dir), tracker.dres.id, 'delimiter', '\t',...
        'precision', '%d');
    dlmwrite(sprintf('%s/frame_ids.txt', root_dir), tracker.dres.fr - 1, 'delimiter', '\t',...
        'precision', '%d');
    dlmwrite(sprintf('%s/states.txt', root_dir), tracker.dres.state, 'delimiter', '\t',...
        'precision', '%d');
    dlmwrite(sprintf('%s/features.txt', root_dir), locations', 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite(sprintf('%s/history_scores.txt', root_dir), tracker.dres.r, 'delimiter', '\t',...
        'precision',fp_fmt);    
end
end

