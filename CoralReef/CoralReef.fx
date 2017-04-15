#include "RayMarcher.hlsl"


//--------------------------------------------------------------------------------------
// This shader computes standard transform and lighting
//--------------------------------------------------------------------------------------
VS_QUAD RenderSceneVSRayMarch(float4 vPos : POSITION,
                         float3 vNormal : NORMAL,
                         float2 vTexCoord0 : TEXCOORD)
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
	cam.position = float3(cos(g_fTime * 0.2) * 6.0, 0, sin(g_fTime * 0.2) * 6.0);
    //cam.position = float3(0.0, 0.0, -6.0);
	cam.target = float3(0, 0, 0.0);
	cam.fov = 45.0;

	Ray eyeray = CreatePrimaryRay(cam, In.Position.xy, float2(WinWidth, WinHeight));

	PS_OUTPUTWithDepth Output;
	Output.RGBColor = GetRayColour(eyeray, Output.depth);

    return Output;
}

PS_OUTPUT PSCausticsGodrays(VS_QUAD In)
{
	PS_OUTPUT Output;
	Output.RGBColor = float4(0.0, 0.0, 0.0, 1.0);

	float2 p = (float2(WinWidth, WinHeight) - 2.0 * In.Position.xy) / WinHeight;

	float3 skyColor = float3(0.3, 1.0, 1.0);

	Output.RGBColor.rgb += ((0.3 * caustic(float2(p.x, -p.y * 1.0))) + (0.3 * caustic(float2(p.x, -p.y * 2.7)))) * pow(p.y, 4.0);
	Output.RGBColor.rgb += float3(0.7, 1.0, 1.0) * GodRays(p) * lerp(skyColor.x, 1.0, p.y * p.y);

	return Output;
}

//--------------------------------------------------------------------------------------
// This shader computes standard transform and lighting
//--------------------------------------------------------------------------------------
VS_OUTPUT RenderSceneVSExplicit(float4 vPos : POSITION,
                         float3 vNormal : NORMAL,
                         float2 vTexCoord0 : TEXCOORD,
                          uniform float3 offset,
                          uniform float3 scale)
{
    VS_OUTPUT Output;
    
    float frequency = 400.0;
    float amplitude = 1.2;

    float4 dPos = vPos;

    dPos.x *= clamp(cos(vPos.x + vPos.y * frequency) * vPos.y * 10.0, 0.3, 1.0);
    dPos.y *= 3.0;

    dPos.xyz += offset;
    dPos.xyz *= scale;

    // Transform the position from object space to homogeneous projection space
    Output.Position = mul(dPos, MVP);

    // Transform the normal from object space to world space    
    float3 vNormalWorldSpace = normalize(mul(vNormal, (float3x3) M)); // normal (world space)
    
    // Compute simple directional lighting equation
    float3 vTotalLightDiffuse = float3(0, 0, 0);
    
    vTotalLightDiffuse += max(0, dot(vNormalWorldSpace, normalize(LightPos)));
        
    Output.Diffuse.rgb = float3(1.0, 0.0, 1.0) * abs(fbm3(float3(vTexCoord0 ,g_fTime * 0.05), 4, 6.0)) * vTotalLightDiffuse;
    Output.Diffuse.a = 1.0f;
    
    Output.TextureUV = vTexCoord0;
    
    return Output;
}

PS_OUTPUT RenderScenePSExplicit(VS_OUTPUT In)
{
    PS_OUTPUT output;

    output.RGBColor.rgb = In.Diffuse.rgb;
    output.RGBColor.a = 1.0;

    return output;
}

technique11 CoralReef
{
	pass P0
	{
        SetVertexShader(CompileShader(vs_5_0, RenderSceneVSRayMarch()));
		SetPixelShader(CompileShader(ps_5_0, PSSeaFloorSeaSurfaceFog()));

		SetDepthStencilState(EnableDepth, 0);
	}

    /* P1
    {
        SetVertexShader(CompileShader(vs_5_0, RenderSceneVSExplicit(float3(0.5 + 2.0, -3.0, 5.0), float3(1.0, 1.0, 1.0))));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, RenderScenePSExplicit()));

        SetDepthStencilState(EnableDepth, 0);
        SetBlendState(NoBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
    }

    pass P2
    {
        SetVertexShader(CompileShader(vs_5_0, RenderSceneVSExplicit(float3(-0.5 + 2.0, -3.0, 5.0), float3(1.0, 1.0, 1.0))));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, RenderScenePSExplicit()));

        SetDepthStencilState(EnableDepth, 0);
        SetBlendState(NoBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
    }

    pass P3
    {
        SetVertexShader(CompileShader(vs_5_0, RenderSceneVSExplicit(float3(2.0 + (-0.25), -3.0, 5.0), float3(1.0, 1.0, 1.0))));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, RenderScenePSExplicit()));

        SetDepthStencilState(EnableDepth, 0);
        SetBlendState(NoBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
    }

    pass P4
    {
        SetVertexShader(CompileShader(vs_5_0, RenderSceneVSExplicit(float3(2.0 + 0.25, -3.0, 5.0), float3(1.0, 1.0, 1.0))));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, RenderScenePSExplicit()));

        SetDepthStencilState(EnableDepth, 0);
        SetBlendState(NoBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
    }

    pass P5
    {
        SetVertexShader(CompileShader(vs_5_0, RenderSceneVSExplicit(float3(2.0, -3.0, 5.0), float3(1.0, 1.0, 1.0))));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, RenderScenePSExplicit()));

        SetDepthStencilState(EnableDepth, 0);
        SetBlendState(NoBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
    }*/

	pass P6
	{
        SetVertexShader(CompileShader(vs_5_0, RenderSceneVSRayMarch()));
		SetPixelShader(CompileShader(ps_5_0, PSCausticsGodrays()));

		SetDepthStencilState(DisableDepth, 0);

		SetBlendState(AdditiveBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
	}
}
