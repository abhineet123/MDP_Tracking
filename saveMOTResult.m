close all;
% clear all;

is_save = 0;
opt = globals();
db_type = 0;
seq_idx = 2;
results_dir = 'results';


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

hf = figure(1);
if db_type == 0
    seq_name = opt.mot2d_test_seqs{seq_idx};
    seq_num = opt.mot2d_test_nums(seq_idx);    
    seq_set = 'train';
    filename = sprintf('%s/%s_dres_image.mat', results_dir, seq_name);
elseif db_type == 1
    seq_name = opt.kitti_train_seqs{seq_idx};
    seq_num = opt.kitti_train_nums(seq_idx);
    seq_set = 'training';
    filename = sprintf('%s/kitti_%s_%s_dres_image.mat', opt.results_kitti, seq_set, seq_name);
else
    seq_name = opt.gram_seqs{seq_idx};
    seq_num = opt.gram_nums(seq_idx);
    filename = sprintf('%s/%s_dres_image.mat', opt.results, seq_name);
end

% build the dres structure for images
if exist(filename, 'file') ~= 0
    object = load(filename);
    dres_image = object.dres_image;
    fprintf('load images from file %s done\n', filename);
else
    if db_type == 0
        dres_image = read_dres_image(opt, seq_set, seq_name, seq_num);
    elseif db_type == 1
        dres_image = read_dres_image_kitti(opt, seq_set, seq_name, seq_num);
    else
        dres_image = read_dres_image_gram(opt, seq_name, start_id, end_id);
    end        
    fprintf('read images done\n');
    save(filename, 'dres_image', '-v7.3');
end

% read tracking results
filename = sprintf('%s/%s.txt', results_dir, seq_name);
dres_track = read_mot2dres(filename);
fprintf('read tracking results from %s\n', filename);
ids = unique(dres_track.id);
cmap = colormap(hsv(numel(ids)));
cmap = cmap(randperm(numel(ids)),:);

if is_save
    file_video = sprintf('results_MOT/results_MOT_1/%s.avi', seq_name);
    aviobj = VideoWriter(file_video);
    aviobj.FrameRate = 9;
    open(aviobj);
    fprintf('save video to %s\n', file_video);
end

for fr = 1:seq_num
    show_dres(fr, dres_image.I{fr}, '', dres_track, 2, cmap);
    if is_save
        writeVideo(aviobj, getframe(hf));
    else
        pause(0.001);
    end
end

if is_save
    close(aviobj);
end