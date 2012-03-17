// Shader taken from: http://webglsamples.googlecode.com/hg/electricflower/electricflower.html

#ifdef GL_ES
precision mediump float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

uniform sampler2D u_texture;

void main() {
	vec4 sum = vec4(0.0);
    
    float ps=10.0;
	sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y - 0.0067402*ps)) * 0.010376;
	sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y - 0.00428922*ps)) * 0.0944214;
	sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y - 0.00183824*ps)) * 0.296753;
	sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y                 )) * 0.196381;
	sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y + 0.00183824*ps)) * 0.296753;
	sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y + 0.00428922*ps)) * 0.0944214;
	sum += texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y + 0.0067402*ps)) * 0.010376;
    
    float l = length(sum.rgb);
    vec4 color = vec4(0.6, 0.6, 1.0, 1.0);
    vec4 color2 = vec4(0.0, 0.0, 0.0, 0.0);
    
    if(l > 0.8) {
        gl_FragColor = color;
    } else {
        gl_FragColor = mix(color, color2, (0.8 - l) / 0.8);
    }
	
    //gl_FragColor = sum;
}

