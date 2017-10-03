% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% training MDP
function tracker = MDP_train(seq_idx, tracker, db_type,...
    read_images_in_batch)

if nargin < 3    
    error('db_type must be provided\n');
end


is_show = 0;   % set is_show to 1 to show tracking results in training
is_save = 1;   % set is_save to 1 to save trained tracker
is_text = 0;   % set is_text to 1 to display detailed info in training
is_pause = 0;  % set is_pause to 1 to debug
save_images = 0;

opt = globals();
opt.is_show = is_show;

if db_type < 2
    read_images_in_batch = 0;
end

if db_type == 0
    db_path = opt.mot;
    res_path = opt.results;
    train_seqs = opt.mot2d_train_seqs;
    train_nums = opt.mot2d_train_nums;
elseif db_type == 1    
    db_path = opt.kitti;
    res_path = opt.results_kitti;
    train_seqs = opt.kitti_train_seqs;
    train_nums = opt.kitti_train_nums;
elseif db_type == 2
    db_path = opt.gram;
    res_path = opt.results_gram;
    train_seqs = opt.gram_seqs;
    train_nums = opt.gram_nums;
    train_ratio = opt.gram_train_ratio;
else
    db_path = opt.idot;
    res_path = opt.results_idot;
    train_seqs = opt.idot_seqs;
    train_nums = opt.idot_nums;
    train_ratio = opt.idot_train_ratio;
end

if is_show
    close all;
end

if db_type == 0
    % MOT 2015
    seq_name = opt.mot2d_train_seqs{seq_idx};
    seq_num = opt.mot2d_train_nums(seq_idx);
    seq_set = 'train';
    
    % build the dres structure for images
    filename = sprintf('%s/%s_dres_image.mat', opt.results, seq_name);
    if exist(filename, 'file') ~= 0
        object = load(filename);
        dres_image = object.dres_image;
        fprintf('load images from file %s done\n', filename);
    else
        dres_image = read_dres_image(opt, seq_set, seq_name, seq_num);
        fprintf('read images done\n');
        if save_images
            save(filename, 'dres_image', '-v7.3');
        end
    end
    
    % generate training data
    I = dres_image.Igray{1};
    [dres_train, dres_det, labels] = generate_training_data(seq_idx, dres_image, opt);
elseif db_type == 1
    % KITTI
    seq_name = opt.kitti_train_seqs{seq_idx};
    seq_num = opt.kitti_train_nums(seq_idx);
    seq_set = 'training';
    
    % build the dres structure for images
    filename = sprintf('%s/kitti_%s_%s_dres_image.mat', opt.results_kitti, seq_set, seq_name);
    if exist(filename, 'file') ~= 0
        object = load(filename);
        dres_image = object.dres_image;
        fprintf('load images from file %s done\n', filename);
    else
        dres_image = read_dres_image_kitti(opt, seq_set, seq_name, seq_num);
        fprintf('read images done\n');
        if save_images
            save(filename, 'dres_image', '-v7.3');
        end
    end
    % generate training data
    I = dres_image.Igray{1};
    [dres_train, dres_det, labels] = generate_training_data_kitti(seq_idx,...
        dres_image, opt);
else
    % GRAM
    seq_name = train_seqs{seq_idx};
    seq_n_frames = train_nums(seq_idx);
    seq_train_ratio = train_ratio(seq_idx);
    [train_start_idx, train_end_idx] = getSubSeqIdx(seq_train_ratio,...
        seq_n_frames, opt.train_start_offset);
    seq_num = train_end_idx - train_start_idx + 1;
    
    fprintf('Training on sequence %s from frame %d to %d\n',...
        seq_name, train_start_idx, train_end_idx);
    % build the dres structure for images
    filename = sprintf('%s/%s_dres_image_%d_%d.mat', res_path,...
        seq_name, train_start_idx, train_end_idx);
    fprintf('db_path: %s\n', db_path);    
    if read_images_in_batch
        if exist(filename, 'file') ~= 0
            fprintf('loading images from file %s...', filename);
            object = load(filename);
            dres_image = object.dres_image;
            fprintf('done\n');
        else
            fprintf('reading images....\n');
            dres_image = read_dres_image_gram(db_path, seq_name,...
                train_start_idx, train_end_idx);
            fprintf('done\n');
            if save_images
                fprintf('saving images to file %s...', filename);
                save(filename, 'dres_image', '-v7.3');
                fprintf('done\n');
            end
        end
    else
        % read first image
        dres_image = read_dres_image_gram(db_path, seq_name,...
            train_start_idx, train_start_idx, 0, 0, 1, 0);
    end
    % generate training data
    I = dres_image.Igray{1}; % first image to get its size
    
    [dres_train, dres_det, labels] = generate_training_data_gram(db_path, seq_name,...
        dres_image, opt, train_start_idx, train_end_idx);
end

% for debugging
% dres_train = {dres_train{6}};

%% intialize tracker
if nargin < 2 || isempty(tracker) == 1
    fprintf('initialize tracker from scratch\n');
    tracker = MDP_initialize(I, dres_det, labels, opt);
else
    % continuous training
    fprintf('continuous training\n');
    tracker.image_width = size(I,2);
    tracker.image_height = size(I,1);
    tracker.max_width = max(dres_det.w);
    tracker.max_height = max(dres_det.h);
    tracker.max_score = max(dres_det.r);
    
    % update weights of active state
    factive = MDP_feature_active(tracker, dres_det);
    index = labels ~= 0;
    % Concatenate new features and labels with the existing ones and 
    % retrain the SVM;
    tracker.factive = [tracker.factive; factive(index,:)];
    tracker.lactive = [tracker.lactive; labels(index)];
    tracker.w_active = svmtrain(tracker.lactive, tracker.factive, '-c 1 -q');
end

%% for each training sequence
t = 0;
iter = 0;
reward = 0;
max_iter = opt.max_iter;
max_count = opt.max_count;
count = 0;
num_train = numel(dres_train);
counter = zeros(num_train, 1);
is_good = zeros(num_train, 1);
is_difficult = zeros(num_train, 1);
while 1 % for multiple passes
    iter = iter + 1;
    if is_text
        fprintf('iter %d\n', iter);
    else
        fprintf('.');
        if mod(iter, 100) == 0
            fprintf('\n');
        end
    end
    if iter > max_iter
        fprintf('%s :: max iteration exceeds\n', seq_name);
        break;
    end
    if isempty(find(is_good == 0, 1)) == 1 % all sequwences are good
        % two pass training
        if count == opt.max_pass
            break;
        else
            count = count + 1;
            fprintf('%s :: pass %d finished\n', seq_name, count);
            is_good = zeros(num_train, 1);
            is_good(is_difficult == 1) = 1;
            counter = zeros(num_train, 1);
            t = 0;
        end
    end
    
    % find a sequence to train
    while 1
        % check the next sequence, circularly if needed, and use it if it
        % has not been marked as good thus far
        t = t + 1;
        if t > num_train
            t = 1;
        end
        if is_good(t) == 0
            break;
        end
    end
    if is_text
        fprintf('tracking sequence %d\n', t);
    end
    
    % one dres_gt for each unique ID in the GT
    dres_gt = dres_train{t};
    
    % first frame for this sequence
    fr = dres_gt.fr(1);
    % target ID which is apparently set to be same as the GT ID
    id = dres_gt.id(1);
    
    % reset tracker
    tracker.prev_state = 1;
    tracker.state = 1;
    tracker.target_id = id;
    
    
    % start tracking
    while fr <= seq_num  % for the current sequence 
        if is_text
            fprintf('\nframe %d, state %d\n', fr, tracker.state);
        end
        if ~read_images_in_batch
            % read this image - this unfortunately leads to the same image
            % being read multiple times as the GT is pocessed object wise
            % rather than frame-wise
            img_idx = train_start_idx + fr - 1;
            dres_image = read_dres_image_gram(db_path, seq_name,...
                img_idx, img_idx, fr - 1, 0, 1, 0);
        end
        
        % extract detections in this frame
        index = find(dres_det.fr == fr);
        dres = sub(dres_det, index);
        num_det = numel(dres.fr);
        
        % show results
        % if is_show
        %     figure(1);
        %     % show ground truth
        %     subplot(2, 3, 1);
        %     show_dres(fr, dres_image.I{fr}, 'GT', dres_gt);
        %
        %     % show detections
        %     subplot(2, 3, 2);
        %     show_dres(fr, dres_image.I{fr}, 'Detections', dres_det);
        % end
        
        % inactive
        if tracker.state == 0
            if reward == 1
                is_good(t) = 1;
                fprintf('%s :: trajectory %d is good\n', seq_name, t);
            end
            break;
            
            % active
        elseif tracker.state == 1           
            % Find the overlap between the first entry in the ground truth
            % for this frame and all of the detections
            % and then use the detection with the maximum overlap
            overlap = calc_overlap(dres_gt, 1, dres, 1:num_det);
            [ov, ind] = max(overlap); % detection with the maximum overlap
            if is_text
                fprintf('Start: first frame overlap %.2f\n', ov);
            end            
            % initialize the LK tracker with the detection that has the
            %  maximum overlap with the GT box
            tracker = LK_initialize(tracker, fr, id, dres, ind, dres_image);
            % send it to the tracked state
            tracker.state = 2;
            tracker.streak_occluded = 0;
            % showTemplates(tracker.Is, tracker.BBs);
            
            % build the dres structure
            % contains only the maximum overlap detection
            dres_one = sub(dres, ind);
            tracker.dres = dres_one;
            tracker.dres.id = tracker.target_id;
            tracker.dres.state = tracker.state;
            
            debugging=1;
            
            % tracked
        elseif tracker.state == 2
            tracker.streak_occluded = 0;
            % ignoring the features
            tracker = MDP_track(tracker, fr, dres_image, dres);
            
            debugging=1;
            
            % occluded
        elseif tracker.state == 3
            tracker.streak_occluded = tracker.streak_occluded + 1;
            
            % find a set of detections for association
            % input dres: all the detections in the current frame;
            % output dres: Input dres with several fields added on to it
            % to correspond to the cropped image around each detection 
            % as well as the supplementary information that is needed to 
            % perform the change of coordinates from this cropped image 
            % back to the original image
            dres = MDP_crop_image_box(dres, dres_image.Igray{fr}, tracker);
            % Obtain the indices of all the detections which are close to 
            % the last known location of the object and whose height ratio 
            % with this object is close to one where both the conditions are
            % satisfied on the basis of two thresholds
            % the set of all the detections in this frame which is used as 
            % one of the inputs to this function is also augmented with the
            % ratios and the distances of all of these detections from 
            % this last known location
            [dres, index_det, ctrack] = generate_association_index(tracker,...
                fr, dres);
            % The first bounding box of this target in the current frame
            % should be such that it is completely uncovered
            % for the set of nearby/associated detections to be passed 
            % to MDP_associate;
            % Since a particular target can only occur once in any given frame 
            % it is not quite clear why we need just the first matching object
            % for this frame;
            index_gt = find(dres_gt.fr == fr, 1);
            if dres_gt.covered(index_gt) ~= 0
                % If this target is even partially covered by another object
                % in the current frame then the associated detections that we found
                % earlier are discarded when trying to perform the association
                index_det = [];
            end
            % Association can only be successful or in other words the
            % tracker can only move to tracked state if the associated
            % detections are rather the potentially associated detections
            % are passed to this function
            % since we are discarding the potentially associated detections if
            % this object is even partially covered in the ground truth,
            % therefore the tracker will remain unassociated if it is
            % even partially covered
            % we seem to be the performing some kind of cheating here by
            % using information from the ground truth to apriorily remove
            % the detections and thus condemn the tracker to fail to associate
            % in other words, the tracker will only associate if this object
            % is known to be completely uncovered in the ground truth
            [tracker, ~, f] = MDP_associate(tracker, fr, dres_image, dres,...
                index_det);
            
            % if is_show
            %     figure(1);
            %     subplot(2, 3, 3);
            %     show_dres(fr, dres_image.I{fr}, 'Potential Associations', sub(dres, index_det));
            %     hold on;
            %     plot(ctrack(1), ctrack(2), 'ro', 'LineWidth', 2);
            %     hold off;
            % end
          
            % only done if the GT is uncovered
            if isempty(index_det) == 0
                % compute reward
                
                % reward computation in the occluded state is only done
                % if the potentially associated detections were not discarded
                % which in turn means that the the object in the GT must be
                % completely uncovered for any of this to happen
                % we can therefore take the complete uncoverage of the object
                % in the ground truth as a priori condition or calling the
                % reward computing function in the occluded state
                [reward, label, f, is_end] = MDP_reward_occluded(fr, f, dres_image, ...
                    dres_gt, dres, index_det, tracker, opt, is_text);
                
                % update weights if negative reward
                if reward == -1
                    tracker.f_occluded(end+1,:) = f;
                    tracker.l_occluded(end+1) = label;
                    tracker.w_occluded = svmtrain(tracker.l_occluded,...
                        tracker.f_occluded, '-c 1 -q -g 1 -b 1');
                    if is_text
                        fprintf('training examples in occluded state %d\n',...
                            size(tracker.f_occluded,1));
                    end
                end
                
                if is_end
                    % this seems to be getting set to 1 in MDP_reward_occluded
                    % whenever the reward is negative;
                    % therefore the tracker seems to be transitioning to the
                    % inactive state whenever we get a negative reward
                    % the transition to inactive estate in turn means that this
                    % particular trajectory will be set to good in the next
                    % frame and then we will break it
                    % this in turn seems to suggest that each trajectory is only
                    % used for training as long as we continue to get
                    % positive reward out of it
                    % and since we only update the SVM whenever we get a
                    % negative reward, it further seems that the we only train from
                    % each trajectory only once when we get negative reward
                    % and as soon as that happens, we break it in the next frame
                    % itself and do not train on it again 
                    
                    % In fact a correction is needed here since the we actually set
                    % this trajectory to good only if the reward is 1
                    % therefore if the tracker state is inactive but the reward is
                    % negative, then we simply break this trajectory without setting
                    % it to good
                    % therefore when we are looking for a trajectory to train on
                    % next time, we might be able to find it - in fact we will be able
                    % to find it when all of the other trajectories have been
                    % used for training too
                    % since the process for finding a trajectory to train is
                    % circular in nature, it always go to the next trajectory first
                    % or rather we always check the next trajectory first but
                    % when we reach the last trajectory, we circle back
                    % to the first one
                    % therefore, if any trajectory is broken down because we got
                    % a negative reward and we set the tracker state to inactive,
                    % we will be able to find it sometime in the future after we are
                    % done training on the subsequent trajectories
                    % which have not been set to good yet
                    tracker.state = 0;
                end
            end
            
            % transition to inactive if lost for a long time
            if tracker.streak_occluded > opt.max_occlusion
                tracker.state = 0;
                if isempty(find(dres_gt.fr == fr, 1)) == 1
                    % This particular object is actually not present in this
                    % frame according to the GT therefore the fact of finding
                    % it to be occluded for very long time in the tracker
                    % means that this object has permanently left the scene
                    % in actuality and therefore the tracker did not fail
                    % and its reward remains positive
                    
                    % In this case, this particular trajectory will be set
                    % to good in the next frame and we will no longer train
                    % on it again because, as we saw before, the object
                    % has been assumed to have left the scene permanently
                    % so there is no further point in training on it again
                    % in other words, we have already trained on all of the  
                    % frames in which the object was actually present scene
                    reward = 1;
                end
                if is_text
                    fprintf('target exits due to long time occlusion\n');
                end
            end
        end
        write_state_info = 2;
        write_to_bin = 1;
        if fr >= write_state_info
            writeStateInfo(tracker, write_to_bin);    
            debugging=1;
        end
        
        % check if outside image
        if tracker.state == 2
            [~, ov] = calc_overlap(tracker.dres, numel(tracker.dres.fr),...
                dres_image, fr);
            if ov < opt.exit_threshold
                if is_text
                    fprintf('target outside image by checking boarders\n');
                end
                % If the tracker state is 2, that is, it is in the tracked state
                % but the current location of the object is too far outside the image
                % or in other words its overlap with the BB corresponding
                % to the entire image is below a threshold we can assume
                % that the object has left the scene by simply going out
                % of its borders and therefore we set the reward to 1 and the
                % tracker state to inactive so that this trajectory is set
                % to good in the next frame and we no longer train on it again
                % here, as in the case of long-term occlusion, we have already
                % trained on all of the frames in which the object
                % is actually present in the scene
                tracker.state = 0;
                reward = 1;
            end
        end
        
        % show results
        % if is_show
        %     figure(1);
        %
        %     % show tracking results
        %     subplot(2, 3, 4);
        %     show_dres(fr, dres_image.I{fr}, 'Tracking', tracker.dres, 2);
        %
        %     % show lost targets
        %     subplot(2, 3, 5);
        %     show_dres(fr, dres_image.I{fr}, 'Lost', tracker.dres, 3);
        %
        %     subplot(2, 3, 6);
        %     show_templates(tracker, dres_image);
        %
        %     fprintf('frame %d, state %d\n', fr, tracker.state);
        %     if is_pause
        %         pause();
        %     else
        %         pause(0.01);
        %     end
        %
        %     % filename = sprintf('results/%s_%06d.png', seq_name, fr);
        %     % hgexport(h, filename, hgexport('factorystyle'), 'Format', 'png');
        % end
        
        % try to connect recently lost target
        if ~(tracker.state == 3 && tracker.prev_state == 2)
            % We do not move on to the next frame if the tracker was
            % in the tracked state in the last frame and is occluded
            % in the current frame
            % or, in other words, if it has been very recently lost
            % in the current frame itself then we try to track it again
            % it is not quite clear what has changed in this
            % particular iteration that we expect the next iteration on
            % the same frame to lead to a different result
            % that is, we seem to be expecting the tracker state to
            % become 2 again when we track this same frame the next
            % time round in the next iteration
            
            % It must be that to the change in parameters by retraining the SVM,
            % if indeed such was done, is expected to have improved the
            % tracker enough to be able to find this object in this frame
            % whwn we track on it again in the next iteration
            fr = fr + 1;
        end        
    end % end tracking this sequence
    
    if fr > seq_num
        is_good(t) = 1;
        fprintf('%s :: trajectory %d is good\n', seq_name, t);
    end
    counter(t) = counter(t) + 1;
    if counter(t) > max_count
        % Exceeded the maximum number of iterations, therefore we will
        % not train on this particular trajectory again
        % it has been discarded as being too difficult to train on
        is_good(t) = 1;
        is_difficult(t) = 1;
        fprintf('%s :: trajectory %d max iteration\n', seq_name, t);
    end
end
fprintf('%s :: Finish training\n', seq_name);

% save model
if is_save
    if db_type == 0
        filename = sprintf('%s/%s_tracker.mat', opt.results, seq_name);
    elseif db_type == 1
        filename = sprintf('%s/kitti_%s_%s_tracker.mat', opt.results_kitti, seq_set, seq_name);
    else
        filename = sprintf('%s/gram_%s_%d_%d_tracker.mat',...
            opt.results_gram, seq_name, train_start_idx, train_end_idx);
    end
    save(filename, 'tracker');
end