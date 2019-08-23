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
        /// 每个块的垂直方向的三角形数
        /// </summary>
        public int TileVerticalVertexNum = 2;

        public int TileHorizontalVertexNum = 2;

        /// <summary>
        /// Mesh名字
        /// </summary>
        public string MeshAssetPath = "temporary.asset";
    }

    public class MeshGenerator : MonoBehaviour
    {

        public MeshConfig Config = new MeshConfig();

        public void Create()
        {
            string meshPath = "Assets/" + Config.MeshAssetPath;

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

                vertices = GeneratorVertices(Config.TileHorizontalVertexNum, Config.TileVerticalVertexNum),
                triangles = GeneratorTriangles(Config.TileHorizontalVertexNum, Config.TileVerticalVertexNum),
                colors = GeneratorColors(Config.TileHorizontalVertexNum, Config.TileVerticalVertexNum)
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
                    triangles[triangleIndex + 1] = i * (width + 1) + j + 1;
                    triangles[triangleIndex + 2] = (i + 1) * (width + 1) + j;

                    triangles[triangleIndex + 3] = i * (width + 1) + j + 1;
                    triangles[triangleIndex + 4] = (i + 1) * (width + 1) + j + 1;
                    triangles[triangleIndex + 5] = (i + 1) * (width + 1) + j;

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

            int verticesIndex = 0;
            for (int i = 0; i <= height; ++i)
            {
                for (int j = 0; j <= width; ++j)
                {
                    vertices[verticesIndex++] = new Vector3(tileX * j, 0, i * tileY);
                }
            }

            return vertices;
        }
    }
}