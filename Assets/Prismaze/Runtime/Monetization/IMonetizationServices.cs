using System;

namespace Prismaze.Unity.Monetization
{
    public interface IAdService
    {
        bool IsInitialized { get; }
        bool IsInterstitialReady { get; }
        bool IsRewardedReady { get; }
        void Initialize();
        void LoadInterstitial();
        void ShowInterstitial(Action onClosed);
        void LoadRewarded();
        void ShowRewarded(Action onRewardEarned, Action onClosed);
    }

    public interface IConsentService
    {
        bool CanRequestAds { get; }
        bool IsPrivacyOptionsRequired { get; }
        void CheckConsent(Action onCompleted);
        void ShowPrivacyOptionsForm(Action onDismissed = null);
    }

    public interface IBillingService
    {
        bool IsInitialized { get; }
        bool HasNoAds { get; }
        void Initialize(Action<bool> onInitialized);
        void PurchaseNoAds(Action<bool, string> onComplete);
        void RestorePurchases(Action<bool> onComplete);
    }
}
