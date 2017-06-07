% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% build the dres structure for images in KITTI
function dres_image = read_dres_image_stanford(opt, scene, seq_id)
file_path = fullfile(opt.stanford, 'videos', scene, sprintf('video%d', seq_id), 'video.mov');
seq_num = 0;
video = VideoReader(file_path);
while hasFrame(video)
    I = readFrame(video);
    seq_num = seq_num + 1;
end
dres_image.x = zeros(seq_num, 1);
dres_image.y = zeros(seq_num, 1);
dres_image.w = zeros(seq_num, 1);
dres_image.h = zeros(seq_num, 1);
dres_image.I = cell(seq_num, 1);
dres_image.Igray = cell(seq_num, 1);
video = VideoReader(file_path);
id = 1;
while hasFrame(video)
    I = readFrame(video);
    dres_image.x(id) = 1;
    dres_image.y(id) = 1;
    dres_image.w(id) = size(I, 2);
    dres_image.h(id) = size(I, 1);
    dres_image.I{id} = I;
    dres_image.Igray{id} = rgb2gray(I);
    id = id + 1;
end