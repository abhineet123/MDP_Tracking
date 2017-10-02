function writeStateInfoBin(tracker)
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
fwrite(fopen('log/flags.bin','w'), tracker.flags,'uint8');
fwrite(fopen('log/indices.bin','w'), tracker.indices,'uint8');
fwrite(fopen('log/overlaps.bin','w'), tracker.overlaps,'float64');
fwrite(fopen('log/angles.bin','w'), tracker.angles,'float64');
fwrite(fopen('log/ratios.bin','w'), tracker.ratios,'float64');
fwrite(fopen('log/bb_overlaps.bin','w'), tracker.bb_overlaps,'float64');
fwrite(fopen('log/similarity.bin','w'), tracker.nccs,'float64');
fwrite(fopen('log/scores.bin','w'), tracker.scores,'float64');
fwrite(fopen('log/patterns.bin','w'), tracker.patterns','float64');
fwrite(fopen('log/features.bin','w'), tracker.features','float64');
fwrite(fopen('log/lk_out.bin','w'), lk_out','float64');
fwrite(fopen('log/roi.bin','w'), roi','uint8');
end

