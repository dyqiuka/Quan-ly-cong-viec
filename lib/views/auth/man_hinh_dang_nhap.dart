import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart' hide LinearGradient, Image; 

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

        if (!mounted) return;

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
            content: Text(isEn ? "Login failed! Please check your credentials." : "Lỗi đăng nhập: Sai email hoặc mật khẩu!")
          )
        );
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

  void _hienThiHopThoaiQuenMatKhau() {
    final isEn = context.read<CaiDatProvider>().isEnglish;
    final isDark = context.read<CaiDatProvider>().isDarkMode;
    TextEditingController emailResetController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEn ? "Reset Password" : "Khôi phục mật khẩu", 
          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEn ? "Enter your email address" : "Nhập địa chỉ email của bạn",
              style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: emailResetController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[400]!)
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade400, width: 2)
                ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () async {
              String input = emailResetController.text.trim();
              if (input.isNotEmpty && input.contains('@')) {
                try {
                  await _dichVuFirebase.quenMatKhau(input);
                  if (!context.mounted) return;
                  Navigator.pop(context); 
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.green, content: Text(isEn ? "Sent!" : "Đã gửi!")));
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text("Error!")));
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.orange, content: Text(isEn ? "Invalid email!" : "Email không hợp lệ!")));
              }
            },
            child: Text(isEn ? "Send" : "Gửi", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<CaiDatProvider>().isEnglish;
    final isDark = context.watch<CaiDatProvider>().isDarkMode;

    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF4F7FC);
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputFill = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50;
    final inputBorder = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Center( 
              child: SingleChildScrollView( 
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt_rounded, size: 42, color: Colors.blue.shade600),
                        const SizedBox(width: 12),
                        Text(
                          "SMART TO-DO",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEn ? "Organize your work, boost productivity" : "Tổ chức công việc, nâng cao năng suất",
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 36),

                    Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue.shade100, width: 4),  
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black54 : Colors.blue.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
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
                    const SizedBox(height: 32),
                    
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black38 : Colors.grey.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          )
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEn ? "Sign in to your account" : "Đăng nhập tài khoản",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            const SizedBox(height: 24),
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
                                labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                prefixIcon: Icon(Icons.email_outlined, color: isDark ? Colors.grey[400] : Colors.grey),
                                filled: true,
                                fillColor: inputFill,
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: inputBorder)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blue.shade400, width: 2)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return isEn ? "Enter email" : "Vui lòng nhập email";
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
                                labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                prefixIcon: Icon(Icons.lock_outline, color: isDark ? Colors.grey[400] : Colors.grey),
                                filled: true,
                                fillColor: inputFill,
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: inputBorder)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blue.shade400, width: 2)),
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
                                child: Text(isEn ? "Forgot password?" : "Quên mật khẩu?", style: TextStyle(color: isDark ? Colors.blue.shade300 : Colors.blue.shade700, fontWeight: FontWeight.w600)),
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,  
                                ),
                                child: _dangTai 
                                    ? const CircularProgressIndicator(color: Colors.white) 
                                    : Text(isEn ? "Sign In" : "Đăng Nhập", style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(child: Divider(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(isEn ? "OR" : "HOẶC", style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                Expanded(child: Divider(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                              ],
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton.icon(
                                icon: Image.asset('assets/images/google_logo.png', height: 24, errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 36, color: Colors.red)),
                                label: Text(
                                  isEn ? "Continue with Google" : "Tiếp tục với Google", 
                                  style: TextStyle(fontSize: 15, color: textColor, fontWeight: FontWeight.w600)
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
                    
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(isEn ? "Don't have an account?" : "Chưa có tài khoản?", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey.shade700)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ManHinhDangKy()));
                          },
                          child: Text(isEn ? "Register now" : "Đăng ký ngay", style: TextStyle(color: isDark ? Colors.blue.shade300 : Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: inputBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    IconButton(
                      icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: isDark ? Colors.blue.shade200 : Colors.orange),
                      onPressed: () => context.read<CaiDatProvider>().toggleTheme(),
                      tooltip: isEn ? "Toggle Theme" : "Đổi nền",
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Divider(height: 1, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                    ),
                    IconButton(
                      icon: Text(
                        isEn ? "EN" : "VN", 
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)
                      ),
                      onPressed: () => context.read<CaiDatProvider>().toggleLanguage(),
                      tooltip: isEn ? "Change Language" : "Đổi ngôn ngữ",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}