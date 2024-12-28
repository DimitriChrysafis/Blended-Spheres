float Circle(vec2 position, float scale) {
    return length(position) - scale;
}

vec4 opSmoothUnion(float d1, vec3 color1, float d2, vec3 color2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    float blendedDist = mix(d2, d1, h) - k * h * (1.0 - h);
    vec3 blendedColor = mix(color2, color1, h);
    return vec4(blendedDist, blendedColor);
}

vec3 fractalNoise(vec2 uv) {
    uv = uv * 2.0 - vec2(1.0, 1.0);
    float a = sin(uv.x * 3.0 + sin(iTime)) * 0.5 + 0.5;
    float b = cos(uv.y * 3.0 + cos(iTime)) * 0.5 + 0.5;
    return vec3(a, b, 1.0 - a);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 R = iResolution.xy;
    vec2 uv = (2.0 * fragCoord - R) / min(R.x, R.y);
    float movementScale = 1.5;

    vec4 params1 = vec4(0.3, 0.5, 2.0, 1.5) * movementScale;
    vec4 params2 = vec4(0.4, 0.3, 1.0, 2.5) * movementScale;
    vec4 params3 = vec4(0.5, 0.4, 1.5, 2.0) * movementScale;

    float moveSpeed1 = 1.0;
    float moveSpeed2 = 0.75;
    float moveSpeed3 = 1.25;

    vec2 pos1 = vec2(sin(iTime * moveSpeed1) * 0.8 + sin(iTime * 0.3) * 0.4, cos(iTime * moveSpeed1) * 0.6 + cos(iTime * 0.4) * 0.4);
    vec2 pos2 = vec2(sin(iTime * moveSpeed2 + 1.0) * 0.8 + cos(iTime * 0.7) * 0.5, cos(iTime * moveSpeed2 + 1.0) * 0.6 + sin(iTime * 0.8) * 0.5);
    vec2 pos3 = vec2(sin(iTime * moveSpeed3 + 2.0) * 0.8 + cos(iTime * 0.5) * 0.3, cos(iTime * moveSpeed3 + 2.0) * 0.6 + sin(iTime * 0.9) * 0.2);
    vec2 pos4 = vec2(sin(iTime * moveSpeed1 + 3.0) * 0.8 + sin(iTime * 0.6) * 0.3, cos(iTime * moveSpeed1 + 3.0) * 0.6 + cos(iTime * 0.6) * 0.5);
    vec2 pos5 = vec2(sin(iTime * moveSpeed2 + 4.0) * 0.8 + cos(iTime * 0.4) * 0.4, cos(iTime * moveSpeed2 + 4.0) * 0.6 + sin(iTime * 0.6) * 0.6);
    vec2 pos6 = vec2(sin(iTime * moveSpeed3 + 5.0) * 0.8 + cos(iTime * 0.2) * 0.3, cos(iTime * moveSpeed3 + 5.0) * 0.6 + sin(iTime * 0.7) * 0.4);

    vec3 gradColor1 = vec3(0.5 + 0.5 * sin(iTime * 0.1), 0.5, 0.5 + 0.5 * cos(iTime * 0.1));
    vec3 gradColor2 = vec3(0.5 + 0.5 * cos(iTime * 0.2), 0.5, 0.5 + 0.5 * sin(iTime * 0.2));
    vec3 gradColor3 = vec3(0.5 + 0.5 * sin(iTime * 0.3), 0.5, 0.5 + 0.5 * cos(iTime * 0.3));
    vec3 gradColor4 = vec3(0.5 + 0.5 * cos(iTime * 0.4), 0.5, 0.5 + 0.5 * sin(iTime * 0.4));
    vec3 gradColor5 = vec3(0.5 + 0.5 * sin(iTime * 0.5), 0.5, 0.5 + 0.5 * cos(iTime * 0.5));
    vec3 gradColor6 = vec3(0.5 + 0.5 * cos(iTime * 0.6), 0.5, 0.5 + 0.5 * sin(iTime * 0.6));

    float circleSize = 0.35;

    float circle1 = Circle(uv + pos1, circleSize);
    float circle2 = Circle(uv + pos2, circleSize);
    float circle3 = Circle(uv + pos3, circleSize);
    float circle4 = Circle(uv + pos4, circleSize);
    float circle5 = Circle(uv + pos5, circleSize);
    float circle6 = Circle(uv + pos6, circleSize);

    float blendFactor = 0.1;
    vec4 blendResult1 = opSmoothUnion(circle1, gradColor1, circle2, gradColor2, blendFactor);
    vec4 blendResult2 = opSmoothUnion(blendResult1.x, blendResult1.yzw, circle3, gradColor3, blendFactor);
    vec4 blendResult3 = opSmoothUnion(blendResult2.x, blendResult2.yzw, circle4, gradColor4, blendFactor);
    vec4 blendResult4 = opSmoothUnion(blendResult3.x, blendResult3.yzw, circle5, gradColor5, blendFactor);
    vec4 blendResult5 = opSmoothUnion(blendResult4.x, blendResult4.yzw, circle6, gradColor6, blendFactor);

    float blendDist = blendResult5.x;
    vec3 finalColor = blendResult5.yzw;

    vec3 bgPattern = fractalNoise(uv * 2.0);
    finalColor = mix(finalColor, bgPattern, 0.3);

    float pix = 1.5 / min(R.x, R.y);
    float aa = smoothstep(-pix / 2.0, pix / 2.0, blendDist);

    fragColor = vec4(finalColor, 1.0) * (1.0 - aa);
}
