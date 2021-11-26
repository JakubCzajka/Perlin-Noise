#include "MainForm.h"
#include <Windows.h>
#include <iostream>

using namespace System;

using namespace System::Windows::Forms;

//[STAThread]

typedef int(__fastcall* Myproc)(int, int);
typedef  double(__fastcall* interpolateDll)(double, double, double);

void main(array<String^>^ args)
{

    Application::EnableVisualStyles();

    Application::SetCompatibleTextRenderingDefault(false);

    HINSTANCE CppLib = LoadLibrary(TEXT("JACpp.dll"));
    HINSTANCE AsmLib = LoadLibrary(TEXT("JAAsm.dll"));

    Myproc func;

    int a;
    double b;
    if (CppLib != NULL)
    {
        func = (Myproc)GetProcAddress(CppLib, "MyProc");
        if (func != NULL)
        {
            a = func(1, 2);
          //  std::cout << "a\n";
           // throw "a";
        }

    }
    if (AsmLib != NULL)
    {
        interpolateDll funci = (interpolateDll)GetProcAddress(AsmLib, "interpolate");
        if (funci != NULL)
        {
            b = funci(3.0, 4.0, 0.5);
       // std::cout << "a\n";
        //throw "a";
    }
    }

    /*PerlinNoise::MainForm form;

    Application::Run(% form);*/

}