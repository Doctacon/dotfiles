// Subtle orange cursor trail for Ghostty.
// Works best with Ghostty cursor uniforms enabled by current releases.

float easeOut(float x) {
    return pow(1.0 - x, 3.0);
}

vec2 norm(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

vec2 rectCenter(vec4 rect) {
    return vec2(rect.x + rect.z * 0.5, rect.y - rect.w * 0.5);
}

float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);

    vec4 current = vec4(norm(iCurrentCursor.xy, 1.0), norm(iCurrentCursor.zw, 0.0));
    vec4 previous = vec4(norm(iPreviousCursor.xy, 1.0), norm(iPreviousCursor.zw, 0.0));

    vec2 p = norm(fragCoord, 1.0);
    vec2 a = rectCenter(previous);
    vec2 b = rectCenter(current);

    float cursorSize = max(current.z, current.w);
    float travel = distance(a, b);
    if (travel < cursorSize * 1.6) return;

    float age = clamp((iTime - iTimeCursorChange) / 0.42, 0.0, 1.0);
    float fade = easeOut(age);

    float d = sdSegment(p, a, b);
    float width = cursorSize * 0.42;
    float core = 1.0 - smoothstep(width * 0.25, width, d);
    float glow = 1.0 - smoothstep(width, width * 3.2, d);

    vec3 orange = vec3(0.976, 0.451, 0.086);
    vec3 amber = vec3(0.992, 0.729, 0.455);
    vec3 color = mix(amber, orange, core);
    float alpha = (core * 0.18 + glow * 0.08) * fade;

    fragColor.rgb = mix(fragColor.rgb, color, alpha);
}
