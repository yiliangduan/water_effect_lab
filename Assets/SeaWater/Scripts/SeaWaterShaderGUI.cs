using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class SeaWaterShaderGUI: UnityEditor.ShaderGUI
{
    public enum DebugMode
    {
        OFF = 0,
        DEPTH = 1,
        LIGHTING = 2,
    }

    public DebugMode mDebugMode = DebugMode.OFF;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);

        Material targetMaterial = materialEditor.target as Material;

        DebugMode debugMode = (DebugMode)EditorGUILayout.EnumPopup("DEBUG", mDebugMode);

        if (debugMode != mDebugMode)
        {
            mDebugMode = debugMode;

            string[] shaderKeywords = targetMaterial.shaderKeywords;

            List<string> shaderNewKeywords = new List<string>();
            shaderNewKeywords.AddRange(shaderKeywords);

            if (mDebugMode == DebugMode.DEPTH)
            {
                shaderNewKeywords.Add("DEBUG_DEPTH");
                shaderNewKeywords.Remove("DEBUG_LIGHTING");
            }
            else if (mDebugMode == DebugMode.LIGHTING)
            {
                shaderNewKeywords.Remove("DEBUG_DEPTH");
                shaderNewKeywords.Add("DEBUG_LIGHTING");
            }
            else if (mDebugMode == DebugMode.OFF)
            {
                shaderNewKeywords.Remove("DEBUG_DEPTH");
                shaderNewKeywords.Remove("DEBUG_LIGHTING");
            }

            targetMaterial.shaderKeywords = shaderNewKeywords.ToArray();
            EditorUtility.SetDirty(targetMaterial);
        }
    }
}
