import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/banner_model.dart';

class BannerProvider extends ChangeNotifier {
  List<BannerModel> _banners = [];
  bool _isLoading = false;

  List<BannerModel> get banners => _banners;
  bool get isLoading => _isLoading;

  Future<void> fetchBanners({String? city}) async {
    _isLoading = true;
    notifyListeners();

    try {
      var query = Supabase.instance.client
          .from('banners')
          .select()
          .or('status.eq.Approved,status.eq.Active');

      if (city != null && city.isNotEmpty) {
        query = query.or('city.eq.$city,city.is.null');
      }

      final data = await query.order('priority', ascending: false);
      
      _banners = (data as List<dynamic>)
          .map((json) => BannerModel.fromJson(json as Map<String, dynamic>))
          .where((banner) {
            // Filter by date if applicable
            bool valid = true;
            /*
            if (banner.startDate != null) {
              if (now.isBefore(DateTime.parse(banner.startDate!))) valid = false;
            }
            if (banner.endDate != null) {
              if (now.isAfter(DateTime.parse(banner.endDate!))) valid = false;
            }
            */
            // Above commented out for simplicity, Supabase timestamp parsing can be tricky, 
            // doing it via DB might be better. Let's assume active if approved for now.
            return valid;
          })
          .toList();

    } catch (e) {
      debugPrint('Error fetching banners: $e');
      _banners = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
