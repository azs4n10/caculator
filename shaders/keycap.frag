#version 460 core
#include <flutter/runtime_effect.glsl>

// Per-pixel keycap material with four distinct looks:
//   0 glossy  - pearl gloss, sharp specular
//   1 matte   - velvety, almost no specular
//   2 crystal - transparent overlay: fresnel rim + crisp specular (real
//               see-through comes from a BackdropFilter behind this)
//   3 jelly   - translucent gummy with subsurface glow + soft wide specular

uniform vec2 uSize;
uniform vec4 uColor;    // straight-alpha base colour
uniform float uTexture;
uniform float uPressed;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec2 p = uv * 2.0 - 1.0;
  float r = length(p);
  float aa = 2.5 / uSize.x;
  float mask = 1.0 - smoothstep(1.0 - aa, 1.0, r);
  if (mask <= 0.0) { fragColor = vec4(0.0); return; }

  float z = sqrt(max(0.0001, 1.0 - r * r));
  vec3 n = normalize(vec3(p, z * 1.7));
  vec3 L = normalize(vec3(-0.55, -0.65, 0.95));
  vec3 V = vec3(0.0, 0.0, 1.0);
  vec3 H = normalize(L + V);
  float diff = max(dot(n, L), 0.0);
  float ndv = max(dot(n, V), 0.0);
  float fres = pow(1.0 - ndv, 3.0);
  float ao = mix(0.80, 1.05, smoothstep(1.0, 0.30, r));

  vec3 col;
  float alpha;

  if (uTexture == 2.0) {
    // Crystal overlay: clear centre, lit edges + sharp glint.
    float spec = pow(max(dot(n, H), 0.0), 120.0);
    col = vec3(1.0) * (spec * 0.9 + fres * 0.35);
    alpha = mask * clamp(spec * 0.9 + fres * 0.5, 0.0, 1.0);
  } else if (uTexture == 1.0) {
    // Matte: diffuse, faint broad sheen.
    float sheen = pow(max(dot(n, H), 0.0), 3.0) * 0.06;
    col = (uColor.rgb * (0.82 + 0.30 * diff) + vec3(sheen)) * ao;
    alpha = mask * uColor.a;
  } else if (uTexture == 3.0) {
    // Jelly: translucent, subsurface glow toward the centre, soft wide gloss.
    float spec = pow(max(dot(n, H), 0.0), 18.0) * 0.40;
    float sss = (1.0 - r) * 0.22;
    col = (uColor.rgb * (0.80 + 0.34 * diff + sss) + vec3(spec)) * ao;
    alpha = mask * 0.82;
  } else {
    // Glossy: pearl, sharp specular + bottom bounce.
    float spec = pow(max(dot(n, H), 0.0), 60.0) * 0.55;
    float bounce = smoothstep(0.55, 1.0, r) * max(0.0, p.y) * 0.12;
    col = (uColor.rgb * (0.74 + 0.40 * diff) + uColor.rgb * bounce + vec3(spec)) * ao;
    alpha = mask * uColor.a;
  }

  col *= (1.0 - uPressed * 0.05);
  fragColor = vec4(col * alpha, alpha);
}
