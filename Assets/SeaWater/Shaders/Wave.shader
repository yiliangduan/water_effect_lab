Shader "Unlit/Wave"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
		Tags { "RenderType" = "Overlay" "Queue" = "Transparent" }

		Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

			//Gerstner波
			float4 get_gerstner_wave_vertex(float4 vertex, float3 direction, float steepness, float waveLength, float speed, float amplitude)
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

            v2f vert (appdata v)
            {
                v2f o;

				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				float3 viewDir = normalize(WorldSpaceViewDir(worldPos));

                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
				fixed4 col = float4(0, 1, 0, 0.2);// tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
