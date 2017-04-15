#ifndef MATERIALS_HLSL_
#define MATERIALS_HLSL_

static const int MATERIAL_SEA_FLOOR = 0;
const int MATERIAL_SEA_SURFACE = 1;
const int MATERIAL_SEA_WEED = 2;
const int MATERIAL_CORAL = 3;
const int MATERIAL_BUBBLE = 4;

const float3 seaFloorColour = float3(0.8666666666666667, 0.5215686274509804, 0.3607843137254902);
const float3 seaSurfaceColour = float3(0.0, 0.08, 0.5);
const float3 seaWeedColour = float3(0.0, 1.0, 0.0);
const float3 coralColour = float3(1.0, 0.1, 0.3137254901960784);
const float3 bubbleColour = float3(0.0, 0.0, 0.0);

#endif //MATERIALS_HLSL_
