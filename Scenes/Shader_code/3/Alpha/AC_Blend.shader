Shader "Alpha/AC_Blend"
{
	properties{
		_MainTex ("rgba",2D) = "white"{}
        _Cutoff ("Cutoff",range(0,1))= 1
	}
    SubShader {
        Tags {
            "RenderType"="Transparent"  
			"ForceNoshadowCast" ="Ture"
			"lgnoreProject"= "Ture"
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
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0
			uniform sampler2D _MainTex;uniform float4 _MainTex_ST;
            float _Cutoff;
            struct VertexInput {
                float4 vertex : POSITION;  // 将模型顶点信息输入
				float3 texcoord0 : TEXCOORD0;
            };
            //令Output 
			// 模型顶点信息换算而来的顶点屏幕位置
            struct VertexOutput {
                float4 pos : SV_POSITION;
				float3 uv0 : TEXCOORD0;
            };
			//输入结构>>顶点shader>>>输出结构
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;  //新建一个输出结构
                o.pos = UnityObjectToClipPos( v.vertex ); //变换顶点信息 并将其塞给输出结构
				o.uv0 = v.texcoord0;

                return o;                                //将输出结构输出
            }
            // 输出结构到像素
            float4 frag(VertexOutput i) : COLOR { 
                float4 var_Maintex = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
				half opacity =var_Maintex.a;
				clip(opacity-_Cutoff);
				return half4 (var_Maintex.rgb,1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}