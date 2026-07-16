#include <metal_stdlib>
using namespace metal;

// Forward declarations from Common.metal
float hash1(float2 p);
float2 hash2(float2 p);
float noise2(float2 p);
float2 applySizing(float2 uv, float2 resolution, constant struct CommonUniforms& u);

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

struct CommonUniforms {
    float  time;
    float2 resolution;
    float  scale;
    float  rotation;
    float  originX;
    float  originY;
    float  offsetX;
    float  offsetY;
    int    fit;
};

struct MeshGradientUniforms {
    float distortion;
    float swirl;
    float grainMixer;
    float grainOverlay;
    int   colorCount;
};

// MARK: - Mesh Gradient Fragment
// Ported from paper-design/shaders MeshGradient GLSL → MSL

fragment float4 meshGradientFragment(
    VertexOut         in        [[stage_in]],
    constant CommonUniforms&        common [[buffer(0)]],
    constant MeshGradientUniforms&  eff    [[buffer(1)]],
    constant float4*                colors [[buffer(2)]]
) {
    float2 uv = in.texCoord;
    float  t  = common.time * 0.4;

    int count = max(eff.colorCount, 1);

    // Apply distortion
    float2 distUv = uv;
    if (eff.distortion > 0.0) {
        float d = eff.distortion;
        distUv.x += sin(uv.y * 3.14159 * 2.0 + t)       * d * 0.3;
        distUv.y += cos(uv.x * 3.14159 * 2.0 + t * 1.3) * d * 0.3;
    }

    // Apply swirl
    if (eff.swirl > 0.0) {
        float2 c = distUv - 0.5;
        float  r = length(c);
        float  angle = eff.swirl * r * 6.0 + t * 0.5;
        float  cs = cos(angle), sn = sin(angle);
        distUv = float2(cs * c.x - sn * c.y, sn * c.x + cs * c.y) + 0.5;
    }

    // Blend colors using animated voronoi-like basis
    float4 outColor = float4(0.0);
    float  totalWeight = 0.0;

    for (int i = 0; i < count; i++) {
        float fi = float(i) / float(max(count - 1, 1));
        // Animated control point
        float2 cp = float2(
            0.5 + 0.4 * sin(fi * 3.14159 * 2.0 + t * (0.7 + fi * 0.3)),
            0.5 + 0.4 * cos(fi * 3.14159 * 2.0 * 1.3 + t * (0.5 + fi * 0.5))
        );
        float dist = distance(distUv, cp);
        float weight = 1.0 / max(dist * dist, 0.0001);
        outColor    += colors[i] * weight;
        totalWeight += weight;
    }

    outColor /= totalWeight;

    // Grain overlay
    if (eff.grainMixer > 0.0 || eff.grainOverlay > 0.0) {
        float grain = fract(sin(dot(uv + t * 0.01, float2(12.9898, 78.233))) * 43758.5453);
        outColor.rgb = mix(outColor.rgb, float3(grain), eff.grainMixer);
        outColor.rgb += (grain - 0.5) * eff.grainOverlay;
    }

    return clamp(float4(outColor.rgb, 1.0), 0.0, 1.0);
}
