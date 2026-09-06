using System;
using System.Collections;
using System.IO;
using System.Linq;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.TestTools;
using UnityEngine.UI;

namespace Prismaze.Unity.Tests
{
    public sealed class FlowTests
    {
        PrismazeApp app;
        string directory;
        [UnitySetUp] public IEnumerator SetUp()
        {
            directory=Path.Combine(Application.temporaryCachePath,"prismaze-flow-"+Guid.NewGuid().ToString("N"));
            var go=new GameObject("PrismazeTest");go.SetActive(false);
            app=go.AddComponent<PrismazeApp>();app.SaveDirectoryOverride=directory;go.SetActive(true);
            yield return null;Canvas.ForceUpdateCanvases();
        }
        [UnityTearDown] public IEnumerator TearDown()
        {
            if(app)UnityEngine.Object.Destroy(app.gameObject);
            var eventSystem=UnityEngine.Object.FindFirstObjectByType<EventSystem>();
            if(eventSystem)UnityEngine.Object.Destroy(eventSystem.gameObject);
            yield return null;
            if(Directory.Exists(directory))Directory.Delete(directory,true);
        }
        void Press(string label)
        {
            var button=app.GetComponentsInChildren<Button>().Single(b=>b.GetComponentInChildren<Text>().text==label);
            button.onClick.Invoke();
        }
        BoardView Board() => app.GetComponentInChildren<BoardView>();
        void Tap(BoardView board,string id,int pointer=0)
        {
            var world=board.rectTransform.TransformPoint(board.ObjectPoint(id));
            var data=new PointerEventData(EventSystem.current) {pointerId=pointer,button=PointerEventData.InputButton.Left,position=RectTransformUtility.WorldToScreenPoint(null,world)};
            board.OnPointerDown(data);board.OnPointerUp(data);
        }
        [UnityTest] public IEnumerator TutorialWinsWithOneRealPointerRelease()
        {
            Assert.That(app.ScreenName,Is.EqualTo("menu"));
            Press("Başla");yield return null;Canvas.ForceUpdateCanvases();
            Assert.That(Board().Tutorial,Is.True);Assert.That(app.Session.Moves,Is.Zero);
            Tap(Board(),"m1");yield return null;
            Assert.That(app.ScreenName,Is.EqualTo("result"));Assert.That(app.Session.Moves,Is.EqualTo(1));
            Assert.That(app.Profile.Unlocked,Is.EqualTo(2));Assert.That(app.Profile.TutorialDone,Is.True);
            Press("Sonraki Bölüm");yield return null;
            Assert.That(app.Session.Definition.Id,Is.EqualTo(2));
        }
        [UnityTest] public IEnumerator PauseBlocksPointerAndContinueRestoresSave()
        {
            app.Profile.Unlocked=2;app.OpenLevel(1,false);yield return null;Canvas.ForceUpdateCanvases();
            Tap(Board(),"m1");Assert.That(app.Session.Moves,Is.EqualTo(1));app.Pause();
            Tap(Board(),"m1");Assert.That(app.Session.Moves,Is.EqualTo(1));
            Press("Ana Menü");yield return null;Press("Devam Et · 02");yield return null;
            Assert.That(app.Session.Moves,Is.EqualTo(1));Assert.That(app.ScreenName,Is.EqualTo("playing"));
        }
        [UnityTest] public IEnumerator DragCancelDoesNotBecomeAMove()
        {
            app.OpenLevel(0,false);yield return null;Canvas.ForceUpdateCanvases();
            var board=Board();var world=board.rectTransform.TransformPoint(board.ObjectPoint("m1"));
            var data=new PointerEventData(EventSystem.current) {pointerId=0,position=RectTransformUtility.WorldToScreenPoint(null,world)};
            board.OnPointerDown(data);board.OnBeginDrag(data);board.OnPointerUp(data);
            Assert.That(app.Session.Moves,Is.Zero);
        }
    }
}
