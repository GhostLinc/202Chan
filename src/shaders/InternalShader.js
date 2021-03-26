const LightCubeVertexShader = `
attribute vec3 aVertexPosition;

uniform mat4 uModelViewMatrix;
uniform mat4 uProjectionMatrix;


void main(void) {

  gl_Position = uProjectionMatrix * uModelViewMatrix * vec4(aVertexPosition, 1.0);

}
`;

const LightCubeFragmentShader = `
#ifdef GL_ES
precision mediump float;
#endif

uniform float uLigIntensity;
uniform vec3 uLightColor;

void main(void) {
    
  //gl_FragColor = vec4(1,1,1, 1.0);
  gl_FragColor = vec4(uLightColor, 1.0);
}
`;
const VertexShader = `
attribute vec3 aVertexPosition;
attribute vec3 aNormalPosition;
attribute vec2 aTextureCoord;

uniform mat4 uModelViewMatrix;
uniform mat4 uProjectionMatrix;

varying highp vec3 vFragPos;
varying highp vec3 vNormal;
varying highp vec2 vTextureCoord;

void main(void) {

  vFragPos = aVertexPosition;
  vNormal = aNormalPosition;

  gl_Position = uProjectionMatrix * uModelViewMatrix * vec4(aVertexPosition, 1.0);

  vTextureCoord = aTextureCoord;

}
`;

const FragmentShader = `
#ifdef GL_ES
precision mediump float;
#endif

uniform int uTextureSample;
uniform vec3 uKd;
uniform sampler2D uSampler;
uniform vec3 uLightPos;
uniform vec3 uCameraPos;

varying highp vec3 vFragPos;
varying highp vec3 vNormal;
varying highp vec2 vTextureCoord;

void main(void) {
  
  if (uTextureSample == 1) {
    gl_FragColor = texture2D(uSampler, vTextureCoord);
  } else {
    gl_FragColor = vec4(uKd,1);
  }

}
`;

const PhongVertexShader = `
attribute vec3 aVertexPosition;
attribute vec3 aNormalPosition;
attribute vec2 aTextureCoord;

uniform mat4 uModelViewMatrix;
uniform mat4 uProjectionMatrix;

varying highp vec3 vFragPos;
varying highp vec3 vNormal;
varying highp vec2 vTextureCoord;

void main(void){
  vFragPos = aVertexPosition;
  gl_Position = uProjectionMatrix * uModelViewMatrix * vec4(aVertexPosition, 1.0);
  vNormal = aNormalPosition;
  vTextureCoord = aTextureCoord;
}
`;



const PhongFragmentShader = `
#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D uSampler;
uniform vec3 uKd;
uniform vec3 uKs;
uniform vec3 uLightPos;
uniform vec3 uCameraPos;
uniform float uLightIntensity;
uniform float uPointLightIntensity;
uniform float uDirLightIntensity;
uniform vec3 uDirLightDirection;
uniform vec3 uDirLightColor;
uniform int uTextureSample;

varying highp vec3 vFragPos;
varying highp vec3 vNormal;
varying highp vec2 vTextureCoord;

void main(void){
  vec3 baseColor;
  if (uTextureSample == 1) { 
    baseColor = texture2D(uSampler, vTextureCoord).rgb;
  }
  else{
    baseColor = uKd;
  }

  baseColor = pow(baseColor, vec3(2.2));
  vec3 normal = normalize(vNormal);
  vec3 viewDir = normalize(uCameraPos - vFragPos);
  vec3 lightDir = normalize(uDirLightDirection);
  vec3 reflectDir = reflect(-lightDir, normal);
  float NdotL = dot(lightDir, normal);
  float VdotR = dot(viewDir, reflectDir);
  
  vec3 ambient = vec3(0.3, 0.1, 0.1) * uDirLightColor * baseColor;
  float diff = max(NdotL, 0.0);
  vec3 diffuse =  diff * baseColor * uDirLightIntensity * uDirLightColor;
  float spec = pow(max(VdotR, 0.0), 35.0);
  vec3 specular = uKs * spec * uDirLightIntensity * uDirLightColor; 
  vec3 dirLightColor = ambient + diffuse + specular;
  // vec3 dirLightColor = vec3(0);

  vec3 pointLightDir = normalize(uLightPos - vFragPos);
  float pointLightNdotL = dot(pointLightDir, normal);
  vec3 pointLightReflectDir = reflect(-pointLightDir, normal);
  float pointLightVdotR = dot(viewDir, pointLightReflectDir);
  float pointLightDiff = max(pointLightNdotL, 0.0);
  float light_atten_coff = uPointLightIntensity / length(uLightPos - vFragPos);
  vec3 pointLightDiffuse = pointLightDiff * baseColor;
  float pointLightSpec = pow(max(pointLightVdotR, 0.0), 35.0);
  vec3 pointLightSpecular = uKs * light_atten_coff * pointLightSpec;
  vec3 pointLightColor = pointLightDiffuse + pointLightSpecular;

  gl_FragColor = vec4(pow(dirLightColor + pointLightColor, vec3(1.0 / 2.2)), 1.0);
  // gl_FragColor = vec4(uDirLightIntensity, uDirLightIntensity, uDirLightIntensity, 1.0);
}
`;