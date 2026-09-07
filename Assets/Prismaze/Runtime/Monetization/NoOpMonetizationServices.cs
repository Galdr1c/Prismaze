using System;
using UnityEngine;

namespace Prismaze.Unity.Monetization
{
    public sealed class NoOpAdService : IAdService
    {
        public bool IsInitialized => true;
        public bool IsInterstitialReady => false;
        public bool IsRewardedReady => false;

        public void Initialize() { }
        public void LoadInterstitial() { }
        public void ShowInterstitial(Action onClosed) => onClosed?.Invoke();
        public void LoadRewarded() { }
        public void ShowRewarded(Action onRewardEarned, Action onClosed) => onClosed?.Invoke();
    }

    public sealed class NoOpConsentService : IConsentService
    {
        public bool CanRequestAds => false;
        public bool IsPrivacyOptionsRequired => false;
        public void CheckConsent(Action onCompleted) => onCompleted?.Invoke();
        public void ShowPrivacyOptionsForm(Action onDismissed = null) => onDismissed?.Invoke();
    }

    public sealed class NoOpBillingService : IBillingService
    {
        public bool IsInitialized => true;
        public bool HasNoAds => false;
        public void Initialize(Action<bool> onInitialized) => onInitialized?.Invoke(true);
        public void PurchaseNoAds(Action<bool, string> onComplete) => onComplete?.Invoke(false, "Billing not available in offline/mock mode");
        public void RestorePurchases(Action<bool> onComplete) => onComplete?.Invoke(false);
    }
}
