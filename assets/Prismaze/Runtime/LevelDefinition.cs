using Prismaze.Core;
using UnityEngine;

namespace Prismaze.Unity
{
    [CreateAssetMenu(menuName = "Prismaze/Level", fileName = "Level")]
    public sealed class LevelDefinition : ScriptableObject
    {
        public LevelData Data;
    }
}
