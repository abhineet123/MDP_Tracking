function I = im_crop(img, bb)
% Extract the patch from the given image corresponding to the given bounding box after constraining it to lie within image extents;
% this patch is then assigned to a new image which again has the same dimensions as the bounding box but the location within this new image where the patch is assigned does not seem to be quite as simple as one might imagine;
% the coordinates of the top left corner off the bonding box is simply subtracted from the coordinates at which the image batch is extracted from within the given image since the same values are subtracted from both the top left and the bottom right corners of this new image coordinates the overall size remains the same;
% does not quite clear why the subtraction is being done;
% if the top left corner of the bonding box is greater than one then the top left corner of the old image from where the batch was extracted will be same as top left corner of the bonding box so subtracting it will just make it zero and then the add one so that's perfectly fine and yeah in that case the bottom right also make sense;
% but if this top left corner of the given bonding box is less than one then asked one would be one and subtracting a negative number for instance if this top left corner of BB is negative and subtracting a negative number makes it the positive number that then we are moving it away from the top left corner off the new image in which case you the whole batch the location of this extracted batch within the new image will be shifted by the same amount as the negative magnitude of top left corner of the given bonding box;
% it is not quite clear how such a thing is going to work but I imagine that Matt left can dynamically resize matrices so this will probably not really create an error it will just extend the original image matrix which has the same size as the bonding box to be larger than the size so that dispatch pixels can be placed at these shifted locations;
w = bb_width(bb);
h = bb_height(bb);
I = uint8(zeros(h, w));

x1 = max([1 bb(1)]);
y1 = max([1 bb(2)]);
x2 = min([size(img,2) bb(3)]);
y2 = min([size(img,1) bb(4)]);
patch = img(y1:y2, x1:x2);

x1 = x1-bb(1)+1;
y1 = y1-bb(2)+1;
x2 = x2-bb(1)+1;
y2 = y2-bb(2)+1;
I(y1:y2, x1:x2) = patch;