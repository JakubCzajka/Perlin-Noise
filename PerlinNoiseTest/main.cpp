#include <iostream>
#include <opencv2/highgui/highgui.hpp>
#include "perlin.hpp"
#include "thread_pool.hpp"
#include <random>
#include <vector>
#include <algorithm>
#include <Windows.h>

#define HASH_SIZE 256

typedef double(__cdecl* DLLPerlinFunc)(double, double, double, unsigned char, unsigned char*, unsigned short);
typedef  double(__fastcall* interpolateDll)(double, double, double);
typedef  void(__fastcall* randomGradientDll)(int, int, unsigned char*, unsigned short);
typedef  void(__fastcall* Prelindll)(double, double, unsigned char*, unsigned short);

int main()
{

    HINSTANCE hinstLib = LoadLibrary(TEXT("PerlinNoiseTestDLLcpp.dll"));
    HINSTANCE hinstAsmLib = LoadLibrary(TEXT("Dll1.dll"));
    unsigned char H_HASH[HASH_SIZE];
    std::mt19937 sudornd(1);
    for (int i = 0; i < HASH_SIZE; i++)
        H_HASH[i] = sudornd() % 256;
    if (hinstAsmLib == NULL)
        std::cout << "Niedll\n";
    if (hinstLib != NULL)
    {

        interpolateDll IntF = (interpolateDll)GetProcAddress(hinstAsmLib, "interpolate");
        Prelindll PerlinF = (Prelindll)GetProcAddress(hinstAsmLib, "perlinNoise");
        DLLPerlinFunc FractalPerlinFunc = (DLLPerlinFunc)GetProcAddress(hinstLib, "fractalPerlinNoise");
        randomGradientDll rgF = (randomGradientDll)GetProcAddress(hinstAsmLib, "randomGradient");
        rgF(1, 1, H_HASH, HASH_SIZE);
        //auto x = FractalPerlinFunc(1, 1, 0.01, 1, H_HASH, HASH_SIZE);


PerlinF(0.5, 2.5, H_HASH, HASH_SIZE);
        /*std::function<void()> binded = //std::bind(IntF, )
            [IntF]()->void {
            HINSTANCE hinstAsmLib = LoadLibrary(TEXT("Dll1.dll"));
            interpolateDll IntF = (interpolateDll)GetProcAddress(hinstAsmLib, "interpolate");
            IntF(3.0, 4.0, 0.6);
        };*/

        /* Thread_pool tp0(1);
         Thread_pool tp1(1);
         tp0.AddJobABCS(binded);
         tp0.WaitForAllJobs();
         tp1.AddJobABCS(binded);
         tp1.WaitForAllJobs();*/

         /*IntF(3.0, 4.0, 0.6);
         IntF(3.0, 4.0, 0.6);*/


         //interpolateDll AsmF = (interpolateDll)GetProcAddress(hinstAsmLib, "interpolate");
         //if (AsmF == NULL)
         //{
         //    std::cout << "Nie pyklo\n";
         //}
         //    
         //else
         //{
         //    double w;
         //    std::cin >> w;
         //    std::cout << AsmF(9.8463, 5.20009, w) << "\n";
         //    std::cout << interpolate(9.8463, 5.20009, w) << "\n";
         //    std::cout << 3 % 2 << "\n";
         //    std::cout << -3 % 2 << "\n";
         //    std::cout << 3 % -2 << "\n";
         //    std::cout << -3 % -2 << "\n";
         //}
         //    
         //if (FractalPerlinFunc != NULL)
         //{
        int height = 1000;
        int width = 1800;
        unsigned char H_HASH[HASH_SIZE];
        std::mt19937 sudornd(1);
        for (int i = 0; i < HASH_SIZE; i++)
            H_HASH[i] = sudornd() % 256;
        cv::Mat img(height, width, CV_8UC3, cv::Scalar(0, 128, 128));

        //    std::vector<double> test;

        if (!img.empty())
        {
            std::string windowName = "Blank Image";


            for (int i = 0; i < height; ++i)
            {
                for (int j = 0; j < width; ++j)
                {
                    unsigned char val = 255 * (((FractalPerlinFunc)(i, j, 0.01, 7, H_HASH, HASH_SIZE) + 1) / 2.0);
                    //                //test.push_back(perlinNoise(i * 0.01, j * 0.01, H_HASH, HASH_SIZE));
                    //                //test.push_back(fractalPerlinNoise(i, j, 0.01, 1, H_HASH, HASH_SIZE));
                    cv::Vec3b color;
                    color.val[0] = val;
                    color.val[1] = val;
                    color.val[2] = val;
                    img.at<cv::Vec3b>(cv::Point(j, i)) = color;
                }
            }
            //       // std::sort(test.begin(), test.end());
            //       // std::cout << test.front() << "    " << test.back() << "\n";


            cv::imshow(windowName, img);

                    cv::waitKey(0);


            cv::destroyAllWindows();
            return 0;

            //    }
            //}
            //else
            //{
            //    std::cout << "Function not found.\n";
            //}



     }
        else
        {
            std::cout << "DLL not found.\n";
        }
        return 0;
    }
}