% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function dres_image = read_dres_image_gram(db_path, seq_name,...
    start_idx, end_idx, storage_offset, store_rgb, store_gs, verbose)

if nargin < 5
    storage_offset = 0;
end
if nargin < 6
    store_rgb = 0;
end
if nargin < 7
    store_gs = 1;
end
if nargin < 8
    verbose = 1;
end

n_frames = end_idx - start_idx + 1;
seq_path = fullfile(db_path, 'Images', seq_name);
if verbose
    fprintf('Reading images from %s\n', seq_path);
    fprintf('start_idx: %d end_idx: %d n_frames: %d\n',...
        start_idx, end_idx, n_frames);
end

dres_image.x = zeros(n_frames, 1);
dres_image.y = zeros(n_frames, 1);
dres_image.w = zeros(n_frames, 1);
dres_image.h = zeros(n_frames, 1);
if store_gs
    dres_image.Igray = cell(n_frames, 1);
else
    if verbose
        fprintf('Not computing the grayscale images\n');
    end
end

if store_rgb
    dres_image.I = cell(n_frames, 1);
else
    if verbose
        fprintf('Discarding the RGB images\n');
    end
end
for frame_id = start_idx:end_idx
    filename = fullfile(seq_path, sprintf('image%06d.jpg', frame_id));
    I = imread(filename);
    
    id = frame_id - start_idx + 1 + storage_offset;

    dres_image.x(id) = 1;
    dres_image.y(id) = 1;
    dres_image.w(id) = size(I, 2);
    dres_image.h(id) = size(I, 1);
    if store_gs
        dres_image.Igray{id} = rgb2gray(I);
    end
    if store_rgb
        dres_image.I{id} = I;
    end
    
    if mod(id - storage_offset, 500) == 0
        fprintf('Done %d frames\n', id - storage_offset);
    end
end