using System;
using System.Collections.Generic;

namespace Prismaze.Core
{
    // Design 6.3: builds the valid light path first. Rotatables are searched
    // in placement order with ascending orientations after the
    // canonical-friendly 3, so the first valid assignment is deterministic.
    // Target colors are fixed from the masks the built path delivers.
    public sealed class SolvedBoardBuilder
    {
        static readonly int[] OrientationOrder = { 3, 0, 1, 2 };

        public BoardBuildResult Build(BoardObject[] placements, int width, int height)
        {
            var rotatables = new List<BoardObject>();
            foreach (var item in placements)
                if (item.Rotatable) rotatables.Add(item);
            var assignment = new Dictionary<string, int>(StringComparer.Ordinal);
            if (!Assign(placements, width, height, rotatables, 0, assignment))
                return BoardBuildResult.Failed();
            var objects = Materialize(placements, assignment);
            var trace = RayTracer.Trace(objects, width, height);
            if (!trace.Valid) return BoardBuildResult.Failed();
            var colors = new Dictionary<string, int>(StringComparer.Ordinal);
            foreach (var item in objects)
                if (item.Kind == ObjectKind.Target)
                {
                    int mask = trace.Hits[item.Id];
                    if (mask == 0) return BoardBuildResult.Failed();
                    colors[item.Id] = mask;
                    item.Color = mask;
                }
            var solution = new OrientationEntry[rotatables.Count];
            for (int i = 0; i < rotatables.Count; i++)
                solution[i] = new OrientationEntry { Id = rotatables[i].Id, Orientation = assignment[rotatables[i].Id] };
            return new BoardBuildResult { Ok = true, Objects = objects, Solution = solution, TargetColors = colors };
        }

        bool Assign(BoardObject[] placements, int width, int height, List<BoardObject> rotatables, int index, Dictionary<string, int> assignment)
        {
            if (index == rotatables.Count)
            {
                var objects = Materialize(placements, assignment);
                var trace = RayTracer.Trace(objects, width, height);
                if (!trace.Valid) return false;
                // Every target must actually receive light; a dead target
                // would be "satisfied" by the zero mask.
                foreach (var item in objects)
                    if (item.Kind == ObjectKind.Target && trace.Hits[item.Id] == 0)
                        return false;
                // Fix target colors from delivered masks and confirm solved.
                foreach (var item in objects)
                    if (item.Kind == ObjectKind.Target) item.Color = trace.Hits[item.Id];
                return RayTracer.Trace(objects, width, height).Solved;
            }
            foreach (int orientation in OrientationOrder)
            {
                assignment[rotatables[index].Id] = orientation;
                if (Assign(placements, width, height, rotatables, index + 1, assignment)) return true;
            }
            assignment.Remove(rotatables[index].Id);
            return false;
        }

        static BoardObject[] Materialize(BoardObject[] placements, Dictionary<string, int> assignment)
        {
            var objects = new BoardObject[placements.Length];
            for (int i = 0; i < placements.Length; i++)
            {
                var item = placements[i].Clone();
                if (item.Rotatable) item.Orientation = assignment[item.Id];
                objects[i] = item;
            }
            return objects;
        }
    }

    public sealed class BoardBuildResult
    {
        public bool Ok;
        public BoardObject[] Objects;
        public OrientationEntry[] Solution;
        public Dictionary<string, int> TargetColors;
        public static BoardBuildResult Failed() => new BoardBuildResult { Ok = false };
    }
}