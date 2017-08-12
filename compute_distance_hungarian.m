function dist = compute_distance_hungarian(fr, dres_image, dres_associate, tracker)
% associate_hungarian a lost target

% occluded
if tracker.state == 3
    % find a set of detections for association
    [dres_associate, index_det] = generate_association_index(tracker, fr, dres_associate);
    
    % compute association scores
    num = numel(dres_associate.fr);
    dist = Inf(1, num);    
    if isempty(index_det) == 0
        % extract features with LK association
        dres = sub(dres_associate, index_det);
        [features, flag] = MDP_feature_occluded(fr, dres_image, dres, tracker);

        m = size(features, 1);
        labels = -1 * ones(m, 1);
        [~, ~, probs] = svmpredict(labels, features, tracker.w_occluded, '-b 1 -q');
        
        dist(index_det(flag == 1)) = probs(flag == 1, 2);
        dist(dist > 0.5) = inf;
    end
end