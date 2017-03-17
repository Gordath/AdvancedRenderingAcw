#include "GlobalDeclarations.hlsl"
#include "SimplexNoise.hlsl"
#include "PrimitiveDistanceFunctions.hlsl"
#include "DistanceOperations.hlsl"
#include "DomainOperations.hlsl"
#include "RayMarcher.hlsl"


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
// This shader outputs the pixel's color by modulating the texture's
//       color with diffuse material color
//--------------------------------------------------------------------------------------
PS_OUTPUT RenderScenePS(VS_QUAD In)
{ 
	float WinWidth = 800, WinHeight = 600;
	float2 xy = 0.02 * In.TextureUV * float2(WinWidth, WinHeight);
	float distEye2Canvas = 2.0;
	float3 PixelPos = float3(xy, distEye2Canvas);
//___________________________________ //2. for each pixel location (x,y), fire a ray
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Ray eyeray;
	eyeray.o = E.xyz; //eye position specified in world space
	eyeray.d = normalize(PixelPos - E.xyz); //view direction in world space

    PS_OUTPUT Output;
	Output.RGBColor = RayMarching(eyeray);

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
        SetPixelShader( CompileShader( ps_5_0, RenderScenePS() ) );
    }
}


//TODO: Create DistanceDeformations.hlsl
//TODO: Create DomainDeformations.hlsl
