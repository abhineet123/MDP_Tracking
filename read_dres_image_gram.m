% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function dres_image = read_dres_image_gram(db_path, seq_name,...
    start_idx, end_idx)
n_frames = end_idx - start_idx + 1;
fprintf('start_idx: %d end_idx: %d n_frames: %d\n',...
    start_idx, end_idx, n_frames);

dres_image.x = zeros(n_frames, 1);
dres_image.y = zeros(n_frames, 1);
dres_image.w = zeros(n_frames, 1);
dres_image.h = zeros(n_frames, 1);
dres_image.I = cell(n_frames, 1);
dres_image.Igray = cell(n_frames, 1);

for frame_id = start_idx:end_idx
    filename = fullfile(db_path, 'Images', seq_name, sprintf('image%06d.jpg', frame_id));
    I = imread(filename);
    
    id = frame_id - start_idx + 1;

    dres_image.x(id) = 1;
    dres_image.y(id) = 1;
    dres_image.w(id) = size(I, 2);
    dres_image.h(id) = size(I, 1);
    dres_image.I{id} = I;
    dres_image.Igray{id} = rgb2gray(I);
    
    if mod(id, 500) == 0
        fprintf('Done %d frames\n', id);
    end
end