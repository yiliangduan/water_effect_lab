using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[ExecuteInEditMode]
public class DepthCamera : MonoBehaviour
{

    public Material mat;
    public int width = 512;
    public int height = 512;

    private Camera cam;
    private RenderTexture rt;

    void Start()
    {
        cam = GetComponent<Camera>();

        cam.depthTextureMode = DepthTextureMode.Depth;
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, mat);

    }
}