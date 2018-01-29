function show_dres_gt(frame_id, I, dres, colors_rgb,...
    box_line_width, traj_line_width, obj_id_font_size, det_color)

if nargin<5
    box_line_width = 1;
end
if nargin<6
    traj_line_width = 1;
end
if nargin<7
    obj_id_font_size = 6;
end
if nargin<8
    det_color = [0, 0, 0];
end
imshow(I);
hold on;

n_cols = length(colors_rgb);

if isempty(dres) == 1
    index = [];
else
    index = find(dres.fr == frame_id);
end
s = '-';
for i = 1:numel(index)
    set(gca,'position',[0 0 1 1],'units','normalized');
    ind = index(i);
    x = dres.x(ind);
    y = dres.y(ind);
    w = dres.w(ind);
    h = dres.h(ind);
    if isfield(dres, 'id') && dres.id(ind) > 0
        id = dres.id(ind);
        col_id = mod(id - 1, n_cols) + 1;
        c = colors_rgb{col_id};
        str = sprintf('%d', id);
    else
        c = det_color;
        str = '';
    end
    rectangle('Position', [x y w h], 'EdgeColor', c,...
        'LineWidth', box_line_width, 'LineStyle', s);
    if ~isempty(str)
        text(x, y-size(I,1)*0.01, str, 'BackgroundColor', [.7 .9 .7],...
            'FontSize', obj_id_font_size);
    end
    if isfield(dres, 'id') && dres.id(ind) > 0
        % show the previous path
        ind = find(dres.id == id & dres.fr <= frame_id);
        centers = [dres.x(ind)+dres.w(ind)/2, dres.y(ind)+dres.h(ind)];
        patchline(centers(:,1), centers(:,2), 'LineWidth',...
            traj_line_width, 'edgecolor', c, 'edgealpha', 0.3);
    end
end
hold off;