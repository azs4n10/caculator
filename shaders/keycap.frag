#version 460 core
#include <flutter/runtime_effect.glsl>

// Keycap material. The body stays close to its base colour (no bright glowing
// centre); only the rim is gently shaded. Each texture is defined by its
// FINISH, not by overall brightness:
//   0 glossy  - flat body + a small sharp reflection top-left + a rim glint
//   1 matte   - flat even colour, no shine at all
//   2 crystal - transparent, only a glassy rim glow (see-through behind)
//   3 jelly   - saturated translucent gummy with an inner glow

uniform vec2 uSize;
uniform vec4 uColor;
uniform float uTexture;
uniform float uPressed;

out vec4 fragColor;

vec3 saturate3(vec3 c, float s) {
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

  // Near-flat top, bevelled rim.
  float bevel = smoothstep(0.62, 1.0, r);
  vec2 dir = r > 1e-4 ? p / r : vec2(0.0);
  float slope = 0.20 * r + 1.5 * bevel;
  vec3 n = normalize(vec3(dir * slope, 1.0));

  vec3 L = normalize(vec3(-0.55, -0.62, 0.9));
  vec3 V = vec3(0.0, 0.0, 1.0);
  vec3 H = normalize(L + V);
  float diff = max(dot(n, L), 0.0);
  float ndv = max(dot(n, V), 0.0);
  float fres = pow(1.0 - ndv, 3.0);

  // Body keeps the base colour; the rim is gently darkened.
  float ao = mix(0.80, 1.0, smoothstep(1.0, 0.58, r));
  vec3 body = uColor.rgb * (0.96 + 0.08 * diff) * ao;

  // top-left rim glint
  float rim = smoothstep(0.78, 1.0, r) * max(0.0, dot(dir, normalize(vec2(-0.6, -0.7))));

  vec3 col;
  float alpha;

  if (uTexture == 1.0) {
    // Matte — flat, no shine.
    col = body;
    alpha = mask * uColor.a;
  } else if (uTexture == 3.0) {
    // Jelly — saturated translucent, inner glow.
    float sss = (1.0 - r) * 0.16;
    float spec = pow(max(dot(n, H), 0.0), 28.0) * 0.20;
    col = saturate3(uColor.rgb, 1.3) * (0.92 + 0.10 * diff + sss) * ao + vec3(spec);
    alpha = mask * 0.80;
  } else if (uTexture == 2.0) {
    // Crystal — clear; glassy rim + faint sheen only.
    float spec = pow(max(dot(n, H), 0.0), 40.0) * 0.25;
    col = vec3(1.0) * (spec * 0.5 + fres * 0.22 + rim * 0.10);
    alpha = mask * clamp(fres * 0.5 + spec * 0.5 + rim * 0.12, 0.0, 1.0);
  } else {
    // Glossy — small sharp reflection + rim glint.
    float spec = pow(max(dot(n, H), 0.0), 110.0) * 0.7;
    col = body + vec3(spec) + vec3(rim * 0.16);
    alpha = mask * uColor.a;
  }

  col *= (1.0 - uPressed * 0.05);
  fragColor = vec4(col * alpha, alpha);
}
