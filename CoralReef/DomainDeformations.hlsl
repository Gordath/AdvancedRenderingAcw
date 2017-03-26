#ifndef DOMAIN_DEFORMATIONS_HLSL_
#define DOMAIN_DEFORMATIONS_HLSL_

float3 OperationTwist(float3 p, float angle)
{
	float c = cos(angle * p.y);
	float s = sin(angle * p.y);
	float2x2 m = float2x2(float2(c, -s), float2(s, c));
	float3 q = float3(mul(p.xz, m), p.y);
	return q;
}

float3 OperationCheapBend(float3 p)
{
	float c = cos(20.0 * p.y);
	float s = sin(20.0 * p.y);
	float2x2 m = float2x2(float2(c, -s), float2(s, c));
	float3 q = float3(mul(p.xy, m), p.z);
	return q;
}

#endif //DOMAIN_DEFORMATIONS_HLSL_
