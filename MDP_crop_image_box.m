% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% add cropped image and box to dres
function dres = MDP_crop_image_box(dres, I, tracker, figure_ids, colors_rgb)
% call LK_crop_image_box for each object in dres

show_figs = 0;
% line_width = 1;
% line_style = '-';
% obj_id_font_size = 6;

% if nargin<4
%     figure_ids = [];
% end
% if nargin<5
%     colors_rgb = {};
% end
% 
% if ~isempty(figure_ids) && ~isempty(colors_rgb)
%     show_figs = 1;
% end

num = numel(dres.fr);

% if show_figs
%     n_cols = numel(colors_rgb);
%     figure(figure_ids(1));
%     set(figure_ids(1),'Name', sprintf('Original Image with %d boxes', num),...
%         'NumberTitle','off');
%     imshow(I);
%     hold on;
%     for i = 1:num        
%         col_id = mod(i - 1, n_cols) + 1;
%         line_col = colors_rgb{col_id};
%         
%         x = dres.x(i);
%         y = dres.y(i);
%         w = dres.w(i);
%         h = dres.h(i);
%         rectangle('Position', [x y w h], 'EdgeColor', line_col,...
%             'LineWidth', line_width, 'LineStyle', line_style);
%         text(x, y-size(I,1)*0.01, sprintf('%d', i),...
%             'BackgroundColor', [.7 .9 .7], 'FontSize', obj_id_font_size);
%     end
%     hold off;
%     
%     figure(figure_ids(2));
%     set(figure_ids(2),'Name', sprintf('Cropped Images'),...
%         'NumberTitle','off');
%     pcols = ceil(sqrt(num));
%     prows = ceil(double(num) / double(pcols));
% end

dres.I_crop = cell(num, 1);
dres.BB_crop = cell(num, 1);
dres.bb_crop = cell(num, 1);
dres.scale = cell(num, 1);

for i = 1:num
    % yet another of the countless instances of the horribly annoying and
    % insidious bug where the -1 is simply ignored
    BB = [dres.x(i); dres.y(i); dres.x(i) + dres.w(i) - 1; dres.y(i) + dres.h(i) - 1];
    [I_crop, BB_crop, bb_crop, s] = LK_crop_image_box(I, BB, tracker);  
  
    dres.I_crop{i} = I_crop;
    dres.BB_crop{i} = BB_crop;
    dres.bb_crop{i} = bb_crop;
    dres.scale{i} = s;
    
    if tracker.pause_for_debug 
        debugging=1;
    end 
    
    % if show_figs
    %     subplot(prows, pcols,i);
    %     % figure(figure_ids(2));
    %     % set(figure_ids(2),'Name', sprintf('Cropped Image %d', i),...
    %     %   'NumberTitle','off');
    %     imshow(I_crop);
    %     hold on;
    %     x = BB_crop(1);
    %     y = BB_crop(2);
    %     w = BB_crop(3) - x;
    %     h = BB_crop(4) - y;
    %     col_id = mod(i - 1, n_cols) + 1;
    %     line_col = colors_rgb{col_id};
    %     rectangle('Position', [x y w h], 'EdgeColor', line_col,...
    %         'LineWidth', line_width, 'LineStyle', line_style);
    %     text(x, y-size(I_crop,1)*0.01, sprintf('%d', i),...
    %         'BackgroundColor', [.7 .9 .7], 'FontSize', obj_id_font_size);
    %     hold off;
    %     % pause(0.75);
    %     % k = waitforbuttonpress;
    % end
end
% if show_figs
%     pause(0.75);
% end