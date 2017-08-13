% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function opt = globals()

%% Important settings

gram_train_ratio = 1;
gram_split_train_ratio = 0.6;
idot_train_ratio = -0.4;
lost_train_ratio = 0.6;
isl_train_ratio = 0.6;

gram_test_ratio = 1;
gram_split_test_ratio = 1;
idot_test_ratio = 1;
lost_test_ratio = 1;
isl_test_ratio = 1;

if isunix
    gram_paths = {'/data/GRAM'};
    idot_paths = {'/data/IDOT'};
else
    gram_paths = {'C:\Datasets\GRAM'};
    idot_paths = {'C:\Datasets\IDOT'};
end
path_found = 0;
for i = 1:numel(gram_paths)
    if exist(gram_paths{i}, 'dir')
        opt.gram = gram_paths{i};
        path_found = 1;
        break;        
    end
end
if ~path_found
    error('None of the GRAM paths are valid');
end

opt.gram_seqs = {'M-30','M-30-HD','Urban1','M-30-Large','M-30-HD-Small'};
opt.gram_nums = [7520, 9390, 23435, 7520, 9390];
opt.gram_train_ratio = ones(1, numel(opt.gram_nums)) * gram_train_ratio;
opt.gram_test_ratio = ones(1, numel(opt.gram_nums)) * gram_test_ratio;
opt.gram_types = {'Car', 'Pedestrian', 'Cyclist'};

opt.gram_split_seqs = {'M-30_1','M-30_2','M-30_3','M-30_4','M-30_5','M-30_6','M-30_7','M-30_8',...
    'M-30_9','M-30_10','M-30_11','M-30_12','M-30_13','M-30_14','M-30_15',...
    'M-30-HD_1','M-30-HD_2','M-30-HD_3','M-30-HD_4','M-30-HD_5','M-30-HD_6','M-30-HD_7',...
    'M-30-HD_8','M-30-HD_9','M-30-HD_10','M-30-HD_11','M-30-HD_12','M-30-HD_13','M-30-HD_14','M-30-HD_15',...
    'Urban1_1','Urban1_2','Urban1_3','Urban1_4','Urban1_5','Urban1_6','Urban1_7','Urban1_8',...
    'Urban1_9','Urban1_10','Urban1_11','Urban1_12','Urban1_13','Urban1_14','Urban1_15','Urban1_16',...
    'Urban1_17','Urban1_18','Urban1_19','Urban1_20','Urban1_21','Urban1_22','Urban1_23','Urban1_24',...
    'Urban1_25','Urban1_26','Urban1_27','Urban1_28','Urban1_29','Urban1_30'};
opt.gram_split_nums = [501, 501, 501, 501, 501, 501, 501, 501, 501, 501, 501, 501, 501, 501, 506,...
    626, 626, 626, 626, 626, 626, 626, 626, 626, 626, 626, 626, 626, 626, 626,...
    781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781,...
    781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 786];
opt.gram_split_train_ratio = ones(1, numel(opt.gram_split_nums)) * gram_split_train_ratio;
opt.gram_split_test_ratio = ones(1, numel(opt.gram_split_nums)) * gram_split_test_ratio;

opt.idot_seqs = {'seq_1', 'seq_2', 'seq_3', 'seq_4', 'seq_5', 'seq_6',...
    'seq_7', 'seq_8', 'seq_9', 'seq_10', 'seq_11', 'seq_12', 'seq_13'};
opt.idot_nums = [8991, 8990, 8981, 8866, 8851, 8791, 8964, 8962, 8966,...
    7500, 7500, 7500, 8851];
opt.idot_train_ratio = ones(1, numel(opt.idot_nums)) * idot_train_ratio;
opt.idot_test_ratio = ones(1, numel(opt.idot_nums)) * idot_test_ratio;

opt.lost_seqs = {'009_2011-03-29_07-00-00', '009_2011-04-24_07-00-00'};
opt.lost_nums = [3027, 5000];
opt.lost_train_ratio = ones(1, numel(opt.lost_nums)) * lost_train_ratio;
opt.lost_test_ratio = ones(1, numel(opt.lost_nums)) * lost_test_ratio;

opt.isl_seqs = {
    '20170620-055940', '20170620-060941',...
    '20170620-061942', '20170620-062943', '20170620-063943',...
    '20170620-064944', '20170620-065944', '20170620-070945',...
    '20170620-071946', '20170620-072946', '20170620-073947',...
    '20170620-074947', '20170620-075949'
    };
opt.isl_nums = [10162, 10191, 10081, 10089, 10177, 10195, 10167, 10183,...
    10174, 10127, 9738, 10087, 8614];
opt.isl_train_ratio = ones(1, numel(opt.isl_nums)) * isl_train_ratio;
opt.isl_test_ratio = ones(1, numel(opt.isl_nums)) * isl_test_ratio;

opt.gram_seqs = cat(2, opt.gram_seqs, opt.gram_split_seqs, opt.idot_seqs,...
    opt.lost_seqs,opt.isl_seqs);
opt.gram_nums = cat(2, opt.gram_nums, opt.gram_split_nums, opt.idot_nums,...
    opt.lost_nums, opt.isl_nums);
opt.gram_train_ratio = cat(2, opt.gram_train_ratio,...
    opt.gram_split_train_ratio, opt.idot_train_ratio,...
    opt.lost_train_ratio, opt.isl_train_ratio);
opt.gram_test_ratio = cat(2, opt.gram_test_ratio, opt.gram_split_test_ratio,...
    opt.idot_test_ratio, opt.lost_test_ratio, opt.isl_test_ratio);

% opt.stanford_seqs = {{'quad', [0:3]}, {'bookstore', [0:6]}, {'coupa', [0:3]},...
%     {'deathCircle', [0:4]},...
%     {'gates', [0:8]}, {'hyang', [0:14]}, {'little', [0:3]}, {'nexus', [0:11]}};

%% Obsolete settings

opt.root = pwd;

if isunix
    mot_paths = {'/data/MOT2015/'};   
    kitti_paths = {'/data/KITTI'};
else
    mot_paths = {'C:\Datasets\MOT2015'};
    kitti_paths = {'C:\Datasets\KITTI'};
end

for i = 1:numel(mot_paths)
    if exist(mot_paths{i}, 'dir')
        opt.mot = mot_paths{i};
        break;
    end
end

opt.mot2d = '2DMOT2015';
opt.results = 'results';
opt.results_kitti = 'results_kitti';
opt.results_gram = 'results_gram';
opt.results_idot = 'results_idot';

opt.mot2d_train_seqs = {'TUD-Stadtmitte', 'TUD-Campus', 'PETS09-S2L1', ...
    'ETH-Bahnhof', 'ETH-Sunnyday', 'ETH-Pedcross2', 'ADL-Rundle-6', ...
    'ADL-Rundle-8', 'KITTI-13', 'KITTI-17', 'Venice-2'};
opt.mot2d_train_nums = [179, 71, 795, 1000, 354, 837, 525, 654, 340, 145, 600];

opt.mot2d_test_seqs = {'TUD-Crossing', 'PETS09-S2L2', 'ETH-Jelmoli', ...
    'ETH-Linthescher', 'ETH-Crossing', 'AVG-TownCentre', 'ADL-Rundle-1', ...
    'ADL-Rundle-3', 'KITTI-16', 'KITTI-19', 'Venice-1'};
opt.mot2d_test_nums = [201, 436, 440, 1194, 219, 450, 500, 625, 209, 1059, 450];

% path for KITTI tracking dataset

for i = 1:numel(kitti_paths)
    if exist(kitti_paths{i}, 'dir')
        opt.kitti = kitti_paths{i};
        break;
    end
end

opt.kitti_train_seqs = {'0000', '0001', '0002', '0003', '0004', '0005', ...
    '0006', '0007', '0008', '0009', '0010', '0011', '0012', '0013', '0014', ...
    '0015', '0016', '0017', '0018', '0019', '0020'};
opt.kitti_train_nums = [154, 447, 233, 144, 314, 297, 270, 800, 390, 803, 294, ...
    373, 78, 340, 106, 376, 209, 145, 339, 1059, 837];

opt.kitti_test_seqs = {'0000', '0001', '0002', '0003', '0004', '0005', ...
    '0006', '0007', '0008', '0009', '0010', '0011', '0012', '0013', '0014', ...
    '0015', '0016', '0017', '0018', '0019', '0020', '0021', '0022', ...
    '0023', '0024', '0025', '0026', '0027', '0028'};
opt.kitti_test_nums = [465, 147, 243, 257, 421, 809, 114, 215, 165, 349, 1176, ...
    774, 694, 152, 850, 701, 510, 305, 180, 404, 173, 203, 436, 430, 316, 176, ...
    170, 85, 175];
opt.kitti_types = {'Car', 'Pedestrian', 'Cyclist'};

%% Add paths

% addpath(fullfile(opt.mot, 'devkit', 'utils'));
% addpath(fullfile(opt.kitti, 'devkit', 'matlab'));
addpath(fullfile('utils'));

if isunix
    addpath([opt.root '/3rd_party/libsvm-3.20/matlab']);
    addpath([opt.root '/3rd_party/Hungarian']);
else
    addpath([opt.root '\3rd_party\libsvm-3.20\matlab']);
    addpath([opt.root '\3rd_party\Hungarian']);
end

if exist(opt.results, 'dir') == 0
    mkdir(opt.results);
end

if exist(opt.results_kitti, 'dir') == 0
    mkdir(opt.results_kitti);
end

if exist(opt.results_gram, 'dir') == 0
    mkdir(opt.results_gram);
end

%% tracking parameters

opt.num = 10;                 % number of templates in tracker (default 10)
opt.fb_factor = 30;           % normalization factor for forward-backward error in optical flow
opt.threshold_ratio = 0.6;    % aspect ratio threshold in target association
opt.threshold_dis = 3;        % distance threshold in target association, multiple of the width of target
opt.threshold_box = 0.8;      % bounding box overlap threshold in tracked state
opt.std_box = [30 60];        % [width height] of the stanford (?? probably standard) box in computing flow
opt.margin_box = [5, 2];      % [width height] of the margin in computing flow
opt.enlarge_box = [5, 3];     % enlarge the box before computing flow
opt.level_track = 1;          % LK level in association
opt.level =  1;               % LK level in association
opt.max_ratio = 0.9;          % min allowed ratio in LK
opt.min_vnorm = 0.2;          % min allowed velocity norm in LK
opt.overlap_box = 0.5;        % overlap with detection in LK
opt.patchsize = [24 12];      % patch size for target appearance
opt.weight_tracking = 1;      % weight for tracking box in tracked state
opt.weight_detection = 1;      % weight for detection box in tracked state
opt.weight_association = 1;   % weight for tracking box in lost state
opt.overlap_suppress1 = 0.5;   % overlap for suppressing detections with tracked objects
opt.overlap_suppress2 = 0.5;   % overlap for suppressing detections with tracked objects

% parameters for generating training data
opt.overlap_occ = 0.7;
opt.overlap_pos = 0.5;
opt.overlap_neg = 0.2;
opt.overlap_sup = 0.7;      % suppress target used in testing only

% training parameters
opt.max_iter = 10000;     % max iterations in total
opt.max_count = 10;       % max iterations per sequence
opt.max_pass = 2;

% parameters to transite to inactive
opt.max_occlusion = 50;
opt.exit_threshold = 0.95;
opt.tracked = 5;