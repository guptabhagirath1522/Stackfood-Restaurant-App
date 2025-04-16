import 'package:stackfood_multivendor_restaurant/common/widgets/custom_app_bar_widget.dart';
import 'package:stackfood_multivendor_restaurant/common/widgets/custom_asset_image_widget.dart';
import 'package:stackfood_multivendor_restaurant/features/order/controllers/order_controller.dart';
import 'package:stackfood_multivendor_restaurant/features/home/widgets/order_button_widget.dart';
import 'package:stackfood_multivendor_restaurant/features/order/widgets/count_widget.dart';
import 'package:stackfood_multivendor_restaurant/features/order/widgets/order_view_widget.dart';
import 'package:stackfood_multivendor_restaurant/features/profile/controllers/profile_controller.dart';
import 'package:stackfood_multivendor_restaurant/util/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackfood_multivendor_restaurant/util/images.dart';
import 'package:stackfood_multivendor_restaurant/util/styles.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {

    Get.find<OrderController>().getPaginatedOrders(1, true);

    return Scaffold(

      appBar: CustomAppBarWidget(title: 'order_history'.tr, isBackButtonExist: false),

      body: GetBuilder<OrderController>(builder: (orderController) {
        return Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Column(children: [

            GetBuilder<ProfileController>(builder: (profileController) {
              return profileController.profileModel != null ? Row(children: [

                CountWidget(title: 'today'.tr, count: profileController.profileModel!.todaysOrderCount),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                CountWidget(title: 'this_week'.tr, count: profileController.profileModel!.thisWeekOrderCount),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                CountWidget(title: 'this_month'.tr, count: profileController.profileModel!.thisMonthOrderCount),

              ]) : const SizedBox();
            }),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            Expanded(
              child: Container(
                constraints: BoxConstraints(minHeight: context.height * 0.4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  color: Theme.of(context).cardColor,
                  boxShadow: const [BoxShadow(color: Colors.black12, spreadRadius: 0, blurRadius: 5)],
                ),
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Column(children: [
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: orderController.statusList.length,
                      itemBuilder: (context, index) {
                        return OrderButtonWidget(
                          title: orderController.statusList[index].tr, index: index, orderController: orderController, fromHistory: true,
                        );
                      },
                    ),
                  ),

                  const Divider(height: Dimensions.paddingSizeOverLarge),

                  Expanded(child:orderController.historyOrderList != null ? orderController.historyOrderList!.isNotEmpty
                      ? const OrderViewWidget()
                      : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const CustomAssetImageWidget(image: Images.noOrderIcon, height: 50, width: 50),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        Text('${'no_order_yet'.tr}!', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).disabledColor)),
                  ])) : const Center(child: CircularProgressIndicator()),
                  )


                ]),
              ),
            ),

          ]),
        );
      }),
    );
  }
}