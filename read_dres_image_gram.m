% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% build the dres structure for images in KITTI
function dres_image = read_dres_image_gram(opt, seq_name, seq_num)
disp(seq_num)
dres_image.x = zeros(seq_num, 1);
dres_image.y = zeros(seq_num, 1);
dres_image.w = zeros(seq_num, 1);
dres_image.h = zeros(seq_num, 1);
dres_image.I = cell(seq_num, 1);
dres_image.Igray = cell(seq_num, 1);

for id = 1:seq_num
    filename = fullfile(opt.gram, 'Images', seq_name, sprintf('image%06d.jpg', id));
    disp(filename);
    I = imread(filename);

    dres_image.x(id) = 1;
    dres_image.y(id) = 1;
    dres_image.w(id) = size(I, 2);
    dres_image.h(id) = size(I, 1);
    dres_image.I{id} = I;
    dres_image.Igray{id} = rgb2gray(I);
end