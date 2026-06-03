// lib/core/network/api_exception.dart

class ApiException implements Exception {
  final String message;
  final int    statusCode;

  const ApiException({
    required this.message,
    required this.statusCode,
  });

  // ── Thông báo thân thiện hiển thị cho user ────────────────
  String get userFriendlyMessage {
    final msg = message.toLowerCase();

    // ── Map theo nội dung message trước (ưu tiên hơn statusCode) ──

    // Email đã tồn tại
    if (msg.contains('đã được đăng ký') ||
        msg.contains('already registered') ||
        msg.contains('already exists')) {
      return 'Email này đã được đăng ký. Vui lòng dùng email khác.';
    }

    // Sai email hoặc mật khẩu
    if (msg.contains('email hoặc mật khẩu') ||
        msg.contains('incorrect') ||
        msg.contains('invalid credentials') ||
        msg.contains('wrong password') ||
        msg.contains('could not validate credentials')) {
      return 'Email hoặc mật khẩu không đúng.';
    }

    // Token hết hạn
    if (msg.contains('token') &&
        (msg.contains('expired') || msg.contains('invalid'))) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }

    // Tài khoản bị khoá
    if (msg.contains('vô hiệu hóa') ||
        msg.contains('disabled') ||
        msg.contains('inactive')) {
      return 'Tài khoản đã bị vô hiệu hóa. Vui lòng liên hệ hỗ trợ.';
    }

    // OTP
    if (msg.contains('otp') && (msg.contains('expired') || msg.contains('hết hạn'))) {
      return 'Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.';
    }
    if (msg.contains('otp') && (msg.contains('invalid') || msg.contains('không đúng'))) {
      return 'Mã OTP không đúng. Vui lòng kiểm tra lại.';
    }

    // Không có quyền
    if (msg.contains('không có quyền') ||
        msg.contains('forbidden') ||
        msg.contains('permission denied')) {
      return 'Bạn không có quyền thực hiện thao tác này.';
    }

    // Bài viết không tồn tại
    if (msg.contains('bài viết') && msg.contains('không tồn tại')) {
      return 'Bài viết không còn tồn tại.';
    }

    // ── Map theo statusCode ───────────────────────────────────

    switch (statusCode) {
      case 0:
        return 'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối mạng.';
      case 400:
        return _parse400(msg);
      case 401:
      // 401 khi login = sai email/password
      // 401 khi đã login = token hết hạn
        return 'Email hoặc mật khẩu không đúng.';
      case 403:
        return 'Bạn không có quyền thực hiện thao tác này.';
      case 404:
        return 'Không tìm thấy dữ liệu yêu cầu.';
      case 409:
        return 'Email này đã được đăng ký. Vui lòng dùng email khác.';
      case 422:
        return _parse422(msg);
      case 429:
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau ít phút.';
      case 500:
        return 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.';
      case 503:
        return 'Dịch vụ tạm thời không khả dụng. Vui lòng thử lại sau.';
      default:
        return message.isNotEmpty
            ? message
            : 'Có lỗi xảy ra (mã: $statusCode). Vui lòng thử lại.';
    }
  }

  String _parse400(String msg) {
    if (msg.contains('email'))    return 'Địa chỉ email không hợp lệ.';
    if (msg.contains('password')) return 'Mật khẩu không đáp ứng yêu cầu bảo mật.';
    if (msg.contains('content'))  return 'Nội dung không được để trống.';
    return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại thông tin.';
  }

  String _parse422(String msg) {
    if (msg.contains('email'))     return 'Địa chỉ email không đúng định dạng.';
    if (msg.contains('password'))  return 'Mật khẩu phải có ít nhất 8 ký tự, 1 chữ hoa và 1 số.';
    if (msg.contains('full_name')) return 'Họ tên phải có ít nhất 2 ký tự.';
    if (msg.contains('content'))   return 'Nội dung bài viết không được để trống.';
    // FastAPI validation error thường đã rõ ràng
    return message.isNotEmpty
        ? message
        : 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại các trường.';
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}