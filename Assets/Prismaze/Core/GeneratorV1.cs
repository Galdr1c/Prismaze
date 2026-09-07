using System;
using System.Collections.Generic;

namespace Prismaze.Core
{
    public interface IGenerator
    {
        int Version { get; }
        GenerationOutcome Generate(string profile, long seed, int levelIndex);
    }

    // Full solved-state -> scramble -> solver -> difficulty pipeline
    // (design 6.6). Retries are deterministic: attempt n uses seed + n, so a
    // fixed seed always regenerates the same accepted level.
    public sealed class GeneratorV1 : IGenerator
    {
        public const int MaxAttempts = 200;
        // Design 6.5 target solution behavior; thresholds are frozen for
        // generator v1.
        static readonly int[] TutorialMoves = { 1, 3 }, EasyMoves = { 2, 5 }, MediumMoves = { 5, 9 }, HardMoves = { 8, 14 };
        const int TutorialIrrelevant = 0, EasyIrrelevant = 1, MediumIrrelevant = 2, HardIrrelevant = 2;

        readonly LayoutGenerator layout = new LayoutGenerator();
        readonly SolvedBoardBuilder builder = new SolvedBoardBuilder();
        readonly ScrambleService scramble = new ScrambleService();
        readonly DifficultyValidator validator = new DifficultyValidator();

        public int Version => 1;

        public GenerationOutcome Generate(string profile, long seed, int levelIndex)
        {
            for (int attempt = 0; attempt < MaxAttempts; attempt++)
            {
                long attemptSeed = seed + attempt;
                var built = builder.Build(layout.Generate(profile, attemptSeed).Placements, LayoutGenerator.Width, LayoutGenerator.Height);
                if (!built.Ok) continue;
                var scrambled = scramble.Scramble(built.Objects, LayoutGenerator.Width, LayoutGenerator.Height, attemptSeed);
                if (!scrambled.Ok) continue;
                var metrics = validator.Evaluate(built.Objects, LayoutGenerator.Width, LayoutGenerator.Height);
                if (!Accepts(profile, metrics)) continue;
                var definition = Definition(levelIndex, profile, built, metrics);
                return new GenerationOutcome
                {
                    Ok = true,
                    GeneratorVersion = Version,
                    Profile = profile,
                    Seed = attemptSeed,
                    Attempts = attempt + 1,
                    Definition = definition,
                    Metrics = metrics,
                    Signature = definition.Fingerprint(),
                };
            }
            return new GenerationOutcome { Ok = false, GeneratorVersion = Version, Profile = profile, Attempts = MaxAttempts };
        }

        bool Accepts(string profile, DifficultyMetrics metrics)
        {
            int[] moves; int maxIrrelevant;
            switch (profile)
            {
                case "tutorial": moves = TutorialMoves; maxIrrelevant = TutorialIrrelevant; break;
                case "medium": moves = MediumMoves; maxIrrelevant = MediumIrrelevant; break;
                case "hard": moves = HardMoves; maxIrrelevant = HardIrrelevant; break;
                default: moves = EasyMoves; maxIrrelevant = EasyIrrelevant; break;
            }
            if (!metrics.Solvable || metrics.CycleFound) return false;
            if (metrics.ShortestSolution < moves[0] || metrics.ShortestSolution > moves[1]) return false;
            return metrics.IrrelevantObjects <= maxIrrelevant;
        }

        static LevelData Definition(int levelIndex, string profile, BoardBuildResult built, DifficultyMetrics metrics)
        {
            string title = char.ToUpperInvariant(profile[0]) + profile.Substring(1);
            return new LevelData
            {
                Id = levelIndex,
                Title = "Endless · " + title,
                Lesson = "Işığı " + metrics.ShortestSolution + " hamlede hedefe ulaştır.",
                Width = LayoutGenerator.Width,
                Height = LayoutGenerator.Height,
                ParMoves = metrics.ShortestSolution,
                Objects = built.Objects,
                Solution = built.Solution,
            };
        }
    }

    // Design 6.7: published generator versions are frozen; only versions
    // whose levels are still in the game stay servable.
    public sealed class GeneratorFactory
    {
        public IGenerator Create(int version)
        {
            if (version == 1) return new GeneratorV1();
            return null;
        }
    }

    public sealed class GenerationOutcome
    {
        public bool Ok;
        public int GeneratorVersion;
        public string Profile;
        public long Seed;
        public int Attempts;
        public LevelData Definition;
        public DifficultyMetrics Metrics;
        public string Signature;
    }
}