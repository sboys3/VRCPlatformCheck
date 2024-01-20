Shader "Unlit/DepthTestRenderTarget"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#define RENDER_WIDTH 32

			#include "UnityCG.cginc"



			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
    			UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 screenPos: TEXCOORD1;
				float4 worldPos: TEXCOORD2;
    			UNITY_VERTEX_INPUT_INSTANCE_ID
            	UNITY_VERTEX_OUTPUT_STEREO
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			// plane normal must be normalized
			float distanceFromPlaneToPoint(float3 planePoint, float3 planeNormal, float3 targetPoint) {
				return dot(targetPoint - planePoint, planeNormal);
			}
			float Linear01DepthToRawDepth(float linearDepth){
				return (1.0f - (linearDepth * _ZBufferParams.y)) / (linearDepth * _ZBufferParams.x);
			}
			float LinearWorldDepthToRawDepth(float linearDepth){
				return (1.0f - (linearDepth * _ZBufferParams.w)) / (linearDepth * _ZBufferParams.z);
			}
			float LinearWorldDepthToRawDepthOrtho(float linearDepth){
				// depth in ortho cameras is already linear
				return (1.0f - (linearDepth - _ProjectionParams.y) / (_ProjectionParams.z - _ProjectionParams.y));
			}

			v2f vert(appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
    			UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.screenPos = ComputeScreenPos(o.vertex);
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				
				uint2 pixel = i.screenPos.xy / i.screenPos.w * /*_ScreenParams.xy*/float2(RENDER_WIDTH, RENDER_WIDTH) + 0.0f;
				
				
				float worldDepth = distanceFromPlaneToPoint(_WorldSpaceCameraPos, unity_WorldToCamera._m20_m21_m22, i.worldPos);
				// returnValue.color = float4(worldDepth/10,worldDepth/10,worldDepth/10,1);
				float calculatedDepth;
				if(unity_OrthoParams.w){
					// depth in ortho cameras is already linear
					calculatedDepth = LinearWorldDepthToRawDepthOrtho(worldDepth);
				}else{
					calculatedDepth = LinearWorldDepthToRawDepth(worldDepth);
				}
				calculatedDepth = clamp(calculatedDepth, 0.00000001, 0.999999);
				
				
				
				bool inverted = i.vertex.z < 0.5;
				
				// when calculating depth manually it needs to be multiplied by 0.999983 to work correctly on adreno 600 series gpus.
				// this checks if multiplying by 0.999983 is correct
				float badDepth = (1.1 - (abs(calculatedDepth * 0.999983 - i.vertex.z) * (1 / 0.000003))) * !inverted;
				
				// green for inverted depth associated with desktop gpus
				// blue for non-inverted depth buffer associated with mobile devices
				// red for misbehaving mobile gpus with incorrect depth buffer, this will also always be blue and is triggered by the adreno gpus from the same generation as the quest 2
				float4 col = float4(
					badDepth,
					inverted,
					!inverted,
					1
				);
				
				// emulate normal mobile gpu
				//col = float4(0, 0, 1, 1);
				
				// emulate adreno 600 gpu
				//col = float4(1, 0, 1, 1);
				
				// for testing purposes only
				if(pixel.y == 31){
					col /= ((uint)pixel.x / (uint)2) + 1;
					col *= (pixel.x % 2) ? -1 : 1;
				}
				if(pixel.y == 30){
					if(pixel.x == 0){
						col = frac(_Time.y);
					}
					if(pixel.x == 1){
						col = i.vertex.z;
					}
					if(pixel.x == 2){
						col = calculatedDepth;
					}
					if(pixel.x == 3){
						col = (1 - i.vertex.z) * 1000;
					}
					if(pixel.x == 4){
						col = (1 - calculatedDepth) * 1000;
					}
					if(pixel.x == 5){
						col = (1 - i.vertex.z) * 10000;
					}
					if(pixel.x == 6){
						col = (1 - calculatedDepth) * 10000;
					}
					if(pixel.x == 7){
						col = (1 - i.vertex.z) * 100000;
					}
					if(pixel.x == 8){
						col = (1 - calculatedDepth) * 100000;
					}
					if(pixel.x == 9){
						col = (1 - i.vertex.z) * 1000000;
					}
					if(pixel.x == 10){
						col = (1 - calculatedDepth) * 1000000;
					}
				}
				
				return col;
			}
			ENDCG
		}
	}
}
