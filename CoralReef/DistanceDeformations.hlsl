#ifndef DISTANCE_DEFORMATIONS_HLSL_
#define DISTANCE_DEFORMATIONS_HLSL_

float3 OperationDisplace(float primitiveDistance, float displacement)
{
	return primitiveDistance + displacement;
}

#endif //DISTANCE_DEFORMATIONS_HLSL_
