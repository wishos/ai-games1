shader_type canvas_item;

// God Rays - volumetric light beams using screen-space UV
uniform vec2 source_uv = vec2(0.5, 0.0);  // Light source UV position (top center = 0.5, 0.0)
uniform float exposure : hint_range(0.0, 1.0) = 0.35;
uniform float decay : hint_range(0.5, 1.0) = 0.95;
uniform float density : hint_range(0.0, 1.0) = 0.7;
uniform float weight : hint_range(0.0, 1.0) = 0.5;
uniform int num_samples : hint_range(20, 150) = 80;
uniform vec3 ray_color : source_color = vec3(1.0, 0.88, 0.65);
uniform float ray_width : hint_range(0.01, 0.5) = 0.18;
uniform float noise_speed : hint_range(0.0, 5.0) = 0.4;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.4;

// Simple hash noise for variation
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    
    // Direction from source to current pixel
    vec2 delta = uv - source_uv;
    float dist = length(delta);
    vec2 dir = delta / max(dist, 0.001);
    
    // Angular falloff from center ray
    float perp_dist = abs(dot(delta, vec2(-dir.y, dir.x)));
    float angular_falloff = 1.0 - smoothstep(0.0, ray_width, perp_dist);
    
    // Distance-based decay
    float radial_decay = pow(decay, dist * 6.0);
    
    // Accumulate samples along ray
    vec2 step_uv = delta * density / float(num_samples);
    float illumination = 1.0;
    float ray_sum = 0.0;
    
    for (int i = 0; i < num_samples; i++) {
        vec2 sample_pos = uv - step_uv * float(i);
        // Noise adds shimmer
        float noise = hash(sample_pos * 30.0 + vec2(TIME * noise_speed));
        ray_sum += illumination * (0.5 + noise * noise_strength);
        illumination *= radial_decay;
    }
    
    // Final intensity
    float intensity = ray_sum * exposure * weight * angular_falloff;
    
    // Gold-tinted light rays
    vec3 col = ray_color * intensity;
    
    // Output: color with alpha
    COLOR = vec4(col, intensity * 0.85);
}
