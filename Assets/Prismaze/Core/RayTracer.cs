using System;
using System.Collections.Generic;

namespace Prismaze.Core
{
    public static class RayTracer
    {
        private static readonly int[] Dx = { 0, 1, 0, -1 }, Dy = { -1, 0, 1, 0 };
        // Rows: | / - backslash. Columns: travelling N E S W. -1 absorbs.
        private static readonly int[,] Reflections = { { -1, 3, -1, 1 }, { 1, 0, 3, 2 }, { 2, -1, 0, -1 }, { 3, 2, 1, 0 } };
        internal static int Normalize(int orientation) => (orientation % 4 + 4) % 4;

        private sealed class Ray
        {
            public int X, Y, Direction, Color;
            public HashSet<(int, int, int, int)> Path;
        }

        public static TraceResult Trace(IEnumerable<BoardObject> objects, int width = 6, int height = 12)
        {
            var output = new TraceResult();
            if (objects == null || width <= 0 || height <= 0) return output;
            var grid = new Dictionary<(int, int), BoardObject>();
            var ids = new HashSet<string>(StringComparer.Ordinal);
            var targets = new List<BoardObject>();
            var queue = new Queue<Ray>();
            foreach (var item in objects)
            {
                if (item == null || item.Id == null || !Inside(item.X, item.Y, width, height)
                    || grid.ContainsKey((item.X, item.Y)) || !ids.Add(item.Id)
                    || item.Kind < ObjectKind.Source || item.Kind > ObjectKind.Wall || item.Color < 0 || item.Color > 7)
                    return output;
                grid.Add((item.X, item.Y), item);
                if (item.Kind == ObjectKind.Source)
                    queue.Enqueue(new Ray { X = item.X, Y = item.Y, Direction = Normalize(item.Orientation), Color = item.Color, Path = new HashSet<(int, int, int, int)>() });
                else if (item.Kind == ObjectKind.Target)
                {
                    targets.Add(item);
                    output.Hits.Add(item.Id, 0);
                }
            }
            output.Valid = true;
            var processed = new HashSet<(int, int, int, int)>();
            while (queue.Count > 0)
            {
                var ray = queue.Dequeue();
                int x = ray.X, y = ray.Y, direction = ray.Direction, color = ray.Color;
                float fromX = x + .5f, fromY = y + .5f;
                while (true)
                {
                    var key = (x, y, direction, color);
                    // Only repetition in this ray's ancestry is a loop. Other rays
                    // may converge on an already processed state without cycling.
                    if (ray.Path.Contains(key)) { output.LoopDetected = true; break; }
                    if (!processed.Add(key)) break;
                    ray.Path.Add(key);
                    int nextX = x + Dx[direction], nextY = y + Dy[direction];
                    if (!Inside(nextX, nextY, width, height))
                    {
                        Segment(output, fromX, fromY, x + .5f + Dx[direction] * .5f, y + .5f + Dy[direction] * .5f, color);
                        break;
                    }
                    grid.TryGetValue((nextX, nextY), out var item);
                    if (item == null || item.Kind == ObjectKind.Source) { x = nextX; y = nextY; continue; }
                    if (item.Kind == ObjectKind.Target)
                    {
                        output.Hits[item.Id] |= color;
                        x = nextX; y = nextY; continue;
                    }
                    Segment(output, fromX, fromY, nextX + .5f, nextY + .5f, color);
                    void Enqueue(int outgoing, int mask)
                    {
                        queue.Enqueue(new Ray { X = nextX, Y = nextY, Direction = outgoing, Color = mask, Path = new HashSet<(int, int, int, int)>(ray.Path) });
                    }
                    if (item.Kind == ObjectKind.Mirror)
                    {
                        int outgoing = Reflections[Normalize(item.Orientation), direction];
                        if (outgoing >= 0) Enqueue(outgoing, color);
                    }
                    else if (item.Kind == ObjectKind.Prism)
                    {
                        if (color == 7)
                        {
                            int angle = Normalize(item.Orientation);
                            Enqueue(angle, 1); Enqueue((angle + 1) % 4, 2); Enqueue((angle + 3) % 4, 4);
                        }
                        else Enqueue(direction, color);
                    }
                    break;
                }
            }
            output.Solved = targets.Count > 0;
            foreach (var target in targets)
                if (output.Hits[target.Id] != target.Color) output.Solved = false;
            return output;
        }

        private static bool Inside(int x, int y, int width, int height) => x >= 0 && y >= 0 && x < width && y < height;
        private static void Segment(TraceResult result, float fromX, float fromY, float toX, float toY, int color)
        {
            if (fromX != toX || fromY != toY)
                result.Segments.Add(new BeamSegment { FromX = fromX, FromY = fromY, ToX = toX, ToY = toY, Color = color });
        }
    }
}
