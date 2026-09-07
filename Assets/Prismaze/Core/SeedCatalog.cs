using System;
using System.Collections.Generic;

namespace Prismaze.Core
{
    // Design 6.6: a verified endless level record. Runtime never rolls a
    // fresh seed; it regenerates an entry and verifies its signature.
    public sealed class CatalogEntry
    {
        public int GeneratorVersion;
        public int LevelIndex;
        public long Seed;
        public string Signature;
        public string DifficultyProfile;
        public int DifficultyScore;
    }

    public sealed class RegenerationResult
    {
        public bool Ok;
        public LevelData Definition;
        public static RegenerationResult Failed() => new RegenerationResult { Ok = false };
    }

    public sealed class SeedCatalog
    {
        public List<CatalogEntry> Entries = new List<CatalogEntry>();

        public CatalogEntry Next(string profile, int index)
        {
            var pool = new List<CatalogEntry>();
            foreach (var entry in Entries)
                if (entry.DifficultyProfile == profile) pool.Add(entry);
            if (pool.Count == 0) return null;
            int wrapped = index % pool.Count;
            if (wrapped < 0) wrapped += pool.Count;
            return pool[wrapped];
        }

        public RegenerationResult Regenerate(CatalogEntry entry)
        {
            if (entry == null) return RegenerationResult.Failed();
            var generator = new GeneratorFactory().Create(entry.GeneratorVersion);
            if (generator == null) return RegenerationResult.Failed();
            var outcome = generator.Generate(entry.DifficultyProfile, entry.Seed, entry.LevelIndex);
            if (!outcome.Ok || outcome.Signature != entry.Signature) return RegenerationResult.Failed();
            return new RegenerationResult { Ok = true, Definition = outcome.Definition };
        }

        // Design 6.6: on a signature mismatch fall back to a pre-validated
        // entry from the same catalog instead of generating anything new.
        public RegenerationResult Emergency()
        {
            foreach (var entry in Entries)
            {
                var result = Regenerate(entry);
                if (result.Ok) return result;
            }
            return RegenerationResult.Failed();
        }
    }

    // Design 6.6: for each profile scan seeds deterministically, push every
    // candidate through the generator pipeline, and keep only accepted
    // entries. Same count + base_seed always rebuilds the identical catalog.
    // minScan guarantees a minimum number of candidate seeds are evaluated
    // per profile (plan §10.6 scans at least 10,000 candidates).
    public sealed class CatalogBuilder
    {
        public const int SeedLimit = 100000;
        static readonly string[] Profiles = { "tutorial", "easy", "medium", "hard" };

        public SeedCatalog Build(int countPerProfile, long baseSeed = 1, int minScan = 0)
        {
            var catalog = new SeedCatalog();
            var generator = new GeneratorFactory().Create(1);
            int levelIndex = 1;
            foreach (var profile in Profiles)
            {
                int found = 0, scanned = 0;
                long seedValue = baseSeed;
                while ((found < countPerProfile || scanned < minScan) && scanned < SeedLimit)
                {
                    scanned++;
                    var outcome = generator.Generate(profile, seedValue, levelIndex);
                    if (outcome.Ok)
                    {
                        catalog.Entries.Add(new CatalogEntry
                        {
                            GeneratorVersion = outcome.GeneratorVersion,
                            LevelIndex = levelIndex,
                            Seed = outcome.Seed,
                            Signature = outcome.Signature,
                            DifficultyProfile = profile,
                            DifficultyScore = outcome.Metrics.DifficultyScore,
                        });
                        found++;
                        levelIndex++;
                    }
                    seedValue++;
                }
            }
            return catalog;
        }
    }
}