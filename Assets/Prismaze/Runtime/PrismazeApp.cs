using System;
using System.Linq;
using Prismaze.Core;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace Prismaze.Unity
{
    public sealed class PrismazeApp : MonoBehaviour
    {
        public GameSession Session { get; } = new GameSession();
        public string ScreenName { get; private set; }
        public PlayerProfile Profile { get; private set; }
        [NonSerialized] public string SaveDirectoryOverride;
        SaveService saves;
        GameAudio audioService;
        LevelData[] levels;
        RectTransform safe, content, modal;
        BoardView board;
        Text status, caption;
        Font font;
        float saveClock;
        bool applicationPaused;
        static PrismazeApp instance;
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
        static void ResetInstance() { instance = null; }
        static readonly Color Background = new Color(.035f,.06f,.115f), Panel = new Color(.09f,.13f,.21f), Accent = new Color(.4f,.91f,.93f);

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void Bootstrap()
        {
            if (UnityEngine.SceneManagement.SceneManager.GetActiveScene().path != "Assets/Prismaze/Scenes/Boot.unity") return;
            if (FindFirstObjectByType<PrismazeApp>() == null) new GameObject("Prismaze").AddComponent<PrismazeApp>();
        }
        void Awake()
        {
            if (instance && instance != this) { Destroy(gameObject); return; }
            instance = this;
            DontDestroyOnLoad(gameObject);
            Application.targetFrameRate = 60;
            Screen.orientation = ScreenOrientation.Portrait;
            saves = new SaveService(string.IsNullOrEmpty(SaveDirectoryOverride) ? Application.persistentDataPath : SaveDirectoryOverride);
            Profile = saves.Load();
            var assets = Resources.LoadAll<LevelDefinition>("Levels");
            levels = assets.Length == 12 ? assets.Select(x=>x.Data).OrderBy(x=>x.Id).ToArray() : Campaign.Create();
            font = Resources.Load<Font>("Fonts/DynaPuff-Medium") ?? Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            audioService = gameObject.AddComponent<GameAudio>();
            audioService.Configure(Profile.Settings);
            if (!FindFirstObjectByType<AudioListener>()) gameObject.AddComponent<AudioListener>();
            if (!FindFirstObjectByType<EventSystem>())
                new GameObject("EventSystem",typeof(EventSystem),typeof(StandaloneInputModule));
            var canvasObject=new GameObject("PrismazeCanvas",typeof(RectTransform),typeof(Canvas),typeof(CanvasScaler),typeof(GraphicRaycaster));
            canvasObject.transform.SetParent(transform,false);
            canvasObject.GetComponent<Canvas>().renderMode=RenderMode.ScreenSpaceOverlay;
            var scaler=canvasObject.GetComponent<CanvasScaler>();scaler.uiScaleMode=CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution=new Vector2(720,1280);scaler.matchWidthOrHeight=0;
            var background=Rect("Background",canvasObject.transform);Stretch(background);background.gameObject.AddComponent<Image>().color=Background;
            safe=Rect("SafeArea",canvasObject.transform);Stretch(safe);
            audioService.Startup(); ShowMenu();
        }
        void Update()
        {
            var area=Screen.safeArea;
            if(Screen.width>0 && Screen.height>0) { safe.anchorMin=new Vector2(area.xMin/Screen.width,area.yMin/Screen.height);safe.anchorMax=new Vector2(area.xMax/Screen.width,area.yMax/Screen.height); }
            if(Input.GetKeyDown(KeyCode.Escape)) Back();
            if(ScreenName=="playing" && !applicationPaused)
            { Session.Elapsed+=Time.unscaledDeltaTime;saveClock+=Time.unscaledDeltaTime;if(saveClock>=5){saveClock=0;Persist();} }
        }
        void Clear()
        {
            if(content) {content.gameObject.SetActive(false);Destroy(content.gameObject);}
            if(modal) {modal.gameObject.SetActive(false);Destroy(modal.gameObject);}
            modal=null;board=null;
            content=Rect("Content",safe);Stretch(content);content.offsetMin=new Vector2(36,26);content.offsetMax=new Vector2(-36,-26);
            var layout=content.gameObject.AddComponent<VerticalLayoutGroup>();layout.spacing=16;layout.childControlHeight=true;layout.childForceExpandHeight=false;layout.childForceExpandWidth=true;
        }
        public void ShowMenu()
        {
            Persist();Clear();ScreenName="menu";audioService.SetContext(false);
            Label("CRYSTAL LAB / İLK IŞIK",21);Space(0,true);Label("◇",120,Accent);Label("Prismaze",68);
            Label("Işığı yönlendir. Renkleri buluştur.",25);Space(30);
            Label(Profile.Stars.Count(x=>x>0)+" / 12 bölüm · "+Profile.Stars.Sum()+" / 36 yıldız",23,Accent);Space(0,true);
            Button(Profile.Stars.Sum()==0 && Profile.Active==null?"Başla":"Devam Et · "+(Profile.Current+1).ToString("00"),()=>OpenLevel(Profile.Current),true);
            Button("Bölümler",ShowLevels);Button("Ayarlar",()=>ShowSettings(false));Button("Nasıl oynanır?",()=>OpenLevel(0,false,true));
            Label("12 bulmaca · Çevrimdışı · Kendi hızında",19);
            if(saves.RecoveryMessage.Length>0)Label(saves.RecoveryMessage,18,Accent);
        }
        void Header(string text,Action back)
        { Button("‹  "+text,back); }
        public void ShowLevels()
        {
            Clear();ScreenName="levels";Header("Işık yolculuğu",ShowMenu);
            var list=ScrollList();
            for(int i=0;i<levels.Length;i++)
            { int index=i; var button=Button((i+1).ToString("00")+"  "+levels[i].Title+"  "+new string('★',Profile.Stars[i]),()=>OpenLevel(index,false),false,list);button.interactable=i<Profile.Unlocked; }
        }
        public void OpenLevel(int index,bool resume=true,bool tutorial=false)
        {
            if(index<0 || index>=levels.Length || index>=Profile.Unlocked)return;
            Clear();Session.Start(levels[index]);
            if(resume && Profile.Active!=null)Session.Restore(Profile.Active);
            Profile.Current=index;ScreenName="playing";audioService.SetContext(true);
            Header((index+1).ToString("00")+" / "+Session.Definition.Title,Pause);
            status=Label("",22);
            var rect=Rect("Board",content);var element=rect.gameObject.AddComponent<LayoutElement>();element.minHeight=300;element.flexibleHeight=1;
            board=rect.gameObject.AddComponent<BoardView>();board.Session=Session;board.Settings=Profile.Settings;board.Tapped=Rotate;
            board.Tutorial=index==0 && (tutorial || !Profile.TutorialDone) && !Session.Result.Solved;
            caption=Label(board.Tutorial?"Işığı hedefe ulaştır. Elin gösterdiği aynaya dokun.":Session.Definition.Lesson,24,Accent);
            var row=Rect("Actions",content);row.gameObject.AddComponent<LayoutElement>().preferredHeight=88;
            var layout=row.gameObject.AddComponent<HorizontalLayoutGroup>();layout.spacing=12;layout.childForceExpandWidth=true;layout.childForceExpandHeight=true;
            Button("Sıfırla",ConfirmReset,false,row);Button("İpucu",Hint,false,row);
            if(board.Tutorial)Button("Atla",()=>{Profile.TutorialDone=true;Persist();OpenLevel(0);},false,row);
            UpdateStatus();Persist();if(Session.Result.Solved)Complete();
        }
        void Rotate(string id)
        {
            if(ScreenName!="playing" || applicationPaused || !Session.Rotate(id))return;
            audioService.Sfx("rotate");if(Profile.Settings.Vibration && Application.platform==RuntimePlatform.Android)Handheld.Vibrate();
            board.HintId=null;UpdateStatus();if(Session.Result.Solved)Complete();else Persist();
        }
        void UpdateStatus() { status.text=Session.Moves+" hamle · Hedef "+Session.Definition.ParMoves+" / "+Session.Result.Hits.Count(x=>Session.Objects.Any(o=>o.Id==x.Key && o.Color==x.Value))+" ışık"; }
        void Hint()
        {
            var hint=Session.Hint();if(hint==null)return;board.HintId=hint.Id;
            caption.text="İşaretli nesneye "+((hint.Orientation-Session.OrientationOf(hint.Id)+4)%4)+" kez dokun.";
        }
        void Complete()
        {
            ScreenName="result";board.InputEnabled=false;board.Tutorial=false;Profile.TutorialDone=true;
            int index=Session.Definition.Id-1,stars=Session.Moves<=Session.Definition.ParMoves?3:Session.Moves<=Session.Definition.ParMoves+3?2:1;
            Profile.Stars[index]=Math.Max(Profile.Stars[index],stars);
            Profile.BestMoves[index]=Profile.BestMoves[index]==0?Session.Moves:Math.Min(Profile.BestMoves[index],Session.Moves);
            Profile.Unlocked=Math.Max(Profile.Unlocked,Math.Min(index+2,12));Profile.Current=Math.Min(index+1,11);Profile.Active=null;
            SaveProfile();audioService.Sfx("complete");
            var box=Modal("Işık tamamlandı!");Label(new string('★',stars),58,Accent,box);
            Label(Session.Moves+" hamle",26,null,box);
            if(index<11)Button("Sonraki Bölüm",()=>OpenLevel(index+1,false),true,box);
            else Label("12 bölüm tamam!",30,Accent,box);
            Button("Tekrar Oyna",()=>OpenLevel(index,false),false,box);Button("Ana Menü",ShowMenu,false,box);
        }
        public void Pause()
        {
            if(ScreenName!="playing")return;ScreenName="paused";board.InputEnabled=false;Persist();
            var box=Modal("Bir nefes.");Button("Devam Et",Resume,true,box);Button("Ayarlar",()=>ShowSettings(true),false,box);Button("Ana Menü",ShowMenu,false,box);
        }
        void Resume() { if(modal){modal.gameObject.SetActive(false);Destroy(modal.gameObject);}modal=null;ScreenName="playing";board.InputEnabled=true; }
        void ConfirmReset()
        {
            if(Session.Moves==0)return;ScreenName="paused";board.InputEnabled=false;
            var box=Modal("Baştan deneyelim mi?");Label("Bu bölümdeki hamlelerin sıfırlanacak.",24,null,box);
            Button("Bölümü Sıfırla",()=>OpenLevel(Session.Definition.Id-1,false),true,box);Button("Vazgeç",Resume,false,box);
        }
        public void ShowSettings(bool fromGame)
        {
            Persist();Clear();ScreenName="settings";
            Header("Ayarlar",()=>{if(fromGame){OpenLevel(Session.Definition.Id-1);Pause();}else ShowMenu();});
            var list=ScrollList();
            Button("Müzik: "+(Profile.Settings.Music>0?"Açık":"Kapalı"),()=>{Profile.Settings.Music=Profile.Settings.Music>0?0:.65f;audioService.Configure(Profile.Settings);SaveProfile();ShowSettings(fromGame);},false,list);
            Button("Efektler: "+(Profile.Settings.Sfx>0?"Açık":"Kapalı"),()=>{Profile.Settings.Sfx=Profile.Settings.Sfx>0?0:.65f;audioService.Configure(Profile.Settings);SaveProfile();ShowSettings(fromGame);},false,list);
            Setting("Titreşim",Profile.Settings.Vibration,()=>Profile.Settings.Vibration=!Profile.Settings.Vibration,list,fromGame);
            Setting("Hareketi azalt",Profile.Settings.ReducedMotion,()=>Profile.Settings.ReducedMotion=!Profile.Settings.ReducedMotion,list,fromGame);
            Setting("Parlamayı azalt",Profile.Settings.ReducedGlow,()=>Profile.Settings.ReducedGlow=!Profile.Settings.ReducedGlow,list,fromGame);
            Setting("Yüksek kontrast",Profile.Settings.HighContrast,()=>Profile.Settings.HighContrast=!Profile.Settings.HighContrast,list,fromGame);
            Setting("Renk işaretleri",Profile.Settings.ColorAssist,()=>Profile.Settings.ColorAssist=!Profile.Settings.ColorAssist,list,fromGame);
            Label("Tüm bulmacalar ve kayıtların bu cihazda çalışır.",24,null,list);
            Button("İlk Bölüm Eğitimini Tekrarla",()=>OpenLevel(0,false,true),false,list);
        }
        void Setting(string label,bool enabled,Action toggle,Transform parent,bool fromGame)
        { Button(label+": "+(enabled?"Açık":"Kapalı"),()=>{toggle();SaveProfile();ShowSettings(fromGame);},false,parent); }
        void Back()
        {
            if(ScreenName=="playing")Pause();else if(ScreenName=="paused")Resume();
            else if(ScreenName=="menu") { var box=Modal("Oyundan çıkılsın mı?");Button("Çık",()=>{Persist();Application.Quit();},false,box);Button("Vazgeç",ShowMenu,true,box); }
            else ShowMenu();
        }
        void Persist()
        {
            if(Profile==null)return;
            if(Session.Definition!=null && (ScreenName=="playing" || ScreenName=="paused"))Profile.Active=Session.Snapshot();
            SaveProfile();
        }
        void SaveProfile() { if(!saves.Save(Profile) && caption)caption.text="Kayıt yazılamadı. Cihazda boş alan açıp yeniden dene."; }
        void OnApplicationPause(bool paused) { if(Profile==null)return;applicationPaused=paused;if(paused){Persist();Pause();audioService.Suspend();}else audioService.Resume(); }
        void OnApplicationQuit() { Persist(); }
        void OnDestroy() { if (instance == this) instance = null; }

        RectTransform Modal(string title)
        {
            if(modal){modal.gameObject.SetActive(false);Destroy(modal.gameObject);}
            modal=Rect("Modal",safe);Stretch(modal);modal.gameObject.AddComponent<Image>().color=new Color(.01f,.02f,.04f,.93f);
            var box=Rect("Panel",modal);box.anchorMin=new Vector2(.07f,.2f);box.anchorMax=new Vector2(.93f,.8f);box.offsetMin=box.offsetMax=Vector2.zero;
            var layout=box.gameObject.AddComponent<VerticalLayoutGroup>();layout.spacing=20;layout.childForceExpandHeight=false;layout.childAlignment=TextAnchor.MiddleCenter;
            Label(title,34,Accent,box);return box;
        }
        RectTransform ScrollList()
        {
            var scroll=Rect("Scroll",content);scroll.gameObject.AddComponent<LayoutElement>().flexibleHeight=1;
            scroll.gameObject.AddComponent<RectMask2D>();var sr=scroll.gameObject.AddComponent<ScrollRect>();sr.horizontal=false;
            var list=Rect("List",scroll);list.anchorMin=new Vector2(0,1);list.anchorMax=Vector2.one;list.pivot=new Vector2(.5f,1);list.sizeDelta=Vector2.zero;
            var layout=list.gameObject.AddComponent<VerticalLayoutGroup>();layout.spacing=12;layout.childForceExpandHeight=false;
            list.gameObject.AddComponent<ContentSizeFitter>().verticalFit=ContentSizeFitter.FitMode.PreferredSize;
            sr.content=list;sr.viewport=scroll;return list;
        }
        Text Label(string text,int size,Color? tint=null,Transform parent=null)
        {
            var rect=Rect("Text",parent?parent:content);var label=rect.gameObject.AddComponent<Text>();label.font=font;label.fontSize=size;
            label.text=text;label.color=tint??new Color(.91f,.94f,1);label.alignment=TextAnchor.MiddleCenter;label.raycastTarget=false;
            rect.gameObject.AddComponent<LayoutElement>().minHeight=size*1.6f;return label;
        }
        Button Button(string text,Action action,bool primary=false,Transform parent=null)
        {
            var rect=Rect(text,parent?parent:content);rect.gameObject.AddComponent<LayoutElement>().preferredHeight=88;
            var image=rect.gameObject.AddComponent<Image>();image.color=primary?Accent:Panel;
            var button=rect.gameObject.AddComponent<Button>();button.targetGraphic=image;
            button.onClick.AddListener(()=>{audioService.Sfx("click");action();});
            var label=Label(text,25,primary?Background:(Color?)null,rect);Stretch(label.rectTransform);label.rectTransform.offsetMin=new Vector2(12,4);label.rectTransform.offsetMax=new Vector2(-12,-4);
            return button;
        }
        void Space(float height,bool expand=false) { var e=Rect("Space",content).gameObject.AddComponent<LayoutElement>();e.preferredHeight=height;e.flexibleHeight=expand?1:0; }
        static RectTransform Rect(string name,Transform parent) {var r=new GameObject(name,typeof(RectTransform)).GetComponent<RectTransform>();r.SetParent(parent,false);return r;}
        static void Stretch(RectTransform rect) {rect.anchorMin=Vector2.zero;rect.anchorMax=Vector2.one;rect.offsetMin=rect.offsetMax=Vector2.zero;}
    }
}
