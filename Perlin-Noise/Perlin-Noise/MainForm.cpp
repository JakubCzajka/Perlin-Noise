#include "MainForm.h"
#include <Windows.h>
#include <iostream>
#include <opencv2/highgui/highgui.hpp>
//#include "thread_pool.hpp"
#include <random>
#include <vector>
#include <algorithm>
#include <Windows.h>
#include <chrono>

using namespace System;

using namespace System::Windows::Forms;


#define HASH_SIZE 256

typedef  double(__fastcall* PN)(double, double, unsigned char*, unsigned short);
typedef double(__fastcall* PNF)(double, double, double, unsigned short, unsigned char*, unsigned char);

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
            //H_HASH[i] = 0xAA;

        PNF asmFuncTest = (PNF)GetProcAddress(asmLib, "fractalPerlinNoise");
        PNF cppFuncTest = (PNF)GetProcAddress(cppLib, "fractalPerlinNoise");


        if (asmFuncTest != NULL && cppFuncTest != NULL)
        {
            // double fractalPerlinNoise(double pointX, double pointY, double frequency, unsigned short hashTableSize, unsigned char* hashTable, unsigned char numberOfOctaves);
            //double a = cppFuncTest(-1.5, 2.5, 0.01, HASH_SIZE, H_HASH, 3);
            //;double fractalPerlinNoise(double pointX, double pointY, double frequency, unsigned short hashTableSize, unsigned char* hashTable, unsigned char numberOfOctaves)
            //double b = asmFuncTest(-1.5, 2.5, 0.01, HASH_SIZE, H_HASH, 3); 


            int height = 900;
            int width = 1500;

            cv::Mat img(height, width, CV_8UC3, cv::Scalar(0, 128, 128));

            if (!img.empty())
            {
                std::string windowName = "Blank Image";
                auto begin = std::chrono::high_resolution_clock::now();

                
                for (int i = 0; i < height; ++i)
                {
                    for (int j = 0; j < width; ++j)
                    {
                        unsigned char val = 255 * ((cppFuncTest(i, j, 0.01, HASH_SIZE, H_HASH, 7) + 1) / 2.0);
                        cv::Vec3b color;
                        color.val[0] = val;
                        color.val[1] = val;
                        color.val[2] = val;
                        img.at<cv::Vec3b>(cv::Point(j, i)) = color;
                    }
                }
                auto end = std::chrono::high_resolution_clock::now();
                auto cpp = std::chrono::duration_cast<std::chrono::nanoseconds>(end - begin).count();


                cv::imshow(windowName, img);
                cv::waitKey(0);
                cv::destroyAllWindows();

                auto beginAsm = std::chrono::high_resolution_clock::now();
                for (int i = 0; i < height; ++i)
                {
                    for (int j = 0; j < width; ++j)
                    {
                        unsigned char val = 255 * ((asmFuncTest(i, j, 0.01, HASH_SIZE, H_HASH, 7) + 1) / 2.0);
                        cv::Vec3b color;
                        color.val[0] = val;
                        color.val[1] = val;
                        color.val[2] = val;
                        img.at<cv::Vec3b>(cv::Point(j, i)) = color;
                        if (j == width - 1)
                            continue;
                    }
                    if (i == height - 1)
                        continue;
                }
                auto endAsm = std::chrono::high_resolution_clock::now();
                auto timeAsm = std::chrono::duration_cast<std::chrono::nanoseconds>(endAsm - beginAsm).count();
                Console.WriteLine()
                cv::imshow(windowName, img);
                cv::waitKey(0);
                cv::destroyAllWindows();
            }
          

        }
    }
    

    /*PerlinNoise::MainForm form;

    Application::Run(% form);*/
    return;

}