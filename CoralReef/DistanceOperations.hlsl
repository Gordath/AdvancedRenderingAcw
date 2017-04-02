#ifndef DISTANCE_OPERATIONS_HLSL_
#define DISTANCE_OPERATIONS_HLSL_

float OperationUnion(float d1, int matId1, float d2, int matId2, out int selectedMat)
{
    float res = min(d1, d2);
    
    if (res >= d1)
    {
        selectedMat = matId1;
    }
    else
    {
        selectedMat = matId2;
    }

    return res;
}

float OperationSubtraction(float d1, int matId1, float d2, int matId2, out int selectedMat)
{
    float res = max(-d1, d2);

    if (res >= d1)
    {
        selectedMat = matId1;
    }
    else
    {
        selectedMat = matId2;
    }

    return res;
}

float OperationIntersection(float d1, int matId1, float d2, int matId2, out int selectedMat)
{
    float res = max(d1, d2);

    if (res >= d1)
    {
        selectedMat = matId1;
    }
    else
    {
        selectedMat = matId2;
    }

	return res;
}

#endif //DISTANCE_OPERATIONS_HLSL_
