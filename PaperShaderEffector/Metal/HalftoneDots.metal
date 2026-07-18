#include <metal_stdlib>
using namespace metal;

// Forward declarations from Common.metal
float hash1(float2 p);

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

struct HalftonDotsUniforms {
    int    type;           // 0=classic,1=gooey,2=holes,3=soft
    int    grid;           // 0=square,1=hex
    float  size;
    float  radius;
    float  contrast;
    int    originalColors; // bool as int
    int    inverted;       // bool as int
    float  grainMixer;
    float  grainOverlay;
    float  grainSize;
    float4 colorFront;
    float4 colorBack;
};

static float luminance(float3 c) {
    return dot(c, float3(0.299, 0.587, 0.114));
}

// MARK: - Fragment

fragment float4 halftonDotsFragment(
    VertexOut                    in     [[stage_in]],
    constant CommonUniforms&     common [[buffer(0)]],
    constant HalftonDotsUniforms& u     [[buffer(1)]],
    texture2d<float>             inputTex [[texture(0)]],
    sampler                      s        [[sampler(0)]]
) {
    float2 uv = in.texCoord;
    float aspect = common.resolution.x / max(common.resolution.y, 1.0);

    // Tile size in uv space (smaller size param → smaller tiles → more dots)
    float tileSize = max(u.size, 0.01) * 0.1;

    // Determine the tile center this fragment belongs to.
    // For hex grid, offset every other row by half a tile.
    float2 center;
    if (u.grid == 1) {
        float row = floor(uv.y / tileSize);
        float xOffset = (fmod(row, 2.0) < 1.0) ? 0.0 : tileSize * 0.5;
        float2 shifted = float2(uv.x - xOffset, uv.y);
        float2 tile = floor(shifted / tileSize);
        center = (tile + 0.5) * tileSize + float2(xOffset, 0.0);
    } else {
        float2 tile = floor(uv / tileSize);
        center = (tile + 0.5) * tileSize;
    }

    // Sample source brightness at the tile center (halftone screening)
    float4 src = inputTex.sample(s, center);
    float b = luminance(src.rgb);

    // Contrast around mid-grey
    b = clamp((b - 0.5) * (1.0 + u.contrast) + 0.5, 0.0, 1.0);

    // In a halftone, darker areas → larger dots. Invert brightness for coverage.
    float coverage = 1.0 - b;
    if (u.inverted != 0) coverage = b;

    // Dot radius (in uv units) proportional to coverage
    float maxR = u.radius * tileSize * 0.6;
    float dotRadius = coverage * maxR;

    // Distance from tile center (aspect corrected so dots stay round)
    float2 offset = uv - center;
    offset.x *= aspect;
    float dist = length(offset);

    // Edge softness depends on dot type
    float aa = tileSize * 0.03 + 0.0015;
    float dotMask; // 1 = inside dot (front color), 0 = background

    switch (u.type) {
        case 1: { // gooey — wide soft transition, blobby merge feel
            float soft = tileSize * 0.25 + aa;
            dotMask = smoothstep(dotRadius + soft, dotRadius - soft, dist);
            break;
        }
        case 2: { // holes — background filled, punch holes where dots would be
            float hole = smoothstep(dotRadius - aa, dotRadius + aa, dist);
            dotMask = hole; // inverted sense: 1 outside hole
            break;
        }
        case 3: { // soft — gentle fade dot
            dotMask = 1.0 - smoothstep(0.0, dotRadius + aa, dist);
            break;
        }
        default: { // 0 classic — crisp circle
            dotMask = smoothstep(dotRadius + aa, dotRadius - aa, dist);
            break;
        }
    }

    // Choose colors. If originalColors, use the sampled photo color as front.
    float4 front = (u.originalColors != 0) ? src : u.colorFront;
    float4 back  = u.colorBack;

    float4 color = mix(back, front, dotMask);

    // Grain overlay
    if (u.grainMixer > 0.0 || u.grainOverlay > 0.0) {
        float gScale = mix(200.0, 900.0, clamp(u.grainSize, 0.0, 1.0));
        float grain = hash1(uv * gScale + common.time * 7.0);
        color.rgb = mix(color.rgb, float3(grain), u.grainMixer);
        color.rgb += (grain - 0.5) * u.grainOverlay;
    }

    return float4(clamp(color.rgb, 0.0, 1.0), 1.0);
}
