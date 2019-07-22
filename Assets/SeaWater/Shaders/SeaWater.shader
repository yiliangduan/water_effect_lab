Shader "Unlit/SeaWater"
{
	Properties
	{
		_BumpTex("Bump Tex[凹凸]", 2D) = "white" {}

		_WaterColor("Water Color [水颜色]", Color) = (1.0, 1.0, 1.0, 1.0)

		_WaterBorderColor ("Water Border Color [水边缘颜色]", Color) = (1.0, 1.0, 1.0, 1.0)

		_BumpTexScale("Bump Tex scale [凹凸贴图缩放]", Range(0, 1)) = 0.063

		_FoamTex("Foam Tex[泡沫]", 2D) = "white"{}

		_UVWaveSpeed(" UV wave speed [UV摆动速]", Vector) = (19, 9,-16,-7)

        _WaveLength("Wave length [波长]", float) = 0.1

        _WaveAmplitude("Wave amplitude [振幅]", float) = 0.1

        _Steepness("Steepness[坡度]", Range(0, 1)) = 0.1

        _WaveSpeed("Wave Speed[波速]", float) = 1

        _Shininess ("Shininess[反光度]", float) = 0.5

		_Fresnel ("Fresnel [菲涅尔光照因子]", float) = 0.3

		_BorderTransparentFadeFactor ("Border Fade [水的边缘的透明渐变效果因子]", float) = 1.5
	}


	SubShader
	{
		Tags { "RenderType" = "Overlay" "Queue" = "Transparent" }

		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off
		Cull Off
		LOD 100

		GrabPass
		{
			"_RefractionTex"
		}

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 normal : TEXCOORD1;
				float4 worldPos : TEXCOORD2;
				float3 viewDir : TEXCOORD3;
                float4 lightDir : TEXCOORD4;
				float4 screenPos : TEXCOORD5;
			};

			sampler2D _BumpTex;
			float4    _BumpTex_ST;

			sampler2D _FoamTex;
			float4    _FoamTex_ST;

			float  _BumpTexScale;
			float4 _UVWaveSpeed;

			float4 _WaterColor;
			float4  _WaterBorderColor;
            float  _WaveSpeed;
            float  _WaveLength;
            float  _WaveAmplitude;

            float _Steepness;

            float _Shininess;
			float _Fresnel;

			float _BorderTransparentFadeFactor;

			//相机的深度纹理，Unity内置
			sampler2D _CameraDepthTexture;

			v2f vert (appdata v)
			{
				v2f o;

                o.viewDir.xzy = normalize(WorldSpaceViewDir(v.vertex));

                //摆动坐标
                float4 vertexWavePos;

                float vecFactorArgument = (6.28318 / _WaveLength) * o.viewDir.xzy + _WaveSpeed * _Time.y;

                float cosFactor = pow(cos(vecFactorArgument), 2);
                float sinFactor = pow(sin(vecFactorArgument), 2);
                
                vertexWavePos.x = v.vertex.x + _Steepness * _WaveAmplitude * o.viewDir.x * cosFactor;
                vertexWavePos.y = _Steepness * sinFactor;
                vertexWavePos.z = v.vertex.z + _Steepness * _WaveAmplitude * o.viewDir.z * cosFactor;
				vertexWavePos.w = v.vertex.w;

                o.vertex = UnityObjectToClipPos(vertexWavePos);

                o.worldPos.xyz = mul(unity_ObjectToWorld, vertexWavePos);

                //摆动法线
                float4 bumpTexScale = float4(_BumpTexScale, _BumpTexScale, _BumpTexScale*0.4, _BumpTexScale*0.45);
 
                float4 temp = (o.worldPos.xzxz + _UVWaveSpeed * _Time.x) * bumpTexScale;

                o.normal.xy = temp.xy;
                o.normal.zw = temp.zw;
   
                float3 vertexToLightSource = o.worldPos.xyz - _WorldSpaceLightPos0.xyz;
                o.lightDir.xyz = normalize(vertexToLightSource);
                o.lightDir.w = 1.0 / length(vertexToLightSource);

				//屏幕坐标
				o.screenPos = ComputeScreenPos(o.vertex);

				return o;
			}

			//菲涅尔因子 cosTheta = dot( norliaze(normalize(Normal), normalize(cameraPosition - worldPos))
			float fresnelSchlick(float cosTheta, float3 F0)
			{
				return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 2.0);
			}

			fixed4 frag (v2f i) : SV_Target
			{
                //法线从两个方向交叉摆动，形成一种来回的水面波纹
				float3 bump1 = UnpackNormal(tex2D(_BumpTex, i.normal.xy)).rgb;
				float3 bump2 = UnpackNormal(tex2D(_BumpTex, i.normal.zw)).rgb;
				float3 bump = (bump1 + bump2) * 0.5;

				//用来计算光照的菲涅尔因子
				half fresnelFac =  fresnelSchlick(1-dot(i.viewDir.xyz, bump), _Fresnel);


				//水面边缘的透明渐变因子  [远处 -> 岸边 颜色越来越透，形成离岸越近水越浅的效果]
				float2 normalizeSceneVertex = i.screenPos.xy/i.screenPos.w;

				//非线性的深度值 sceneDepth是GPU中的深度Buffer中的值，记录着在当前顶点渲染之前的最新的顶点深度值。
				float sceneDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, normalizeSceneVertex);
				//转换为View空间的线性值
				float linearSceneDepth = LinearEyeDepth(sceneDepth);

				//当前顶点的深度值
				float vertexDepth = i.screenPos.w;

				float4 foamColor = tex2D(_FoamTex, i.normal.xy);

				float fadeWeight = (1 - saturate((linearSceneDepth - vertexDepth) * _BorderTransparentFadeFactor));

				float4 color = lerp(_WaterColor, _WaterBorderColor, fadeWeight);

				//边缘直接使用泡沫的颜色
				color = lerp(color, foamColor, fadeWeight);

				//Phong漫反射光照
				float4 diffuse = max(dot(bump, i.lightDir.xyz), 0);

				//Blin-Phong高光
				float3 halfwayDir = normalize(i.lightDir.xyz + i.viewDir.xyz);
				float4 specular = pow(max(dot(bump, halfwayDir), 0.0), _Shininess);

				color = float4(color.rgb * _LightColor0.rgb * diffuse + _LightColor0.rgb * specular, color.a);


				return color;
			}
			ENDCG
		}
	}
}  