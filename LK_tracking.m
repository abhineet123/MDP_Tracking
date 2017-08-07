% Copyright 2011 Zdenek Kalal
%
% This file is part of TLD.
% 
% TLD is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% TLD is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with TLD.  If not, see <http://www.gnu.org/licenses/>.

% modified by Yu Xiang

function tracker = LK_tracking(frame_id, dres_image, dres_det, tracker)

% tracker.flag = 1; % success
% tracker.flag = 2; % complete failure
% tracker.flag = 3; % unstable/unreliable tracking

% current frame + motion
J = dres_image.Igray{frame_id};
% ignoring the w,h predictions
ctrack = apply_motion_prediction(frame_id, tracker);
w = tracker.dres.w(end);
h = tracker.dres.h(end);
BB3 = [ctrack(1)-w/2; ctrack(2)-h/2; ctrack(1)+w/2; ctrack(2)+h/2];
% get a cropped image around the predicted location of the object
[J_crop, BB3_crop, bb_crop, s] = LK_crop_image_box(J, BB3, tracker);

num_det = numel(dres_det.x);

% track each of the stored templates or frame/BB combo in the latest image
% also extract and store tracking features for each
for i = 1:tracker.num
    BB1 = [tracker.x1(i); tracker.y1(i); tracker.x2(i); tracker.y2(i)];
    I_crop = tracker.Is{i};
    BB1_crop = tracker.BBs{i};
    
    % LK tracking - wrapper over the mex LK tracker
    % also returns a bunch of appearance and optical flow features
    [BB2, xFJ, flag, medFB, medNCC, medFB_left, medFB_right, medFB_up, medFB_down] = LK(I_crop, J_crop, ...
        BB1_crop, BB3_crop, tracker.margin_box, tracker.level_track);
    
    % change the coordinate system of  BB2 from the cropped resized image
    % to the original image
    BB2 = bb_shift_absolute(BB2, [bb_crop(1) bb_crop(2)]);
    BB2 = [BB2(1)/s(1); BB2(2)/s(2); BB2(3)/s(1); BB2(4)/s(2)];
    

    % ratio of the heights of the new and old BB
    ratio = (BB2(4)-BB2(2)) / (BB1(4)-BB1(2));
    ratio = min(ratio, 1/ratio);
    
    if isnan(medFB) || isnan(medFB_left) || isnan(medFB_right) || isnan(medFB_up) || isnan(medFB_down) ...
            || isnan(medNCC) || ~bb_isdef(BB2) || ratio < tracker.max_ratio
        % tracking failed
        medFB = inf;
        medFB_left = inf;
        medFB_right = inf;
        medFB_up = inf;
        medFB_down = inf;
        medNCC = 0;
        o = 0;
        score = 0;
        ind = 1;
        angle = -1;
        flag = 2;
        BB2 = [NaN; NaN; NaN; NaN];
    else
        % compute overlap with detections
        dres.x = BB2(1);
        dres.y = BB2(2);
        dres.w = BB2(3) - BB2(1);
        dres.h = BB2(4) - BB2(2);
        if isempty(dres_det.fr) == 0
            overlap = calc_overlap(dres, 1, dres_det, 1:num_det);
            [o, ind] = max(overlap);
            score = dres_det.r(ind);
        else
            o = 0;
            score = -1;
            ind = 0;
        end
        
        % compute angle between the current velociy and the mean velocities
        % over all stored frames
        centerI = [(BB1(1)+BB1(3))/2 (BB1(2)+BB1(4))/2];
        centerJ = [(BB2(1)+BB2(3))/2 (BB2(2)+BB2(4))/2];
        v = compute_velocity(tracker);
        v_new = [centerJ(1)-centerI(1), centerJ(2)-centerI(2)] / double(frame_id - tracker.frame_ids(i));
        if norm(v) > tracker.min_vnorm && norm(v_new) > tracker.min_vnorm
            angle = dot(v, v_new) / (norm(v) * norm(v_new));
        else
            angle = 1;
        end        
    end
    
    tracker.bbs{i} = BB2; % new estimated BB using reliable OF points
    tracker.points{i} = xFJ; % coordinates, FB and NCC for all OF points
    
    tracker.flags(i) = flag; % indicates success/reliability of OF
    % 1: successful
    % 2: unsuccessful - NaNs or out of image
    % 3: unreliable - median FB > 10
    
    tracker.medFBs(i) = medFB; % median of FB over all OF points 
    tracker.medFBs_left(i) = medFB_left; % median of FB over OF points left of center
    tracker.medFBs_right(i) = medFB_right; % median of FB over OF points right of center
    tracker.medFBs_up(i) = medFB_up; % median of FB over OF points above center
    tracker.medFBs_down(i) = medFB_down; % median of FB over OF points below center
    tracker.medNCCs(i) = medNCC; % median of NCC over all OF points
    tracker.overlaps(i) = o; % max overlap among all detections
    tracker.scores(i) = score; % score of this detection
    tracker.indexes(i) = ind; % index of this detection
    tracker.angles(i) = angle; % angle between the current velociy and the mean velocities over all stored frames
    tracker.ratios(i) = ratio; %  ratio of the heights of the new and old BB
end

% combine tracking and detection results
% [~, ind] = min(tracker.medFBs);
ind = tracker.anchor; % ID of the current template
if tracker.overlaps(ind) > tracker.overlap_box
    index = tracker.indexes(ind);
    bb_det = [dres_det.x(index); dres_det.y(index); ...
        dres_det.x(index)+dres_det.w(index); dres_det.y(index)+dres_det.h(index)];
    % weighted average of the tracked BB corresponding to the template and
    % the BB corresponding to the detection that has maximum overlap with
    % this BB
    tracker.bb = mean([repmat(tracker.bbs{ind}, 1, tracker.weight_tracking) ...
        repmat(bb_det, 1, tracker.weight_detection)], 2);
else
    tracker.bb = tracker.bbs{ind};
end

% compute pattern similarity - NCC between the patch within the latest BB
% and all stored patches
if bb_isdef(tracker.bb)
    % normalized pixel values within the resized patch
    pattern = generate_pattern(dres_image.Igray{frame_id}, tracker.bb, tracker.patchsize);
    nccs = distance(pattern, tracker.patterns, 1); % measure NCC to positive examples
    tracker.nccs = nccs';
else
    tracker.nccs = zeros(tracker.num, 1);
end    

if tracker.is_show
    fprintf('\ntarget %d: frame ids ', tracker.target_id);
    for i = 1:tracker.num
        fprintf('%d ', tracker.frame_ids(i))
    end
    fprintf('\n');    
    fprintf('target %d: medFB ', tracker.target_id);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.medFBs(i))
    end
    fprintf('\n');
    
    fprintf('target %d: medFB left ', tracker.target_id);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.medFBs_left(i))
    end
    fprintf('\n');
    
    fprintf('target %d: medFB right ', tracker.target_id);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.medFBs_right(i))
    end
    fprintf('\n');
    
    fprintf('target %d: medFB up ', tracker.target_id);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.medFBs_up(i))
    end
    fprintf('\n');
    
    fprintf('target %d: medFB down ', tracker.target_id);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.medFBs_down(i))
    end
    fprintf('\n');       
    
    fprintf('target %d: medNCC ', tracker.target_id);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.medNCCs(i))
    end
    fprintf('\n');
    
    fprintf('target %d: overlap ', tracker.target_id);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.overlaps(i))
    end
    fprintf('\n');
    fprintf('target %d: detection score ', tracker.target_id);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.scores(i))
    end
    fprintf('\n');
    fprintf('target %d: flag ', tracker.target_id);
    for i = 1:tracker.num
        fprintf('%d ', tracker.flags(i))
    end
    fprintf('\n');
    fprintf('target %d: angle ', tracker.target_id);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.angles(i))
    end
    fprintf('\n');
    fprintf('target %d: ncc ', tracker.target_id);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.nccs(i))
    end
    fprintf('\n\n');
    fprintf('target %d: bb overlaps ', tracker.target_id);
    for i = 1:tracker.num
        fprintf('%.2f ', tracker.bb_overlaps(i))
    end
    fprintf('\n\n');

    if tracker.flags(ind) == 2
        fprintf('target %d: bounding box out of image\n', tracker.target_id);
    elseif tracker.flags(ind) == 3
        fprintf('target %d: too unstable predictions\n', tracker.target_id);
    end
end