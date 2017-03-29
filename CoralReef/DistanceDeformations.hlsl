#ifndef DISTANCE_DEFORMATIONS_HLSL_
#define DISTANCE_DEFORMATIONS_HLSL_

float Displacement1(float3 p, float angle)
{
	return sin(angle * p.x) * sin(angle * p.y) * sin(angle * p.z);
}

float OperationDisplace(float primitiveDistance, float displacement)
{
	return primitiveDistance + displacement;
}

#endif //DISTANCE_DEFORMATIONS_HLSL_
