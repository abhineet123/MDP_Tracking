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
dres_all.fr = C{1};
dres_all.id = C{2};
dres_all.x = C{3};
dres_all.y = C{4};
dres_all.w = C{5};
dres_all.h = C{6};
dres_all.r = C{7};

index = find((dres_all.fr >= start_idx) & (dres_all.fr <= end_idx));
dres = sub(dres_all, index);

% dres.fr=[];
% dres.id=[];
% dres.x=[];
% dres.y=[];
% dres.w=[];
% dres.h=[];
% dres.r=[];
% n_entries = numel(fr);
% for i= 1:n_entries
%     if fr(i) >= start_idx && fr(i) <= end_idx
%         dres.fr(end + 1) = fr(i);
%         dres.id(end + 1) = id(i);
%         dres.x(end + 1) = x(i);
%         dres.y(end + 1) = y(i);
%         dres.w(end + 1) = w(i);   
%         dres.h(end + 1) = h(i);   
%         dres.r(end + 1) = r(i);   
%     end
% end


    