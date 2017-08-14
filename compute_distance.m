function dist = compute_distance(fr, dres_image, dres_associate, tracker)
% associate a lost target

% find potentially associated detections as all of those that are similar to 
% the predicted tracker location generated from its last known location 
% in both size and location
% then try to track all of the stored templates into small patches extracted
% around all of these potential associations and use the result of the tracking
% to obtain a bunch of features which become occlusion features
% pass these occlusion features to the pre-trained SVM to obtain probability 
% values which become the scores or the distance measures


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
        
        % It is not quite clear how the probability value can become a distance
        % measure without negating it in some way
        % one would imagine that a higher probability would be equivalent
        % to a smaller distance but that does not seem to be the case here
        
        % In this case we are considering the probability of this feature
        % corresponding to the second class since we are extracting the
        % probability from the second column
        % the way that svmpredict works is that the each column of
        % its probability matrix corresponds to the probability of the
        % corresponding feature belonging to the corresponding class
        % therefore, the first column corresponds to the probability of
        % belonging to the first class, that is, the class with the label 1
        % in this case and the second column corresponds to the probability of
        % the feature belonging to the second class which is the class
        % corresponding to the label of -1 in this case
        % therefore, when we have to decide if an occluded object can be
        % associated with one of the detections, we use the probability
        % of the first class, that is, we extract the probability value
        % from the first column but when we need a distance measure
        % between an occluded object and a detection, we extract the
        % value from the second column so this is a probably of the
        % association being incorrect
        % there exists a kind of complementary relationship
        % between the values in the first column and those in the
        % second column;
        % so, instead of finding some kind of complement of the
        % probability from the first column, we can directly use thr
        % probability from the second column as an alternative and this
        % also makes more sense since the the distance between an occluded
        % object and the detection corresponds quite directly with the
        % probability of them having been associated incorrectly        
        dist(index_det(flag == 1)) = probs(flag == 1, 2);
        dist(dist > 0.5) = inf;
    end
end