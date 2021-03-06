#ifndef RAY_MARCHER_HLSL_
#define RAY_MARCHER_HLSL_

#include "MainScene.hlsl"

#define INTERVALS 512
#define MIN_DIST 0
#define MAX_DIST 20
#define EPSILON 0.005

float3 CalcNormal(float3 Position)
{
    int materialId;
	float2 e = float2(1.0, -1.0) * 0.5773 * 0.0005;
	return normalize(e.xyy * SceneMap(Position + e.xyy, materialId).x +
					  e.yyx * SceneMap(Position + e.yyx, materialId).x +
					  e.yxy * SceneMap(Position + e.yxy, materialId).x +
					  e.xxx * SceneMap(Position + e.xxx, materialId).x);
}

bool RayMarch(in Ray ray, in float start, in float final, out float val, out int materialId)
{
	float depth = start;
	for (int i = 0; i < INTERVALS; i++)
	{
		float3 p = ray.o + depth * ray.d;
		float dist = SceneMap(p, materialId);
		if (dist < EPSILON)
		{
			val = depth;
			return true;
		}
		depth += dist * 0.9;
		if (depth >= final)
		{
			val = final;
			break;
		}
	}

	val = final;
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

Ray GetReflectedRay(float3 p, float3 rayDir, float3 n)
{
    Ray r;
    r.o = p;
    r.d = normalize(reflect(rayDir, n));

    return r;
}

float GetFresnelTerm(float3 camPos, float3 normal, Material mat)
{
    float fresnelScale = 1.0 - mat.fresnelBias;
    return mat.fresnelBias + fresnelScale * pow(saturate(1.0 + dot(camPos, normal)), mat.fresnelPower);
}

float4 Shade(float3 hitPos, float3 normal, float3 viewDir, float lightIntensity, int materialId)
{
	float3 lightDir = normalize(LightPos - hitPos);

	Material mat = GetMaterial(hitPos, materialId);
    float fresnelTerm = GetFresnelTerm(viewDir, normal, mat);

    float4 res = LightColor * lightIntensity * Phong(normal, lightDir, viewDir, mat.shininess, mat.diffuse, mat.specular);

    //caustics only on the sea floor
    if (materialId == MATERIAL_SEA_FLOOR)
    {
        res.rgb += 0.3 * caustic(float2(hitPos.x, hitPos.z));
    }

    //reflection
    float reflectivity = 1.0 - mat.roughness;
	if (reflectivity > 0)
    {
        Ray ray = GetReflectedRay(hitPos, viewDir, normal);
        ray.o += ray.d * EPSILON; //advance 1 step to avoid finding an intersection with the same object.
        float t = 0.0;
        int mId = -1;
        if (RayMarch(ray, MIN_DIST, MAX_DIST, t, mId))
        {
            float3 p = ray.o + t * ray.d;
            Material reflMat = GetMaterial(p, mId);
            float4 reflColor = LightColor * lightIntensity * Phong(CalcNormal(p), normalize(LightPos - p), ray.d, reflMat.shininess, reflMat.diffuse, reflMat.specular);
            res = res * mat.roughness + reflColor * fresnelTerm * reflectivity;
        }
        else
        {
            res = res * mat.roughness + float4(0.0, 0.05, 0.2, 1.0) * fresnelTerm * reflectivity;
        }
    }

    //refraction
    if (mat.ior > 0.0)
    {
        //ray that enters the object
        Ray refrRay;
        refrRay.d = refract(viewDir, normal, mat.ior);
        refrRay.o = hitPos;
        refrRay.o += normalize(refrRay.d);
        
        float t = 0.0;
        int mId = -1;
        if (RayMarch(refrRay, MIN_DIST, MAX_DIST, t, mId))
        {
            float3 p = refrRay.o + t * refrRay.d;
            float3 n = CalcNormal(p);

            //ray that exits the object
            Ray refrRay2; 
            refrRay2.d = refract(refrRay.d, n, 1.33 / mat.ior);
            refrRay2.o = p;
            refrRay2.o += refrRay2.d * EPSILON;
            if (RayMarch(refrRay2, MIN_DIST, MAX_DIST, t, mId))
            {
                float3 p = refrRay2.o + t * refrRay2.d;
                float3 n = CalcNormal(p);
                Material m = GetMaterial(p, mId);

                float4 refrColor = LightColor * lightIntensity * Phong(n, normalize(LightPos - p), refrRay2.d, m.shininess, m.diffuse, m.specular);
                res += refrColor + float4(0.0, 0.05, 0.2, 0.0); //maybe use an exponent for the blue tint colour.
            }
        }
    }

	return res;
}

float4 GetRayColour(Ray ray, out float depth)
{
	float4 result = float4(0.0, 0.05, 0.2, 1.0);
	float start, final;
	float t;

	depth = 1.0;

    int materialId = -1;
	if (RayMarch(ray, MIN_DIST, MAX_DIST, t, materialId))
	{
		float3 Position = ray.o + ray.d * t;
		float3 normal = CalcNormal(Position);
		//float3 color = (Position - BoxMinimum) / (BoxMaximum - BoxMinimum);
		float far = MAX_DIST;
		float near = MIN_DIST;
			//result = float4(normalize(Position), 1.0);
		result = Shade(Position, normal, ray.d, 1.0, materialId);

		float fogAmount = 1.0 - exp(-t * 0.2);
		result.rgb = lerp(result.rgb, float3(0.0, 0.05, 0.2), fogAmount);

        depth = -(ray.o - t * ray.d).z / (far * 0.2);
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
	ray.d.z = 1.0 / tan(cam.fov * 0.5);

	ray.d = normalize(ray.d);

	float4x4 viewMat = LookAtLH(cam, float3(0.0, 1.0, 0.0));

	float3x3 rotOnly = (float3x3) viewMat;

	ray.d = mul(ray.d, rotOnly);
	ray.o = mul(float4(ray.o, 1.0), viewMat).xyz;

	return ray;
}

#endif //RAY_MARCHER_HLSL_