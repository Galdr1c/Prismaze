using System;
using System.Collections.Generic;

namespace Prismaze.Core
{
    // Design 6.4: a move rotates a single rotatable object to its next
    // orientation. Every candidate state is evaluated with RayTracer, whose
    // solved verdict is the WinChecker. BFS guarantees the shortest
    // solution; counting stops as soon as two solutions are known. This runs
    // only in editor/build tooling, never on a player device.
    public sealed class Solver
    {
        public const int MaxSolutions = 2;

        sealed class Node
        {
            public Dictionary<string, int> Orientations;
            public int Depth;
            public List<string> Path;
        }

        public SolveResult Solve(BoardObject[] objects, int width, int height)
        {
            var rotatable = new List<int>();
            var start = new Dictionary<string, int>(StringComparer.Ordinal);
            for (int i = 0; i < objects.Length; i++)
                if (objects[i].Rotatable)
                {
                    rotatable.Add(i);
                    start[objects[i].Id] = objects[i].Orientation;
                }
            var result = new SolveResult();
            if (RayTracer.Trace(objects, width, height).Solved)
            {
                result.Solvable = true;
                result.SolutionCount = 1;
                result.ShortestSolution = 0;
                return result;
            }
            if (rotatable.Count == 0) return result;
            var visited = new HashSet<string>(StringComparer.Ordinal) { StateKey(objects, rotatable, start) };
            var queue = new Queue<Node>();
            queue.Enqueue(new Node { Orientations = start, Depth = 0, Path = new List<string>() });
            int foundDepth = -1;
            while (queue.Count > 0 && result.SolutionCount < MaxSolutions)
            {
                var node = queue.Dequeue();
                if (foundDepth >= 0 && node.Depth > foundDepth) break;
                foreach (int index in rotatable)
                {
                    var next = new Dictionary<string, int>(node.Orientations, StringComparer.Ordinal);
                    next[objects[index].Id] = (next[objects[index].Id] + 1) % 4;
                    string key = StateKey(objects, rotatable, next);
                    if (!visited.Add(key)) continue;
                    Apply(objects, rotatable, next);
                    var path = new List<string>(node.Path) { objects[index].Id };
                    if (RayTracer.Trace(objects, width, height).Solved)
                    {
                        if (result.SolutionCount < MaxSolutions) result.SolutionCount++;
                        if (foundDepth < 0)
                        {
                            foundDepth = node.Depth + 1;
                            result.Solvable = true;
                            result.ShortestSolution = foundDepth;
                            result.FirstSolution = path.ToArray();
                        }
                        if (result.SolutionCount >= MaxSolutions) break;
                    }
                    else queue.Enqueue(new Node { Orientations = next, Depth = node.Depth + 1, Path = path });
                }
            }
            // Restore caller's orientations; solving is read-only on input.
            Apply(objects, rotatable, start);
            return result;
        }

        static void Apply(BoardObject[] objects, List<int> rotatable, Dictionary<string, int> orientations)
        {
            foreach (int index in rotatable)
                objects[index].Orientation = orientations[objects[index].Id];
        }

        static string StateKey(BoardObject[] objects, List<int> rotatable, Dictionary<string, int> orientations)
        {
            var builder = new System.Text.StringBuilder();
            foreach (int index in rotatable)
                builder.Append(objects[index].Id).Append(':').Append(orientations[objects[index].Id]).Append(',');
            return builder.ToString();
        }
    }

    public sealed class SolveResult
    {
        public bool Solvable;
        public int ShortestSolution;
        public int SolutionCount;
        public string[] FirstSolution = Array.Empty<string>();
    }
}