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


function bb = bb_shift_relative(bb,shift)
% Change

if isempty(bb)
    return;
end
% annoying bug - evidently the authors did not realize that computing 
% width and height from 'bb' after having already shifted bb(1,:)
% and bb(3,:) would cause the other two rows to be messed up

shift_x = bb_width(bb)*shift(1);
shift_y = bb_height(bb)*shift(2);

bb(1,:) = bb(1,:) + shift_x;
bb(2,:) = bb(2,:) + shift_y;
bb(3,:) = bb(3,:) + shift_x;
bb(4,:) = bb(4,:) + shift_y;