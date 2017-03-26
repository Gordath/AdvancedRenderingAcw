#ifndef MAIN_SCENE_HLSL_
#define MAIN_SCENE_HLSL_

#include "SimplexNoise.hlsl"
#include "PrimitiveDistanceFunctions.hlsl"
#include "DistanceOperations.hlsl"
#include "DomainOperations.hlsl"
#include "DomainDeformations.hlsl"
#include "DistanceDeformations.hlsl"

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

float SeaFloor(float3 p)
{
	return SignedPlane(float3(p.x, p.y + fbm2(p.xz, 3, 0.1) * 0.2, p.z) + float3(0.0, 1.5, 0.0),
						float4(0.0, 1.0, 0.0, 0.0));
}

float Sea(float3 p)
{
	return SignedPlane(float3(p.x, p.y + fbm3(float3(p.xz, g_fTime), 3, 0.5) * 0.1, p.z) + float3(0.0, -5.5, 0.0),
						float4(0.0, -1.0, 0.0, 0.0));
}

float SceneMap(float3 p)
{
	float res = OperationUnion(SeaFloor(p), Sea(p));
	return res;
}

#endif //MAIN_SCENE_HLSL_
