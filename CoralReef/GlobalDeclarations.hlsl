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

float4 LightColor = float4(1, 1, 1, 1);
float3 LightPos = float3(0, 1, -10);

float WinWidth;
float WinHeight;

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
	float4 RGBColor : SV_Target;
};

struct PS_OUTPUTWithDepth
{
	float4 RGBColor : SV_Target; // Pixel color
	float depth : SV_Depth;
};

struct Material
{
	float4 diffuse;
	float4 specular;
	float shininess;
};

struct Camera
{
	float3 position;
	float3 target;
	float fov;
};

DepthStencilState EnableDepth
{
	DepthEnable = TRUE;
	DepthWriteMask = ALL;
	DepthFunc = LESS_EQUAL;
};

DepthStencilState DisableDepth
{
	DepthEnable = FALSE;
	DepthWriteMask = ZERO;
	DepthFunc = LESS_EQUAL;
};

BlendState NoBlend
{
	AlphaToCoverageEnable = FALSE;
	BlendEnable[0] = FALSE;
};

BlendState AdditiveBlend
{
	BlendEnable[0] = TRUE;
	SrcBlend = ONE;
	DestBlend = ONE;
	BlendOp = ADD;
};

#endif //GLOBAL_DECLARATIONS_HLSL_
