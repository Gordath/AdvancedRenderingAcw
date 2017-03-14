#ifndef DOMAIN_OPERATIONS_HLSL_
#define DOMAIN_OPERATIONS_HLSL_

float OperationRepetition( float3 p, float3 c )
{
    float3 q = (p % c) - 0.5 * c;
    //return primitve( q ); //Any primitive distance function goes here. Maibe ifdef the return type.
	return 0.0; //PLACEHOLDER.
}

float3 OperationTransform( float3 p, float4x4 m )
{
    //float3 q = invert(m)*p; Why inverse the matrix here?
    //return primitive(q); //Any primitive distance function goes here. Maibe ifdef the return type.
	return float3(0.0, 0.0, 0.0); //PLACEHOLDER.
}

float OperationScale( float3 p, float s )
{
    //return primitive(p/s)*s; //Any primitive distance function goes here. Maibe ifdef the return type.
	return 0.0;
}

#endif //DOMAIN_OPERATIONS_HLSL_
