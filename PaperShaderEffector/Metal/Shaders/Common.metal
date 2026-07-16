#include <metal_stdlib>
using namespace metal;

// MARK: - Shared Types (must match ShaderPipeline.swift)

struct VertexIn {
    float4 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

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

// MARK: - Common Vertex (Fullscreen Quad Passthrough)

struct VertexData {
    float4 position;
    float2 texCoord;
};

vertex VertexOut vertexPassthrough(
    uint vertexID [[vertex_id]],
    constant VertexData* vertices [[buffer(0)]]
) {
    VertexOut out;
    out.position = vertices[vertexID].position;
    out.texCoord = vertices[vertexID].texCoord;
    return out;
}

// MARK: - Utility Functions

// Hash / pseudo-random
float hash1(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

float2 hash2(float2 p) {
    p = float2(dot(p, float2(127.1, 311.7)),
               dot(p, float2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

// Smooth-step noise
float noise2(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);

    float a = hash1(i + float2(0, 0));
    float b = hash1(i + float2(1, 0));
    float c = hash1(i + float2(0, 1));
    float d = hash1(i + float2(1, 1));

    return mix(mix(a, b, u.x),
               mix(c, d, u.x), u.y);
}

// Rotation matrix
float2x2 rotation2D(float angle) {
    float c = cos(angle), s = sin(angle);
    return float2x2(float2(c, -s), float2(s, c));
}

// Apply sizing transform (fit/scale/rotation/origin/offset) to uv
float2 applySizing(float2 uv, float2 resolution, constant CommonUniforms& u) {
    // Aspect ratio correction
    float aspect = resolution.x / resolution.y;

    // Center
    float2 center = float2(u.originX, u.originY);
    float2 st = uv - center;

    // Scale
    st /= u.scale;

    // Rotation
    if (u.rotation != 0.0) {
        float angle = u.rotation * (3.14159265 / 180.0);
        st = rotation2D(-angle) * st;
    }

    // Offset
    st -= float2(u.offsetX, u.offsetY);

    return st + center;
}
