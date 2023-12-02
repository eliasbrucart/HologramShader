// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/Hologram"
{
    Properties
    {   
        //General
        _Brightness("Brightness", Range(0.1, 6.0)) = 3.0
        _Alpha("Alpha", Range(0.0, 1.0)) = 1.0
        _Direction("Direction", Vector) = (0,1,0,0)
        //Color principal
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,0,0,1)
        //Valor del grosor de las scanlines
        _Bias("Bias", Float) = 0
        //Configuracion de las scanlines
        _ScanningFrequency("Scanning Frequency", Float) = 100
        _ScanningSpeed("Scanning Speed", Float) = 100
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent"} //Configuraciones para el shader
        ZWrite Off
        LOD 100
        Blend SrcAlpha One
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma shader_feature _SCAN_ON //shader feature para usar compilacion condicional
            #pragma shader_feature _GLOW_ON
            #pragma shader_feature _GLITCH_ON
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata //vertice original
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f //Este struct representa a un vertice, vertice que vamos a modificar con la ayuda del vertice original
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(2)
                float4 vertex : SV_POSITION;
                float4 objVertex : TEXCOORD1;
            };

            float _Brightness;
            float _Alpha;
            float4 _Direction;
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Bias;
            float _ScanningFrequency;
            float _ScanningSpeed;

            v2f vert (appdata v) //vertice original como input de vertex shader
            {
                v2f o;
                o.objVertex = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o; //vertice procesado que retornaremos para pasarlo al fragment
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                
                col = _Color * max(0, cos(i.objVertex.y * _ScanningFrequency + _Time.x * _ScanningSpeed) + _Bias); //Bias es el valor de grosor de las scan lines
                col *= 1 - max(0, cos(i.objVertex.x * _ScanningFrequency + _Time.x * _ScanningSpeed) + 0.9); //Crear variable para este valor de Bias en X
                col *= 1 - max(0, cos(i.objVertex.z * _ScanningFrequency + _Time.x * _ScanningSpeed) + 0.9); //Crear variable para este valor de Bias en Z

                col.a = col.a + _Alpha; //Aplicamos alpha al canal Alpha del color del fragmento

                col.rgb *= _Brightness;

                return col; //El output del fragment shader es el color resultante de cada fragmento
            }
            ENDCG
        }
    }
}
