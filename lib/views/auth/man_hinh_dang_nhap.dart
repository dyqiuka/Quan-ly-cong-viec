import 'package:flutter/material.dart';
import '../../services/dich_vu_firebase.dart';
import '../auth/man_hinh_dang_ky.dart';
import '../home/man_hinh_chinh.dart';

class ManHinhDangNhap extends StatefulWidget {
  const ManHinhDangNhap({Key? key}) : super(key: key);

  @override
  _ManHinhDangNhapState createState() => _ManHinhDangNhapState();
}

class _ManHinhDangNhapState extends State<ManHinhDangNhap> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _matKhauController = TextEditingController();
  
  final DichVuFirebase _dichVuFirebase = DichVuFirebase();
  
  bool _anMatKhau = true; 
  bool _dangTai = false; 

  // Hàm xử lý Đăng nhập Email/Mật khẩu
  void _xuLyDangNhap() async {
    // Kích hoạt validate form
    if (_formKey.currentState!.validate()) {
      setState(() => _dangTai = true); 
      
      try {
        await _dichVuFirebase.dangNhapEmailMatKhau(
          _emailController.text.trim(),
          _matKhauController.text.trim(),
        );
        
        if (!mounted) return; 

        setState(() => _dangTai = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng nhập thành công!"))
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ManHinhChinh()),
        );

      } catch (e) {
        if (!mounted) return;
        setState(() => _dangTai = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi đăng nhập: ${e.toString()}"))
        );
      }
    }
  }

  // Hàm xử lý Google Sign-in
  void _xuLyDangNhapGoogle() async {
    setState(() => _dangTai = true);
    try {
      final user = await _dichVuFirebase.dangNhapGoogle();
      
      if (!mounted) return;

      if (user != null) {
        // 🔥 ĐÃ SỬA: Thêm lệnh chuyển trang khi đăng nhập Google thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng nhập Google thành công!"))
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ManHinhChinh()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi Google: ${e.toString()}"))
        );
      }
    }
    if (mounted) {
      setState(() => _dangTai = false);
    }
  }

  // Hộp thoại Quên mật khẩu
  void _hienThiHopThoaiQuenMatKhau() {
    TextEditingController emailResetController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Quên mật khẩu?"),
        content: TextField(
          controller: emailResetController,
          decoration: const InputDecoration(hintText: "Nhập email của bạn"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              if (emailResetController.text.isNotEmpty) {
                await _dichVuFirebase.quenMatKhau(emailResetController.text.trim());
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã gửi email khôi phục. Vui lòng kiểm tra hộp thư!")));
              }
            },
            child: const Text("Gửi"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Nên set màu nền để tránh lỗi giao diện
      body: SafeArea(
        child: Center( // Bọc Center để giao diện luôn nằm giữa nếu màn hình dài
          child: SingleChildScrollView( 
            padding: const EdgeInsets.all(24.0),
            // 🔥 ĐÃ SỬA: Bọc thẻ Form vào đây và gọi _formKey
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("ĐĂNG NHẬP", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 40),
                  
                  // Ô nhập Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? "Vui lòng nhập email" : null,
                  ),
                  const SizedBox(height: 20),

                  // Ô nhập Mật khẩu (Có nút ẩn hiện)
                  TextFormField(
                    controller: _matKhauController,
                    obscureText: _anMatKhau, 
                    decoration: InputDecoration(
                      labelText: "Mật khẩu",
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      // Lấy icon làm nút bấm cho gọn
                      suffixIcon: IconButton(
                        icon: Icon(_anMatKhau ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _anMatKhau = !_anMatKhau; 
                          });
                        },
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? "Vui lòng nhập mật khẩu" : null,
                  ),
                  
                  // Nút Quên mật khẩu
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _hienThiHopThoaiQuenMatKhau,
                      child: const Text("Quên mật khẩu?"),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Nút Đăng nhập
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _dangTai ? null : _xuLyDangNhap,
                      child: _dangTai 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text("Đăng Nhập", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nút Đăng nhập bằng Google
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.red),
                      label: const Text("Đăng nhập bằng Google", style: TextStyle(fontSize: 16)),
                      onPressed: _dangTai ? null : _xuLyDangNhapGoogle,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Chuyển sang màn hình Đăng ký
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Chưa có tài khoản?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ManHinhDangKy()));
                        },
                        child: const Text("Đăng ký ngay"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}