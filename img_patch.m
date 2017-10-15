% Copyright 2011 Zdenek Kalal
%
% This file is part of TLD.
% 
% TLD is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% TLD is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with TLD.  If not, see <http://www.gnu.org/licenses/>.


function patch_uint8 = img_patch(img, bb, pause_for_debug,...
    randomize, p_par)
if nargin < 3
    pause_for_debug = 0;
end
if nargin == 5 && randomize > 0
    
    rand('state',randomize);
    randn('state',randomize);
    
    NOISE = p_par.noise;
    ANGLE = p_par.angle;
    SCALE = p_par.scale;
    SHIFT = p_par.shift;
    
    cp  = bb_center(bb)-1;
    Sh1 = [1 0 -cp(1); 0 1 -cp(2); 0 0 1];
    
    sca = 1-SCALE*(rand-0.5);
    Sca = diag([sca sca 1]);
    
    ang = 2*pi/360*ANGLE*(rand-0.5);
    ca = cos(ang);
    sa = sin(ang);
    Ang = [ca, -sa; sa, ca];
    Ang(end+1,end+1) = 1;
    
    shR  = SHIFT*bb_height(bb)*(rand-0.5);
    shC  = SHIFT*bb_width(bb)*(rand-0.5);
    Sh2 = [1 0 shC; 0 1 shR; 0 0 1];
    
    bbW = bb_width(bb)-1;
    bbH = bb_height(bb)-1;
    box = [-bbW/2 bbW/2 -bbH/2 bbH/2];
    
    H     = Sh2*Ang*Sca*Sh1;
    bbsize = bb_size(bb);
    patch_uint8 = uint8(warp(img,inv(H),box) + NOISE*randn(bbsize(1),bbsize(2)));
    
    
else
    
    % All coordinates are integers
    if isempty(find((round(bb)-bb) ~= 0, 1)) == 1
        % yet another annoying horrible bug - the locations in ground truth
        % are alwys 0-based while Matlab indexing is 1-based so we should
        % be adding 1 to the locations before using them for indexing
        L = max([1 bb(1) + 1]);
        T = max([1 bb(2) + 1]);
        R = min([size(img,2) bb(3) + 1]);
        B = min([size(img,1) bb(4) + 1]);
        patch_uint8 = img(T:B,L:R);
        if pause_for_debug
            debugging=1;
        end

        % Sub-pixel accuracy
    else
        
        cp = 0.5 * [bb(1)+bb(3); bb(2)+bb(4)]-1;
        H = [1 0 -cp(1); 0 1 -cp(2); 0 0 1];
        H_inv = inv(H);
        
        bbW = bb(3,:)-bb(1,:)+1;
        bbH = bb(4,:)-bb(2,:)+1;
        if bbW <= 0 || bbH <= 0
            patch_uint8 = [];
            return;
        end
        box = [-bbW/2 bbW/2 -bbH/2 bbH/2];
        
        if size(img,3) == 3
            for i = 1:3
                patch = warp(img(:,:,i),H_inv, box);
                patch_uint8(:,:,i) = uint8(patch);
            end
        else
            patch = warp(img,H_inv,box);
            patch_uint8 = uint8(patch);
%             if pause_for_debug
%                 entries = {
%                     {patch, 'patch', 'float32',  '%.10f'},...
%                     {patch_uint8, 'patch_uint8', 'uint8', '%d'},...
%                     };
%                 writeToFiles('log', 0, entries);
%             end
        end
        if pause_for_debug
            debugging=1;
        end
    end
    if pause_for_debug
        debugging=1;
    end
end