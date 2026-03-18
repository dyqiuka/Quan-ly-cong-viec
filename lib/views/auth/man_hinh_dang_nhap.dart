import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart'; 

import '../../services/dich_vu_firebase.dart';
import '../../providers/cai_dat_provider.dart';
import '../auth/man_hinh_dang_ky.dart';
import '../home/man_hinh_chinh.dart';

class ManHinhDangNhap extends StatefulWidget {
  const ManHinhDangNhap({super.key});

  @override
  State<ManHinhDangNhap> createState() => _ManHinhDangNhapState();
}

class _ManHinhDangNhapState extends State<ManHinhDangNhap> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _matKhauController = TextEditingController();
  
  final DichVuFirebase _dichVuFirebase = DichVuFirebase();
  
  bool _anMatKhau = true; 
  bool _dangTai = false; 

  // 🔥 Rive Controllers
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

  // 🔥 HÀM CHUYỂN TRANG HIỆU ỨNG TRƯỢT (SLIDE)
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

  // 🔥 1. HÀM XỬ LÝ ĐĂNG NHẬP
  void _xuLyDangNhap() async {
    final isEn = context.read<CaiDatProvider>().isEnglish;

    if (_formKey.currentState!.validate()) {
      setState(() => _dangTai = true); 
      _isHandsUp?.value = false;
      
      try {
        await _dichVuFirebase.dangNhapEmailMatKhau(
          _emailController.text.trim(),
          _matKhauController.text.trim(),
        );
        
        if (!mounted) return; 

        _success?.fire(); 
        await Future.delayed(const Duration(milliseconds: 800));

        setState(() => _dangTai = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEn ? "Login successful!" : "Đăng nhập thành công!"))
        );

        _chuyenTrangVoiHieuUngKeo();

      } catch (e) {
        if (!mounted) return;
        _fail?.fire(); 
        setState(() => _dangTai = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(isEn ? "Login failed!" : "Lỗi đăng nhập: Sai email hoặc mật khẩu!")
          )
        );
      }
    }
  }

  // 🔥 2. HÀM XỬ LÝ ĐĂNG NHẬP GOOGLE
  void _xuLyDangNhapGoogle() async {
    final isEn = context.read<CaiDatProvider>().isEnglish;
    setState(() => _dangTai = true);

    try {
      final user = await _dichVuFirebase.dangNhapGoogle();
      
      if (!mounted) return;

      if (user != null) {
        _success?.fire();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEn ? "Google login successful!" : "Đăng nhập Google thành công!"))
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

  // 🔥 3. HỘP THOẠI QUÊN MẬT KHẨU
  void _hienThiHopThoaiQuenMatKhau() {
    final isEn = context.read<CaiDatProvider>().isEnglish;
    final isDark = context.read<CaiDatProvider>().isDarkMode;
    TextEditingController emailResetController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          isEn ? "Reset Password" : "Khôi phục mật khẩu", 
          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEn ? "Enter your email" : "Nhập email của bạn",
              style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: emailResetController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[400]!)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text(isEn ? "Cancel" : "Hủy", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600),
            onPressed: () async {
              String email = emailResetController.text.trim();
              if (email.isNotEmpty) {
                try {
                  await _dichVuFirebase.quenMatKhau(email);
                  if (!context.mounted) return;
                  Navigator.pop(context); 
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.green, content: Text(isEn ? "Sent!" : "Đã gửi!")));
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Error!")));
                }
              }
            },
            child: Text(isEn ? "Send" : "Gửi", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🔥 4. GIAO DIỆN CHÍNH
  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<CaiDatProvider>().isEnglish;
    final isDark = context.watch<CaiDatProvider>().isDarkMode;

    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputFill = isDark ? Colors.grey[900] : Colors.grey.shade50;
    final inputBorder = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bgColor, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Row(
            children: [
              Text("VN", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
              Switch(
                value: isEn,
                activeThumbColor: Colors.blue, 
                onChanged: (value) => context.read<CaiDatProvider>().toggleLanguage(),
              ),
              Text("EN", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              Icon(Icons.light_mode, color: isDark ? Colors.grey : Colors.orange, size: 20),
              Switch(
                value: isDark,
                activeThumbColor: Colors.blue, 
                onChanged: (value) => context.read<CaiDatProvider>().toggleTheme(),
              ),
              Icon(Icons.dark_mode, color: isDark ? Colors.blue.shade200 : Colors.grey, size: 20),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),

      body: SafeArea(
        child: Center( 
          child: SingleChildScrollView( 
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                    isEn ? "LOGIN" : "ĐĂNG NHẬP", 
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.blue.shade300 : Colors.blue.shade700)
                  ),
                  const SizedBox(height: 30),
                  
                  // Ô nhập Email
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
                      labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                      prefixIcon: Icon(Icons.email, color: isDark ? Colors.grey[400] : Colors.grey),
                      filled: true,
                      fillColor: inputFill,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: inputBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade400, width: 2)),
                    ),
                    validator: (value) => value!.isEmpty ? (isEn ? "Enter email" : "Vui lòng nhập email") : null,
                  ),
                  const SizedBox(height: 20),

                  // Ô nhập Mật khẩu 
                  TextFormField(
                    controller: _matKhauController,
                    obscureText: _anMatKhau, 
                    style: TextStyle(color: textColor),
                    onTap: () {
                      _isChecking?.value = false;
                      _isHandsUp?.value = true; // 🔥 Gấu che mắt ngay lập tức
                    },
                    decoration: InputDecoration(
                      labelText: isEn ? "Password" : "Mật khẩu",
                      labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                      prefixIcon: Icon(Icons.lock, color: isDark ? Colors.grey[400] : Colors.grey),
                      filled: true,
                      fillColor: inputFill,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: inputBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade400, width: 2)),
                      suffixIcon: IconButton(
                        icon: Icon(_anMatKhau ? Icons.visibility_off : Icons.visibility, color: isDark ? Colors.grey[400] : Colors.grey),
                        onPressed: () => setState(() => _anMatKhau = !_anMatKhau),
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? (isEn ? "Enter password" : "Vui lòng nhập mật khẩu") : null,
                  ),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _hienThiHopThoaiQuenMatKhau,
                      child: Text(isEn ? "Forgot password?" : "Quên mật khẩu?", style: TextStyle(color: isDark ? Colors.blue.shade300 : Colors.blue)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _dangTai ? null : _xuLyDangNhap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _dangTai 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : Text(isEn ? "Sign In" : "Đăng Nhập", style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.g_mobiledata, size: 36, color: Colors.red),
                      label: Text(
                        isEn ? "Sign in with Google" : "Đăng nhập bằng Google", 
                        style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w600)
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: inputBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
                      ),
                      onPressed: _dangTai ? null : _xuLyDangNhapGoogle,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isEn ? "Don't have an account?" : "Chưa có tài khoản?", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.black87)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ManHinhDangKy()));
                        },
                        child: Text(isEn ? "Register now" : "Đăng ký ngay", style: TextStyle(color: isDark ? Colors.blue.shade300 : Colors.blue, fontWeight: FontWeight.bold)),
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