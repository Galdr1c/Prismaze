using System;
using System.Collections.Generic;

namespace Prismaze.Core
{
    // Design 6.4: layout = topology only. Generator v1 ships the seeded
    // staircase template family; walls and prisms arrive with later
    // generator versions. Same seed always reproduces the same placements.
    public sealed class LayoutGenerator
    {
        public const int Width = 6, Height = 12;
        // Design 6.5 content limits. Hard is capped at 7 mirrors because the
        // staircase consumes one board column per two mirrors.
        static readonly int[] TutorialRange = { 1, 2 }, EasyRange = { 2, 4 }, MediumRange = { 3, 7 }, HardRange = { 5, 7 };

        static int[] RangeFor(string profile)
        {
            switch (profile)
            {
                case "tutorial": return TutorialRange;
                case "medium": return MediumRange;
                case "hard": return HardRange;
                default: return EasyRange;
            }
        }

        public Layout Generate(string profile, long seed)
        {
            int[] range = RangeFor(profile);
            var rng = new DeterministicRng(seed);
            int mirrorCount = rng.Next(range[0], range[1]);
            int targetOffset = mirrorCount % 2 == 0 ? mirrorCount / 2 : (mirrorCount + 1) / 2 + 1;
            int y0 = rng.Next(0, Math.Max(0, Height - 1 - targetOffset));
            var placements = new List<BoardObject>
            {
                new BoardObject { Id = "s", Kind = ObjectKind.Source, X = 0, Y = y0, Orientation = 1, Color = 7 },
            };
            for (int i = 0; i < mirrorCount; i++)
                placements.Add(new BoardObject { Id = "m" + i, Kind = ObjectKind.Mirror, X = 2 + i / 2, Y = y0 + (i + 1) / 2, Color = 7 });
            if (mirrorCount % 2 == 0)
                placements.Add(new BoardObject { Id = "t", Kind = ObjectKind.Target, X = 5, Y = y0 + mirrorCount / 2, Color = 7 });
            else
                placements.Add(new BoardObject { Id = "t", Kind = ObjectKind.Target, X = 2 + (mirrorCount - 1) / 2, Y = y0 + (mirrorCount + 1) / 2 + 1, Color = 7 });
            return new Layout { Profile = profile, Seed = seed, MirrorCount = mirrorCount, Width = Width, Height = Height, Placements = placements.ToArray() };
        }
    }

    public sealed class Layout
    {
        public string Profile;
        public long Seed;
        public int MirrorCount, Width, Height;
        public BoardObject[] Placements;
    }
}