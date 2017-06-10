function show_dres_gt(frame_id, I, dres, colors_rgb)

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
         c = [0, 0, 0];
         str = '';
    end
    rectangle('Position', [x y w h], 'EdgeColor', c, 'LineWidth', 4, 'LineStyle', s);
    if ~isempty(str)
        text(x, y-size(I,1)*0.01, str, 'BackgroundColor', [.7 .9 .7], 'FontSize', 14); 
    end
    if isfield(dres, 'id') && dres.id(ind) > 0
        % show the previous path
        ind = find(dres.id == id & dres.fr <= frame_id);
        centers = [dres.x(ind)+dres.w(ind)/2, dres.y(ind)+dres.h(ind)];
        patchline(centers(:,1), centers(:,2), 'LineWidth', 4, 'edgecolor', c, 'edgealpha', 0.3);
    end
end
hold off;