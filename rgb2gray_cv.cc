#include <opencv2/imgproc/imgproc.hpp>
#include <mex.h>

#define _A3D_IDX_COLUMN_MAJOR(i,j,k,nrows,ncols) ((i)+((j)+(k)*ncols)*nrows)
// interleaved row-major indexing for 2-D OpenCV images
//#define _A3D_IDX_OPENCV(x,y,c,mat) (((y)*mat.step[0]) + ((x)*mat.step[1]) + (c))
#define _A3D_IDX_OPENCV(i,j,k,nrows,ncols,nchannels) (((i*ncols + j)*nchannels) + (k))

using namespace std;
/**
* Copy the (image) data from Matlab-algorithm compatible (column-major) representation to cv::Mat.
* The information about the image are taken from the OpenCV cv::Mat structure.
adapted from OpenCV-Matlab package available at: https://se.mathworks.com/matlabcentral/fileexchange/41530-opencv-matlab
*/
template <typename T>
inline void
copyMatrixFromMatlab(const T* from, cv::Mat& to, int n_channels){

	const int n_rows = to.rows;
	const int n_cols = to.cols;

	T* pdata = (T*)to.data;

	for(int c = 0; c < n_channels; ++c){
		for(int x = 0; x < n_cols; ++x){
			for(int y = 0; y < n_rows; ++y){
				const T element = from[_A3D_IDX_COLUMN_MAJOR(y, x, c, n_rows, n_cols)];
				pdata[_A3D_IDX_OPENCV(y, x, c, rows, n_cols, n_channels)] = element;
			}
		}
	}
}
/**
 * Copy the (image) data from cv::Mat to a Matlab-algorithm compatible (column-major) representation.
 * The information about the image are taken from the OpenCV cv::Mat structure.
 */
template <typename T>
inline void
copyMatrixToMatlab(const cv::Mat& from, T* to)
{
	assert(from.dims == 2); // =2 <=> 2-D image

	const int rows=from.rows;
	const int cols=from.cols;
	const T* pdata = (T*)from.data;

	for (int x = 0; x < cols; x++){
		for (int y = 0; y < rows; y++){
			//const T element = pdata[_A3D_IDX_OPENCV(x,y,c,from)];
			const T element = pdata[_A3D_IDX_OPENCV(y,x,0,rows,cols,1)];
			to[_A3D_IDX_COLUMN_MAJOR(y,x,0,rows,cols)] = element;
		}
	}
}
cv::Mat getImage(const mxArray *mx_img){
	int img_n_dims = mxGetNumberOfDimensions(mx_img);
	if(!mxIsClass(mx_img, "uint8")){
		mexErrMsgTxt("Input image must be of 8 bit unsigned integral type");
	}
	if(img_n_dims < 2 || img_n_dims > 3){
		mexErrMsgTxt("Input image must have 2 or 3 dimensions");
	}
	int img_type = img_n_dims == 2 ? CV_8UC1 : CV_8UC3;
	const mwSize *img_dims = mxGetDimensions(mx_img);
	int height = img_dims[0];
	int width = img_dims[1];
	//printf("width: %d\t height=%d\t img_n_dims: %d\n", width, height, img_n_dims);
	unsigned char *img_ptr = (unsigned char*)mxGetData(mx_img);
	cv::Mat img(height, width, img_type);
	if(img_n_dims == 2){
		cv::Mat img_transpose(width, height, img_type, img_ptr);
		cv::transpose(img_transpose, img);
	} else{
		copyMatrixFromMatlab(img_ptr, img, 3);
	}
	return img;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){	
	if(nrhs < 1){
		mexErrMsgTxt("Not enough input arguments.");
	}
	cv::Mat frame_raw = getImage(prhs[0]);
	int dims[2];
	dims[0] = frame_raw.rows;
	dims[1] = frame_raw.cols;	
	plhs[0] = mxCreateNumericArray (2, dims, mxUINT8_CLASS, mxREAL);	
	// cv::Mat frame_gs(frame_raw.rows, frame_raw.cols, CV_8UC1, mxGetPr(plhs[0]));
	cv::Mat frame_gs(frame_raw.rows, frame_raw.cols, CV_8UC1);
	// cv::Mat frame_mat(frame_raw.rows, frame_raw.cols, CV_8UC1, mxGetPr(plhs[0]));
	cv::cvtColor(frame_raw, frame_gs, CV_BGR2GRAY);
	// cv::transpose(frame_gs, frame_mat);
	copyMatrixToMatlab<unsigned char>(frame_gs, (unsigned char*)(mxGetPr(plhs[0])));
}
