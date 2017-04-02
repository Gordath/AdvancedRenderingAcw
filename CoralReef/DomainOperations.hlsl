#ifndef DOMAIN_OPERATIONS_HLSL_
#define DOMAIN_OPERATIONS_HLSL_

float3 OperationRepetition( float3 p, float3 spacing )
{
	return p % spacing - 0.5 * spacing;
}

float3 OperationRepetition(float3 p, float3 distance, bool3 repeatOnAxis)
{
    float3 P = p;
    if (repeatOnAxis.x)
        P.x = (abs(P.x) % distance.x - 0.5 * distance.x) * sign(P.x);
    if (repeatOnAxis.y)
        P.y = (abs(P.y) % distance.y - 0.5 * distance.y) * sign(P.y);
    if (repeatOnAxis.z)
        P.z = (abs(P.z) % distance.z - 0.5 * distance.z) * sign(P.z);
    return P;
}

float3 OperationTransform( float3 p, float4x4 m )
{
    //float3 q = invert(m)*p; Why inverse the matrix here?
    //return primitive(q); //Any primitive distance function goes here. Maibe ifdef the return type.
	return float3(0.0, 0.0, 0.0);
}

float OperationScale( float3 p, float s )
{
    return p / s * s;
}

#endif //DOMAIN_OPERATIONS_HLSL_
