#ifndef SIMPLEX_NOISE_HLSL_
#define SIMPLEX_NOISE_HLSL_

#include "SimplexNoise2D.hlsl"
#include "SimplexNoise3D.hlsl"
#include "SimplexNoise4D.hlsl"

float fbm2(float2 input, int octaves, float scale)
{
	float factor = 0.0;

	for (int i = 0; i < octaves; i++)
	{
		factor += snoise(input * scale) / scale;
		scale *= 2.0;
	}

	return factor;
}

float fbm3(float3 input, int octaves, float scale)
{
	float factor = 0.0;

	for (int i = 0; i < octaves; i++)
	{
		factor += snoise(input * scale) / scale;
		scale *= 2.0;
	}

	return factor;
}

#endif //SIMPLEX_NOISE_HLSL_
