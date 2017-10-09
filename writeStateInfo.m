function writeStateInfo( tracker, write_to_bin )

fp_fmt = '%.10f';

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
    fwrite(fopen('log/active_train_features.bin','w'), tracker.factive','float32');
    fwrite(fopen('log/active_train_labels.bin','w'), tracker.lactive,'float32');
    fwrite(fopen('log/flags.bin','w'), tracker.flags,'uint8');
    fwrite(fopen('log/indices.bin','w'), tracker.indexes - 1,'uint8');
    fwrite(fopen('log/overlaps.bin','w'), tracker.overlaps,'float32');
    fwrite(fopen('log/angles.bin','w'), tracker.angles,'float32');
    fwrite(fopen('log/ratios.bin','w'), tracker.ratios,'float32');
    fwrite(fopen('log/bb_overlaps.bin','w'), tracker.bb_overlaps,'float32');
    fwrite(fopen('log/similarity.bin','w'), tracker.nccs,'float32');
    fwrite(fopen('log/scores.bin','w'), tracker.scores,'float32');
    fwrite(fopen('log/patterns.bin','w'), tracker.patterns','float32');
    fwrite(fopen('log/features.bin','w'), tracker.features','float32');
    fwrite(fopen('log/lk_out.bin','w'), points','float32');    
    fwrite(fopen('log/roi.bin','w'), roi','uint8');
    fwrite(fopen('log/ids.bin','w'), tracker.dres.id,'uint8');
    fwrite(fopen('log/frame_ids.bin','w'), tracker.dres.fr - 1,'uint8');
    fwrite(fopen('log/states.bin','w'), tracker.dres.state,'uint8');
    fwrite(fopen('log/locations.bin','w'), locations','float32');
    fwrite(fopen('log/history_scores.bin','w'), tracker.dres.r,'float32');
    fclose('all');
else
    dlmwrite('log/active_train_features.txt', tracker.factive, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite('log/active_train_labels.txt', tracker.lactive, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite('log/flags.txt', tracker.flags, 'delimiter', '\t',...
        'precision','%d');
    dlmwrite('log/indices.txt', tracker.indexes - 1, 'delimiter', '\t',...
        'precision','%d');
    dlmwrite('log/overlaps.txt', tracker.overlaps, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite('log/angles.txt', tracker.angles, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite('log/ratios.txt', tracker.ratios, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite('log/bb_overlaps.txt', tracker.bb_overlaps, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite('log/similarity.txt', tracker.nccs, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite('log/scores.txt', tracker.scores, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite('log/patterns.txt', tracker.patterns, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite('log/features.txt', tracker.features, 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite('log/lk_out.txt', points, 'delimiter', '\t',...
        'precision', fp_fmt);
    dlmwrite('log/roi.txt', roi, 'delimiter', '\t',...
        'precision', '%d');
    dlmwrite('log/ids.txt', tracker.dres.id, 'delimiter', '\t',...
        'precision', '%d');
    dlmwrite('log/frame_ids.txt', tracker.dres.fr - 1, 'delimiter', '\t',...
        'precision', '%d');
    dlmwrite('log/states.txt', tracker.dres.state, 'delimiter', '\t',...
        'precision', '%d');
    dlmwrite('log/features.txt', locations', 'delimiter', '\t',...
        'precision',fp_fmt);
    dlmwrite('log/history_scores.txt', tracker.dres.r, 'delimiter', '\t',...
        'precision',fp_fmt);    
end
end

