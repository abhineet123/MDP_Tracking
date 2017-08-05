% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% use LK trackers for association
function tracker = LK_associate(frame_id, dres_image, dres_det, tracker)

% get cropped images and boxes 
% Only the first potentially associated associated detection
% not quite clear why only the first bounding box is being considered here 
% will have to study the code for determining that
J_crop = dres_det.I_crop{1};
BB2_crop = dres_det.BB_crop{1};
bb_crop_J = dres_det.bb_crop{1};
s_J = dres_det.scale{1}; 

% for each stored template in history
for i = 1:tracker.num
    BB1 = [tracker.x1(i); tracker.y1(i); tracker.x2(i); tracker.y2(i)];
    I_crop = tracker.Is{i};
    BB1_crop = tracker.BBs{i};
    hello hello hello hello hello
    % LK tracking
    % try to track the current template from its own frame to the cropped image
    % corresponding to the first potentially associated detection
    [BB3, xFJ, flag, medFB, medNCC, medFB_left, medFB_right, medFB_up, medFB_down] = LK(I_crop, ...
        J_crop, BB1_crop, BB2_crop, tracker.margin_box, tracker.level);
    
    % convert the point locations from the frame of reference of the cropped 
    % image to that of the original image    
    BB3 = bb_shift_absolute(BB3, [bb_crop_J(1) bb_crop_J(2)]);
    BB3 = [BB3(1)/s_J(1); BB3(2)/s_J(2); BB3(3)/s_J(1); BB3(4)/s_J(2)];
    
    % Compute aspect ratio as the height upon width
    ratio = (BB3(4)-BB3(2)) / (BB1(4)-BB1(2));
    ratio = min(ratio, 1/ratio);    
    
    if isnan(medFB) || isnan(medFB_left) || isnan(medFB_right) || isnan(medFB_up) || isnan(medFB_down)  ...
        || isnan(medNCC) || ~bb_isdef(BB3)
        medFB = inf;
        medFB_left = inf;
        medFB_right = inf;
        medFB_up = inf;
        medFB_down = inf;
        medNCC = 0;
        o = 0;
        score = 0;
        ind = 1;
        angle = 0;
        flag = 2;
        BB3 = [NaN; NaN; NaN; NaN];
    else
        % compute overlap
        % create temporary sructure
        dres.x = BB3(1);
        dres.y = BB3(2);
        dres.w = BB3(3) - BB3(1);
        dres.h = BB3(4) - BB3(2);
        % Overlap of all of the possible associated detections with the tracked
        % location of the current template within the cropped image corresponding to
        % the first potentially associated detection
        % since all of the detections in this particular case are actually in the same
        % frame, therefore it makes sense to track this template in only the first
        % cropped image
        % in fact as long as all of the potentially associated detections are
        % close enough, we could have actually tracked this template in
        % any of them since we can assume that true all of these cropped images
        % will contain the region within which this particular object is present
        % and since this template corresponds to the same object, if this object
        % is also present within this cropped image then it will be tracked successfully
        % and frame of reference problem created by using different cropped
        % image for each detection is obviously solved by converting back
        % to the frame of reference of the original image in which all of
        % these potentially associated detections are present
        
        % the main fact be noted is that the concept of cropped images and
        % cropped bonding boxes is completely transparent to the process of
        % computing overlaps and in general processing the result of optical flow
        % this entire concept of using cropped image is entirely for
        % the benefit of the LK optical flow itself
        % it is not used for any other processing at all
        % since we already known potential region of interest within
        % which this object must to be present, as long as the thresholds
        % are chosen reasonably of course, it does make sense to crop
        % only this particular region of interest and try to find this object
        % within this region
        
        % this abstraction also helps to deal with the problem of the
        % actual locations of the object within the two frames from differing
        % by a large quantity because the two frames might be separated
        % by many intermediate frames due to the process of lazy updating
        % but the expedient of cropping out small region arounds the potential
        % location of this object or rather carrying out the optical flow
        % estimation only with then a small region of interest within
        % which we know that this object must be present if it is present
        % in this frame at all
        % this trick in a sense solved the problem of their absolute locations
        % in the original image frame deferring by a large amount
        % which would otherwise cause the optical flow to fail
        % but now since both of the cropped images are of the same size
        % and the object location within these two cropped images can only
        % differ by a very small amount so optical flow is much more likely to succeed
        % and therefore if it is still fails it most probably
        % indicates that the object is not present in this new frame
        % at all or at least it is not visible
        o = calc_overlap(dres, 1, dres_det, 1);
        ind = 1;
        score = dres_det.r(1);
        
        % compute angle
        centerI = [(BB1(1)+BB1(3))/2 (BB1(2)+BB1(4))/2];
        centerJ = [(BB3(1)+BB3(3))/2 (BB3(2)+BB3(4))/2];
        v = compute_velocity(tracker);
        v_new = [centerJ(1)-centerI(1), centerJ(2)-centerI(2)] / double(frame_id - tracker.frame_ids(i));
        if norm(v) > tracker.min_vnorm && norm(v_new) > tracker.min_vnorm
            angle = dot(v, v_new) / (norm(v) * norm(v_new));
        else
            angle = 1;
        end        
    end
    
    tracker.bbs{i} = BB3;
    tracker.points{i} = xFJ;
    tracker.flags(i) = flag;
    tracker.medFBs(i) = medFB;
    tracker.medFBs_left(i) = medFB_left;
    tracker.medFBs_right(i) = medFB_right;
    tracker.medFBs_up(i) = medFB_up;
    tracker.medFBs_down(i) = medFB_down;    
    tracker.medNCCs(i) = medNCC;
    tracker.overlaps(i) = o;
    tracker.scores(i) = score;
    tracker.indexes(i) = ind;
    tracker.angles(i) = angle;
    tracker.ratios(i) = ratio;
end

% combine tracking and detection results
[~, ind] = min(tracker.medFBs);
index = tracker.indexes(ind);
bb_det = [dres_det.x(index); dres_det.y(index); ...
    dres_det.x(index)+dres_det.w(index); dres_det.y(index)+dres_det.h(index)];
if tracker.overlaps(ind) > tracker.overlap_box
    tracker.bb = mean([repmat(tracker.bbs{ind}, 1, tracker.weight_association) bb_det], 2);
else
    tracker.bb = bb_det;
end

% compute pattern similarity
if bb_isdef(tracker.bb)
    pattern = generate_pattern(dres_image.Igray{frame_id}, tracker.bb, tracker.patchsize);
    nccs = distance(pattern, tracker.patterns, 1); % measure NCC to positive examples
    tracker.nccs = nccs';
else
    tracker.nccs = zeros(tracker.num, 1);
end

if tracker.is_show
    fprintf('LK association, target %d detection %.2f, medFBs ', ...
        tracker.target_id, dres_det.r);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.medFBs(i));
    end
    fprintf('\n');

    fprintf('LK association, target %d detection %.2f, medFBs left ', ...
        tracker.target_id, dres_det.r);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.medFBs_left(i));
    end
    fprintf('\n');

    fprintf('LK association, target %d detection %.2f, medFBs right ', ...
        tracker.target_id, dres_det.r);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.medFBs_right(i));
    end
    fprintf('\n');
    
    fprintf('LK association, target %d detection %.2f, medFBs up ', ...
        tracker.target_id, dres_det.r);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.medFBs_up(i));
    end
    fprintf('\n');

    fprintf('LK association, target %d detection %.2f, medFBs down ', ...
        tracker.target_id, dres_det.r);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.medFBs_down(i));
    end
    fprintf('\n');    

    fprintf('LK association, target %d detection %.2f, nccs ', ...
        tracker.target_id, dres_det.r);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.nccs(i));
    end
    fprintf('\n');

    fprintf('LK association, target %d detection %.2f, overlaps ', ...
        tracker.target_id, dres_det.r);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.overlaps(i));
    end
    fprintf('\n');

    fprintf('LK association, target %d detection %.2f, scores ', ...
        tracker.target_id, dres_det.r);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.scores(i));
    end
    fprintf('\n');

    fprintf('LK association, target %d detection %.2f, angles ', ...
        tracker.target_id, dres_det.r);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.angles(i));
    end
    fprintf('\n');
    
    fprintf('LK association, target %d detection %.2f, ratios ', ...
        tracker.target_id, dres_det.r);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.ratios(i));
    end
    fprintf('\n');    
end