#ifdef GL_ES
precision mediump float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

uniform sampler2D u_texture;

void main() {
	vec4 sum = vec4(0.0);
    float blurSize = 0.005;
    float scale = 0.03;
    
    float offset[3];
    offset[0]= 0.0;
    offset[1] = 1.3846153846;
    offset[2] = 3.2307692308;
    
    float weight[3];
    weight[0] = 0.2270270270;
    weight[1] = 0.3162162162;
    weight[2] = 0.0702702703;
    
    sum = texture2D(u_texture, vec2(gl_FragCoord)/1024.0);
    
    
    for(int ii = 1; ii < 3; ii++) {
        sum += texture2D(u_texture, (vec2(gl_FragCoord) + vec2(0.0, offset[ii]))/1024.0) * weight[ii];
        sum += texture2D(u_texture, (vec2(gl_FragCoord) - vec2(0.0, offset[ii]))/1024.0) * weight[ii];
    }
    
    /*
    for(float ii = 1.0; ii < 3.0; ii+=1.0) {
        for(float jj = 1.0; jj < 3.0; jj+=1.0) {
            vec2 p1 = vec2(v_texCoord.x - ii * blurSize,
                           v_texCoord.y - jj * blurSize);
            
            vec2 p2 = vec2(v_texCoord.x - ii * blurSize,
                           v_texCoord.y + jj * blurSize);
            
            vec2 p3 = vec2(v_texCoord.x + ii * blurSize,
                           v_texCoord.y - jj * blurSize);
            
            vec2 p4 = vec2(v_texCoord.x + ii * blurSize,
                           v_texCoord.y + jj * blurSize);
            
            sum += texture2D(u_texture, p1) * scale;
            sum += texture2D(u_texture, p2) * scale;
            sum += texture2D(u_texture, p3) * scale;
            sum += texture2D(u_texture, p4) * scale;
        }
    }
    */
    
    
    //sum = sum * 0.01;
    /*
	sum += texture2D(u_texture, v_texCoord - 4.0 * blurSize) * 0.05;
	sum += texture2D(u_texture, v_texCoord - 3.0 * blurSize) * 0.09;
	sum += texture2D(u_texture, v_texCoord - 2.0 * blurSize) * 0.12;
	sum += texture2D(u_texture, v_texCoord - 1.0 * blurSize) * 0.15;
	sum += texture2D(u_texture, v_texCoord                 ) * 0.16;
	sum += texture2D(u_texture, v_texCoord + 1.0 * blurSize) * 0.15;
	sum += texture2D(u_texture, v_texCoord + 2.0 * blurSize) * 0.12;
	sum += texture2D(u_texture, v_texCoord + 3.0 * blurSize) * 0.09;
	sum += texture2D(u_texture, v_texCoord + 4.0 * blurSize) * 0.05;
    */
    
    /*
    
    if(length(sum.rgb) > 0.01) {
        gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
    } else {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
    }
    */
    
    gl_FragColor = vec4(sum.rgb, 1.0);
}

