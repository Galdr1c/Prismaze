using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

namespace Prismaze.Core
{
    public enum ObjectKind { Source, Mirror, Prism, Target, Wall }

    [Serializable]
    public class BoardObject
    {
        public string Id;
        public ObjectKind Kind;
        public int X, Y, Orientation, Color = 7;
        public bool Rotatable => Kind == ObjectKind.Mirror || Kind == ObjectKind.Prism;
        public BoardObject Clone() => (BoardObject)MemberwiseClone();
    }

    [Serializable]
    public class OrientationEntry
    {
        public string Id;
        public int Orientation;
    }

    [Serializable]
    public class LevelData
    {
        public int Id, Width = 6, Height = 12, ParMoves;
        public string Title, Lesson;
        public BoardObject[] Objects = Array.Empty<BoardObject>();
        public OrientationEntry[] Solution = Array.Empty<OrientationEntry>();
        // Versioned, length-prefixed UTF-8 binary serialization. Ordinal sorting makes
        // identity independent of collection order and the device's current culture.
        // As in Godot, localized text and par moves do not invalidate saved progress.
        public string Fingerprint()
        {
            using (var stream = new MemoryStream())
            {
                using (var writer = new BinaryWriter(stream, Encoding.UTF8, true))
                {
                    writer.Write("Prismaze.Core.Level.v1");
                    writer.Write(Id); writer.Write(Width); writer.Write(Height);
                    writer.Write(Objects.Length);
                    foreach (var item in Objects.OrderBy(o => o.Id, StringComparer.Ordinal))
                    {
                        writer.Write(item.Id); writer.Write((int)item.Kind);
                        writer.Write(item.X); writer.Write(item.Y);
                        writer.Write(item.Orientation); writer.Write(item.Color);
                    }
                    writer.Write(Solution.Length);
                    foreach (var entry in Solution.OrderBy(e => e.Id, StringComparer.Ordinal))
                    {
                        writer.Write(entry.Id); writer.Write(entry.Orientation);
                    }
                }
                using (var sha = SHA256.Create())
                {
                    var hash = sha.ComputeHash(stream.ToArray());
                    var text = new StringBuilder(hash.Length * 2);
                    const string digits = "0123456789abcdef";
                    foreach (byte b in hash) { text.Append(digits[b >> 4]); text.Append(digits[b & 15]); }
                    return text.ToString();
                }
            }
        }
    }

    public class BeamSegment
    {
        public float FromX, FromY, ToX, ToY;
        public int Color;
    }

    public class TraceResult
    {
        public List<BeamSegment> Segments = new List<BeamSegment>();
        public Dictionary<string, int> Hits = new Dictionary<string, int>(StringComparer.Ordinal);
        public bool Valid, Solved, LoopDetected;
    }

    [Serializable]
    public class SessionSnapshot
    {
        public int LevelId, Moves;
        public string Fingerprint;
        public double Elapsed;
        public OrientationEntry[] Orientations;
    }
}
