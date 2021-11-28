#pragma once

extern "C" double fractalPerlinNoise(double pointX, double pointY, double frequency, unsigned short hashTableSize, unsigned char* hashTable, unsigned char numberOfOctaves);
extern "C" double perlinNoise(double pointX, double pointY, unsigned char* hashTable, unsigned short hashTableSize);