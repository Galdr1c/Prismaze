using System;
using UnityEngine;
using UnityEngine.Purchasing;
using UnityEngine.Purchasing.Extension;

namespace Prismaze.Unity.Monetization
{
    public sealed class UnityIAPAdapter : IBillingService, IDetailedStoreListener
    {
        public const string ProductNoAds = "remove_ads";

        IStoreController _controller;
        IExtensionProvider _extensions;
        Action<bool> _initCallback;
        Action<bool, string> _purchaseCallback;
        Action<bool> _restoreCallback;

        bool _hasNoAds;

        public bool IsInitialized => _controller != null && _extensions != null;
        public bool HasNoAds => _hasNoAds;

        public UnityIAPAdapter(bool initialNoAds = false)
        {
            _hasNoAds = initialNoAds;
        }

        public void Initialize(Action<bool> onInitialized)
        {
            _initCallback = onInitialized;
            if (IsInitialized)
            {
                onInitialized?.Invoke(true);
                return;
            }

            var builder = ConfigurationBuilder.Instance(StandardPurchasingModule.Instance());
            builder.AddProduct(ProductNoAds, ProductType.NonConsumable);
            UnityPurchasing.Initialize(this, builder);
        }

        Product FindProduct(string id)
        {
            if (_controller?.products?.all == null) return null;
            foreach (var p in _controller.products.all)
            {
                if (string.Equals(p.definition.id, id, StringComparison.Ordinal)) return p;
            }
            return null;
        }

        public void OnInitialized(IStoreController controller, IExtensionProvider extensions)
        {
            _controller = controller;
            _extensions = extensions;

            var product = FindProduct(ProductNoAds);
            if (product != null && product.hasReceipt)
            {
                _hasNoAds = true;
            }

            Debug.Log($"[UnityIAP] Initialized. NoAds owned: {_hasNoAds}");
            _initCallback?.Invoke(true);
            _initCallback = null;
        }

        public void OnInitializeFailed(InitializationFailureReason error)
        {
            Debug.LogWarning($"[UnityIAP] Initialization failed: {error}");
            _initCallback?.Invoke(false);
            _initCallback = null;
        }

        public void OnInitializeFailed(InitializationFailureReason error, string message)
        {
            Debug.LogWarning($"[UnityIAP] Initialization failed: {error} - {message}");
            _initCallback?.Invoke(false);
            _initCallback = null;
        }

        public void PurchaseNoAds(Action<bool, string> onComplete)
        {
            if (!IsInitialized)
            {
                onComplete?.Invoke(false, "Store not initialized");
                return;
            }

            var product = FindProduct(ProductNoAds);
            if (product == null || !product.availableToPurchase)
            {
                onComplete?.Invoke(false, "Product not available for purchase");
                return;
            }

            _purchaseCallback = onComplete;
            _controller.InitiatePurchase(product);
        }

        public PurchaseProcessingResult ProcessPurchase(PurchaseEventArgs args)
        {
            if (string.Equals(args.purchasedProduct.definition.id, ProductNoAds, StringComparison.Ordinal))
            {
                _hasNoAds = true;
                Debug.Log("[UnityIAP] remove_ads successfully purchased.");
                _purchaseCallback?.Invoke(true, null);
                _purchaseCallback = null;
            }

            return PurchaseProcessingResult.Complete;
        }

        public void OnPurchaseFailed(Product product, PurchaseFailureReason failureReason)
        {
            Debug.LogWarning($"[UnityIAP] Purchase failed for {product.definition.id}: {failureReason}");
            _purchaseCallback?.Invoke(false, failureReason.ToString());
            _purchaseCallback = null;
        }

        public void OnPurchaseFailed(Product product, PurchaseFailureDescription failureDescription)
        {
            Debug.LogWarning($"[UnityIAP] Purchase failed: {failureDescription.message}");
            _purchaseCallback?.Invoke(false, failureDescription.message);
            _purchaseCallback = null;
        }

        public void RestorePurchases(Action<bool> onComplete)
        {
            if (!IsInitialized)
            {
                onComplete?.Invoke(false);
                return;
            }

            _restoreCallback = onComplete;
#if UNITY_ANDROID
            var googlePlay = _extensions.GetExtension<IGooglePlayStoreExtensions>();
            if (googlePlay != null)
            {
                googlePlay.RestoreTransactions((success, error) =>
                {
                    var product = FindProduct(ProductNoAds);
                    if (product != null && product.hasReceipt)
                    {
                        _hasNoAds = true;
                    }
                    _restoreCallback?.Invoke(success);
                    _restoreCallback = null;
                });
            }
            else
            {
                _restoreCallback?.Invoke(false);
                _restoreCallback = null;
            }
#elif UNITY_IOS || UNITY_STANDALONE_OSX
            var apple = _extensions.GetExtension<IAppleExtensions>();
            if (apple != null)
            {
                apple.RestoreTransactions((success, error) =>
                {
                    var product = FindProduct(ProductNoAds);
                    if (product != null && product.hasReceipt)
                    {
                        _hasNoAds = true;
                    }
                    _restoreCallback?.Invoke(success);
                    _restoreCallback = null;
                });
            }
            else
            {
                _restoreCallback?.Invoke(false);
                _restoreCallback = null;
            }
#else
            _restoreCallback?.Invoke(true);
            _restoreCallback = null;
#endif
        }
    }
}
