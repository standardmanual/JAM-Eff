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
    float canvasAspect;  // 캔버스 width/height (e.g. 0.5625 for 9:16)
    float _pad0;
    float _pad1;
};

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

    // 회전 보정: UV 좌표를 물리 픽셀 비율(aspect-corrected)로 변환 후 회전
    // aspect = W/H (e.g. 9/16 = 0.5625). X는 좁고 Y는 길므로 Y가 더 큰 물리 거리.
    // 변환: physDelta = (delta.x * W, delta.y * H) = (delta.x, delta.y / aspect) * W
    // 회전 후 역변환: (rotated.x / W, rotated.y / H) = (rotated.x, rotated.y * aspect)
    float aspect = max(u.canvasAspect, 0.001);
    float2 phys  = float2(delta.x, delta.y / aspect);  // aspect-corrected space

    float cosR = cos(-u.rotation);
    float sinR = sin(-u.rotation);
    float2 rotated;
    rotated.x = cosR * phys.x - sinR * phys.y;
    rotated.y = sinR * phys.x + cosR * phys.y;

    // 물리 공간에서 다시 UV 공간으로 역변환 후 스케일 적용
    float2 backUV = float2(rotated.x, rotated.y * aspect);
    float2 ovUV   = backUV / max(u.scale, 0.001) + float2(0.5);

    bool inBounds = ovUV.x >= 0.0 && ovUV.x <= 1.0 &&
                    ovUV.y >= 0.0 && ovUV.y <= 1.0;
    if (!inBounds) {
        return float4(bg.rgb, 1.0);
    }

    float4 ov    = ovTex.sample(s, ovUV);
    float  alpha = ov.a * u.opacity;
    float3 blended = mix(bg.rgb, ov.rgb, alpha);
    return float4(blended, 1.0);
}
