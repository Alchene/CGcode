Shader "VS/Lambert/01"
{
	Properties {
        _Liang ("Liang", Range(0, 90)) = 5
        _Frenal ("Frenal", Range(0, 50)) =5
        _Color_Lambert ("Color_Lambert", Color) = (0.9338235,0,0,1)
        _AO_Col1 ("AO_Col1", Color) = (1,0.9310344,0,1)
        _AO_Col2 ("AO_Col2", Color) = (0,1,0.1724138,1)
        _AO_Col3 ("AO_Col3", Color) = (0,0.2965517,1,1)
        _Light_Col ("Light_Col", Color) = (1,1,1,1)
        _AO_TEX ("AO_TEX", 2D) = "white" {}
        _AO ("AO", Range(0, 1)) = 0.3052947
		_NormalMap ("Normal", 2D) = "bump" {}
        _BaseMap ("TEX", 2D) = "white" {}
        _SSS ("SSS", 2D) = "white" {}
        _SSS1 ("sss", Range(0, 3)) = 1
        _Diff ("TEX1", Range(0, 5)) = 1
    }   
    SubShader {
		
        Tags {
            "RenderType"="Opaque"  
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
			#include "AutoLight.cginc"
            #include "Lighting.cginc"
            #pragma multi_compile_fwdbase_fullshadows
			#pragma only_renderers d3d9 d3d11 glcore gles gles3 metal d3d11_9x xboxone ps4 psp2 n3ds wiiu 
            #pragma target 3.0
			//放入参数
			uniform float _Liang;
			uniform sampler2D _NormalMap;
            uniform sampler2D _BaseMap;uniform float4 _BaseMap_ST;
            uniform sampler2D _AO_TEX;uniform float4 _AO_TEX_ST;
            uniform sampler2D _SSS;uniform float4 _SSS_ST;
			uniform float4 _Color_Lambert;                             //置入贴图
            uniform float4 _AO_Col1;
            uniform float4 _AO_Col2;
            uniform float4 _AO_Col3;
            uniform float _AO;
            uniform float _Diff;
            uniform float _SSS1;
            uniform float _Frenal;
           //令Input Vertrx Position 输入结构体
            struct VertexInput   {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 uv : TEXCOORD0;                    //uv
				
            };
            //令Output 
			// 模型顶点信息换算而来的顶点屏幕位置
            struct VertexOutput   {
                float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				float4 posWS : TEXCOORD1;
				float3 nDir : TEXCOORD2;
                float3 tDir : TEXCOORD4;
                float3 bDir : TEXCOORD5;
            };
			//输入结构>>顶点shader>>>输出结构
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;            //新建一个输出结构
				o.uv0 = v.uv;
                o.pos = UnityObjectToClipPos( v.vertex );     //UnityObject到裁剪空间
				o.nDir = UnityObjectToWorldNormal(v.normal);//UnityObject到世界法线
				o.posWS = mul(unity_ObjectToWorld, v.vertex); //法线方向
				//切线方向
				o.tDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
				//副切线方向
                o.bDir = normalize(cross(o.nDir, o.tDir) * v.tangent.w);
                return o;                                     //将输出结构输出
            }
            // 输出结构到像素
            float4 frag(VertexOutput i) : COLOR { 
			//准备
            i.nDir = normalize(i.nDir);
            //float3 nDir = i.nDir;
			float3 nDirTS = UnpackNormal(tex2D(_NormalMap,i.uv0));      //法线解
			float3x3 TBN = float3x3(i.tDir,i.bDir,i.nDir);               //tnb矩阵
			float3 nDirWS = normalize (mul(nDirTS,TBN));   //法线转与TBN的转换
            // i.nDirWS = normalize(i.nDirWS);                //归一化，不然像素
			// float3 nDirWS = i.nDirWS;
			float3 lDir = _WorldSpaceLightPos0.xyz;           //灯光方向
			float3 vDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
			float3 vrDir = reflect( -vDir, nDirWS);
            
			//Lambert+phong
            float4 BaseMap_var = tex2D(_BaseMap,TRANSFORM_TEX(i.uv0, _BaseMap));
			float hlafLambert = max((dot(nDirWS,lDir)*0.5+0.5),0.0);                  //Lambert
			float vdotl = max(dot(vrDir,lDir),0.0);                      //Phong
			float Phong = pow(vdotl,_Liang);                    //限制范围后再做Pow
            //SSS+Frenal
            float2 sss_uv = float2 (hlafLambert,_SSS1);
            float4 SSS_var = _SSS1*tex2D(_SSS,TRANSFORM_TEX(i.uv0, _SSS));
            float  Frenal  =pow((1.0-max(dot(vrDir,nDirWS),0.0)),_Frenal);

			float LPhong =hlafLambert + Phong;
            float3 LP = (LPhong,LPhong,LPhong) * BaseMap_var*_Diff + SSS_var.rgb + Frenal ;
            //三色AO
            float4 AO_TEX_var = tex2D(_AO_TEX,TRANSFORM_TEX(i.uv0, _AO_TEX));
            float Upcol   = max(nDirWS.g,0.0);
            float Downcol = max(-nDirWS.g,0.0);
            float Evcol   = 1.0-Upcol-Downcol;
            float3 AO1    = (Upcol*_AO_Col1 + Evcol*_AO_Col2 + Downcol*_AO_Col3)*AO_TEX_var.b*_AO;




			float3 final = AO1 *LP;
            //float3 final = (Evcol,Evcol,Evcol );
            fixed4 finalCol = fixed4(final,1.0);

			return finalCol;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
