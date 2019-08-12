﻿Shader "YiLiang/Effect/Water/SeaWater"
{
	Properties
	{
		_BumpTex("Bump Tex[凹凸]", 2D) = "white" {}

		[HDR]_WaterColor("Water Color [水颜色]", Color) = (1.0, 1.0, 1.0, 1.0)

		_WaterRimColor ("Water Rim Color [水边缘颜色]", Color) = (1.0, 1.0, 1.0, 1.0)

		_WaterRimWaveTex("Water Rim Tex [水边缘浪的贴图]", 2D) = "white" {}

		_WaterRimNoise ("Water Rim Noise [水边缘颜色噪点图]", 2D) = "white" {}

		_BumpTexScale("Bump Tex scale [凹凸贴图缩放]", Range(0, 1)) = 0.063

		_WaterFoamTex("Foam Tex[泡沫]", 2D) = "white"{}

		_UVWaveSpeed(" UV wave speed [UV摆动速]", Vector) = (19, 9,-16,-7)

		_WaveSpeed("Wave Speed[波速]", float) = 1

		_RimWaveSpeed("Rim Wave Speed[岸边的水浪速度]", float) = 1

        _WaveLength("Wave length [波长]", float) = 0.1

        _WaveAmplitude("Wave amplitude [振幅]", float) = 0.1

        _Steepness("Steepness[坡度]", Range(0, 1)) = 0.1

        _Shininess ("Shininess[反光度]", float) = 0.5

		_Fresnel ("Fresnel [菲涅尔光照因子]", float) = 0.3

		_WaveDirection("Wave Direction [波动方向]", Vector) = (1, 0, 0, 0)

		_DiffuseColor("Diffuse Color", Color) = (1.0, 1.0, 1.0, 1.0)

		_RimFade ("Rim Fade [岸边渐变]", Range(0, 1)) = 0.5

		_FoamDensity("Foam Density [泡沫浓度]", Range(0, 1)) = 0.5
	}


	SubShader
	{
		Tags { "RenderType" = "Overlay" "Queue" = "Transparent" }

		Blend SrcAlpha OneMinusSrcAlpha
		LOD 100

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma shader_feature _ DEBUG_DEPTH
			#pragma shader_feature _ DEBUG_LIGHTING

			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 texCoord : TEXCOORD0;
				float4 bump : TEXCOORD1;
				float4 worldPos : TEXCOORD2;
				float3 viewDir : TEXCOORD3;
                float3 lightDir : TEXCOORD4;
				float4 screenPos : TEXCOORD5;
				float3 reflect : TEXCOORD6;
				float3 normal : TEXCOORD7;
			};

			sampler2D _BumpTex;
			float4    _BumpTex_ST;

			sampler2D _WaterFoamTex;
			float4    _WaterFoamTex_ST;

			sampler2D _WaterRimNoise;
			float4 _WaterRimNoise_ST;

			float  _BumpTexScale;
			float4 _UVWaveSpeed;

			float _RimWaveSpeed;
			float _RimFade;
			
			float4 _WaterColor;
			float4  _WaterRimColor;
            float  _WaveSpeed;
            float  _WaveLength;
            float  _WaveAmplitude;
			float4 _WaveDirection;

			sampler2D _WaterRimWaveTex;
			float4 _WaterRimWaveTex_ST;

            float _Steepness;

            float _Shininess;
			float _Fresnel;

			float4 _DiffuseColor;

			float _FoamDensity;

			//相机的深度纹理，Unity内置
			sampler2D _CameraDepthTexture;

			//Gerstner波
			float4 get_gerstner_wave_vertex(float4 vertex, float3 direction,float steepness, float waveLength, float speed, float amplitude)
			{
				float factorW = 2 * UNITY_PI / waveLength;

				float factortrangle = factorW * direction.x + speed * _Time.y;

				float factorQ = steepness;

				float cosFactor = pow(cos(factortrangle), 2);
				float sinFactor = pow(sin(factortrangle), 2);

				float4 vertexWavePos;

				vertexWavePos.x = vertex.x + direction.x * factorQ * amplitude * cosFactor;
				vertexWavePos.y = factorQ * sinFactor;
				vertexWavePos.z = vertex.z + direction.z * factorQ  * amplitude *  cosFactor;
				vertexWavePos.w = vertex.w;

				return vertexWavePos;
			}

			//波的深度值
			float get_wave_depth(float4 screenPos)
			{
				//水面边缘的透明渐变因子  [远处 -> 岸边 颜色越来越透，形成离岸越近水越浅的效果]
				float4 screenPosNorm = screenPos / screenPos.w;

				screenPosNorm.z = (UNITY_NEAR_CLIP_VALUE >= 0) ? screenPosNorm.z : screenPosNorm.z * 0.5 + 0.5;

				//非线性的深度值 sceneDepth是GPU中的深度Buffer中的值，记录着在当前顶点渲染之前的最新的顶点深度值。
				//转换为View空间的线性值
				float linearSceneDepth = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(screenPosNorm))));

				float depth = (linearSceneDepth - LinearEyeDepth(screenPosNorm.z))*_RimFade;

			 	return depth;
			}

			v2f vert (appdata v)
			{
				v2f o;

				float3 direction = normalize(_WaveDirection - v.vertex);
				float4 vertexWavePos = get_gerstner_wave_vertex(v.vertex, direction, _Steepness, _WaveLength, _WaveSpeed, _WaveAmplitude);

                o.vertex = UnityObjectToClipPos(vertexWavePos);

                o.worldPos = mul(unity_ObjectToWorld, vertexWavePos);
				o.viewDir.xyz = direction;

				float4 bumpTexScale = float4(_BumpTexScale, _BumpTexScale, _BumpTexScale*0.4, _BumpTexScale*0.45);
                float4 temp = (o.worldPos.xzxz + _UVWaveSpeed * _Time.x) * bumpTexScale;

                o.bump.xy = TRANSFORM_TEX(temp.xy, _BumpTex);
                o.bump.zw = TRANSFORM_TEX(temp.zw, _BumpTex);
   
                o.lightDir = normalize(WorldSpaceLightDir(o.worldPos));

				//屏幕坐标
				o.screenPos = ComputeScreenPos(o.vertex);
				o.normal = UnityObjectToWorldNormal(v.normal);

				o.reflect = reflect(-o.viewDir.xyz, o.normal.xyz); 

				return o;
			}

			//菲涅尔因子 cosTheta = dot( norliaze(normalize(Normal), normalize(cameraPosition - worldPos))
			float fresnel_schlick(float cosTheta, float3 F0)
			{
				return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 2.0);
			}

			fixed4 frag (v2f i) : SV_Target
			{
                //法线从两个方向交叉摆动，形成一种来回的水面波纹
				//不使用blue颜色，bump贴图的blue颜色太强了。
				float3 bump1 = UnpackNormal(tex2D(_BumpTex, i.bump.xy)).rgr; 
				float3 bump2 = UnpackNormal(tex2D(_BumpTex, i.bump.zw)).rgr;
				float3 bump = (bump1 + bump2) * 0.5;

				//水深的权重
				float waveDepth = get_wave_depth(i.screenPos);
				float fadeWeight = saturate(1 - saturate(waveDepth));
				
				//噪声纹理，打散岸边的水，显得不均匀，自然一些。
				float4 noisePixel = tex2D(_WaterRimNoise, bump.xy);

				//岸边水的颜色，自定义的颜色，带白色
				float4 rimColor = float4(_WaterRimColor.rgb  , _WaterRimColor.a*noisePixel.r);
				float4 color = lerp(_WaterColor, rimColor, fadeWeight);

				//岸边的水混合一点泡沫
				float4 foamPixel = tex2D(_WaterFoamTex, bump.xy);            
				color = lerp(color, foamPixel, foamPixel.r*_FoamDensity);

				//长带白浪
				float4 waterRimWaveColor = tex2D(_WaterRimWaveTex, float2((fadeWeight + sin(_Time.y*_RimWaveSpeed + noisePixel.r)), 1)+bump)*noisePixel.r;
				color += waterRimWaveColor*fadeWeight;

				//环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				//漫反射光照
				fixed3 diffuse = _LightColor0.rgb * max(dot(bump, i.lightDir), 0);
				//高光
				fixed3 specular = _LightColor0.rgb * pow(max(dot(i.reflect, i.viewDir), 0), 16);

				//反射
				fixed4 reflection = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, i.reflect);
				float3 hdrReflection = DecodeHDR(reflection, unity_SpecCube0_HDR);

				//菲涅尔混合
				half fresnelFac =  fresnel_schlick(1-dot(bump, i.lightDir.xyz), _Fresnel);
				fixed3 lightColor = lerp((ambient + diffuse + specular), hdrReflection, fresnelFac);

				//水的颜色+光照
				color = float4(lightColor+color.rgb, color.a);

				return color;

			}
			ENDCG
		}
	}

	CustomEditor "SeaWaterShaderGUI"
}  