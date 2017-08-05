% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function showMOTGT()

addpath('E:\UofA\Thesis\Code\TrackingFramework\Matlab');

save_video = 1;
show_detections = 1;
db_type = 2;
start_idx = 73;
end_idx = 73;
seq_idx_list = [1:3, 66:78];

seq_start_offset_ratio = 0;
seq_ratio = 0.1;

save_input_images = 0;
video_fps = 30;

box_line_width = 1;
traj_line_width = 1;
obj_id_font_size = 6;

seq_type = 0;

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

if ~exist('seq_idx_list', 'var')
    if end_idx<start_idx
        end_idx = start_idx;
    end
    seq_idx_list = start_idx:end_idx;
end
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
        start_frame_idx = 1;
        end_frame_idx = seq_num;
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
        start_frame_idx = 1;
        end_frame_idx = seq_num;
        filename = sprintf('%s/kitti_%s_%s_dres_image.mat', opt.results_kitti, seq_set, seq_name);
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
        filename = sprintf('%s/%s_dres_image_%d_%d.mat', opt.results,...
            seq_name, start_idx, end_idx);
        seq_num = end_frame_idx - start_frame_idx + 1;
    end  
    
    % build the dres structure for images
    if exist(filename, 'file') ~= 0
        fprintf('loading images from file %s...', filename);
        object = load(filename);
        dres_image = object.dres_image;
        fprintf('done\n');
    else
        fprintf('reading images...\n');
        if db_type == 0
            dres_image = read_dres_image(opt, seq_set, seq_name, seq_num);
        elseif db_type == 1
            dres_image = read_dres_image_kitti(opt, seq_set, seq_name, seq_num);
        else
            dres_image = read_dres_image_gram(db_path, seq_name,...
                start_frame_idx, end_frame_idx);
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
            filename = fullfile(db_path, 'Detections', [seq_name '.txt']);
            dres_det = read_gram2dres(filename, start_frame_idx, end_frame_idx);
        end
    else
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
    end

    if save_video
        if show_detections
            video_dir = sprintf('Detections/%s', db_name);
        else
            video_dir = sprintf('GT/%s', db_name);            
        end        
        if ~exist(video_dir, 'dir')
            mkdir(video_dir);
        end
        file_video = sprintf('%s/%s_%d_%d.mp4', video_dir, seq_name,...
            start_frame_idx, end_frame_idx);
        aviobj = VideoWriter(file_video, 'MPEG-4');
        aviobj.FrameRate = video_fps;
        open(aviobj);
        fprintf('saving video to %s\n', file_video);
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
        if save_video
            writeVideo(aviobj, getframe(hf));
        else
            pause(0.001);
        end
    end

    if save_video
        close(aviobj);
    end
end
end