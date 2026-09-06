using UnityEngine;

namespace Prismaze.Unity
{
    public sealed class GameAudio : MonoBehaviour
    {
        AudioSource music, effects, stinger;
        Preferences preferences;
        bool started, suspended, waitingForStinger;
        string context = "menu";
        void Awake()
        {
            music = gameObject.AddComponent<AudioSource>();
            effects = gameObject.AddComponent<AudioSource>();
            stinger = gameObject.AddComponent<AudioSource>();
            foreach (var source in new[] { music, effects, stinger }) source.playOnAwake = false;
            music.loop = true;
        }
        public void Configure(Preferences settings)
        {
            preferences = settings;
            music.volume = settings.Music * .4f;
            effects.volume = settings.Sfx * .65f;
            stinger.volume = settings.Music * .5f;
            if (settings.Music <= 0) { music.Stop(); stinger.Stop(); waitingForStinger = false; }
            else if (started && !waitingForStinger) PlayContext();
            if (settings.Sfx <= 0) effects.Stop();
        }
        public void Startup()
        {
            if (started) return;
            started = true;
            stinger.clip = Resources.Load<AudioClip>("Audio/stingers/starting_sound");
            if (!suspended && preferences.Music > 0 && stinger.clip)
            {
                music.Stop(); stinger.Play(); waitingForStinger = true;
            }
            else PlayContext();
        }
        void Update()
        {
            if (waitingForStinger && !suspended && !stinger.isPlaying)
            { waitingForStinger = false; stinger.clip = null; PlayContext(); }
        }
        public void SetContext(bool gameplay)
        {
            context = gameplay ? "gameplay" : "menu";
            if (waitingForStinger && !gameplay) return;
            if (waitingForStinger) { stinger.Stop(); stinger.clip = null; waitingForStinger = false; }
            PlayContext();
        }
        void PlayContext()
        {
            if (suspended || preferences == null || preferences.Music <= 0) return;
            var clip = Resources.Load<AudioClip>("Audio/runtime/" + context);
            if (music.clip != clip) { music.Stop(); music.clip = clip; }
            if (clip && !music.isPlaying) music.Play();
        }
        public void Sfx(string name)
        {
            if (suspended || preferences.Sfx <= 0 || (name != "click" && name != "rotate" && name != "complete")) return;
            var clip = Resources.Load<AudioClip>("Audio/runtime/" + name);
            if (clip) { effects.clip = clip; effects.Play(); }
        }
        public void Suspend()
        {
            suspended = true; stinger.Stop(); stinger.clip = null;
            waitingForStinger = false; effects.Stop(); music.Pause();
        }
        public void Resume() { suspended = false; music.UnPause(); PlayContext(); }
        void OnDestroy()
        {
            foreach (var source in new[] { music, effects, stinger })
                if (source) { source.Stop(); source.clip = null; }
        }
    }
}
