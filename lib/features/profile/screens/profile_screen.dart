import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/custom_bottom_sheet_widget.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/custom_image_widget.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/switch_button_widget.dart';
import 'package:stackfood_multivendor_restaurant/common/controllers/theme_controller.dart';
import 'package:stackfood_multivendor_restaurant/features/profile/controllers/profile_controller.dart';
import 'package:stackfood_multivendor_restaurant/features/profile/widgets/account_delete_bottom_sheet.dart';
import 'package:stackfood_multivendor_restaurant/features/profile/widgets/profile_bg_widget.dart';
import 'package:stackfood_multivendor_restaurant/features/profile/widgets/profile_card_widget.dart';
import 'package:stackfood_multivendor_restaurant/helper/route_helper.dart';
import 'package:stackfood_multivendor_restaurant/util/app_constants.dart';
import 'package:stackfood_multivendor_restaurant/util/dimensions.dart';
import 'package:stackfood_multivendor_restaurant/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  void initState() {
    super.initState();

    Get.find<ProfileController>().getProfile();
    // checkBatteryPermission();
  }

  void checkBatteryPermission() async {
    Future.delayed(const Duration(milliseconds: 400), () async {
      if(await Permission.ignoreBatteryOptimizations.status.isDenied) {
        Get.find<ProfileController>().setBackgroundNotificationActive(false);
      } else {
        Get.find<ProfileController>().setBackgroundNotificationActive(true);
      }
    });
  }

  final WidgetStateProperty<Icon?> thumbIcon = WidgetStateProperty.resolveWith<Icon?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return Icon(Icons.circle, color: Get.find<ThemeController>().darkTheme ? Colors.black : Colors.white);
      }
      return Icon(Icons.circle, color: Get.find<ThemeController>().darkTheme ? Colors.white: Colors.black);
    },
  );

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,

      body: GetBuilder<ProfileController>(builder: (profileController) {
        return profileController.profileModel == null ? const Center(child: CircularProgressIndicator()) : ProfileBgWidget(
          backButton: true,
          circularImage: Container(
            decoration: BoxDecoration(
              border: Border.all(width: 2, color: Theme.of(context).cardColor),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: ClipOval(child: CustomImageWidget(
              image: '${profileController.profileModel != null ? profileController.profileModel!.imageFullUrl : ''}',
              height: 100, width: 100, fit: BoxFit.cover,
            )),
          ),
          mainWidget: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: Center(child: Container(
            width: 1170, color: Theme.of(context).cardColor,
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Column(children: [

              Text(
                '${profileController.profileModel!.fName} ${profileController.profileModel!.lName}',
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
              const SizedBox(height: 30),

              Row(children: [
                ProfileCardWidget(title: 'since_joining'.tr, data: '${profileController.profileModel!.memberSinceDays} ${'days'.tr}'),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                ProfileCardWidget(title: 'total_order'.tr, data: profileController.profileModel!.orderCount.toString()),
              ]),
              const SizedBox(height: 30),

              SwitchButtonWidget(icon: Icons.dark_mode, title: 'dark_mode'.tr, isButtonActive: Get.isDarkMode, onTap: () {
                Get.find<ThemeController>().toggleTheme();
              }),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              SwitchButtonWidget(
                icon: Icons.notifications, title: 'system_notification'.tr,
                isButtonActive: profileController.notification, onTap: () {
                  profileController.setNotificationActive(!profileController.notification);
                },
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              InkWell(
                onTap: () {
                  showBgNotificationBottomSheet(profileController.backgroundNotification);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: Dimensions.paddingSizeExtraSmall,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(children: [

                    const Icon(Icons.notifications_active_rounded, size: 25),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    Expanded(child: Text('background_notification'.tr, style: robotoRegular)),

                    CupertinoSwitch(
                      activeTrackColor: Theme.of(context).primaryColor,
                      inactiveTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                      value: profileController.backgroundNotification,
                      onChanged: (bool isActive) {
                        showBgNotificationBottomSheet(profileController.backgroundNotification);
                      },
                    ),
                    // Switch(
                    //   thumbIcon: thumbIcon,
                    //   value: profileController.backgroundNotification,
                    //   onChanged: (bool isActive) {
                    //     showBgNotificationBottomSheet(profileController.backgroundNotification);
                    //   },
                    // ),
                  ]),
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeSmall),

              SwitchButtonWidget(icon: Icons.lock, title: 'change_password'.tr, onTap: () {
                Get.toNamed(RouteHelper.getResetPasswordRoute('', '', 'password-change'));
              }),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              SwitchButtonWidget(icon: Icons.edit, title: 'edit_profile'.tr, onTap: () {
                Get.toNamed(RouteHelper.getUpdateProfileRoute());
              }),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              SwitchButtonWidget(
                icon: Icons.delete, title: 'delete_account'.tr,
                onTap: () {
                  showCustomBottomSheet(
                    child: const AccountDeleteBottomSheet(),
                  );
                },
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [

                Text('${'version'.tr}:', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall)),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                Text(AppConstants.appVersion.toString(), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall)),

              ]),

            ]),
          ))),
        );
      }),
    );
  }

  void showBgNotificationBottomSheet(bool allow) {
    Get.bottomSheet(Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusExtraLarge), topRight: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        Container(
          height: 5, width: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            color: Theme.of(context).disabledColor,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        Text(
          '${!allow ? 'allow'.tr : 'disable'.tr} ${AppConstants.appName} ${'to_run_notification_in_background'.tr}',
          textAlign: TextAlign.center,
          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
        ),

        allow ? Text(
          '(${AppConstants.appName} -> Battery -> Select Optimized)',
          textAlign: TextAlign.center,
          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
        ) : const SizedBox(),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        _buildInfoText("you_will_be_able_to_get_order_notification_even_if_you_are_not_in_the_app".tr),
        _buildInfoText("${AppConstants.appName} ${!allow ? 'will_run_notification_service_in_the_background_always'.tr : 'will_not_run_notification_service_in_the_background_always'.tr}"),
        _buildInfoText(!allow ? "notification_will_always_send_alert_from_the_background".tr : 'notification_will_not_always_send_alert_from_the_background'.tr),
        const SizedBox(height: 20.0),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("cancel".tr, style: robotoMedium),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            ElevatedButton(
              onPressed: () async {
                if(await Permission.ignoreBatteryOptimizations.status.isGranted) {
                  openAppSettings();
                } else {
                  await Permission.ignoreBatteryOptimizations.request();
                }
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                "okay".tr,
                style: robotoMedium.copyWith(color: Theme.of(context).cardColor),
              ),
            ),
          ],
        ),
      ]),
    ), isScrollControlled: true).then((value) {
      checkBatteryPermission();
    });
  }

  Widget _buildInfoText(String text) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        text,
        style: robotoRegular,
      ),
    );
  }
}