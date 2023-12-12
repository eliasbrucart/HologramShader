Shader "Unlit/ConeLight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex mainVS
            #pragma fragment mainPS
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct VS_INPUT
            {
                float4 Position : POSITION;
            };

            struct VS_OUTPUT
            {
                float4 Position : POSITION;
            };

            VS_OUTPUT mainVS(VS_INPUT input)
            {
                VS_OUTPUT output;
                output.Position = input.Position;
                return output;
            }

            // Pixel Shader
            struct PS_INPUT
            {
                float4 Position : POSITION;
            }

            float4 mainPS(PS_INPUT input) : SV_TARGET
            {
                // Define holographic color
                float4 hologramColor = float4(0.0, 0.8, 1.0, 1.0); // Adjust as needed

                // Calculate distance from the center of the hologram
                float distance = length(input.Position.xy);

                // Define the radius of the light cone
                float coneRadius = 0.5;

                // Soft edge for the light cone
                float softEdge = 0.1;

                // Calculate falloff based on distance and soft edge
                float falloff = saturate((coneRadius - distance) / softEdge);

                // Combine holographic color with falloff for the light cone
                float4 resultColor = hologramColor * falloff;

                return resultColor;
            }

            technique Render
            {
                pass P0
                {
                    VertexShader = compile vs_5_0 mainVS();
                    PixelShader = compile ps_5_0 mainPS();
                }
            }

            
            ENDCG
        }
    }
}
