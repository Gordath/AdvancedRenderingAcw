#ifndef GLOBAL_DECLARATIONS_HLSL_
#define GLOBAL_DECLARATIONS_HLSL_

//--------------------------------------------------------------------------------------
// Global variables
//--------------------------------------------------------------------------------------
float4 g_MaterialAmbientColor; // Material's ambient color
float4 g_MaterialDiffuseColor; // Material's diffuse color

float g_fTime; // App's time in seconds
float4x4 g_mWorld; // World matrix for object
float4x4 g_mWorldViewProjection; // World * View * Projection matrix

float4 E = float4(0, 0, 50, 1); //eye position
float nearPlane = 1.0;
float farPlane = 1000.0;
float4 LightColor = float4(1, 1, 1, 1);
float3 LightPos = float3(0, 100, 100);
float4 backgroundColor = float4(0.1, 0.2, 0.3, 1);

#define PI 3.14159265359	

struct Ray
{
	float3 o; // origin
	float3 d; // direction
};

//--------------------------------------------------------------------------------------
// Vertex shader output structure
//--------------------------------------------------------------------------------------
struct VS_QUAD
{
	float4 Position : SV_POSITION; // vertex position
	float2 TextureUV : TEXCOORD0; // vertex texture coords
};

//--------------------------------------------------------------------------------------
// Pixel shader output structure
//--------------------------------------------------------------------------------------
struct PS_OUTPUT
{
	float4 RGBColor : SV_Target; // Pixel color
};

#endif //GLOBAL_DECLARATIONS_HLSL_
