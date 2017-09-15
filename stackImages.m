function stacked_img = stackImages(img_list, stack_order)
if nargin<2
    stack_order = 0;
end
n_images = length(img_list);
img_size = size(img_list{1});
grid_size = ceil(sqrt(n_images));
stacked_img = '';
list_ended = 0;
inner_axis = 1 - stack_order;
img_id = 1;
for row_id = 1 : grid_size
    curr_row = '';
    for col_id = 1 : grid_size
        if img_id > n_images
            curr_img = zeros(img_size);
            list_ended = 1;
        else
            curr_img = img_list{img_id};
            if img_id == n_images
                list_ended = 1;
            end
        end
        if isempty(curr_row)
            curr_row = curr_img;
        else
            curr_row = cat(inner_axis + 1, curr_row, curr_img);
        end
        img_id = img_id + 1;
    end
    if isempty(stacked_img)
        stacked_img = curr_row;
    else
        stacked_img = cat(stack_order + 1, stacked_img, curr_row);
    end
    if list_ended
        break;
    end
end
end