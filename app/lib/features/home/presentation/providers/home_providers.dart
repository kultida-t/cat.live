import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/mock_home_hero_data_source.dart';
import '../../data/repositories/home_hero_repository_impl.dart';
import '../../domain/repositories/home_hero_repository.dart';
import '../../domain/usecases/get_home_hero_gallery.dart';

final homeHeroDataSourceProvider = Provider<MockHomeHeroDataSource>(
  (ref) => const MockHomeHeroDataSource(),
);

final homeHeroRepositoryProvider = Provider<HomeHeroRepository>(
  (ref) => HomeHeroRepositoryImpl(ref.watch(homeHeroDataSourceProvider)),
);

final getHomeHeroGalleryProvider = Provider<GetHomeHeroGallery>(
  (ref) => GetHomeHeroGallery(ref.watch(homeHeroRepositoryProvider)),
);
