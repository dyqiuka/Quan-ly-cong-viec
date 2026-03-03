import 'package:flutter/material.dart';
import '../../services/dich_vu_firebase.dart';
class ManHinhDangKy extends StatefulWidget {
  const ManHinhDangKy({Key? key}) : super(key: key);

  @override
  _ManHinhDangKyState createState() => _ManHinhDangKyState();
}

class _ManHinhDangKyState extends State<ManHinhDangKy> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _matKhauController = TextEditingController();
  final TextEditingController _xacNhanMatKhauController = TextEditingController();
  
  final DichVuFirebase _dichVuFirebase = DichVuFirebase();
  
  bool _anMatKhau = true; 
  bool _anXacNhanMatKhau = true;
  bool _dangTai = false;

  // Hàm xử lý Đăng ký
  void _xuLyDangKy() async {
    // Kiểm tra xem các ô nhập liệu đã hợp lệ chưa
    if (_formKey.currentState!.validate()) {
      setState(() => _dangTai = true); // Hiện vòng quay loading
      
      try {
        await _dichVuFirebase.dangKyEmailMatKhau(
          _emailController.text.trim(),
          _matKhauController.text.trim(),
        );
        
        // Hiện thông báo thành công
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đăng ký thành công! Vui lòng đăng nhập lại.")),
          );
          // Trở về màn hình đăng nhập
          Navigator.pop(context); 
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
      
      if (mounted) {
        setState(() => _dangTai = false); // Tắt loading
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Nút back trên AppBar
      appBar: AppBar(
        title: const Text("Tạo tài khoản"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.blue, // Màu mũi tên quay lại
      ),
      body: SafeArea(
        child: SingleChildScrollView( // Giúp màn hình không bị lỗi khi bàn phím hiện lên
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "ĐĂNG KÝ", 
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)
                ),
                const SizedBox(height: 10),
                const Text("Tạo tài khoản để đồng bộ công việc của bạn"),
                const SizedBox(height: 40),
                
                // 1. Ô nhập Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Vui lòng nhập email";
                    }
                    if (!value.contains('@')) {
                      return "Email không hợp lệ";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 2. Ô nhập Mật khẩu
                TextFormField(
                  controller: _matKhauController,
                  obscureText: _anMatKhau,
                  decoration: InputDecoration(
                    labelText: "Mật khẩu",
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_anMatKhau ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _anMatKhau = !_anMatKhau;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Vui lòng nhập mật khẩu";
                    }
                    if (value.length < 6) {
                      return "Mật khẩu phải từ 6 ký tự trở lên";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 3. Ô Xác nhận mật khẩu
                TextFormField(
                  controller: _xacNhanMatKhauController,
                  obscureText: _anXacNhanMatKhau,
                  decoration: InputDecoration(
                    labelText: "Xác nhận mật khẩu",
                    prefixIcon: const Icon(Icons.lock_clock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_anXacNhanMatKhau ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _anXacNhanMatKhau = !_anXacNhanMatKhau;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Vui lòng xác nhận lại mật khẩu";
                    }
                    if (value != _matKhauController.text) {
                      return "Mật khẩu không khớp!";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Nút Đăng ký
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _dangTai ? null : _xuLyDangKy,
                    child: _dangTai 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text("Đăng Ký", style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}