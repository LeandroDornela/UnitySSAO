using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[ExecuteInEditMode]
public class PostProcessingCamera : MonoBehaviour
{

    public Material postProcessingMat;
    public int samples = 64;

    public List<Vector4> ssaoKernel;
    public Texture2D noiseTexture;

    public enum DebugMode
    {
        off,
        depth,
        normal,
        albedo,
        scrPosition,
        noiseTexture,
        sampleDepth,
        viewNormal,
        sampleOffset,
        occlusion,
        sample,
        viewPosition
    }

    public DebugMode debugMode = DebugMode.off;
    [Range(0.0f, 0.5f)]
    public float radius = 0.1f;
    public bool randomPerFrame = false;
    private Camera cam;

    
    float lerp(float a, float b, float f)
    {
        return a + f * (b - a);
    }


    Texture2D CreateNoiseTexture(int w, int h)
    {
        Texture2D texture = new Texture2D(w, h, TextureFormat.RGBA32, false);
        texture.wrapModeU = TextureWrapMode.Repeat;
        texture.wrapModeV = TextureWrapMode.Repeat;
        texture.filterMode = FilterMode.Point;

        for(int i = 0; i < h; i++)
        {
            for(int j = 0; j < w; j++)
            {
                Color noise = new Color(Random.Range(-1.0f, 1.1f),
                                        Random.Range(-1.0f, 1.1f),
                                        0.0f, 1.0f);

                if(noise.r == 0)
                {
                    noise = new Color(1.0f,
                              1.0f,
                              0.0f, 1.0f);
                }

                if(noise.g == 0)
                {
                    noise = new Color(1.0f,
                              1.0f,
                              0.0f, 1.0f);
                }

                texture.SetPixel(i, j, noise);
            }
        }

        texture.Apply();

        return texture;
    }


    void Start()
    {
        cam = GetComponent<Camera>();
        cam.depthTextureMode = DepthTextureMode.DepthNormals;
        ssaoKernel = new List<Vector4>();


        for(int i = 0; i < samples; i++)
        {
            Vector3 sample = new Vector3(Random.Range(-1.0f, 1.1f),
                                         Random.Range(-1.0f, 1.1f),
                                         Random.Range(0.0f, 1.0f));

            if(sample.x == 0 || sample.y == 0)
            {
                sample = new Vector3(1.0f, 1.0f, 1.0f);
            }

            sample = sample.normalized;
            //sample *= Random.Range(0.0f, 1.0f);
            float scale = (float)i / samples;
            scale = lerp(0.1f, 1.0f, scale*scale);
            sample *= scale;

            ssaoKernel.Add(new Vector4(sample.x, sample.y, sample.z, 0));
        }

        noiseTexture = CreateNoiseTexture(4, 4);

        postProcessingMat.SetTexture("noiseTexture", noiseTexture);


        try
        {
            postProcessingMat.SetVectorArray("samples", ssaoKernel);
        }
        catch (System.Exception)
        {
            
            throw;
        }
    }
    
    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if(randomPerFrame)
        {
            ssaoKernel = new List<Vector4>();

            for(int i = 0; i < samples; i++)
            {
                Vector3 sample = new Vector3(Random.Range(-1.0f, 1.0f),
                                            Random.Range(-1.0f, 1.0f),
                                            Random.Range(0.0f, 1.0f));

                sample = sample.normalized;
                //sample *= Random.Range(0.0f, 1.0f);
                float scale = (float)i / samples;
                scale = lerp(0.1f, 1.0f, scale*scale);
                sample *= scale;

                ssaoKernel.Add(new Vector4(sample.x, sample.y, sample.z, 0));
            }

            noiseTexture = CreateNoiseTexture(4, 4);

            postProcessingMat.SetTexture("noiseTexture", noiseTexture);


            try
            {
                postProcessingMat.SetVectorArray("samples", ssaoKernel);
            }
            catch (System.Exception)
            {
                
                throw;
            }
        }

        postProcessingMat.SetMatrix("invProjection", cam.projectionMatrix.inverse);
        postProcessingMat.SetMatrix("projection", cam.projectionMatrix);
        postProcessingMat.SetMatrix("viewMatrix", cam.worldToCameraMatrix);
        postProcessingMat.SetFloat("radius", radius);

        if(debugMode == DebugMode.off)
        {
            postProcessingMat.SetInt("debugMode", 0);
        }
        else if(debugMode == DebugMode.depth)
        {
            postProcessingMat.SetInt("debugMode", 1);
        }
        else if (debugMode == DebugMode.normal)
        {
            postProcessingMat.SetInt("debugMode", 2);
        }
        else if (debugMode == DebugMode.albedo)
        {
            postProcessingMat.SetInt("debugMode", 3);
        }
        else if (debugMode == DebugMode.scrPosition)
        {
            postProcessingMat.SetInt("debugMode", 4);
        }
        else if (debugMode == DebugMode.noiseTexture)
        {
            postProcessingMat.SetInt("debugMode", 5);
        }
        else if (debugMode == DebugMode.sampleDepth)
        {
            postProcessingMat.SetInt("debugMode", 6);
        }
        else if (debugMode == DebugMode.viewNormal)
        {
            postProcessingMat.SetInt("debugMode", 7);
        }
        else if (debugMode == DebugMode.sampleOffset)
        {
            postProcessingMat.SetInt("debugMode", 8);
        }
        else if (debugMode == DebugMode.occlusion)
        {
            postProcessingMat.SetInt("debugMode", 9);
        }
        else if (debugMode == DebugMode.sample)
        {
            postProcessingMat.SetInt("debugMode", 10);
        }
        else if (debugMode == DebugMode.viewPosition)
        {
            postProcessingMat.SetInt("debugMode", 11);
        }

        Graphics.Blit(src, dest, postProcessingMat);
    }
}
