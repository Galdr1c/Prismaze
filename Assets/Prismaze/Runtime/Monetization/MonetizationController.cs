using System;
using UnityEngine;

namespace Prismaze.Unity.Monetization
{
    public sealed class MonetizationController
    {
        readonly IAdService _adService;
        readonly IConsentService _consentService;
        readonly IBillingService _billingService;
        readonly SaveService _saveService;
        readonly PlayerProfile _profile;

        int _levelsCompletedSinceLastAd;

        public bool HasNoAds => _profile.NoAds || _billingService.HasNoAds;
        public int HintCredits => _profile.HintCredits;
        public bool IsRewardedReady => _adService.IsRewardedReady;
        public bool IsPrivacyOptionsRequired => _consentService.IsPrivacyOptionsRequired;

        public MonetizationController(
            SaveService saveService,
            PlayerProfile profile,
            IAdService adService = null,
            IConsentService consentService = null,
            IBillingService billingService = null)
        {
            _saveService = saveService;
            _profile = profile;

#if UNITY_EDITOR
            _adService = adService ?? new NoOpAdService();
            _consentService = consentService ?? new NoOpConsentService();
            _billingService = billingService ?? new NoOpBillingService();
#else
            var googleAdapter = new GoogleMobileAdsAdapter();
            _adService = adService ?? googleAdapter;
            _consentService = consentService ?? googleAdapter;
            _billingService = billingService ?? new UnityIAPAdapter(profile.NoAds);
#endif
        }

        public void Initialize()
        {
            // Non-blocking Consent check
            _consentService.CheckConsent(() =>
            {
                if (_consentService.CanRequestAds)
                {
                    _adService.Initialize();
                }
            });

            // Non-blocking Billing initialization
            _billingService.Initialize(success =>
            {
                if (success && _billingService.HasNoAds && !_profile.NoAds)
                {
                    _profile.NoAds = true;
                    _saveService.Save(_profile);
                }
            });
        }

        public void OnLevelCompleted(int levelNumber, Action onAdFlowDone)
        {
            // Design spec 8.4:
            // 1. First 5 levels: NO interstitial.
            // 2. If NoAds purchased: NO interstitial.
            // 3. Level > 5: at most every 3 levels completed.
            // 4. If ad not ready: proceed immediately without delay.
            if (levelNumber <= 5 || HasNoAds)
            {
                onAdFlowDone?.Invoke();
                return;
            }

            _levelsCompletedSinceLastAd++;
            if (_levelsCompletedSinceLastAd >= 3 && _adService.IsInterstitialReady)
            {
                _levelsCompletedSinceLastAd = 0;
                _adService.ShowInterstitial(onAdFlowDone);
            }
            else
            {
                onAdFlowDone?.Invoke();
            }
        }

        public void RequestHintWithReward(Action<bool> onComplete)
        {
            if (_profile.HintCredits > 0)
            {
                _profile.HintCredits--;
                _saveService.Save(_profile);
                onComplete?.Invoke(true);
                return;
            }

            if (!_adService.IsRewardedReady)
            {
                onComplete?.Invoke(false);
                return;
            }

            bool rewarded = false;
            _adService.ShowRewarded(
                onRewardEarned: () =>
                {
                    rewarded = true;
                    _profile.HintCredits++;
                    _saveService.Save(_profile);
                },
                onClosed: () =>
                {
                    onComplete?.Invoke(rewarded);
                }
            );
        }

        public void PurchaseNoAds(Action<bool, string> onComplete)
        {
            _billingService.PurchaseNoAds((success, error) =>
            {
                if (success)
                {
                    _profile.NoAds = true;
                    _saveService.Save(_profile);
                }
                onComplete?.Invoke(success, error);
            });
        }

        public void RestorePurchases(Action<bool> onComplete)
        {
            _billingService.RestorePurchases(success =>
            {
                if (_billingService.HasNoAds && !_profile.NoAds)
                {
                    _profile.NoAds = true;
                    _saveService.Save(_profile);
                }
                onComplete?.Invoke(success);
            });
        }

        public void ShowPrivacyOptions()
        {
            _consentService.ShowPrivacyOptionsForm();
        }
    }
}
