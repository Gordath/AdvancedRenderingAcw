#ifndef RAY_MARCHER_HLSL_
#define RAY_MARCHER_HLSL_

#include "MainScene.hlsl"

#define MIN_XYZ -100.0
#define MAX_XYZ 100.0
const float3 BoxMinimum = (float3) MIN_XYZ;
const float3 BoxMaximum = (float3) MAX_XYZ;

#define INTERVALS 200	

float ToRad(float degrees)
{
	return degrees * PI / 180.0;
}

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

const float3 Zero = float3(0.0, 0.0, 0.0);
const float3 Unit = float3(1.0, 1.0, 1.0);
const float3 AxisX = float3(1.0, 0.0, 0.0);
const float3 AxisY = float3(0.0, 1.0, 0.0);
const float3 AxisZ = float3(0.0, 0.0, 1.0);

#define STEP 0.01

float3 CalcNormal(float3 Position)
{
	float2 e = float2(1.0, -1.0) * 0.5773 * 0.0005;
	return normalize(e.xyy * SceneMap(Position + e.xyy).x +
					  e.yyx * SceneMap(Position + e.yyx).x +
					  e.yxy * SceneMap(Position + e.yxy).x +
					  e.xxx * SceneMap(Position + e.xxx).x);
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

	Material mat = GetMaterial(hitPos);
	
	return LightColor * lightIntensity * Phong(normal, lightDir, viewDir, mat.shininess, mat.diffuse, mat.specular);
}

float4 RayMarching(Ray ray, out float depth)
{
	float4 result = float4(0.0, 0.0, 0.0, 1.0);
	float start, final;
	float t;

	depth = 1.0;

	if (IntersectBox(ray, BoxMinimum, BoxMaximum, start, final))
	{
		if (RayMarchingInsideCube(ray, start, final, t))
		{
			float3 Position = ray.o + ray.d * t;
			float3 normal = CalcNormal(Position);
			float3 color = (Position - BoxMinimum) / (BoxMaximum - BoxMinimum);
			float far = 200.0;
			float near = 0.1;
			//result = float4(normalize(Position), 1.0);
			result = Shade(Position, normal, ray.d, 1.0);

			float a = far / (far - near);
			float b = 2.0 * far * near / (far - near);
			depth = saturate((a + b) / Position.z);
		}
	}

	return result;
}

float4x4 LookAtLH(Camera cam, float3 up)
{
	float3 f = normalize(cam.target - cam.position);
	float3 r = normalize(cross(up, f));
	float3 u = normalize(cross(f, r));
	float4x4 rot = float4x4(float4(r, 0.0), 
							float4(u, 0.0), 
							float4(f, 0.0),
							float4(0.0, 0.0, 0.0, 1.0));
	
	float4x4 trans = float4x4(float4(1.0, 0.0, 0.0, 0.0),
							  float4(0.0, 1.0, 0.0, 0.0),
							  float4(0.0, 0.0, 1.0, 0.0),
							  float4(cam.position.x, cam.position.y, cam.position.z, 1.0));

	return mul(rot, trans);
}

Ray CreatePrimaryRay(Camera cam, float2 fragCoord, float2 resolution)
{
	float aspect = resolution.x / resolution.y;

	Ray ray;
	ray.o = float3(0.0, 0.0, 0.0);
	ray.d.x = (2.0f * fragCoord.x / resolution.x - 1.0f) * aspect;
	ray.d.y = 1.0 - 2.0 * fragCoord.y / resolution.y;
	ray.d.z = 1.0 / tan(cam.fov / 2.0);

	ray.d = normalize(ray.d);

	float4x4 viewMat = LookAtLH(cam, float3(0.0, 1.0, 0.0));

	float3x3 rotOnly = (float3x3) viewMat;

	ray.d = mul(ray.d, rotOnly);
	ray.o = mul(float4(ray.o, 1.0), viewMat).xyz;

	return ray;
}

#endif //RAY_MARCHER_HLSL_