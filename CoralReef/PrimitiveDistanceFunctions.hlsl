#ifndef PRIMITIVE_DISTANCE_FUNCTIONS_HLSL_
#define PRIMITIVE_DISTANCE_FUNCTIONS_HLSL_

float SignedSphere(float3 p, float s)
{
	return length(p) - s;
}

float UnsignedBox(float3 p, float3 b)
{
	return length(max(abs(p) - b, 0.0));
}

float UnsignedRoundBox(float3 p, float3 b, float r)
{
	return length(max(abs(p) - b, 0.0)) - r;
}

float SignedBox(float3 p, float3 b)
{
	float3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float SignedTorus(float3 p, float2 t)
{
	float2 q = float2(length(p.xz) - t.x, p.y);
	return length(q) - t.y;
}

float SignedCylinder(float3 p, float3 c)
{
	return length(p.xz - c.xy) - c.z;
}

float SignedCone(float3 p, float2 c)
{
    // c must be normalized
	float q = length(p.xy);
	return dot(c, float2(q, p.z));
}

float SignedPlane(float3 p, float4 n)
{
  // n must be normalized
	return dot(p, n.xyz) + n.w;
}

float SignedHexPrism(float3 p, float2 h)
{
	float3 q = abs(p);
	return max(q.z - h.y, max((q.x * 0.866025 + q.y * 0.5), q.y) - h.x);
}

float SignedTriPrism(float3 p, float2 h)
{
	float3 q = abs(p);
	return max(q.z - h.y, max(q.x * 0.866025 + p.y * 0.5, -p.y) - h.x * 0.5);
}

float SignedCapsule(float3 p, float3 a, float3 b, float r)
{
	float3 pa = p - a, ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h) - r;
}

float SignedCappedCylinder(float3 p, float2 h)
{
	float2 d = abs(float2(length(p.xz), p.y)) - h;
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float SignedCappedCone(in float3 p, in float3 c)
{
	float2 q = float2(length(p.xz), p.y);
	float2 v = float2(c.z * c.y / c.x, -c.z);
	float2 w = v - q;
	float2 vv = float2(dot(v, v), v.x * v.x);
	float2 qv = float2(dot(v, w), v.x * w.x);
	float2 d = max(qv, 0.0) * qv / vv;
	return sqrt(dot(w, w) - max(d.x, d.y)) * sign(max(q.y * v.x - q.x * v.y, w.y));
}

float SignedEllipsoid(in float3 p, in float3 r)
{
	return (length(p / r) - 1.0) * min(min(r.x, r.y), r.z);
}

float dot2(in float3 v)
{
	return dot(v, v);
}

float UnsignedTriangle(float3 p, float3 a, float3 b, float3 c)
{
	float3 ba = b - a;
	float3 pa = p - a;
	float3 cb = c - b;
	float3 pb = p - b;
	float3 ac = a - c;
	float3 pc = p - c;
	float3 nor = cross(ba, ac);

	return sqrt(
    (sign(dot(cross(ba, nor), pa)) +
     sign(dot(cross(cb, nor), pb)) +
     sign(dot(cross(ac, nor), pc)) < 2.0)
     ?
     min(min(
     dot2(ba * clamp(dot(ba, pa) / dot2(ba), 0.0, 1.0) - pa),
     dot2(cb * clamp(dot(cb, pb) / dot2(cb), 0.0, 1.0) - pb)),
     dot2(ac * clamp(dot(ac, pc) / dot2(ac), 0.0, 1.0) - pc))
     :
     dot(nor, pa) * dot(nor, pa) / dot2(nor));
}

float UnsignedQuad(float3 p, float3 a, float3 b, float3 c, float3 d)
{
	float3 ba = b - a;
	float3 pa = p - a;
	float3 cb = c - b;
	float3 pb = p - b;
	float3 dc = d - c;
	float3 pc = p - c;
	float3 ad = a - d;
	float3 pd = p - d;
	float3 nor = cross(ba, ad);

	return sqrt(
    (sign(dot(cross(ba, nor), pa)) +
     sign(dot(cross(cb, nor), pb)) +
     sign(dot(cross(dc, nor), pc)) +
     sign(dot(cross(ad, nor), pd)) < 3.0)
     ?
     min(min(min(
     dot2(ba * clamp(dot(ba, pa) / dot2(ba), 0.0, 1.0) - pa),
     dot2(cb * clamp(dot(cb, pb) / dot2(cb), 0.0, 1.0) - pb)),
     dot2(dc * clamp(dot(dc, pc) / dot2(dc), 0.0, 1.0) - pc)),
     dot2(ad * clamp(dot(ad, pd) / dot2(ad), 0.0, 1.0) - pd))
     :
     dot(nor, pa) * dot(nor, pa) / dot2(nor));
}

#endif //PRIMITIVE_DISTANCE_FUNCTIONS_HLSL_
