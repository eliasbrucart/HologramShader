Shader "Custom/Hologram_3"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Color("Tint", Color) = (1, 1, 1, 1)
        _Speed("Rotation Speed", Range(0, 10)) = 1.0
        _Intensity("Intensity", Range(0, 1)) = 0.5
        _EdgeIntensity("Edge Intensity", Range(0, 1)) = 0.3
        _EdgeWidth("Edge Width", Range(0, 0.5)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass{
            CGPROGRAM
            #pragma vertex vert
        #pragma fragment frag
        #include "UnityCG.cginc"

            // Shader properties
            sampler2D _MainTex;
            float4 _Color;
            float _Speed;
            float _Intensity;
            float _EdgeIntensity;
            float _EdgeWidth;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float2 screenPos : TEXCOORD1;
            };

            // Vertex shader
            v2f vert(appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            // Fragment shader
            fixed4 frag(v2f i) : SV_Target {
                // Calculate hologram color with intensity
                fixed4 hologramColor = _Color * _Intensity;

            // Offset the UV to make the texture scroll over time
            float2 offset = float2(_Speed * _Time.y, _Speed * _Time.x);
            float2 uv = i.uv + offset;

            // Sample the hologram texture and apply color
            fixed4 texColor = tex2D(_MainTex, uv) * hologramColor;

            // Calculate distance to the edge
            float2 center = 0.5 * _ScreenParams.zw;
            float distToEdge = length(i.screenPos - center) / length(center);

            // Apply edge glow effect
            float edgeGlow = smoothstep(_EdgeWidth, 0, distToEdge);
            fixed4 edgeColor = _Color * _EdgeIntensity * edgeGlow;

            // Combine the hologram color with the edge glow
            fixed4 finalColor = texColor + edgeColor;

            return finalColor;
        }
            ENDCG
        }

    }
    FallBack "Diffuse"
}
