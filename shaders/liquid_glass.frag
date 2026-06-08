#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform vec3 uGlowColor;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    
    // Distorsione liquida sinusoidale
    float wave = sin(uv.y * 10.0 + uTime * 2.0) * 0.02;
    float waveX = cos(uv.x * 12.0 + uTime * 1.5) * 0.015;
    vec2 distortedUV = vec2(uv.x + wave, uv.y + waveX);
    
    // Miscelazione del colore base di overlay
    vec4 baseColor = vec4(0.0, 0.0, 0.0, 0.35); 
    
    // Calcolo iridescenza sui bordi (Ambient Glow) usando uGlowColor
    float edgeGlow = smoothstep(0.8, 1.0, distortedUV.y) + smoothstep(0.0, 0.2, 1.0 - distortedUV.x);
    
    // Flutter richiede alpha pre-moltiplicata: i canali RGB non devono MAI superare l'Alpha.
    float highlightAlpha = edgeGlow * 0.35;
    vec3 highlightRGB = uGlowColor * highlightAlpha; // Pre-moltiplicazione matematica corretta
    vec4 highlight = vec4(highlightRGB, highlightAlpha);
    
    fragColor = baseColor + highlight;
}
