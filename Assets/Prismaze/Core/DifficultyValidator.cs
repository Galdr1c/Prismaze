using System;
using System.Collections.Generic;

namespace Prismaze.Core
{
    // Design 6.4 metrics. branch_count is the distinct solved states at the
    // shortest depth (the solver's early-stopped solution_count signal).
    // Generator v1 computes shortest_solution, color_dependencies and
    // beam_intersections; decision_points, prism_dependencies and
    // misleading_rotations are not computed in v1 and contribute 0
    // (documented in the implementation plan).
    public sealed class DifficultyValidator
    {
        public DifficultyMetrics Evaluate(BoardObject[] objects, int width, int height)
        {
            var metrics = new DifficultyMetrics();
            var outcome = new Solver().Solve(objects, width, height);
            metrics.Solvable = outcome.Solvable;
            metrics.ShortestSolution = outcome.ShortestSolution;
            metrics.SolutionCount = outcome.SolutionCount;
            metrics.BranchCount = outcome.SolutionCount;
            if (!outcome.Solvable) return metrics;

            var moved = new HashSet<string>(outcome.FirstSolution, StringComparer.Ordinal);
            foreach (var item in objects)
                if (item.Rotatable)
                {
                    if (moved.Contains(item.Id)) metrics.ActiveObjects++;
                    else metrics.IrrelevantObjects++;
                }

            // Beam metrics come from the trace after replaying the first
            // solution path over the scrambled start.
            var saved = new Dictionary<string, int>(StringComparer.Ordinal);
            foreach (var item in objects)
                if (item.Rotatable) saved[item.Id] = item.Orientation;
            foreach (var id in outcome.FirstSolution)
                foreach (var item in objects)
                    if (item.Id == id) { item.Orientation = (item.Orientation + 1) % 4; break; }
            var trace = RayTracer.Trace(objects, width, height);
            metrics.BeamLength = BeamLength(trace);
            metrics.BeamIntersections = Intersections(trace);
            metrics.CycleFound = trace.LoopDetected;
            foreach (var item in objects)
                if (item.Rotatable) item.Orientation = saved[item.Id];

            metrics.ColorDependencies = ColorDependencies(objects);
            double baseScore = 0.30 * metrics.ShortestSolution
                + 0.20 * metrics.ColorDependencies
                + 0.10 * metrics.BeamIntersections;
            metrics.DifficultyScore = Math.Clamp((int)Math.Round(100.0 * baseScore, MidpointRounding.AwayFromZero) - 8 * metrics.IrrelevantObjects, 0, 100);
            return metrics;
        }

        static float BeamLength(TraceResult trace)
        {
            float total = 0f;
            foreach (var segment in trace.Segments)
                total += Math.Abs(segment.ToX - segment.FromX) + Math.Abs(segment.ToY - segment.FromY);
            return total;
        }

        // Crossings between perpendicular beam segments, counted only at
        // strictly interior points so same-beam corners and parallel
        // overlaps stay out.
        static int Intersections(TraceResult trace)
        {
            int count = 0;
            for (int i = 0; i < trace.Segments.Count; i++)
                for (int j = i + 1; j < trace.Segments.Count; j++)
                    if (Crosses(trace.Segments[i], trace.Segments[j])) count++;
            return count;
        }

        static bool Crosses(BeamSegment a, BeamSegment b)
        {
            bool aHorizontal = a.FromY == a.ToY;
            bool bHorizontal = b.FromY == b.ToY;
            if (aHorizontal == bHorizontal) return false;
            var horizontal = aHorizontal ? a : b;
            var vertical = aHorizontal ? b : a;
            float hx1 = Math.Min(horizontal.FromX, horizontal.ToX), hx2 = Math.Max(horizontal.FromX, horizontal.ToX);
            float hy = horizontal.FromY;
            float vx = vertical.FromX;
            float vy1 = Math.Min(vertical.FromY, vertical.ToY), vy2 = Math.Max(vertical.FromY, vertical.ToY);
            return hx1 < vx && vx < hx2 && vy1 < hy && hy < vy2;
        }

        static int ColorDependencies(BoardObject[] objects)
        {
            int count = 0;
            foreach (var item in objects)
                if (item.Kind == ObjectKind.Target)
                {
                    int bits = 0;
                    for (int bit = 1; bit <= 4; bit <<= 1)
                        if ((item.Color & bit) != 0) bits++;
                    if (bits >= 2) count++;
                }
            return count;
        }
    }

    public sealed class DifficultyMetrics
    {
        public bool Solvable;
        public int ShortestSolution;
        public int SolutionCount;
        public int ActiveObjects;
        public int IrrelevantObjects;
        public float BeamLength;
        public int BeamIntersections;
        public int ColorDependencies;
        public int BranchCount;
        public bool CycleFound;
        public int DifficultyScore;
    }
}