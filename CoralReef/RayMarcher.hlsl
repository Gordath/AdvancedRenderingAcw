#ifndef RAY_MARCHER_HLSL_
#define RAY_MARCHER_HLSL_

#include "SimplexNoise.hlsl"
#include "PrimitiveDistanceFunctions.hlsl"
#include "DistanceOperations.hlsl"
#include "DomainOperations.hlsl"

#define MIN_XYZ -50.0
#define MAX_XYZ 50.0
const float3 BoxMinimum = (float3) MIN_XYZ;
const float3 BoxMaximum = (float3) MAX_XYZ;

#define INTERVALS 200
#define PI 3.14159265359	


bool IntersectBox(in Ray ray, in float3 minimum, in float3 maximum, out float timeIn, out float timeOut)
{
	float3 OMIN = (minimum - ray.o) / ray.d;
	float3 OMAX = (maximum - ray.o) / ray.d;
	float3 MAX = max(OMAX, OMIN);
	float3 MIN = min(OMAX, OMIN);
	timeOut = min(MAX.x, min(MAX.y, MAX.z));
	timeIn = max(max(MIN.x, 0.0), max(MIN.y, MIN.z));
	return timeOut > timeIn;
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

float SceneMap(float3 Position)
{
	return OperationUnion(SignedPlane(float3(Position.x , Position.y + noise(Position.xz) * 0.1, Position.z) + float3(0.0, 1.5, 0.0), float4(0.0, 1.0, 0.0, 0.0)),
							OperationIntersection(Function(Position + simplexNoise(float3(Position.yz, g_fTime)), 1.0), SignedSphere(Position + float3(0.0, -4.0, 0.0), 5.0)));
}

const float3 Zero = float3(0.0, 0.0, 0.0);
const float3 Unit = float3(1.0, 1.0, 1.0);
const float3 AxisX = float3(1.0, 0.0, 0.0);
const float3 AxisY = float3(0.0, 1.0, 0.0);
const float3 AxisZ = float3(0.0, 0.0, 1.0);

#define STEP 0.01

float3 CalcNormal(float3 Position)
{
	float A = SceneMap(Position + AxisX * STEP) - SceneMap(Position - AxisX * STEP);
	float B = SceneMap(Position + AxisY * STEP) - SceneMap(Position - AxisY * STEP);
	float C = SceneMap(Position + AxisZ * STEP) - SceneMap(Position - AxisZ * STEP);
	return normalize(float3(A, B, C));
}

bool RayMarchingInsideCube(in Ray ray, in float start, in float final, out float val)
{
	float step = (final - start) / float(INTERVALS);
	float time = start;
	float3 Position = ray.o + time * ray.d;
	float right, left = SceneMap(Position);
	for (int i = 0; i < INTERVALS; ++i)
	{
		time += step;
		Position += step * ray.d;
		right = SceneMap(Position);
		if (left * right < 0.0)
		{
			val = time + right * step / (left - right);
			return true;
		}
		left = right;
	}
	return false;
}

float4 Phong(float3 n, float3 l, float3 v, float shininess, float4 diffuseColor, float4 specularColor)
{
	float NdotL = dot(n, l);
	float diff = saturate(NdotL);
	float3 r = reflect(l, n);
	float spec = pow(saturate(dot(v, r)), shininess) * (NdotL > 0.0);
	return diff * diffuseColor + spec * specularColor;
}

float4 Shade(float3 hitPos, float3 normal, float3 viewDir, float lightIntensity)
{
	float3 lightDir = normalize(LightPos - hitPos);
	float4 diff = float4(0.8666666666666667, 0.5215686274509804, 0.3607843137254902, 1.0) * (1.0 - abs(noise(hitPos.xz)));
	float4 spec = float4(1.0, 1.0, 1.0, 1.0);
	return LightColor * lightIntensity * Phong(normal, lightDir, viewDir, 60.0, diff, spec);
}

float4 RayMarching(Ray ray)
{
	float4 result = (float4) 0.05;
	float start, final;
	float t;
	if (IntersectBox(ray, BoxMinimum, BoxMaximum, start, final))
	{
		if (RayMarchingInsideCube(ray, start, final, t))
		{
			float3 Position = ray.o + ray.d * t;
			float3 normal = CalcNormal(Position);
			float3 color = (Position - BoxMinimum) / (BoxMaximum - BoxMinimum);
			result = Shade(Position, normal, ray.d, 1.0);
		}
	}
	return result;
}

#endif //RAY_MARCHER_HLSL_