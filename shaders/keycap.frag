#version 460 core
#include <flutter/runtime_effect.glsl>

// Per-pixel keycap material: a convex dome lit from the top-left with diffuse +
// specular shading, rim ambient occlusion and a soft bottom bounce. Far richer
// than a flat gradient. Crystal is handled in Dart (real BackdropFilter glass).

uniform vec2 uSize;     // key size in px
uniform vec4 uColor;    // straight-alpha base colour (0..1)
uniform float uTexture; // 0 glossy, 1 matte, 3 jelly
uniform float uPressed; // 0..1

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;   // 0..1
  vec2 p = uv * 2.0 - 1.0;                    // -1..1
  float r = length(p);

  float aa = 2.5 / uSize.x;
  float mask = 1.0 - smoothstep(1.0 - aa, 1.0, r);
  if (mask <= 0.0) { fragColor = vec4(0.0); return; }

  // Convex hemisphere normal (slightly flattened so it doesn't look like a ball).
  float z = sqrt(max(0.0001, 1.0 - r * r));
  vec3 n = normalize(vec3(p, z * 1.7));

  vec3 L = normalize(vec3(-0.55, -0.65, 0.95)); // light: top-left, frontal
  vec3 V = vec3(0.0, 0.0, 1.0);
  vec3 H = normalize(L + V);

  float diff = max(dot(n, L), 0.0);
  float spec = pow(max(dot(n, H), 0.0), 60.0);

  float ambient = 0.74;
  float diffK = 0.40;
  float specK = 0.55;
  float shine = 60.0;
  if (uTexture == 1.0) { specK = 0.05; diffK = 0.26; ambient = 0.80; } // matte
  if (uTexture == 3.0) { specK = 0.70; ambient = 0.80; }               // jelly

  vec3 base = uColor.rgb;
  vec3 col = base * (ambient + diffK * diff);

  // Rim ambient occlusion (darker toward the edge).
  col *= mix(0.80, 1.05, smoothstep(1.0, 0.30, r));

  // Soft bounce light along the lower rim.
  float bounce = smoothstep(0.55, 1.0, r) * max(0.0, p.y) * 0.12;
  col += base * bounce;

  // Specular hotspot (white).
  col += vec3(1.0) * spec * specK;

  float alpha = mask * uColor.a;
  if (uTexture == 3.0) { alpha *= 0.86; } // jelly translucent
  col *= (1.0 - uPressed * 0.05);

  fragColor = vec4(col * alpha, alpha); // premultiplied
}
