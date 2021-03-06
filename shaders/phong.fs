precision highp float;

varying vec3 fNormal;	//fragment normal direction
varying vec3 fPosition; //fragment position in *eye* space.

uniform vec3 lightPosition;
uniform vec4 lightColor;
uniform vec4 materialProperties;
uniform vec3 materialColor;
uniform vec2 attenuation;

uniform mat4 view;

vec3 phong(vec3 lightPosition, vec4 lightColor, vec4 material, vec3 materialColor, vec3 position, vec3 normal, vec3 v, vec2 attenuationVals){
	
	//calculate attenuation
	float distanceLightToFragment = length(lightPosition - position);
	float attenuation = lightColor.w / ((attenuationVals.x * distanceLightToFragment) + (attenuationVals.y * pow(distanceLightToFragment, 2.0)));

	if (attenuation > 0.01){
		//transform light in world space ot eye space.
		vec3 light = lightPosition;

		//calculate all our direction vectors
		vec3 n = normalize( normal );
		vec3 l = normalize(light-position);// vector to light source
		vec3 r = normalize(reflect(l,n));

		//calculate diffuse/specular components based on view/normal/light vectors
		float diffuse = max( dot(l,n), 0.0 );
		float specular = max(dot(r,v), 0.0);
		specular = pow( specular, material.w);

		//mix all three comonents together
		vec3 lightContribColor = lightColor.rgb * materialColor.rgb;
		vec3 diffuseComponent = material.x*diffuse*lightContribColor;
		vec3 specularComponent = material.y*specular*lightContribColor;
			
		

		vec3 intensity = (diffuseComponent + specularComponent) * attenuation;
		return intensity;
	}
	return vec3(0.0, 0.0, 0.0);
}

void main(){


	vec3 ambientComponent = materialProperties.z*materialColor;
	vec3 sumColor = ambientComponent;

	vec3 position = fPosition;
	vec3 normal = fNormal;
	vec3 viewDir = normalize(fPosition);

	vec3 light = (view * vec4(lightPosition, 1.0)).xyz;

	sumColor += phong(light , lightColor, materialProperties, materialColor, position, normal, viewDir, attenuation);

	gl_FragColor = vec4( sumColor, 1.0);
}
