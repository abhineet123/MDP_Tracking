% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% generate training data from GRAM
function [dres_train, dres_det, labels, dres_gt] = generate_training_data_gram(db_path,...
    seq_name, dres_image, opt, train_start_idx, train_end_idx)

% dres.covered: Normalized overlap between the bounding box for each target
% in each frame with the maximally overlapping GT box in the same frame
is_show = 0;

% read detections
filename = fullfile(db_path, 'Detections', [seq_name '.txt']);
fprintf('reading detections from: %s\n', filename);
try    
    zip_files = ls(fullfile(db_path, 'Detections', '*.zip'));    
    fprintf('Zip files in this folder:\n');
    disp(zip_files)
catch ME
    fprintf('No zip files in this folder\n');
end
    
dres_det = read_gram2dres(filename, train_start_idx, train_end_idx);

% read ground truth
filename = fullfile(db_path, 'Annotations', [seq_name '.txt']);
fprintf('reading gt from: %s\n', filename);
dres_gt = read_gram2dres(filename, train_start_idx, train_end_idx);
 % max y of all objects in the gt
y_gt = dres_gt.y + dres_gt.h;

% collect true positives and false alarms from detections
num = numel(dres_det.fr); %  no. of detections
labels = zeros(num, 1);
overlaps = zeros(num, 1);
indices = zeros(num, 1);
for i = 1:num
    fr = dres_det.fr(i);
    index = find(dres_gt.fr == fr);
    if isempty(index) == 0
        % overlaps between detection i and all gt boxes in the same frame
        % as this detection
        overlap = calc_overlap(dres_det, i, dres_gt, index);
        [o, max_ind] = max(overlap);
        % label this detection based on the maximum overlap between it and
        % all gt boxes in its frame
        if o < opt.overlap_neg % 0.2
            labels(i) = -1; % false positive
        elseif o > opt.overlap_pos % 0.5
            labels(i) = 1; % true positive
        else
            labels(i) = 0; % unknown
        end
        overlaps(i) = o;
        indices(i) = max_ind;
    else
        overlaps(i) = 0;
        labels(i) = -1;
        indices(i) = -1;
    end
end

% entries = {
%     {overlaps, 'detections_overlaps', 'float32',  '%.10f'},...
%     {labels, 'detections_labels', 'float32', '%.10f'},...
%     };
% writeToFiles('log', 0, entries);


% build the training sequences
ids = unique(dres_gt.id);
dres_train = [];
count = 0;

n_gt = numel(dres_gt.id);
dres_gt.occluded = zeros(n_gt, 1);
dres_gt.covered = zeros(n_gt, 1);
dres_gt.overlap = zeros(n_gt, 1);
dres_gt.area_inside = zeros(n_gt, 1);
dres_gt.r = zeros(n_gt, 1);

% one object/target in the GT at a time
for i = 1:numel(ids)    
    % check if the target is occluded or not
    
     % set of frames with this object
    index_global = find(dres_gt.id == ids(i)); 
    dres = sub(dres_gt, index_global); 
    % no. of frames with this object
    num = numel(dres.fr);
    dres.occluded = zeros(num, 1);
    dres.covered = zeros(num, 1); % with GT boxes    
    dres.overlap = zeros(num, 1); % with detections
    dres.r = zeros(num, 1);
    dres.area_inside = zeros(num, 1);
    y = dres.y + dres.h; % max y of the object box
    % one frame containing this object at a time
    for j = 1:num
        fr = dres.fr(j);
        % all objects except the current one in the current frame 
        index_gt = find(dres_gt.fr == fr & dres_gt.id ~= ids(i));
        
        if isempty(index_gt) == 0
            % normalized intersection area of this GT box with all other 
            % GT boxes in the current frame
            [~, ov] = calc_overlap(dres, j, dres_gt, index_gt); 
            % for some unknown reason, if the max y of this box exceeds the
            % max y of another box, the norm overlap between them is set to 0
            invalid_idx = y(j) > y_gt(index_gt);
            ov(invalid_idx) = 0;
            % fractional coverage of this object is the max norm overlap
            dres.covered(j) = max(ov);
            
        end
        % if fractional coverage of this obj exceeds a threshold, it is
        % considered as occluded
        if dres.covered(j) > opt.overlap_occ % 0.7
            dres.occluded(j) = 1;
        end
        
        % overlap with detections
        index_det = find(dres_det.fr == fr);
        if isempty(index_det) == 0
            overlap = calc_overlap(dres, j, dres_det, index_det);
            [o, ind] = max(overlap);
            % overlap is the IoU rather than the IoA that was
            % used for GT coverage; the pruning of boxes whose maximum y exceeds
            % this box's is not done either
            dres.overlap(j) = o;        
            % detection score of the detection with the maximum overlap
            dres.r(j) = dres_det.r(index_det(ind));
            
            % area inside image of the max overlap detection
            [~, overlap] = calc_overlap(dres_det, index_det(ind), dres_image, 1);
            dres.area_inside(j) = overlap;
        end
        gt_id = index_global(j);
        dres_gt.covered(gt_id) = dres.covered(j);
        dres_gt.overlap(gt_id) = dres.overlap(j);
        dres_gt.occluded(gt_id) = dres.occluded(j);
        dres_gt.area_inside(gt_id) = dres.area_inside(j);        
        dres_gt.r(gt_id) = dres.r(j);        
    end
    
    % start with bounding overlap > opt.overlap_pos and non-occluded box
    
    % start with the frame where the overlap with the detection that has the maximum overlap
    % with this box is greater than a threshold - 0.5 - and it is not  
    % covered by another GT box and the fraction of the maximum overlap 
    % detection box that lies  inside the image also exceeds a threshold - 0.95
    index = find(dres.overlap > opt.overlap_pos & dres.covered == 0 & dres.area_inside > opt.exit_threshold);

    if isempty(index) == 0
        index_start = index(1);
        count = count + 1;
        dres_train{count} = sub(dres, index_start:num);
        
        % show gt
        % if is_show
        % disp(count);
        % for j = 1:numel(dres_train{count}.fr)
        %     fr = dres_train{count}.fr(j);
        %     I = dres_image.I{fr};
        %     figure(1);
        %     show_dres(fr, I, 'GT', dres_train{count});
        %     pause;
        % end
        % end
    end
end

if opt.write_state_info
    fp_dtype = 'float32';
    fp_fmt = '%.10f';
    entries = {
        {labels, 'labels', 'int32', '%d'},...
        {overlaps, 'overlaps', fp_dtype, fp_fmt},...
        {indices, 'indices', 'int32', '%d'},...
        };
    writeToFiles(sprintf('log/detections'), opt.write_to_bin, entries);
    entries = {
        {dres_gt.covered, 'covered', fp_dtype, fp_fmt},...
        {dres_gt.overlap, 'overlaps', fp_dtype, fp_fmt},...
        {dres_gt.occluded, 'occluded', fp_dtype, fp_fmt},...
        {dres_gt.area_inside, 'area_inside', fp_dtype, fp_fmt},...
        {dres_gt.r, 'scores', fp_dtype, fp_fmt},...
        };
    writeToFiles(sprintf('log/annotations'), opt.write_to_bin, entries);
    sync_w_fname = sprintf('log/write_0.sync');
    fclose(fopen(sync_w_fname, 'w'));
    sync_r_fname = sprintf('log/read_0.sync');
    fprintf('Waiting for %s...',sync_r_fname);
    pause('on')
    iter_id = 0;
    max_iters = 10;
    while ~exist(sync_r_fname, 'file')
        pause(0.5);
        iter_id = iter_id + 1;
        if iter_id == max_iters
            % pause for debugging after 5 seconds
            debugging = 1;
            % break;
        end
        % fprintf('.');
    end
    fprintf('\n');
    delete(sync_r_fname);
end

fprintf('%s: %d positive sequences\n', seq_name, numel(dres_train));