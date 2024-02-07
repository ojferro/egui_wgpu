struct VertexOut {
    @location(0) color: vec4<f32>,
    @location(1) norm: vec2<f32>,
    @builtin(position) position: vec4<f32>,
};

struct Uniforms {
    x_range: vec2<f32>,
    y_range: vec2<f32>,
};

@group(0) @binding(0)
var<uniform> uniforms: Uniforms;

let LINE_WIDTH: f32 = 0.002;
let FEATHER: f32 = 0.50;

fn permute4(x: vec4<f32>) -> vec4<f32> { return ((x * 34. + 1.) * x) % vec4<f32>(289.); }
fn fade2(t: vec2<f32>) -> vec2<f32> { return t * t * t * (t * (t * 6. - 15.) + 10.); }

fn perlinNoise2(P: vec2<f32>) -> f32 {
    var Pi: vec4<f32> = floor(P.xyxy) + vec4<f32>(0., 0., 1., 1.);
    let Pf = fract(P.xyxy) - vec4<f32>(0., 0., 1., 1.);
    Pi = Pi % vec4<f32>(289.); // To avoid truncation effects in permutation
    let ix = Pi.xzxz;
    let iy = Pi.yyww;
    let fx = Pf.xzxz;
    let fy = Pf.yyww;
    let i = permute4(permute4(ix) + iy);
    var gx: vec4<f32> = 2. * fract(i * 0.0243902439) - 1.; // 1/41 = 0.024...
    let gy = abs(gx) - 0.5;
    let tx = floor(gx + 0.5);
    gx = gx - tx;
    var g00: vec2<f32> = vec2<f32>(gx.x, gy.x);
    var g10: vec2<f32> = vec2<f32>(gx.y, gy.y);
    var g01: vec2<f32> = vec2<f32>(gx.z, gy.z);
    var g11: vec2<f32> = vec2<f32>(gx.w, gy.w);
    let norm = 1.79284291400159 - 0.85373472095314 *
        vec4<f32>(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));
    g00 = g00 * norm.x;
    g01 = g01 * norm.y;
    g10 = g10 * norm.z;
    g11 = g11 * norm.w;
    let n00 = dot(g00, vec2<f32>(fx.x, fy.x));
    let n10 = dot(g10, vec2<f32>(fx.y, fy.y));
    let n01 = dot(g01, vec2<f32>(fx.z, fy.z));
    let n11 = dot(g11, vec2<f32>(fx.w, fy.w));
    let fade_xy = fade2(Pf.xy);
    let n_x = mix(vec2<f32>(n00, n01), vec2<f32>(n10, n11), vec2<f32>(fade_xy.x));
    let n_xy = mix(n_x.x, n_x.y, fade_xy.y);
    return 2.3 * n_xy;
}

@vertex
fn vs_main(@location(0) position: vec2<f32>,
           @location(1) norm: vec2<f32>,
           @location(2) color: vec4<f32>) -> VertexOut {
    var out: VertexOut;

    let width = (uniforms.x_range[1] - uniforms.x_range[0]);
    let height = (uniforms.y_range[1] - uniforms.y_range[0]);

    // Convert from data space (x0..x1, y0..y1) to view space (-1..1, -1..1).
    let x = mix(-1.0, 1.0, (position.x - uniforms.x_range[0]) / width);
    let y = mix(-1.0, 1.0, (position.y - uniforms.y_range[0]) / height);

    // // Move the point along the normal by LINE_WIDTH. If the normals are
    // // provided such that they are sequentially flipped, this forms a triangle
    // // strip the width of the line.
    let delta = vec4(LINE_WIDTH * norm, 0.0, 0.0);

    // out.color = color;
    // out.norm = norm;
    // out.position = vec4<f32>(x, y, 0.0, 1.0) + delta;

    let intensity = perlinNoise2(vec2<f32>(x,y));
    let intensity = 255.0;
    out.color = vec4<f32>(intensity, intensity, intensity, 1.0);
    out.norm = norm;
    out.position = vec4<f32>(x, y, 0.0, 1.0) + delta;

    return out;
}

@fragment
fn fs_main(in: VertexOut) -> @location(0) vec4<f32> {
    // At the edge of the line (final FEATHER % width) feather out the alpha
    // channel to zero.
    // let alpha = smoothstep(0.0, 1.0, (1.0 - length(in.norm)) / FEATHER);
    vec2
    
}