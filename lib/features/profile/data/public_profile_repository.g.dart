// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_profile_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$publicProfileHash() => r'00443d4279a6bedfd7032f4f99099900d465a0cf';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [publicProfile].
@ProviderFor(publicProfile)
const publicProfileProvider = PublicProfileFamily();

/// See also [publicProfile].
class PublicProfileFamily extends Family<AsyncValue<Map<String, dynamic>>> {
  /// See also [publicProfile].
  const PublicProfileFamily();

  /// See also [publicProfile].
  PublicProfileProvider call(String userId) {
    return PublicProfileProvider(userId);
  }

  @override
  PublicProfileProvider getProviderOverride(
    covariant PublicProfileProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'publicProfileProvider';
}

/// See also [publicProfile].
class PublicProfileProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// See also [publicProfile].
  PublicProfileProvider(String userId)
    : this._internal(
        (ref) => publicProfile(ref as PublicProfileRef, userId),
        from: publicProfileProvider,
        name: r'publicProfileProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$publicProfileHash,
        dependencies: PublicProfileFamily._dependencies,
        allTransitiveDependencies:
            PublicProfileFamily._allTransitiveDependencies,
        userId: userId,
      );

  PublicProfileProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>> Function(PublicProfileRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PublicProfileProvider._internal(
        (ref) => create(ref as PublicProfileRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _PublicProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PublicProfileProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PublicProfileRef on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _PublicProfileProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with PublicProfileRef {
  _PublicProfileProviderElement(super.provider);

  @override
  String get userId => (origin as PublicProfileProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
