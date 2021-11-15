#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "UnityLightingCommon.cginc"
#define USELIGHT

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
};

struct v2f
{
    float4 vertex : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
    float3 worldPos : TEXCOORD2;
    LIGHTING_COORDS(3, 4)
};

sampler2D AlbedoTexture;
float4 AlbedoTexture_ST;
float Gloss;
float4 SurfaceColor;


v2f vert (appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, AlbedoTexture);
    o.normal = UnityObjectToWorldNormal(v.normal);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    TRANSFER_VERTEX_TO_FRAGMENT(o);
    return o;
}

float4 frag (v2f i) : SV_Target
{
    float3 tex = tex2D(AlbedoTexture, i.uv).rgb;
    float3 surfaceColor = tex * SurfaceColor.rgb;
    
    
    #ifdef USELIGHT
        //diffuse
        float3 n = normalize(i.normal);
        float3 l = normalize(UnityWorldSpaceLightDir(i.worldPos));
        
        float atten = LIGHT_ATTENUATION(i);
        float3 lambert = saturate(dot(n, l));
        float3 diffuse = (lambert * atten) * _LightColor0.xyz;
                    
        //specular
        float3 v = normalize(_WorldSpaceCameraPos - i.worldPos);
        float3 h = normalize(l + v);
        const float3 specularExponent = exp2(Gloss * 6) + 2; //not great can be done in c#
        
        float3 specular = saturate(dot(h, n) * (lambert > 0));
        specular = pow(specular, specularExponent) * Gloss * atten;
        specular *= _LightColor0.xyz;
        return float4(diffuse * surfaceColor + specular, 1);
    #else
        #if IS_BASE_PASS
            return surfaceColor;
        #else
            return 0;
        #endif
    #endif
    
}