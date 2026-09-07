using System;
using System.Collections.Generic;

namespace Prismaze.Core
{
    // Design 6.3: converts solved orientations into the player's start.
    // Each attempt reseeds the RNG with seed + attempt, so retries are
    // deterministic. A layout whose targets stay lit regardless of mirror
    // orientation can never scramble; we bail out instead of looping forever.
    public sealed class ScrambleService
    {
        public const int MaxAttempts = 64;

        public ScrambleResult Scramble(BoardObject[] objects, int width, int height, long seed)
        {
            var canonical = new Dictionary<string, int>(StringComparer.Ordinal);
            foreach (var item in objects)
                if (item.Rotatable) canonical[item.Id] = item.Orientation;
            for (int attempt = 0; attempt < MaxAttempts; attempt++)
            {
                var rng = new DeterministicRng(seed + attempt);
                var initial = new Dictionary<string, int>(StringComparer.Ordinal);
                foreach (var item in objects)
                    if (item.Rotatable)
                    {
                        item.Orientation = (canonical[item.Id] + rng.Next(0, 3)) % 4;
                        initial[item.Id] = item.Orientation;
                    }
                bool differs = false;
                foreach (var pair in canonical)
                    if (initial[pair.Key] != pair.Value) { differs = true; break; }
                if (differs && !RayTracer.Trace(objects, width, height).Solved)
                    return new ScrambleResult { Ok = true, InitialOrientations = initial, Attempts = attempt + 1 };
            }
            return new ScrambleResult { Ok = false, Attempts = MaxAttempts };
        }
    }

    public sealed class ScrambleResult
    {
        public bool Ok;
        public int Attempts;
        public Dictionary<string, int> InitialOrientations = new Dictionary<string, int>(StringComparer.Ordinal);
    }
}