using UnityEngine;
using UnityEditor;


namespace YiLiang.Effect.Water
{
    [CustomEditor(typeof(WaterMeshGenerator))]
    public class WaterMeshGeneratorEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            WaterMeshGenerator generator = target as WaterMeshGenerator;

            if (null == generator)
            {
                return;
            }

            EditorGUILayout.BeginVertical();

            if (GUILayout.Button("Generator"))
            {
                generator.Create();
            }

            EditorGUILayout.EndVertical();

            base.OnInspectorGUI();
        }
    }
}