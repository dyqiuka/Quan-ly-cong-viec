import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import '../../services/dich_vu_firebase.dart';
import '../../providers/cai_dat_provider.dart'; // Đảm bảo đã import cái này

class ManHinhDangKy extends StatefulWidget {
  const ManHinhDangKy({super.key});

  @override
  State<ManHinhDangKy> createState() => _ManHinhDangKyState();
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

  StateMachineController? _controller;
  SMIInput<bool>? _isChecking;
  SMIInput<bool>? _isHandsUp;
  SMIInput<double>? _lookAt;
  SMITrigger? _success;
  SMITrigger? _fail;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      if (_lookAt != null) {
        _lookAt!.value = _emailController.text.length.toDouble() * 1.5;
      }
    });
  }

  void _onRiveInit(Artboard artboard) {
    _controller = StateMachineController.fromArtboard(artboard, 'State Machine 1');
    if (_controller != null) {
      artboard.addController(_controller!);
      _isChecking = _controller!.getBoolInput('Check');
      _isHandsUp = _controller!.getBoolInput('hands_up');
      _lookAt = _controller!.getNumberInput('Look');
      _success = _controller!.getTriggerInput('success');
      _fail = _controller!.getTriggerInput('fail');
    }
  }

  void _xuLyDangKy() async {
    final isEn = context.read<CaiDatProvider>().isEnglish; // Đọc ngôn ngữ để hiện thông báo

    if (_formKey.currentState!.validate()) {
      setState(() => _dangTai = true);
      _isHandsUp?.value = false;
      
      try {
        await _dichVuFirebase.dangKyEmailMatKhau(
          _emailController.text.trim(),
          _matKhauController.text.trim(),
        );
        
        _success?.fire();
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isEn ? "Registration successful! Please login." : "Đăng ký thành công! Vui lòng đăng nhập lại.")),
          );
          Navigator.pop(context); 
        }
      } catch (e) {
        _fail?.fire();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text(e.toString())),
          );
        }
      }
      
      if (mounted) {
        setState(() => _dangTai = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Lấy trạng thái từ Provider
    final isEn = context.watch<CaiDatProvider>().isEnglish;
    final isDark = context.watch<CaiDatProvider>().isDarkMode;

    // 🔥 Cấu hình màu sắc theo Mode
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final inputFill = isDark ? Colors.grey[900] : Colors.grey.shade50;
    final inputBorder = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(isEn ? "Create Account" : "Tạo tài khoản"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.blue.shade300 : Colors.blue, 
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView( 
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: RiveAnimation.asset(
                      'assets/rive/520-990-teddy-login-screen.riv',
                      onInit: _onRiveInit,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Text(
                    isEn ? "REGISTER" : "ĐĂNG KÝ", 
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.blue.shade300 : Colors.blue)
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isEn ? "Create an account to sync your tasks" : "Tạo tài khoản để đồng bộ công việc của bạn",
                    style: TextStyle(color: subTextColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  
                  // 1. Ô nhập Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: textColor),
                    onTap: () {
                      _isHandsUp?.value = false;
                      _isChecking?.value = true;
                    },
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(color: subTextColor),
                      prefixIcon: Icon(Icons.email, color: subTextColor),
                      filled: true,
                      fillColor: inputFill,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return isEn ? "Please enter email" : "Vui lòng nhập email";
                      if (!value.contains('@')) return isEn ? "Invalid email" : "Email không hợp lệ";
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 2. Ô nhập Mật khẩu
                  TextFormField(
                    controller: _matKhauController,
                    obscureText: _anMatKhau,
                    style: TextStyle(color: textColor),
                    onTap: () {
                      _isChecking?.value = false;
                      _isHandsUp?.value = true;
                    },
                    decoration: InputDecoration(
                      labelText: isEn ? "Password" : "Mật khẩu",
                      labelStyle: TextStyle(color: subTextColor),
                      prefixIcon: Icon(Icons.lock, color: subTextColor),
                      filled: true,
                      fillColor: inputFill,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(_anMatKhau ? Icons.visibility_off : Icons.visibility, color: subTextColor),
                        onPressed: () => setState(() => _anMatKhau = !_anMatKhau),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return isEn ? "Please enter password" : "Vui lòng nhập mật khẩu";
                      if (value.length < 6) return isEn ? "At least 6 characters" : "Mật khẩu phải từ 6 ký tự trở lên";
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 3. Ô Xác nhận mật khẩu
                  TextFormField(
                    controller: _xacNhanMatKhauController,
                    obscureText: _anXacNhanMatKhau,
                    style: TextStyle(color: textColor),
                    onTap: () {
                      _isChecking?.value = false;
                      _isHandsUp?.value = true;
                    },
                    decoration: InputDecoration(
                      labelText: isEn ? "Confirm Password" : "Xác nhận mật khẩu",
                      labelStyle: TextStyle(color: subTextColor),
                      prefixIcon: Icon(Icons.lock_clock, color: subTextColor),
                      filled: true,
                      fillColor: inputFill,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(_anXacNhanMatKhau ? Icons.visibility_off : Icons.visibility, color: subTextColor),
                        onPressed: () => setState(() => _anXacNhanMatKhau = !_anXacNhanMatKhau),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return isEn ? "Please confirm password" : "Vui lòng xác nhận mật khẩu";
                      if (value != _matKhauController.text) return isEn ? "Passwords do not match!" : "Mật khẩu không khớp!";
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // Nút Đăng ký
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _dangTai ? null : _xuLyDangKy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _dangTai 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : Text(
                              isEn ? "Sign Up" : "Đăng Ký", 
                              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)
                            ),
                    ),
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