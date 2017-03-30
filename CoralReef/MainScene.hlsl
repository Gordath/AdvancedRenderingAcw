#ifndef MAIN_SCENE_HLSL_
#define MAIN_SCENE_HLSL_

#include "SimplexNoise.hlsl"
#include "PrimitiveDistanceFunctions.hlsl"
#include "DistanceOperations.hlsl"
#include "DomainOperations.hlsl"
#include "DomainDeformations.hlsl"
#include "DistanceDeformations.hlsl"

Material GetMaterial(float3 p)
{
	Material mat;

	mat.diffuse = float4(1.0, 1.0, 1.0, 1.0);
	mat.specular = float4(1.0, 1.0, 1.0, 1.0);
	mat.shininess = 1.0;

	if (p.y > 2.8)
	{
		mat.diffuse.rgb = float3(0.0, 0.08, 0.5) * (1.0 - abs(fbm2(p.xz, 4, 1)));
		mat.shininess = 30.0;
	}
	else
	{
		mat.diffuse.rgb = float3(0.8666666666666667, 0.5215686274509804, 0.3607843137254902) * (1.0 - abs(fbm2(p.xz, 4, 3)));
		mat.shininess = 128.0;
	}

	return mat;
}

float Function(float3 Position, float levelVal)
{
	float X = Position.x;
	float Y = Position.y;
	float Z = Position.z;
	float T = PI / 2.0;
	float Fun = 2.0 - cos(X + T * Y) - cos(X - T * Y) - cos(Y + T * Z) -
cos(Y - T * Z) - cos(Z - T * X) - cos(Z + T * X);
	return Fun - levelVal;
}

#define TAU 6.28318530718
#define MAX_ITER 5

float3 caustic(float2 uv)
{
	float2 p = (uv * TAU) % TAU - 250.0;
	float time = g_fTime * 0.5 + 23.0;

	float2 i = float2(p);
	float c = 1.0;
	float inten = .005;

	for (int n = 0; n < MAX_ITER; n++)
	{
		float t = time * (1.0 - (3.5 / float(n + 1)));
		i = p + float2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
		c += 1.0 / length(float2(p.x / (sin(i.x + t) / inten), p.y / (cos(i.y + t) / inten)));
	}
    
	c /= (float)MAX_ITER;
	c = 1.17 - pow(c, 1.4);
	float3 color = (float3)pow(abs(c), 8.0);
	color = clamp(color + float3(0.0, 0.35, 0.5), 0.0, 1.0);
	color = lerp(color, float3(1.0, 1.0, 1.0), 0.3);
    
	return color;
}

float causticX(float x, float power, float gtime)
{
	float p = (x * TAU) % TAU - 250.0;
	float time = gtime * .5 + 23.0;

	float i = p;
	float c = 1.0;
	float inten = 0.005;

	for (int n = 0; n < MAX_ITER / 2; n++)
	{
		float t = time * (1.0 - (3.5 / float(n + 1)));
		i = p + cos(t - i) + sin(t + i);
		c += 1.0 / length(p / (sin(i + t) / inten));
	}
	c /= float(MAX_ITER);
	c = 1.17 - pow(c, power);
    
	return c;
}

float GodRays(float2 uv)
{
	float light = 0.0;

	light += pow(causticX((uv.x + 0.08 * uv.y) / 1.7 + 0.5, 1.8, g_fTime * 0.65), 10.0) * 0.05;
	light -= pow((1.0 - uv.y) * 0.3, 2.0) * 0.2;
	light += pow(causticX(sin(uv.x), 0.3, g_fTime * 0.7), 9.0) * 0.4;
	light += pow(causticX(cos(uv.x * 2.3), 0.3, g_fTime * 1.3), 4.0) * 0.1;
        
	light -= pow((1.0 - uv.y) * 0.3, 3.0);
	light = clamp(light, 0.0, 1.0);
    
	return light;
}

float SeaFloor(float3 p)
{
	return SignedPlane(float3(p.x, p.y + fbm2(p.xz, 4, 0.2) * 0.08, p.z) + float3(0.0, 2.5, 0.0),
						float4(0.0, 1.0, 0.0, 0.0));
}

float Sea(float3 p)
{
	return SignedPlane(float3(p.x, p.y + fbm3(float3(p.xz, g_fTime), 3, 0.5) * 0.1, p.z) + float3(0.0, -3.0, 0.0),
						float4(0.0, -1.0, 0.0, 0.0));
}

float Coral(float3 p, float scale)
{
	return SignedTorus(OperationTwist(p / scale, radians(180.0) + fbm3(float3(p.xy, 10.0), 4, 4.0)), float2(1.0, 1.1)) * scale;
	//return SignedCappedCylinder(p / scale, float2(0.3, 1.0)) * scale;
}

float SceneMap(float3 p)
{
	float res = OperationUnion(SeaFloor(p), Sea(p));
	res = OperationUnion(res, Coral(p + float3(0.0, 0.0, 0.0), 0.5));
	return res;
}

#endif //MAIN_SCENE_HLSL_
