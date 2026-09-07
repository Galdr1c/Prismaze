using System;
using System.Linq;
using Prismaze.Core;
using Prismaze.Unity.Monetization;
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
        public MonetizationController Monetization { get; private set; }
        [NonSerialized] public string SaveDirectoryOverride;
        SaveService saves;
        GameAudio audioService;
        LevelData[] levels;
        RectTransform safe, content, contentFrame, modal;
        BoardView board;
        Text status, caption;
        Font displayFont, bodyFont;
        float saveClock;
        bool applicationPaused;
        static PrismazeApp instance;
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
        static void ResetInstance() { instance = null; }
        static readonly Color Background = new Color(.035f,.06f,.115f), Panel = new Color(.10f,.15f,.24f), PanelLight = new Color(.17f,.24f,.36f), Accent = new Color(.45f,.95f,.98f), AccentDim = new Color(.3f,.7f,.78f), TextLight = new Color(.93f,.96f,1f), TextDim = new Color(.62f,.68f,.82f);

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
            Monetization = new MonetizationController(saves, Profile);
            Monetization.Initialize();
            var assets = Resources.LoadAll<LevelDefinition>("Levels");
            levels = assets.Length == 12 ? assets.Select(x=>x.Data).OrderBy(x=>x.Id).ToArray() : Campaign.Create();
            displayFont = Resources.Load<Font>("Fonts/DynaPuff-SemiBold") ?? Resources.Load<Font>("Fonts/DynaPuff-Medium") ?? Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            bodyFont = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf") ?? displayFont;
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
            var background=Rect("Background",canvasObject.transform);Stretch(background);background.gameObject.AddComponent<GradientFill>();
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
            contentFrame=Rect("ContentFrame",safe);
            contentFrame.anchorMin=new Vector2(.5f,0);contentFrame.anchorMax=new Vector2(.5f,1);
            contentFrame.offsetMin=new Vector2(-300,22);contentFrame.offsetMax=new Vector2(300,-22);
            content=Rect("Content",contentFrame);Stretch(content);
            var layout=content.gameObject.AddComponent<VerticalLayoutGroup>();layout.spacing=16;layout.childControlHeight=true;layout.childForceExpandHeight=false;layout.childForceExpandWidth=true;
        }
        public void ShowMenu()
        {
            Persist();Clear();ScreenName="menu";audioService.SetContext(false);
            Space(20);
            var hero=Card("Hero",content,Panel,292);
            Label("CRYSTAL LAB / İLK IŞIK",15,AccentDim,hero,true);
            Label("◇",76,Accent,hero,true);
            Label("Prismaze",54,TextLight,hero,true);
            Label("Işığı yönlendir. Renkleri buluştur.",18,TextDim,hero);
            Space(16);
            var progress=Card("Progress",content,new Color(.08f,.13f,.22f),58);
            Label(Profile.Stars.Count(x=>x>0)+" / 12 bölüm   ·   "+Profile.Stars.Sum()+" / 36 yıldız",17,Accent,progress,true);
            Space(12);
            Button(Profile.Stars.Sum()==0 && Profile.Active==null?"Başla":"Devam Et · "+(Profile.Current+1).ToString("00"),()=>OpenLevel(Profile.Current),true,content,72,23);
            var utility=Rect("UtilityRow",content);utility.gameObject.AddComponent<LayoutElement>().preferredHeight=64;
            var utilityLayout=utility.gameObject.AddComponent<HorizontalLayoutGroup>();utilityLayout.spacing=10;utilityLayout.childForceExpandWidth=true;utilityLayout.childForceExpandHeight=true;
            Button("Bölümler",ShowLevels,false,utility,60,18);
            Button("Ayarlar",()=>ShowSettings(false),false,utility,60,18);
            Button("Nasıl oynanır?",()=>OpenLevel(0,false,true),false,content,60,18);
            Space(16);
            Label("12 bulmaca · Çevrimdışı · Kendi hızında",16,TextDim);
            if(saves.RecoveryMessage.Length>0)Label(saves.RecoveryMessage,18,Accent);
        }
        void Header(string text,Action back)
        { Button("‹  "+text,back,false,null,64,21); }
        public void ShowLevels()
        {
            Clear();ScreenName="levels";Header("Işık yolculuğu",ShowMenu);
            Label("Bölüm seç",18,TextDim);
            var list=LevelGrid();
            for(int i=0;i<levels.Length;i++)
            { int index=i; var button=Button((i+1).ToString("00")+"  "+levels[i].Title+"  "+new string('★',Profile.Stars[i]),()=>OpenLevel(index,false),false,list,62,20);button.interactable=i<Profile.Unlocked; }
        }
        public void OpenLevel(int index,bool resume=true,bool tutorial=false)
        {
            if(index<0 || index>=levels.Length || index>=Profile.Unlocked)return;
            Clear();Session.Start(levels[index]);
            if(resume && Profile.Active!=null)Session.Restore(Profile.Active);
            Profile.Current=index;ScreenName="playing";audioService.SetContext(true);
            // Overlay chrome so the board owns the middle of the screen.
            var top=Anchored("TopBar",safe,new Vector2(0,1),new Vector2(1,1),new Vector2(10,-64),new Vector2(-10,-8));
            var topSurface=top.gameObject.AddComponent<RoundedRect>();topSurface.Radius=22;topSurface.color=new Color(.08f,.13f,.22f,.94f);topSurface.raycastTarget=false;
            var topLayout=top.gameObject.AddComponent<HorizontalLayoutGroup>();
            topLayout.spacing=12;topLayout.childControlHeight=true;topLayout.childForceExpandHeight=true;topLayout.childForceExpandWidth=false;topLayout.childAlignment=TextAnchor.MiddleCenter;
            Button("‹  "+(index+1).ToString("00")+"  "+Session.Definition.Title,Pause,false,top,50,19);
            var spacer=Rect("Spacer",top).gameObject.AddComponent<LayoutElement>();spacer.flexibleWidth=1;spacer.minHeight=0;
            status=Label("",20,TextDim,top);
            var host=Anchored("BoardHost",safe,new Vector2(0,0),new Vector2(1,1),new Vector2(0,104),new Vector2(0,-78));
            board=host.gameObject.AddComponent<BoardView>();board.Session=Session;board.Settings=Profile.Settings;board.Tapped=Rotate;
            board.Tutorial=index==0 && (tutorial || !Profile.TutorialDone) && !Session.Result.Solved;
            var bottom=Anchored("BottomBar",safe,new Vector2(0,0),new Vector2(1,0),new Vector2(10,10),new Vector2(-10,112));
            var bottomSurface=bottom.gameObject.AddComponent<RoundedRect>();bottomSurface.Radius=22;bottomSurface.color=new Color(.08f,.13f,.22f,.96f);bottomSurface.raycastTarget=false;
            var bottomLayout=bottom.gameObject.AddComponent<VerticalLayoutGroup>();
            bottomLayout.spacing=4;bottomLayout.childForceExpandHeight=false;bottomLayout.childControlHeight=true;bottomLayout.childForceExpandWidth=true;bottomLayout.childAlignment=TextAnchor.UpperCenter;
            caption=Label(board.Tutorial?"Aynayı döndürmek için dokun":Session.Definition.Lesson,19,Accent,bottom);
            var row=Rect("Actions",bottom);row.gameObject.AddComponent<LayoutElement>().preferredHeight=62;
            var layout=row.gameObject.AddComponent<HorizontalLayoutGroup>();layout.spacing=12;layout.childForceExpandWidth=true;layout.childForceExpandHeight=true;
            Button("Sıfırla",ConfirmReset,false,row,62,20);Button("İpucu",Hint,false,row,62,20);
            if(board.Tutorial)Button("Atla",()=>{Profile.TutorialDone=true;Persist();OpenLevel(0);},false,row,62,20);
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
            if(index<11)Button("Sonraki Bölüm",()=>Monetization.OnLevelCompleted(index+1, ()=>OpenLevel(index+1,false)),true,box);
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
            Button("Müzik: "+(Profile.Settings.Music>0?"Açık":"Kapalı"),()=>{Profile.Settings.Music=Profile.Settings.Music>0?0:.65f;audioService.Configure(Profile.Settings);SaveProfile();ShowSettings(fromGame);},false,list,60,19);
            Button("Efektler: "+(Profile.Settings.Sfx>0?"Açık":"Kapalı"),()=>{Profile.Settings.Sfx=Profile.Settings.Sfx>0?0:.65f;audioService.Configure(Profile.Settings);SaveProfile();ShowSettings(fromGame);},false,list,60,19);
            Setting("Titreşim",Profile.Settings.Vibration,()=>Profile.Settings.Vibration=!Profile.Settings.Vibration,list,fromGame);
            Setting("Hareketi azalt",Profile.Settings.ReducedMotion,()=>Profile.Settings.ReducedMotion=!Profile.Settings.ReducedMotion,list,fromGame);
            Setting("Parlamayı azalt",Profile.Settings.ReducedGlow,()=>Profile.Settings.ReducedGlow=!Profile.Settings.ReducedGlow,list,fromGame);
            Setting("Yüksek kontrast",Profile.Settings.HighContrast,()=>Profile.Settings.HighContrast=!Profile.Settings.HighContrast,list,fromGame);
            Setting("Renk işaretleri",Profile.Settings.ColorAssist,()=>Profile.Settings.ColorAssist=!Profile.Settings.ColorAssist,list,fromGame);
            if (!Monetization.HasNoAds)
            {
                Button("Reklamları Kaldır (Satın Al)", () => Monetization.PurchaseNoAds((ok, msg) => { SaveProfile(); ShowSettings(fromGame); }), false, list, 60, 19);
                Button("Satın Alımları Geri Yükle", () => Monetization.RestorePurchases(ok => { SaveProfile(); ShowSettings(fromGame); }), false, list, 60, 19);
            }
            else
            {
                Label("Reklamlar Kaldırıldı (Premium)", 19, Accent, list);
            }
            if (Monetization.IsPrivacyOptionsRequired)
            {
                Button("Gizlilik Seçenekleri (KVKK/GDPR)", Monetization.ShowPrivacyOptions, false, list, 60, 19);
            }
            Label("Tüm bulmacalar ve kayıtların bu cihazda çalışır.",19,TextDim,list);
            Button("İlk Bölüm Eğitimini Tekrarla",()=>OpenLevel(0,false,true),false,list,60,19);
        }
        void Setting(string label,bool enabled,Action toggle,Transform parent,bool fromGame)
        { Button(label+": "+(enabled?"Açık":"Kapalı"),()=>{toggle();SaveProfile();ShowSettings(fromGame);},false,parent,60,19); }
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

        RectTransform Card(string name,Transform parent,Color surface,float height)
        {
            var card=Rect(name,parent);
            var image=card.gameObject.AddComponent<RoundedRect>();image.Radius=24;image.Border=1.5f;image.BorderColor=new Color(1,1,1,.10f);image.color=surface;image.raycastTarget=false;
            card.gameObject.AddComponent<LayoutElement>().preferredHeight=height;
            var layout=card.gameObject.AddComponent<VerticalLayoutGroup>();layout.spacing=4;layout.padding=new RectOffset(18,18,14,14);layout.childControlHeight=true;layout.childForceExpandHeight=false;layout.childForceExpandWidth=true;layout.childAlignment=TextAnchor.MiddleCenter;
            return card;
        }

        RectTransform Modal(string title)
        {
            if(modal){modal.gameObject.SetActive(false);Destroy(modal.gameObject);}
            modal=Rect("Modal",safe);Stretch(modal);modal.gameObject.AddComponent<Image>().color=new Color(.01f,.02f,.04f,.93f);
            var shadow=Rect("PanelShadow",modal);shadow.anchorMin=new Vector2(.07f,.2f);shadow.anchorMax=new Vector2(.93f,.8f);shadow.offsetMin=shadow.offsetMax=Vector2.zero;
            shadow.anchoredPosition=new Vector2(0,6);
            var shadowImage=shadow.gameObject.AddComponent<RoundedRect>();shadowImage.Radius=22;shadowImage.color=new Color(0,0,0,.45f);
            var box=Rect("Panel",modal);box.anchorMin=new Vector2(.07f,.2f);box.anchorMax=new Vector2(.93f,.8f);box.offsetMin=box.offsetMax=Vector2.zero;
            var panel=box.gameObject.AddComponent<RoundedRect>();panel.Radius=22;panel.Border=1.5f;panel.BorderColor=new Color(1,1,1,.12f);panel.color=Panel;
            var layout=box.gameObject.AddComponent<VerticalLayoutGroup>();layout.spacing=20;layout.childForceExpandHeight=false;layout.childAlignment=TextAnchor.MiddleCenter;
            Label(title,34,Accent,box,true);return box;
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
        RectTransform LevelGrid()
        {
            var grid=Rect("LevelGrid",content);
            var layout=grid.gameObject.AddComponent<GridLayoutGroup>();layout.constraint=GridLayoutGroup.Constraint.FixedColumnCount;layout.constraintCount=2;layout.cellSize=new Vector2(290,72);layout.spacing=new Vector2(12,12);layout.childAlignment=TextAnchor.UpperCenter;
            grid.gameObject.AddComponent<ContentSizeFitter>().verticalFit=ContentSizeFitter.FitMode.PreferredSize;
            return grid;
        }
        Text Label(string text,int size,Color? tint=null,Transform parent=null,bool display=false)
        {
            var rect=Rect("Text",parent?parent:content);var label=rect.gameObject.AddComponent<Text>();label.font=display?displayFont:bodyFont;label.fontSize=size;
            label.text=text;label.color=tint??TextLight;label.alignment=TextAnchor.MiddleCenter;label.raycastTarget=false;
            rect.gameObject.AddComponent<LayoutElement>().minHeight=size*1.5f;return label;
        }
        Button Button(string text,Action action,bool primary=false,Transform parent=null,int height=88,int fontSize=25)
        {
            var rect=Rect(text,parent?parent:content);rect.gameObject.AddComponent<LayoutElement>().preferredHeight=height;
            var glow=Rect("Glow",rect);glow.gameObject.AddComponent<LayoutElement>().ignoreLayout=true;
            glow.anchorMin=Vector2.zero;glow.anchorMax=Vector2.one;
            glow.offsetMin=new Vector2(-height*.35f,-height*.2f);glow.offsetMax=new Vector2(height*.35f,height*.3f);
            var glowImage=glow.gameObject.AddComponent<RoundedRect>();glowImage.Radius=height;glowImage.color=primary?new Color(Accent.r,Accent.g,Accent.b,.16f):new Color(1,1,1,.05f);glowImage.raycastTarget=false;
            var image=rect.gameObject.AddComponent<RoundedRect>();image.Radius=height*.32f;image.Border=1.5f;image.BorderColor=new Color(1,1,1,.10f);
            image.color=primary?Accent:Panel;
            var button=rect.gameObject.AddComponent<Button>();button.targetGraphic=image;
            button.transition=Selectable.Transition.ColorTint;var colors=button.colors;
            colors.normalColor=Color.white;colors.highlightedColor=new Color(.94f,.96f,.98f);colors.pressedColor=new Color(.82f,.85f,.90f);button.colors=colors;
            button.onClick.AddListener(()=>{audioService.Sfx("click");action();});
            var label=Label(text,fontSize,primary?Background:(Color?)null,rect,true);Stretch(label.rectTransform);label.rectTransform.offsetMin=new Vector2(12,2);label.rectTransform.offsetMax=new Vector2(-12,-2);
            return button;
        }
        void Space(float height,bool expand=false) { var e=Rect("Space",content).gameObject.AddComponent<LayoutElement>();e.preferredHeight=height;e.flexibleHeight=expand?1:0; }
        static RectTransform Rect(string name,Transform parent) {var r=new GameObject(name,typeof(RectTransform)).GetComponent<RectTransform>();r.SetParent(parent,false);return r;}
        static RectTransform Anchored(string name,Transform parent,Vector2 anchorMin,Vector2 anchorMax,Vector2 offsetMin,Vector2 offsetMax)
        { var r=Rect(name,parent);r.anchorMin=anchorMin;r.anchorMax=anchorMax;r.offsetMin=offsetMin;r.offsetMax=offsetMax;return r; }
        static void Stretch(RectTransform rect) {rect.anchorMin=Vector2.zero;rect.anchorMax=Vector2.one;rect.offsetMin=rect.offsetMax=Vector2.zero;}
    }
}
