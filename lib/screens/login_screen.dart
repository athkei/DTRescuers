import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

enum _Mode { splash, login }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  _Mode _mode = _Mode.splash;
  bool _entered = false;
  bool _buttonsIn = false;
  bool _busy = false;
  bool _hidePw = true;

  final _loginKey = GlobalKey<FormState>();
  final _loginId = TextEditingController();
  final _loginPw = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _buttonsIn = true);
    });
  }

  @override
  void dispose() {
    _loginId.dispose();
    _loginPw.dispose();
    super.dispose();
  }

  void _go(_Mode m) {
    FocusScope.of(context).unfocus();
    setState(() {
      _mode = m;
      _hidePw = true;
    });
  }

  Future<void> _logIn() async {
    if (!_loginKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await AuthService.instance.signIn(_loginId.text, _loginPw.text);
    } on AuthException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } catch (_) {
      if (mounted)
        showSnack(context, 'Something went wrong. Please try again.',
            error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.redLight, AppColors.redDark],
  );
  static const _slow = Duration(milliseconds: 650);
  static const _curve = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    OutlineInputBorder pill([Color c = AppColors.line]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: c));

    final formTheme = base.copyWith(
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: Colors.white,
        border: pill(),
        enabledBorder: pill(),
        focusedBorder: pill(AppColors.red),
        errorBorder: pill(const Color(0xFFB3261E)),
        focusedErrorBorder: pill(const Color(0xFFB3261E)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      ),
    );

    final mq = MediaQuery.of(context);
    final splash = _mode == _Mode.splash;
    final keyboard = mq.viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(builder: (context, box) {
        final h = box.maxHeight;
        final safeTop = mq.padding.top;

        final logoTop = splash ? h * 0.26 : safeTop + 26;
        final scale = !_entered ? 0.82 : (splash ? 1.0 : 0.72);
        final groupH = (124 + 22 + 38) * 0.72;
        final sheetTop =
            splash ? h : (keyboard ? safeTop + 12 : safeTop + 26 + groupH + 22);

        return Container(
          decoration: const BoxDecoration(gradient: _gradient),
          child: Stack(children: [
            // Decorative circles
            AnimatedPositioned(
              duration: _slow,
              curve: _curve,
              top: splash ? -60 : -95,
              right: splash ? -50 : -70,
              child: Container(
                width: 190,
                height: 190,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.gold),
              ),
            ),
            AnimatedPositioned(
              duration: _slow,
              curve: _curve,
              bottom: splash ? -120 : -200,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),

            // Logo + name
            AnimatedPositioned(
              duration: _slow,
              curve: _curve,
              top: logoTop,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: (!_entered || (keyboard && !splash)) ? 0 : 1,
                child: AnimatedScale(
                  duration: _slow,
                  curve: _curve,
                  scale: scale,
                  alignment: Alignment.topCenter,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black38,
                              blurRadius: 24,
                              offset: Offset(0, 10))
                        ],
                      ),
                      // NOTE: Replace this Icon with Image.asset('assets/logo.png', width: 124, height: 124) when you have the file
                      child: const Icon(Icons.shield_outlined,
                          size: 124, color: Colors.white),
                    ),
                    const SizedBox(height: 22),
                    const Text('DisasTrack',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            height: 1.2,
                            fontWeight: FontWeight.w800)),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: splash && _entered ? 1 : 0,
                      child: const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text('DRRM Personnel Access',
                            style: TextStyle(
                                color: Color(0xFFF3DAD2), fontSize: 14.5)),
                      ),
                    ),
                  ]),
                ),
              ),
            ),

            // Splash button
            Positioned(
              left: 28,
              right: 28,
              bottom: mq.padding.bottom + 24,
              child: IgnorePointer(
                ignoring: !splash,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  offset: (splash && _buttonsIn)
                      ? Offset.zero
                      : const Offset(0, 0.5),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: (splash && _buttonsIn) ? 1 : 0,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      FilledButton(
                        onPressed: () => _go(_Mode.login),
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.red,
                            shape: const StadiumBorder()),
                        child: const Text('Log In to Dashboard'),
                      ),
                    ]),
                  ),
                ),
              ),
            ),

            // White form sheet slides up from the bottom.
            AnimatedPositioned(
              duration: _slow,
              curve: _curve,
              left: 0,
              right: 0,
              bottom: 0,
              top: sheetTop,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SafeArea(
                  top: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.topCenter,
                          fit: StackFit.expand,
                          children: [...previous, if (current != null) current],
                        ),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween(
                                    begin: const Offset(0, 0.04),
                                    end: Offset.zero)
                                .animate(anim),
                            child: child,
                          ),
                        ),
                        child: SingleChildScrollView(
                          key: const ValueKey(_Mode.login),
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                          child: Theme(
                            data: formTheme,
                            child: _loginForm(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        );
      }),
    );
  }

  Widget _busyChild(String label) => _busy
      ? const SizedBox(
          height: 22,
          width: 22,
          child:
              CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
      : Text(label);

  Widget _loginForm() {
    return Form(
      key: _loginKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Welcome back!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.red,
                fontSize: 24,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Log in to view assigned incidents',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 24),
        TextFormField(
          controller: _loginId,
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
              labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Username is required' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _loginPw,
          obscureText: _hidePw,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: _busy ? null : (_) => _logIn(),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_hidePw
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () => setState(() => _hidePw = !_hidePw),
            ),
          ),
          validator: (v) => (v ?? '').isEmpty ? 'Password is required' : null,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : _logIn,
          style: FilledButton.styleFrom(shape: const StadiumBorder()),
          child: _busyChild('Log In'),
        ),
      ]),
    );
  }
}
