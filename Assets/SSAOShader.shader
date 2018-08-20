Shader "Hidden/SSAO"
{
	Properties
	{
		_MainTex ("", 2D) = "" {}
		_SSAO ("", 2D) = "" {}
	}
	Subshader
	{
		ZTest Always
		Cull Off
		ZWrite Off

		CGINCLUDE

		#include "UnityCG.cginc"
		struct v2f_ao
		{
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
		};

		float4 _CameraDepthNormalsTexture_ST;

		v2f_ao vert_ao (appdata_img v)
		{
			v2f_ao o;
			o.pos = UnityObjectToClipPos (v.vertex);
			o.uv = TRANSFORM_TEX(v.texcoord, _CameraDepthNormalsTexture);
			return o;
		}

		sampler2D _CameraDepthNormalsTexture;
		float4 _Params; // x=radius, y=minz, z=NONE, w=SSAO power

		ENDCG

		Pass
		{
			CGPROGRAM
			#pragma vertex vert_ao
			#pragma fragment frag


			half4 frag (v2f_ao i) : SV_Target
			{
				const float samplesCount = 8;

				const float3 samples[samplesCount] = {
					float3(0.01305719,0.5872321,-0.119337),
					float3(0.3230782,0.02207272,-0.4188725),
					float3(-0.310725,-0.191367,0.05613686),
					float3(-0.4796457,0.09398766,-0.5802653),
					float3(0.1399992,-0.3357702,0.5596789),
					float3(-0.2484578,0.2555322,0.3489439),
					float3(0.1871898,-0.702764,-0.2317479),
					float3(0.8849149,0.2842076,0.368524),
				};

				float4 depthnormal = tex2D(_CameraDepthNormalsTexture, i.uv);
				float3 viewNorm;
				float depth;
				DecodeDepthNormal(depthnormal, depth, viewNorm);
				//解包一次*深度法线图*，使用自身UV.

				depth *= _ProjectionParams.z;
				float scale = _Params.x / depth;//采样点偏移的缩放，越近的物体缩放越大。

				float occ = 0.0;
				for (int s = 0; s < samplesCount; ++s)
				{
					half3 randomDir = samples[s];

					half flip = (dot(viewNorm, randomDir)<0) ? 1.0 : -1.0;
					randomDir *= -flip;
					randomDir += viewNorm * 0.3;
					//这一步操作让采样点更接近视口法线的背面，而不是对面。这样非闭塞区域会更干净。

					float2 offset = randomDir.xy * scale;
					float4 sampleND = tex2D(_CameraDepthNormalsTexture, i.uv + offset);
					float sampleD;
					float3 sampleN;
					DecodeDepthNormal(sampleND, sampleD, sampleN);
					//解包一次*深度法线图*，使用采样UV.
					sampleD *= _ProjectionParams.z;

					float zd = saturate(depth - sampleD);
					if (zd > _Params.y)
						occ += zd;
					//计算采样UV和原始UV获得深度图的差，加在OCC上。但如果差小于阈值则忽略。
				}
				occ /= samplesCount;
				return 1 - occ;//occ是一个不断的被累加的结果，所以闭塞区域必然是比较亮，这里翻转一下。
			}
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv[2] : TEXCOORD0;
			};

			v2f vert (appdata_img v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos (v.vertex);
				o.uv[0] = MultiplyUV (UNITY_MATRIX_TEXTURE0, v.texcoord);
				o.uv[1] = MultiplyUV (UNITY_MATRIX_TEXTURE1, v.texcoord);
				return o;
			}

			sampler2D _MainTex;
			sampler2D _SSAO;

			half4 frag( v2f i ) : SV_Target
			{
				half4 c = tex2D (_MainTex, i.uv[0]);
				half ao = tex2D (_SSAO, i.uv[1]).r;
				ao = pow (ao, _Params.w);
				c.rgb *= ao;
				return c;
			}
			ENDCG
		}
	}
	Fallback off
}
