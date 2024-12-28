

struct Material {
    vec3 ambientColor;
    vec3 diffuseColor;
    vec3 specularColor;
    float alpha;
};

Material singularColorTexture(vec3 p, vec3 color) {
    vec3 ambientColor = color;
    vec3 diffuseColor = 0.7 * color;
    vec3 specularColor = 0.2 * vec3(1.0);
    float alpha = 1.0;
    return Material(ambientColor, diffuseColor, specularColor, alpha);
}

struct Surface {
    Material m;
    float d;
};

Surface sdSphere(vec3 p, vec3 c, float r, Material m, mat3 tm) {
    return Surface(m, length(p * tm - c) - r);
}

Surface sdBox(vec3 p, vec3 c, vec3 dimensions, Material m, mat3 tm) {
    vec3 q = abs(p * tm - c) - dimensions;
    return Surface(m, length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0));
}

Surface sdCylinder(vec3 p, vec3 c, float radius, float height, Material m, mat3 tm) {
    vec2 d = vec2(length(p.xz - c.xz) - radius, abs(p.y - c.y) - height * 0.5);
    return Surface(m, min(max(d.x, d.y), 0.0) + length(max(d, 0.0)));
}

Surface sdTorus(vec3 p, vec3 c, float r1, float r2, Material m, mat3 tm) {
    vec2 q = vec2(length(p.xz - c.xz) - r1, p.y);
    return Surface(m, length(q) - r2);
}

Surface blendSurfaces(Surface a, Surface b, float k) {
    float h = clamp(0.5 + 0.5 * (b.d - a.d) / k, 0.0, 1.0);
    Material blendedMaterial;
    blendedMaterial.ambientColor = mix(b.m.ambientColor, a.m.ambientColor, h);
    blendedMaterial.diffuseColor = mix(b.m.diffuseColor, a.m.diffuseColor, h);
    blendedMaterial.specularColor = mix(b.m.specularColor, a.m.specularColor, h);
    blendedMaterial.alpha = mix(b.m.alpha, a.m.alpha, h);
    return Surface(blendedMaterial, mix(b.d, a.d, h) - k * h * (1.0 - h));
}


const float MERGE_RADIUS = 2.5;


Surface scene(vec3 pr) {
    Material redMaterial = singularColorTexture(pr, vec3(1.0, 0.0, 0.0));
    Material greenMaterial = singularColorTexture(pr, vec3(0.0, 1.0, 0.0));
    Material blueMaterial = singularColorTexture(pr, vec3(0.0, 0.0, 1.0));
    Material yellowMaterial = singularColorTexture(pr, vec3(1.0, 1.0, 0.0));
    Material purpleMaterial = singularColorTexture(pr, vec3(0.5, 0.0, 0.5));
    Material orangeMaterial = singularColorTexture(pr, vec3(1.0, 0.5, 0.0));
    Material cyanMaterial = singularColorTexture(pr, vec3(0.0, 1.0, 1.0));
    Material magentaMaterial = singularColorTexture(pr, vec3(1.0, 0.0, 1.0));
    Material whiteMaterial = singularColorTexture(pr, vec3(1.0, 1.0, 1.0));
    Material blackMaterial = singularColorTexture(pr, vec3(0.0, 0.0, 0.0));

    float time = iTime * 0.5; 

    Surface result = Surface(Material(vec3(0.0), vec3(0.0), vec3(0.0), 1.0), 1000.0); 

    for (int i = 0; i < 15; i++) {
        float offset = float(i) * 2.5; 
        vec3 spherePos = vec3(sin(time * 0.5 + offset) * 5.0, cos(time * 0.6 + offset) * 5.0, sin(time * (0.7 + float(i) * 0.1)) * 8.0);
        Material sphereMaterial;

        if (i % 10 == 0) sphereMaterial = redMaterial;
        else if (i % 10 == 1) sphereMaterial = greenMaterial;
        else if (i % 10 == 2) sphereMaterial = blueMaterial;
        else if (i % 10 == 3) sphereMaterial = yellowMaterial;
        else if (i % 10 == 4) sphereMaterial = purpleMaterial;
        else if (i % 10 == 5) sphereMaterial = orangeMaterial;
        else if (i % 10 == 6) sphereMaterial = cyanMaterial;
        else if (i % 10 == 7) sphereMaterial = magentaMaterial;
        else if (i % 10 == 8) sphereMaterial = whiteMaterial;
        else sphereMaterial = blackMaterial;

        float radius = 0.5 + float(i) * 0.2; 
        Surface sphere = sdSphere(pr, spherePos, radius, sphereMaterial, identity());

        result = blendSurfaces(result, sphere, MERGE_RADIUS); 
    }

    return result;
}

vec3 calcNormal(vec3 p) {
    const float EPSILON = 0.0005;
    vec2 e = vec2(1.0, -1.0) * EPSILON;
    return normalize(
        e.xyy * scene(p + e.xyy).d +
        e.yyx * scene(p + e.yyx).d +
        e.yxy * scene(p + e.yxy).d +
        e.xxx * scene(p + e.xxx).d
    );
}

struct RaymarchRes {
    Surface s;
    vec3 p;
    float d;
};

const float MIN_DISTANCE = 0.0;
const float MAX_DISTANCE = 100.0;
const float PRECISION = 0.01;
RaymarchRes raymarch(vec3 ro, vec3 rd, vec3 lightVector) {
    float t = MIN_DISTANCE;
    RaymarchRes res;
    res.d = MAX_DISTANCE;

    for (int i = 0; i < 155; i++) {
        vec3 p = ro + t * rd;
        Surface sf = scene(p);

        if (sf.d < PRECISION) {
            res.p = p;
            res.s = sf;
            break;
        } else if (sf.d > MAX_DISTANCE) break;

        t += sf.d;
    }

    res.d = t;
    return res;
}

mat3 camera(vec3 cameraPos, vec3 lookAtPoint) {
    vec3 cd = normalize(lookAtPoint - cameraPos);
    vec3 cr = normalize(cross(vec3(0, 1, 0), cd));
    vec3 cu = normalize(cross(cd, cr));
    return mat3(-cr, cu, -cd);
}

vec3 calculateCameraPosition(vec3 lookAt, float pitch, float yaw) {
    float cameraRadius = 25.0;
    return vec3(
        cameraRadius * cos(pitch) * sin(yaw),
        cameraRadius * sin(pitch),
        cameraRadius * cos(pitch) * cos(yaw)
    );
}

vec3 calculateLightPosition() {
    float lightTime = iTime * 0.7;
    return vec3(
        8.0 * cos(lightTime),
        6.0,
        8.0 * sin(lightTime)
    );
}

vec3 calculateLight(vec2 fragCoord, RaymarchRes rr, vec3 rd, vec3 lo) {
    vec3 normal = calcNormal(rr.p);              
    vec3 lightDir = normalize(lo - rr.p);       
    vec3 ambient = rr.s.m.ambientColor * 0.3;
    vec3 diffuse = rr.s.m.diffuseColor * max(dot(normal, lightDir), 0.0);
    vec3 reflectDir = reflect(-lightDir, normal);
    vec3 specular = rr.s.m.specularColor * pow(max(dot(reflectDir, -rd), 0.0), rr.s.m.alpha);

    vec3 color = ambient + diffuse + specular;
    return color;
}

float prevMouseX = 0.0;
float prevMouseY = 0.0;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec3 lookAt = vec3(0.0, 0.0, 0.0);

    if (iMouse.z > 0.0) {
        prevMouseX = iMouse.x;
        prevMouseY = iMouse.y;
    }
    const float PI = 3.1415;
    float pitch = (prevMouseY / iResolution.y - 0.5) * PI;
    float yaw = (prevMouseX / iResolution.x - 0.5) * 2.0 * PI;

    vec3 ro = calculateCameraPosition(lookAt, pitch, yaw);
    vec3 rd = camera(ro, lookAt) * normalize(vec3(uv, -1.));
    vec3 lo = calculateLightPosition();

    vec3 bgGradient = mix(
        vec3(0.05, 0.1, 0.2),
        vec3(0.1, 0.15, 0.3),
        uv.y
    );

    RaymarchRes rr = raymarch(ro, rd, lo);

    if (rr.d < MAX_DISTANCE) {
        fragColor = vec4(calculateLight(fragCoord, rr, rd, lo), 1.0);
    } else {
        fragColor = vec4(bgGradient, 1.0);
    }
}
