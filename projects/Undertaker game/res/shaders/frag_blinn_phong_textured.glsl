#version 410

layout(location = 0) in vec3 inPos;
layout(location = 1) in vec3 inColor;
layout(location = 2) in vec3 inNormal;
layout(location = 3) in vec2 inUV;

uniform sampler2D s_Diffuse;
uniform sampler2D s_Diffuse2;
uniform sampler2D s_Specular;

uniform vec3  u_AmbientCol;
uniform float u_AmbientStrength;

uniform vec3  u_LightPos;
uniform vec3 u_LightMix;
uniform vec3  u_LightCol;
uniform float u_AmbientLightStrength;
uniform float u_SpecularLightStrength;
uniform float u_Shininess;
// NEW in week 7, see https://learnopengl.com/Lighting/Light-casters for a good reference on how this all works, or
// https://developer.valvesoftware.com/wiki/Constant-Linear-Quadratic_Falloff
uniform float u_LightAttenuationConstant;
uniform float u_LightAttenuationLinear;
uniform float u_LightAttenuationQuadratic;

uniform float u_TextureMix;

uniform vec3  u_CamPos;

out vec4 frag_color;

uniform bool u_Option1;
uniform bool u_Option2;
uniform bool u_Option3;
uniform bool u_Option4;
uniform bool u_Option5;

vec3 result = vec3(0.0, 0.0, 0.0);

// Toon Shading //
const int bands = 5;
const float scaleFactor = 1.0/bands;

// https://learnopengl.com/Advanced-Lighting/Advanced-Lighting
void main() {
	// Lecture 5
	vec3 ambient = u_AmbientLightStrength * u_LightCol;

	// Diffuse
	vec3 N = normalize(inNormal);
	vec3 lightDir = normalize(u_LightPos - inPos);

	float dif = max(dot(N, lightDir), 0.0);
	vec3 diffuse = dif * u_LightCol;// add diffuse intensity

	//Attenuation
	float dist = length(u_LightPos - inPos);
	float attenuation = 1.0f / (
		u_LightAttenuationConstant + 
		u_LightAttenuationLinear * dist +
		u_LightAttenuationQuadratic * dist * dist);

	// Specular
	vec3 viewDir  = normalize(u_CamPos - inPos);
	vec3 h        = normalize(lightDir + viewDir);

	// Get the specular power from the specular map
	float texSpec = texture(s_Specular, inUV).x;
	float spec = pow(max(dot(N, h), 0.0), u_Shininess); // Shininess coefficient (can be a uniform)
	vec3 specular = u_SpecularLightStrength * texSpec * spec * u_LightCol; // Can also use a specular color

	// Get the albedo from the diffuse / albedo map
	vec4 textureColor1 = texture(s_Diffuse, inUV);
	vec4 textureColor2 = texture(s_Diffuse2, inUV);
	vec4 textureColor = mix(textureColor1, textureColor2, u_TextureMix);

	// Toon Shading - Outline Effect
	float edge = (dot(viewDir, N) < 0.4) ? 0.0 : 1.0;
		
		//Debug Toggles
		//No Lighting
		if(u_Option1 == true)
		{
			result = inColor * textureColor.rgb;
		}
		//Ambient Only
		else if(u_Option2 == true)
		{
			result = ((u_AmbientCol * u_AmbientStrength) + (ambient  * attenuation)) * inColor * textureColor.rgb;
		}
		//Specular Only
		else if(u_Option3 == true)
		{
			result = ((specular) * attenuation) * inColor * textureColor.rgb;
		}
		//Ambient + Specular
		else if(u_Option4 == true)
		{
			result = ((u_AmbientCol * u_AmbientStrength) + (ambient + diffuse + specular) * attenuation) * inColor * textureColor.rgb;
		}
		//Custom Lighting
		else if(u_Option5 == true)
		{
			diffuse = floor(diffuse * bands) * scaleFactor;
			
			result = (u_AmbientCol * u_AmbientStrength) + (ambient + diffuse + specular) * edge * inColor * textureColor.rgb;
		}

	frag_color = vec4(result, textureColor.a);
}