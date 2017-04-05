#ifndef MAIN_SCENE_HLSL_
#define MAIN_SCENE_HLSL_

#include "GlobalDeclarations.hlsl"
#include "Noise.hlsl"
#include "PrimitiveDistanceFunctions.hlsl"
#include "DistanceOperations.hlsl"
#include "DomainOperations.hlsl"
#include "DomainDeformations.hlsl"
#include "DistanceDeformations.hlsl"
#include "Materials.hlsl"

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

Material GetMaterial(float3 p, int materialId)
{
    Material mat;

    mat.diffuse = float4(1.0, 1.0, 1.0, 1.0);
    mat.specular = float4(1.0, 1.0, 1.0, 1.0);
    mat.shininess = 1.0;
    mat.roughness = 1.0;
    mat.fresnelBias = 1.0;
    mat.fresnelPower = 1.0;
    mat.ior = 0.0;

    if (materialId == MATERIAL_SEA_SURFACE)
    {
        mat.diffuse.rgb = seaSurfaceColour * (1.0 - abs(fbm2(p.xz, 2, 1)));
        mat.shininess = 30.0;
    }
    else if (materialId == MATERIAL_SEA_FLOOR)
    {
        mat.diffuse.rgb = seaFloorColour * (1.0 - abs(fbm2(p.xz, 4, 3)));
        mat.shininess = 128.0;
        mat.specular *= 0.1;
    }
    else if (materialId == MATERIAL_SEA_WEED)
    {
        mat.diffuse.rgb = seaWeedColour * (abs(fbm2(p.xz, 4, 1)));
        mat.shininess = 128.0;
    }
    else if (materialId == MATERIAL_CORAL)
    {
        mat.diffuse.rgb = coralColour;
        mat.shininess = 128.0;
        mat.roughness = 1.0;
    }
    else if (materialId == MATERIAL_BUBBLE)
    {
        mat.diffuse.rgb = bubbleColour;
        mat.shininess = 30.0;
        mat.roughness = 0.0;
        mat.fresnelBias = 0.5;
        mat.fresnelPower = 3.0;
        mat.ior = 1.0;
    }

    return mat;
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

// Scalar derivative approach by Enforcer:
// http://www.fractalforums.com/mandelbulb-implementation/realtime-renderingoptimisations/
void powN(float p, inout float3 z, float zr0, inout float dr)
{
    float zo0 = asin(z.z / zr0);
    float zi0 = atan2(z.x, z.y); //watch this order
    float zr = pow(zr0, p - 1.0);
    float zo = zo0 * p;
    float zi = zi0 * p;
    float czo = cos(zo);

    dr = zr * dr * p + 1.0;
    zr *= zr0;

    z = zr * float3(czo * cos(zi), czo * sin(zi), sin(zo));
}



// The fractal calculation
//
// Calculate the closest distance to the fractal boundary and use this
// distance as the size of the step to take in the ray marching.
//
// Fractal formula:
//    z' = z^p + c
//
// For each iteration we also calculate the derivative so we can estimate
// the distance to the nearest point in the fractal set, which then sets the
// maxiumum step we can move the ray forward before having to repeat the calculation.
//
//   dz' = p * z^(p-1)
//
// The distance estimation is then calculated with:
//
//   0.5 * |z| * log(|z|) / |dz|
//
#define bailout 4.0
//static const float juliaFactor = 0.0; // {"label":"Juliabulb factor", "min":0, "max":1, "step":0.01, "default":0, "group":"Fractal", "group_label":"Additional parameters"}
//static const float radiolariaFactor = 0.0; // {"label":"Radiolaria factor", "min":-2, "max":2, "step":0.1, "default":0, "group":"Fractal"}
//static const float radiolaria = 0.0; // {"label":"Radiolaria", "min":0, "max":1, "step":0.01, "default": 0, "group":"Fractal"}
//static const float3 offset = float3(0.0, 0.0, 0.0);

float3 Mandelbulb(float3 w, float power, int maxIterations, float juliaFactor, float radiolariaFactor, float radiolaria, float3 offset)
{   
    float3 z = w;
    float3 c = lerp(w, offset, juliaFactor);
    float3 d = w;
    float dr = 1.0;
    float r = length(z);
    float md = 10000.0;
    
    for (int i = 0; i < maxIterations; i++)
    {
        powN(power, z, r, dr);
        
        z += c;
            
        if (z.y > radiolariaFactor)
        {
            z.y = lerp(z.y, radiolariaFactor, radiolaria);
        }
        
        r = length(z);
        
        if (r > bailout)
            break;
    }

    return float3(0.5 * log(r) * r / dr, md, 0.33 * log(dot(d, d)) + 1.0);
}

float Coral(float3 p)
{
    float val = lerp(6, 8, cos(g_fTime) * 0.5 + 0.5);
    return Mandelbulb(p, val, 8, 0.0, 0.0, 0.0, (float3) 0.0);
}

float Seaweed(float3 p)
{
    return SignedCappedCylinder(p + fbm3(p, 4, 2.3) * 0.1, float2(0.035, 2.0));
}

float SceneMap(float3 p, out int materialId)
{
	float res = SeaFloor(p);
    materialId = MATERIAL_SEA_FLOOR;
    res = OperationUnion(res, materialId, Sea(p), MATERIAL_SEA_SURFACE, materialId);
    res = OperationUnion(res, materialId, Coral(float3(p.x, p.y + 1.5, p.z)), MATERIAL_CORAL, materialId);

    float frequency = 2.5;
    float amplitude = 0.1;
    float speed = 1.0;
    float3 tilledP = OperationRepetition(float3(p.x + cos(g_fTime * speed + p.y * frequency) * amplitude, p.y + 1.0, p.z), float3(4.0, 0.0, 4.0), bool3(true, false, true));
    res = OperationUnion(res, materialId, Seaweed(tilledP), MATERIAL_SEA_WEED, materialId);

    frequency = 16.0;
    amplitude = 0.03;
    speed = 6.0;
    float3 tmpP = float3(p.x + 2.0 + sin(g_fTime * speed + p.y * frequency) * amplitude, p.y - (g_fTime * 0.2 - 1.0) % 6 + 3.0, p.z);
    res = OperationUnion(res, materialId, SignedSphere(tmpP, 0.3), MATERIAL_BUBBLE, materialId);

    frequency = 16.0;
    amplitude = 0.03;
    speed = 4.0;
    tmpP = float3(p.x + sin(g_fTime * speed + p.y * frequency) * amplitude, p.y - (g_fTime * 0.2) % 6 + 3.0, p.z + 3.0);
    res = OperationUnion(res, materialId, SignedSphere(tmpP, 0.3), MATERIAL_BUBBLE, materialId);

    frequency = 16.0;
    amplitude = 0.03;
    speed = 6.0;
    tmpP = float3(p.x + 2.0 + sin(g_fTime * speed + p.y * frequency) * amplitude, p.y - (g_fTime * 0.2 - 1.0) % 6 + 3.0, p.z - 3.0);
    res = OperationUnion(res, materialId, SignedSphere(tmpP, 0.3), MATERIAL_BUBBLE, materialId);

    frequency = 16.0;
    amplitude = 0.03;
    speed = 4.0;
    tmpP = float3(p.x - 4.0 + sin(g_fTime * speed + p.y * frequency) * amplitude, p.y - (g_fTime * 0.2 - 3.0) % 6 + 3.0, p.z + 4.0);
    res = OperationUnion(res, materialId, SignedSphere(tmpP, 0.3), MATERIAL_BUBBLE, materialId);

    frequency = 16.0;
    amplitude = 0.03;
    speed = 6.0;
    tmpP = float3(p.x + 3.0 + sin(g_fTime * speed + p.y * frequency) * amplitude, p.y - (g_fTime * 0.2 - 1.0) % 6 + 3.0, p.z + 1.5);
    res = OperationUnion(res, materialId, SignedSphere(tmpP, 0.3), MATERIAL_BUBBLE, materialId);

    frequency = 16.0;
    amplitude = 0.03;
    speed = 4.0;
    tmpP = float3(p.x + sin(g_fTime * speed + p.y * frequency) * amplitude, p.y - (g_fTime * 0.2 - 2.0) % 6 + 3.0, p.z + 3.0);
    res = OperationUnion(res, materialId, SignedSphere(tmpP, 0.3), MATERIAL_BUBBLE, materialId);

    return res;
}

#endif //MAIN_SCENE_HLSL_
