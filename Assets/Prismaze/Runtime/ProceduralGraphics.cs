using UnityEngine;
using UnityEngine.UI;

namespace Prismaze.Unity
{
    // Rounded rectangle with optional border, drawn as a mesh so buttons and
    // panels share the crystal look without sprite assets.
    public sealed class RoundedRect : MaskableGraphic
    {
        public float Radius = 18f;
        public float Border = 0f;
        public Color BorderColor = Color.white;

        protected override void OnPopulateMesh(VertexHelper mesh)
        {
            mesh.Clear();
            var rect = rectTransform.rect;
            float radius = Mathf.Min(Radius, Mathf.Min(rect.width, rect.height) * .5f);
            if (Border > 0f)
            {
                MeshDraw.RoundedRect(mesh, rect, radius, BorderColor);
                var inner = rect;
                inner.xMin += Border; inner.xMax -= Border; inner.yMin += Border; inner.yMax -= Border;
                MeshDraw.RoundedRect(mesh, inner, Mathf.Max(0f, radius - Border), color);
            }
            else MeshDraw.RoundedRect(mesh, rect, radius, color);
        }
    }

    // Vertical gradient fill for the app background.
    public sealed class GradientFill : MaskableGraphic
    {
        public Color Top = new Color(.07f, .12f, .22f);
        public Color Bottom = new Color(.015f, .03f, .07f);

        protected override void OnPopulateMesh(VertexHelper mesh)
        {
            mesh.Clear();
            var rect = rectTransform.rect;
            int index = mesh.currentVertCount;
            mesh.AddVert(new Vector2(rect.xMin, rect.yMin), Bottom, Vector2.zero);
            mesh.AddVert(new Vector2(rect.xMax, rect.yMin), Bottom, Vector2.zero);
            mesh.AddVert(new Vector2(rect.xMax, rect.yMax), Top, Vector2.zero);
            mesh.AddVert(new Vector2(rect.xMin, rect.yMax), Top, Vector2.zero);
            mesh.AddTriangle(index, index + 1, index + 2);
            mesh.AddTriangle(index, index + 2, index + 3);
        }
    }

    // Reusable mesh builders shared by UI graphics and the board view.
    public static class MeshDraw
    {
        public static void RoundedRect(VertexHelper mesh, Rect rect, float radius, Color tint)
        {
            float r = Mathf.Max(0f, Mathf.Min(radius, Mathf.Min(rect.width, rect.height) * .5f));
            // Center
            Quad(mesh, new Rect(rect.xMin + r, rect.yMin + r, rect.width - 2 * r, rect.height - 2 * r), tint);
            // Edges
            Quad(mesh, new Rect(rect.xMin + r, rect.yMin, rect.width - 2 * r, r), tint);
            Quad(mesh, new Rect(rect.xMin + r, rect.yMax - r, rect.width - 2 * r, r), tint);
            Quad(mesh, new Rect(rect.xMin, rect.yMin + r, r, rect.height - 2 * r), tint);
            Quad(mesh, new Rect(rect.xMax - r, rect.yMin + r, r, rect.height - 2 * r), tint);
            // Corners
            Arc(mesh, new Vector2(rect.xMin + r, rect.yMin + r), r, 180f, 270f, tint);
            Arc(mesh, new Vector2(rect.xMax - r, rect.yMin + r), r, 270f, 360f, tint);
            Arc(mesh, new Vector2(rect.xMax - r, rect.yMax - r), r, 0f, 90f, tint);
            Arc(mesh, new Vector2(rect.xMin + r, rect.yMax - r), r, 90f, 180f, tint);
        }

        static void Arc(VertexHelper mesh, Vector2 center, float radius, float from, float to, Color tint)
        {
            const int segments = 6;
            int centerIndex = mesh.currentVertCount;
            mesh.AddVert(center, tint, Vector2.zero);
            for (int i = 0; i <= segments; i++)
            {
                float angle = Mathf.Lerp(from, to, i / (float)segments) * Mathf.Deg2Rad;
                mesh.AddVert(center + new Vector2(Mathf.Cos(angle), Mathf.Sin(angle)) * radius, tint, Vector2.zero);
            }
            for (int i = 0; i < segments; i++)
                mesh.AddTriangle(centerIndex, centerIndex + 1 + i, centerIndex + 2 + i);
        }

        public static void Quad(VertexHelper mesh, Rect rect, Color tint)
        {
            int index = mesh.currentVertCount;
            mesh.AddVert(new Vector2(rect.xMin, rect.yMin), tint, Vector2.zero);
            mesh.AddVert(new Vector2(rect.xMax, rect.yMin), tint, Vector2.zero);
            mesh.AddVert(new Vector2(rect.xMax, rect.yMax), tint, Vector2.zero);
            mesh.AddVert(new Vector2(rect.xMin, rect.yMax), tint, Vector2.zero);
            mesh.AddTriangle(index, index + 1, index + 2);
            mesh.AddTriangle(index, index + 2, index + 3);
        }
    }
}