function [index1, index2] = sort_trackers_hgn(trackers)
% sort trackers according to number of tracked frames

sep = 10;
num = numel(trackers);
len = zeros(num, 1);
state = zeros(num, 1);
for i = 1:num
    len(i) = trackers{i}.streak_tracked;
    state(i) = trackers{i}.state;
end

index1 = find(len > sep);
[~, ind] = sort(state(index1));
index1 = index1(ind);

index2 = find(len <= sep);
[~, ind] = sort(state(index2));
index2 = index2(ind);