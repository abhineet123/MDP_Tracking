% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% read GRAM file for frame IDs within the given limits
function dres = read_gram2dres(filename, start_idx, end_idx)

fid = fopen(filename, 'r');
% <frame>, <id>, <bb_left>, <bb_top>, <bb_width>, <bb_height>, <conf>, <x>, <y>, <z>
C = textscan(fid, '%d %d %f %f %f %f %f %f %f %f', 'Delimiter', ',');
fclose(fid);

% build the dres structure for detections
dres.fr = C{1}(start_idx:end_idx);
dres.id = C{2}(start_idx:end_idx);
dres.x = C{3}(start_idx:end_idx);
dres.y = C{4}(start_idx:end_idx);
dres.w = C{5}(start_idx:end_idx);
dres.h = C{6}(start_idx:end_idx);
dres.r = C{7}(start_idx:end_idx);