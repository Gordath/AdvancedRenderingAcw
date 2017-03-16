#include "SimplexNoise.hlsl"
#include "PrimitiveDistanceFunctions.hlsl"
#include "DistanceOperations.hlsl"
#include "DomainOperations.hlsl"

//--------------------------------------------------------------------------------------
// Global variables
//--------------------------------------------------------------------------------------
float4 g_MaterialAmbientColor;      // Material's ambient color
float4 g_MaterialDiffuseColor;      // Material's diffuse color

float    g_fTime;                   // App's time in seconds
float4x4 g_mWorld;                  // World matrix for object
float4x4 g_mWorldViewProjection;    // World * View * Projection matrix

//--------------------------------------------------------------------------------------
// DepthStates
//--------------------------------------------------------------------------------------
DepthStencilState EnableDepth
{
    DepthEnable = TRUE;
    DepthWriteMask = ALL;
    DepthFunc = LESS_EQUAL;
};

//--------------------------------------------------------------------------------------
// Texture samplers
//--------------------------------------------------------------------------------------
SamplerState MeshTextureSampler
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};

float4 E = float4(0, 0, 50, 1); //eye position
float nearPlane = 1.0;
float farPlane = 1000.0;
float4 LightColor = float4(1, 1, 1, 1);
float3 LightPos = float3(0, 100, 0);
float4 backgroundColor = float4(0.1, 0.2, 0.3, 1);

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


float SphereIntersect(Ray ray, out bool hit)
{
	float t;
	float3 v = -ray.o;
	float A = dot(v, ray.d);
	float B = dot(v, v) - A * A;
	float R = 5;
	if (B > R * R)
	{
		hit = false;
		t = farPlane;
	}
	else
	{
		float disc = sqrt(R * R - B);
		t = A - disc;
		if (t < 0.0)
		{
			hit = false;
		}
		else
			hit = true;
	}
	return t;
}

float4 RayCasting(VS_QUAD input)
{
//___________________________________
// 1. specify canvas size
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	float WinWidth = 800, WinHeight = 800;
	float2 xy = 0.02 * input.TextureUV * float2(WinWidth, WinHeight);
	float distEye2Canvas = 2.0;
	float3 PixelPos = float3(xy, distEye2Canvas);
//___________________________________ //2. for each pixel location (x,y), fire a ray
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Ray eyeray;
	eyeray.o = E.xyz; //eye position specified in world space
	eyeray.d = normalize(PixelPos - E.xyz); //view direction in world space
//___________________________________ //3. Calculate ray-sphere hit position
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	bool hit = false;
	float t = SphereIntersect(eyeray, hit);
	float3 interP = eyeray.o + t * normalize(eyeray.d);
//___________________________________ //4. Render
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	float4 RTColor = (float4) 0;
	if (!hit)
		RTColor = backgroundColor;
	else
	{
		float3 c = LightColor.rgb;
		float3 N = normalize(interP);
		N = normalize(N);
		float3 L = normalize(LightPos - interP);
		float3 V = normalize(E.xyz - interP);
		float3 R = reflect(-L, N);
		float r = max(dot(N, L), 0.2);
		r += 0.6 * pow(max(0.1, dot(R, V)), 50);
		RTColor = float4(r * c, 1.0);
	}
	return RTColor;
}

//--------------------------------------------------------------------------------------
// This shader computes standard transform and lighting
//--------------------------------------------------------------------------------------
VS_QUAD RenderSceneVS(float4 vPos : POSITION)
{
	VS_QUAD output;

	output.Position = float4(sign(vPos.xy), 0, 1);
	output.TextureUV = sign(vPos.xy);
    
    return output;    
}


//--------------------------------------------------------------------------------------
// Pixel shader output structure
//--------------------------------------------------------------------------------------
struct PS_OUTPUT
{
    float4 RGBColor : SV_Target;  // Pixel color
};


//--------------------------------------------------------------------------------------
// This shader outputs the pixel's color by modulating the texture's
//       color with diffuse material color
//--------------------------------------------------------------------------------------
PS_OUTPUT RenderScenePS(VS_QUAD In)
{ 
    PS_OUTPUT Output;

	Output.RGBColor = RayCasting(In);

    return Output;
}


//--------------------------------------------------------------------------------------
// Renders scene to render target using D3D11 Techniques
//--------------------------------------------------------------------------------------
technique11 RenderSceneWithTexture1Light
{
    pass P0
    {
        SetVertexShader( CompileShader( vs_5_0, RenderSceneVS() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_5_0, RenderScenePS() ) );

        SetDepthStencilState( EnableDepth, 0 );
    }
}


//TODO: Create DistanceDeformations.hlsl
//TODO: Create DomainDeformations.hlsl
