shader_type canvas_item;

uniform float black_threshold : hint_range(0.0, 1.0) = 0.08;
uniform float edge_softness : hint_range(0.001, 0.2) = 0.03;

void fragment() {
    vec4 video_color = texture(TEXTURE, UV);

    // Perceived brightness of the pixel
    float brightness = dot(video_color.rgb, vec3(0.299, 0.587, 0.114));

    // Smoothly fade dark pixels out
    float alpha = smoothstep(
        black_threshold,
        black_threshold + edge_softness,
        brightness
    );

    COLOR = vec4(video_color.rgb, video_color.a * alpha);
}
