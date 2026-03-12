import 'package:flutter/material.dart';
import '../models/premium_model.dart';
import '../services/premium_service.dart';

class PremiumProvider extends ChangeNotifier {
  final PremiumService _service = PremiumService();

  bool _isPremium = false;
  SubscriptionInfo? _subscription;
  Map<String, dynamic>? _benefits;
  bool _isLoading = false;
  String? _error;

  bool get isPremium => _isPremium;
  SubscriptionInfo? get subscription => _subscription;
  Map<String, dynamic>? get benefits => _benefits;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<PremiumTier> get availableTiers => PremiumTier.tiers;
  List<PremiumFeature> get allFeatures => PremiumFeature.allFeatures;

  Future<void> checkPremiumStatus() async {
    try {
      _isPremium = await _service.isPremium();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadSubscriptionInfo() async {
    try {
      _isLoading = true;
      notifyListeners();

      _subscription = await _service.getCurrentSubscription();
      _isPremium = _subscription?.isActive ?? false;

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBenefits() async {
    try {
      _benefits = await _service.getPremiumBenefits();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> activatePremium({
    required String tier,
    required DateTime expiryDate,
    String? platform,
    String? transactionId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.activatePremium(
        tier: tier,
        expiryDate: expiryDate,
        platform: platform,
        transactionId: transactionId,
      );

      await loadSubscriptionInfo();
      await loadBenefits();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelSubscription() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.cancelSubscription();
      await loadSubscriptionInfo();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.restorePurchases();
      await loadSubscriptionInfo();
      await loadBenefits();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
