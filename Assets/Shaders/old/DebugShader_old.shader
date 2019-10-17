// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_CameraToWorld' with 'unity_CameraToWorld'

// Upgrade NOTE: commented out 'float4x4 _CameraToWorld', a built-in variable

// Upgrade NOTE: commented out 'float4x4 _CameraToWorld', a built-in variable

Shader "Hidden/DebugShader"
{
    // Propriedades visiveis no editor.
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader
    {
        Pass
        {
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma target 4.0

                #include "UnityCG.cginc"
                #include "UnityGBuffer.cginc"
                #include "UnityDeferredLibrary.cginc"
                #include "UnityShaderVariables.cginc"

                sampler2D _MainTex;
                sampler2D _CameraGBufferTexture0;
                sampler2D _CameraGBufferTexture1;
                sampler2D _CameraGBufferTexture2;
                sampler2D _CameraDepthNormalsTexture;
                sampler2D noiseTexture;
                float3 samples[64];
                float4x4 projection;
                float4x4 invProjection;
                float4x4 viewMatrix;
                float radius = 0.1;

                // Modo de exibição de debug, 0: debug desligado.
                int debugMode = 0;


                struct appdata
                {
                    float4 position : POSITION;
                    float2 uv : TEXCOORD0;
                    float4 scrPos : TEXCOORD1;
                    float3 viewPos : TEXCOORD2;
                    fixed4 color : COLOR;
                };


                // Struct com as uniforms que seram passadas do vertex
                // para o fragment shader.
                struct v2f
                {
                    float4 position : SV_POSITION;
                    float2 uv : TEXCOORD0;
                    float4 scrPos : TEXCOORD1;
                    float3 viewPos : TEXCOORD2;
                    fixed4 color : COLOR;
                };


                // Vertex Shader.
                v2f vert (appdata vertex)
                {
                    v2f output;

                    output.color = vertex.position;

                    // Trasnforma os vertices para o espaço de clipping.
                    output.position = UnityObjectToClipPos(vertex.position);

                    // Obtem as posições nas coordenadas de tela.
                    
                    //output.scrPos = float4(UnityWorldSpaceViewDir(vertex.position), 1);
                    //output.scrPos = float4(UnityWorldToClipPos(vertex.position));

                    output.viewPos = UnityObjectToViewPos(vertex.position);

                    output.scrPos = ComputeScreenPos(UnityViewToClipPos(float4(output.viewPos, 1)));

                    // Obtem as coordenadas uv de textura do vertice.
                    output.uv = vertex.uv;

                    //output.ray = mul (UNITY_MATRIX_MV, vertex.position).xyz * float3(-1,-1,1);
                    //output.ray = lerp(output.ray, vertex.uv, vertex.uv.z != 0);

                    // Retorna o objeto.
                    return output;
                }
                

                // Fragment Shader.
                fixed4 frag (v2f input) : SV_Target
                {
                    float2 noiseScale = float2(800.0/4.0, 600.0/4.0);
                    int kernelSize = 64;
                    float occlusion = 0.0;

                    // Obtem as texturas do g-buffer.
                    float3 g_albedo = tex2D(_CameraGBufferTexture0, input.uv).rgb;
                    float3 g_specularTint = tex2D(_CameraGBufferTexture1, input.uv).rgb;
                    float3 g_smoothness = tex2D(_CameraGBufferTexture1, input.uv).a;
                    float3 g_normal = (tex2D(_CameraGBufferTexture2, input.uv).rgb);

                    half4 col = half4(0,0,0,0);
                    
                    
                    float4 depthNormal;
                    float3 normal;
                    float depth;
                    depthNormal = tex2D(_CameraDepthNormalsTexture, input.uv);
                    DecodeDepthNormal(depthNormal, depth, normal);
                    //depth = Linear01Depth(depth);
                    //normal = g_normal;



                    //normal = normal*2.0 - 1.0;


                    normal = normalize(normal);



                    //normal = mul(viewMatrix, float4(normal,0)).xyz;


                    depth = LinearEyeDepth(tex2D(_CameraDepthTexture, input.scrPos).r);


                    float3 randomVec = normalize(tex2D(noiseTexture, input.uv*noiseScale).rgb);
                    //randomVec = float3(1,1,1);

                    //float4 viewPosH = mul(invProjection, float4(input.viewPos.xy*2-1, depth, 1.0));
                    //float3 viewPos = viewPosH.xyz / viewPosH.w;

                    //float3 viewPos = (input.viewPos)/depth;
                    float3 viewPos = (input.viewPos*2-1)/depth;
                    viewPos = input.viewPos;
                    //viewPos.z = depth;
                    


                    // Obtem a textura de profundidade.
                    //float depthValue = Linear01Depth (tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(input.scrPos)).r);

                    //input.scrPos = input.position;

                    
                    // Criar a matriz para transformar de target-space para view-space
                    // utilizando o processo de Gramm-Schmidt.
                    float3 tangent = normalize(randomVec - normal * dot(randomVec, normal));
                    float3 bitangent = normalize(cross(normal, tangent));
                    float3x3 TBN = float3x3(tangent, bitangent, normal);
                    

                    float4 offset = float4(0,0,0,1);
                    float sampleDepth = 0;
                    float3 sample = float3(0,0,0);
                    float4 coord;
                    
                    for(int k = 0; k < 64; k++)
                    {
                        //sample = samples[k];
                        sample = mul(TBN, samples[k]);
                        sample = (input.viewPos) + (sample * radius);
                        offset = (float4(sample, 1.0));
                        //offset = mul(projection, offset);
                        //offset = UnityViewToClipPos(offset);
                        //offset = ComputeScreenPos(offset);
                        //offset = ComputeScreenPos(offset);
                        //offset = ComputeScreenPos(mul(UNITY_MATRIX_P, offset));
                        //offset.xyz = offset.xyz / offset.w;
                        //offset.xyz = offset.xyz * 0.5 + 0.5;
                        
                        float3 sampleNormal;
                        //float sampleDepthNormal = tex2D(_CameraDepthNormalsTexture, input.uv);
                        //DecodeDepthNormal(sampleDepthNormal, sampleDepth, sampleNormal);
                        //sampleDepthNormal = Linear01Depth(sampleDepthNormal);

                        sampleDepth = LinearEyeDepth(tex2D(_CameraDepthTexture, offset.xy).r);

                        if(sampleDepth >= ( (depth)) + 0.025)// +  (mul(TBN, samples[k]).z)* radius
                        {
                            occlusion += 0.01;
                        }
                    }

                    
                    if (debugMode == 0)
                    {
                        col = tex2D(_MainTex, input.uv) + occlusion;
                    }
                    else if (debugMode == 1)
                    {
                        col.r = depth;
                        col.g = depth;
                        col.b = depth;
                        col.a = 1;
                    }
                    else if(debugMode == 2)
                    {
                        col = half4(g_normal, 1);
                    }
                    else if (debugMode == 3)
                    {
                        col = half4(g_albedo, 1);
                    }
                    else if(debugMode == 4)
                    {
                        col.r = input.scrPos.r;
                        col.g = input.scrPos.g;
                        col.b = input.scrPos.b;
                        col.a = 1;
                    }
                    else if(debugMode == 5)
                    {
                        col = half4(randomVec, 1);
                    }
                    else if(debugMode == 6)
                    {
                        col = half4(sampleDepth, sampleDepth, sampleDepth, 1);
                    }
                    else if(debugMode == 7)
                    {
                        col = half4(normal, 1);
                    }
                    else if(debugMode == 8)
                    {
                        col = half4(offset.xy,0, 1);
                    }
                    else if(debugMode == 9)
                    {
                        col = half4(occlusion, occlusion, occlusion, 1);
                    }
                    else if(debugMode == 10)
                    {
                        //col = half4(sample, 1);
                        col = half4(sample, 1);
                    }
                    else if(debugMode == 11)
                    {
                        col = half4(viewPos.xyz, 1);
                    }
                    
                    return col;
                }
            ENDCG
        }
    }
}
