import {vec3} from 'gl-matrix';
import Stats from 'stats-js';
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

import lambertVertSource from './shaders/lambert-vert.glsl?raw';
import lambertFragSource from './shaders/lambert-frag.glsl?raw';
import backgroundVertSource from './shaders/background-vert.glsl?raw';
import backgroundFragSource from './shaders/background-frag.glsl?raw';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const defaultParams = {
    tesselations: 5,
    noiseStrength: 0.2,
    tailLength: 1.2,
    animationSpeed: 1.0,
    octaves: 6,
  };
const controls = {
  ...defaultParams,
  // tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially
  'Reset': () =>{
    Object.assign(controls, defaultParams);
  },
};

let icosphere: Icosphere;
let square: Square;
let prevTesselations: number = 5;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1).listen();
  gui.add(controls, 'noiseStrength', 0.0, 1.0).step(0.01).listen();
  gui.add(controls, 'tailLength', 0.0, 5.0).step(0.01).listen();
  gui.add(controls, 'animationSpeed', 0.0, 20.0).step(0.01).listen();
  gui.add(controls, 'octaves', 1, 12).step(1).listen();
  gui.add(controls, 'Load Scene');
  gui.add(controls, 'Reset');

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, lambertVertSource),
    new Shader(gl.FRAGMENT_SHADER, lambertFragSource),
  ]);

  const background = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, backgroundVertSource),
    new Shader(gl.FRAGMENT_SHADER, backgroundFragSource),
  ]);

  let previousTime = performance.now();
  let animationTime = 0.0;

  // This function will be called every frame
  function tick() {
    const tnow = performance.now();
    const deltaSeconds = (tnow - previousTime) / 1000.0;
    previousTime = tnow;
    animationTime += deltaSeconds*controls.animationSpeed;
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }

    gl.disable(gl.DEPTH_TEST);
    gl.depthMask(false);
    background.draw(square);


    gl.depthMask(true);
    gl.enable(gl.DEPTH_TEST);
    lambert.setTime(animationTime);
    lambert.setFireballParameters(controls.noiseStrength, controls.tailLength, controls.octaves);
    renderer.render(camera, lambert, [
      icosphere,
      // square,
    ]);
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
