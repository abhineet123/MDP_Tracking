function compile2

include = ' -I/usr/local/include/opencv/ -I/usr/local/include/';
lib = ' -lopencv_core -lopencv_highgui -lopencv_imgproc -lopencv_video';
eval(['mex rgb2gray_cv.cc -O' include lib]);
eval(['mex imread_cv.cc -O' include lib]);

disp('Compilation finished.');