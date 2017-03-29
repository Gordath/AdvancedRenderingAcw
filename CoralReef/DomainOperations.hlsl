#ifndef DOMAIN_OPERATIONS_HLSL_
#define DOMAIN_OPERATIONS_HLSL_

float3 OperationRepetition( float3 p, float3 spacing )
{
	return p % spacing - 0.5 * spacing;
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
