using System;
using GoogleMobileAds.Api;
using GoogleMobileAds.Ump.Api;
using UnityEngine;

namespace Prismaze.Unity.Monetization
{
    public sealed class GoogleMobileAdsAdapter : IAdService, IConsentService
    {
        // Google Official Sample / Test Ad Unit IDs for Android
        const string InterstitialTestId = "ca-app-pub-3940256099942544/1033173712";
        const string RewardedTestId = "ca-app-pub-3940256099942544/5224354917";

        readonly string _interstitialId;
        readonly string _rewardedId;

        InterstitialAd _interstitialAd;
        RewardedAd _rewardedAd;

        bool _isInitialized;
        bool _isLoadingInterstitial;
        bool _isLoadingRewarded;

        public bool IsInitialized => _isInitialized;
        public bool IsInterstitialReady => _interstitialAd != null && _interstitialAd.CanShowAd();
        public bool IsRewardedReady => _rewardedAd != null && _rewardedAd.CanShowAd();

        public bool CanRequestAds => ConsentInformation.CanRequestAds();
        public bool IsPrivacyOptionsRequired => ConsentInformation.PrivacyOptionsRequirementStatus == PrivacyOptionsRequirementStatus.Required;

        public GoogleMobileAdsAdapter(string interstitialId = null, string rewardedId = null)
        {
            _interstitialId = string.IsNullOrEmpty(interstitialId) ? InterstitialTestId : interstitialId;
            _rewardedId = string.IsNullOrEmpty(rewardedId) ? RewardedTestId : rewardedId;
        }

        public void CheckConsent(Action onCompleted)
        {
            var requestParameters = new ConsentRequestParameters();
            ConsentInformation.Update(requestParameters, error =>
            {
                if (error != null)
                {
                    Debug.LogWarning($"[GoogleMobileAds] UMP Consent update failed: {error.Message}");
                    onCompleted?.Invoke();
                    return;
                }

                ConsentForm.LoadAndShowConsentFormIfRequired(formError =>
                {
                    if (formError != null)
                    {
                        Debug.LogWarning($"[GoogleMobileAds] Consent form failed: {formError.Message}");
                    }
                    if (CanRequestAds && !_isInitialized)
                    {
                        Initialize();
                    }
                    onCompleted?.Invoke();
                });
            });
        }

        public void ShowPrivacyOptionsForm(Action onDismissed = null)
        {
            ConsentForm.ShowPrivacyOptionsForm(error =>
            {
                if (error != null)
                {
                    Debug.LogWarning($"[GoogleMobileAds] Privacy options form error: {error.Message}");
                }
                onDismissed?.Invoke();
            });
        }

        public void Initialize()
        {
            if (_isInitialized) return;
            MobileAds.Initialize(status =>
            {
                _isInitialized = true;
                Debug.Log("[GoogleMobileAds] Initialized successfully.");
                LoadInterstitial();
                LoadRewarded();
            });
        }

        public void LoadInterstitial()
        {
            if (!CanRequestAds || _isLoadingInterstitial || IsInterstitialReady) return;
            _isLoadingInterstitial = true;

            if (_interstitialAd != null)
            {
                _interstitialAd.Destroy();
                _interstitialAd = null;
            }

            var request = new AdRequest();
            InterstitialAd.Load(_interstitialId, request, (ad, error) =>
            {
                _isLoadingInterstitial = false;
                if (error != null || ad == null)
                {
                    Debug.LogWarning($"[GoogleMobileAds] Interstitial failed to load: {error?.GetMessage()}");
                    return;
                }
                _interstitialAd = ad;
                Debug.Log("[GoogleMobileAds] Interstitial loaded.");
            });
        }

        public void ShowInterstitial(Action onClosed)
        {
            if (!IsInterstitialReady)
            {
                onClosed?.Invoke();
                LoadInterstitial();
                return;
            }

            _interstitialAd.OnAdFullScreenContentClosed += () =>
            {
                onClosed?.Invoke();
                LoadInterstitial();
            };
            _interstitialAd.OnAdFullScreenContentFailed += _ =>
            {
                onClosed?.Invoke();
                LoadInterstitial();
            };

            _interstitialAd.Show();
        }

        public void LoadRewarded()
        {
            if (!CanRequestAds || _isLoadingRewarded || IsRewardedReady) return;
            _isLoadingRewarded = true;

            if (_rewardedAd != null)
            {
                _rewardedAd.Destroy();
                _rewardedAd = null;
            }

            var request = new AdRequest();
            RewardedAd.Load(_rewardedId, request, (ad, error) =>
            {
                _isLoadingRewarded = false;
                if (error != null || ad == null)
                {
                    Debug.LogWarning($"[GoogleMobileAds] Rewarded failed to load: {error?.GetMessage()}");
                    return;
                }
                _rewardedAd = ad;
                Debug.Log("[GoogleMobileAds] Rewarded ad loaded.");
            });
        }

        public void ShowRewarded(Action onRewardEarned, Action onClosed)
        {
            if (!IsRewardedReady)
            {
                onClosed?.Invoke();
                LoadRewarded();
                return;
            }

            bool earned = false;
            _rewardedAd.OnAdFullScreenContentClosed += () =>
            {
                if (earned) onRewardEarned?.Invoke();
                onClosed?.Invoke();
                LoadRewarded();
            };
            _rewardedAd.OnAdFullScreenContentFailed += _ =>
            {
                onClosed?.Invoke();
                LoadRewarded();
            };

            _rewardedAd.Show(reward =>
            {
                earned = true;
                Debug.Log($"[GoogleMobileAds] Rewarded earned: {reward.Type} {reward.Amount}");
            });
        }
    }
}
