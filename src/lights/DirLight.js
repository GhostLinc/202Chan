
class DirLight {
    /**
     * Creates an instance of DirLight.
     * @param {float} lightIntensity  The intensity of the DirLight.
     * @param {vec3f} lightColor The color of the DirLight.
     * @memberof DirLight
     */
    //  * @param {vec3f} lightDir The color of the DirLight.
    constructor(lightIntensity, lightColor) {
        this.mesh = Mesh.cube();
        this.mat = new EmissiveMaterial(lightIntensity, lightColor);
    }
}