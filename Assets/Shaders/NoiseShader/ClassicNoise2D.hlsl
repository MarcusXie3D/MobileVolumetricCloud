//
// Noise Shader Library for Unity - https://github.com/keijiro/NoiseShader
//
// Original work (webgl-noise) Copyright (C) 2011 Stefan Gustavson
// Translation and modification was made by Keijiro Takahashi.
//
// This shader is based on the webgl-noise GLSL shader. For further details
// of the original shader, please see the following description from the
// original source code.
//

//
// GLSL textureless classic 2D noise "cnoise",
// with an RSL-style periodic variant "pnoise".
// Author:  Stefan Gustavson (stefan.gustavson@liu.se)
// Version: 2011-08-22
//
// Many thanks to Ian McEwan of Ashima Arts for the
// ideas for permutation and gradient selection.
//
// Copyright (c) 2011 Stefan Gustavson. All rights reserved.
// Distributed under the MIT license. See LICENSE file.
// https://github.com/ashima/webgl-noise
//

fixed4 mod(fixed4 x, fixed4 y)
{
  return x - y * floor(x / y);
}

fixed4 mod289(fixed4 x)
{
  return x - floor(x / 289.0) * 289.0;
}

fixed4 permute(fixed4 x)
{
  return mod289(((x*34.0)+1.0)*x);
}

fixed4 taylorInvSqrt(fixed4 r)
{
  return (fixed4)1.79284291400159 - r * 0.85373472095314;
}

fixed2 fade(fixed2 t) {
  return t*t*t*(t*(t*6.0-15.0)+10.0);
}

// Classic Perlin noise
fixed cnoise(fixed2 P)
{
  fixed4 Pi = floor(P.xyxy) + fixed4(0.0, 0.0, 1.0, 1.0);
  fixed4 Pf = frac (P.xyxy) - fixed4(0.0, 0.0, 1.0, 1.0);
  Pi = mod289(Pi); // To avoid truncation effects in permutation
  fixed4 ix = Pi.xzxz;
  fixed4 iy = Pi.yyww;
  fixed4 fx = Pf.xzxz;
  fixed4 fy = Pf.yyww;

  fixed4 i = permute(permute(ix) + iy);

  fixed4 gx = frac(i / 41.0) * 2.0 - 1.0 ;
  fixed4 gy = abs(gx) - 0.5 ;
  fixed4 tx = floor(gx + 0.5);
  gx = gx - tx;

  fixed2 g00 = fixed2(gx.x,gy.x);
  fixed2 g10 = fixed2(gx.y,gy.y);
  fixed2 g01 = fixed2(gx.z,gy.z);
  fixed2 g11 = fixed2(gx.w,gy.w);

  fixed4 norm = taylorInvSqrt(fixed4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
  g00 *= norm.x;
  g01 *= norm.y;
  g10 *= norm.z;
  g11 *= norm.w;

  fixed n00 = dot(g00, fixed2(fx.x, fy.x));
  fixed n10 = dot(g10, fixed2(fx.y, fy.y));
  fixed n01 = dot(g01, fixed2(fx.z, fy.z));
  fixed n11 = dot(g11, fixed2(fx.w, fy.w));

  fixed2 fade_xy = fade(Pf.xy);
  fixed2 n_x = lerp(fixed2(n00, n01), fixed2(n10, n11), fade_xy.x);
  fixed n_xy = lerp(n_x.x, n_x.y, fade_xy.y);
  return 2.3 * n_xy;
}

// Classic Perlin noise, periodic variant
fixed pnoise(fixed2 P, fixed2 rep)
{
  fixed4 Pi = floor(P.xyxy) + fixed4(0.0, 0.0, 1.0, 1.0);
  fixed4 Pf = frac (P.xyxy) - fixed4(0.0, 0.0, 1.0, 1.0);
  Pi = mod(Pi, rep.xyxy); // To create noise with explicit period
  Pi = mod289(Pi);        // To avoid truncation effects in permutation
  fixed4 ix = Pi.xzxz;
  fixed4 iy = Pi.yyww;
  fixed4 fx = Pf.xzxz;
  fixed4 fy = Pf.yyww;

  fixed4 i = permute(permute(ix) + iy);

  fixed4 gx = frac(i / 41.0) * 2.0 - 1.0 ;
  fixed4 gy = abs(gx) - 0.5 ;
  fixed4 tx = floor(gx + 0.5);
  gx = gx - tx;

  fixed2 g00 = fixed2(gx.x,gy.x);
  fixed2 g10 = fixed2(gx.y,gy.y);
  fixed2 g01 = fixed2(gx.z,gy.z);
  fixed2 g11 = fixed2(gx.w,gy.w);

  fixed4 norm = taylorInvSqrt(fixed4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
  g00 *= norm.x;
  g01 *= norm.y;
  g10 *= norm.z;
  g11 *= norm.w;

  fixed n00 = dot(g00, fixed2(fx.x, fy.x));
  fixed n10 = dot(g10, fixed2(fx.y, fy.y));
  fixed n01 = dot(g01, fixed2(fx.z, fy.z));
  fixed n11 = dot(g11, fixed2(fx.w, fy.w));

  fixed2 fade_xy = fade(Pf.xy);
  fixed2 n_x = lerp(fixed2(n00, n01), fixed2(n10, n11), fade_xy.x);
  fixed n_xy = lerp(n_x.x, n_x.y, fade_xy.y);
  return 2.3 * n_xy;
}
