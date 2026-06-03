#version 460 core
#include <flutter/runtime_effect.glsl>

// Keycap material with four clearly-different finishes:
//   0 glossy  - wet lacquer: broad highlight + sharp core, slightly brighter
//   1 matte   - flat, slightly desaturated & darker, no shine (chalky)
//   2 crystal - transparent glass: rim glow only (see-through behind)
//   3 jelly   - clearly translucent + saturated + inner glow (gummy)

uniform vec2 uSize;
uniform vec4 uColor;
uniform float uTexture;
uniform float uPressed;

out vec4 fragColor;

vec3 sat(vec3 c, float s) {
  float l = dot(c, vec3(0.299, 0.587, 0.114));
  return clamp(mix(vec3(l), c, s), 0.0, 1.0);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec2 p = uv * 2.0 - 1.0;
  float r = length(p);
  float aa = 2.5 / uSize.x;
  float mask = 1.0 - smoothstep(1.0 - aa, 1.0, r);
  if (mask <= 0.0) { fragColor = vec4(0.0); return; }

  float bevel = smoothstep(0.62, 1.0, r);
  vec2 dir = r > 1e-4 ? p / r : vec2(0.0);
  float slope = 0.20 * r + 1.5 * bevel;
  vec3 n = normalize(vec3(dir * slope, 1.0));

  vec3 L = normalize(vec3(-0.55, -0.62, 0.9));
  vec3 V = vec3(0.0, 0.0, 1.0);
  vec3 H = normalize(L + V);
  float ndh = max(dot(n, H), 0.0);
  float ndl = max(dot(n, L), 0.0);
  float ndv = max(dot(n, V), 0.0);
  float fres = pow(1.0 - ndv, 3.0);
  float ao = mix(0.80, 1.0, smoothstep(1.0, 0.58, r));
  float rim = smoothstep(0.78, 1.0, r) * max(0.0, dot(dir, normalize(vec2(-0.6, -0.7))));

  vec3 col;
  float alpha;

  if (uTexture == 1.0) {
    // Matte — flat, chalky, no highlight.
    col = sat(uColor.rgb, 0.85) * 0.92 * ao;
    alpha = mask * uColor.a;
  } else if (uTexture == 3.0) {
    // Jelly — translucent, saturated, glowing.
    float gloss = pow(ndh, 20.0) * 0.25;
    float sss = (1.0 - r) * 0.28;
    col = sat(uColor.rgb, 1.45) * (0.90 + 0.12 * ndl + sss) * ao + vec3(gloss);
    alpha = mask * 0.66;
  } else if (uTexture == 2.0) {
    // Crystal — clear glass, rim glow only.
    float spec = pow(ndh, 40.0) * 0.25;
    col = vec3(1.0) * (spec * 0.5 + fres * 0.22 + rim * 0.10);
    alpha = mask * clamp(fres * 0.5 + spec * 0.5 + rim * 0.12, 0.0, 1.0);
  } else {
    // Glossy — wet lacquer: broad sheen + sharp glint.
    float broad = pow(ndh, 26.0) * 0.34;
    float core = pow(ndh, 200.0) * 0.65;
    col = uColor.rgb * (1.02 + 0.06 * ndl) * ao + vec3(broad + core + rim * 0.12);
    alpha = mask * uColor.a;
  }

  col *= (1.0 - uPressed * 0.05);
  fragColor = vec4(col * alpha, alpha);
}
