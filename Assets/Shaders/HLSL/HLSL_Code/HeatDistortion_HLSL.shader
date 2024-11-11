// You can modify the variables in the inspector in Unity
Shader "Custom/HeatDistortion_HLSL"
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
        _DistortionAmount("Distortion Amount", Float) = 1.0
        _DistortionScale("Distortion Scale", Float) = 1.0
        _RotationAmount("Rotation Amount", Float) = 0.1
        _TwirlStrength("Twirl Strength", Float) = 0.5
        _Alpha("Alpha", Range(0, 1)) = 1.0
        _EdgeFadeStart("Edge Fade Start", Range(0, 1)) = 0.7
        _EdgeFadeEnd("Edge Fade End", Range(0, 1)) = 1.0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        LOD 200

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float _DistortionAmount;
            float _DistortionScale;
            float _RotationAmount;
            float _TwirlStrength;
            float _Alpha;
            float _EdgeFadeStart;
            float _EdgeFadeEnd;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float2 RotateUV(float2 uv, float angle, float2 center)
            {
                float s = sin(angle);
                float c = cos(angle);
                uv -= center;
                float xnew = uv.x * c - uv.y * s;
                float ynew = uv.x * s + uv.y * c;
                return float2(xnew, ynew) + center;
            }

            float2 TwirlUV(float2 uv, float strength, float2 center)
            {
                float2 offset = uv - center;
                float dist = length(offset);
                float angle = strength * dist;
                return RotateUV(uv, angle, center);
            }

            float4 frag(v2f i) : SV_Target
            {
                // Distortion and rotation
                float angle = _RotationAmount * _Time.y;
                float2 distortedUV = RotateUV(i.uv, angle, float2(0.5, 0.5));

                // Twirl effect
                distortedUV = TwirlUV(distortedUV, _TwirlStrength, float2(0.5, 0.5));

                // Noise and distortion scale
                float noiseValue = frac(sin(dot(distortedUV * _DistortionScale, float2(12.9898, 78.233))) * 43758.5453);
                distortedUV += noiseValue * _DistortionAmount;

                // Sample texture
                float4 col = tex2D(_MainTex, distortedUV);

                // Radial fade based on distance from center (0.5, 0.5)
                float2 center = float2(0.5, 0.5);
                float distFromCenter = length(i.uv - center);
                float edgeFade = saturate((distFromCenter - _EdgeFadeStart) / (_EdgeFadeEnd - _EdgeFadeStart));

                // Apply the edge fade to alpha
                col.a *= (1.0 - edgeFade) * _Alpha;

                return col;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}