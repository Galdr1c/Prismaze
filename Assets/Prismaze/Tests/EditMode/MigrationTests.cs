using System;
using System.IO;
using NUnit.Framework;
using Prismaze.Core;
using UnityEngine;

namespace Prismaze.Unity.Tests
{
    public sealed class MigrationTests
    {
        string directory;
        [SetUp] public void SetUp() { directory=Path.Combine(Application.temporaryCachePath,"prismaze-tests-"+Guid.NewGuid().ToString("N")); }
        [TearDown] public void TearDown() { if(Directory.Exists(directory))Directory.Delete(directory,true); }

        [Test] public void JsonSaveRoundTripAndCorruptPrimaryRecovery()
        {
            var saves=new SaveService(directory);var profile=saves.Load();
            var session=new GameSession();session.Start(Campaign.Create()[1]);session.Rotate("m1");
            profile.Unlocked=2;profile.Current=1;profile.Active=session.Snapshot();
            Assert.That(saves.Save(profile),Is.True);
            Assert.That(saves.Load().Active.Orientations[0].Orientation,Is.EqualTo(session.OrientationOf("m1")));
            Assert.That(saves.Save(profile),Is.True);
            File.WriteAllText(Path.Combine(directory,"save-unity-v1.json"),"{broken");
            var restored=saves.Load();Assert.That(restored.Unlocked,Is.EqualTo(2));Assert.That(saves.RecoveryMessage,Is.Not.Empty);
            Assert.That(saves.Save(restored),Is.True);
            File.WriteAllText(Path.Combine(directory,"save-unity-v1.json"),"{broken again");
            Assert.That(saves.Load().Unlocked,Is.EqualTo(2));
        }
        [Test] public void InvalidProfileCannotOverwriteValidSave()
        {
            var saves=new SaveService(directory);var profile=saves.Load();Assert.That(saves.Save(profile),Is.True);
            profile.Stars=new[]{99};Assert.That(saves.Save(profile),Is.False);Assert.That(saves.Load().Stars.Length,Is.EqualTo(12));
        }
        [Test] public void ScriptableObjectCampaignIsPlayableWithoutAssetMutation()
        {
            var levels=Resources.LoadAll<LevelDefinition>("Levels");Assert.That(levels.Length,Is.EqualTo(12));
            foreach(var asset in levels)
            {
                var fingerprint=asset.Data.Fingerprint();var session=new GameSession();session.Start(asset.Data);
                Assert.That(session.Result.Solved,Is.False);
                foreach(var target in asset.Data.Solution)
                    for(int turn=0;turn<4 && !session.Result.Solved && session.OrientationOf(target.Id)!=target.Orientation;turn++)session.Rotate(target.Id);
                Assert.That(session.Result.Solved,Is.True,"Level "+asset.Data.Id);
                Assert.That(asset.Data.Fingerprint(),Is.EqualTo(fingerprint));
            }
        }
        [Test] public void JsonSnapshotRestoresRealSession()
        {
            var original=new GameSession();original.Start(Campaign.Create()[3]);original.Rotate("m1");
            var snapshot=JsonUtility.FromJson<SessionSnapshot>(JsonUtility.ToJson(original.Snapshot()));
            var restored=new GameSession();restored.Start(Campaign.Create()[3]);
            Assert.That(restored.Restore(snapshot),Is.True);Assert.That(restored.Moves,Is.EqualTo(original.Moves));
            Assert.That(restored.OrientationOf("m1"),Is.EqualTo(original.OrientationOf("m1")));
        }
    }
}
