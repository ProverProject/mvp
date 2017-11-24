#pragma once


#include <opencv2/opencv.hpp>
#include <vector>
#include <cmath>
#include <ctime>
#include <cstdlib>
#include <cstring>
//#include <iostream>
#include "opencv2/core/ocl.hpp"




class SwypeDetect
{
public:
	
	SwypeDetect();
	~SwypeDetect();
	
	void init(int fps_e, std::string swype);
	void setSwype(std::string swype);
	void processFrame(cv::Mat frame, int &state, int &index, int &x, int &y, int &debug);
	void processFrame(const unsigned char *frame_i, int width_i, int height_i, int &state, int &index, int &x, int &y, int &debug);
	void Reset(void);

private:
	
	//External data
	std::vector<int> swype_Numbers; 
	int fps;
	
	//Internal data
	cv::UMat frame1; //previous frame
	std::vector<cv::Point2d> Delta; //������������ ������ ����������� ������
	
	int S; //������� ���� �������������
	int call; //����������� ������� ������� ��������� ������
	int count_num; //����������� ��������� ��������� �����-����
	std::vector<int> Swype_Numbers_Get; //�������� ����� ���������
	std::vector<cv::Point2d> Swype_Koord; //���������� ���������� ���������
	std::vector<int> DirectionS; //������ �����������
	
	cv::Point2d D_coord;
	int Direction;
	bool fl_dir;

	std::vector<cv::Point2d> koord_Sw_points;
	cv::UMat buf1ft;
	cv::UMat buf2ft;
	cv::UMat hann;
	
	int CircleDetection(void);
	std::vector<cv::Point2d> Koord_Swipe_Points(int width, int height);
	void Delta_Calculation(cv::Point2d output);
	void Swype_Data(std::vector<cv::Point2d>& koord);
	cv::Point2d Frame_processor(cv::Mat &frame_i);
	void S1_processor(void);
	std::vector<double> S_L_define(cv::Point2d a, cv::Point2d b);
};

