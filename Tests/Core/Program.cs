using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Text.RegularExpressions;
using Prismaze.Core;

internal static class Program
{
    private static int checks, failures;
    private static readonly int[] Dx = { 0, 1, 0, -1 }, Dy = { -1, 0, 1, 0 };
    private static BoardObject O(string id, ObjectKind kind, int x, int y, int orientation = 0, int color = 7)
        => new BoardObject { Id = id, Kind = kind, X = x, Y = y, Orientation = orientation, Color = color };
    private static void Check(bool condition, string message)
    {
        checks++;
        if (!condition) throw new Exception(message);
    }
    private static void Run(string name, Action test)
    {
        try { test(); Console.WriteLine("PASS " + name); }
        catch (Exception e) { failures++; Console.Error.WriteLine("FAIL " + name + ": " + e.Message); }
    }
    private static int Main()
    {
        Run("mirror truth table and cell centres", Mirrors);
        Run("colors, transparent targets/sources, walls and crossings", Colors);
        Run("white prism ports and nonwhite transmission", Prisms);
        Run("loops versus converging rays", Loops);
        Run("invalid boards", InvalidBoards);
        Run("all twelve literal levels and canonical replays", CampaignTests);
        Run("session snapshot validation is atomic", Sessions);
        Run("fingerprint determinism and gameplay identity", Fingerprints);
        Console.WriteLine($"{checks} assertions; {failures} failed groups.");
        return failures == 0 ? 0 : 1;
    }

    private static void Mirrors()
    {
        int[,] expected = { { -1, 3, -1, 1 }, { 1, 0, 3, 2 }, { 2, -1, 0, -1 }, { 3, 2, 1, 0 } };
        for (int angle = 0; angle < 4; angle++)
        for (int incoming = 0; incoming < 4; incoming++)
        {
            var objects = new[] { O("s", ObjectKind.Source, 2 - Dx[incoming], 2 - Dy[incoming], incoming, 1), O("m", ObjectKind.Mirror, 2, 2, angle) };
            var result = RayTracer.Trace(objects, 5, 5);
            var outgoing = expected[angle, incoming];
            Check(result.Valid && !result.LoopDetected && result.Segments.Count == (outgoing < 0 ? 1 : 2), $"mirror {angle}/{incoming}");
            var first = result.Segments[0];
            Check(first.FromX == objects[0].X + .5f && first.FromY == objects[0].Y + .5f && first.ToX == 2.5f && first.ToY == 2.5f && first.Color == 1, "incoming centres");
            if (outgoing >= 0)
            {
                var last = result.Segments[1];
                Check(last.FromX == 2.5f && last.FromY == 2.5f && last.ToX == 2.5f + Dx[outgoing] * 2.5f && last.ToY == 2.5f + Dy[outgoing] * 2.5f, "outgoing reaches board edge");
            }
            Check(objects[1].Orientation == angle, "trace does not mutate mirror");
        }
        var normalized = RayTracer.Trace(new[] { O("s", ObjectKind.Source, 0, 2, -3), O("m", ObjectKind.Mirror, 2, 2, -1), O("t", ObjectKind.Target, 2, 4) });
        Check(normalized.Solved, "legacy positive-modulo orientations");
    }

    private static void Colors()
    {
        for (int a = 0; a <= 7; a++)
        for (int b = 0; b <= 7; b++)
        {
            var objects = new[] { O("a", ObjectKind.Source, 0, 2, 1, a), O("b", ObjectKind.Source, 2, 0, 2, b), O("t", ObjectKind.Target, 2, 2, 0, a | b) };
            var result = RayTracer.Trace(objects);
            Check(result.Solved && result.Hits["t"] == (a | b), "exact color OR");
            objects[2].Color = (a | b) ^ 1;
            Check(!RayTracer.Trace(objects).Solved, "wrong mask rejected");
        }
        var s = O("s", ObjectKind.Source, 0, 2, 1, 1);
        var t = O("t", ObjectKind.Target, 4, 2, 0, 1);
        Check(RayTracer.Trace(new[] { s, t, O("t2", ObjectKind.Target, 5, 2, 0, 1) }).Solved, "targets transmit");
        Check(!RayTracer.Trace(new[] { s }).Solved, "no targets not a win");
        var blocked = RayTracer.Trace(new[] { s, t, O("w", ObjectKind.Wall, 2, 2) });
        Check(blocked.Valid && !blocked.Solved && blocked.Segments.Single().ToX == 2.5f, "wall absorbs at centre");
        Check(RayTracer.Trace(new[] { s, t, O("b", ObjectKind.Source, 2, 0, 2, 4), O("bt", ObjectKind.Target, 2, 5, 0, 4) }).Solved, "crossings preserve separate colors");
        Check(RayTracer.Trace(new[] { s, t, O("s2", ObjectKind.Source, 2, 2, 0, 2) }).Solved, "source transmits incoming light");
    }

    private static void Prisms()
    {
        for (int angle = 0; angle < 4; angle++)
        for (int incoming = 0; incoming < 4; incoming++)
        {
            var objects = new List<BoardObject> { O("s", ObjectKind.Source, 3 - Dx[incoming] * 2, 3 - Dy[incoming] * 2, incoming), O("p", ObjectKind.Prism, 3, 3, angle) };
            var result = RayTracer.Trace(objects, 7, 7);
            Check(result.Segments.Count == 4, "one white input and three output segments");
            int[] ports = { 0, 1, 3 }, masks = { 1, 2, 4 };
            for (int p = 0; p < 3; p++)
            {
                int direction = (ports[p] + angle) % 4;
                var beam = result.Segments[p + 1];
                Check(beam.Color == masks[p] && beam.FromX == 3.5f && beam.FromY == 3.5f && beam.ToX == 3.5f + Dx[direction] * 3.5f && beam.ToY == 3.5f + Dy[direction] * 3.5f, "RGB fixed ports independent of input");
            }
            for (int mask = 0; mask < 7; mask++)
            {
                objects[0].Color = mask;
                var transmitted = RayTracer.Trace(objects, 7, 7);
                Check(transmitted.Segments.Count == 2 && transmitted.Segments[1].Color == mask && transmitted.Segments[1].ToX == 3.5f + Dx[incoming] * 3.5f && transmitted.Segments[1].ToY == 3.5f + Dy[incoming] * 3.5f, "nonwhite passes unchanged");
            }
        }
    }

    private static void Loops()
    {
        var result = RayTracer.Trace(new[] { O("s", ObjectKind.Source, 2, 2, 1, 1), O("m1", ObjectKind.Mirror, 4, 2), O("m2", ObjectKind.Mirror, 0, 2) });
        Check(result.Valid && result.LoopDetected && result.Segments.Count < 100, "opposing mirrors terminate");
        var merge = RayTracer.Trace(new[] { O("a", ObjectKind.Source, 0, 2, 1, 1), O("b", ObjectKind.Source, 1, 2, 1, 1), O("t", ObjectKind.Target, 4, 2, 0, 1) });
        Check(merge.Valid && merge.Solved && !merge.LoopDetected, "shared processed state is not a cycle");
        var splitLoop = RayTracer.Trace(new[] { O("s", ObjectKind.Source, 2, 4, 0), O("p", ObjectKind.Prism, 2, 2), O("top", ObjectKind.Mirror, 2, 0, 2), O("bottom", ObjectKind.Mirror, 2, 5, 2), O("green", ObjectKind.Target, 5, 2, 0, 2), O("blue", ObjectKind.Target, 0, 2, 0, 4) });
        Check(splitLoop.Valid && splitLoop.Solved && splitLoop.LoopDetected && splitLoop.Segments.Count < 100, "a prism branch may loop while sibling branches solve targets");
    }

    private static void InvalidBoards()
    {
        var s = O("s", ObjectKind.Source, 0, 0, 1);
        foreach (var bad in new[] { O("w", ObjectKind.Wall, 0, 0), O("s", ObjectKind.Target, 2, 2), O("w", ObjectKind.Wall, -1, 0), O("w", ObjectKind.Wall, 6, 0), O("w", ObjectKind.Wall, 0, 12), O(null, ObjectKind.Wall, 2, 2), O("w", (ObjectKind)99, 2, 2), O("w", ObjectKind.Source, 2, 2, 0, 8), null })
        {
            var result = RayTracer.Trace(new[] { s, bad });
            Check(!result.Valid && !result.Solved && result.Segments.Count == 0, "malformed board rejected before tracing");
        }
        Check(!RayTracer.Trace(null).Valid && !RayTracer.Trace(new[] { s }, 0, 12).Valid, "null and invalid dimensions rejected");
    }

    private static void CampaignTests()
    {
        var levels = Campaign.Create();
        Check(levels.Length == 12, "twelve levels");
        var root = new DirectoryInfo(AppContext.BaseDirectory);
        while (root != null && !Directory.Exists(Path.Combine(root.FullName, "LegacyGodot"))) root = root.Parent;
        Check(root != null, "legacy fixtures found");
        foreach (var level in levels)
        {
            var text = File.ReadAllText(Path.Combine(root.FullName, "LegacyGodot", "data", "levels", $"level_{level.Id:000}.tres"));
            string Field(string name) => Regex.Match(text, "(?m)^" + name + " = (.+)\r?$").Groups[1].Value.TrimEnd('\r');
            Check(level.Id == int.Parse(Field("id")) && level.Width == 6 && level.Height == 12 && level.ParMoves == int.Parse(Field("par_moves")), "literal dimensions/id/par");
            Check(level.Title == JsonSerializer.Deserialize<string>(Field("title")) && level.Lesson == JsonSerializer.Deserialize<string>(Field("lesson")), "literal Turkish text");
            var rawObjects = Field("objects");
            using var parsed = JsonDocument.Parse(rawObjects.Substring("Array[Dictionary](".Length).TrimEnd(')'));
            Check(parsed.RootElement.GetArrayLength() == level.Objects.Length, "literal object count");
            int index = 0;
            foreach (var obj in parsed.RootElement.EnumerateArray())
            {
                var actual = level.Objects[index++];
                Check(actual.Id == obj.GetProperty("id").GetString() && (int)actual.Kind == obj.GetProperty("kind").GetInt32() && actual.X == obj.GetProperty("x").GetInt32() && actual.Y == obj.GetProperty("y").GetInt32() && actual.Orientation == obj.GetProperty("orientation").GetInt32() && actual.Color == obj.GetProperty("color").GetInt32(), "every literal object field");
                var clone = actual.Clone();
                Check(!ReferenceEquals(actual, clone) && clone.Id == actual.Id && clone.Color == actual.Color && clone.Rotatable == ((int)actual.Kind == 1 || (int)actual.Kind == 2), "clone and rotation contract");
            }
            using var solution = JsonDocument.Parse(Field("solution"));
            index = 0;
            foreach (var entry in solution.RootElement.EnumerateObject())
            {
                Check(level.Solution[index].Id == entry.Name && level.Solution[index++].Orientation == entry.Value.GetInt32(), "literal solution and order");
            }
            Check(index == level.Solution.Length, "solution count");
            var fingerprint = level.Fingerprint();
            var session = new GameSession(); session.Start(level);
            Check(session.Result.Valid && !session.Result.Solved && session.Hint() != null, "campaign starts valid unsolved with hint");
            foreach (var entry in level.Solution)
                for (int tap = 0; session.OrientationOf(entry.Id) != entry.Orientation && tap < 4; tap++)
                    Check(session.Rotate(entry.Id), "canonical rotation accepted");
            Check(session.Result.Solved && session.Moves == level.ParMoves && session.Hint() == null, "canonical replay solves at par");
            Check(!session.Rotate(level.Solution[0].Id) && level.Fingerprint() == fingerprint, "win locks input and definition unchanged");
            session.Elapsed = 99; session.Reset();
            Check(session.Moves == 0 && session.Elapsed == 0 && !session.Result.Solved && session.Objects.Zip(level.Objects, (a, b) => !ReferenceEquals(a, b) && a.Orientation == b.Orientation).All(x => x), "reset clones initial state");
        }
        levels[0].Objects[0].X = 99; levels[0].Solution[0].Orientation = 0;
        Check(Campaign.Create()[0].Objects[0].X == 0 && Campaign.Create()[0].Solution[0].Orientation == 3, "fresh campaign graph each call");
    }

    private static string SnapshotText(GameSession session) => JsonSerializer.Serialize(session.Snapshot(), new JsonSerializerOptions { IncludeFields = true });
    private static void Sessions()
    {
        var session = new GameSession(); session.Start(Campaign.Create()[3]);
        var initial = SnapshotText(session);
        Check(!session.Rotate("s") && !session.Rotate("missing") && session.OrientationOf("missing") == -1 && SnapshotText(session) == initial, "fixed/missing no moves");
        var hint = session.Hint(); hint.Orientation = 99;
        Check(session.Hint().Orientation == 1, "hint detached");
        session.Rotate("m1"); session.Elapsed = 12.75;
        var saved = session.Snapshot();
        var restored = new GameSession(); restored.Start(Campaign.Create()[3]);
        Check(restored.Restore(saved) && SnapshotText(restored) == SnapshotText(session), "snapshot roundtrip");
        saved.Orientations[0].Orientation = 3;
        Check(restored.OrientationOf("m1") == 1, "snapshot detached after restore");
        var before = SnapshotText(restored); var objects = restored.Objects; var result = restored.Result;
        var mutations = new Action<SessionSnapshot>[] {
            s => s.LevelId++, s => s.Fingerprint = "bad", s => s.Moves = -1,
            s => s.Elapsed = -1, s => s.Elapsed = double.NaN, s => s.Elapsed = double.PositiveInfinity,
            s => s.Orientations = null, s => s.Orientations = s.Orientations.Take(1).ToArray(),
            s => s.Orientations[1].Id = s.Orientations[0].Id, s => s.Orientations[1].Id = "missing",
            s => s.Orientations[1].Id = "s", s => s.Orientations[1].Id = null,
            s => s.Orientations[1].Orientation = 4, s => s.Orientations[1].Orientation = -1,
            s => s.Orientations[1] = null
        };
        foreach (var mutate in mutations)
        {
            var corrupt = restored.Snapshot(); mutate(corrupt);
            Check(!restored.Restore(corrupt) && SnapshotText(restored) == before && ReferenceEquals(objects, restored.Objects) && ReferenceEquals(result, restored.Result), "invalid snapshot atomic rejection");
        }
        Check(!restored.Restore(null), "null snapshot rejected");
        var reordered = restored.Snapshot(); Array.Reverse(reordered.Orientations);
        Check(restored.Restore(reordered), "snapshot order independent");
        restored.Reset(); Check(SnapshotText(restored) == initial, "reset after restore");
        var empty = new GameSession();
        Check(!empty.Restore(session.Snapshot()) && empty.Hint() == null && !empty.Rotate("missing"), "unstarted session safe queries");
        var noHint = Campaign.Create()[0]; noHint.Solution = Array.Empty<OrientationEntry>();
        empty.Start(noHint); Check(empty.Hint() == null, "no canonical hint available");
        var won = new GameSession(); won.Start(Campaign.Create()[0]); won.Rotate("m1");
        var wonCopy = new GameSession(); wonCopy.Start(Campaign.Create()[0]);
        Check(wonCopy.Restore(won.Snapshot()) && wonCopy.Result.Solved && !wonCopy.Rotate("m1") && wonCopy.Hint() == null, "restored victory retraces and locks input");
    }

    private static void Fingerprints()
    {
        var level = Campaign.Create()[0]; var hash = level.Fingerprint();
        Check(Regex.IsMatch(hash, "^[0-9a-f]{64}$") && hash == Campaign.Create()[0].Fingerprint(), "stable SHA256");
        var culture = CultureInfo.CurrentCulture;
        try { CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo("tr-TR"); Check(level.Fingerprint() == hash, "culture invariant"); }
        finally { CultureInfo.CurrentCulture = culture; }
        Array.Reverse(level.Objects); Array.Reverse(level.Solution);
        Check(level.Fingerprint() == hash, "canonical object/solution ordering");
        level.Title = "translated"; level.Lesson = "translation"; level.ParMoves++;
        Check(level.Fingerprint() == hash, "presentation and par excluded like legacy");
        foreach (var mutate in new Action<LevelData>[] { l => l.Id++, l => l.Width++, l => l.Height++, l => l.Objects[0].Id += "x", l => l.Objects[0].X++, l => l.Objects[0].Y++, l => l.Objects[0].Color = 1, l => l.Objects[0].Kind = ObjectKind.Wall, l => l.Objects[0].Orientation++, l => l.Solution[0].Orientation++ })
        {
            var changed = Campaign.Create()[0]; mutate(changed);
            Check(changed.Fingerprint() != hash, "gameplay change invalidates fingerprint");
        }
    }
}
