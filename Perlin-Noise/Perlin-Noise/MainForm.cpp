#include "MainForm.h"
#include <Windows.h>
#include <iostream>
#include <opencv2/highgui/highgui.hpp>
//#include "thread_pool.hpp"
#include <random>
#include <vector>
#include <algorithm>
#include <Windows.h>

using namespace System;

using namespace System::Windows::Forms;


#define HASH_SIZE 256

typedef  double(__fastcall* PN)(double, double, unsigned char*, unsigned short);
typedef double(__fastcall* PNF)(double, double, double, unsigned char, unsigned char*, unsigned short);

[STAThread]
void main(array<String^>^ args)
{

    Application::EnableVisualStyles();

    Application::SetCompatibleTextRenderingDefault(false);

    HINSTANCE cppLib = LoadLibrary(TEXT("JACpp.dll"));
    HINSTANCE asmLib = LoadLibrary(TEXT("JAAsm.dll"));

    if (asmLib != NULL && cppLib != NULL)
    {
        unsigned char H_HASH[HASH_SIZE];
        std::mt19937 sudornd(1);
        for (int i = 0; i < HASH_SIZE; i++)
            H_HASH[i] = sudornd() % 256;

        PN asmFuncTest = (PN)GetProcAddress(asmLib, "perlinNoise");
        PNF FractalPerlinFunc = (PNF)GetProcAddress(cppLib, "fractalPerlinNoise");

        if (FractalPerlinFunc != NULL)
        {
            int height = 1000;
            int width = 1800;
           
            cv::Mat img(height, width, CV_8UC3, cv::Scalar(0, 128, 128));


            if (!img.empty())
            {
                std::string windowName = "Blank Image";


                for (int i = 0; i < height; ++i)
                {
                    for (int j = 0; j < width; ++j)
                    {
                        unsigned char val = 255 * (((FractalPerlinFunc)(i, j, 0.01, 7, H_HASH, HASH_SIZE) + 1) / 2.0);
                        cv::Vec3b color;
                        color.val[0] = val;
                        color.val[1] = val;
                        color.val[2] = val;
                        img.at<cv::Vec3b>(cv::Point(j, i)) = color;
                    }
                }

                cv::imshow(windowName, img);

                cv::waitKey(0);


                cv::destroyAllWindows();
            }
        }

        if (asmFuncTest != NULL)
        {
            asmFuncTest(0.5, 2.5, H_HASH, HASH_SIZE);
        }
    }
    

    /*PerlinNoise::MainForm form;

    Application::Run(% form);*/
    return;

}