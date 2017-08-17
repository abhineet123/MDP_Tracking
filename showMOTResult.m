function status = showMOTResult(seq_idx_list, test_start_offset,...
    vid_start_offset, n_frames)

% addpath('E:\UofA\Thesis\Code\TrackingFramework\Matlab');
opt = globals();
if nargin < 2
    seq_idx_list = [81];
end
if nargin < 2
    test_start_offset = 0;
end
if nargin < 3
    vid_start_offset = 0;
end
if nargin < 4
    n_frames = 0;
end
read_images_in_batch = 0;
save_video = 1;
save_as_img_seq = 0;
db_type = 2;
results_dir = 'results';
save_input_images = 0;
start_idx = 68;
end_idx = 1;

global exit_flag
exit_flag = 0;

if ~exist('seq_idx_list', 'var')
    if end_idx<start_idx
        end_idx = start_idx;
    end
    seq_idx_list = start_idx:end_idx;
end


traj_line_width = 2;
box_line_width = 2;
obj_id_font_size = 6;

status = 0;

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

if db_type == 0
    db_name = 'MOT2015';
    db_path = opt.mot;
    res_path = opt.results;
elseif db_type == 1
    db_name = 'KITTI';
    db_path = opt.kitti;
    res_path = opt.results_kitti;
elseif db_type == 2
    db_name = 'GRAM';
    db_path = opt.gram;
    res_path = opt.results_gram;
    train_ratio = opt.gram_train_ratio;
    test_ratio = opt.gram_test_ratio;
else
    db_name = 'IDOT';
    db_path = opt.idot;
    res_path = opt.results_idot;
    train_ratio = opt.idot_train_ratio;
    test_ratio = opt.idot_test_ratio;
end

n_cols = length(colors);
colors_rgb = cell(n_cols, 1);
for i = 1:n_cols
    colors_rgb{i} = col_rgb{strcmp(col_names,colors{i})};
end

hf = figure(1);
set(hf,'WindowButtonDownFcn',@ButtonDown);

for seq_idx = seq_idx_list
    if db_type == 0
        seq_name = opt.mot2d_test_seqs{seq_idx};
        seq_num = opt.mot2d_test_nums(seq_idx);
        seq_set = 'test';
        filename = sprintf('%s/%s_dres_image.mat', results_dir, seq_name);
    elseif db_type == 1
        seq_name = opt.kitti_train_seqs{seq_idx};
        seq_num = opt.kitti_train_nums(seq_idx);
        seq_set = 'training';
        filename = sprintf('%s/kitti_%s_%s_dres_image.mat', opt.results_kitti, seq_set, seq_name);
    else
        seq_name = opt.gram_seqs{seq_idx};
        seq_n_frames = opt.gram_nums(seq_idx);
        if test_ratio(seq_idx)<=0
            seq_train_ratio = train_ratio(seq_idx);
            [ start_idx, end_idx ] = getInvSubSeqIdx(seq_train_ratio,...
                seq_n_frames, test_start_offset);
        else
            seq_test_ratio = test_ratio(seq_idx);
            [ start_idx, end_idx ] = getSubSeqIdx(seq_test_ratio,...
                seq_n_frames, test_start_offset);
        end
        filename = sprintf('%s/%s_%d_%d_dres_image.mat',...
            opt.results, seq_name, start_idx, end_idx);
        seq_num = end_idx - start_idx + 1;
        if n_frames > 0 && n_frames < seq_num
            seq_num = n_frames;
        end
    end
    
    start_frame_idx = vid_start_offset + start_idx;
    if start_frame_idx > end_idx
        return
    end
    end_frame_idx = start_frame_idx + seq_num - 1;
    if end_frame_idx > end_idx
        end_frame_idx = end_idx;
        seq_num = end_frame_idx - start_frame_idx + 1;
    end
    if read_images_in_batch
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
                    start_frame_idx, end_frame_idx, 1, 0);
            end
            fprintf('done\n');
            if save_input_images
                fprintf('saving images to file %s...', filename);
                save(filename, 'dres_image', '-v7.3');
                fprintf('done\n');
            end
        end
    end
    
    if db_type == 0
        filename = sprintf('%s/%s.txt', opt.results, seq_name);
        file_video = sprintf('%s/%s.mp4', opt.results, seq_name);
        dres_track = read_mot2dres(filename);
    elseif db_type == 1
        filename = sprintf('%s/%s.txt', opt.results_kitti, seq_name);
        file_video = sprintf('%s/%s.mp4', opt.results_kitti, seq_name);
        dres_track = read_kitti2dres(filename);
    else
        filename = sprintf('%s/%s_%d_%d.txt', res_path, seq_name,...
            start_idx, end_idx);
        dres_track = read_gram2dres(filename);
    end
    fprintf('reading tracking results from %s\n', filename);
    
    if save_video
        video_dir = sprintf('Tracked/%s', db_name);
        if ~exist(video_dir, 'dir')
            mkdir(video_dir);
        end
        if save_as_img_seq
            img_seq_dir = fullfile(video_dir, sprintf('%s_%d_%d', seq_name,...
                start_idx, end_idx));
            fprintf('saving image sequence to %s\n', img_seq_dir);
            if ~exist(img_seq_dir, 'dir')
                mkdir(img_seq_dir);
            end
        else
            file_video = sprintf('%s/%s_%d_%d.mp4', video_dir, seq_name,...
                start_frame_idx, end_frame_idx);
            aviobj = VideoWriter(file_video, 'MPEG-4');
            aviobj.FrameRate = 30;
            open(aviobj);
            fprintf('saving video to %s\n', file_video);
        end
    end
    for fr = start_frame_idx:end_frame_idx
        if read_images_in_batch
            show_dres_gt(fr, dres_image.I{fr - start_frame_idx + 1}, dres_track, colors_rgb,...
                box_line_width, traj_line_width, obj_id_font_size);
        else
            dres_image = read_dres_image_gram(db_path, seq_name,...
                fr, fr, 1, 0, 0);
            show_dres_gt(fr, dres_image.I{1}, dres_track, colors_rgb,...
                box_line_width, traj_line_width, obj_id_font_size);
        end
        if save_video
            if save_as_img_seq
                img_file = fullfile(img_seq_dir, sprintf('frame%06d.png', fr));
                saveas(hf, img_file);
            else
                writeVideo(aviobj, getframe(hf));
            end
        end
        pause(0.001);
        if mod(fr - start_frame_idx + 1, 100) == 0
            fprintf('Done %d frames\n', fr - start_frame_idx + 1);
        end
        if exit_flag
            fprintf('exiting...\n');
            break;
        end
    end
    
    if save_video && ~save_as_img_seq
        close(aviobj);
    end
end
status = 1;
end
function ButtonDown(hObject, eventdata)
global exit_flag
exit_flag = 1;
end