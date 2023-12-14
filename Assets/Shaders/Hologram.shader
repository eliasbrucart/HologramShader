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
        //Valor del grosor de las scanlines para type 2
        _Bias("Bias", Range(0, 1)) = 0.5
        //Configuracion de las scanlines
        _ScanningFrequency("Scanning Frequency", Float) = 100
        _ScanningSpeed("Scanning Speed", Range(0, 50)) = 5
        _ScanningBrightness("Scanning Brightness", Range(0.0, 1.0)) = 0.5
        _ScanHeight("Scan Height", Range(0.0, 1.0)) = 0.5
        //Configuracion de Glitch
        _GlitchSpeed("Glitch Speed", Range(0, 50)) = 1.0
        _GlitchIntensity("Glitch Intensity", Float) = 0
        _BlurGlitch("Blur Glitch", Range(0, 100)) = 1.0
        _GlitchFrequency("Glitch Frequency", Range(0, 5)) = 5.0
        _TimeInGlitch("Time Glitch", Range(0, 1)) = 0.99

        //Glow
        _GlowTiling("Glow Tiling", Range(0,1)) = 0.5
        _GlowSpeed("Glow Speed", Range(0,1)) = 0.5

        //Flicker Texture
        _FlickerTexture("Flicker texture", 2D) = "white"{}
        _FlickerSpeed("Flicker Speed", Range(0, 100)) = 1.0

        //Edge
        _EdgeColor("Edge Color", Color) = (1,1,1,1)
        _EdgePower("Edge Power", Range(0.0, 10)) = 5.0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent"} //Tags
        //Configuraciones para el shader
        ZWrite Off //depth buffer apagado para hacer el efecto semitransparente
        LOD 100 //Nivel de detalle
        Blend SrcAlpha One //Determina como es la salida del canal alpha del fragment
        Cull Off //Determina que poligonos se renderizan segun la camara, apagado.

        Pass
        {
            CGPROGRAM
            #pragma shader_feature _SCAN_ON //shader feature para usar compilacion condicional
            #pragma shader_feature _GLOW_ON
            #pragma shader_feature _GLITCH_ON
            #pragma shader_feature _EDGE_ON
            #pragma shader_feature _SHAPE_1_ON
            #pragma shader_feature _SHAPE_2_ON
            #pragma vertex vert //declaramos vertex shader
            #pragma fragment frag //declaramos fragment shader
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
                float3 viewDir : TEXCOORD2;
                float3 worldNormal : NORMAL;
            };

            float _Brightness;
            float _Alpha;
            float4 _Direction;
            fixed4 _Color;
            sampler2D _MainTex;
            sampler2D _FlickerTexture;
            float _FlickerSpeed;
            float4 _MainTex_ST;
            float _Bias;
            float _ScanningFrequency;
            float _ScanningSpeed;
            float _ScanningBrightness;
            float _ScanHeight;
            float _GlitchSpeed;
            float _GlitchIntensity;
            float _BlurGlitch;
            float _GlitchFrequency;
            float _TimeInGlitch;
            float _GlowTiling;
            float _GlowSpeed;
            fixed4 _EdgeColor;
            float _EdgePower;

            v2f vert (appdata v) //vertice original como input de vertex shader
            {
                v2f o;
                
                const float speedInY = 2.0;
                const float glitch = 0.5;
                #ifdef _GLITCH_ON
                    v.vertex.x += _GlitchIntensity * (step(glitch, sin(_Time.y * speedInY + v.vertex.y * _BlurGlitch)) * step(_TimeInGlitch, sin(_Time.y * _GlitchSpeed * _GlitchFrequency)));
                    //depende de los valores que le pases a step tiene distintos resultados
                #endif

                o.objVertex = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //UNITY_TRANSFER_FOG(o,o.vertex);
                return o; //vertice procesado que retornaremos para pasarlo al fragment
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                //Se utiliza fixed para colores normales que se almacenan en texturas
                //se usa para operaciones sencillas
                //sampleamos la textura original del modelo para agregarle los efectos

                //                                                                        w          cantidad de scanlines (revisar)
                half directionVertex = (dot(i.objVertex, normalize(float4(_Direction.xyz, 1.0)))); //half es un float con menos precision
                //Se usa para dar una mejor performance al shader para valores que no requieren tanta precision.
                //DirectionVertex no tiene que ser tan preciso
                //Genera un vector resultante para la direccion del vertice

                //Scanlines
                float scan = 0.0;
                #ifdef _SCAN_ON
                    scan = step(frac(directionVertex * _ScanningFrequency + _Time.y * _ScanningSpeed), _ScanHeight) * _ScanningBrightness; //Este valor representa el brillo de las scanlines
                    //Generamos las scanlines, setp function genera la linea y la posiciona
                #endif

                //glow
                float glow = 0;
                #ifdef _GLOW_ON
                    glow = frac(directionVertex * _GlowTiling - _Time.y * _GlowSpeed);
                    //Se fracciona el numero resultante para generar el glow, como se va a usar en un uv, el numero entero lo ignora, deja los numero detras de la coma.
                #endif

                //Flicker texture
                fixed4 flicker = tex2D(_FlickerTexture, _Time * _FlickerSpeed);
                //Sampleamos una textura que le aplicaremos al fragmento para generar el efecto de parpadeo

                //Edge 
                fixed4 edgeColor = (0,0,0,0);
                #ifdef _EDGE_ON
                    half edge = 1.0-saturate(dot(i.viewDir, i.worldNormal)); //saturamos el vector para que el borde tenga mas color
                    edgeColor = _EdgeColor * pow(edge, _EdgePower); //Le damos mas potencia al color del borde.
                #endif

                //col = _Color * max(0, cos(i.objVertex.y * _ScanningFrequency + _Time.x * _ScanningSpeed) + _Bias); //Bias es el valor de grosor de las scan lines
                //col *= 1 - max(0, cos(i.objVertex.x * _ScanningFrequency + _Time.x * _ScanningSpeed) + 1.9); //Crear variable para este valor de Bias en X
                //col *= 1 - max(0, cos(i.objVertex.z * _ScanningFrequency + _Time.x * _ScanningSpeed) + 0.9); //Crear variable para este valor de Bias en Z
                float glowMultiplier = 1.0;

                #ifdef _SHAPE_1_ON
                    col = col * _Color + (glow * glowMultiplier * _Color) + edgeColor;
                    col.a = col.a * _Alpha * (scan) * flicker; //Aplicamos alpha al canal Alpha del color del fragmento
                #endif

                //Otras formas
                const float _Bias1 = 1.9;
                const float _Bias2 = 0.9;
                #ifdef _SHAPE_2_ON
                    #ifdef _SCAN_ON
                        col = _Color * max(0, cos(i.objVertex.y * _ScanningFrequency + _Time.y * _ScanningSpeed) + _Bias); //Bias es el valor de grosor de las scan lines tipo 2
                        col *= max(0, cos(i.objVertex.x * _ScanningFrequency + _Time.x * _ScanningSpeed) + _Bias1);
                        col *= max(0, cos(i.objVertex.z * _ScanningFrequency + _Time.z * _ScanningSpeed) + _Bias2);
                        //Devuelve el maximo entre dos valores. Se usa para generar el fragmento de las shape tipo 2
                        col += (glow * glowMultiplier * _Color);
                        col.a = col.a * _Alpha * flicker;
                    #endif
                    //col.a = col.a * _Alpha * (shape) * flicker;
                    //col = col * _Color + (glow * glowMultiplier * _Color) + shape;
                #endif

                //col = col * _Color + (glow * glowMultiplier * _Color);

                col.rgb *= _Brightness;

                return col; //El output del fragment shader es el color resultante de cada fragmento
            }
            ENDCG
        }
    }
    CustomEditor "HologramShaderUI"
}
