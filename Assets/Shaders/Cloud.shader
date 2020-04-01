// author: Marcus Xie
Shader "Custom/Cloud" {
Properties {
    _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
    _FlowSpeed ("Flow Speed", Range(0.0, 1.0)) = 0.3
    _WriggleSpeed ("Wriggle Speed", Range(0.0, 3.0)) = 1.5
    _WriggleMagnitude ("Wriggle Magnitude", Range(0.0, 1.0)) = 0.2
    _WriggleVertexDivergence ("Wriggle Vertex Divergence", Range(0.0, 20.0)) = 20.0
    _NearClipPlane ("Near Clip Plane", Float) = 0.3
}

SubShader {
    // set just like normal transparent objects
    Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
    LOD 100
    ZWrite Off
    Blend SrcAlpha OneMinusSrcAlpha

    // render both sides
    Cull Off

    Pass {
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            // containing perlin noise generating function cnoise()
            #include "./NoiseShader/ClassicNoise2D.hlsl"

            struct appdata_t {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                fixed3 normal : NORMAL;
                // gpu instancing
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                fixed3 worldNormal : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _FlowSpeed;
            float _WriggleSpeed;
            float _WriggleMagnitude;
            float _WriggleVertexDivergence;
            float _NearClipPlane;

            v2f vert (appdata_t v)
            {
                v2f o;
                // gpu instancing
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex = UnityObjectToClipPos(v.vertex);
                // move the cloud around as a whole
                o.vertex.xy += sin(_Time.y * _FlowSpeed) * 3.0;
                // move every vertex around individually,  and make their movement different from each other, which makes the cloud look like wriggling
                o.vertex.xyz += (sin(_Time.w * _WriggleSpeed + (v.vertex.x + v.vertex.y + v.vertex.z) * _WriggleVertexDivergence) + 1.0) * _WriggleMagnitude;
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldViewDir = _WorldSpaceCameraPos.xyz - worldPos;
                return o;
            }

            fixed procedualTex(fixed2 texcoord)
            {
                // holistic transparency, set to 0.2 to make clouds look less stuffy when looked from outside
                const fixed trasparency = 0.20;
                // to make texcoords vary from the range of [-0.5, 0.5]
                fixed x = texcoord.x - 0.5;
                fixed y = texcoord.y - 0.5;
                // make this piece of cloud dense in the middle and fade out towards the edge.
                // By writting (x * x + y * y) I wanted to represent the radius, but we don't have to be so rigorous so I left out the square-root,
                // and doing square-root is computationally intensive for shaders, by the way.
                fixed attenuation = max(((0.25 - (x * x + y * y)) * 4.0 * trasparency), 0.0);
                // generate perlin noise in real-time, 
                fixed perlinNoise = (cnoise(texcoord * 4.0 + _Time.x * 10.0) + 1) * 0.5;
                //fixed perlinNoise = (cnoise(texcoord * 4.0 + _Time.y) + 1) * 0.5;
                return perlinNoise * attenuation + attenuation * attenuation;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // when this piece of cloud is looked from aside, it looks like a sharp piece, which is not supposed to exist in a real cloud
                // we can let this piece of cloud fade out if it's normal is perpendicular to our view direction
                const float fade = 0.5;
                fixed3 worldNormal = normalize(i.worldNormal);
                float3 worldViewDir = normalize(i.worldViewDir);
                float rim = abs(dot(worldViewDir, worldNormal));
                fixed tmp = step(fade,rim);

                // when it approaches the camera's near clip plane, let it fade out,
                // or the meshes will be sharply cut by the near clip plane
                const half cutFade = 20.0;
                half viewDistance = length(i.worldViewDir);
                fixed cut = smoothstep(_NearClipPlane, _NearClipPlane + cutFade, viewDistance);


                fixed alpha = procedualTex(i.texcoord);
                
                // if the tmp approaches to 1.0, we output alpha, and if the tmp approaches 0.0, we output another term
                // by doing this we can avoid IF operation in shader, which stalls the GPU a lot
                alpha = alpha * tmp + (1.0 - tmp) * lerp(0.0, alpha, ((max(0, (rim - 0.1))) / (fade - 0.1)));
                alpha *= cut;
                return fixed4(1.0, 1.0, 1.0, alpha);
            }
        ENDCG
    }
}

}
