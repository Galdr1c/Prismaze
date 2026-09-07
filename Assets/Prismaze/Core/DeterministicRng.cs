using System;

namespace Prismaze.Core
{
    // Design 6.7: generator v1 freezes its own RNG so the same seed replays
    // the same level on every platform and every runtime. System.Random and
    // UnityEngine.Random are never relied on for published content. This is
    // a SplitMix64 bit source with rejection sampling for ranged draws.
    public sealed class DeterministicRng
    {
        ulong _state;

        public DeterministicRng(long seed) => _state = (ulong)seed;

        public ulong NextUInt64()
        {
            _state += 0x9E3779B97F4A7C15UL;
            ulong z = _state;
            z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9UL;
            z = (z ^ (z >> 27)) * 0x94D049BB133111EBUL;
            return z ^ (z >> 31);
        }

        // Inclusive on both ends, matching the legacy randi_range contract.
        public int Next(int minInclusive, int maxInclusive)
        {
            if (maxInclusive < minInclusive) throw new ArgumentOutOfRangeException(nameof(maxInclusive));
            ulong range = (ulong)((long)maxInclusive - (long)minInclusive + 1L);
            if (range == 1) return minInclusive;
            // Rejection sampling keeps non-power-of-two spans uniform.
            ulong limit = ulong.MaxValue - (ulong.MaxValue % range);
            ulong value;
            do { value = NextUInt64(); } while (value >= limit);
            return (int)(minInclusive + (long)(value % range));
        }
    }
}