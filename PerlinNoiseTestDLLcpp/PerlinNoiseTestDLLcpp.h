#pragma once


extern "C" __declspec(dllexport) double fractalPerlinNoise(double pointX, double pointY, double frequency, unsigned char numberOfOctaves, unsigned char* hashTable, unsigned int hashTableSize)