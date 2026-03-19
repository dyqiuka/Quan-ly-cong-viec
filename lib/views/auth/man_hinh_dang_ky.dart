import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart' hide LinearGradient, Image; 

import '../../services/dich_vu_firebase.dart';
import '../../providers/cai_dat_provider.dart';
import '../home/man_hinh_chinh.dart';

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

  void _chuyenTrangVoiHieuUngKeo() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const ManHinhChinh(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _xuLyDangKy() async {
    final isEn = context.read<CaiDatProvider>().isEnglish; 

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
            SnackBar(backgroundColor: Colors.red, content: Text(isEn ? "Registration failed!" : "Đăng ký thất bại, tài khoản có thể đã tồn tại!")),
          );
        }
      }
      
      if (mounted) {
        setState(() => _dangTai = false);
      }
    }
  }

  void _xuLyDangNhapGoogle() async {
    final isEn = context.read<CaiDatProvider>().isEnglish;
    setState(() => _dangTai = true);

    try {
      final user = await _dichVuFirebase.dangNhapGoogle();
      
      if (!mounted) return;

      if (user != null) {
        _success?.fire();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEn ? "Google sign-up successful!" : "Đăng ký Google thành công!"))
        );
        _chuyenTrangVoiHieuUngKeo();
      }
    } catch (e) {
      if (mounted) {
        _fail?.fire();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(isEn ? "Google Error!" : "Lỗi Google!")
          )
        );
      }
    }
    if (mounted) {
      setState(() => _dangTai = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<CaiDatProvider>().isEnglish;
    final isDark = context.watch<CaiDatProvider>().isDarkMode;

    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputFill = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50;
    final inputBorder = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEn ? "Create Account" : "Tạo tài khoản"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.blue.shade300 : Colors.blue.shade800, 
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF121212), const Color(0xFF1A1A2E)] 
              : [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView( 
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                children: [
                  Container(
                    height: 160,
                    width: 160,
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black54 : Colors.blue.withValues(alpha: 0.15),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: ClipOval(
                      child: RiveAnimation.asset(
                        'assets/rive/520-990-teddy-login-screen.riv',
                        onInit: _onRiveInit,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    isEn ? "REGISTER" : "ĐĂNG KÝ", 
                    style: TextStyle(
                      fontSize: 26, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 1.2,
                      color: isDark ? Colors.blue.shade300 : Colors.blue.shade800
                    )
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEn ? "Create an account to sync your tasks" : "Tạo tài khoản để đồng bộ công việc của bạn",
                    style: TextStyle(color: subTextColor, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black38 : Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
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
                              prefixIcon: Icon(Icons.email_outlined, color: subTextColor),
                              filled: true,
                              fillColor: inputFill,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: inputBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return isEn ? "Please enter email" : "Vui lòng nhập email";
                              if (!value.contains('@')) return isEn ? "Invalid email format" : "Định dạng email không hợp lệ";
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

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
                              prefixIcon: Icon(Icons.lock_outline, color: subTextColor),
                              filled: true,
                              fillColor: inputFill,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: inputBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
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
                              prefixIcon: Icon(Icons.lock_clock_outlined, color: subTextColor),
                              filled: true,
                              fillColor: inputFill,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: inputBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
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

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _dangTai ? null : _xuLyDangKy,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 4,
                                shadowColor: Colors.blue.withValues(alpha: 0.4),
                              ),
                              child: _dangTai 
                                  ? const CircularProgressIndicator(color: Colors.white) 
                                  : Text(
                                      isEn ? "Sign Up" : "Đăng Ký", 
                                      style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(child: Divider(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(isEn ? "OR" : "HOẶC", style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade500, fontSize: 12)),
                              ),
                              Expanded(child: Divider(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.g_mobiledata, size: 36, color: Colors.red),
                              label: Text(
                                isEn ? "Sign up with Google" : "Đăng ký bằng Google", 
                                style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w600)
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: inputBorder),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                backgroundColor: isDark ? Colors.grey[900] : Colors.white,
                              ),
                              onPressed: _dangTai ? null : _xuLyDangNhapGoogle,
                            ),
                          ),
                        ],
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