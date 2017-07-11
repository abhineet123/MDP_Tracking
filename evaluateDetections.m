% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
close all;
clear all;

addpath('E:\UofA\Thesis\Code\TrackingFramework\Matlab');

is_save = 0;
show_detections = 1;
db_type = 2;
seq_type = 0;
idot_split = 1;
save_input_images = 0;
video_fps = 30;

start_idx = 5;
end_idx = 5;
seq_start_offset_ratio = 0;
seq_ratio = 0.05;

box_line_width = 1;
traj_line_width = 1;
obj_id_font_size = 6;

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

if db_type == 0
    db_name = 'MOT2015';
    db_path = opt.mot;
elseif db_type == 1
    db_name = 'KITTI';
    db_path = opt.kitti;
elseif db_type == 2
    db_name = 'GRAM';
    db_path = opt.gram;
else
    db_name = 'IDOT';
    db_path = opt.idot;
end

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
    else
        if db_type == 2
            seq_name = opt.gram_seqs{seq_idx};
            seq_n_frames = opt.gram_nums(seq_idx);
        else
            seq_name = opt.idot_seqs{seq_idx};
            seq_n_frames = opt.idot_nums(seq_idx);
        end
        seq_start_offset = seq_start_offset_ratio * seq_n_frames;
        [start_frame_idx, end_frame_idx] = getSubSeqIdx(seq_ratio, seq_n_frames,...
            seq_start_offset);
        seq_num = end_frame_idx - start_frame_idx + 1;
    end     

    % read detections
    if db_type == 0
        filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'det', 'det.txt');
        dres_det = read_mot2dres(filename);
    elseif db_type == 1
        filename = fullfile(opt.kitti, seq_set, 'det_02', [seq_name '.txt']);
        dres_det = read_kitti2dres(filename);
    else
        filename = fullfile(db_path, 'Detections', [seq_name '.txt']);
        dres_det = read_gram2dres(filename, start_frame_idx, end_frame_idx);
    end
    
    % read ground truth
    if db_type == 0
        filename = fullfile(opt.mot, opt.mot2d, seq_set, seq_name, 'gt', 'gt.txt');
        dres_gt = read_mot2dres(filename);
        dres_gt = fix_groundtruth(seq_name, dres_gt);
    elseif db_type == 1
        filename = fullfile(opt.kitti, seq_set, 'label_02', [seq_name '.txt']);
        dres_gt = read_kitti2dres(filename);
    else
        if db_type == 2
            filename = fullfile(opt.gram, 'Annotations',...
                [seq_name '.txt']);
        elseif db_type == 3
            filename = fullfile(opt.idot, 'Annotations',...
                [seq_name '.txt']);
        end            
        dres_gt = read_gram2dres(filename, start_frame_idx, end_frame_idx);
    end   
    
    for fr = 1:seq_num
        if show_detections
            show_dres_gt(fr, dres_image.I{fr}, dres_det, colors_rgb,...
                box_line_width, traj_line_width, obj_id_font_size);
        else
            show_dres_gt(fr, dres_image.I{fr}, dres_gt, colors_rgb,...
                box_line_width, traj_line_width, obj_id_font_size);
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