using System.IO;
using Prismaze.Core;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Prismaze.Unity.Editor
{
    public static class ProjectSetup
    {
        const string BootPath="Assets/Prismaze/Scenes/Boot.unity";
        [InitializeOnLoadMethod]
        static void OnLoad()
        {
            EditorApplication.delayCall += () => {
                if(!EditorApplication.isPlayingOrWillChangePlaymode && !File.Exists(BootPath)) Prepare();
            };
        }

        [MenuItem("Prismaze/Prepare Project")]
        public static void Prepare()
        {
            Directory.CreateDirectory("Assets/Prismaze/Scenes");
            Directory.CreateDirectory("Assets/Resources/Levels");
            Directory.CreateDirectory("Assets/Prismaze/Rendering");
            AssetDatabase.Refresh();
            foreach(var data in Campaign.Create())
            {
                var path="Assets/Resources/Levels/Level"+data.Id.ToString("000")+".asset";
                if(AssetDatabase.LoadAssetAtPath<LevelDefinition>(path))continue;
                var level=ScriptableObject.CreateInstance<LevelDefinition>();level.Data=data;
                AssetDatabase.CreateAsset(level,path);
            }
            const string pipelinePath="Assets/Prismaze/Rendering/PrismazeURP.asset";
            var pipeline=AssetDatabase.LoadAssetAtPath<UniversalRenderPipelineAsset>(pipelinePath);
            if(!pipeline)
            {
                var renderer=ScriptableObject.CreateInstance<Renderer2DData>();
                AssetDatabase.CreateAsset(renderer,"Assets/Prismaze/Rendering/PrismazeRenderer2D.asset");
                pipeline=UniversalRenderPipelineAsset.Create(renderer);
                pipeline.msaaSampleCount=2;pipeline.supportsHDR=false;
                AssetDatabase.CreateAsset(pipeline,pipelinePath);
            }
            GraphicsSettings.defaultRenderPipeline=pipeline;QualitySettings.renderPipeline=pipeline;
            PlayerSettings.companyName="Prismaze";PlayerSettings.productName="Prismaze";
            PlayerSettings.bundleVersion="0.1.0";
            PlayerSettings.SetApplicationIdentifier(NamedBuildTarget.Android,"com.prismaze.game.dev");
            PlayerSettings.defaultInterfaceOrientation=UIOrientation.Portrait;
            PlayerSettings.Android.minSdkVersion=AndroidSdkVersions.AndroidApiLevel24;
            PlayerSettings.Android.targetSdkVersion=AndroidSdkVersions.AndroidApiLevelAuto;
            PlayerSettings.Android.forceInternetPermission=false;
            PlayerSettings.SetScriptingBackend(NamedBuildTarget.Android,ScriptingImplementation.IL2CPP);
            PlayerSettings.Android.targetArchitectures=AndroidArchitecture.ARM64;
            PlayerSettings.SetApiCompatibilityLevel(NamedBuildTarget.Android,ApiCompatibilityLevel.NET_Standard);
            var settings=new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/ProjectSettings.asset")[0]);
            var input=settings.FindProperty("activeInputHandler");if(input!=null){input.intValue=0;settings.ApplyModifiedPropertiesWithoutUndo();}
            if(!File.Exists(BootPath))
            {
                // Additively create the boot scene without discarding any open user scene.
                var previous=SceneManagerActive();
                var scene=EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Additive);
                UnityEngine.SceneManagement.SceneManager.SetActiveScene(scene);
                var cameraObject=new GameObject("Camera",typeof(Camera),typeof(AudioListener));
                var camera=cameraObject.GetComponent<Camera>();camera.orthographic=true;camera.orthographicSize=6;
                camera.transform.position=new Vector3(0,0,-10);camera.backgroundColor=new Color(.035f,.06f,.115f);
                camera.clearFlags=CameraClearFlags.SolidColor;cameraObject.tag="MainCamera";
                cameraObject.AddComponent<UniversalAdditionalCameraData>();
                new GameObject("Prismaze").AddComponent<PrismazeApp>();
                EditorSceneManager.SaveScene(scene,BootPath);
                EditorSceneManager.CloseScene(scene,true);
                if(previous.IsValid())UnityEngine.SceneManagement.SceneManager.SetActiveScene(previous);
            }
            EditorBuildSettings.scenes=new[]{new EditorBuildSettingsScene(BootPath,true)};
            AssetDatabase.SaveAssets();
            Debug.Log("Prismaze Unity project prepared: 12 levels, URP 2D, Android portrait.");
        }
        static UnityEngine.SceneManagement.Scene SceneManagerActive() => UnityEngine.SceneManagement.SceneManager.GetActiveScene();

        [MenuItem("Prismaze/Build Android Development APK")]
        public static void BuildAndroid()
        {
            Prepare();Directory.CreateDirectory("Builds/Android");
            EditorUserBuildSettings.buildAppBundle=false;
            var report=BuildPipeline.BuildPlayer(new BuildPlayerOptions {
                scenes=new[]{BootPath},locationPathName="Builds/Android/Prismaze-dev.apk",
                target=BuildTarget.Android,options=BuildOptions.Development
            });
            if(report.summary.result!=BuildResult.Succeeded)throw new BuildFailedException("Prismaze Android build failed.");
        }
    }
}
