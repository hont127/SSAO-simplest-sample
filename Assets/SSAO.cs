using System;
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class SSAO : MonoBehaviour
{
    public float m_Radius = 0.4f;
    public float m_OcclusionIntensity = 1.5f;
    public int m_Downsampling = 2;
    public float m_MinZ = 0.01f;

    Material mSSAOMaterial;


    void OnDisable()
    {
        Destroy(mSSAOMaterial);
    }

    void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
    }

    [ImageEffectOpaque]
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (!mSSAOMaterial)
            mSSAOMaterial = new Material(Shader.Find("Hidden/SSAO"));

            RenderTexture rtAO = RenderTexture.GetTemporary(source.width / m_Downsampling, source.height / m_Downsampling, 0);
        mSSAOMaterial.SetVector("_Params", new Vector4(
                                                 m_Radius,
                                                 m_MinZ,
                                                 0,
                                                 m_OcclusionIntensity));

        Graphics.Blit(null, rtAO, mSSAOMaterial, 0);

        mSSAOMaterial.SetTexture("_SSAO", rtAO);
        Graphics.Blit(source, destination, mSSAOMaterial, 1);

        RenderTexture.ReleaseTemporary(rtAO);
    }
}
