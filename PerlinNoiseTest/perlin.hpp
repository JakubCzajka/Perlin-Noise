#include <math.h>

double interpolate(double firstValue, double secondValue, double weight)
{
	return (secondValue - firstValue) * weight + firstValue; // ((weight * (weight * 6.0 - 15.0) + 10.0) * weight * weight * weight) + firstValue;
}

void randomGradient(int x, int y, unsigned char* hashTable, unsigned short hashTableSize, double* gradientVectorX, double* gradientVectorY)
{
	int yIndex = y % hashTableSize;
	if (yIndex < 0)
		yIndex += hashTableSize;
	int xIndex = (hashTable[yIndex] + x) % hashTableSize;
	if(xIndex < 0)
		xIndex += hashTableSize;

	double gradientX;
	double gradientY;
	if (hashTable[xIndex] % 4 == 0)
	{
		gradientX = -1.0;
		gradientY = -1.0;
	}
	if (hashTable[xIndex] % 4 == 1)
	{
		gradientX = -1.0;
		gradientY = 1.0;
	}
	if (hashTable[xIndex] % 4 == 2)
	{
		gradientX = 1.0;
		gradientY = -1.0;
	}
	if (hashTable[xIndex] % 4 == 3)
	{
		gradientX = 1.0;
		gradientY = 1.0;
	}
	

	*gradientVectorX = gradientX;
	*gradientVectorY = gradientY;

	//const unsigned w = 8 * sizeof(unsigned);
	//const unsigned s = w / 2; // rotation width
	//unsigned a = x, b = y;
	//a *= 3284157443; b ^= a << s | a >> w - s;
	//b *= 1911520717; a ^= b << s | b >> w - s;
	//a *= 2048419325;
	//float random = a * (3.14159265 / ~(~0u >> 1)); // in [0, 2*Pi]
	//*gradientVectorX = sin(random); 
	//*gradientVectorY = cos(random);
}

double dotGridGradient(int gridX, int gridY, double pointX, double pointY, unsigned char* hashTable, unsigned short hashTableSize)
{
	double gradientX, gradientY;
	//get the gradient vector
	randomGradient(gridX, gridY, hashTable, hashTableSize, &gradientX, &gradientY);

	//calculate offset form grid point
	double dx = pointX - (double)gridX;
	double dy = pointY - (double)gridY;

	//return dot product
	return (dx * gradientX + dy * gradientY);
}

double perlinNoise(double pointX, double pointY, unsigned char* hashTable, unsigned short hashTableSize)
{
	//grid cell coordinates
	int x0 = std::floor(pointX);
	int x1 = x0 + 1;
	int y0 = std::floor(pointY);
	int y1 = y0 + 1;

	//calculate interpolation weights
	double wieightX = pointX - (double)x0;
	double wieightY = pointY - (double)y0;

	//interpolation along the x-axis
	double firstDotProduct = dotGridGradient(x0, y0, pointX, pointY, hashTable, hashTableSize);
	double secondDotProduct = dotGridGradient(x1, y0, pointX, pointY, hashTable, hashTableSize);

	double firstInterpolatedValueX = interpolate(firstDotProduct, secondDotProduct, wieightX);

	double thirdDotProduct = dotGridGradient(x0, y1, pointX, pointY, hashTable, hashTableSize);
	double fourthDotProduct = dotGridGradient(x1, y1, pointX, pointY, hashTable, hashTableSize);

	double secondInterpolatedValueX = interpolate(thirdDotProduct, fourthDotProduct, wieightX);

	//returning interpolation along the y-axis
	return interpolate(firstInterpolatedValueX, secondInterpolatedValueX, wieightY);
}

double fractalPerlinNoise(double pointX, double pointY, double frequency, unsigned char numberOfOctaves, unsigned char* hashTable, unsigned short hashTableSize)
{
	double amplitude = 1.0;
	double sum = 0.0;
	double sumOfAmplitudes = 0.0;
	for (int i = 0; i < numberOfOctaves; ++i)
	{
		sumOfAmplitudes += amplitude;
		sum += perlinNoise(pointX * frequency, pointY * frequency, hashTable, hashTableSize) * amplitude;
		amplitude /= 2.0;
		frequency *= 2.0;
	}

	return sum / sumOfAmplitudes;
}