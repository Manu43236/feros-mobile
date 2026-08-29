import 'package:dio/dio.dart';
import 'package:feros/core/api/api_client.dart';

/// Lightweight fake for ApiClient. Override onInit to skip Dio setup.
/// Register stubs by path before calling controller methods.
class FakeApiClient extends ApiClient {
  final _gets  = <String, dynamic Function(Map<String, dynamic>?)>{};
  final _posts = <String, dynamic Function(dynamic)>{};
  final _puts  = <String, dynamic Function(dynamic)>{};

  @override
  // ignore: must_call_super
  void onInit() {} // ponytail: skip Dio + interceptor setup entirely

  void stubGet(String path, dynamic data)    => _gets[path]  = (_) => data;
  void stubPost(String path, dynamic data)   => _posts[path] = (_) => data;
  void stubPut(String path, dynamic data)    => _puts[path]  = (_) => data;

  void stubGetFn(String path, dynamic Function(Map<String, dynamic>? params) fn) =>
      _gets[path] = fn;
  void stubPostFn(String path, dynamic Function(dynamic body) fn) =>
      _posts[path] = fn;
  void stubPutFn(String path, dynamic Function(dynamic body) fn) =>
      _puts[path] = fn;

  @override
  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    if (_gets.containsKey(path)) return _ok(_gets[path]!(params));
    throw Exception('FakeApiClient: no GET stub for "$path"');
  }

  @override
  Future<Response> post(String path, {dynamic data}) async {
    if (_posts.containsKey(path)) return _ok(_posts[path]!(data));
    throw Exception('FakeApiClient: no POST stub for "$path"');
  }

  @override
  Future<Response> put(String path, {dynamic data}) async {
    if (_puts.containsKey(path)) return _ok(_puts[path]!(data));
    throw Exception('FakeApiClient: no PUT stub for "$path"');
  }

  static Response<dynamic> _ok(dynamic data) => Response(
        data: data,
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      );
}
