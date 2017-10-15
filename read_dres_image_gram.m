% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
function dres_image = read_dres_image_gram(db_path, seq_name,...
    start_idx, end_idx, storage_offset, store_rgb, store_gs, verbose)
addpath('./mexopencv-2.4.11/')
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
read_from_bin = 1;
n_frames = end_idx - start_idx + 1;
seq_path = fullfile(db_path, 'Images', seq_name);
if read_from_bin
    src_img_fname_bin = sprintf('%s_%d_%d.bin', seq_path, start_idx, end_idx);
    if exist(src_img_fname_bin, 'file') ~= 2
        fprintf('Binary image data file: %s does not exist\n',...
            src_img_fname_bin);
        fprintf('Reading from image files instead\n');
        read_from_bin = 0;
    end
end
if read_from_bin
    fprintf('Reading binary image data from: %s\n', src_img_fname_bin);
    img_data=dir(src_img_fname_bin);
    img_data_size=img_data.bytes;
    img_fid=fopen(src_img_fname_bin);
    img_width=fread(img_fid, 1, 'uint32', 'a');
    img_height=fread(img_fid, 1, 'uint32', 'a');
    no_of_frames = (img_data_size - 8)/(img_width*img_height);
    fprintf('no_of_frames: %d\n', no_of_frames);
    verbose = 0;
else
    if verbose
        fprintf('Reading images from %s\n', seq_path);
        fprintf('start_idx: %d end_idx: %d n_frames: %d\n',...
            start_idx, end_idx, n_frames);
    end
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
% figure;
for frame_id = start_idx:end_idx
    id = frame_id - start_idx + 1 + storage_offset;
    if read_from_bin
        dres_image.Igray{id}=uint8(fread(img_fid, [img_width img_height],...
            'uint8', 'a'))';
        % imshow(dres_image.Igray{id});
        % pause(0.1);
    else
        filename = fullfile(seq_path, sprintf('image%06d.jpg', frame_id));
        % I = cv.imread(filename);
        I = imread(filename);
        % imshow(I);
        if store_gs
            dres_image.Igray{id} = cv.cvtColor(I, 'BGR2GRAY');
            %dres_image.Igray{id} = rgb2gray_cv(I);
            % dres_image.Igray{id} = rgb2gray(I);
            % imshow(dres_image.Igray{id})
        end
        if store_rgb
            dres_image.I{id} = I;
        end
    end
    dres_image.x(id) = 1;
    dres_image.y(id) = 1;
    dres_image.w(id) = size(dres_image.Igray{id}, 2);
    dres_image.h(id) = size(dres_image.Igray{id}, 1);
    if mod(id - storage_offset, 500) == 0
        fprintf('Done %d frames\n', id - storage_offset);
    end
end
if read_from_bin
    fclose(img_fid);
end
