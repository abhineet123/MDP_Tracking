% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
close all;
clear all;

addpath('E:\UofA\Thesis\Code\TrackingFramework\Matlab');

is_save = 1;
show_detections = 0;
db_type = 0;
seq_type = 0;
save_input_images = 0;
start_idx = 1;
end_idx = 11;

colRGBDefs;
colors={
    'blue',...%1
    'red',...%2
    'green',...%3
    'cyan',...%4
    'magenta',...%5
    'yellow',...%6
    'forest_green',...%7
    'slate_gray',...%8
    'peach_puff_3',...%9
    'maroon',...%10
    'purple',...%11
    'orange',...%12
    'gold'...%13
    };

n_cols = length(colors);
colors_rgb = cell(n_cols, 1);
for i = 1:n_cols
    colors_rgb{i} = col_rgb{strcmp(col_names,colors{i})};
end

seq_idx_list = start_idx:end_idx;
opt = globals();

for seq_idx = seq_idx_list
    hf = figure(1);

    if db_type == 0
        if seq_type==0
            seq_name = opt.mot2d_train_seqs{seq_idx};
            seq_num = opt.mot2d_train_nums(seq_idx);    
            seq_set = 'train';
        else
            seq_name = opt.mot2d_test_seqs{seq_idx};
            seq_num = opt.mot2d_test_nums(seq_idx);    
            seq_set = 'test';
        end        
        filename = sprintf('%s/%s_dres_image.mat', results_dir, seq_name);
    elseif db_type == 1
        if seq_type==0
            seq_name = opt.kitti_train_seqs{seq_idx};
            seq_num = opt.kitti_train_nums(seq_idx);
            seq_set = 'training';
        else
            seq_name = opt.kitti_test_seqs{seq_idx};
            seq_num = opt.kitti_test_nums(seq_idx);
            seq_set = 'testing';
        end 
        filename = sprintf('%s/kitti_%s_%s_dres_image.mat', opt.results_kitti, seq_set, seq_name);
    else
        seq_name = opt.gram_seqs{seq_idx};
        seq_num = opt.gram_nums(seq_idx);
        filename = sprintf('%s/%s_dres_image.mat', opt.results, seq_name);
    end

    % build the dres structure for images
    if exist(filename, 'file') ~= 0
        fprintf('loading images from file %s...', filename);
        object = load(filename);
        dres_image = object.dres_image;
        fprintf('done\n');
    else
        fprintf('reading images...');
        if db_type == 0
            dres_image = read_dres_image(opt, seq_set, seq_name, seq_num);
        elseif db_type == 1
            dres_image = read_dres_image_kitti(opt, seq_set, seq_name, seq_num);
        else
            dres_image = read_dres_image_gram(opt, seq_name, seq_num);
        end 
        fprintf('done\n');
        if save_input_images
            fprintf('saving images to file %s...', filename);
            save(filename, 'dres_image', '-v7.3');
            fprintf('done\n');
        end
    end
    if show_detections
        % read detections
        if db_type == 0
            filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'det', 'det.txt');
            dres_det = read_mot2dres(filename);
        elseif db_type == 1
            filename = fullfile(opt.kitti, seq_set, 'det_02', [seq_name '.txt']);
            dres_det = read_kitti2dres(filename);
        else
            filename = fullfile(opt.gram, 'Detections', [seq_name '.txt']);
            dres_det = read_gram2dres(filename);
        end
    end

    if db_type == 0
        % read ground truth
        filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'gt', 'gt.txt');
        dres_gt = read_mot2dres(filename);
        dres_gt = fix_groundtruth(seq_name, dres_gt);
    elseif db_type == 1
        % read ground truth
        filename = fullfile(opt.kitti, seq_set, 'label_02', [seq_name '.txt']);
        dres_gt = read_kitti2dres(filename);
    else
        % read ground truth
        filename = fullfile(opt.gram, 'Annotations', [seq_name '.txt']);
        dres_gt = read_gram2dres(filename);
    end

    if is_save
        if show_detections
            file_video = sprintf('GT/%s_det.avi', seq_name);
        else
            file_video = sprintf('GT/%s_gt.avi', seq_name);
        end
        aviobj = VideoWriter(file_video);
        aviobj.FrameRate = 9;
        open(aviobj);
        fprintf('saving video to %s\n', file_video);
    end

    for fr = 1:seq_num
        if show_detections
            show_dres_gt(fr, dres_image.I{fr}, dres_det, colors_rgb);
        else
            show_dres_gt(fr, dres_image.I{fr}, dres_gt, colors_rgb);
        end
        % imshow(dres_image.I{fr});
        if is_save
            writeVideo(aviobj, getframe(hf));
        else
            pause(0.001);
        end
    end

    if is_save
        close(aviobj);
    end
end