import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/custom_app_bar_widget.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/custom_button_widget.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/custom_snackbar_widget.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/custom_text_field_widget.dart';
import 'package:stackfood_multivendor_restaurant/features/auth/controllers/auth_controller.dart';
import 'package:stackfood_multivendor_restaurant/helper/route_helper.dart';
import 'package:stackfood_multivendor_restaurant/util/dimensions.dart';
import 'package:stackfood_multivendor_restaurant/util/images.dart';
import 'package:stackfood_multivendor_restaurant/util/styles.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({Key? key}) : super(key: key);

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  String? _countryDialCode = '+91';

  @override
  void initState() {
    super.initState();
    _phoneController.text = Get.find<AuthController>().getUserNumber();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'phone_login'.tr),
      body: SafeArea(
        child: Center(
          child: Scrollbar(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Center(
                child: SizedBox(
                  width: 1170,
                  child: GetBuilder<AuthController>(builder: (authController) {
                    return Column(children: [
                      Image.asset(Images.logo, width: 100),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Image.asset(Images.logoName, width: 100),
                      const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                      Text('sign_in'.tr.toUpperCase(),
                          style: robotoBlack.copyWith(fontSize: 30)),
                      const SizedBox(height: 50),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusSmall),
                          color: Theme.of(context).cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              spreadRadius: 1,
                              blurRadius: 5,
                            )
                          ],
                        ),
                        child: Column(children: [
                          Row(children: [
                            CodePickerWidget(
                              onChanged: (CountryCode countryCode) {
                                _countryDialCode = countryCode.dialCode;
                              },
                              initialSelection: _countryDialCode ?? '+91',
                              favorite: [_countryDialCode ?? '+91'],
                              showDropDownButton: true,
                              padding: EdgeInsets.zero,
                              showFlagMain: true,
                              textStyle: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeLarge,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .color,
                              ),
                            ),
                            Expanded(
                              child: CustomTextFieldWidget(
                                hintText: 'phone'.tr,
                                controller: _phoneController,
                                focusNode: _phoneFocus,
                                inputType: TextInputType.phone,
                                divider: false,
                                showBorder: false,
                              ),
                            ),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(
                          child: ListTile(
                            onTap: () => authController.toggleRememberMe(),
                            leading: Checkbox(
                              activeColor: Theme.of(context).primaryColor,
                              value: authController.isActiveRememberMe,
                              onChanged: (bool? isChecked) =>
                                  authController.toggleRememberMe(),
                            ),
                            title: Text('remember_me'.tr),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            horizontalTitleGap: 0,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Get.toNamed(RouteHelper.getForgotPassRoute()),
                          child: Text('${'forgot_password'.tr}?'),
                        ),
                      ]),
                      const SizedBox(height: 50),
                      !authController.isLoading
                          ? CustomButtonWidget(
                              buttonText: 'sign_in'.tr,
                              onPressed: () => _login(authController),
                            )
                          : const Center(child: CircularProgressIndicator()),
                      const SizedBox(height: 10),
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(1, 40),
                        ),
                        onPressed: () {
                          Get.toNamed(RouteHelper.getSignInRoute());
                        },
                        child: RichText(
                          text: TextSpan(children: [
                            TextSpan(
                              text: '${'sign_in_with_email'.tr} ',
                              style: robotoRegular.copyWith(
                                  color: Theme.of(context).disabledColor),
                            ),
                          ]),
                        ),
                      ),
                    ]);
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _login(AuthController authController) async {
    String phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      showCustomSnackBar('enter_phone_number'.tr);
    } else {
      authController.sendOtp(_countryDialCode! + phone).then((status) {
        if (status.isSuccess) {
          Get.toNamed(
              RouteHelper.getVerifyPhoneRoute(_countryDialCode! + phone));
        } else {
          showCustomSnackBar(status.message);
        }
      });
    }
  }
}

class CodePickerWidget extends StatelessWidget {
  final Function(CountryCode) onChanged;
  final String initialSelection;
  final List<String> favorite;
  final bool showDropDownButton;
  final EdgeInsetsGeometry padding;
  final bool showFlagMain;
  final TextStyle textStyle;

  const CodePickerWidget({
    required this.onChanged,
    required this.initialSelection,
    required this.favorite,
    required this.showDropDownButton,
    required this.padding,
    required this.showFlagMain,
    required this.textStyle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 85,
      padding: padding,
      child: DropdownButton<String>(
        value: initialSelection,
        icon: const Icon(Icons.keyboard_arrow_down),
        items: favorite.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: textStyle),
          );
        }).toList(),
        onChanged: (String? value) {
          onChanged(CountryCode(dialCode: value!));
        },
      ),
    );
  }
}

class CountryCode {
  final String dialCode;
  CountryCode({required this.dialCode});
}
