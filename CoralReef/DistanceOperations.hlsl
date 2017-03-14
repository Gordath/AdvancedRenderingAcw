#ifndef DISTANCE_OPERATIONS_HLSL_
#define DISTANCE_OPERATIONS_HLSL_

float OperationUnion(float d1, float d2)
{
	return min(d1, d2);
}

float OperationSubtraction(float d1, float d2)
{
	return max(-d1, d2);
}

float OperationIntersection(float d1, float d2)
{
	return max(d1, d2);
}

#endif //DISTANCE_OPERATIONS_HLSL_
