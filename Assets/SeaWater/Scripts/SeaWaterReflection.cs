using UnityEngine;

public class SeaWaterReflection : MonoBehaviour
{
    public bool Reflection = true;

    public int RenderTextureSize = 256;

    public LayerMask ReflectLayers = -1;

    private RenderTexture mReflectionRenderTexture;

    private Camera mReflectionCamera;

    private void CreateReflectionComponent()
    {
        //尺寸变了，先释放
        if (null != mReflectionRenderTexture && mReflectionRenderTexture.width != RenderTextureSize)
        {
            mReflectionRenderTexture.Release();
            DestroyImmediate(mReflectionRenderTexture);
            mReflectionRenderTexture = null;
        }

        if (null == mReflectionRenderTexture)
        {
            mReflectionRenderTexture = RenderTexture.GetTemporary(RenderTextureSize, RenderTextureSize);
            mReflectionRenderTexture.name = "ReflectionRenderTexture";
            mReflectionRenderTexture.isPowerOfTwo = true;
            mReflectionRenderTexture.hideFlags = HideFlags.DontSave;
        }

        if (null == mReflectionCamera)
        {
            GameObject cameraObj = new GameObject("Reflection Camera");

            mReflectionCamera = cameraObj.AddComponent<Camera>();

            if (null == mReflectionCamera)
            {
                Debug.LogError("Add camera component error!");
                return;
            }

            mReflectionCamera.enabled = false;
            mReflectionCamera.transform.position = transform.position;
            mReflectionCamera.transform.rotation = transform.rotation;
            mReflectionCamera.gameObject.AddComponent<FlareLayer>();
            cameraObj.hideFlags = HideFlags.DontSave;

            Camera currentRendererCamera = Camera.current;

            if (null != currentRendererCamera)
            {
                mReflectionCamera.CopyFrom(currentRendererCamera);
            }
        }
    }

    private void OnWillRenderObject()
    {
        if (!enabled)
        {
            return;
        }

        Renderer waterRenderer = GetComponent<Renderer>();

        if (!waterRenderer|| !waterRenderer.sharedMaterial ||!waterRenderer.enabled)
        {
            return;
        }

        Camera currentRendererCamera = Camera.current;
        if (!currentRendererCamera)
        {
            return;
        }

        CreateReflectionComponent();

        Vector3 pos = transform.position;
        Vector3 normal = transform.up;

        // Reflect camera around reflection plane
        float direction = -Vector3.Dot(normal, pos);
        Vector4 reflectionPlane = new Vector4(normal.x, normal.y, normal.z, direction);

        Matrix4x4 reflection = Matrix4x4.zero;

        CalculateReflectionMatrix(ref reflection, reflectionPlane);

        Vector3 oldpos = currentRendererCamera.transform.position;
        Vector3 newpos = reflection.MultiplyPoint(oldpos);
        mReflectionCamera.worldToCameraMatrix = currentRendererCamera.worldToCameraMatrix * reflection;

        Vector4 clipPlane = CameraSpacePlane(mReflectionCamera, pos, normal, 1.0f);
        mReflectionCamera.projectionMatrix = currentRendererCamera.CalculateObliqueMatrix(clipPlane);

        mReflectionCamera.cullingMatrix = currentRendererCamera.projectionMatrix * currentRendererCamera.worldToCameraMatrix;

        mReflectionCamera.cullingMask = ~(1 << 4) & ReflectLayers.value; // never render water layer
        mReflectionCamera.targetTexture = mReflectionRenderTexture;
        bool oldCulling = GL.invertCulling;
        GL.invertCulling = !oldCulling;
        mReflectionCamera.transform.position = newpos;
        Vector3 euler = currentRendererCamera.transform.eulerAngles;
        mReflectionCamera.transform.eulerAngles = new Vector3(-euler.x, euler.y, euler.z);
        mReflectionCamera.Render();
        mReflectionCamera.transform.position = oldpos;
        GL.invertCulling = oldCulling;

        waterRenderer.sharedMaterial.SetTexture("_ReflectionTex", mReflectionRenderTexture);
        waterRenderer.sharedMaterial.EnableKeyword("ENABLE_REFLECTION");
    }

    
    Vector4 CameraSpacePlane(Camera currentRendererCamera, Vector3 pos, Vector3 normal, float sideSign)
    {
        Vector3 offsetPos = pos + normal;
        Matrix4x4 m = currentRendererCamera.worldToCameraMatrix;
        Vector3 cpos = m.MultiplyPoint(offsetPos);
        Vector3 cnormal = m.MultiplyVector(normal).normalized * sideSign;
        return new Vector4(cnormal.x, cnormal.y, cnormal.z, -Vector3.Dot(cpos, cnormal));
    }

    // Calculates reflection matrix around the given plane
    static void CalculateReflectionMatrix(ref Matrix4x4 reflectionMat, Vector4 plane)
    {
        reflectionMat.m00 = (1F - 2F * plane[0] * plane[0]);
        reflectionMat.m01 = (- 2F * plane[0] * plane[1]);
        reflectionMat.m02 = (- 2F * plane[0] * plane[2]);
        reflectionMat.m03 = (- 2F * plane[3] * plane[0]);

        reflectionMat.m10 = (- 2F * plane[1] * plane[0]);
        reflectionMat.m11 = (1F - 2F * plane[1] * plane[1]);
        reflectionMat.m12 = (- 2F * plane[1] * plane[2]);
        reflectionMat.m13 = (- 2F * plane[3] * plane[1]);

        reflectionMat.m20 = (- 2F * plane[2] * plane[0]);
        reflectionMat.m21 = (- 2F * plane[2] * plane[1]);
        reflectionMat.m22 = (1F - 2F * plane[2] * plane[2]);
        reflectionMat.m23 = (- 2F * plane[3] * plane[2]);

        reflectionMat.m30 = 0F;
        reflectionMat.m31 = 0F;
        reflectionMat.m32 = 0F;
        reflectionMat.m33 = 1F;
    }

    void OnDisable()
    {
        Renderer waterRenderer = GetComponent<Renderer>();
        if (null != waterRenderer && null != waterRenderer.sharedMaterial)
        {
            waterRenderer.sharedMaterial.DisableKeyword("ENABLE_REFLECTION");
            return;
        }

        if (null != mReflectionRenderTexture)
        {
            DestroyImmediate(mReflectionRenderTexture);
            mReflectionRenderTexture = null;
        }
   
        if (null != mReflectionCamera)
        {
            DestroyImmediate(mReflectionCamera.gameObject);
            mReflectionCamera = null;
        }

        
    }
}
