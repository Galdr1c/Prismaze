using System;
using System.Collections.Generic;
using System.Linq;

namespace Prismaze.Core
{
    public class GameSession
    {
        public LevelData Definition { get; private set; }
        public BoardObject[] Objects { get; private set; } = Array.Empty<BoardObject>();
        public TraceResult Result { get; private set; } = new TraceResult();
        public int Moves { get; private set; }
        public double Elapsed { get; set; }
        public void Start(LevelData level)
        {
            if (level == null) throw new ArgumentNullException(nameof(level));
            Definition = level;
            Reset();
        }
        public void Reset()
        {
            if (Definition == null) throw new InvalidOperationException("Start a level first.");
            Objects = Definition.Objects.Select(item => item.Clone()).ToArray();
            foreach (var item in Objects) item.Orientation = RayTracer.Normalize(item.Orientation);
            Moves = 0; Elapsed = 0;
            Result = RayTracer.Trace(Objects, Definition.Width, Definition.Height);
        }
        public bool Rotate(string id)
        {
            if (Result.Solved) return false;
            foreach (var item in Objects)
            {
                if (item.Id != id || !item.Rotatable) continue;
                item.Orientation = (RayTracer.Normalize(item.Orientation) + 1) % 4;
                Moves++;
                Result = RayTracer.Trace(Objects, Definition.Width, Definition.Height);
                return true;
            }
            return false;
        }
        public int OrientationOf(string id)
        {
            foreach (var item in Objects) if (item.Id == id) return item.Orientation;
            return -1;
        }
        public OrientationEntry Hint()
        {
            if (Definition == null || Result.Solved) return null;
            foreach (var entry in Definition.Solution)
                if (OrientationOf(entry.Id) != entry.Orientation)
                    return new OrientationEntry { Id = entry.Id, Orientation = entry.Orientation };
            return null;
        }
        public SessionSnapshot Snapshot()
        {
            if (Definition == null) throw new InvalidOperationException("Start a level first.");
            return new SessionSnapshot {
                LevelId = Definition.Id, Fingerprint = Definition.Fingerprint(), Moves = Moves, Elapsed = Elapsed,
                Orientations = Objects.Where(o => o.Rotatable).Select(o => new OrientationEntry { Id = o.Id, Orientation = o.Orientation }).ToArray()
            };
        }
        public bool Restore(SessionSnapshot snapshot)
        {
            if (Definition == null || snapshot == null || snapshot.LevelId != Definition.Id
                || snapshot.Fingerprint != Definition.Fingerprint() || snapshot.Orientations == null
                || snapshot.Moves < 0 || snapshot.Elapsed < 0 || double.IsNaN(snapshot.Elapsed) || double.IsInfinity(snapshot.Elapsed))
                return false;
            var expected = new HashSet<string>(Definition.Objects.Where(o => o.Rotatable).Select(o => o.Id), StringComparer.Ordinal);
            if (snapshot.Orientations.Length != expected.Count) return false;
            var angles = new Dictionary<string, int>(StringComparer.Ordinal);
            foreach (var entry in snapshot.Orientations)
            {
                if (entry == null || entry.Id == null || !expected.Contains(entry.Id)
                    || entry.Orientation < 0 || entry.Orientation > 3 || angles.ContainsKey(entry.Id)) return false;
                angles.Add(entry.Id, entry.Orientation);
            }
            // Build and trace a candidate before committing any session state.
            var candidate = Objects.Select(o => o.Clone()).ToArray();
            foreach (var item in candidate)
                if (item.Rotatable)
                {
                    if (!angles.TryGetValue(item.Id, out int angle)) return false;
                    item.Orientation = angle;
                }
            var result = RayTracer.Trace(candidate, Definition.Width, Definition.Height);
            if (!result.Valid) return false;
            Objects = candidate; Result = result;
            Moves = snapshot.Moves; Elapsed = snapshot.Elapsed;
            return true;
        }
    }
}
