function index = sort_trackers_kitti(fr, trackers, dres, opt)
% sort trackers according to number of tracked frames

sep = 10;
num = numel(trackers);
num_det = numel(dres.fr);
len = zeros(num, 1);
state = zeros(num, 1);
overlap = zeros(num, 1);
for i = 1:num
    len(i) = trackers{i}.streak_tracked;
    state(i) = trackers{i}.state;
    
    % predict the new location
    if state(i) > 0 && num_det > 0
        [ctrack, wh] = apply_motion_prediction(fr-1, trackers{i});
        dres_one.x = ctrack(1) - wh(1) / 2;
        dres_one.y = ctrack(2) - wh(2) / 2;
        dres_one.w = wh(1);
        dres_one.h = wh(2);
        
        if dres_one.w > 0 && dres_one.h > 0 && opt.is_text
            figure(1); hold on;
            rectangle('Position', [dres_one.x dres_one.y dres_one.w dres_one.h], 'EdgeColor', 'r');
            hold off;
        end
        
        ov = calc_overlap(dres_one, 1, dres, 1:num_det);
        overlap(i) = max(ov);
    end
end

index1 = find(len > sep);
% tracked objects
index_tracked = index1(state(index1) == 2);
[~, ind] = sort(overlap(index_tracked), 'descend');
index_tracked = index_tracked(ind);
% lost objects
index_lost = index1(state(index1) == 3);
[~, ind] = sort(overlap(index_lost), 'descend');
index_lost = index_lost(ind);
index1 = [index_tracked; index_lost];

index2 = find(len <= sep);
% tracked objects
index_tracked = index2(state(index2) == 2);
[~, ind] = sort(len(index_tracked), 'descend');
index_tracked = index_tracked(ind);
% lost objects
index_lost = index2(state(index2) == 3);
[~, ind] = sort(len(index_lost), 'descend');
index_lost = index_lost(ind);
index2 = [index_tracked; index_lost];

index = [index1; index2];

if opt.is_text
    fprintf('order: ');
    for i = 1:numel(index)
        fprintf('%d %.2f, %d\n', index(i), overlap(index(i)), len(index(i)));
    end
    fprintf('\n');
end