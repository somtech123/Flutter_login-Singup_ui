import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth.dart';
import '../model/http_execption.dart';

enum AuthMode { Signup, Login }

class AuthCard extends StatefulWidget {
  const AuthCard({super.key});

  @override
  State<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  AuthMode _authMode = AuthMode.Login;
  Map<String, String> _authData = {'email': '', 'password': ''};
  var _isLoading = false;
  final _passwordController = TextEditingController();

  bool _passwordVisible = true;
  void _toggle() {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: ((context) => AlertDialog(
            title: const Text('An Error Occured'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Okay'),
              )
            ],
          )),
    );
  }

  void _switchAuthMode() {
    if (_authMode == AuthMode.Login) {
      setState(() {
        _authMode = AuthMode.Signup;
      });
    } else {
      setState(() {
        _authMode = AuthMode.Login;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
      // invalid
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });
    try {
      if (_authMode == AuthMode.Login) {
        await Provider.of<Auth>(context, listen: false)
            .login(_authData['email']!, _authData['password']!);
      } else {
        await Provider.of<Auth>(context, listen: false)
            .singup(_authData['email']!, _authData['password']!);
      }
    } on HttpExecption catch (error) {
      var errorMessage = 'Authetication failed';
      if (error.toString().contains('EMAIL_EXISTS')) {
        errorMessage = 'This email address is already in use';
      } else if (error.toString().contains('INVALID_EMAIL')) {
        errorMessage = 'this is not a valid email address';
      } else if (error.toString().contains('WEAK_PASSWORD')) {
        errorMessage = 'This password is too weak.';
      } else if (error.toString().contains('EMAIL_NOT_FOUND')) {
        errorMessage = 'Could not find a user with that email.';
      } else if (error.toString().contains('INVALID_PASSWORD')) {
        errorMessage = 'Invalid password';
      }
      _showErrorDialog(errorMessage);
    } catch (error) {
      const errorMessage =
          'Could not authenticate you. Please try again later.';
      _showErrorDialog(errorMessage);
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 8.0,
      child: Container(
        height: _authMode == AuthMode.Signup ? 320 : 260,
        constraints:
            BoxConstraints(maxHeight: _authMode == AuthMode.Signup ? 320 : 260),
        width: deviceSize.width * 0.75,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'E-Mail',
                    suffixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value!.isEmpty || !value.contains('@')) {
                      return 'Invalid email';
                    }
                    return null;
                  },
                  onSaved: (newValue) {
                    _authData['email'] = newValue!;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      onPressed: _toggle,
                      icon: Icon(_passwordVisible
                          ? Icons.visibility_off
                          : Icons.visibility),
                    ),
                  ),
                  obscureText: _passwordVisible,
                  controller: _passwordController,
                  validator: ((value) {
                    if (value!.isEmpty || value.length < 5) {
                      return 'Password is too short!';
                    }
                  }),
                  onSaved: ((newValue) {
                    _authData['password'] = newValue!;
                  }),
                ),
                if (_authMode == AuthMode.Signup)
                  TextFormField(
                    enabled: _authMode == AuthMode.Signup,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      suffixIcon: IconButton(
                        onPressed: _toggle,
                        icon: Icon(_passwordVisible
                            ? Icons.visibility_off
                            : Icons.visibility),
                      ),
                    ),
                    obscureText: _passwordVisible,
                    validator: _authMode == AuthMode.Signup
                        ? (value) {
                            if (value != _passwordController.text) {
                              return 'Password do not match!';
                            }
                          }
                        : null,
                  ),
                const SizedBox(
                  height: 20,
                ),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30.0, vertical: 8.0),
                      primary: Theme.of(context).primaryColor,
                    ),
                    onPressed: _submit,
                    child:
                        Text(_authMode == AuthMode.Login ? 'Login' : 'SIGN UP'),
                  ),
                TextButton(
                  onPressed: _switchAuthMode,
                  // ignore: sort_child_properties_last
                  child: Text(
                      '${_authMode == AuthMode.Login ? 'SIGNUP' : 'LOGIN'} INSTEAD'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30.0, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    primary: Theme.of(context).primaryColor,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
