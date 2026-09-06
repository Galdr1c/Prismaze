using System;

namespace Prismaze.Core
{
    public static class Campaign
    {
        // Literal campaign data converted from LegacyGodot/data/levels/level_001..012.tres.
        // Every call returns independent mutable definitions and object graphs.
        public static LevelData[] Create() => new[]
        {
            new LevelData
            {
                Id = 1, Title = "İlk ışık",
                Lesson = "Aynaya dokun. Işığı aşağıdaki hedefe ulaştır.", Width = 6, Height = 12, ParMoves = 1,
                Objects = new[]
                {
                    new BoardObject { Id = "s", Kind = ObjectKind.Source, X = 0, Y = 4, Orientation = 1, Color = 7 },
                    new BoardObject { Id = "m1", Kind = ObjectKind.Mirror, X = 3, Y = 4, Orientation = 2, Color = 7 },
                    new BoardObject { Id = "t", Kind = ObjectKind.Target, X = 3, Y = 9, Orientation = 0, Color = 7 },
                },
                Solution = new[]
                {
                    new OrientationEntry { Id = "m1", Orientation = 3 },
                }
            },
            new LevelData
            {
                Id = 2, Title = "Yönünü bul",
                Lesson = "Her dokunuş aynayı bir sonraki konuma çevirir.", Width = 6, Height = 12, ParMoves = 2,
                Objects = new[]
                {
                    new BoardObject { Id = "s", Kind = ObjectKind.Source, X = 1, Y = 1, Orientation = 2, Color = 7 },
                    new BoardObject { Id = "m1", Kind = ObjectKind.Mirror, X = 1, Y = 6, Orientation = 1, Color = 7 },
                    new BoardObject { Id = "t", Kind = ObjectKind.Target, X = 4, Y = 6, Orientation = 0, Color = 7 },
                },
                Solution = new[]
                {
                    new OrientationEntry { Id = "m1", Orientation = 3 },
                }
            },
            new LevelData
            {
                Id = 3, Title = "İki dönüş",
                Lesson = "Işığın yolunu iki aynayla tamamla.", Width = 6, Height = 12, ParMoves = 2,
                Objects = new[]
                {
                    new BoardObject { Id = "s", Kind = ObjectKind.Source, X = 0, Y = 2, Orientation = 1, Color = 7 },
                    new BoardObject { Id = "m1", Kind = ObjectKind.Mirror, X = 4, Y = 2, Orientation = 2, Color = 7 },
                    new BoardObject { Id = "m2", Kind = ObjectKind.Mirror, X = 4, Y = 8, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "t", Kind = ObjectKind.Target, X = 1, Y = 8, Orientation = 0, Color = 7 },
                },
                Solution = new[]
                {
                    new OrientationEntry { Id = "m1", Orientation = 3 },
                    new OrientationEntry { Id = "m2", Orientation = 1 },
                }
            },
            new LevelData
            {
                Id = 4, Title = "Duvarın ötesi",
                Lesson = "Duvar ışığı durdurur. Açık koridordan dolaş.", Width = 6, Height = 12, ParMoves = 3,
                Objects = new[]
                {
                    new BoardObject { Id = "s", Kind = ObjectKind.Source, X = 2, Y = 0, Orientation = 2, Color = 7 },
                    new BoardObject { Id = "m1", Kind = ObjectKind.Mirror, X = 2, Y = 3, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "m2", Kind = ObjectKind.Mirror, X = 0, Y = 3, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "m3", Kind = ObjectKind.Mirror, X = 0, Y = 9, Orientation = 2, Color = 7 },
                    new BoardObject { Id = "t", Kind = ObjectKind.Target, X = 4, Y = 9, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "w1", Kind = ObjectKind.Wall, X = 2, Y = 5, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "w2", Kind = ObjectKind.Wall, X = 3, Y = 5, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "w3", Kind = ObjectKind.Wall, X = 4, Y = 5, Orientation = 0, Color = 7 },
                },
                Solution = new[]
                {
                    new OrientationEntry { Id = "m1", Orientation = 1 },
                    new OrientationEntry { Id = "m2", Orientation = 1 },
                    new OrientationEntry { Id = "m3", Orientation = 3 },
                }
            },
            new LevelData
            {
                Id = 5, Title = "Işık merdiveni",
                Lesson = "Aynalar ışığı sırayla taşır. Yolu kaynaktan takip et.", Width = 6, Height = 12, ParMoves = 3,
                Objects = new[]
                {
                    new BoardObject { Id = "s", Kind = ObjectKind.Source, X = 5, Y = 1, Orientation = 3, Color = 7 },
                    new BoardObject { Id = "m1", Kind = ObjectKind.Mirror, X = 1, Y = 1, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "m2", Kind = ObjectKind.Mirror, X = 1, Y = 6, Orientation = 2, Color = 7 },
                    new BoardObject { Id = "m3", Kind = ObjectKind.Mirror, X = 4, Y = 6, Orientation = 2, Color = 7 },
                    new BoardObject { Id = "t", Kind = ObjectKind.Target, X = 4, Y = 10, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "w1", Kind = ObjectKind.Wall, X = 2, Y = 3, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "w2", Kind = ObjectKind.Wall, X = 3, Y = 3, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "w3", Kind = ObjectKind.Wall, X = 4, Y = 3, Orientation = 0, Color = 7 },
                },
                Solution = new[]
                {
                    new OrientationEntry { Id = "m1", Orientation = 1 },
                    new OrientationEntry { Id = "m2", Orientation = 3 },
                    new OrientationEntry { Id = "m3", Orientation = 3 },
                }
            },
            new LevelData
            {
                Id = 6, Title = "Uzun yol",
                Lesson = "Dört aynayı birbirine bağlayan yolu keşfet.", Width = 6, Height = 12, ParMoves = 4,
                Objects = new[]
                {
                    new BoardObject { Id = "s", Kind = ObjectKind.Source, X = 0, Y = 1, Orientation = 1, Color = 7 },
                    new BoardObject { Id = "m1", Kind = ObjectKind.Mirror, X = 4, Y = 1, Orientation = 2, Color = 7 },
                    new BoardObject { Id = "m2", Kind = ObjectKind.Mirror, X = 4, Y = 4, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "m3", Kind = ObjectKind.Mirror, X = 1, Y = 4, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "m4", Kind = ObjectKind.Mirror, X = 1, Y = 9, Orientation = 2, Color = 7 },
                    new BoardObject { Id = "t", Kind = ObjectKind.Target, X = 5, Y = 9, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "w1", Kind = ObjectKind.Wall, X = 2, Y = 6, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "w2", Kind = ObjectKind.Wall, X = 3, Y = 6, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "w3", Kind = ObjectKind.Wall, X = 4, Y = 6, Orientation = 0, Color = 7 },
                },
                Solution = new[]
                {
                    new OrientationEntry { Id = "m1", Orientation = 3 },
                    new OrientationEntry { Id = "m2", Orientation = 1 },
                    new OrientationEntry { Id = "m3", Orientation = 1 },
                    new OrientationEntry { Id = "m4", Orientation = 3 },
                }
            },
            new LevelData
            {
                Id = 7, Title = "İki renk",
                Lesson = "Her hedefi kendi rengiyle aydınlat.", Width = 6, Height = 12, ParMoves = 2,
                Objects = new[]
                {
                    new BoardObject { Id = "s", Kind = ObjectKind.Source, X = 0, Y = 2, Orientation = 1, Color = 1 },
                    new BoardObject { Id = "m1", Kind = ObjectKind.Mirror, X = 4, Y = 2, Orientation = 2, Color = 7 },
                    new BoardObject { Id = "t", Kind = ObjectKind.Target, X = 4, Y = 6, Orientation = 0, Color = 1 },
                    new BoardObject { Id = "s2", Kind = ObjectKind.Source, X = 5, Y = 9, Orientation = 3, Color = 4 },
                    new BoardObject { Id = "m2", Kind = ObjectKind.Mirror, X = 1, Y = 9, Orientation = 2, Color = 7 },
                    new BoardObject { Id = "t2", Kind = ObjectKind.Target, X = 1, Y = 5, Orientation = 0, Color = 4 },
                },
                Solution = new[]
                {
                    new OrientationEntry { Id = "m1", Orientation = 3 },
                    new OrientationEntry { Id = "m2", Orientation = 3 },
                }
            },
            new LevelData
            {
                Id = 8, Title = "Mor buluşma",
                Lesson = "Kırmızı ve mavi aynı hedefe ulaşınca mor oluşur.", Width = 6, Height = 12, ParMoves = 1,
                Objects = new[]
                {
                    new BoardObject { Id = "s", Kind = ObjectKind.Source, X = 0, Y = 2, Orientation = 1, Color = 1 },
                    new BoardObject { Id = "m1", Kind = ObjectKind.Mirror, X = 3, Y = 2, Orientation = 2, Color = 7 },
                    new BoardObject { Id = "s2", Kind = ObjectKind.Source, X = 5, Y = 8, Orientation = 3, Color = 4 },
                    new BoardObject { Id = "t", Kind = ObjectKind.Target, X = 3, Y = 8, Orientation = 0, Color = 5 },
                },
                Solution = new[]
                {
                    new OrientationEntry { Id = "m1", Orientation = 3 },
                }
            },
            new LevelData
            {
                Id = 9, Title = "Sarı buluşma",
                Lesson = "Kırmızı + yeşil = sarı. İki yolu aynı hedefte buluştur.", Width = 6, Height = 12, ParMoves = 3,
                Objects = new[]
                {
                    new BoardObject { Id = "s", Kind = ObjectKind.Source, X = 0, Y = 2, Orientation = 1, Color = 1 },
                    new BoardObject { Id = "m1", Kind = ObjectKind.Mirror, X = 4, Y = 2, Orientation = 2, Color = 7 },
                    new BoardObject { Id = "s2", Kind = ObjectKind.Source, X = 0, Y = 10, Orientation = 1, Color = 2 },
                    new BoardObject { Id = "m2", Kind = ObjectKind.Mirror, X = 2, Y = 10, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "m3", Kind = ObjectKind.Mirror, X = 2, Y = 8, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "t", Kind = ObjectKind.Target, X = 4, Y = 8, Orientation = 0, Color = 3 },
                    new BoardObject { Id = "w1", Kind = ObjectKind.Wall, X = 1, Y = 5, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "w2", Kind = ObjectKind.Wall, X = 2, Y = 5, Orientation = 0, Color = 7 },
                },
                Solution = new[]
                {
                    new OrientationEntry { Id = "m1", Orientation = 3 },
                    new OrientationEntry { Id = "m2", Orientation = 1 },
                    new OrientationEntry { Id = "m3", Orientation = 1 },
                }
            },
            new LevelData
            {
                Id = 10, Title = "Prizmanın sırrı",
                Lesson = "Prizma beyaz ışığı üç renge ayırır. Renkli çıkışları izle.", Width = 6, Height = 12, ParMoves = 1,
                Objects = new[]
                {
                    new BoardObject { Id = "s", Kind = ObjectKind.Source, X = 2, Y = 0, Orientation = 2, Color = 7 },
                    new BoardObject { Id = "p1", Kind = ObjectKind.Prism, X = 2, Y = 5, Orientation = 1, Color = 7 },
                    new BoardObject { Id = "r", Kind = ObjectKind.Target, X = 2, Y = 10, Orientation = 0, Color = 1 },
                    new BoardObject { Id = "g", Kind = ObjectKind.Target, X = 0, Y = 5, Orientation = 0, Color = 2 },
                    new BoardObject { Id = "b", Kind = ObjectKind.Target, X = 5, Y = 5, Orientation = 0, Color = 4 },
                },
                Solution = new[]
                {
                    new OrientationEntry { Id = "p1", Orientation = 2 },
                }
            },
            new LevelData
            {
                Id = 11, Title = "Üç ışık yolu",
                Lesson = "Prizmayı ve iki aynayı çevirerek üç hedefi aydınlat.", Width = 6, Height = 12, ParMoves = 4,
                Objects = new[]
                {
                    new BoardObject { Id = "s", Kind = ObjectKind.Source, X = 2, Y = 0, Orientation = 2, Color = 7 },
                    new BoardObject { Id = "p1", Kind = ObjectKind.Prism, X = 2, Y = 4, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "m1", Kind = ObjectKind.Mirror, X = 0, Y = 4, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "m2", Kind = ObjectKind.Mirror, X = 5, Y = 4, Orientation = 2, Color = 7 },
                    new BoardObject { Id = "r", Kind = ObjectKind.Target, X = 2, Y = 10, Orientation = 0, Color = 1 },
                    new BoardObject { Id = "g", Kind = ObjectKind.Target, X = 0, Y = 8, Orientation = 0, Color = 2 },
                    new BoardObject { Id = "b", Kind = ObjectKind.Target, X = 5, Y = 9, Orientation = 0, Color = 4 },
                },
                Solution = new[]
                {
                    new OrientationEntry { Id = "p1", Orientation = 2 },
                    new OrientationEntry { Id = "m1", Orientation = 1 },
                    new OrientationEntry { Id = "m2", Orientation = 3 },
                }
            },
            new LevelData
            {
                Id = 12, Title = "Renklerin uyumu",
                Lesson = "Işığı ayır, yolları kur, kırmızı ve maviyi yeniden buluştur.", Width = 6, Height = 12, ParMoves = 4,
                Objects = new[]
                {
                    new BoardObject { Id = "s", Kind = ObjectKind.Source, X = 2, Y = 0, Orientation = 2, Color = 7 },
                    new BoardObject { Id = "p1", Kind = ObjectKind.Prism, X = 2, Y = 4, Orientation = 1, Color = 7 },
                    new BoardObject { Id = "m1", Kind = ObjectKind.Mirror, X = 0, Y = 4, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "m2", Kind = ObjectKind.Mirror, X = 5, Y = 4, Orientation = 2, Color = 7 },
                    new BoardObject { Id = "m3", Kind = ObjectKind.Mirror, X = 5, Y = 9, Orientation = 0, Color = 7 },
                    new BoardObject { Id = "t", Kind = ObjectKind.Target, X = 2, Y = 9, Orientation = 0, Color = 5 },
                    new BoardObject { Id = "g", Kind = ObjectKind.Target, X = 0, Y = 10, Orientation = 0, Color = 2 },
                },
                Solution = new[]
                {
                    new OrientationEntry { Id = "p1", Orientation = 2 },
                    new OrientationEntry { Id = "m1", Orientation = 1 },
                    new OrientationEntry { Id = "m2", Orientation = 3 },
                    new OrientationEntry { Id = "m3", Orientation = 1 },
                }
            },
        };
    }
}
