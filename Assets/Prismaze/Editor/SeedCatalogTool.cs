using System.IO;
using Prismaze.Core;
using UnityEditor;
using UnityEngine;

namespace Prismaze.Unity.Editor
{
    // Plan §10.6: development tool that scans at least 10,000 candidate
    // seeds per profile through the solved-state -> scramble -> solver ->
    // difficulty pipeline and records every accepted entry. Runtime never
    // retries; it only regenerates these verified entries. Re-running the
    // same counts/base seed rebuilds an identical catalog (determinism is
    // asserted in Tests/Core).
    public static class SeedCatalogTool
    {
        const string AssetPath = "Assets/Resources/Catalogs/endless_seed_catalog_v1.asset";
        const int CountPerProfile = 20;
        const int MinScan = 10000;

        [MenuItem("Prismaze/Build Endless Seed Catalog")]
        public static void Build()
        {
            Directory.CreateDirectory("Assets/Resources/Catalogs");
            var builder = new CatalogBuilder();
            var catalog = builder.Build(CountPerProfile, baseSeed: 1, minScan: MinScan);
            if (catalog.Entries.Count == 0)
            {
                Debug.LogError("Prismaze: seed catalog is empty; generator failed for every candidate.");
                return;
            }
            var asset = EndlessSeedCatalogAsset.From(catalog);
            AssetDatabase.CreateAsset(asset, AssetPath);
            AssetDatabase.SaveAssets();
            Debug.Log($"Prismaze: endless seed catalog written with {catalog.Entries.Count} verified entries to {AssetPath}.");
        }
    }
}