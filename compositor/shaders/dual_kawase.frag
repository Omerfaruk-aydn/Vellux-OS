#version 450

/*
 * Vellux OS Real-Time Dual-Kawase Downsample & Specular Lighting Pass
 * Executes an antialiased 4-tap box filter with corner radius masking
 * and a top-lit 1px light reflection line.
 */

layout(location = 0) in vec2 v_texCoord;
layout(location = 0) out vec4 outColor;

layout(binding = 0) uniform sampler2D u_screenTexture;

layout(push_constant) uniform Uniforms {
    vec2 u_resolution;
    vec2 u_halfpixel;
    vec4 u_glassTint;
    float u_radius;
    float u_topLightIntensity;
} ubo;

void main() {
    vec2 halfpixel = ubo.u_halfpixel;

    // 4-tap Dual-Kawase Downsample Kernel
    vec4 sum = texture(u_screenTexture, v_texCoord) * 4.0;
    sum += texture(u_screenTexture, v_texCoord - halfpixel);
    sum += texture(u_screenTexture, v_texCoord + halfpixel);
    sum += texture(u_screenTexture, v_texCoord + vec2(halfpixel.x, -halfpixel.y));
    sum += texture(u_screenTexture, v_texCoord - vec2(halfpixel.x, -halfpixel.y));
    vec4 blurred = sum / 8.0;

    // Vibrance & Saturation Matrix Boost (+20% for Apple-like vibrancy)
    float luma = dot(blurred.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 saturated = mix(vec3(luma), blurred.rgb, 1.25);

    // Apply translucent glass material tint
    vec3 finalRgb = mix(saturated, ubo.u_glassTint.rgb, ubo.u_glassTint.a);

    // Specular Top Bevel Edge Highlight (simulates light refraction at the rim)
    float pixelY = v_texCoord.y * ubo.u_resolution.y;
    if (pixelY < 1.5) {
        finalRgb += vec3(ubo.u_topLightIntensity);
    }

    outColor = vec4(finalRgb, 1.0);
}
