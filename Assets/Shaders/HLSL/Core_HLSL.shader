// You can modify the variables in the inspector in Unity
Shader "Custom/Core_HLSL"
{
    Properties
    {
        _FresnelPower ("Fresnel Power", Float) = 3.0
        _FresnelColor ("Fresnel Color", Color) = (0.267, 0.102, 0.749, 1.0)
        _Intensity ("Color Intensity", Float) = 3.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float _FresnelPower;
            float4 _FresnelColor;
            float _Intensity;

            // Struct to hold vertex data input
            struct appdata
            {
                float4 vertex : POSITION; // Vertex position in object space
                float3 normal : NORMAL;   // Vertex normal in object space
            };

            // Struct to hold data passed to the fragment shader
            struct v2f
            {
                float4 pos : SV_POSITION;     // Screen position after vertex transformation
                float3 viewDir : TEXCOORD0;   // View direction vector in world space
                float3 worldNormal : TEXCOORD1; // Normal vector transformed to world space
            };

            // Vertex shader function
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex); // Transform vertex position to clip space

                // Transform normal from object space to world space
                o.worldNormal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));

                // Calculate the world space position of the vertex
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                // Calculate and normalize view direction vector (from vertex to camera)
                o.viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                return o;
            }

            // Fragment shader function
            fixed4 frag (v2f i) : SV_Target
            {
                // Compute the Fresnel effect based on the angle between view direction and surface normal
                float fresnel = pow(1.0 - dot(i.viewDir, i.worldNormal), _FresnelPower * 0.5);

                // Smooth out the Fresnel effect to soften the gradient
                fresnel = smoothstep(0.1, 1.0, fresnel);

                // Define a secondary color for edge blend (pinkish tone)
                float4 pinkishColor = float4(1.0, 0.5, 0.7, 1.0);

                // Blend between the Fresnel color property and the pinkish color based on the Fresnel effect value
                float4 fresnelColor = lerp(_FresnelColor, pinkishColor, fresnel);

                // Slightly blend towards white to add highlights to the edge color
                fresnelColor = lerp(fresnelColor, float4(1.0, 0.8, 0.9, 1.0), fresnel * 0.1);

                // Increase brightness by multiplying with Fresnel intensity and overall intensity
                float4 color = fresnelColor * (fresnel * _Intensity);

                return color; // Output the final color
            }            
            ENDCG
        }
    }
    FallBack "Diffuse"
}