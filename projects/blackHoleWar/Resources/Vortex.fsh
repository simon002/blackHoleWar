#ifdef OPENGL_ES
precision mediump float;
#endif
uniform sampler2D CC_Texture0;
//uniform sampler2D u_texture;
// Varyings
//varying vec2 v_texCoord;
#ifdef GL_ES
varying mediump vec2 v_texCoord;
#else
varying vec2 v_texCoord;
#endif
uniform	float radius ;
uniform	float angle ;

vec2 vortex2( vec2 uv)
{
    uv -= vec2(0.5,0.5);
	float dis = length(uv);
	if (dis <= radius)
	{
	    uv = vec2(dis * cos(angle),dis * sin(angle));
	}
	uv += vec2(0.5,0.5);
	return uv;
}
vec2 vortex( vec2 uv )
{
	uv -= vec2(0.5, 0.5);
	float dist = length(uv);
	float percent = (1.0 - dist) / 1.0;
	if ( percent <= 1.0 && percent >= 0.0) 
	{
		float theta = percent * percent * angle * 0.5;
		float s = sin(theta);
		float c = cos(theta);
		uv = vec2(dot(uv, vec2(c, -s)), dot(uv, vec2(s, c)));
	}
	uv += vec2(0.5, 0.5);

	return uv;
}

void main()
{
	gl_FragColor = texture2D( CC_Texture0, vortex( v_texCoord ) );
	
}