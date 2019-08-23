using UnityEngine;
using UnityEditor;


namespace YiLiang.Effect.Water
{
    [CustomEditor(typeof(MeshGenerator))]
    public class MeshGeneratorEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            MeshGenerator generator = target as MeshGenerator;

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