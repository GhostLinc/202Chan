class PhongMaterial extends Material{
    // /**
    // * Create Phong Material
    // * @param {vec3f} color The material color 
    // * @param {Texture} colorMap The texture object of the material
    // * @param {vec3f} specluar specluar the material specluar
    // * @param {float} pointLightInstensity The light intensity
    // * @param {float} dirLightIntensity The light intensity
    // * @param {vec3f} dirLightDirection The direction of light intensity
    // * @param {vec3f} dirLightColor The color of light intensity
    // * @memberof PhongMaterial
    // **/
    SetDirLightIntensity(dirLightIntensity){

    }
    constructor(color, colorMap, specluar, pointLightInstensity, dirLightIntensity, dirLightDirection, dirLightColor){
        let textureSample = 0;
        if(colorMap != null){
            let textureSample = 1;
            super({
                'uSampler'              : {type : 'texture', value : colorMap},
                'uTextureSample'        : {type : '1i', value  : textureSample},
                'uPointLightIntensity'  : {type : '1f', value  : pointLightInstensity},
                'uDirLightIntensity'    : {type : '1f', value  : dirLightIntensity},
                'uKd'                   : {type : '3fv', value : color},
                'uKs'                   : {type : '3fv', value : specluar},
                'uDirLightDirection'    : {type : '3fv', value : dirLightDirection}, 
                'uDirLightColor'        : {type : '3fv', value : dirLightColor}
            }, [], PhongVertexShader, PhongFragmentShader);
        }
        else{
            super({
                'uTextureSample'        : {type : '1i', value : textureSample},
                'uPointLightIntensity'  : {type : '1f', value : pointLightInstensity},
                'uDirLightIntensity'    : {type : '1f', value : dirLightIntensity},
                'uKd'                   : {type : '3fv', value : color},
                'uKs'                   : {type : '3fv', value : specluar},
                'uDirLightDirection'    : {type : '3fv', value : dirLightDirection}, 
                'uDirLightColor'        : {type : '3fv', value : dirLightColor}
            }, [], PhongVertexShader, PhongFragmentShader);
        }
    }
}