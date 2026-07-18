#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// NOTE: must match OverlayUniforms in ShaderPipeline.swift (32 bytes)
struct OverlayUniforms {
    float scale;         // 오버레이 크기 배율 (1.0 = 캔버스 꽉 채움)
    float rotation;      // 회전 (라디안)
    float offsetX;       // 위치 오프셋 X (UV 단위, 0 = 중앙)
    float offsetY;       // 위치 오프셋 Y (UV 단위, 0 = 중앙)
    float opacity;       // 투명도 (0~1)
    float canvasAspect;  // 캔버스 width/height
    int   blendMode;     // LayerBlendMode raw value (0=Normal, 1=Multiply, ...)
    float _pad;
};

// Blend mode implementations (src = foreground/layer, dst = background)
static float3 applyBlendMode(float3 dst, float3 src, int mode) {
    if (mode == 1) {
        // Multiply
        return dst * src;
    } else if (mode == 2) {
        // Screen
        return 1.0 - (1.0 - dst) * (1.0 - src);
    } else if (mode == 3) {
        // Overlay
        float3 r;
        r.r = dst.r < 0.5 ? 2.0*dst.r*src.r : 1.0 - 2.0*(1.0-dst.r)*(1.0-src.r);
        r.g = dst.g < 0.5 ? 2.0*dst.g*src.g : 1.0 - 2.0*(1.0-dst.g)*(1.0-src.g);
        r.b = dst.b < 0.5 ? 2.0*dst.b*src.b : 1.0 - 2.0*(1.0-dst.b)*(1.0-src.b);
        return r;
    } else if (mode == 4) {
        // Soft Light (W3C formula)
        float3 d;
        d.r = dst.r < 0.25 ? ((16.0*dst.r - 12.0)*dst.r + 4.0)*dst.r : sqrt(dst.r);
        d.g = dst.g < 0.25 ? ((16.0*dst.g - 12.0)*dst.g + 4.0)*dst.g : sqrt(dst.g);
        d.b = dst.b < 0.25 ? ((16.0*dst.b - 12.0)*dst.b + 4.0)*dst.b : sqrt(dst.b);
        float3 r;
        r.r = src.r < 0.5 ? dst.r-(1.0-2.0*src.r)*dst.r*(1.0-dst.r) : dst.r+(2.0*src.r-1.0)*(d.r-dst.r);
        r.g = src.g < 0.5 ? dst.g-(1.0-2.0*src.g)*dst.g*(1.0-dst.g) : dst.g+(2.0*src.g-1.0)*(d.g-dst.g);
        r.b = src.b < 0.5 ? dst.b-(1.0-2.0*src.b)*dst.b*(1.0-dst.b) : dst.b+(2.0*src.b-1.0)*(d.b-dst.b);
        return r;
    } else if (mode == 5) {
        // Hard Light
        float3 r;
        r.r = src.r < 0.5 ? 2.0*dst.r*src.r : 1.0 - 2.0*(1.0-dst.r)*(1.0-src.r);
        r.g = src.g < 0.5 ? 2.0*dst.g*src.g : 1.0 - 2.0*(1.0-dst.g)*(1.0-src.g);
        r.b = src.b < 0.5 ? 2.0*dst.b*src.b : 1.0 - 2.0*(1.0-dst.b)*(1.0-src.b);
        return r;
    } else if (mode == 6) {
        // Color Dodge
        return min(dst / max(1.0 - src, float3(0.001)), float3(1.0));
    } else if (mode == 7) {
        // Color Burn
        return 1.0 - min((1.0 - dst) / max(src, float3(0.001)), float3(1.0));
    } else if (mode == 8) {
        // Darken
        return min(dst, src);
    } else if (mode == 9) {
        // Lighten
        return max(dst, src);
    } else if (mode == 10) {
        // Difference
        return abs(dst - src);
    } else if (mode == 11) {
        // Exclusion
        return dst + src - 2.0 * dst * src;
    }
    // Normal (mode == 0 or default)
    return src;
}

fragment float4 overlayFragment(
    VertexOut                 in      [[stage_in]],
    constant OverlayUniforms& u       [[buffer(0)]],
    texture2d<float>          bgTex   [[texture(0)]],
    texture2d<float>          ovTex   [[texture(1)]],
    sampler                   s       [[sampler(0)]]
) {
    float4 bg = bgTex.sample(s, in.texCoord);

    // 오버레이 중심 (UV 단위)
    float2 center = float2(0.5 + u.offsetX, 0.5 + u.offsetY);
    float2 delta  = in.texCoord - center;

    // 회전 보정: aspect-corrected space에서 회전
    float aspect = max(u.canvasAspect, 0.001);
    float2 phys  = float2(delta.x, delta.y / aspect);

    float cosR = cos(-u.rotation);
    float sinR = sin(-u.rotation);
    float2 rotated;
    rotated.x = cosR * phys.x - sinR * phys.y;
    rotated.y = sinR * phys.x + cosR * phys.y;

    float2 backUV = float2(rotated.x, rotated.y * aspect);
    float2 ovUV   = backUV / max(u.scale, 0.001) + float2(0.5);

    bool inBounds = ovUV.x >= 0.0 && ovUV.x <= 1.0 &&
                    ovUV.y >= 0.0 && ovUV.y <= 1.0;
    if (!inBounds) {
        return float4(bg.rgb, 1.0);
    }

    float4 ov     = ovTex.sample(s, ovUV);
    float  alpha  = ov.a * u.opacity;
    float3 blended = applyBlendMode(bg.rgb, ov.rgb, u.blendMode);
    return float4(mix(bg.rgb, blended, alpha), 1.0);
}
