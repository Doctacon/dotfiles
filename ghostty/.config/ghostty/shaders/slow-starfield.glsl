// Slow, subtle warm starfield for Ghostty.
// Stable light-theme version: stars tint/darken bright background pixels instead
// of adding light, because adding color to white can clamp back to invisible.

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec4 starLayer(vec2 uv, float scale, float speed, float threshold, vec3 color, float size, float time) {
    uv.x += time * speed;
    uv.y += time * speed * 0.13;

    vec2 grid = uv * scale;
    vec2 cell = floor(grid);
    vec2 local = fract(grid) - 0.5;

    float rnd = hash21(cell);
    float exists = step(threshold, rnd);
    float d = length(local);
    float twinkle = 0.72 + 0.28 * sin(time * 1.2 + rnd * 6.2831);
    float alpha = smoothstep(size, 0.0, d) * exists * twinkle;

    return vec4(color * alpha, alpha);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);

    // Only draw on very bright background-like pixels, not on text.
    float lum = dot(fragColor.rgb, vec3(0.2126, 0.7152, 0.0722));
    float backgroundMask = smoothstep(0.78, 0.92, lum);

    vec2 uv = fragCoord.xy / iResolution.xy;
    uv.x *= iResolution.x / iResolution.y;

    // Warm-only parallax layers: orange / cream / amber. No blue.
    vec4 s1 = starLayer(uv, 16.0, 0.006, 0.965, vec3(0.976, 0.451, 0.086), 0.090, iTime);
    vec4 s2 = starLayer(uv + vec2(4.7, 2.1), 24.0, 0.010, 0.976, vec3(0.996, 0.862, 0.667), 0.075, iTime);
    vec4 s3 = starLayer(uv + vec2(8.2, 1.3), 34.0, 0.014, 0.984, vec3(0.992, 0.729, 0.455), 0.060, iTime);

    vec3 starColor = s1.rgb + s2.rgb + s3.rgb;
    float starAlpha = clamp(s1.a + s2.a + s3.a, 0.0, 1.0) * backgroundMask;

    // Tint toward star color rather than adding brightness, so stars show on light themes.
    fragColor.rgb = mix(fragColor.rgb, starColor / max(starAlpha, 0.001), starAlpha * 0.42);
}
