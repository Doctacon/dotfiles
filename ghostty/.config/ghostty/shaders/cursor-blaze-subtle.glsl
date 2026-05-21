// Subtle ember/blaze around the active cursor for Ghostty.

vec2 norm(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

vec2 rectCenter(vec4 rect) {
    return vec2(rect.x + rect.z * 0.5, rect.y - rect.w * 0.5);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);

    vec4 current = vec4(norm(iCurrentCursor.xy, 1.0), norm(iCurrentCursor.zw, 0.0));
    vec2 p = norm(fragCoord, 1.0);
    vec2 c = rectCenter(current);

    float cursorSize = max(current.z, current.w);
    float d = distance(p, c);

    float pulse = 0.78 + 0.22 * sin(iTime * 5.0);
    float ember = 1.0 - smoothstep(cursorSize * 0.9, cursorSize * 5.5, d);
    float core = 1.0 - smoothstep(cursorSize * 0.15, cursorSize * 1.4, d);

    vec3 orange = vec3(0.976, 0.451, 0.086);
    vec3 gold = vec3(0.992, 0.729, 0.455);
    vec3 blaze = mix(gold, orange, core);

    float alpha = ember * 0.055 * pulse + core * 0.055;
    fragColor.rgb = mix(fragColor.rgb, blaze, alpha);
}
