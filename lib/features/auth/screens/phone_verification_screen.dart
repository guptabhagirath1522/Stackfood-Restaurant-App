import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/custom_app_bar_widget.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/custom_button_widget.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/custom_snackbar_widget.dart';
import 'package:stackfood_multivendor_restaurant/features/auth/controllers/auth_controller.dart';
import 'package:stackfood_multivendor_restaurant/features/profile/controllers/profile_controller.dart';
import 'package:stackfood_multivendor_restaurant/helper/route_helper.dart';
import 'package:stackfood_multivendor_restaurant/util/dimensions.dart';
import 'package:stackfood_multivendor_restaurant/util/styles.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phone;
  const PhoneVerificationScreen({Key? key, required this.phone})
      : super(key: key);

  @override
  PhoneVerificationScreenState createState() => PhoneVerificationScreenState();
}

class PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  String _otp = '';
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds = _seconds - 1;
      if (_seconds == 0) {
        timer.cancel();
        _timer?.cancel();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'otp_verification'.tr),
      body: SafeArea(
        child: GetBuilder<AuthController>(builder: (authController) {
          return Column(children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: Center(
                  child: SizedBox(
                    width: 1170,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 55),
                          Text(
                            'verification_code_sent'.tr,
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                              color: Theme.of(context).disabledColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: widget.phone,
                                style: robotoMedium.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: Dimensions.fontSizeSmall,
                                ),
                              ),
                            ]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          PinCodeTextField(
                            length: 4,
                            appContext: context,
                            keyboardType: TextInputType.number,
                            animationType: AnimationType.slide,
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              fieldHeight: 60,
                              fieldWidth: 60,
                              borderWidth: 1,
                              borderRadius: BorderRadius.circular(
                                  Dimensions.radiusDefault),
                              selectedColor: Theme.of(context).primaryColor,
                              selectedFillColor: Colors.white,
                              inactiveFillColor: Colors.white,
                              inactiveColor: Theme.of(context)
                                  .disabledColor
                                  .withOpacity(0.3),
                              activeColor: Theme.of(context)
                                  .disabledColor
                                  .withOpacity(0.3),
                              activeFillColor: Colors.white,
                            ),
                            animationDuration:
                                const Duration(milliseconds: 300),
                            backgroundColor: Colors.transparent,
                            enableActiveFill: true,
                            onChanged: (value) {
                              setState(() {
                                _otp = value;
                              });
                            },
                            beforeTextPaste: (text) => true,
                          ),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'did_not_receive_the_code'.tr,
                                  style: robotoRegular.copyWith(
                                      color: Theme.of(context).disabledColor),
                                ),
                                TextButton(
                                  onPressed: _seconds > 0
                                      ? null
                                      : () {
                                          authController
                                              .sendOtp(widget.phone)
                                              .then((value) {
                                            if (value.isSuccess) {
                                              _startTimer();
                                              showCustomSnackBar(
                                                  'resend_code_successful'.tr,
                                                  isError: false);
                                            } else {
                                              showCustomSnackBar(value.message);
                                            }
                                          });
                                        },
                                  child: Text(
                                    '${'resend'.tr}${_seconds > 0 ? ' (${_seconds}s)' : ''}',
                                    style: TextStyle(
                                      color: _seconds > 0
                                          ? Theme.of(context).disabledColor
                                          : Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ]),
                        ]),
                  ),
                ),
              ),
            ),
            !authController.isLoading
                ? CustomButtonWidget(
                    buttonText: 'verify'.tr,
                    margin: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    onPressed: _otp.length == 4
                        ? () {
                            authController
                                .verifyOtp(widget.phone, _otp)
                                .then((status) async {
                              if (status.isSuccess) {
                                if (authController.isActiveRememberMe) {
                                  authController.saveUserCredentials(
                                      widget.phone, '');
                                } else {
                                  authController.clearUserCredentials();
                                }
                                await Get.find<ProfileController>()
                                    .getProfile();
                                Get.offAllNamed(RouteHelper.getInitialRoute());
                              } else {
                                showCustomSnackBar(status.message);
                              }
                            });
                          }
                        : null,
                  )
                : const Center(child: CircularProgressIndicator()),
          ]);
        }),
      ),
    );
  }
}
