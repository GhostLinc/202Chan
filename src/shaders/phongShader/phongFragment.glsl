#ifdef GL_ES
precision mediump float;
#endif

// Phong related variables
uniform sampler2D uSampler;
uniform vec3 uKd;
uniform vec3 uKs;
uniform vec3 uLightPos;
uniform vec3 uCameraPos;
uniform vec3 uLightIntensity;

varying highp vec2 vTextureCoord;
varying highp vec3 vFragPos;
varying highp vec3 vNormal;

#define AMBIENT vec3(0.5, 0.28, 0.3)
#define LIGHT_WEIGHT 100.0

// Shadow map related variables
#define NUM_SAMPLES 20
#define BLOCKER_SEARCH_NUM_SAMPLES NUM_SAMPLES
#define PCF_NUM_SAMPLES NUM_SAMPLES
#define NUM_RINGS 10

#define EPS 1e-3
#define PI 3.141592653589793
#define PI2 6.283185307179586

uniform sampler2D uShadowMap;

varying vec4 vPositionFromLight;

highp float rand_1to1(highp float x ) { 
  // -1 -1
  return fract(sin(x)*10000.0);
}

highp float rand_2to1(vec2 uv ) { 
  // 0 - 1
	const highp float a = 12.9898, b = 78.233, c = 43758.5453;
	highp float dt = dot( uv.xy, vec2( a,b ) ), sn = mod( dt, PI );
	return fract(sin(sn) * c);
}

float unpack(vec4 rgbaDepth) {
    const vec4 bitShift = vec4(1.0, 1.0/256.0, 1.0/(256.0*256.0), 1.0/(256.0*256.0*256.0));
    return dot(rgbaDepth, bitShift);
}

float useShadowMap(sampler2D shadowMap, vec4 shadowCoord){
  vec4 depthValue = texture2D(shadowMap, shadowCoord.xy);
  return unpack(depthValue);
}

vec2 poissonDisk[NUM_SAMPLES];

void poissonDiskSamples( const in vec2 randomSeed ) {

  float ANGLE_STEP = PI2 * float( NUM_RINGS ) / float( NUM_SAMPLES );
  float INV_NUM_SAMPLES = 1.0 / float( NUM_SAMPLES );

  float angle = rand_2to1( randomSeed ) * PI2;
  float radius = INV_NUM_SAMPLES;
  float radiusStep = radius;

  for( int i = 0; i < NUM_SAMPLES; i ++ ) {
    poissonDisk[i] = vec2( cos( angle ), sin( angle ) ) * pow( radius, 0.75 );
    radius += radiusStep;
    angle += ANGLE_STEP;
  }
}

void uniformDiskSamples( const in vec2 randomSeed ) {

  float randNum = rand_2to1(randomSeed);
  float sampleX = rand_1to1( randNum ) ;
  float sampleY = rand_1to1( sampleX ) ;

  float angle = sampleX * PI2;
  float radius = sqrt(sampleY);

  for( int i = 0; i < NUM_SAMPLES; i ++ ) {
    poissonDisk[i] = vec2( radius * cos(angle) , radius * sin(angle)  );

    sampleX = rand_1to1( sampleY ) ;
    sampleY = rand_1to1( sampleX ) ;

    angle = sampleX * PI2;
    radius = sqrt(sampleY);
  }
}

float PCF(sampler2D shadowMap, vec4 coords, float penumbra) {
  //float closestDepth = useShadowMap(shadowMap, coords);
  vec3 lightDirWS = normalize(uLightPos - vFragPos);
  vec3 normalWS = normalize(vNormal);
  float ndotl = max(dot(normalWS, lightDirWS), 0.0);
  float bias = EPS * (1.0 - ndotl);
  float currentDepth = coords.z;
  float inShadow = 0.0;
  //float texelSize = 1.0 / 8192.0;
  float texelSize = 1.0 / 1024.0;
  //uniformDiskSamples(coords.xy);
  poissonDiskSamples(coords.xy);
  //for(int i = -1; i <= 1; i++)
  //{
  //    for(int j = -1; j <= 1; j++)
  //    {
  //        float pcfDepth = useShadowMap(shadowMap, vec4(coords.xy + vec2(i, j) * texelSize, 0, 0)); 
  //        inShadow += currentDepth < pcfDepth + bias ? 1.0 : 0.0;      
  //    }    
  //}
  //inShadow /= 9.0;
  for(int i = 0; i < NUM_SAMPLES; i++)
  {
    float shadowMapDepth = useShadowMap(shadowMap, vec4(coords.xy + poissonDisk[i] * penumbra * texelSize, 0, 0)); 
    inShadow += currentDepth > shadowMapDepth + bias ? 0.0 : 1.0;   
  }
  inShadow /= float(NUM_SAMPLES);
  return inShadow;
}


float findBlocker(sampler2D shadowMap, vec2 uv, float zReceiver){
  vec3 lightDirWS = normalize(uLightPos - vFragPos);
  vec3 normalWS = normalize(vNormal);
  float ndotl = max(dot(normalWS, lightDirWS), 0.0);
  float bias = EPS * (1.0 - ndotl);
  float blockDepth = 0.0;
  float texelSize = 1.0 / 1024.0;
  float blockNum = 0.0;
  //poissonDiskSamples(uv);
  uniformDiskSamples(uv);
  for(int i = 0; i < BLOCKER_SEARCH_NUM_SAMPLES; i++)
  {
    float shadowMapDepth = useShadowMap(shadowMap, vec4(uv.xy + poissonDisk[i] * LIGHT_WEIGHT * texelSize, 0, 0)); 
    if(zReceiver > shadowMapDepth){
      blockDepth += shadowMapDepth;
      blockNum++;
    } 
  }
  blockDepth /= blockNum;
  //blockDepth /= float(BLOCKER_SEARCH_NUM_SAMPLES);
  float averBlockerDepth = zReceiver < blockDepth + bias ? zReceiver : blockDepth + bias;
	return averBlockerDepth;
}

float PCSS(sampler2D shadowMap, vec4 coords){
  float currentDepth = coords.z;
  // STEP 1: avgblocker depth
  float averBlocker = findBlocker(shadowMap, coords.xy, currentDepth);
  // STEP 2: penumbra size
  float penumbra = (currentDepth - averBlocker) * LIGHT_WEIGHT / averBlocker;
  // STEP 3: filtering
  float pcssShadow = PCF(shadowMap, vec4(coords.xy, coords.zw), penumbra);
  return pcssShadow;

}

vec3 blinnPhong() {
  vec3 color = texture2D(uSampler, vTextureCoord).rgb;
  color = pow(color, vec3(2.2));

  vec3 ambient = AMBIENT * color;

  vec3 lightDir = normalize(uLightPos);
  vec3 normal = normalize(vNormal);
  float diff = max(dot(lightDir, normal), 0.0);
  vec3 light_atten_coff =
      uLightIntensity / pow(length(uLightPos - vFragPos), 2.0);
  vec3 diffuse = diff * light_atten_coff * color;

  vec3 viewDir = normalize(uCameraPos - vFragPos);
  vec3 halfDir = normalize((lightDir + viewDir));
  float spec = pow(max(dot(halfDir, normal), 0.0), 32.0);
  vec3 specular = uKs * light_atten_coff * spec;

  vec3 radiance = (ambient + diffuse + specular);
  vec3 phongColor = pow(radiance, vec3(1.0 / 2.2));
  return phongColor;
}

void main(void) {

  float visibility = 1.0;
  vec3 shadowCoord = vPositionFromLight.xyz / vPositionFromLight.w;
  shadowCoord = shadowCoord * 0.5 + 0.5;
  //visibility = PCF(uShadowMap, vec4(shadowCoord, 1.0), 1.0);
  visibility = PCSS(uShadowMap, vec4(shadowCoord, 1.0));

  vec3 phongColor = blinnPhong();
  gl_FragColor = vec4(phongColor * visibility + AMBIENT * texture2D(uSampler, vTextureCoord).rgb * (1.0 - visibility), 1.0);
  //gl_FragColor = vec4(visibility * 400.0, 0.0, 0.0, 1.0);
}