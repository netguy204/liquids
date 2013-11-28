// Shader taken from: http://webglsamples.googlecode.com/hg/electricflower/electricflower.html

#ifdef GL_ES
precision lowp float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

uniform sampler2D u_texture;

void main() {
    vec4 sample = texture2D(u_texture, v_texCoord);
    vec4 solid = vec4(1.0, 1.0, 1.0, 1.0);
    vec4 background = vec4(0.0, 0.0, 0.0, 1.0);
    float threshhold = 0.4;
    
    if(sample.a > threshhold) {
        gl_FragColor = solid;
    } else {
        //float factor = (threshhold - sample.a) / threshhold;
        //gl_FragColor = mix(solid, background, pow(factor, 120.0));
        gl_FragColor = background;
    }
    
    //gl_FragColor = sample;
}

