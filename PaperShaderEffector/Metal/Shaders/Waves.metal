#include <metal_stdlib>
using namespace metal;

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

struct WavesUniforms {
    float  shape;        // 0~3: 0=zigzag, 1.5=sine, 3=waves morph
    float  frequency;   // 0~2
    float  amplitude;   // 0~1
    float  spacing;     // 0~2
    float  proportion;  // 0~1
    float  softness;    // 0~1
    float4 colorFront;
    float4 colorBack;
};

// MARK: - Wave shape functions (ported from paper-design/shaders Waves GLSL)

// Zigzag wave
float zigzag(float x) {
    return abs(fract(x * 0.5) * 2.0 - 1.0) * 2.0 - 1.0;
}

// Sine wave
float sineWave(float x) {
    return sin(x * 3.14159265 * 2.0);
}

// Square-ish wave (approximated)
float squareWave(float x) {
    return sign(sin(x * 3.14159265 * 2.0));
}

// Morphable wave: shape 0→zigzag, 1→sine, 2→sine(wider), 3→squareish
float shapedWave(float x, float shape) {
    if (shape < 1.0) {
        return mix(zigzag(x), sineWave(x), shape);
    } else if (shape < 2.0) {
        return mix(sineWave(x), sineWave(x * 0.5), shape - 1.0);
    } else {
        return mix(sineWave(x * 0.5), squareWave(x), shape - 2.0);
    }
}

// MARK: - Fragment

fragment float4 wavesFragment(
    VertexOut              in     [[stage_in]],
    constant CommonUniforms&  common [[buffer(0)]],
    constant WavesUniforms&   eff    [[buffer(1)]]
) {
    float2 uv = in.texCoord;
    float  t  = common.time * 0.5;

    float aspect = common.resolution.x / common.resolution.y;

    // Normalized coordinate with aspect correction
    float2 st = uv;
    st.x *= aspect;

    // Wave layers
    float freq  = eff.frequency * 2.0;
    float amp   = eff.amplitude * 0.15;
    float space = max(eff.spacing, 0.01) * 0.15;

    // Multiple wave bands
    int bands = int(1.0 / max(space, 0.01)) + 2;
    float mask = 0.0;

    for (int i = 0; i < bands; i++) {
        float fi = float(i);
        // Band center y (proportional position)
        float bandY = (fi + eff.proportion) * space;
        // Wave displacement
        float wave = shapedWave(st.x * freq + t + fi * 0.7, eff.shape) * amp;
        // Signed distance to band center
        float d = abs(st.y - bandY - wave) - space * 0.3;
        // Smooth edge
        float soft = max(eff.softness * 0.02, 0.002);
        float band = 1.0 - smoothstep(-soft, soft, d);
        mask = max(mask, band);
    }

    float4 color = mix(eff.colorBack, eff.colorFront, mask);
    return float4(color.rgb, 1.0);
}
