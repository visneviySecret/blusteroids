shader_type canvas_item;

uniform float blur_strength : hint_range(0.0, 5.0) = 1.0;
uniform int blur_samples : hint_range(1, 32) = 16;

vec4 blur_texture(sampler2D tex, vec2 uv, vec2 pixel_size, float strength) {
    vec4 color = vec4(0.0);
    float total_weight = 0.0;
    
    // Гауссово размытие
    for (int x = -blur_samples / 2; x <= blur_samples / 2; x++) {
        for (int y = -blur_samples / 2; y <= blur_samples / 2; y++) {
            vec2 offset = vec2(float(x), float(y)) * pixel_size * strength;
            float weight = exp(-0.5 * (float(x * x + y * y)) / (strength * strength));
            
            color += texture(tex, uv + offset) * weight;
            total_weight += weight;
        }
    }
    
    return color / total_weight;
}

void fragment() {
    vec2 pixel_size = 1.0 / TEXTURE_PIXEL_SIZE;
    COLOR = blur_texture(TEXTURE, UV, TEXTURE_PIXEL_SIZE, blur_strength);
} 