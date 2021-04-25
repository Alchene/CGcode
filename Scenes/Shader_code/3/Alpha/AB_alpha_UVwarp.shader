Shader "Alpha/AB_UVWarp"
{
	properties{
		_MainTex ("rgba",2D) = "gray"{}
        _Opacity ("透明度",range(0,1))= 0.5
        _NoiseTex ("扭曲图",2D) = "gray"{}
        _WarpInt ("niuqu强度",range(0,5))= 1
        _NoiseInt ("透明强度",range(0,5))= 1
        _Speed ("speed",range(0,10))= 1
	}
    SubShader {
        Tags {
            "Queue"="Transparent"      //调整渲染序列
            "RenderType"="TransparentCutout"  //对应改为cutout
			"ForceNoshadowCast" ="Ture" //关闭阴影投影
			"lgnoreProject"= "Ture"   //不响应投射器
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
             Blend One OneMinusSrcAlpha   //混合方式  SrcAlpha在预乘他自己
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0
			uniform sampler2D _MainTex;
            uniform sampler2D _NoiseTex;uniform float4 _NoiseTex_ST;
			uniform half _Opacity;
            uniform half _NoiseInt;
            uniform half _Speed;
            uniform half _WarpInt;
            //input 结构
            struct VertexInput {
                float4 vertex : POSITION;  // 将模型顶点信息输入
				float3 uv : TEXCOORD0;
            };
            //令Output 输出结构
            struct VertexOutput {
                float4 pos : SV_POSITION;
				float3 uv0 : TEXCOORD0;
                float3 uv1 : TEXCOORD1;     //采样Noise贴图
            };
			//输入结构>>顶点shader>>>输出结构
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;  //新建一个输出结构
                o.pos = UnityObjectToClipPos( v.vertex ); //变换顶点信息 并将其塞给输出结构
				o.uv0 = v.uv;
                o.uv1 = v.uv;    //uv1支持TillingOffect
                o.uv1.y = o.uv1.y + frac(-_Time.x*_Speed);  //uv移动

                return o;                                //将输出结构输出
            }
            // 输出结构>>像素
            half4 frag(VertexOutput i) : COLOR { 
                
				half3 var_NoiseTex = tex2D(_NoiseTex,TRANSFORM_TEX(i.uv1, _NoiseTex)).rgb;
                half2 uvBase = (var_NoiseTex.rg-0.5)*_WarpInt; //贴图阈值是0-1，减去0.5
                half2 uv0=i.uv0 +uvBase;    //取代MainTex的UV0
                half4 var_Maintex = tex2D(_MainTex,uv0);
                half noise = max(lerp(1.0,var_NoiseTex.b * 2.0 , _NoiseInt),0.0);
                half opacity = (var_Maintex.a) * noise*_Opacity;
				return half4 (var_Maintex.rgb*opacity,opacity);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}