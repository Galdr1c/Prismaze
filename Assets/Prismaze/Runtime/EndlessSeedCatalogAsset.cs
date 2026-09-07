using System;
using System.Collections.Generic;
using Prismaze.Core;
using UnityEngine;

namespace Prismaze.Unity
{
    // Design 6.6: runtime reads only pre-verified endless levels from this
    // catalog; it never rolls a fresh seed. Serialized fields mirror the
    // Core CatalogEntry contract so the asset is inspectable in the editor.
    [CreateAssetMenu(menuName = "Prismaze/Endless Seed Catalog", fileName = "endless_seed_catalog_v1")]
    public sealed class EndlessSeedCatalogAsset : ScriptableObject
    {
        [Serializable]
        public sealed class Record
        {
            public int GeneratorVersion;
            public int LevelIndex;
            public long Seed;
            public string Signature;
            public string DifficultyProfile;
            public int DifficultyScore;
        }

        public List<Record> Records = new List<Record>();

        public static EndlessSeedCatalogAsset From(SeedCatalog catalog)
        {
            var asset = CreateInstance<EndlessSeedCatalogAsset>();
            foreach (var entry in catalog.Entries)
                asset.Records.Add(new Record
                {
                    GeneratorVersion = entry.GeneratorVersion,
                    LevelIndex = entry.LevelIndex,
                    Seed = entry.Seed,
                    Signature = entry.Signature,
                    DifficultyProfile = entry.DifficultyProfile,
                    DifficultyScore = entry.DifficultyScore,
                });
            return asset;
        }

        public SeedCatalog ToCatalog()
        {
            var catalog = new SeedCatalog();
            foreach (var record in Records)
                catalog.Entries.Add(new CatalogEntry
                {
                    GeneratorVersion = record.GeneratorVersion,
                    LevelIndex = record.LevelIndex,
                    Seed = record.Seed,
                    Signature = record.Signature,
                    DifficultyProfile = record.DifficultyProfile,
                    DifficultyScore = record.DifficultyScore,
                });
            return catalog;
        }
    }
}