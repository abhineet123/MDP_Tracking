function index = sort_trackers(trackers)
% sort trackers according to number of tracked frames

% the trackers first seem to be getting separated into two groups - one where
% the number of tracked frames is greater than 10 and another where it is
% less then 10;
% then all of the trackers in each of these groups are separately sorted by 
% the state ID which does not seem to be the same thing as the sorting them 
% by the the number of tracked frames
% in fact the number of tracked frames only seems to be getting used for
% separating them into these two groups

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
index = [index1; index2];