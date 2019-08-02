using System.Collections.Generic;
using UnityEditor;
using UnityEngine;


namespace YiLiang.Effect.Water
{
    [System.Serializable]
    public class MeshConfig
    {
        /// <summary>
        /// 块数
        /// </summary>
        public int TileCount = 8;

        /// <summary>
        /// 每个块的网格分割
        /// </summary>
        public int TileGridNum = 8;

        /// <summary>
        /// Mesh名字
        /// </summary>
        public string MeshName = "gerstner_wave_mesh.asset";
    }

    public class WaterMeshGenerator : MonoBehaviour
    {

        public MeshConfig Config = new MeshConfig();

        public void Create()
        {
            string meshPath = "Assets/SeaWater/" + Config.MeshName;

            if (System.IO.File.Exists(meshPath))
            {
                EditorUtility.DisplayDialog("Notice!", "File exist!", "OK");
                return;
            }

            Mesh mesh = new Mesh
            {
                name = "gerstner_wave_mesh"
            };

            mesh.subMeshCount = Config.TileCount * Config.TileCount;

            CombineInstance[] combineInstances = new CombineInstance[mesh.subMeshCount];

            List<Mesh> tileList = new List<Mesh>();

            for (int i = 0; i < Config.TileCount; ++i)
            {
                for (int j = 0; j < Config.TileCount; ++j)
                {
                    Mesh tileMesh = CreateMeshTile();

                    tileList.Add(tileMesh);

                    Vector3 boundSize = tileMesh.bounds.size;

                    GameObject tileObject = new GameObject("tile_" + i);
                    tileObject.transform.position = new Vector3(i * boundSize.x, 0, j * boundSize.z);

                    CombineInstance tileCombineInstance = new CombineInstance
                    {
                        mesh = tileMesh,
                        transform = tileObject.transform.localToWorldMatrix
                    };

                    UnityEngine.Object.DestroyImmediate(tileObject);

                    combineInstances[i * Config.TileCount + j] = tileCombineInstance;
                }
            }

            mesh.CombineMeshes(combineInstances);

            AssetDatabase.CreateAsset(mesh, meshPath);


            EditorUtility.DisplayDialog("Notice!", "Create mesh success!", "OK");

        }

        private Mesh CreateMeshTile()
        {
            Mesh mesh = new Mesh
            {
                name = "tile",

                vertices = GeneratorVertices(Config.TileGridNum, Config.TileGridNum),
                triangles = GeneratorTriangles(Config.TileGridNum, Config.TileGridNum),
                colors = GeneratorColors(Config.TileGridNum, Config.TileGridNum)
            };

            mesh.RecalculateNormals();
            mesh.RecalculateTangents();
            mesh.RecalculateBounds();

            return mesh;
        }

        private Color[] GeneratorColors(int width, int height)
        {
            Color[] colors = new Color[(width + 1) * (height + 1)];

            for (int i = 0; i < colors.Length; ++i)
            {
                colors[i] = Color.white;
            }

            return colors;
        }

        private int[] GeneratorTriangles(int width, int height)
        {
            int[] triangles = new int[width * height * 6];

            int triangleIndex = 0;

            for (int i = 0; i < height; ++i)
            {
                for (int j = 0; j < width; ++j)
                {
                    triangles[triangleIndex + 0] = i * (width + 1) + j;
                    triangles[triangleIndex + 1] = (i + 1) * (width + 1) + j;
                    triangles[triangleIndex + 2] = i * (width + 1) + j + 1;

                    triangles[triangleIndex + 3] = i * (width + 1) + j + 1;
                    triangles[triangleIndex + 4] = (i + 1) * (width + 1) + j;
                    triangles[triangleIndex + 5] = (i + 1) * (width + 1) + j + 1;

                    triangleIndex += 6;
                }
            }

            return triangles;
        }

        private Vector3[] GeneratorVertices(int width, int height)
        {
            Vector3[] vertices = new Vector3[(width + 1) * (height + 1)];

            float tileX = 1.0f / (float)(width);
            float tileY = 1.0f / (float)(height);

            for (int i = 0; i <= height; ++i)
            {
                for (int j = 0; j <= width; ++j)
                {
                    vertices[i * (height + 1) + j] = new Vector3(tileX * j, 0, i * tileY);
                }
            }

            return vertices;
        }
    }
}