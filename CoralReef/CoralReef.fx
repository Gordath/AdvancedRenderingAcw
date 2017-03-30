#include "GlobalDeclarations.hlsl"
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
PS_OUTPUTWithDepth PSSeaFloorSeaSurfaceFog(VS_QUAD In)
{ 
	Camera cam;
	cam.position = float3(cos(g_fTime * 0.2) * 10.0, 0, sin(g_fTime * 0.2) * 10.0);
	cam.target = float3(0, 0, 0.0);
	cam.fov = 45.0;

	Ray eyeray = CreatePrimaryRay(cam, In.Position.xy, float2(WinWidth, WinHeight));

	PS_OUTPUTWithDepth Output;
	Output.RGBColor = RayMarching(eyeray, Output.depth);

	float2 p = (float2(WinWidth, WinHeight) - 2.0 * In.Position.xy) / WinHeight;

	float3 horizonColor = float3(0.0, 0.05, 0.2);

    // horizon fog
	//Output.RGBColor.rgb = lerp(Output.RGBColor.rgb, horizonColor, pow(1.0 - pow(eyeray.d.y, 2.0), 20.0));

    return Output;
}

PS_OUTPUT PSCausticsGodrays(VS_QUAD In)
{
	PS_OUTPUT Output;
	Output.RGBColor = float4(0.0, 0.0, 0.0, 1.0);

	float2 xy = 0.02 * In.TextureUV * float2(WinWidth, WinHeight);
	float distEye2Canvas = 0.0;
	float3 PixelPos = float3(xy, distEye2Canvas);
//___________________________________ //2. for each pixel location (x,y), fire a ray
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Ray eyeray;
	eyeray.o = E.xyz; //eye position specified in world space
	eyeray.d = normalize(PixelPos - E.xyz); //view direction in world space

	float2 p = (float2(WinWidth, WinHeight) - 2.0 * In.Position.xy) / WinHeight;

	float3 skyColor = float3(0.3, 1.0, 1.0);

	Output.RGBColor.rgb += ((0.3 * caustic(float2(p.x, -p.y * 1.0))) + (0.3 * caustic(float2(p.x, -p.y * 2.7)))) * pow(p.y, 4.0);
	Output.RGBColor.rgb += float3(0.7, 1.0, 1.0) * GodRays(p) * lerp(skyColor.x, 1.0, p.y * p.y);

	return Output;
}

//--------------------------------------------------------------------------------------
// Renders scene to render target using D3D11 Techniques
//--------------------------------------------------------------------------------------
technique11 RenderSceneWithTexture1Light
{
	pass P0
	{
		SetVertexShader(CompileShader(vs_5_0, RenderSceneVS()));
		SetPixelShader(CompileShader(ps_5_0, PSSeaFloorSeaSurfaceFog()));

		SetDepthStencilState(EnableDepth, 1);
	}

	/*pass P1
	{
		SetVertexShader(CompileShader(vs_5_0, RenderSceneVS()));
		SetPixelShader(CompileShader(ps_5_0, PSCausticsGodrays()));

		SetDepthStencilState(DisableDepth, 1);

		SetBlendState(AdditiveBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
	}*/
}
