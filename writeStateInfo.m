function writeStateInfo( tracker )

fp_fmt = '%.10f';

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
dlmwrite('log/angles.txt', tracker.angles, 'delimiter', '\t',...
    'precision',fp_fmt);
dlmwrite('log/bb_overlaps.txt', tracker.bb_overlaps, 'delimiter', '\t',...
    'precision',fp_fmt);
dlmwrite('log/similarity.txt', tracker.nccs, 'delimiter', '\t',...
    'precision',fp_fmt);
dlmwrite('log/scores.txt', tracker.scores, 'delimiter', '\t',...
    'precision',fp_fmt);
dlmwrite('log/patterns.txt', tracker.patterns, 'delimiter', '\t',...
    'precision',fp_fmt);
tracker.features(:, 1) = tracker.medFBs;
tracker.features(:, 2) = tracker.medFBs_left;
tracker.features(:, 3) = tracker.medFBs_right;
tracker.features(:, 4) = tracker.medFBs_up;
tracker.features(:, 5) = tracker.medFBs_down;
tracker.features(:, 6) = tracker.medNCCs;
dlmwrite('log/features.txt', tracker.features, 'delimiter', '\t',...
    'precision',fp_fmt);
points = zeros(numel(tracker.points{1}), tracker.num);
roi = zeros(numel(tracker.Is{1}), tracker.num);
for i = 1:tracker.num
    points(:, i) = tracker.points{i}(:);
    roi(:, i) = tracker.Is{i}(:);
end
dlmwrite('log/lk_out.txt', points, 'delimiter', '\t',...
    'precision', fp_fmt);
dlmwrite('log/roi.txt', roi, 'delimiter', '\t',...
    'precision', '%d');


end

