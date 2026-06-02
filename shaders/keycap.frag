#version 460 core
#include <flutter/runtime_effect.glsl>

// Keycap material: a nearly FLAT top with a bevelled rim (a real keycap, not a
// hemisphere/pearl). Lit from the top-left so the top-left bevel catches light
// and the bottom-right is shaded. Four materials:
//   0 glossy, 1 matte, 2 crystal (transparent overlay), 3 jelly.

uniform vec2 uSize;
uniform vec4 uColor;
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

  // Surface normal: ~flat in the centre, tilting out only near the rim (bevel).
  float bevel = smoothstep(0.60, 1.0, r);
  vec2 dir = r > 1e-4 ? p / r : vec2(0.0);
  float slope = 0.28 * r + 1.6 * bevel; // gentle top + strong bevel
  vec3 n = normalize(vec3(dir * slope, 1.0));

  vec3 L = normalize(vec3(-0.5, -0.6, 0.95));
  vec3 V = vec3(0.0, 0.0, 1.0);
  vec3 H = normalize(L + V);
  float diff = max(dot(n, L), 0.0);
  float ndv = max(dot(n, V), 0.0);
  float fres = pow(1.0 - ndv, 3.0);
  float ao = mix(0.82, 1.04, smoothstep(1.0, 0.45, r));

  vec3 col;
  float alpha;

  if (uTexture == 2.0) {
    // Crystal: glassy rim + soft broad sheen on the bevel, clear centre.
    float spec = pow(max(dot(n, H), 0.0), 22.0);
    col = vec3(1.0) * (spec * 0.28 + fres * 0.28);
    alpha = mask * clamp(spec * 0.28 + fres * 0.55, 0.0, 1.0);
  } else if (uTexture == 1.0) {
    // Matte: diffuse, barely any sheen.
    float sheen = pow(max(dot(n, H), 0.0), 4.0) * 0.05;
    col = (uColor.rgb * (0.86 + 0.24 * diff) + vec3(sheen)) * ao;
    alpha = mask * uColor.a;
  } else if (uTexture == 3.0) {
    // Jelly: translucent, subsurface glow, soft wide gloss.
    float spec = pow(max(dot(n, H), 0.0), 13.0) * 0.30;
    float sss = (1.0 - r) * 0.18;
    col = (uColor.rgb * (0.84 + 0.24 * diff + sss) + vec3(spec)) * ao;
    alpha = mask * 0.82;
  } else {
    // Glossy: clean keycap sheen along the bevel (not a centred dot).
    float spec = pow(max(dot(n, H), 0.0), 26.0) * 0.38;
    col = (uColor.rgb * (0.84 + 0.28 * diff) + vec3(spec)) * ao;
    alpha = mask * uColor.a;
  }

  col *= (1.0 - uPressed * 0.05);
  fragColor = vec4(col * alpha, alpha);
}
