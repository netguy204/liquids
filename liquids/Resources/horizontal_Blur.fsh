// Shader taken from: http://webglsamples.googlecode.com/hg/electricflower/electricflower.html

#ifdef GL_ES
precision mediump float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

uniform sampler2D u_texture;

void main() {
	vec4 sum = vec4(0.0);
    float ps = 10.0;
	sum += texture2D(u_texture, vec2(v_texCoord.x - 0.00505515*ps, v_texCoord.y)) * 0.010376;
	sum += texture2D(u_texture, vec2(v_texCoord.x - 0.00321691*ps, v_texCoord.y)) * 0.0944214;
	sum += texture2D(u_texture, vec2(v_texCoord.x - 0.00137868*ps, v_texCoord.y)) * 0.296753;
	sum += texture2D(u_texture, vec2(v_texCoord.x                 , v_texCoord.y)) * 0.196381;
	sum += texture2D(u_texture, vec2(v_texCoord.x + 0.00137868*ps, v_texCoord.y)) * 0.296753;
	sum += texture2D(u_texture, vec2(v_texCoord.x + 0.00321691*ps, v_texCoord.y)) * 0.0944214;
	sum += texture2D(u_texture, vec2(v_texCoord.x + 0.00505515*ps, v_texCoord.y)) * 0.010376;
    
	gl_FragColor = sum;
}

