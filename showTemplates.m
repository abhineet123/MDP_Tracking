function showTemplates( images, boxes, show_stacked )
if nargin<3
    show_stacked = 1;
end
n_images = length(images);
grid_size = ceil(sqrt(n_images));
drawn_images = cell(n_images, 1);
figure;
for i=1:n_images
    box = boxes{i};
    w = box(3) - box(1) + 1;
    h = box(4) - box(2) + 1;
    if show_stacked        
        rectangle = int32([box(1) box(2) w h]);
        shapeInserter = vision.ShapeInserter;
        drawn_img = step(shapeInserter, images{i}, rectangle);
        drawn_images{i} = drawn_img;
    else
        subplot(grid_size, grid_size, i);
        imshow(images{i}), hold on;
        rectangle('Position', [box(1) box(2) w h], 'EdgeColor', [0, 0, 0],...
            'LineWidth', 1, 'LineStyle', '-');        
    end
end
if show_stacked
    stacked_img = stackImages(drawn_images);
    imshow(stacked_img);
end
    
    
