using System;
using Prismaze.Core;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace Prismaze.Unity
{
    public sealed class BoardView : MaskableGraphic, IPointerDownHandler, IPointerUpHandler, IBeginDragHandler, IDragHandler, ICancelHandler
    {
        public GameSession Session;
        public Preferences Settings;
        public Action<string> Tapped;
        public bool Tutorial;
        public string HintId;
        bool inputEnabled = true;
        int? pointer;
        string pressed;
        float cell;
        Vector2 origin;
        static readonly Color[] Colors = {
            new Color(.25f,.3f,.4f), new Color(1,.39f,.47f), new Color(.45f,.91f,.62f), new Color(1,.88f,.54f),
            new Color(.43f,.67f,1), new Color(.86f,.55f,1), new Color(.4f,.91f,.93f), new Color(.93f,.97f,1)
        };
        public bool InputEnabled { get => inputEnabled; set { inputEnabled = value; if (!value) CancelPointer(); } }
        protected override void OnDisable() { CancelPointer(); base.OnDisable(); }
        void Update() { if (Session != null) SetVerticesDirty(); }
        void Layout()
        {
            var rect = rectTransform.rect;
            cell = Mathf.Max(1, Mathf.Min((rect.width - 24) / Session.Definition.Width, (rect.height - 24) / Session.Definition.Height));
            origin = rect.center + new Vector2(-Session.Definition.Width * cell / 2, Session.Definition.Height * cell / 2);
        }
        Vector2 Point(float x, float y) => origin + new Vector2(x * cell, -y * cell);
        public Vector2 ObjectPoint(string id)
        {
            Layout();
            foreach (var obj in Session.Objects) if (obj.Id == id) return Point(obj.X + .5f, obj.Y + .5f);
            return Vector2.zero;
        }
        string Hit(PointerEventData data)
        {
            if (Session == null || !RectTransformUtility.ScreenPointToLocalPointInRectangle(rectTransform, data.position, data.pressEventCamera, out var p)) return null;
            Layout();
            int x = Mathf.FloorToInt((p.x - origin.x) / cell), y = Mathf.FloorToInt((origin.y - p.y) / cell);
            foreach (var obj in Session.Objects) if (obj.Rotatable && obj.X == x && obj.Y == y) return obj.Id;
            return null;
        }
        public void OnPointerDown(PointerEventData data)
        {
            if (!inputEnabled || pointer.HasValue || data.button != PointerEventData.InputButton.Left) return;
            pointer = data.pointerId; pressed = Hit(data);
        }
        public void OnPointerUp(PointerEventData data)
        {
            if (!inputEnabled || pointer != data.pointerId) return;
            var id = Hit(data);
            bool accepted = id != null && id == pressed && (!Tutorial || id == "m1");
            CancelPointer();
            if (accepted) Tapped?.Invoke(id);
        }
        public void OnBeginDrag(PointerEventData data) { if (pointer == data.pointerId) CancelPointer(); }
        public void OnDrag(PointerEventData data) { }
        public void OnCancel(BaseEventData data) => CancelPointer();
        void CancelPointer() { pointer = null; pressed = null; }
        protected override void OnPopulateMesh(VertexHelper mesh)
        {
            mesh.Clear();
            if (Session == null || Settings == null) return;
            Layout();
            var plate = new Rect(origin.x-10, origin.y-Session.Definition.Height*cell-10, Session.Definition.Width*cell+20, Session.Definition.Height*cell+20);
            MeshDraw.RoundedRect(mesh, plate, 22, new Color(.13f,.19f,.30f));
            MeshDraw.RoundedRect(mesh, new Rect(plate.x+2, plate.y+2, plate.width-4, plate.height-4), 20, new Color(.045f,.075f,.14f));
            for (int y=0; y<Session.Definition.Height; y++)
            {
                for(int x=0; x<Session.Definition.Width; x++)
                {
                    var p = Point(x+.5f,y+.5f);
                    if (Settings.HighContrast) Circle(mesh,p,1.5f,new Color(.45f,.5f,.62f));
                    else
                    {
                        Circle(mesh,p,cell*.20f,new Color(.07f,.11f,.20f));
                        Circle(mesh,p,1.6f,new Color(.24f,.30f,.42f));
                    }
                }
            }
            foreach (var segment in Session.Result.Segments)
            {
                var start = Point(segment.FromX,segment.FromY); var end = Point(segment.ToX,segment.ToY);
                var tint = Colors[segment.Color];
                if (!Settings.ReducedGlow) { var glow = tint; glow.a=.10f; Line(mesh,start,end,cell*.32f,glow); glow.a=.22f; Line(mesh,start,end,cell*.15f,glow); }
                Line(mesh,start,end,4,tint); Line(mesh,start,end,1.4f,Color.white);
                if (!Settings.ReducedMotion) Circle(mesh,Vector2.Lerp(start,end,Mathf.Repeat(Time.unscaledTime*.65f,1)),2.3f,Color.white);
            }
            foreach (var obj in Session.Objects)
            {
                var p = Point(obj.X+.5f,obj.Y+.5f); float r=cell*.32f; var tint=Colors[obj.Color];
                Circle(mesh,p+Vector2.down*4,r+2.5f,new Color(0,0,0,.6f));
                if (obj.Rotatable && obj.Id!=HintId && !(Tutorial && obj.Id=="m1"))
                {
                    float pulse=Settings.ReducedMotion?0:Mathf.Sin(Time.unscaledTime*2.6f)*1.4f;
                    var ring=Settings.HighContrast?new Color(.75f,.8f,.95f,.8f):new Color(.45f,.7f,.9f,.30f);
                    for(int i=0;i<24;i++) Line(mesh,p+Rotate(Vector2.up,i*15)*(r+7+pulse),p+Rotate(Vector2.up,(i+1)*15)*(r+7+pulse),2,ring);
                }
                switch(obj.Kind)
                {
                    case ObjectKind.Source:
                        Circle(mesh,p,r+4,new Color(tint.r,tint.g,tint.b,.14f));
                        Circle(mesh,p,r,tint); Circle(mesh,p,r*.74f,new Color(.08f,.13f,.22f));
                        var forward = Rotate(Vector2.up,obj.Orientation*-90);
                        var side = new Vector2(-forward.y,forward.x);
                        Triangle(mesh,p+forward*r*.7f,p-forward*r*.5f+side*r*.5f,p-forward*r*.5f-side*r*.5f,tint);
                        if (!Settings.ReducedGlow) Circle(mesh,p,r*.55f,new Color(tint.r,tint.g,tint.b,.35f));
                        break;
                    case ObjectKind.Mirror:
                        Circle(mesh,p,r+3,Settings.HighContrast?Color.white:new Color(.45f,.52f,.72f));
                        Circle(mesh,p,r,new Color(.18f,.24f,.36f));
                        var axis=Rotate(Vector2.up,obj.Orientation*-45)*r;
                        Line(mesh,p-axis+Vector2.down*3,p+axis+Vector2.down*3,11,new Color(.28f,.25f,.4f));
                        Line(mesh,p-axis,p+axis,8,new Color(.86f,.8f,1)); Line(mesh,p-axis,p+axis,2,Color.white);
                        Circle(mesh,p,r*.45f,new Color(.7f,.8f,.98f,.18f)); break;
                    case ObjectKind.Prism:
                        Triangle(mesh,p+Vector2.up*r*1.3f,p+Vector2.left*r,p,new Color(.9f,.91f,1));
                        Triangle(mesh,p+Vector2.up*r*1.3f,p,p+Vector2.right*r,new Color(.56f,.66f,.82f));
                        Triangle(mesh,p+Vector2.left*r,p+Vector2.down*r*1.3f,p+Vector2.right*r,new Color(.34f,.4f,.62f));
                        Line(mesh,p+Vector2.up*r*.5f,p+Vector2.left*r*.7f,1.5f,new Color(1,1,1,.5f));
                        for(int port=0;port<3;port++) Circle(mesh,p+Rotate(Vector2.up,-90*(obj.Orientation+(port==2?3:port)))*r*.7f,3,Colors[1<<port]); break;
                    case ObjectKind.Target:
                        Circle(mesh,p,r+3,new Color(tint.r,tint.g,tint.b,.18f));
                        Circle(mesh,p,r,tint); Circle(mesh,p,r-3,new Color(.06f,.11f,.19f));
                        if (Session.Result.Hits.TryGetValue(obj.Id,out int hit) && hit==obj.Color)
                        {
                            Circle(mesh,p,r+2,new Color(tint.r,tint.g,tint.b,.5f));
                            Line(mesh,p+new Vector2(-r*.5f,0),p+new Vector2(-r*.1f,-r*.3f),3,Color.white); Line(mesh,p+new Vector2(-r*.1f,-r*.3f),p+new Vector2(r*.5f,r*.4f),3,Color.white);
                        }
                        else Circle(mesh,p,r*.25f,tint);
                        break;
                    case ObjectKind.Wall:
                        Quad(mesh,new Rect(p-Vector2.one*r,Vector2.one*r*2),new Color(.19f,.23f,.32f));
                        Quad(mesh,new Rect(p-Vector2.one*(r-3),Vector2.one*(r-3)*2),new Color(.13f,.16f,.24f));
                        Line(mesh,p+new Vector2(-r+3,r-3),p+new Vector2(r-3,r-3),2,new Color(.5f,.55f,.66f)); break;
                }
                if (Settings.ColorAssist && (obj.Kind==ObjectKind.Source || obj.Kind==ObjectKind.Target))
                    for (int bit=0;bit<3;bit++) if ((obj.Color & (1<<bit))!=0) Quad(mesh,new Rect(p.x-r+bit*r*.7f,p.y-r-9,4,5+bit*2),Colors[1<<bit]);
                if (obj.Id==HintId || (Tutorial && obj.Id=="m1"))
                {
                    float pulse=Settings.ReducedMotion?0:Mathf.Sin(Time.unscaledTime*4)*3;
                    for(int i=0;i<32;i++) Line(mesh,p+Rotate(Vector2.up,i*360/32f)*(r+11),p+Rotate(Vector2.up,(i+1)*360/32f)*(r+11),2.5f,Colors[6]);
                    if(Tutorial)
                    {
                        var finger=p+new Vector2(cell*.2f,-cell*.3f-pulse);
                        Line(mesh,finger,finger+new Vector2(16,-28),9,Color.white);
                        Quad(mesh,new Rect(finger.x+9,finger.y-45,25,26),Color.white);
                    }
                }
            }
        }
        static Vector2 Rotate(Vector2 p,float angle) { float a=angle*Mathf.Deg2Rad; return new Vector2(p.x*Mathf.Cos(a)-p.y*Mathf.Sin(a),p.x*Mathf.Sin(a)+p.y*Mathf.Cos(a)); }
        static void Triangle(VertexHelper m,Vector2 a,Vector2 b,Vector2 c,Color tint)
        { int i=m.currentVertCount; m.AddVert(a,tint,Vector2.zero);m.AddVert(b,tint,Vector2.zero);m.AddVert(c,tint,Vector2.zero);m.AddTriangle(i,i+1,i+2); }
        static void Quad(VertexHelper m,Rect r,Color c) { Triangle(m,new Vector2(r.xMin,r.yMin),new Vector2(r.xMin,r.yMax),new Vector2(r.xMax,r.yMax),c);Triangle(m,new Vector2(r.xMin,r.yMin),new Vector2(r.xMax,r.yMax),new Vector2(r.xMax,r.yMin),c); }
        static void Circle(VertexHelper m,Vector2 p,float radius,Color c) { for(int i=0;i<24;i++) Triangle(m,p,p+Rotate(Vector2.up,i*15)*radius,p+Rotate(Vector2.up,(i+1)*15)*radius,c); }
        static void Line(VertexHelper m,Vector2 a,Vector2 b,float width,Color c)
        { if(a==b)return; var n=new Vector2(-(b-a).y,(b-a).x).normalized*width*.5f; Triangle(m,a-n,a+n,b+n,c);Triangle(m,a-n,b+n,b-n,c); }
    }
}
