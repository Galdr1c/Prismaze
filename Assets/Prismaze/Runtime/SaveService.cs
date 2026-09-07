using System;
using System.IO;
using Prismaze.Core;
using UnityEngine;

namespace Prismaze.Unity
{
    [Serializable]
    public sealed class Preferences
    {
        public float Music = .65f, Sfx = .65f;
        public bool Vibration = true, ReducedMotion, ReducedGlow, HighContrast, ColorAssist;
    }

    [Serializable]
    public sealed class PlayerProfile
    {
        public int Schema = 1, Unlocked = 1, Current;
        public int[] Stars = new int[12], BestMoves = new int[12];
        public bool TutorialDone, NoAds;
        public int HintCredits;
        public Preferences Settings = new Preferences();
        public SessionSnapshot Active;
    }

    public sealed class SaveService
    {
        readonly string directory;
        public string RecoveryMessage { get; private set; } = "";
        public SaveService(string path) { directory = path; }

        public PlayerProfile Load()
        {
            RecoveryMessage = "";
            var primary = Read(Path.Combine(directory, "save-unity-v1.json"));
            if (primary != null) return primary;
            var backup = Read(Path.Combine(directory, "save-unity-v1.backup.json"));
            if (backup != null) { RecoveryMessage = "Kayıt yedekten kurtarıldı."; return backup; }
            if (File.Exists(Path.Combine(directory, "save-unity-v1.json")))
                RecoveryMessage = "Önceki kayıt okunamadı. Yeni oyun açıldı.";
            return new PlayerProfile();
        }

        public bool Save(PlayerProfile profile)
        {
            if (!Valid(profile)) return false;
            try
            {
                Directory.CreateDirectory(directory);
                var primary = Path.Combine(directory, "save-unity-v1.json");
                var backup = Path.Combine(directory, "save-unity-v1.backup.json");
                var temp = Path.Combine(directory, "save-unity-v1.tmp.json");
                File.WriteAllText(temp, JsonUtility.ToJson(profile));
                if (Read(temp) == null) return false;
                if (File.Exists(primary))
                {
                    // A corrupt primary must never replace a valid backup.
                    if (Read(primary) != null) File.Replace(temp, primary, backup);
                    else File.Replace(temp, primary, null);
                }
                else File.Move(temp, primary);
                return true;
            }
            catch (Exception error) when (error is IOException || error is UnauthorizedAccessException || error is NotSupportedException)
            {
                Debug.LogWarning("Prismaze save failed: " + error.Message);
                return false;
            }
        }

        static PlayerProfile Read(string path)
        {
            try
            {
                if (!File.Exists(path)) return null;
                var result = JsonUtility.FromJson<PlayerProfile>(File.ReadAllText(path));
                return Valid(result) ? result : null;
            }
            catch (Exception error) when (error is IOException || error is ArgumentException || error is UnauthorizedAccessException) { return null; }
        }

        static bool Valid(PlayerProfile value)
        {
            if (value == null || value.Schema != 1 || value.Unlocked < 1 || value.Unlocked > 12 ||
                value.Current < 0 || value.Current >= value.Unlocked || value.Stars == null || value.Stars.Length != 12 ||
                value.BestMoves == null || value.BestMoves.Length != 12 || value.Settings == null) return false;
            for (var i = 0; i < 12; i++) if (value.Stars[i] < 0 || value.Stars[i] > 3 || value.BestMoves[i] < 0) return false;
            var s = value.Settings;
            return !float.IsNaN(s.Music) && !float.IsInfinity(s.Music) && s.Music >= 0 && s.Music <= 1 &&
                   !float.IsNaN(s.Sfx) && !float.IsInfinity(s.Sfx) && s.Sfx >= 0 && s.Sfx <= 1;
        }
    }
}
